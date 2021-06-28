library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;


entity interpolation_2x2 is
      port (
            rstn      : in    std_logic;
            sclk      : in    std_logic;
                       
            data      : in std_logic_vector(7 downto 0);
            
            vsync     : in   std_logic;
            hsync     : in   std_logic;
            
            output_sync : out std_logic;
            
            data_r_o1  : out std_logic_vector(7 downto 0);
            data_g_o1  : out std_logic_vector(7 downto 0);
            data_b_o1  : out std_logic_vector(7 downto 0)   
     );
end interpolation_2x2;

architecture u_interpolation_2x2 of interpolation_2x2 is
  
component sync_dpram is
   port(
         clk_l     : in  std_logic;
         wrn       : in  std_logic;
         waddr     : in  std_logic_vector( 9 downto 0);
         data_in   : in  std_logic_vector( 7 downto 0);

         clk_r     : in  std_logic;
         rdn       : in  std_logic;
         raddr     : in  std_logic_vector( 9 downto 0);
         data_out  : out std_logic_vector( 7 downto 0)
   );
end component;

--dpram 1------------------------------------------------------------------------
  signal w_data_buffer_1    : std_logic_vector( 7 downto 0); --write_data_buffer
  signal w_addr_buffer_1    : std_logic_vector( 9 downto 0); --write_address_buffer
  signal wrn_1              : std_logic;                     --write_flag
  
  signal r_data_buffer_1    : std_logic_vector( 7 downto 0); --read_data_buffer
  signal r_addr_buffer_1    : std_logic_vector( 9 downto 0); --read_address_buffer
  signal rdn_1              : std_logic;                     --read_flag
  
  signal w_data_buffer_1_d  : std_logic_vector( 7 downto 0); --write_data_buffer_delay
  
----------------------------------------------------------------------------------


--dpram 2-------------------------------------------------------------------------
  signal w_data_buffer_2    : std_logic_vector( 7 downto 0); --write_data_buffer
  signal w_addr_buffer_2    : std_logic_vector( 9 downto 0); --write_address_buffer
  signal wrn_2              : std_logic;                     --write_flag
  
  signal r_data_buffer_2    : std_logic_vector( 7 downto 0); --read_data_buffer
  signal r_addr_buffer_2    : std_logic_vector( 9 downto 0); --read_address_buffer
  signal rdn_2              : std_logic;                     --read_flag
  
  signal w_data_buffer_2_d  : std_logic_vector( 7 downto 0); --write_data_buffer_delay
-----------------------------------------------------------------------------------
   
--processing data------------------------------------------------------------------   
  signal p_data_buffer1 : std_logic_vector( 7 downto 0);  --processing data buffer1
  signal p_data_buffer2 : std_logic_vector( 7 downto 0);  --processing data buffer2
  signal p_data_buffer3 : std_logic_vector( 7 downto 0);  --processing data buffer3
  signal p_data_buffer4 : std_logic_vector( 7 downto 0);  --processing data buffer4
-----------------------------------------------------------------------------------  
  
  
  
  signal hsync_1 : std_logic;     --hsync one delay
  signal vsync_1 : std_logic;     --vsync one delay
  
  signal hsync_2  : std_logic;    --hsync two delay

  

  signal hsync_fe : std_logic;    --for line_cnt count
  
  signal line_cnt1  : std_logic_vector(9 downto 0);
  signal line_cnt2  : std_logic_vector(9 downto 0);  --line_cnt1 one delay
  
  signal pixel_cnt1 : std_logic_vector(9 downto 0);
  signal pixel_cnt2 : std_logic_vector(9 downto 0);  --pixel_cnt1 one delay
  signal pixel_cnt3 : std_logic_vector(9 downto 0);  --pixel_cnt1 two delay

  signal R_temp : std_logic_vector(7 downto 0);      --RED    data buffer
  signal G_temp : std_logic_vector(8 downto 0);      --GREEN  data buffer
  signal B_temp : std_logic_vector(7 downto 0);      --BLUE   data buffer
  
  type state is (IDEL0_STATE, ODD_STATE, EVEN_STATE);
  signal csm  : state;
  
  type state1 is (IDEL_STATE, RGGB_STATE, GRBG_STATE, GBRG_STATE, BGGR_STATE);
  signal csm1  : state1;
  
  
