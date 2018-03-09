library ieee;
use ieee.std_logic_1164.all;

ENTITY busmux41 IS
	GENERIC (
		width: integer := 32
	);

	PORT (
		data00:	IN std_logic_vector(width-1 downto 0);
		data01:	IN std_logic_vector(width-1 downto 0);
		data10:	IN std_logic_vector(width-1 downto 0);
		data11:	IN std_logic_vector(width-1 downto 0);
		sel: IN std_logic_vector(1 downto 0);
		output: OUT std_logic_vector(width-1 downto 0)
	);
END busmux41;

ARCHITECTURE multiplexer OF busmux41 IS
	COMPONENT busmux21 IS
		GENERIC (
			width: integer := 32
		);

		PORT (
			data0:	IN std_logic_vector(width-1 downto 0);
			data1:	IN std_logic_vector(width-1 downto 0);
			sel:	IN std_logic;
			output:	OUT std_logic_vector(width-1 downto 0)
		);
	END COMPONENT;

	SIGNAL opt0, opt1: std_logic_vector(width-1 downto 0);

BEGIN
	muxa: busmux21 GENERIC MAP (width => width)
	PORT MAP (
		data0 => data00,
		data1 => data01,
		sel => sel(0),
		output => opt0
	);

	muxb: busmux21 GENERIC MAP (width => width)
	PORT MAP (
		data0 => data10,
		data1 => data11,
		sel => sel(0),
		output => opt1
	);

	mux_out: busmux21 GENERIC MAP (width => width)
	PORT MAP (
		data0 => opt0,
		data1 => opt1,
		sel => sel(1),
		output => output
	);
END multiplexer;
