library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Freq_Divider is

    Generic (

        C_DIVIDER   : integer := 1;
        C_CLOCK_FREQ : integer := 100_000_000 

    );
    
    Port ( 

        Clock_In    : in std_logic;
        Reset       : in std_logic;
        Clock_Out   : out std_logic

    );
    
end Freq_Divider;

architecture behv of Freq_Divider is 
  
    constant C_DIV : integer := C_CLOCK_FREQ / C_DIVIDER - 1;

begin

Frequency_Divider_Process:
    process (Clock_In, Reset)
    
        variable cnt : integer range 0 to C_DIV := 0;
    
    begin
        
        if Reset = '1' then
            
            cnt := 0;
            Clock_Out <= '0';
        
        elsif rising_edge(Clock_In) then
            
            if cnt = C_DIV then
            
                cnt := 0;
                Clock_Out <= '1';    
                
            else
                
                cnt := cnt + 1;
                Clock_Out <= '0';
                
            end if;
            
        end if; 
        
    end process;

end behv;