begin

  -- hsync_1  <= hsync one delay ----------------------------------------------
  -- hsync_2  <= hsync two delay ----------------------------------------------
  -- vsync_1  <= vsync one delay ----------------------------------------------
  process(sclk, rstn)
  begin     
    if (rstn = '0') then
      hsync_1 <= '0';
      vsync_1 <= '0';
      
      hsync_2 <=  '0';
    elsif rising_edge (sclk) then
      hsync_1 <=  hsync;
      vsync_1 <=  vsync;
      
      hsync_2 <=  hsync_1;
    end if;
  end process;
  ------------------------------------------------------------------------------


--hsync count / vsync count
--------------------------------------------------------------------------------
process(sclk,rstn)   --pixel number count!
  begin
    if(rstn = '0') then
      pixel_cnt1 <= (others => '0');
    elsif rising_edge (sclk) then
      if (hsync = '1') then
         pixel_cnt1 <= pixel_cnt1 + 1;
      else
         pixel_cnt1 <= (others => '0');
      end if;
    end if;
  end process;
      
  --hsync_fe------------------------
  hsync_fe <= '1' when(hsync_1 ='0') and (hsync_2 = '1') and (vsync_1 = '1') else '0';
  ----------------------------------           
  
process(hsync_fe,rstn)   --line number count !
  begin
    if(rstn = '0') then
        line_cnt1 <= (others => '0');
    elsif rising_edge (hsync_fe) then
        line_cnt1 <= line_cnt1 + 1;
    end if;
  end process;
----------------------------------------------------------------------------------

-------pixel_cnt delay / line_cnt delay-------------------------------------------

  process(sclk, rstn)
  begin     
    if (rstn = '0') then
      pixel_cnt2 <= (others=>'0');
      pixel_cnt3 <= (others=>'0');
    elsif rising_edge (sclk) then
      pixel_cnt2 <= pixel_cnt1;
      pixel_cnt3 <= pixel_cnt2;
    end if;
  end process;
       
  process(sclk, rstn)   --it always need 2 line for image processing.
  begin     
    if (rstn = '0') then
      line_cnt2 <= (others=>'0');
    elsif rising_edge (sclk) then
      line_cnt2 <= line_cnt1;
    end if;
  end process;
    
----------------------------------------------------------------------------------

---------dpram1 mapping-----------------------------------------------------------
w_data_buffer_1 <= data;
w_addr_buffer_1 <= pixel_cnt2;

r_addr_buffer_1 <= pixel_cnt2;
----------------------------------------------------------------------------------

----------dpram2 mapping----------------------------------------------------------
w_data_buffer_2 <= data;
w_addr_buffer_2 <= pixel_cnt2;

r_addr_buffer_2 <= pixel_cnt2;

----------------------------------------------------------------------------------


------------------------------------state by line_cnt2----------------------------
--dpram r/w timing
process(line_cnt2)
  begin
    if((line_cnt2 = 0) or (line_cnt2 = 481)) then
      csm <= IDEL0_STATE;
    elsif(line_cnt2(0) = '1') then      --line_cnt2(0) -> LSB of line_cnt2 ( if(1) == 0000 0001 / if(2) == 0000 0010 )
      csm <= ODD_STATE;
    elsif(line_cnt2(0) = '0') then
      csm <= EVEN_STATE;
    else
      csm <= IDEL0_STATE;
    end if;  
end process;
----------------------------------------------------------------------------------

--sync----------------------------------------------------------------------------
process(rstn, sclk)
  begin
    if(rstn = '0') then
      w_data_buffer_1_d <= (others => '0');
      w_data_buffer_2_d <= (others => '0');
    elsif rising_edge(sclk) then
      w_data_buffer_1_d <= w_data_buffer_1;
      w_data_buffer_2_d <= w_data_buffer_2;
    end if;
  end process;
------------------------------------------------------------------------

--wrn,rdn timing select-------------------------------------------------
wrn_1 <= hsync_1 when ((csm = IDEL0_STATE) or (csm = EVEN_STATE)) else '0';
rdn_1 <= hsync_1 when ((csm = ODD_STATE)) else '0';
wrn_2 <= hsync_1 when ((csm = ODD_STATE)) else '0';
rdn_2 <= hsync_1 when ((csm = EVEN_STATE)) else '0';
------------------------------------------------------------------------

