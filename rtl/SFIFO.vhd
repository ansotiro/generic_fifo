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
-- 1)           WIDTH indicates the width of words in bits, DEPTH indicates the
--              maximum #words that FIFO can store and RAM_STYLE (block/distributed)
--              indicates FPGA's resources that will be used to store the data.
--
-- 2)           PROG_FULL will assert when #words in fifo is greater than
--              or equal to PFULL_A and deassert when #words in fifo is 
--              less than PFULL_N. PFULL_A implies enable for PROG_FULL and
--              has to be greater than zero in case you want it in use.
--              Always set PFULL_A > PFULL_N.
--
-- 3)           PROG_EMPTY will assert when #words in fifo is less than
--              or equal to PEMPTY_A and deassert when #words in fifo is 
--              greater than PEMPTY_N. PEMPTY_N implies enable for PROG_EMPTY and
--              has to be greater than zero in case you want it in use.
--              Always set PEMPTY_A < PEMPTY_N.
--
-- 4)           VALIDEN parameter enables (>0) or disables (=0) the VALID.
--
-- 5)           Keep PROG_FULL, PROG_EMPTY or VALIDEN disabled if not needed
--		        for saving resources.
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
use ieee.math_real.all;
use ieee.numeric_std.all;

entity SFIFO is
generic (
    WIDTH       : natural := 32;
    DEPTH       : natural := 128;
    PFULL_A     : natural := 65;
    PFULL_N     : natural := 4;
    PEMPTY_A    : natural := 5;
    PEMPTY_N    : natural := 12;
    VALIDEN     : natural := 1;
    DCOUNTEN    : natural := 1;
    RAM_STYLE   : string  := "distributed"
);
Port (
    CLK         : in  std_logic;
    RST         : in  std_logic;
    PUSH        : in  std_logic;
    POP         : in  std_logic;
    D           : in  std_logic_vector (WIDTH-1 downto 0);
    Q           : out std_logic_vector (WIDTH-1 downto 0);
    DATACNT     : out std_logic_vector (natural(ceil(log2(real(DEPTH))))-1 downto 0);
    FULL        : out std_logic;
    EMPTY       : out std_logic;
    PROG_FULL   : out std_logic;
    PROG_EMPTY  : out std_logic;
    VALID       : out std_logic
);
end SFIFO;

architecture arch of SFIFO is

component SRAM
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
end component;

constant c_log_depth    : natural := (natural(ceil(log2(real(DEPTH)))));

signal r_wr_ptr         : std_logic_vector (c_log_depth downto 0) := (others => '0');
signal r_rd_ptr 	    : std_logic_vector (c_log_depth downto 0) := (others => '0');
signal r_q              : std_logic_vector (WIDTH-1 downto 0) := (others => '0');

signal c_full           : std_logic := '0';
signal c_empty          : std_logic := '0';
signal c_vld            : std_logic := '0';

signal pop_en           : std_logic := '0';
signal push_en          : std_logic := '0';

signal c_prog_full_a    : std_logic := '0';
signal c_prog_full_n    : std_logic := '0';
signal c_prog_full      : std_logic := '0';

signal pfull_sel_en     : std_logic := '0';
signal pfull_sel_out    : std_logic_vector (1 downto 0) := (others => '0');
signal pfull_sel_in     : std_logic_vector (1 downto 0) := (others => '0');

signal c_prog_empty_a   : std_logic := '0';
signal c_prog_empty_n   : std_logic := '0';
signal c_prog_empty     : std_logic := '0';

signal pempty_sel_en    : std_logic := '0';
signal pempty_sel_out   : std_logic_vector (1 downto 0) := (others => '0');
signal pempty_sel_in    : std_logic_vector (1 downto 0) := (others => '0');

signal dcount           : std_logic_vector (c_log_depth downto 0) := (others => '0');
signal cnt_en           : std_logic := '0';


begin

-- hook up outputs
Q           <= r_q;
DATACNT     <= dcount(c_log_depth-1 downto 0);
EMPTY       <= c_empty;
FULL        <= c_full;
VALID       <= c_vld;
PROG_FULL   <= c_prog_full;
PROG_EMPTY  <= c_prog_empty;


