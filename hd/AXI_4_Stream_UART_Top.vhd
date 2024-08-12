library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity AXI_4_Stream_UART_Top is
    
    Generic (
    
        C_RX_DATA_BITS       : integer := 8;
        C_RX_FIFO_DEPTH      : integer := 16;
        C_RX_BAUDRATE        : integer := 115_200;
        C_RX_CLOCK_FREQ      : integer := 100_000_000;
        
        C_TX_DATA_BITS       : integer := 8;
        C_TX_FIFO_DEPTH      : integer := 16;
        C_TX_BAUDRATE        : integer := 115_200;
        C_TX_CLOCK_FREQ      : integer := 100_000_000
        
    );
    
    Port ( 
        
        -- AXI-4 Transmitter channel
        S_AXIS_ACLK	     : in  std_logic;
		S_AXIS_ARESETN   : in  std_logic;
		S_AXIS_TREADY    : out std_logic;
		S_AXIS_TVALID    : in  std_logic;
		S_AXIS_TDATA     : in  std_logic_vector( C_TX_DATA_BITS - 1 downto 0 );
		
		-- AXI-4 Receiver channel
		M_AXIS_ACLK      : in  std_logic;
		M_AXIS_ARESETN   : in  std_logic; 
		M_AXIS_TREADY    : in  std_logic;
		M_AXIS_TVALID    : out std_logic;
		M_AXIS_TDATA     : out std_logic_vector( C_RX_DATA_BITS - 1 downto 0 );
        
        -- Serial Receiver channel
        RX              : in  std_logic;
        
        -- Serial Transmitter channel
        TX              : out std_logic
        
    );
    
end AXI_4_Stream_UART_Top;

architecture struct of AXI_4_Stream_UART_Top is
     
    component UART is
    
    Generic (

        C_RX_DATA_BITS       : integer := 8;
        C_RX_FIFO_DEPTH      : integer := 16;
        C_RX_BAUDRATE        : integer := 115_200;
        C_RX_CLOCK_FREQ      : integer := 100_000_000;
        
        C_TX_DATA_BITS       : integer := 8;
        C_TX_FIFO_DEPTH      : integer := 16;
        C_TX_BAUDRATE        : integer := 115_200;
        C_TX_CLOCK_FREQ      : integer := 100_000_000
    
    );
        
    Port ( 
        RX_Clock      : in  std_logic;
        TX_Clock      : in  std_logic;
        
        -- External interface
        RX            : in  std_logic;
        TX            : out std_logic;
        
        -- Internal receiver interface
        RX_Reset      : in  std_logic;
        RX_Read       : in  std_logic; 
        RX_Valid_Out  : out std_logic;
        RX_Data_Out   : out std_logic_vector( C_RX_DATA_BITS - 1 downto 0 );
        
        -- Internal transmitter interface
        TX_Reset      : in  std_logic; 
        TX_Write      : in  std_logic;
        TX_Ready_Out  : out std_logic;
        TX_Data_In    : in  std_logic_vector( C_TX_DATA_BITS - 1 downto 0 )
        
    );
    
    end component UART;
    
    signal RX_Reset   : std_logic := '0'; -- Active high receiver reset signal  
    signal TX_Reset   : std_logic := '0'; -- Active low transmitter reset signal

begin
  
   RX_Reset <= not (M_AXIS_ARESETN);
   TX_Reset <= not (S_AXIS_ARESETN);     
     
UART_System_Unit:
    component UART
    generic map (
    
        C_RX_DATA_BITS          =>          C_RX_DATA_BITS,
        C_RX_FIFO_DEPTH         =>          C_RX_FIFO_DEPTH,
        C_RX_BAUDRATE           =>          C_RX_BAUDRATE,
        C_RX_CLOCK_FREQ         =>          C_RX_CLOCK_FREQ,
        
        C_TX_DATA_BITS          =>          C_TX_DATA_BITS,
        C_TX_FIFO_DEPTH         =>          C_TX_FIFO_DEPTH,
        C_TX_BAUDRATE           =>          C_TX_BAUDRATE,
        C_TX_CLOCK_FREQ         =>          C_TX_CLOCK_FREQ
        
    )
    port map (
    
        RX_Clock                =>          M_AXIS_ACLK,
        TX_Clock                =>          S_AXIS_ACLK,
        
        TX                      =>          TX,
        RX                      =>          RX,
        
        RX_Reset                =>          RX_Reset,
        RX_Read                 =>          M_AXIS_TREADY,
        RX_Valid_Out            =>          M_AXIS_TVALID,
        RX_Data_Out             =>          M_AXIS_TDATA,
        
        TX_Reset                =>          TX_Reset,
        TX_Write                =>          S_AXIS_TVALID,
        TX_Ready_Out            =>          S_AXIS_TREADY,
        TX_Data_In              =>          S_AXIS_TDATA
    
    );
       
end struct;
