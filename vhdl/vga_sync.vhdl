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
		pixClk_in  : in std_logic;
		hSync_out  : out std_logic;
		vSync_out  : out std_logic;
		pixX_out   : out unsigned(9 downto 0);
		pixY_out   : out unsigned(9 downto 0)
	);
end vga_sync;

architecture arch of vga_sync is
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
			vCount <= vCount_next;
			hCount <= hCount_next;
			vSync <= vSync_next;
			hSync <= hSync_next;
		end if;
	end process;

	-- End-of-line flag
	hEnd <=  -- end of horizontal counter
		'1' when hCount = (HORIZ_DISP + HORIZ_FP + HORIZ_BP + HORIZ_RT - 1) --799
		else '0';

	-- End-of-screen flag
	vEnd <=  -- end of vertical counter
		'1' when vCount = (VERT_DISP + VERT_FP + VERT_BP + VERT_RT - 1) --524
		else '0';

	hCount_next <=
		(others => '0') when pixClk_in = '1' and hEnd = '1' else
		hCount + 1      when pixClk_in = '1' and hEnd = '0' else
		hCount;

	vCount_next <=
		(others => '0') when pixClk_in = '1' and hEnd = '1' and vEnd = '1' else
		vCount + 1      when pixClk_in = '1' and hEnd = '1' and vEnd = '0' else
		vCount;
	
	-- Registered horizontal and vertical syncs
	hSync_next <=
		'1' when (hCount >= HORIZ_DISP + HORIZ_FP) and (hCount < HORIZ_DISP + HORIZ_FP + HORIZ_RT)
		else '0';

	vSync_next <=
		'1' when (vCount >= VERT_DISP + VERT_FP) and (vCount < VERT_DISP + VERT_FP + VERT_RT)
		else '0';
	
	-- Drive output signals
	hSync_out <= hSync;
	vSync_out <= vSync;
	pixX_out <= hCount;
	pixY_out <= vCount;
end arch;
