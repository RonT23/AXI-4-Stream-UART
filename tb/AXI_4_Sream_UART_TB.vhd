library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity AXI_4_Stream_UART_TB is
end AXI_4_Stream_UART_TB;

architecture tb of AXI_4_Stream_UART_TB is
    
    constant C_CLOCK_PERIOD  : time    := 10 ns;
    constant C_DATA_BITS     : integer := 8;
    constant C_FIFO_DEPTH    : integer := 16;
    constant C_BAUDRATE      : integer := 115_200;
    constant C_CLOCK_FREQ    : integer := 100_000_000;

    signal S_AXIS_ACLK       : std_logic := '0';
    signal S_AXIS_ARESETN    : std_logic := '1';
    signal S_AXIS_TVALID     : std_logic;
    signal S_AXIS_TREADY     : std_logic := '0';
    signal S_AXIS_TDATA      : std_logic_vector( C_DATA_BITS - 1 downto 0 );

    signal M_AXIS_ACLK       : std_logic := '0';
    signal M_AXIS_ARESETN    : std_logic := '1';
    signal M_AXIS_TVALID     : std_logic := '0';
    signal M_AXIS_TREADY     : std_logic;
    signal M_AXIS_TDATA      : std_logic_vector( C_DATA_BITS - 1 downto 0 ) := (others=>'0');
    
    signal RX                : std_logic;
    signal TX                : std_logic := '1';
    
    signal Bd_Gen_Reset      : std_logic := '0';
    signal Baud_Tick         : std_logic := '0';
     
    -- Procedure to write serial data
    procedure UART_Write(
        signal Baud_Tick : in std_logic;
        signal TX        : out std_logic;
        Data             : in std_logic_vector(C_DATA_BITS - 1 downto 0)
    ) is 
   
    begin
         -- send start bit
         TX <= '0';
        
         wait until rising_edge(Baud_Tick);
         
         -- send data bits
         for i in 0 to C_DATA_BITS - 1 loop
                
            TX <= Data(i);
    
            wait until rising_edge(Baud_Tick);
                
          end loop;
          
          -- send stop bit
          TX <= '1';
          wait until rising_edge(Baud_Tick);
         
    end procedure;
begin

AXI_4_Stream_UART_UUT :
        entity work.AXI_4_Stream_UART
        Generic map (
            C_RX_DATA_BITS      =>          C_DATA_BITS,
            C_RX_FIFO_DEPTH     =>          C_FIFO_DEPTH,
            C_RX_BAUDRATE       =>          C_BAUDRATE,
            C_RX_CLOCK_FREQ     =>          C_CLOCK_FREQ,
            
            C_TX_DATA_BITS      =>          C_DATA_BITS,
            C_TX_FIFO_DEPTH     =>          C_FIFO_DEPTH,
            C_TX_BAUDRATE       =>          C_BAUDRATE,
            C_TX_CLOCK_FREQ     =>          C_CLOCK_FREQ
            
        )
        Port map (
            S_AXIS_ACLK         =>          M_AXIS_ACLK,
            S_AXIS_ARESETN      =>          M_AXIS_ARESETN,
            S_AXIS_TVALID       =>          M_AXIS_TVALID,
            S_AXIS_TREADY       =>          M_AXIS_TREADY,
            S_AXIS_TDATA        =>          M_AXIS_TDATA,
            
            M_AXIS_ACLK         =>          S_AXIS_ACLK,
            M_AXIS_ARESETN      =>          S_AXIS_ARESETN,
            M_AXIS_TVALID       =>          S_AXIS_TVALID,
            M_AXIS_TREADY       =>          S_AXIS_TREADY,
            M_AXIS_TDATA        =>          S_AXIS_TDATA,
            
            TX                  =>          RX,
            RX                  =>          TX    
        );
        
 Clock_generator_100MHz_process:
        process
        begin
        
            wait for C_CLOCK_PERIOD / 2;
            M_AXIS_ACLK <= not M_AXIS_ACLK;
            S_AXIS_ACLK <= not S_AXIS_ACLK;
            
        end process;

Baud_Rate_generator_Unit:
        entity work.Freq_Divider
        Generic map ( 
            C_DIVIDER       =>      C_BAUDRATE,
            C_CLOCK_FREQ    =>      C_CLOCK_FREQ
        )
        Port map (
            Clock_In        =>      S_AXIS_ACLK,
            Reset           =>      Bd_Gen_Reset,
            Clock_Out       =>      Baud_Tick
        );
        
Stimulus_Process:
        process
        begin
            
            -- Reset the slave interface
            S_AXIS_ARESETN <= '0';
           
            for i in 0 to 10 loop
                wait until rising_edge(S_AXIS_ACLK);
            end loop;
            
            S_AXIS_ARESETN <= '1';
           
            -- Reset the master interface
            M_AXIS_ARESETN <= '0';
            
            for i in 0 to 10 loop
                wait until rising_edge(M_AXIS_ACLK);
            end loop;
            
            M_AXIS_ARESETN <= '1';
            
            -- Transmit some data bytes to the RX channel
            for i in 0 to 5 loop
                UART_Write(Baud_Tick, TX, std_logic_vector( to_unsigned(i, C_DATA_BITS) ) );
                wait until rising_edge(M_AXIS_ACLK); 
            end loop;
            
            -- Read the data stored in RX FIFO
            S_AXIS_TREADY <= '1';
            
            -- Set some data to be transmitted from TX channel
            for i in 0 to 5 loop
                
                M_AXIS_TVALID <= '1';
               
                M_AXIS_TDATA <= std_logic_vector ( to_unsigned(i, C_DATA_BITS) );
               
                wait until rising_edge(M_AXIS_ACLK) and M_AXIS_TREADY = '1';
               
                M_AXIS_TVALID <= '0';
               
                wait until rising_edge(M_AXIS_ACLK);
                 
            end loop;
            
            -- simulation terminated
            wait;
            
        end process;

end tb;