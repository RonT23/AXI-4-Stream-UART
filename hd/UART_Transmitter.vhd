library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity UART_Transmitter is

    Generic (
    
        C_DATA_BITS  : integer := 8;
        C_BAUD_TICKS : integer := 16
        
    );
    
    Port (
    
        Baud_Tick : in std_logic;
        Reset     : in std_logic;
        TX        : out std_logic;
        TX_Ready  : out std_logic; 
        TX_Valid  : in std_logic;
        TX_Data   : in std_logic_vector(C_DATA_BITS - 1 downto 0)  
        
    );
    
end UART_Transmitter;

architecture behv of UART_Transmitter is
    
    type tx_fsm_t is (
    
        TX_Idle_State,
        TX_Start_State,
        TX_Data_State,
        TX_Stop_State
        
    );
    
    signal State_Reg : tx_fsm_t := TX_Idle_State;
    
    signal Shift_Reg : std_logic_vector(C_DATA_BITS - 1 downto 0);
    
begin

UART_Transmitter_FSM_Process:
    process (Baud_Tick, Reset)
    
        variable bit_Counter   : integer := 0;
        variable baud_Counter  : integer := 0;
         
    begin
        
        if Reset = '1' then
        
            State_Reg <= TX_Idle_State;
            Shift_Reg <= (others=>'0');
            
            bit_Counter  := 0;
            baud_Counter := 0;
            
            TX <= '1';
            TX_Ready <= '0';
            
        elsif rising_edge(Baud_Tick) then
        
            case State_Reg is 

                when TX_Idle_State =>

                    bit_Counter  := 0;
                    
                    if TX_Valid = '1' then
                        
                        baud_Counter := 1;
                    
                        -- handshaking 
                        TX_Ready <= '1';
                        TX <= '0';
                        
                        State_Reg <= TX_Start_State;
                            
                    else
                        baud_Counter := 0;
                    
                        TX_Ready  <= '0';
                        TX <= '1';
                        
                        State_Reg <= TX_Idle_State;
                            
                    end if;
                    
                when TX_Start_State =>
                    
                    -- load the data to transsmit
                    Shift_Reg <= TX_Data;
                    TX_Ready  <= '0';
                    
                    if baud_Counter >= C_BAUD_TICKS - 1 then
                        
                        baud_Counter := 1;
                        TX <= Shift_Reg(0);
                        
                        State_Reg <= TX_Data_State;
                     
                    else
                        
                        baud_Counter := baud_Counter + 1;
                        TX <= '0';
                        
                        State_Reg <= TX_Start_State;
                        
                    end if;
                    
                when TX_Data_State =>
                    
                    if baud_Counter >= C_BAUD_TICKS - 1 then
                        
                        if bit_Counter >= C_DATA_BITS - 1 then
                            
                            baud_Counter := 1;
                            bit_Counter  := 0;
                            TX <= '1';
                            
                            State_Reg <= TX_Stop_State;
                            
                        else
                            
                            bit_Counter  := bit_Counter + 1;
                            baud_Counter := 0;
                            TX <= Shift_Reg(bit_Counter);
                        
                            State_Reg <= TX_Data_State;
                            
                        end if;
                    
                    else 
                       
                       baud_Counter := baud_Counter + 1;
                       State_Reg <= TX_Data_State;  
                           
                    end if;
                     
                when TX_Stop_State =>

                    -- transmit the stop bit                    
                    TX <= '1';
                        
                    if baud_Counter >= C_BAUD_TICKS - 1 then
                        
                        baud_Counter := 0;
                        State_Reg <= TX_Idle_State;
                        
                    else
                        
                        baud_Counter := baud_Counter + 1;
                        State_Reg <= TX_Stop_State;
                                            
                    end if;
                    
                when others =>
                    State_Reg <= TX_Idle_State;
                    
            end case;
        end if;
        
    end process;
    
end behv;
