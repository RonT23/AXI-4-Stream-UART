library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity AXI_Stream_Dual_Clock_FIFO is

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
    
end AXI_Stream_Dual_Clock_FIFO;

architecture behv of AXI_Stream_Dual_Clock_FIFO is

    type memory_t is array (0 to C_DEPTH - 1) of std_logic_vector(C_WIDTH - 1 downto 0);
    signal FIFO_Memory : memory_t := (others=>(others=>'0'));
   
    signal Full_Reg  : std_logic := '0';
    signal Empty_Reg : std_logic := '1';
      
begin
    
    S_AXIS_TREADY <= not Full_Reg;  -- If the FIFO is not full then is ready to read new data
    M_AXIS_TVALID <= not Empty_Reg; -- If the FIFO is not empty then is has valid data to export
    
FIFO_Transaction_Counter_Process:
    process (S_AXIS_ACLK, M_AXIS_ACLK, ARESETN)
    
        variable count : integer range 0 to C_DEPTH := 0;
    
    begin
        
        if ARESETN = '0' then
            
            count := 0;
            Empty_Reg <= '1';
            Full_Reg  <= '0';
            
        else
        
            if rising_edge( S_AXIS_ACLK ) then
                
                if S_AXIS_TVALID = '1' and Full_Reg = '0' then
     
                   count := count + 1;
                                            
                end if;
                
                if count = C_DEPTH - 1 then

                    Full_Reg <= '1';

                else

                    Full_Reg <= '0';

                end if;
                 
            end if;
            
            if rising_edge( M_AXIS_ACLK ) then
            
                if M_AXIS_TREADY = '1' and Empty_Reg = '0' then
                    
                   count := count - 1;
                                            
                end if;
                
                if count = 0 then

                    Empty_Reg <= '1';

                else
                    
                    Empty_Reg <= '0';

                end if;
                  
            end if;  

        end if;

    end process;

FIFO_Push_Process:
    process (S_AXIS_ACLK, ARESETN)
        
        variable wr_ptr : integer range 0 to C_DEPTH - 1 := 0;
        
    begin
        if ARESETN = '0' then
        
            wr_ptr := 0;
            FIFO_Memory <= (others=>(others=>'0'));
            
        elsif rising_edge(S_AXIS_ACLK) then
            
            if S_AXIS_TVALID = '1' and Full_reg = '0' then
            
                FIFO_Memory(wr_ptr) <= S_AXIS_TDATA;
                                 
                if wr_ptr = C_DEPTH - 1 then    

                    wr_ptr := 0;
                
                else                            
                
                    wr_ptr := wr_ptr + 1;
                
                end if;
                
            end if;
 
        end if;

     end process;
     
FIFO_Pop_Process:
    process (M_AXIS_ACLK, ARESETN )
        
        variable rd_ptr    : integer range 0 to C_DEPTH - 1 := 0;
        
    begin

        if ARESETN = '0' then   
           
            rd_ptr    := 0;            
            M_AXIS_TDATA <= (others=>'0');
        
        elsif rising_edge(M_AXIS_ACLK) then
            
            if M_AXIS_TREADY = '1' and Empty_Reg = '0' then
            
                M_AXIS_TDATA <= FIFO_Memory(rd_ptr);
                
                if rd_ptr = C_DEPTH - 1 then

                    rd_ptr := 0;

                else

                    rd_ptr := rd_ptr + 1;

                end if;

            end if;

        end if;

    end process;
    
end behv;
