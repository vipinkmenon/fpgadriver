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

`timescale 1 ps/1 ps


//------------------------------------------------------------------------------
// The entity declaration for the example_design level wrapper.
//------------------------------------------------------------------------------

module v7_ethernet_controller #(
    parameter tx_dst_addr = 48'h001F293A10FD,
              tx_src_addr = 48'hAABBCCDDEEFF,
              tx_max_data_size = 16'd1024,
              rx_dst_addr=48'hAABBCCDDEEFF)
   (
      // asynchronous reset
      input         glbl_rst,
	
      // 200MHz clock input from board
      input            clkin200,
      output           phy_resetn,
     //added SGMII serial data and reference clock ports
      input            gtrefclk_p,            // Differential +ve of reference clock for MGT: 125MHz, very high quality.
      input            gtrefclk_n,            // Differential -ve of reference clock for MGT: 125MHz, very high quality.
      output           txp,                   // Differential +ve of serial transmission from PMA to PMD.
      output           txn,                   // Differential -ve of serial transmission from PMA to PMD.
      input            rxp,                   // Differential +ve for serial reception from PMD to PMA.
      input            rxn,                   // Differential -ve for serial reception from PMD to PMA.
      
      output           synchronization_done,
      output           linkup,

      // MDIO Interface
      //---------------
      input         mdio_i,
	  output        mdio_o,
	  output        mdio_t,
      output        mdc,
 
      input         loop_back_en,

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


   //----------------------------------------------------------------------------
   // internal signals used in this top level wrapper.
   //----------------------------------------------------------------------------


		
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
   reg         phy_init_d1;

  //----------------------------------------------------------------------------
  // Instantiate the V6 Hard EMAC core fifo block wrapper
  //----------------------------------------------------------------------------
    v7_emac_controller ec(
  .glbl_rst(glbl_rst),
  .clkin200(clkin200),

.phy_resetn(phy_resetn),

.gtrefclk_p(gtrefclk_p),
.gtrefclk_n(gtrefclk_n),
.txp(txp),
.txn(txn),
.rxp(rxp),
.rxn(rxn),

.synchronization_done(synchronization_done),
.linkup(linkup),


.mdio_i(mdio_i),
.mdio_t(mdio_t),
.mdio_o(mdio_o),
.mdc(mdc),

.rx_fifo_clk(rx_fifo_clock),
.rx_fifo_rstn(rx_fifo_resetn),
.rx_axis_fifo_tdata(rx_axis_fifo_tdata),
.rx_axis_fifo_tvalid(rx_axis_fifo_tvalid),
.rx_axis_fifo_tready(rx_axis_fifo_tready),
.rx_axis_fifo_tlast(rx_axis_fifo_tlast),
.tx_fifo_clk(tx_fifo_clock),
.tx_fifo_rstn(tx_fifo_resetn),
.tx_axis_fifo_tdata(tx_axis_fifo_tdata),
.tx_axis_fifo_tvalid(tx_axis_fifo_tvalid),
.tx_axis_fifo_tready(tx_axis_fifo_tready),
.tx_axis_fifo_tlast(tx_axis_fifo_tlast),
.o_tx_mac_count(o_tx_mac_count),
.loop_back_en(loop_back_en)
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
