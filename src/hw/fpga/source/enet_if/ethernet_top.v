//--------------------------------------------------------------------------------
// Project    : SWITCH
// File       : ethernet_top.v
// Version    : 0.2
// Author     : Shreejith S, Vipin K
//
// Description: Ethernet Controller Top File
//
//--------------------------------------------------------------------------------



module ethernet_top(
  input                i_rst,
  input                i_clk_125,
  input                i_clk_200,
  output               phy_resetn,
  // V6 GMII I/F
  output [7:0]         gmii_txd,
  output               gmii_tx_en,
  output               gmii_tx_er,
  output               gmii_tx_clk,
  input  [7:0]         gmii_rxd,
  input                gmii_rx_dv,
  input                gmii_rx_er,
  input                gmii_rx_clk,
  input                gmii_col,
  input                gmii_crs,
  input                mii_tx_clk,
  // V7 SGMII I/F
  		// Commom I/F for V7 Enet - Not used here
		
      input         gtrefclk_p,            // Differential +ve of reference clock for MGT: 125MHz, very high quality.
      input         gtrefclk_n,            // Differential -ve of reference clock for MGT: 125MHz, very high quality.
      output        txp,                   // Differential +ve of serial transmission from PMA to PMD.
      output        txn,                   // Differential -ve of serial transmission from PMA to PMD.
      input         rxp,                   // Differential +ve for serial reception from PMD to PMA.
      input         rxn,                   // Differential -ve for serial reception from PMD to PMA.
      
      output        synchronization_done,
      output        linkup,

  // PHY MDIO I/F
  output        mdio_out,
  input         mdio_in,
  output        mdc_out,
  output        mdio_t,

//Reg file
  input                i_enet_enable,          // Enable the ethernet core
  input                i_enet_loopback,        // Enable loopback mode
  input   [31:0]       i_enet_ddr_source_addr, // Where is data for ethernet
  input   [31:0]       i_enet_ddr_dest_addr,   // Where to store ethernet data
  input   [31:0]       i_enet_rcv_data_size,   // How much data should be received from enet
  input   [31:0]       i_enet_snd_data_size,   // How much data should be sent through enet
  output  [31:0]       o_enet_rx_cnt,          // Ethernet RX Performance Counter
  output  [31:0]       o_enet_tx_cnt,          // Ethernet TX Performance Counter 
  output               o_enet_rx_done,         // Ethernet RX Completed 
  output               o_enet_tx_done,         // Ethernet TX Completed 
  
//To DDR controller
  output               o_ddr_wr_req,
  output               o_ddr_rd_req,
  output   [255:0]     o_ddr_wr_data,
  output      [31:0]   o_ddr_wr_be,
  output      [31:0]   o_ddr_wr_addr,
  output      [31:0]   o_ddr_rd_addr,
  input       [255:0]  i_ddr_rd_data,
  input                i_ddr_wr_ack,
  input                i_ddr_rd_ack,
  input                i_ddr_rd_data_valid
);



wire [63:0]  enet_wr_data;
wire [63:0]  enet_rd_data;

ethernet_controller_top ect (
    .glbl_rst(i_rst), 
    .dcm_locked(1'b1), 
    .i_clk_125(i_clk_125), 
    .i_clk_200(i_clk_200), 
    .phy_resetn(phy_resetn), 
    .gmii_txd(gmii_txd), 
    .gmii_tx_en(gmii_tx_en), 
    .gmii_tx_er(gmii_tx_er), 
    .gmii_tx_clk(gmii_tx_clk), 
    .gmii_rxd(gmii_rxd), 
    .gmii_rx_dv(gmii_rx_dv), 
    .gmii_rx_er(gmii_rx_er), 
    .gmii_rx_clk(gmii_rx_clk), 
    .gmii_col(gmii_col), 
    .gmii_crs(gmii_crs), 
    .mii_tx_clk(mii_tx_clk),
		.mdio_out             (mdio_out),
		.mdio_in              (mdio_in),
		.mdc_out              (mdc_out),
		.mdio_t               (mdio_t),	 
    .enet_loopback(i_enet_loopback),
    .enet_wr_clk(i_clk_200), 
    .enet_wr_data_valid(enet_wr_data_valid), 
    .enet_wr_data(enet_wr_data), 
    .enet_wr_rdy(enet_wr_rdy), 
    .enet_rd_clk(i_clk_200), 
    .enet_rd_rdy(enet_rd_rdy), 
    .enet_rd_data(enet_rd_data), 
    .enet_rd_data_valid(enet_rd_data_valid),
    .if_enable(enet_enable),
	 .o_tx_mac_count(tx_mac_count)
    );
	 
	 
	 
	 enet_ddr_ctrl edc (
    .i_clk(i_clk_200), 
    .i_rst(i_rst), 
    .i_enet_enable(i_enet_enable), 
    .i_enet_ddr_source_addr(i_enet_ddr_source_addr), 
    .i_enet_ddr_dest_addr(i_enet_ddr_dest_addr), 
    .i_enet_rcv_data_size(i_enet_rcv_data_size), 
    .i_enet_snd_data_size(i_enet_snd_data_size), 
    .o_enet_enable(enet_enable), 
    .i_enet_data_avail(enet_rd_data_valid), 
    .o_enet_rx_cnt(o_enet_rx_cnt),
    .o_enet_tx_cnt(o_enet_tx_cnt),
    .o_enet_rx_done(o_enet_rx_done),
    .o_enet_tx_done(o_enet_tx_done),
    .o_core_ready(enet_rd_rdy), 
    .i_data(enet_rd_data), 
    .o_data(enet_wr_data), 
    .o_core_data_avail(enet_wr_data_valid), 
    .i_enet_ready(enet_wr_rdy), 
    .o_ddr_wr_req(o_ddr_wr_req), 
    .o_ddr_rd_req(o_ddr_rd_req), 
    .o_ddr_wr_data(o_ddr_wr_data), 
    .o_ddr_wr_be(o_ddr_wr_be), 
    .o_ddr_wr_addr(o_ddr_wr_addr), 
    .o_ddr_rd_addr(o_ddr_rd_addr), 
    .i_ddr_rd_data(i_ddr_rd_data), 
    .i_ddr_wr_ack(i_ddr_wr_ack), 
    .i_ddr_rd_ack(i_ddr_rd_ack), 
    .i_ddr_rd_data_valid(i_ddr_rd_data_valid),
	 .i_tx_mac_count(tx_mac_count)
    );


endmodule
