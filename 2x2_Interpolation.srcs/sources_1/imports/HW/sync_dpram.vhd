Library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity sync_dpram is
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
end sync_dpram;
 
architecture u_dpram of sync_dpram is

   type mem_tbl is array (0 to 640) of std_logic_vector( 7 downto 0);
   signal mem : mem_tbl;
 	
begin

   process (clk_l)
      variable I_A : natural;
   begin
      I_A := conv_integer (waddr);
      if rising_edge (clk_l) then
         if (wrn = '1') then
 	    mem (I_A) <= data_in;
 	 end if;
      end if;
   end process;
 	
   process(clk_r)
     variable I_A : natural;
   begin   
      I_A := conv_integer(raddr);
      if rising_edge (clk_r) then
         if (rdn = '1') then 
            data_out <= mem(I_A);
         else
            data_out <= (others=>'0');
         end if;
      end if;
   end process;

end u_dpram;
