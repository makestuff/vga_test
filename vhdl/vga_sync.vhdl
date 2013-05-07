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

entity vga_sync is
	generic(
		-- Horizontal parameters (numbers are pixClk counts)
		HORIZ_DISP : integer := 640;  -- display area
		HORIZ_FP   : integer := 16;   -- front porch
		HORIZ_RT   : integer := 96;   -- beam retrace
		HORIZ_BP   : integer := 48;   -- back porch

		-- Vertical parameters (in line counts)
		VERT_DISP  : integer := 480;  -- display area
		VERT_FP    : integer := 10;   -- front porch
		VERT_RT    : integer := 2;    -- beam retrace
		VERT_BP    : integer := 31    -- back porch
	);
	port(
		sysClk_in  : in std_logic;
		hsync_out  : out std_logic;
		vsync_out  : out std_logic;
		vidOn_out  : out std_logic;
		pixClk_out : out std_logic;
		pixX_out   : out std_logic_vector (9 downto 0);
		pixY_out   : out std_logic_vector (9 downto 0)
	);
end vga_sync;

architecture arch of vga_sync is
	-- Pixel clock: sysClk/2 = 25MHz
	signal pixClk      : std_logic := '0';
	signal pixClk_next : std_logic;
	
	-- Line & pixel counters
	signal vCount      : unsigned(9 downto 0) := (others => '0');
	signal vCount_next : unsigned(9 downto 0);
	signal hCount      : unsigned(9 downto 0) := (others => '0');
	signal hCount_next : unsigned(9 downto 0);
	
	-- Registered horizontal & vertical sync signals
	signal vSync       : std_logic := '1';
	signal vSync_next  : std_logic;
	signal hSync       : std_logic := '1';
	signal hSync_next  : std_logic;
	
	-- End-of-line/screen flags
	signal hEnd        : std_logic;
	signal vEnd        : std_logic;
begin
	-- Registers
	process(sysClk_in)
	begin
		if ( rising_edge(sysClk_in) ) then
			pixClk <= pixClk_next;
			vCount <= vCount_next;
			hCount <= hCount_next;
			vSync <= vSync_next;
			hSync <= hSync_next;
		end if;
	end process;

	-- Generate 25MHz pixel clock
	pixClk_next <= not pixClk;
	
	-- End-of-line flag
	hEnd <=  -- end of horizontal counter
		'1' when hCount = (HORIZ_DISP + HORIZ_FP + HORIZ_BP + HORIZ_RT - 1) --799
		else '0';

	-- End-of-screen flag
	vEnd <=  -- end of vertical counter
		'1' when vCount = (VERT_DISP + VERT_FP + VERT_BP + VERT_RT - 1) --524
		else '0';
	
	-- Horizontal sync counter: 0-799
	process(hCount, hEnd, pixClk)
	begin
		if ( pixClk = '1' ) then
			if ( hEnd = '1' ) then
				hCount_next <= (others => '0');
			else
				hCount_next <= hCount + 1;
			end if;
		else
			hCount_next <= hCount;
		end if;
	end process;
	
	-- Vertical sync counter: 0-524
	process(vCount, hEnd, vEnd, pixClk)
	begin
		if ( pixClk = '1' and hEnd = '1' ) then
			if ( vEnd = '1' ) then
				vCount_next <= (others => '0');
			else
				vCount_next <= vCount + 1;
			end if;
		else
			vCount_next <= vCount;
		end if;
	end process;
	
	-- Registered horizontal and vertical syncs
	hSync_next <=
		'1' when (hCount >= (HORIZ_DISP + HORIZ_FP))
		     and (hCount <= (HORIZ_DISP + HORIZ_FP + HORIZ_RT - 1)) else
		'0';

	vSync_next <=
		'1' when (vCount >= (VERT_DISP + VERT_FP))
		     and (vCount <= (VERT_DISP + VERT_FP + VERT_RT - 1)) else
		'0';
	
	-- Video on/off
	vidOn_out <=
		'1' when (hCount < HORIZ_DISP) and (vCount < VERT_DISP) else
		'0';
	
	-- Drive output signals
	hSync_out <= hSync;
	vSync_out <= vSync;
	pixX_out <= std_logic_vector(hCount);
	pixY_out <= std_logic_vector(vCount);
	pixClk_out <= pixClk;
end arch;
