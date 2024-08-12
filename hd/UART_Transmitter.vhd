library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity UART_Transmitter is

    Generic (
        C_DATA_BITS : integer := 8
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
    
        variable bit_Counter  : integer := 0;
         
    begin
        
        if Reset = '1' then
        
            State_Reg <= TX_Idle_State;
            Shift_Reg <= (others=>'0');
            
            bit_Counter  := 0;
            
            TX <= '1';
            TX_Ready <= '0';
            
        elsif rising_edge(Baud_Tick) then
        
            case State_Reg is 

                when TX_Idle_State =>

                    TX <= '1';
                    bit_Counter  := 0;

                    if TX_Valid = '1' then

                        -- handshaking 
                        TX_Ready <= '1';
                        State_Reg <= TX_Start_State;
                            
                    else

                        TX_Ready  <= '0';
                        State_Reg <= TX_Idle_State;
                            
                    end if;
                    
                when TX_Start_State =>
                    
                    -- load the data to transsmit
                    Shift_Reg <= TX_Data;

                    -- transmit the start bit
                    TX_Ready  <= '0';

                    State_Reg <= TX_Data_State;
                     
                when TX_Data_State =>

                    -- transmit the current data bit                    
                    TX <= Shift_Reg(bit_Counter);
                    
                    if bit_Counter >= C_DATA_BITS - 1 then
                        
                        bit_Counter := 0;
                        State_Reg <= TX_Stop_State;
                        
                    else
                        
                        -- point to the next bit
                        bit_Counter := bit_Counter + 1;
                        State_Reg <= TX_Data_State;
                        
                    end if;
                     
                when TX_Stop_State =>
                    
                    -- transmit the stop bit
                    TX <= '1';
                    State_Reg <= TX_Idle_State;
                    
                when others =>
                    State_Reg <= TX_Idle_State;
                    
            end case;
        end if;
        
    end process;
    
end Behavioral;
