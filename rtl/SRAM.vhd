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
-- Module Name: SFIFO
--
-- Description: This entity is a generic FIFO block
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
use ieee.math_real.all;
use ieee.numeric_std.all;

entity SRAM is
generic (
    DWIDTH      : natural := 32;
    AWIDTH      : natural := 7;
    BYPASS      : natural := 1;
    STYLE       : string  := "distributed"
);
port (
    CLK         : in  std_logic;
    WE          : in  std_logic;
    WA          : in  std_logic_vector (AWIDTH-1 downto 0);
    DIN         : in  std_logic_vector (DWIDTH-1 downto 0);
    RA          : in  std_logic_vector (AWIDTH-1 downto 0);          
    DOUT        : out std_logic_vector (DWIDTH-1 downto 0)
);
end SRAM;

architecture arch of SRAM is

constant DEPTH : natural := (natural(real(2**AWIDTH)));

type ram_t is array (0 to DEPTH-1) of std_logic_vector (DWIDTH-1 downto 0);
signal mem : ram_t := (others => (others => '0'));
attribute ram_style : string; 
attribute ram_style of mem : signal is STYLE;
signal mem_dout : std_logic_vector (DWIDTH-1 downto 0) := (others => '0');
signal r_mem_dout : std_logic_vector (DWIDTH-1 downto 0) := (others => '0');

begin

-- hook up output
DOUT <= mem_dout;

WR: process
begin
    wait until rising_edge(CLK);
    if WE = '1' then
        mem(to_integer(unsigned(WA))) <= DIN;
    end if;
end process;

RD_BYPASS: if BYPASS > 0 generate
    process
    begin
        wait until rising_edge(CLK);
        mem_dout <= mem(to_integer(unsigned(RA)));
    end process;
end generate;

RD: if BYPASS = 0 generate
    mem_dout <= mem(to_integer(unsigned(RA)));
end generate;

end arch;
