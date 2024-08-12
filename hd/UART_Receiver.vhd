library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity UART_Receiver is

    Generic (

        C_DATA_BITS    : integer := 8;
        C_BAUD_TICKS   : integer := 2

    );
    
    Port ( 

        Baud_Tick : in   std_logic;
        Reset     : in   std_logic;
        RX        : in   std_logic;
        RX_Ready  : in   std_logic;
        RX_Valid  : out  std_logic;
        RX_Data   : out  std_logic_vector(C_DATA_BITS - 1 downto 0)
    
    );
    
end UART_Receiver;

architecture behv of UART_Receiver is
    
    type rx_fsm_t is (

       RX_Idle_State,
       RX_Start_State,
       RX_Data_State,
       RX_Stop_State  

    );
    
    signal State_Reg : rx_fsm_t := RX_Idle_State;
    
    signal Shift_Reg : std_logic_vector(C_DATA_BITS - 1 downto 0);
    
begin

UART_Receiver_FSM_Process :
    process (Baud_Tick, Reset) 
    
        variable bit_Counter  : integer := 0;
        variable baud_Counter : integer := 0;
         
    begin
        
        if Reset = '1' then 

            State_Reg <= RX_Idle_State;
            Shift_Reg <= (others=>'0');
            
            bit_Counter  := 0;
            baud_Counter := 0;
            
            RX_Valid <= '0';
            RX_Data <= (others=>'0');
            
        elsif rising_edge(Baud_Tick) then 

            case State_Reg is
            
                when RX_Idle_State  =>
                    
                    bit_Counter  := 0;
                    RX_Valid  <= '0';
                         
                    if RX = '0' and RX_Ready = '1' then 
                    
                        -- a transmission maybe is issued
                        baud_Counter := 1;
                        State_Reg <= RX_Start_State;
                        
                    else   
                        
                        -- hold on to idle
                        baud_Counter := 0;
                        State_Reg <= RX_Idle_State;
                        
                    end if;
                
                when RX_Start_State =>
                    
                    -- take a sample at the middle of the start bit
                    if baud_Counter >= C_BAUD_TICKS/2 - 1 then
                         
                        -- check if the transmission is issued
                        if RX = '0' then
                        
                            -- transmission is issued go on and read the data bits
                            baud_Counter := 1;
                            State_Reg <= RX_Data_State;
                            
                        else
                            
                            -- false alarm ...
                            baud_Counter := 0;
                            State_Reg <= RX_Idle_State;
                            
                        end if; 
                        
                    else 
                        
                        baud_Counter := baud_Counter + 1;
                        State_Reg <= RX_Start_State;
                        
                    end if;
                    
                when RX_Data_State  =>
                    
                    -- take samples from the middle of each bit
                    if baud_Counter >= C_BAUD_TICKS - 1 then
                        
                        -- store the current bit read to the shift register
                        Shift_Reg(bit_Counter) <= RX;
                        
                        if bit_Counter >= C_DATA_BITS - 1 then
                            
                            -- all bits are read and stored
                            bit_Counter  := 0;
                            baud_Counter := 1;
                            
                            State_Reg <= RX_Stop_State;
                            
                        else
                            
                            -- point to next bit position
                            bit_Counter  := bit_Counter + 1;
                            baud_Counter := 0;
                        
                            State_Reg <= RX_Data_State;
                            
                        end if;
                         
                    else
                        
                        baud_Counter := baud_Counter + 1;
                        State_Reg <= RX_Data_State; 
                        
                    end if; 
                    
                when RX_Stop_State  =>
                    
                    -- take a sample in the middle of the stop bit
                    if baud_Counter >= C_BAUD_TICKS - 1 then
                        
                        -- the stop bit is issued
                        if RX = '1' then
                        
                            -- the data on the shift register are valid
                            RX_Valid <= '1';
                            RX_Data <= Shift_Reg;
                            
                        end if;  
                            
                        baud_Counter := 0;
                        bit_Counter  := 0;
                        State_Reg <= RX_Idle_State;
                        
                    else
                        
                        baud_Counter := baud_Counter + 1;
                        State_Reg <= RX_Stop_State;
                                            
                    end if; 
                    
                when others         =>
                    State_Reg <= RX_Idle_State;
                     
            end case;

        end if;

    end process; 

end behv;
