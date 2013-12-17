//--------------------------------------------------------------------------------
// Project    : SWITCH
// File       : ethernet_top.v
// Version    : 0.2
// Author     : Shreejith S, Vipin K
//
// Description: Ethernet Controller Top File
//
//--------------------------------------------------------------------------------



module v7_ethernet_top
(
    // asynchronous reset
      input         glbl_rst,

      // 200MHz clock input from board
      input         i_clk_200,
      
      output        phy_resetn,
     
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

v7_ethernet_controller_top ect 
(
    .glbl_rst(glbl_rst),
    .clkin200(i_clk_200),
    
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
    .i_rst(glbl_rst), 
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
