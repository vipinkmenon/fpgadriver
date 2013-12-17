//--------------------------------------------------------------------------------
// Project    : SWITCH
// File       : top.v
// Version    : 0.1
// Author     : Vipin.K
//
// Description: The top most file instantiating the AXI Switch and the user logic
//
//--------------------------------------------------------------------------------
`include "fpga_spec.h"

module top #
  (

   parameter nCS_PER_RANK            = 1,                                       
   parameter BANK_WIDTH              = 3,
   parameter CK_WIDTH                = 1,
   parameter CKE_WIDTH               = 1,
   parameter COL_WIDTH               = 10,
   parameter CS_WIDTH                = 1,
   parameter DM_WIDTH                = 8,
   parameter DQ_WIDTH                = 64,
   parameter DQS_WIDTH               = 8,
   parameter ROW_WIDTH               = 14
   )
  (
   input                                clk_ref_p,     //differential iodelayctrl clk
   input                                clk_ref_n,
   inout  [DQ_WIDTH-1:0]                ddr3_dq,
   output [ROW_WIDTH-1:0]               ddr3_addr,
   output [BANK_WIDTH-1:0]              ddr3_ba,
   output                               ddr3_ras_n,
   output                               ddr3_cas_n,
   output                               ddr3_we_n,
   output                               ddr3_reset_n,
   output [(CS_WIDTH*nCS_PER_RANK)-1:0] ddr3_cs_n,
   output [(CS_WIDTH*nCS_PER_RANK)-1:0] ddr3_odt,
   output [CKE_WIDTH-1:0]               ddr3_cke,
   output [DM_WIDTH-1:0]                ddr3_dm,
   inout  [DQS_WIDTH-1:0]               ddr3_dqs_p,
   inout  [DQS_WIDTH-1:0]               ddr3_dqs_n,
   output [CK_WIDTH-1:0]                ddr3_ck_p,
   output [CK_WIDTH-1:0]                ddr3_ck_n,
   output                               phy_init_done,
   output                               pll_lock,   
   output                               heartbeat,    
   //pcie
   output  [3:0]                        pci_exp_txp,
   output  [3:0]                        pci_exp_txn,
   input   [3:0]                        pci_exp_rxp,
   input   [3:0]                        pci_exp_rxn,
   input                                sys_clk_p,
   input                                sys_clk_n,
   input                                sys_reset_n,
   output                               pcie_link_status,
// Ethernet
	output                               phy_resetn,
   // V6 GMII I/F
   output  [7:0]                        gmii_txd,
   output                               gmii_tx_en,
   output                               gmii_tx_er,
   output                               gmii_tx_clk,
   input   [7:0]                        gmii_rxd,
   input                                gmii_rx_dv,
   input                                gmii_rx_er,
   input                                gmii_rx_clk,
   input                                gmii_col,
   input                                gmii_crs,
   input                                mii_tx_clk,
   inout						                mdio,
	output               					 mdc,
  // V7 SGMII I/F
  input                						 gtrefclk_p,            // Differential +ve of reference clock for MGT: 125MHz, very high quality.
  input                						 gtrefclk_n,            // Differential -ve of reference clock for MGT: 125MHz, very high quality.
  output               						 txp,                   // Differential +ve of serial transmission from PMA to PMD.
  output               						 txn,                   // Differential -ve of serial transmission from PMA to PMD.
  input                						 rxp,                   // Differential +ve for serial reception from PMD to PMA.
  input                						 rxn,                   // Differential -ve for serial reception from PMD to PMA.
  output           	  						 synchronization_done,
  output               						 linkup,

   input                                EMCCLK

);


wire [31:0]  user_wr_data;
wire [19:0]  user_addr;
wire [31:0]  user_rd_data;
wire [255:0] user_ddr_wr_data;
wire [31:0]  user_ddr_wr_data_be;
wire [26:0]  user_ddr_addr;
wire [255:0] user_ddr_rd_data;
wire [9:0]   user_dma_len;
wire [31:0]  user_dma_strt_addr;
wire [63:0]  user_str1_wr_data;
wire [63:0]  user_str1_rd_data;
wire [63:0]  user_str2_wr_data;
wire [63:0]  user_str2_rd_data;
wire [63:0]  user_str3_wr_data;
wire [63:0]  user_str3_rd_data;
wire [63:0]  user_str4_wr_data;
wire [63:0]  user_str4_rd_data;
wire [63:0]  user_str5_wr_data;
wire [63:0]  user_str5_rd_data;
wire [63:0]  user_str6_wr_data;
wire [63:0]  user_str6_rd_data;
wire [63:0]  user_str7_wr_data;
wire [63:0]  user_str7_rd_data;
wire [63:0]  user_str8_wr_data;
wire [63:0]  user_str8_rd_data;
wire [63:0]  ddr_str1_wr_data;
wire [63:0]  ddr_str1_rd_data;
wire [63:0]  ddr_str2_wr_data;
wire [63:0]  ddr_str2_rd_data;
wire [63:0]  ddr_str3_rd_data;
wire [63:0]  ddr_str3_wr_data;
wire [63:0]  ddr_str4_rd_data;
wire [63:0]  ddr_str4_wr_data;
wire [63:0]  ddr_str5_rd_data;
wire [63:0]  ddr_str5_wr_data;
wire [63:0]  ddr_str6_rd_data;
wire [63:0]  ddr_str6_wr_data;
wire [63:0]  ddr_str7_rd_data;
wire [63:0]  ddr_str7_wr_data;
wire [63:0]  ddr_str8_rd_data;
wire [63:0]  ddr_str8_wr_data;

// want to infer an IOBUF on the mdio port
  assign mdio = mdio_t ? 1'bz : mdio_out;

  assign mdio_in = mdio;

  PULLUP mdio_pu (
     .O (mdio_i)
  );

	 
(*KEEP_HIERARCHY = "SOFT"*)	 
switch_top #(
	.NUM_PCIE_STRM(`NUM_PCIE_STRM),
	.NUM_DDR_STRM(`NUM_DDR_STRM),
	.ENET_ENABLE(`ENET_ENABLE),
	.RECONFIG_ENABLE(`RECONFIG_ENABLE),
	.RCM_ENABLE(`RCM_ENABLE)
    )
    st (
    .clk_ref_p(clk_ref_p), 
    .clk_ref_n(clk_ref_n),
    //ddr i/f	 
    .ddr3_dq(ddr3_dq), 
    .ddr3_addr(ddr3_addr), 
    .ddr3_ba(ddr3_ba), 
    .ddr3_ras_n(ddr3_ras_n), 
    .ddr3_cas_n(ddr3_cas_n), 
    .ddr3_we_n(ddr3_we_n), 
    .ddr3_reset_n(ddr3_reset_n), 
    .ddr3_cs_n(ddr3_cs_n), 
    .ddr3_odt(ddr3_odt), 
    .ddr3_cke(ddr3_cke), 
    .ddr3_dm(ddr3_dm), 
    .ddr3_dqs_p(ddr3_dqs_p), 
    .ddr3_dqs_n(ddr3_dqs_n), 
    .ddr3_ck_p(ddr3_ck_p), 
    .ddr3_ck_n(ddr3_ck_n), 
    .phy_init_done(phy_init_done), 
    .pll_lock(pll_lock), 
    .heartbeat(heartbeat), 
	 //pcie i/f
    .pci_exp_txp(pci_exp_txp), 
    .pci_exp_txn(pci_exp_txn), 
    .pci_exp_rxp(pci_exp_rxp), 
    .pci_exp_rxn(pci_exp_rxn), 
    .sys_clk_p(sys_clk_p), 
    .sys_clk_n(sys_clk_n), 
    .sys_reset_n(sys_reset_n), 
    .pcie_link_status(pcie_link_status),
    //ethernet i/f	 
	 .phy_resetn(phy_resetn),
	 // V6 GMII I/F
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
	 // V7 SGMII I/F
	 .gtrefclk_p(gtrefclk_p),
	 .gtrefclk_n(gtrefclk_n),
	 .txp(txp),
	 .txn(txn),
	 .rxp(rxp),
	 .rxn(rxn),
	 .synchronization_done(synchronization_done),
	 .linkup(linkup),
    // MDIO PHY I/F
	 .mdio_out(mdio_out),
	 .mdio_in(mdio_in),
	 .mdc_out(mdc),
	 .mdio_t(mdio_t),	 
	 
	 //user i/f
    .o_pcie_clk(user_pcie_clk), 
    .o_ddr_clk(user_ddr_clk),
    .o_user_clk(user_clk),
    .o_slow_clk(), 
    .o_rst(user_rst), 
    .o_user_data(user_wr_data), 
    .o_user_addr(user_addr), 
    .o_user_wr_req(user_wr_req), 
    //.i_user_wr_ack(user_wr_ack), 
    .i_user_data(user_rd_data), 
    .i_user_rd_ack(user_data_valid), 
    .o_user_rd_req(user_rd_req), 
    .i_ddr_wr_data(user_ddr_wr_data), 
    .i_ddr_wr_data_be_n(user_ddr_wr_data_be), 
    .i_ddr_wr_data_valid(user_ddr_wr_data_valid), 
    .i_ddr_addr(user_ddr_addr), 
    .i_ddr_rd(user_ddr_rd), 
    .o_ddr_rd_data(user_ddr_rd_data), 
    .o_ddr_rd_data_valid(user_ddr_rd_data_valid), 
    .o_ddr_wr_ack(user_ddr_wr_ack), 
    .o_ddr_rd_ack(user_ddr_rd_ack), 
    .i_intr_req(user_intr_req), 
    .o_intr_ack(user_intr_ack),  
    .user_str1_data_valid_o(user_str1_data_wr_valid),
    .user_str1_ack_i(user_str1_wr_ack),
    .user_str1_data_o(user_str1_wr_data),
    .user_str1_data_valid_i(user_str1_data_rd_valid),
    .user_str1_ack_o(user_str1_rd_ack),
    .user_str1_data_i(user_str1_rd_data),
    .user_str2_data_valid_o(user_str2_data_wr_valid),
    .user_str2_ack_i(user_str2_wr_ack),
    .user_str2_data_o(user_str2_wr_data),
    .user_str2_data_valid_i(user_str2_data_rd_valid),
    .user_str2_ack_o(user_str2_rd_ack),
    .user_str2_data_i(user_str2_rd_data),
	 .user_str3_data_valid_o(user_str3_data_wr_valid),
    .user_str3_ack_i(user_str3_wr_ack),
    .user_str3_data_o(user_str3_wr_data),
    .user_str3_data_valid_i(user_str3_data_rd_valid),
    .user_str3_ack_o(user_str3_rd_ack),
    .user_str3_data_i(user_str3_rd_data),
    .user_str4_data_valid_o(user_str4_data_wr_valid),
    .user_str4_ack_i(user_str4_wr_ack),
    .user_str4_data_o(user_str4_wr_data),
    .user_str4_data_valid_i(user_str4_data_rd_valid),
    .user_str4_ack_o(user_str4_rd_ack),
    .user_str4_data_i(user_str4_rd_data),
	 
	 .o_ddr_str1_data_valid(ddr_str1_wr_data_valid),
    .i_ddr_str1_ack(ddr_str1_wr_ack),
    .o_ddr_str1_data(ddr_str1_wr_data),
    .i_ddr_str1_data_valid(ddr_str1_rd_data_valid),
    .o_ddr_str1_ack(ddr_str1_rd_ack),
    .i_ddr_str1_data(ddr_str1_rd_data),
	 
    .o_ddr_str2_data_valid(ddr_str2_wr_data_valid),
    .i_ddr_str2_ack(ddr_str2_wr_ack),
    .o_ddr_str2_data(ddr_str2_wr_data),
    .i_ddr_str2_data_valid(ddr_str2_rd_data_valid),
    .o_ddr_str2_ack(ddr_str2_rd_ack),
    .i_ddr_str2_data(ddr_str2_rd_data),
	 
    .i_ddr_str3_data_valid(ddr_str3_rd_data_valid),
    .o_ddr_str3_ack(ddr_str3_rd_ack),
    .i_ddr_str3_data(ddr_str3_rd_data),
    .o_ddr_str3_data_valid(ddr_str3_wr_data_valid),
    .i_ddr_str3_ack(ddr_str3_wr_ack),
    .o_ddr_str3_data(ddr_str3_wr_data),
	 
    .i_ddr_str4_data_valid(ddr_str4_rd_data_valid), 
    .o_ddr_str4_ack(ddr_str4_rd_ack),
    .i_ddr_str4_data(ddr_str4_rd_data),
    .o_ddr_str4_data_valid(ddr_str4_wr_data_valid),
    .i_ddr_str4_ack(ddr_str4_wr_ack),
    .o_ddr_str4_data(ddr_str4_wr_data)
	 
  );
	
	 
