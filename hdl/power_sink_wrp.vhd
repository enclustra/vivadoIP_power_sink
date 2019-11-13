------------------------------------------------------------------------------
--  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

library work;
	use work.psi_common_math_pkg.all;
	use work.psi_common_array_pkg.all;

------------------------------------------------------------------------------
-- Entity
------------------------------------------------------------------------------	
entity power_sink_wrp is
	generic
	(	
		-- Power Sink Parameters (defaults are choosen small for quick test synthesis)
		FlipFlogs_g	: positive range 64 to 214783647	:= 128;
		SrlSize_g	: positive range 4 to 214783647		:= 32;		-- Use 32 for 7Series one SRL per FF
		SrlCount_g	: positive range 4 to 214783647		:= 32;
		BramDepth_g	: positive range 4 to 214783647 	:= 1024;
		BramWidth_g	: positive range 4 to 63 			:= 18;
		BramCount_g	: positive range 4 to 214783647	  	:= 4;

		
		-- AXI Parameters
		C_S00_AXI_ID_WIDTH          : integer := 1					-- Width of ID for for write address, write data, read address and read data
	);
	port
	(
		-----------------------------------------------------------------------------
		-- Power Sink Clock
		-----------------------------------------------------------------------------	
		ClkPowerSink				: in	std_logic;
	
		-----------------------------------------------------------------------------
		-- Axi Slave Bus Interface
		-----------------------------------------------------------------------------
		-- System
		s00_axi_aclk                : in    std_logic;                                             -- Global Clock Signal
		s00_axi_aresetn             : in    std_logic;                                             -- Global Reset Signal. This signal is low active.
		-- Read address channel
		s00_axi_arid                : in    std_logic_vector(C_S00_AXI_ID_WIDTH-1   downto 0);     -- Read address ID. This signal is the identification tag for the read address group of signals.
		s00_axi_araddr              : in    std_logic_vector(7 downto 0);                          -- Read address. This signal indicates the initial address of a read burst transaction.
		s00_axi_arlen               : in    std_logic_vector(7 downto 0);                          -- Burst length. The burst length gives the exact number of transfers in a burst
		s00_axi_arsize              : in    std_logic_vector(2 downto 0);                          -- Burst size. This signal indicates the size of each transfer in the burst
		s00_axi_arburst             : in    std_logic_vector(1 downto 0);                          -- Burst type. The burst type and the size information, determine how the address for each transfer within the burst is calculated.
		s00_axi_arlock              : in    std_logic;                                             -- Lock type. Provides additional information about the atomic characteristics of the transfer.
		s00_axi_arcache             : in    std_logic_vector(3 downto 0);                          -- Memory type. This signal indicates how transactions are required to progress through a system.
		s00_axi_arprot              : in    std_logic_vector(2 downto 0);                          -- Protection type. This signal indicates the privilege and security level of the transaction, and whether the transaction is a data access or an instruction access.
		s00_axi_arvalid             : in    std_logic;                                             -- Write address valid. This signal indicates that the channel is signaling valid read address and control information.
		s00_axi_arready             : out   std_logic;                                             -- Read address ready. This signal indicates that the slave is ready to accept an address and associated control signals.
		-- Read data channel
		s00_axi_rid                 : out   std_logic_vector(C_S00_AXI_ID_WIDTH-1 downto 0);       -- Read ID tag. This signal is the identification tag for the read data group of signals generated by the slave.
		s00_axi_rdata               : out   std_logic_vector(31 downto 0);                         -- Read Data
		s00_axi_rresp               : out   std_logic_vector(1 downto 0);                          -- Read response. This signal indicates the status of the read transfer.
		s00_axi_rlast               : out   std_logic;                                             -- Read last. This signal indicates the last transfer in a read burst.
		s00_axi_rvalid              : out   std_logic;                                             -- Read valid. This signal indicates that the channel is signaling the required read data.
		s00_axi_rready              : in    std_logic;                                             -- Read ready. This signal indicates that the master can accept the read data and response information.
		-- Write address channel
		s00_axi_awid                : in    std_logic_vector(C_S00_AXI_ID_WIDTH-1   downto 0);     -- Write Address ID
		s00_axi_awaddr              : in    std_logic_vector(7 downto 0);                          -- Write address
		s00_axi_awlen               : in    std_logic_vector(7 downto 0);                          -- Burst length. The burst length gives the exact number of transfers in a burst
		s00_axi_awsize              : in    std_logic_vector(2 downto 0);                          -- Burst size. This signal indicates the size of each transfer in the burst
		s00_axi_awburst             : in    std_logic_vector(1 downto 0);                          -- Burst type. The burst type and the size information, determine how the address for each transfer within the burst is calculated.
		s00_axi_awlock              : in    std_logic;                                             -- Lock type. Provides additional information about the atomic characteristics of the transfer.
		s00_axi_awcache             : in    std_logic_vector(3 downto 0);                          -- Memory type. This signal indicates how transactions are required to progress through a system.
		s00_axi_awprot              : in    std_logic_vector(2 downto 0);                          -- Protection type. This signal indicates the privilege and security level of the transaction, and whether the transaction is a data access or an instruction access.
		s00_axi_awvalid             : in    std_logic;                                             -- Write address valid. This signal indicates that the channel is signaling valid write address and control information.
		s00_axi_awready             : out   std_logic;                                             -- Write address ready. This signal indicates that the slave is ready to accept an address and associated control signals.
		-- Write data channel
		s00_axi_wdata               : in    std_logic_vector(31    downto 0);                      -- Write Data
		s00_axi_wstrb               : in    std_logic_vector(3 downto 0);                          -- Write strobes. This signal indicates which byte lanes hold valid data. There is one write strobe bit for each eight bits of the write data bus.
		s00_axi_wlast               : in    std_logic;                                             -- Write last. This signal indicates the last transfer in a write burst.
		s00_axi_wvalid              : in    std_logic;                                             -- Write valid. This signal indicates that valid write data and strobes are available.
		s00_axi_wready              : out   std_logic;                                             -- Write ready. This signal indicates that the slave can accept the write data.
		-- Write response channel
		s00_axi_bid                 : out   std_logic_vector(C_S00_AXI_ID_WIDTH-1 downto 0);       -- Response ID tag. This signal is the ID tag of the write response.
		s00_axi_bresp               : out   std_logic_vector(1 downto 0);                          -- Write response. This signal indicates the status of the write transaction.
		s00_axi_bvalid              : out   std_logic;                                             -- Write response valid. This signal indicates that the channel is signaling a valid write response.
		s00_axi_bready              : in    std_logic                                              -- Response ready. This signal indicates that the master can accept a write response.		
	);

