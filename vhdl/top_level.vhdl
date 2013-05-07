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
use ieee.numeric_std.all;

entity top_level is
	port (
		sysClk_in : in  std_logic;
		sw_in     : in  std_logic_vector(2 downto 0);
		hSync_out : out std_logic;
		vSync_out : out std_logic;
		rgb_out   : out std_logic_vector(2 downto 0)
	);
end entity;

architecture rtl of top_level is
	signal rgb_sync : std_logic_vector(2 downto 0) := "000";
	signal pixClk   : std_logic := '0';
	signal pixX     : unsigned(9 downto 0);
	signal pixY     : unsigned(9 downto 0);
	signal locked   : std_logic;
	signal reset    : std_logic;
	constant HRES   : integer := 640;
	constant VRES   : integer := 480;
	--constant VRES   : integer := 512;
begin
	-- Instantiate VGA sync circuit, driven with the 25MHz pixel clock
	vga_sync: entity work.vga_sync
		generic map (
			-- Horizontal parameters (numbers are pixel clock counts)
			HORIZ_DISP => HRES,
			HORIZ_FP   => 16,
			HORIZ_RT   => 96,
			HORIZ_BP   => 48,

			-- Vertical parameters (in line counts)
			VERT_DISP  => VRES,
			VERT_FP    => 10,  -- 640x480 @ 60Hz
			VERT_RT    => 2,
			VERT_BP    => 29
			--VERT_FP    => 45,  -- 640x512 @ 50Hz
			--VERT_RT    => 2,
			--VERT_BP    => 66
		)
		port map(
			clk_in     => pixClk,
			reset_in   => reset,
			hSync_out  => hSync_out,
			vSync_out  => vSync_out,
			pixX_out   => pixX,
			pixY_out   => pixY
		);

	-- Generate the 25MHz pixel clock from the main 50MHz crystal
	clk_gen: entity work.clk_gen
		port map(
			CLKIN_IN        => sysClk_in,
			CLKDV_OUT       => pixClk,
			CLKIN_IBUFG_OUT => open,
			CLK0_OUT        => open,
			LOCKED_OUT      => locked
		);

	-- Synchronise RGB switch inputs
	process(pixClk)
	begin
		if ( rising_edge(pixClk) ) then
			rgb_sync <= sw_in;
		end if;
	end process;

	-- We're in reset until the DLL locks on
	reset <= not(locked);

	-- Set the visible area to the chosen colour, and the borders to black
	rgb_out <=
		rgb_sync when pixX < HRES and pixY < VRES
		else "000";
end architecture;
