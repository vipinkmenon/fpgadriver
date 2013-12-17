//--------------------------------------------------------------------------------
// Project    : SWITCH
// File       : ethernet_controller.v
// Version    : 0.2
// Author     : Shreejith S
//
// Description: Ethernet Controller Module
//
//--------------------------------------------------------------------------------
// (c) Copyright 2004-2011 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
// Description:  This is the Verilog example design for the Virtex-6
//               Embedded Tri-Mode Ethernet MAC. It is intended that this
//               example design can be quickly adapted and downloaded onto
//               an FPGA to provide a real hardware test environment.
//
//               This level:
//
//               * Instantiates the FIFO Block wrapper, containing the
//                 block level wrapper and an RX and TX FIFO with an
//                 AXI-S interface;
//
//               * Instantiates a simple AXI-S example design,
//                 providing an address swap and a simple
//                 loopback function;
//
//               * Instantiates transmitter clocking circuitry
//                   -the User side of the FIFOs are clocked at gtx_clk
//                    at all times
//
//
//               * Serializes the Statistics vectors to prevent logic being
//                 optimized out
//
//               * Ties unused inputs off to reduce the number of IO
//
//               Please refer to the Datasheet, Getting Started Guide, and
//               the Virtex-6 Embedded Tri-Mode Ethernet MAC User Gude for
//               further information.
//
//
//    ---------------------------------------------------------------------
//    | EXAMPLE DESIGN WRAPPER                                            |
//    |           --------------------------------------------------------|
//    |           |FIFO BLOCK WRAPPER                                     |
//    |           |                                                       |
//    |           |                                                       |
//    |           |              -----------------------------------------|
//    |           |              | BLOCK LEVEL WRAPPER                    |
//    |           |              |    ---------------------               |
//    |           |              |    |   V6 EMAC CORE    |               |
//    |           |              |    |                   |               |
//    |           |              |    |                   |               |
//    |           |              |    |                   |               |
//    |           |              |    |                   |               |
//    | --------  |  ----------  |    |                   |               |
//    | |      |  |  |        |  |    |                   |  ---------    |
//    | |      |->|->|        |--|--->| Tx            Tx  |--|       |--->|
//    | |      |  |  |        |  |    | AXI-S         PHY |  |       |    |
//    | | ADDR |  |  |        |  |    | I/F           I/F |  |       |    |
//    | | SWAP |  |  |  AXI-S |  |    |                   |  | PHY   |    |
//    | |      |  |  |  FIFO  |  |    |                   |  | I/F   |    |
//    | |      |  |  |        |  |    |                   |  |       |    |
//    | |      |  |  |        |  |    | Rx            Rx  |  |       |    |
//    | |      |  |  |        |  |    | AX)-S         PHY |  |       |    |
//    | |      |<-|<-|        |<-|----| I/F           I/F |<-|       |<---|
//    | |      |  |  |        |  |    |                   |  ---------    |
//    | --------  |  ----------  |    ---------------------               |
//    |           |              |                                        |
//    |           |              -----------------------------------------|
//    |           --------------------------------------------------------|
//    ---------------------------------------------------------------------
//
//------------------------------------------------------------------------------