c_empty     <= '1' when r_wr_ptr = r_rd_ptr else '0';
c_full      <= '1' when ((r_rd_ptr(c_log_depth-1 downto 0)=r_wr_ptr(c_log_depth-1 downto 0)) 
                    and (r_rd_ptr(c_log_depth)/=r_wr_ptr(c_log_depth)) ) else '0';

pop_en      <= POP and (not c_empty);
push_en     <= PUSH and (not c_full);


RD: process
begin
    wait until rising_edge(CLK);
    
    if RST = '1' then
        r_rd_ptr <= (others => '0');
    else
        if pop_en = '1' then
            r_rd_ptr <= r_rd_ptr + 1;
        else
            r_rd_ptr <= r_rd_ptr;
        end if;
    end if;

end process;

WR: process
begin
    wait until rising_edge(CLK);
    
    if RST = '1' then
        r_wr_ptr <= (others => '0');
    else
        if push_en = '1' then
            r_wr_ptr <= r_wr_ptr + 1;
        else
            r_wr_ptr <= r_wr_ptr;
        end if;
    end if;
    
end process;

FIFO: SRAM
generic map (
    AWIDTH  => c_log_depth,
    DWIDTH  => WIDTH,
    BYPASS  => 1,
    STYLE   => "distributed"
)
port map (
    CLK     => CLK,
    WE      => push_en,
    WA      => r_wr_ptr(c_log_depth-1 downto 0),
    DIN     => D,
    RA      => r_rd_ptr(c_log_depth-1 downto 0),
    DOUT    => r_q
);


VLD: if VALIDEN = 1 generate
    process
    begin
        wait until rising_edge(CLK);
        c_vld <= pop_en;
    end process;
end generate;

CNT: if PFULL_A > 0 or PEMPTY_N > 0 or DCOUNTEN > 0 generate

    cnt_en <= POP xor PUSH;
    
    DCNT: process
    begin
        wait until rising_edge(CLK);
        if cnt_en = '1' then
            if PUSH = '1' then
                dcount <= dcount + '1';
            else
                dcount <= dcount - '1';
            end if;
        else
            dcount <= dcount;
        end if;
    end process;
    
end generate;

PF: if PFULL_A > 0 generate

    c_prog_full_a   <= '1' when dcount >= PFULL_A else '0';
    c_prog_full     <= c_prog_full_a when pfull_sel_out(0) = '1' else (not c_prog_full_n);
    pfull_sel_in    <= c_prog_full_a & (not c_prog_full_n);
    pfull_sel_en    <= c_prog_full_a or c_prog_full_n;
    
    process
    begin
        wait until rising_edge(CLK);
        if dcount < PFULL_N then
            c_prog_full_n <= '1';
        else
            c_prog_full_n <= '0';
        end if;
    end process;

    process
    begin
        wait until rising_edge(CLK);
        if RST = '1' then
            pfull_sel_out <= "00";
        else
            if pfull_sel_en = '1' then
                pfull_sel_out <= pfull_sel_in + 1;
            else
                pfull_sel_out <= pfull_sel_out;
            end if;
        end if;
    end process;
    
end generate;

PE: if PEMPTY_N > 0 generate

    c_prog_empty_n  <= '1' when dcount > PEMPTY_N else '0';
    c_prog_empty    <= c_prog_empty_a when pempty_sel_out(0) = '1' else (not c_prog_empty_n);
    pempty_sel_in   <= c_prog_empty_a & (not c_prog_empty_n);
    pempty_sel_en   <= c_prog_empty_a or c_prog_empty_n;

    process
    begin
        wait until rising_edge(CLK);
        if dcount <= PEMPTY_A then
            c_prog_empty_a <= '1';
        else
            c_prog_empty_a <= '0';
        end if;
    end process;
    
    process
    begin
        wait until rising_edge(CLK);
        if RST = '1' then
            pempty_sel_out <= "00";
        else
            if pempty_sel_en = '1' then
                pempty_sel_out <= pempty_sel_in + 1;
            else
                pempty_sel_out <= pempty_sel_out;
            end if;
        end if;
    end process;

end generate;

end arch;
