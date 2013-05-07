--
-- Copyright (C) 2013 Chris McClelland
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
--
-- You should have received a copy of the GNU Lesser General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
library ieee;

use ieee.std_logic_1164.all;

entity top_level is
	port (
		sysClk_in : in  std_logic;
		sw_in     : in  std_logic_vector(2 downto 0);
		hsync_out : out std_logic;
		vsync_out : out std_logic;
		rgb_out   : out std_logic_vector(2 downto 0)
	);
end entity;

architecture rtl of top_level is
	signal rgb_sync : std_logic_vector(2 downto 0) := "000";
	signal vidOn    : std_logic;
begin
	-- Instantiate VGA sync circuit
	vga_sync: entity work.vga_sync
		port map(
			sysClk_in  => sysClk_in,
			hsync_out  => hsync_out,
			vsync_out  => vsync_out,
			vidOn_out  => vidOn,
			pixClk_out => open,
			pixX_out   => open,
			pixY_out   => open
		);
	
	-- rgb buffer
	process(sysClk_in)
	begin
		if ( rising_edge(sysClk_in) ) then
			rgb_sync <= sw_in;
		end if;
	end process;
	rgb_out <= rgb_sync when vidOn = '1' else "000";
end architecture;