-----4 p_data_buffer ---------------------------------------------------
p_data_buffer4 <= w_data_buffer_1_d when ((csm = ODD_STATE)) else
                  w_data_buffer_2_d when ((csm = EVEN_STATE));
p_data_buffer2 <= r_data_buffer_1   when ((csm = ODD_STATE)) else
                  r_data_buffer_2   when ((csm = EVEN_STATE));

process(rstn,sclk)
  begin
  if(rstn = '0') then
    p_data_buffer3 <= (others => '0');
    p_data_buffer1 <= (others => '0');  
  elsif rising_edge(sclk) then
    p_data_buffer3 <= p_data_buffer4;
    p_data_buffer1 <= p_data_buffer2;
  end if;    
end process;
------------------------------------------------------------------------

--when processing start?-----------------------------------------------------------
--  hsync_1
--  hsync_2

csm1 <= IDEL_STATE when ((pixel_cnt3 = 0)   or  (pixel_cnt3 = 641)) else
        RGGB_STATE when ((csm = ODD_STATE)  and (pixel_cnt3(0) = '1')) else
        GRBG_STATE when ((csm = ODD_STATE)  and (pixel_cnt3(0) = '0')) else
        GBRG_STATE when ((csm = EVEN_STATE) and (pixel_cnt3(0) = '1')) else
        BGGR_STATE when ((csm = EVEN_STATE) and (pixel_cnt3(0) = '0')) else
        IDEL_STATE;

-- pixel_cnt3 1 ~ 640 => 640 pixel per line
-------------------------------------------------------------------------

---R,G,B data !----------------------------------------------------------

process(csm1)
  begin
  if(csm1 = IDEL_STATE) then
    R_temp <= (others => '0');
    G_temp <= (others => '0');
    B_temp <= (others => '0');
    output_sync  <=  '0';         
  elsif(csm1 = RGGB_STATE) then                                 --R(buffer1)
    R_temp <= p_data_buffer1;                                   --G(buffer2)
    G_temp <= ('0' & p_data_buffer2) + ('0' & p_data_buffer3);  --G(buffer3)
    B_temp <= p_data_buffer4;                                   --B(buffer4) STATE
    output_sync <= '1';                                              
  elsif(csm1 = GRBG_STATE) then                                 --G(buffer1)
    R_temp <= p_data_buffer2;                                   --R(buffer2)
    G_temp <= ('0' & p_data_buffer1) + ('0' & p_data_buffer4);  --G(buffer3)
    B_temp <= p_data_buffer3;                                   --B(buffer3) STATE
    output_sync <= '1';
  elsif(csm1 = GBRG_STATE) then                                 --G(buffer1)
    R_temp <= p_data_buffer3;                                   --B(buffer2)
    G_temp <= ('0' & p_data_buffer1) + ('0' & p_data_buffer4);  --R(buffer3)
    B_temp <= p_data_buffer2;                                   --G(buffer4) STATE
    output_sync <= '1';
  elsif(csm1 = BGGR_STATE) then                                 --B(buffer1)
    R_temp <= p_data_buffer4;                                   --G(buffer2)
    G_temp <= ('0' & p_data_buffer2) + ('0' & p_data_buffer3);  --G(buffer3)
    B_temp <= p_data_buffer1;                                   --R(buffer4) STATE
    output_sync <= '1';
  end if;    
end process;
  
-------------------------------------------------------------------------


--Data Ouput Mapping-----------------------------------------------------
data_r_o1 <= R_temp;
data_g_o1 <= G_temp(8 downto 1);
data_b_o1 <= B_temp;
-------------------------------------------------------------------------


------------Dpram Mapping -----------------------------------
u0 : sync_dpram
port map(         
            clk_l => sclk,   
            wrn => wrn_1,   
            waddr => w_addr_buffer_1,
            data_in => w_data_buffer_1,
            
            clk_r => sclk,   
            rdn => rdn_1,   
            raddr => r_addr_buffer_1,
            data_out => r_data_buffer_1   
);
-------------------------------------------------------------

-------Dpram Mapping-----------------------------------------
u1 : sync_dpram
port map(
            clk_l => sclk,   
            wrn => wrn_2,   
            waddr => w_addr_buffer_2,
            data_in => w_data_buffer_2,
            
            clk_r => sclk,   
            rdn => rdn_2,   
            raddr => r_addr_buffer_2,
            data_out => r_data_buffer_2  
);
-------------------------------------------------------------


end u_interpolation_2x2;