end entity power_sink_wrp;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture rtl of power_sink_wrp is 

	-- Array of desired number of chip enables for each address range
	constant USER_SLV_NUM_REG               : integer              := 32; 
	
	-- IP Interconnect (IPIC) signal declarations
	signal reg_rd                    		: std_logic_vector(USER_SLV_NUM_REG-1 downto  0);
	signal reg_rdata                 		: t_aslv32(0 to USER_SLV_NUM_REG-1) := (others => (others => '0'));
	signal reg_wr                    		: std_logic_vector(USER_SLV_NUM_REG-1 downto  0);
	signal reg_wdata                 		: t_aslv32(0 to USER_SLV_NUM_REG-1);	
	
	-- Ohter Signals 
	signal AxiRst							: std_logic;
	signal RstPowerSink						: std_logic;
	signal EnaFf							: std_logic;
	signal EnaSrl							: std_logic;
	signal EnaBram							: std_logic;
	signal EnaGlobal						: std_logic;
	signal PatternFf						: std_logic_vector(31 downto 0);
	signal PatternSrl						: std_logic_vector(31 downto 0);
	signal PatternBram						: std_logic_vector(31 downto 0);
	signal PatternSetFf						: std_logic;
	signal PatternSetSrl					: std_logic;
	signal PatternSetBram					: std_logic;
	signal PatternOutFf						: std_logic_vector(31 downto 0);
	signal PatternOutSrl					: std_logic;
	signal PatternOutBramA					: std_logic_vector(31 downto 0);
	signal PatternOutBramB					: std_logic_vector(31 downto 0);
	signal EnaFfLocal						: std_logic;
	signal EnaSrlLocal						: std_logic;
	signal EnaBramLocal						: std_logic;
	
	constant RegResetVal_c : t_aslv32(0 to 6) := (	X"00000001", X"00000001",  X"00000001", 	-- All generators enabled by default
                                                    X"00000001",                                -- Global enable is set by default
                                                    X"AAAAAAAA", X"AAAAAAAA",  X"AAAAAAAA");    -- Default pattern is all A's    (always toggle)
	