//Dummy logic for test purpose
user_logic_top ult(
    .i_pcie_clk(user_pcie_clk), //250Mhz 
    .i_ddr_clk(user_ddr_clk),  //200Mhz
	 .i_user_clk(user_clk),
    //.i_slow_clk(), //100Mhz  
    .i_rst(user_rst),
       //reg i/f 
    .i_user_data(user_wr_data),
    .i_user_addr(user_addr),
    .i_user_wr_req(user_wr_req),
    .o_user_data(user_rd_data),
    .o_user_rd_ack(user_data_valid),
    .i_user_rd_req(user_rd_req), 
    .o_ddr_wr_data(user_ddr_wr_data),
    .o_ddr_wr_data_be_n(user_ddr_wr_data_be),
    .o_ddr_wr_data_valid(user_ddr_wr_data_valid),
    .o_ddr_addr(user_ddr_addr),
    .o_ddr_rd(user_ddr_rd),
    .i_ddr_rd_data(user_ddr_rd_data),
    .i_ddr_rd_data_valid(user_ddr_rd_data_valid),
    .i_ddr_wr_ack(user_ddr_wr_ack),
    .i_ddr_rd_ack(user_ddr_rd_ack),
	 //pcie strm 1
    .i_pcie_str1_data_valid(user_str1_data_wr_valid),
    .o_pcie_str1_ack(user_str1_wr_ack),
	 .i_pcie_str1_data({user_str1_wr_data[31:0],user_str1_wr_data[63:32]}),
    .o_pcie_str1_data_valid(user_str1_data_rd_valid),
    .i_pcie_str1_ack(user_str1_rd_ack),
    .o_pcie_str1_data({user_str1_rd_data[31:0],user_str1_rd_data[63:32]}),
	 //pcie strm 2
    .i_pcie_str2_data_valid(user_str2_data_wr_valid),
    .o_pcie_str2_ack(user_str2_wr_ack),
    .i_pcie_str2_data({user_str2_wr_data[31:0],user_str2_wr_data[63:32]}),
    .o_pcie_str2_data_valid(user_str2_data_rd_valid),
    .i_pcie_str2_ack(user_str2_rd_ack),
    .o_pcie_str2_data({user_str2_rd_data[31:0],user_str2_rd_data[63:32]}),
	 //pcie strm 3
    .i_pcie_str3_data_valid(user_str3_data_wr_valid),
    .o_pcie_str3_ack(user_str3_wr_ack),
	 .i_pcie_str3_data({user_str3_wr_data[31:0],user_str3_wr_data[63:32]}),
    .o_pcie_str3_data_valid(user_str3_data_rd_valid),
    .i_pcie_str3_ack(user_str3_rd_ack),
    .o_pcie_str3_data({user_str3_rd_data[31:0],user_str3_rd_data[63:32]}),	 
	 //pcie strm 4
    .i_pcie_str4_data_valid(user_str4_data_wr_valid),
    .o_pcie_str4_ack(user_str4_wr_ack),
	 .i_pcie_str4_data({user_str4_wr_data[31:0],user_str4_wr_data[63:32]}),
    .o_pcie_str4_data_valid(user_str4_data_rd_valid),
    .i_pcie_str4_ack(user_str4_rd_ack),
    .o_pcie_str4_data({user_str4_rd_data[31:0],user_str4_rd_data[63:32]}),	 	 
	 //ddr strm 1
	 .i_ddr_str1_data_valid(ddr_str1_wr_data_valid),
    .o_ddr_str1_ack(ddr_str1_wr_ack),
    .i_ddr_str1_data({ddr_str1_wr_data[31:0],ddr_str1_wr_data[63:32]}),
    .o_ddr_str1_data_valid(ddr_str1_rd_data_valid),
    .i_ddr_str1_ack(ddr_str1_rd_ack),
    .o_ddr_str1_data({ddr_str1_rd_data[31:0],ddr_str1_rd_data[63:32]}),
    //ddr strm 2
    .i_ddr_str2_data_valid(ddr_str2_wr_data_valid),
    .o_ddr_str2_ack(ddr_str2_wr_ack),
    .i_ddr_str2_data({ddr_str2_wr_data[31:0],ddr_str2_wr_data[63:32]}),
    .o_ddr_str2_data_valid(ddr_str2_rd_data_valid),
    .i_ddr_str2_ack(ddr_str2_rd_ack),
    .o_ddr_str2_data({ddr_str2_rd_data[31:0],ddr_str2_rd_data[63:32]}),
    //ddr strm 3
    .i_ddr_str3_data_valid(ddr_str3_wr_data_valid),
    .o_ddr_str3_ack(ddr_str3_wr_ack),
    .i_ddr_str3_data({ddr_str3_wr_data[31:0],ddr_str3_wr_data[63:32]}),
    .o_ddr_str3_data_valid(ddr_str3_rd_data_valid),
    .i_ddr_str3_ack(ddr_str3_rd_ack),
    .o_ddr_str3_data({ddr_str3_rd_data[31:0],ddr_str3_rd_data[63:32]}),	 
    //ddr strm 4
    .i_ddr_str4_data_valid(ddr_str4_wr_data_valid),
    .o_ddr_str4_ack(ddr_str4_wr_ack),
    .i_ddr_str4_data({ddr_str4_wr_data[31:0],ddr_str4_wr_data[63:32]}),
    .o_ddr_str4_data_valid(ddr_str4_rd_data_valid),
    .i_ddr_str4_ack(ddr_str4_rd_ack),
    .o_ddr_str4_data({ddr_str4_rd_data[31:0],ddr_str4_rd_data[63:32]}),	 
	 //intr
    .o_intr_req(user_intr_req),
    .i_intr_ack(user_intr_ack)
);

endmodule
