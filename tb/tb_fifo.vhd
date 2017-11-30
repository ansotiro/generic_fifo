----------------------------------------------------------------------------------
--                 ________  __       ___  _____        __     	
--                /_  __/ / / / ___  / _/ / ___/______ / /____ 	
--                 / / / /_/ / / _ \/ _/ / /__/ __/ -_) __/ -_)	
--                /_/  \____/  \___/_/   \___/_/  \__/\__/\__/ 	
--			                                        
----------------------------------------------------------------------------------
--
-- Author(s): 	ansotiropoulos
--
-- Design Name: generic_fifo
-- Module Name: tb_fifo
--
-- Description: Testbench for generic FIFO
--
-- Copyright:   (C) 2016 Microprocessor & Hardware Lab, TUC
--
-- This source file is free software; you can redistribute it and/or modify 
-- it under the terms of the GNU Lesser General Public License as published 
-- by the Free Software Foundation; either version 2.1 of the License, or 
-- (at your option) any later version.
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;
 
entity tb_fifo is
end tb_fifo;
 
architecture tb of tb_fifo is 

component SFIFO
generic (
WIDTH           : natural := 32;
DEPTH           : natural := 128;
PFULL_A         : natural := 64;
PFULL_N         : natural := 4;
PEMPTY_A        : natural := 8;
PEMPTY_N        : natural := 4;
VALIDEN         : natural := 1;
DCOUNTEN        : natural := 1;
RAM_STYLE       : string  := "distributed"
);
port (
    CLK         : in  std_logic;
    RST         : in  std_logic;
    PUSH        : in  std_logic;
    POP         : in  std_logic;
    D           : in  std_logic_vector (31 downto 0);
    Q           : out std_logic_vector (31 downto 0);
    DATACNT     : out std_logic_vector (6 downto 0);
    FULL        : out std_logic;
    EMPTY       : out std_logic;
    PROG_FULL   : out std_logic;
    PROG_EMPTY  : out std_logic;
    VALID       : out std_logic
);
end component;

procedure printf_slv (dat : in std_logic_vector (31 downto 0); file f: text) is
    variable my_line : line;
begin
    write(my_line, CONV_INTEGER(dat));
    write(my_line, string'(" -   ("));
    write(my_line, now);
    write(my_line, string'(")"));
    writeline(f, my_line);
end procedure printf_slv;

procedure printf (dat : in std_logic; file f: text) is
    variable my_line : line;
begin
    write(my_line, dat);
    write(my_line, string'(" -   ("));
    write(my_line, now);
    write(my_line, string'(")"));
    writeline(f, my_line);
end procedure printf;

constant CLK_period : time := 10 ns;

signal CLK          : std_logic := '0';
signal RST          : std_logic := '0';
signal PUSH         : std_logic := '0';
signal POP          : std_logic := '0';
signal D            : std_logic_vector (31 downto 0) := (others => '0');
signal Q            : std_logic_vector (31 downto 0) := (others => '0');
signal DATACNT      : std_logic_vector (6 downto 0) := (others => '0');
signal FULL         : std_logic := '0';
signal EMPTY        : std_logic := '0';
signal PROG_FULL    : std_logic := '0';
signal PROG_EMPTY   : std_logic := '0';
signal VALID        : std_logic := '0';
signal data 	    : std_logic_vector (31 downto 0) := (others => '0');

file file_q 	    : text open WRITE_MODE is "out/test_dout.out";
file file_empty	    : text open WRITE_MODE is "out/test_empty.out";
file file_full	    : text open WRITE_MODE is "out/test_full.out";
file file_pempty    : text open WRITE_MODE is "out/test_pempty.out";
file file_pfull	    : text open WRITE_MODE is "out/test_pfull.out";


begin

FIFO: SFIFO
generic map (
	WIDTH       => 32,
	DEPTH       => 128,
	PFULL_A     => 65,
	PFULL_N     => 4,
	PEMPTY_A    => 5,
	PEMPTY_N    => 12,
	VALIDEN     => 1,
	DCOUNTEN    => 1,
 	RAM_STYLE   => "distributed"
)
port map (
    CLK         => CLK,
    RST         => RST,
    PUSH        => PUSH,
    POP         => POP,
    D           => D,
    Q           => Q,
    DATACNT     => DATACNT,
    FULL        => FULL,
    EMPTY       => EMPTY,
    PROG_FULL   => PROG_FULL,
    PROG_EMPTY  => PROG_EMPTY,
    VALID       => VALID
);


CLKP: process
begin
    CLK <= '0';
    wait for CLK_period/2;
    CLK <= '1';
    wait for CLK_period/2;
end process;

TRCE: process
begin
    wait until rising_edge(CLK);
    if VALID = '1' then
        printf_slv(Q, file_q);
        printf(EMPTY, file_empty);
        printf(FULL, file_full);
        printf(PROG_EMPTY, file_pempty);
        printf(PROG_FULL, file_pfull);
    end if;
end process;

SIMUL: process
begin

    wait until rising_edge(CLK);

    RST     <= '0';
    PUSH    <= '0';
    POP     <= '0';
    D       <= data;
    data    <= x"00000000";
    wait for 100 ns;

    RST     <= '1';
    wait for 100 ns;

    RST     <= '0';
    wait for 100 ns;

    for J in 1 to 40 loop

        for I in 1 to 4 loop
            PUSH    <= '1';
            POP     <= '0';
            data    <= data + 1;
            D       <= data;
            wait for 10 ns;
        end loop;

        for I in 1 to 3 loop
            PUSH    <= '1';
            POP     <= '1';
            data    <= data + 1;
            D       <= data;
            wait for 10 ns;
        end loop;

        for I in 1 to 4 loop
            PUSH    <= '0';
            POP     <= '0';
            data    <= data;
            D       <= data;
            wait for 10 ns;
        end loop;

        for I in 1 to 1 loop
            PUSH    <= '0';
            POP     <= '1';
            data    <= data;
            D       <= data;
            wait for 10 ns;
        end loop;

    end loop;

    for J in 1 to 40 loop
        for I in 1 to 5 loop
            PUSH    <= '0';
            POP     <= '1';
            data    <= data;
            D       <= data;
        wait for 10 ns;
        end loop;

        for I in 1 to 4 loop
            PUSH    <= '0';
            POP     <= '0';
            data    <= data;
            D       <= data;
        wait for 10 ns;
        end loop;
    end loop;

wait;
end process;

END;