`timescale 1 ps/1 ps


//------------------------------------------------------------------------------
// The entity declaration for the example_design level wrapper.
//------------------------------------------------------------------------------

module ethernet_controller #(parameter tx_dst_addr = 48'h001F293A10FD,tx_src_addr = 48'hAABBCCDDEEFF,tx_max_data_size = 16'd1024,rx_dst_addr=48'hAABBCCDDEEFF)
   (
      // asynchronous reset
      input         glbl_rst,
		input         dcm_locked,

      // 200MHz clock input from board
      input         i_clk_125,
      input         i_clk_200,

      output        phy_resetn,
      input         loop_back_en,

		
      // GMII Interface
      //---------------

      output [7:0]  gmii_txd,
      output        gmii_tx_en,
      output        gmii_tx_er,
      output        gmii_tx_clk,
      input  [7:0]  gmii_rxd,
      input         gmii_rx_dv,
      input         gmii_rx_er,
      input         gmii_rx_clk,
      input         gmii_col,
      input         gmii_crs,
      input         mii_tx_clk,
      output        mdio_out,
		input         mdio_in,
		output        mdc_out,
		output        mdio_t,

      // AXI stream i/f
      //-----------------------------
		
	  output            o_axi_rx_clk,
      output            o_axi_rx_rst_n,
      output     [7:0]  o_axi_rx_tdata,
      output            o_axi_rx_data_tvalid,
      output            o_axi_rx_data_tlast,
	  input             i_axi_rx_data_tready,
			
	  output            o_axi_tx_clk,
      output            o_axi_tx_rst_n,
      input      [7:0]  i_axi_tx_tdata,
      input             i_axi_tx_data_tvalid,
      output            o_axi_tx_data_tready,
      input             i_axi_tx_data_tlast,
		output            o_tx_mac_count
    );

   // control parameters
   parameter            BOARD_PHY_ADDR = 5'h7;

   //----------------------------------------------------------------------------
   // internal signals used in this top level wrapper.
   //----------------------------------------------------------------------------

   // example design clocks
   (* KEEP = "TRUE" *)
   wire                 gtx_clk_bufg;
   (* KEEP = "TRUE" *)
   wire                 refclk_bufg;
   (* KEEP = "TRUE" *)
   wire                 s_axi_aclk;
   wire                 rx_mac_aclk;
   wire                 tx_mac_aclk;


   reg                  phy_resetn_int;
   // resets (and reset generation)
   wire                 chk_reset_int;
   reg                  chk_pre_resetn = 0;
   reg                  chk_resetn = 0;
   wire                 gtx_clk_reset_int;
   reg                  gtx_pre_resetn = 0;
   reg                  gtx_resetn = 0;

   wire                 glbl_rst_int;
   reg   [5:0]          phy_reset_count;
   wire                 glbl_rst_intn;

   // RX Statistics serialisation signals
   (* KEEP = "TRUE" *)
   wire                 rx_statistics_valid;
   reg                  rx_statistics_valid_reg;
   (* KEEP = "TRUE" *)
   wire  [27:0]         rx_statistics_vector;
   reg   [27:0]         rx_stats;
   reg                  rx_stats_toggle = 0;
   wire                 rx_stats_toggle_sync;
   reg                  rx_stats_toggle_sync_reg = 0;
   reg   [29:0]         rx_stats_shift;

   // TX Statistics serialisation signals
   (* KEEP = "TRUE" *)
   wire                 tx_statistics_valid;
   reg                  tx_statistics_valid_reg;
   (* KEEP = "TRUE" *)
   wire  [31:0]         tx_statistics_vector;
   reg   [31:0]         tx_stats;
   reg                  tx_stats_toggle = 0;
   wire                 tx_stats_toggle_sync;
   reg                  tx_stats_toggle_sync_reg = 0;
   reg   [33:0]         tx_stats_shift;
   (* KEEP = "TRUE" *)
   wire  [79:0]         rx_configuration_vector;
   (* KEEP = "TRUE" *)
   wire  [79:0]         tx_configuration_vector;

   // signal tie offs
   wire  [7:0]         tx_ifg_delay = 0;    // not used in this example
	
		
   wire        rx_fifo_clock;
   wire        rx_fifo_resetn;
   wire        rx_axis_fifo_tvalid;
   wire  [7:0] rx_axis_fifo_tdata;
   wire        rx_axis_fifo_tlast;
   wire        rx_axis_fifo_tready;
	
		
   wire        tx_fifo_clock;
   wire        tx_fifo_resetn;
   wire  [7:0] tx_axis_fifo_tdata;
   wire        tx_axis_fifo_tvalid;
   wire        tx_axis_fifo_tlast;
   wire        tx_axis_fifo_tready;

assign gtx_clk_bufg = i_clk_125;
assign refclk_bufg  = i_clk_200;

  //---------------
  // global reset
   reset_sync glbl_reset_gen (
      .clk              (gtx_clk_bufg),
      .enable           (dcm_locked),
      .reset_in         (glbl_rst),
      .reset_out        (glbl_rst_int)
   );

   assign glbl_rst_intn = !glbl_rst_int;

  //----------------------------------------------------------------------------
  // Generate the user side clocks for the axi fifos
  //----------------------------------------------------------------------------
  assign tx_fifo_clock = gtx_clk_bufg;
  assign rx_fifo_clock = gtx_clk_bufg;

  //----------------------------------------------------------------------------
  // Generate resets required for the fifo side signals etc
  //----------------------------------------------------------------------------
  // in each case the async reset is first captured and then synchronised


  //---------------
  // gtx_clk reset
   reset_sync gtx_reset_gen (
      .clk              (gtx_clk_bufg),
      .enable           (dcm_locked),
      .reset_in         (glbl_rst),
      .reset_out        (gtx_clk_reset_int)
   );

   // Create fully synchronous reset in the gtx_clk domain.
   always @(posedge gtx_clk_bufg)
   begin
     if (gtx_clk_reset_int) begin
       gtx_pre_resetn  <= 0;
       gtx_resetn      <= 0;
     end
     else begin
       gtx_pre_resetn  <= 1;
       gtx_resetn      <= gtx_pre_resetn;
     end
   end

  //---------------
  // data check reset
   reset_sync chk_reset_gen (
      .clk              (gtx_clk_bufg),
      .enable           (dcm_locked),
      .reset_in         (glbl_rst),
      .reset_out        (chk_reset_int)
   );

   // Create fully synchronous reset in the gtx_clk domain.
   always @(posedge gtx_clk_bufg)
   begin
     if (chk_reset_int) begin
       chk_pre_resetn  <= 0;
       chk_resetn      <= 0;
     end
     else begin
       chk_pre_resetn  <= 1;
       chk_resetn      <= chk_pre_resetn;
     end
   end

   //---------------
   // PHY reset
   // the phy reset output (active low) needs to be held for at least 10x25MHZ cycles
   // this is derived using the 125MHz available and a 6 bit counter
   always @(posedge gtx_clk_bufg)
   begin
      if (!glbl_rst_intn) begin
         phy_resetn_int <= 0;
         phy_reset_count <= 0;
      end
      else begin
         if (!(&phy_reset_count)) begin
            phy_reset_count <= phy_reset_count + 1;
         end
         else begin
            phy_resetn_int <= 1;
         end
      end
   end

   assign phy_resetn = phy_resetn_int;

   // generate the user side resets for the axi fifos
   assign tx_fifo_resetn = gtx_resetn;
   assign rx_fifo_resetn = gtx_resetn;

  //----------------------------------------------------------------------------
  // Instantiate the V6 Hard EMAC core fifo block wrapper
  //----------------------------------------------------------------------------
  v6_emac_v2_2_fifo_block v6emac_fifo_block (
      .gtx_clk                      (gtx_clk_bufg),

      // Reference clock for IDELAYCTRL's
      .refclk                       (refclk_bufg),

      // Receiver Statistics Interface
      //---------------------------------------
      .rx_mac_aclk                  (),
      .rx_reset                     (),
      .rx_statistics_vector         (),
      .rx_statistics_valid          (),

      // Receiver (AXI-S) Interface
      //----------------------------------------
      .rx_fifo_clock                (rx_fifo_clock),
      .rx_fifo_resetn               (rx_fifo_resetn),
      .rx_axis_fifo_tdata           (rx_axis_fifo_tdata),
      .rx_axis_fifo_tvalid          (rx_axis_fifo_tvalid),
      .rx_axis_fifo_tready          (rx_axis_fifo_tready),
      .rx_axis_fifo_tlast           (rx_axis_fifo_tlast),

      // Transmitter Statistics Interface
      //------------------------------------------
      .tx_mac_aclk                  (),
      .tx_reset                     (),
      .tx_ifg_delay                 (tx_ifg_delay),
      .tx_statistics_vector         (),
      .tx_statistics_valid          (),

      // Transmitter (AXI-S) Interface
      //-------------------------------------------
      .tx_fifo_clock                (tx_fifo_clock),
      .tx_fifo_resetn               (tx_fifo_resetn),
      .tx_axis_fifo_tdata           (tx_axis_fifo_tdata),
      .tx_axis_fifo_tvalid          (tx_axis_fifo_tvalid),
      .tx_axis_fifo_tready          (tx_axis_fifo_tready),
      .tx_axis_fifo_tlast           (tx_axis_fifo_tlast),

      // MAC Control Interface
      //------------------------
      .pause_req                    (1'b0),
      .pause_val                    (16'd0),

      // GMII Interface
      //-----------------
      .gmii_txd                     (gmii_txd),
      .gmii_tx_en                   (gmii_tx_en),
      .gmii_tx_er                   (gmii_tx_er),
      .gmii_tx_clk                  (gmii_tx_clk),
      .gmii_rxd                     (gmii_rxd),
      .gmii_rx_dv                   (gmii_rx_dv),
      .gmii_rx_er                   (gmii_rx_er),
      .gmii_rx_clk                  (gmii_rx_clk),
      .gmii_col                     (gmii_col),
      .gmii_crs                     (gmii_crs),
      .mii_tx_clk                   (mii_tx_clk),
		.mdio_out             			(mdio_out),
		.mdio_in              			(mdio_in),
		.mdc_out              			(mdc_out),
		.mdio_t               			(mdio_t),
		.loopback_enable      			(loop_back_en),

      // asynchronous reset
      .glbl_rstn                    (glbl_rst_intn),
      .rx_axi_rstn                  (1'b1),
      .tx_axi_rstn                  (1'b1),
		.o_tx_mac_count					(o_tx_mac_count)
      //.loop_back                    (loop_back_en)
   );
	
	
	//Eth receive side unpacking
  eth_rcr_unpack #(
		.unpack_dst_addr(rx_dst_addr)
  )  
  eth_unpack
  (
      .i_axi_rx_clk(rx_fifo_clock),
      .i_axi_rx_rst_n(rx_fifo_resetn),
      .i_rx_axis_fifo_tvalid(rx_axis_fifo_tvalid),
      .i_rx_axis_fifo_tdata(rx_axis_fifo_tdata),
      .i_rx_axis_fifo_tlast(rx_axis_fifo_tlast),
      .o_rx_axis_fifo_tready(rx_axis_fifo_tready),
      .o_axi_rx_clk(o_axi_rx_clk),
      .o_axi_rx_rst_n(o_axi_rx_rst_n),
      .o_axi_rx_tdata(o_axi_rx_tdata),
      .o_axi_rx_data_tvalid(o_axi_rx_data_tvalid),
      .i_axi_rx_data_tready(i_axi_rx_data_tready),
      .o_axi_rx_data_tlast(o_axi_rx_data_tlast),
      .loop_back(loop_back_en)
  );
  
  
  eth_tcr_pack #( 
		.dst_addr(tx_dst_addr),
		.src_addr(tx_src_addr),
		.max_data_size(tx_max_data_size)
  )
  eth_pack(
     .o_axi_tx_clk(o_axi_tx_clk),
     .o_axi_tx_rst_n(o_axi_tx_rst_n),
     .i_axi_tx_tdata(i_axi_tx_tdata),
     .i_axi_tx_data_tvalid(i_axi_tx_data_tvalid),
     .o_axi_tx_data_tready(o_axi_tx_data_tready),
     .i_axi_tx_data_tlast(i_axi_tx_data_tlast),
     .i_axi_tx_clk(tx_fifo_clock),
     .i_axi_tx_rst_n(tx_fifo_resetn),
     .o_tx_axis_fifo_tvalid(tx_axis_fifo_tvalid),
     .o_tx_axis_fifo_tdata(tx_axis_fifo_tdata),
     .o_tx_axis_fifo_tlast(tx_axis_fifo_tlast),
     .i_tx_axis_fifo_tready(tx_axis_fifo_tready)
	);
	

endmodule
