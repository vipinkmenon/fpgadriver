//--------------------------------------------------------------------------------
// Project    : SWITCH
// File       : v7_enet_top.v
// Version    : 0.2
// Author     : Shreejith S
//
// Description: Merged Ethernet Controller Top File for V7
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
  input                gtrefclk_p,            // Differential +ve of reference clock for MGT: 125MHz, very high quality.
  input                gtrefclk_n,            // Differential -ve of reference clock for MGT: 125MHz, very high quality.
  output               txp,                   // Differential +ve of serial transmission from PMA to PMD.
  output               txn,                   // Differential -ve of serial transmission from PMA to PMD.
  input                rxp,                   // Differential +ve for serial reception from PMD to PMA.
  input                rxn,                   // Differential -ve for serial reception from PMD to PMA.
   
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


// Instantiate V7 Top File
v7_ethernet_top v7_et
(
.glbl_rst(i_rst),
.i_clk_200(i_clk_200),
.phy_resetn(phy_resetn),
.gtrefclk_p(gtrefclk_p),
.gtrefclk_n(gtrefclk_n),
.txp(txp),
.txn(txn),
.rxp(rxp),
.rxn(rxn),
.synchronization_done(synchronization_done),
.linkup(linkup),
.mdio_i(mdio_in),
.mdio_o(mdio_out),
.mdio_t(mdio_t),
.mdc(mdc_out),
.i_enet_enable(i_enet_enable),
.i_enet_loopback(i_enet_loopback),
.i_enet_ddr_source_addr(i_enet_ddr_source_addr),
.i_enet_ddr_dest_addr(i_enet_ddr_dest_addr),
.i_enet_rcv_data_size(i_enet_rcv_data_size),
.i_enet_snd_data_size(i_enet_snd_data_size),
.o_enet_rx_cnt(o_enet_rx_cnt),
.o_enet_tx_cnt(o_enet_tx_cnt),
.o_enet_rx_done(o_enet_rx_done),
.o_enet_tx_done(o_enet_tx_done),
.o_ddr_wr_req(o_ddr_wr_req),
.o_ddr_rd_req(o_ddr_rd_req),
.o_ddr_wr_data(o_ddr_wr_data),
.o_ddr_wr_be(o_ddr_wr_be),
.o_ddr_wr_addr(o_ddr_wr_addr),
.o_ddr_rd_addr(o_ddr_rd_addr),
.i_ddr_rd_data(i_ddr_rd_data),
.i_ddr_wr_ack(i_ddr_wr_ack),
.i_ddr_rd_ack(i_ddr_rd_ack),
.i_ddr_rd_data_valid(i_ddr_rd_data_valid)
);

endmodule