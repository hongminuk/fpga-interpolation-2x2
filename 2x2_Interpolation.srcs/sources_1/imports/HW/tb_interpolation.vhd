
library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use STD.textio.all;
use ieee.std_logic_textio.all;


entity tb_interpolation is  
end tb_interpolation;

architecture u_tb_interpolation of tb_interpolation is

    component interpolation_2x2 is
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
    end component;



    signal  rstn      : std_logic;
    signal  clk       : std_logic;

    signal  pixel_cnt     : std_logic_vector(9 downto 0);
    signal  line_cnt      : std_logic_vector(9 downto 0);
    signal  line_cnt_inc  : std_logic;
    
    signal  vsync     : std_logic;
    signal  hsync     : std_logic;
    

    signal data_r_o1  : std_logic_vector(7 downto 0);
    signal data_g_o1  : std_logic_vector(7 downto 0);
    signal data_b_o1  : std_logic_vector(7 downto 0);  

    signal output_sync_tb : std_logic;
  
    signal image_data : std_logic_vector(7 downto 0);        
                      
--    file image_data_in  : text is IN  "../haha_image.txt";
    file image_data_in  : text is IN  "../haha_image.txt";
    file image_data_out : text is OUT "../2009141049_out.txt";
            


begin
  --rstn-------------------------------------------------
  process
  begin
    if (NOW = 0 ns) then
      rstn <= '0', '1' after 500 ns;
    end if;
    wait for 1 us;
  end process;
 -------------------------------------------------------
    
  --clk 25MHz--------------------------------------------
  process
  begin
    clk <= '0', '1' after 20 ns;
    wait for 40 ns;
  end process;
  -------------------------------------------------------
  
  -- pixel / line counter--------------------------------
  process (rstn, clk)
  begin
    if (rstn = '0') then
      pixel_cnt <= (others => '0');
    elsif rising_edge (clk) then
      if (pixel_cnt = 799) then
        pixel_cnt <= (others => '0');
      else
        pixel_cnt <= pixel_cnt + 1;
      end if;
    end if;
  end process;

  line_cnt_inc <= '1' when (pixel_cnt = 799) else '0';

  process (rstn, clk)
  begin
    if (rstn = '0') then
      line_cnt <= (others => '0');
    elsif rising_edge (clk) then
      
      if (line_cnt_inc = '1') then
        if (line_cnt = 524) then
          line_cnt <= (others => '0');
        else
          line_cnt <= line_cnt + 1;
        end if;
      end if;
    end if;
  end process;
    
  --------------------------------------------------------
    
    
    

  -- Sync Generator --------------------------------------

  hsync <= '1' when ((pixel_cnt >= 80) and (pixel_cnt <= 720)) else '0';
  vsync <= '1' when ((line_cnt  >=  22) and (line_cnt <= 502)) else '0';
    
  --------------------------------------------------------


  --TEXT_IN-------------------------------------------------

  process(rstn, clk)
    variable I_LINE : line;
    variable I_CODE : std_logic_vector( 7 downto 0);
  begin
    if(rstn = '0') then
      image_data  <=  I_CODE;
    elsif rising_edge (clk) then
      if ((vsync = '1') and (hsync = '1')) then
        readline  (image_data_in, I_LINE);
        hread     (I_LINE,        I_CODE);
        
        image_data  <=  I_CODE;
      else
        image_data  <=  (others => '0');
      end if;
    end if;  
  end process;
  
  -----------------------------------------------------------
  
  
  
  --TEXT_OUT-------------------------------------------------
  
  process(rstn, clk)
    
    variable O_LINE : line;
    variable O_CODE : std_logic_vector( 7 downto 0);
  
  begin
    if(rstn = '0') then
    
    elsif rising_edge (clk) then
      if(output_sync_tb = '1') then
        O_CODE  :=  data_r_o1;                
        hwrite (O_LINE, O_CODE, left, 3);
    
        O_CODE  :=  data_g_o1;
        hwrite (O_LINE, O_CODE, left, 3);
        
        O_CODE  :=  data_b_o1;
        hwrite (O_LINE, O_CODE, left, 2);
        
        writeline(image_data_out, O_LINE);
      end if;
    end if;  
  end process;
  
  -----------------------------------------------------------


u0 : interpolation_2x2
port map(
            rstn => rstn,   
            sclk => clk,   
            data => image_data,
            vsync => vsync,
            hsync => hsync,        
            
            output_sync => output_sync_tb,
            
            data_r_o1 => data_r_o1,  
            data_g_o1 => data_g_o1,
            data_b_o1 => data_b_o1
);




end u_tb_interpolation;













