library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity UART is
    
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
        
        -- External serial interface
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
    
end UART;

architecture struct of UART is
    
    constant C_BAUD_TICKS : integer := 16;
    constant C_RX_DIV     : integer := C_RX_BAUDRATE * C_BAUD_TICKS;
    constant C_TX_DIV     : integer := C_TX_BAUDRATE * C_BAUD_TICKS;
    
    
    component Freq_Divider is
    
        Generic (
            C_DIVIDER    : integer := 1;
            C_CLOCK_FREQ : integer := 100_000_000 
        );
        
        Port ( 
            Clock_In    : in std_logic;
            Reset       : in std_logic;
            Clock_Out   : out std_logic
        );
        
    end component Freq_Divider;
    
    component UART_Receiver is
    
        Generic (
            C_DATA_BITS  : integer := 8;
            C_BAUD_TICKS : integer := 16
        );
        
        Port (
            Baud_Tick : in std_logic;
            Reset     : in std_logic;
            RX        : in std_logic;
            RX_Ready  : in std_logic; 
            RX_Valid  : out std_logic;
            RX_Data   : out std_logic_vector(C_DATA_BITS - 1 downto 0)  
        );
        
    end component UART_Receiver;
    
    component UART_Transmitter is
    
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
        
    end component UART_Transmitter;

    component AXI_Stream_Dual_Clock_FIFO is
    
        Generic (
            C_WIDTH : integer := 8;
            C_DEPTH : integer := 16
        );
        Port (
            S_AXIS_ACLK     : in  std_logic;
            M_AXIS_ACLK     : in  std_logic;
            ARESETN         : in  std_logic;
                 
                -- slave is the reader interface
            S_AXIS_TDATA    : in  std_logic_vector(C_WIDTH - 1 downto 0);
            S_AXIS_TVALID   : in  std_logic;
            S_AXIS_TREADY   : out std_logic;
                
                -- master is the writer interface
            M_AXIS_TDATA    : out std_logic_vector(C_WIDTH - 1 downto 0);
            M_AXIS_TVALID   : out std_logic;
            M_AXIS_TREADY   : in  std_logic
        );
        
    end component AXI_Stream_Dual_Clock_FIFO;
    
    signal TX_FIFO_Reset : std_logic := '1'; -- Active high TX FIFO reset signal
    signal RX_FIFO_Reset : std_logic := '1'; -- Active high RX FIFO reset signal
    
    signal RX_Bd_Tick    : std_logic; -- Receiver synchronization signal
    signal TX_Bd_Tick    : std_logic; -- Transmitter synchronization signal
    
    -- Transmitter handshaking signals
    signal TX_Valid      : std_logic;
    signal TX_Ready      : std_logic := '0';
   
    -- Receiver handshaking signals
    signal RX_Valid      : std_logic := '0';
    signal RX_Ready      : std_logic;
   
    -- Transmitter data register
    signal TX_Data       : std_logic_vector( C_TX_DATA_BITS - 1 downto 0 ) := (others=>'0');
   
    -- Receiver data register
    signal RX_Data       : std_logic_vector( C_RX_DATA_BITS - 1 downto 0 );
    
    
begin
    
    RX_FIFO_Reset <= not RX_Reset;
    TX_FIFO_Reset <= not TX_Reset;
    
RX_Baud_Rate_Generator_Unit:
    component Freq_Divider
    generic map (
        C_CLOCK_FREQ        =>          C_RX_CLOCK_FREQ,
        C_DIVIDER           =>          C_RX_DIV    
    )
    port map (
        Clock_In            =>          RX_Clock,
        Reset               =>          RX_Reset,
        Clock_Out           =>          RX_Bd_Tick           
    ); 

RX_Data_FIFO_Unit:
    component AXI_Stream_Dual_Clock_FIFO
    generic map (
        C_WIDTH             =>          C_RX_DATA_BITS,
        C_DEPTH             =>          C_RX_FIFO_DEPTH
    )
    port map (
        S_AXIS_ACLK         =>          RX_bd_Tick,
        M_AXIS_ACLK         =>          RX_Clock,
        ARESETN             =>          RX_FIFO_Reset,
        S_AXIS_TDATA        =>          RX_Data,          
        S_AXIS_TVALID       =>          RX_Valid,
        S_AXIS_TREADY       =>          RX_Ready,
        M_AXIS_TDATA        =>          RX_Data_Out,
        M_AXIS_TVALID       =>          RX_Valid_Out,
        M_AXIS_TREADY       =>          RX_Read
    );
    
UART_Receiver_Unit:
    component UART_Receiver
    Generic map (
        C_DATA_BITS         =>          C_RX_DATA_BITS,
        C_BAUD_TICKS        =>          C_BAUD_TICKS
    )
    Port map (
        Baud_Tick           =>          RX_Bd_Tick,
        Reset               =>          RX_Reset,
        RX                  =>          RX,
        RX_Valid            =>          RX_Valid,
        RX_Ready            =>          RX_Ready,
        RX_Data             =>          RX_Data
    ); 


TX_Baud_Rate_Generator_Unit:
    component Freq_Divider
    generic map (
        C_CLOCK_FREQ        =>          C_TX_CLOCK_FREQ,
        C_DIVIDER           =>          C_TX_DIV    
    )
    port map (
        Clock_In            =>          TX_Clock,
        Reset               =>          TX_Reset,
        Clock_Out           =>          TX_Bd_Tick           
    ); 
     
TX_Data_FIFO_Unit:
    component AXI_Stream_Dual_Clock_FIFO
    generic map (
        C_WIDTH             =>          C_TX_DATA_BITS,
        C_DEPTH             =>          C_TX_FIFO_DEPTH
    )
    port map (
        S_AXIS_ACLK         =>          TX_Clock,
        M_AXIS_ACLK         =>          TX_Bd_Tick,
        ARESETN             =>          TX_FIFO_Reset,
        S_AXIS_TDATA        =>          TX_Data_In,          
        S_AXIS_TVALID       =>          TX_Write,
        S_AXIS_TREADY       =>          TX_Ready_Out,
        M_AXIS_TDATA        =>          TX_Data,
        M_AXIS_TVALID       =>          TX_Valid,
        M_AXIS_TREADY       =>          TX_Ready
    );

UART_Transmitter_Unit:
    component UART_Transmitter 
    Generic map (
        C_DATA_BITS         =>          C_TX_DATA_BITS
    )
    Port map (
        Baud_Tick           =>          TX_Bd_Tick,
        Reset               =>          TX_Reset,
        TX                  =>          TX,
        TX_Valid            =>          TX_Valid,
        TX_Ready            =>          TX_Ready,
        TX_Data             =>          TX_Data
    ); 

end struct;