begin

	AxiRst <= not s00_axi_aresetn;

   -----------------------------------------------------------------------------
   -- AXI decode instance
   -----------------------------------------------------------------------------
   axi_slave_reg_inst : entity work.psi_common_axi_slave_ipif
   generic map
   (
	  -- Reset Values
	  ResetVal_g						   => RegResetVal_c,	-- Default pattern is all A's	(always toggle)
												
      -- Users parameters
      NumReg_g                             => USER_SLV_NUM_REG,
      UseMem_g                             => false,
      -- Parameters of Axi Slave Bus Interface
      AxiIdWidth_g                         => C_S00_AXI_ID_WIDTH,
      AxiAddrWidth_g                       => 8
   )
   port map
   (
      --------------------------------------------------------------------------
      -- Axi Slave Bus Interface
      --------------------------------------------------------------------------
      -- System
      s_axi_aclk                  => s00_axi_aclk,
      s_axi_aresetn               => s00_axi_aresetn,
      -- Read address channel
      s_axi_arid                  => s00_axi_arid,
      s_axi_araddr                => s00_axi_araddr,
      s_axi_arlen                 => s00_axi_arlen,
      s_axi_arsize                => s00_axi_arsize,
      s_axi_arburst               => s00_axi_arburst,
      s_axi_arlock                => s00_axi_arlock,
      s_axi_arcache               => s00_axi_arcache,
      s_axi_arprot                => s00_axi_arprot,
      s_axi_arvalid               => s00_axi_arvalid,
      s_axi_arready               => s00_axi_arready,
      -- Read data channel
      s_axi_rid                   => s00_axi_rid,
      s_axi_rdata                 => s00_axi_rdata,
      s_axi_rresp                 => s00_axi_rresp,
      s_axi_rlast                 => s00_axi_rlast,
      s_axi_rvalid                => s00_axi_rvalid,
      s_axi_rready                => s00_axi_rready,
      -- Write address channel
      s_axi_awid                  => s00_axi_awid,
      s_axi_awaddr                => s00_axi_awaddr,
      s_axi_awlen                 => s00_axi_awlen,
      s_axi_awsize                => s00_axi_awsize,
      s_axi_awburst               => s00_axi_awburst,
      s_axi_awlock                => s00_axi_awlock,
      s_axi_awcache               => s00_axi_awcache,
      s_axi_awprot                => s00_axi_awprot,
      s_axi_awvalid               => s00_axi_awvalid,
      s_axi_awready               => s00_axi_awready,
      -- Write data channel
      s_axi_wdata                 => s00_axi_wdata,
      s_axi_wstrb                 => s00_axi_wstrb,
      s_axi_wlast                 => s00_axi_wlast,
      s_axi_wvalid                => s00_axi_wvalid,
      s_axi_wready                => s00_axi_wready,
      -- Write response channel
      s_axi_bid                   => s00_axi_bid,
      s_axi_bresp                 => s00_axi_bresp,
      s_axi_bvalid                => s00_axi_bvalid,
      s_axi_bready                => s00_axi_bready,
      --------------------------------------------------------------------------
      -- Register Interface
      --------------------------------------------------------------------------
      o_reg_rd                    => reg_rd,
      i_reg_rdata                 => reg_rdata,
      o_reg_wr                    => reg_wr,
      o_reg_wdata                 => reg_wdata
   );
   
    -----------------------------------------------------------------------------
	-- Register Bank
	-----------------------------------------------------------------------------
	reg_rdata(0)(0)	<= reg_wdata(0)(0);		-- FF enable
	reg_rdata(1)(0)	<= reg_wdata(1)(0);		-- SRL enable
	reg_rdata(2)(0)	<= reg_wdata(2)(0);		-- BRAM enable
	reg_rdata(3)(0)	<= reg_wdata(3)(0);		-- Global enable
	
	reg_rdata(4)	<= reg_wdata(4);		-- FF pattern
	reg_rdata(5)	<= reg_wdata(5);		-- SRL pattern
	reg_rdata(6)	<= reg_wdata(5);		-- BRAM pattern
   
  	-----------------------------------------------------------------------------
	-- Clock Crossing
	----------------------------------------------------------------------------- 
	i_cc_to_sink : entity work.psi_common_status_cc
		generic map (
			DataWidth_g		=> 4
		)
		port map (
			ClkA		=> s00_axi_aclk,
			RstInA		=> AxiRst,
			DataA(0)	=> reg_wdata(0)(0),
			DataA(1)	=> reg_wdata(1)(0),
			DataA(2)	=> reg_wdata(2)(0),
			DataA(3)	=> reg_wdata(3)(0),
			ClkB		=> ClkPowerSink,
			RstInB		=> '0',
			RstOutB		=> RstPowerSink,
			DataB(0)	=> EnaFf,
			DataB(1)	=> EnaSrl,
			DataB(2)	=> EnaBram,
			DataB(3)	=> EnaGlobal
		);
		
	i_cc_from_sink : entity work.psi_common_status_cc
		generic map (
			DataWidth_g		=> 97
		)
		port map (
			ClkA				=> ClkPowerSink,
			RstInA				=> '0',
			DataA(31 downto 0)	=> PatternOutFf,
			DataA(32)			=> PatternOutSrl,
			DataA(64 downto 33)	=> PatternOutBramA,
			DataA(96 downto 65)	=> PatternOutBramB,
			ClkB				=> s00_axi_aclk,
			RstInB				=> AxiRst,
			DataB(31 downto 0)	=> reg_rdata(8),		-- Outputs are fed to registers only to prevent optimization!
			DataB(32)			=> reg_rdata(9)(0),		-- Outputs are fed to registers only to prevent optimization!
			DataB(64 downto 33)	=> reg_rdata(10),		-- Outputs are fed to registers only to prevent optimization!
			DataB(96 downto 65)	=> reg_rdata(11)		-- Outputs are fed to registers only to prevent optimization!
		);
		
	i_cc_pattern_ff : entity work.psi_common_simple_cc
		generic map (
			DataWidth_g		=> 32
		)
		port map (
			ClkA		=> s00_axi_aclk,
			RstInA		=> AxiRst,
			DataA		=> reg_wdata(4),
			VldA		=> reg_wr(4),
			ClkB		=> ClkPowerSink,
			RstInB		=> '0',
			DataB		=> PatternFf,
			VldB		=> PatternSetFf
		);
		
	i_cc_pattern_srl : entity work.psi_common_simple_cc
		generic map (
			DataWidth_g		=> 32
		)
		port map (
			ClkA		=> s00_axi_aclk,
			RstInA		=> AxiRst,
			DataA		=> reg_wdata(5),
			VldA		=> reg_wr(5),
			ClkB		=> ClkPowerSink,
			RstInB		=> '0',
			DataB		=> PatternSrl,
			VldB		=> PatternSetSrl
		);
		
	i_cc_pattern_bram : entity work.psi_common_simple_cc
		generic map (
			DataWidth_g		=> 32
		)
		port map (
			ClkA		=> s00_axi_aclk,
			RstInA		=> AxiRst,
			DataA		=> reg_wdata(6),
			VldA		=> reg_wr(6),
			ClkB		=> ClkPowerSink,
			RstInB		=> '0',
			DataB		=> PatternBram,
			VldB		=> PatternSetBram
		);
   
	-----------------------------------------------------------------------------
	-- Implementation
	----------------------------------------------------------------------------- 
	EnaFfLocal <= EnaFf and EnaGlobal;
	i_ff : entity work.power_sink_ff
		generic map (
			FlipFlogs_g	=> FlipFlogs_g
		)
		port map (
			Clk			=> ClkPowerSink,
			Rst			=> RstPowerSink,
			Enable		=> EnaFfLocal,
			PatternSet	=> PatternSetFf,
			PatternIn	=> PatternFf,
			PatternOut	=> PatternOutFf
		);
		
	EnaSrlLocal <= EnaSrl and EnaGlobal;
	i_srl : entity work.power_sink_srl
		generic map (
			SrlSize_g	=> SrlSize_g,
			SrlCount_g	=> SrlCount_g
		)
		port map (
			Clk			=> ClkPowerSink,
			Rst			=> RstPowerSink,
			Enable		=> EnaSrlLocal,
			PatternSet	=> PatternSetSrl,
			PatternIn	=> PatternSrl,
			PatternOut	=> PatternOutSrl
		);
		
	EnaBramLocal <= EnaBram and EnaGlobal;
	i_bram : entity work.power_sink_bram
		generic map (
			BramDepth_g	=> BramDepth_g,
			BramWidth_g	=> BramWidth_g,
			BramCount_g	=> BramCount_g,
			Behavior_g	=> "RBW"
		)
		port map (
			Clk			=> ClkPowerSink,
			Rst			=> RstPowerSink,
			Enable		=> EnaBram,
			PatternSet	=> PatternSetBram,
			PatternIn	=> PatternBram,
			PatternOutA	=> PatternOutBramA,
			PatternOutB	=> PatternOutBramB
		);
   
	
  
end rtl;
