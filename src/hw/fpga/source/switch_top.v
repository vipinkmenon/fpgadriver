//--------------------------------------------------------------------------------
// Project    : UPRA
// File       : SWITCH
// Version    : 0.1
// Author     : Vipin.K
//
// Description: The top module instantiating all the switch components
//
//--------------------------------------------------------------------------------
module switch_top #
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
   parameter ROW_WIDTH               = 14,
   parameter NUM_PCIE_STRM           = 4,
   parameter NUM_DDR_STRM            = 4,
   parameter ENET_ENABLE             = 1,
   parameter RECONFIG_ENABLE         = 1,
   parameter RCM_ENABLE              = 1
   )
  (
  input                  clk_ref_p,     //differential iodelayctrl clk
  input                  clk_ref_n,     //
  inout  [DQ_WIDTH-1:0]  ddr3_dq,       //
  output [ROW_WIDTH-1:0] ddr3_addr,
  output [BANK_WIDTH-1:0]ddr3_ba,
  output                 ddr3_ras_n,
  output                 ddr3_cas_n,
  output                 ddr3_we_n,
  output                 ddr3_reset_n,
  output [(CS_WIDTH*nCS_PER_RANK)-1:0] ddr3_cs_n,
  output [(CS_WIDTH*nCS_PER_RANK)-1:0] ddr3_odt,
  output [CKE_WIDTH-1:0]               ddr3_cke,
  output [DM_WIDTH-1:0]                ddr3_dm,
  inout  [DQS_WIDTH-1:0]               ddr3_dqs_p,//
  inout  [DQS_WIDTH-1:0]               ddr3_dqs_n,//
  output [CK_WIDTH-1:0]                ddr3_ck_p, //
  output [CK_WIDTH-1:0]                ddr3_ck_n, //
  output               phy_init_done,
  output               pll_lock,    //  GPIO LED
  output               heartbeat,   // GPIO LED
  //pcie
  output  [3:0]        pci_exp_txp,
  output  [3:0]        pci_exp_txn,
  input   [3:0]        pci_exp_rxp,
  input   [3:0]        pci_exp_rxn,
  input                sys_clk_p,
  input                sys_clk_n,
  input                sys_reset_n,
  output               pcie_link_status,
  //ethernet
  output               phy_resetn,
  // V6 GMII I/F
  output  [7:0]        gmii_txd,
  output               gmii_tx_en,
  output               gmii_tx_er,
  output               gmii_tx_clk,
  input   [7:0]        gmii_rxd,
  input                gmii_rx_dv,
  input                gmii_rx_er,
  input                gmii_rx_clk,
  input                gmii_col,
  input                gmii_crs,
  input                mii_tx_clk,
  output               mdio_out,
  input                mdio_in,
  output               mdc_out,
  output               mdio_t,
  // V7 SGMII I/F
  input                gtrefclk_p,            // Differential +ve of reference clock for MGT: 125MHz, very high quality.
  input                gtrefclk_n,            // Differential -ve of reference clock for MGT: 125MHz, very high quality.
  output               txp,                   // Differential +ve of serial transmission from PMA to PMD.
  output               txn,                   // Differential -ve of serial transmission from PMA to PMD.
  input                rxp,                   // Differential +ve for serial reception from PMD to PMA.
  input                rxn,                   // Differential -ve for serial reception from PMD to PMA.
  output               synchronization_done,
  output               linkup,

  //user logic
  output               o_pcie_clk, //250Mhz
  output               o_ddr_clk,  //200Mhz
  output               o_user_clk,  //configurable
  output               o_slow_clk, //100Mhz  
  output               o_rst,
  //reg i/f 
  output  [31:0]       o_user_data,
  output  [19:0]       o_user_addr,
  output               o_user_wr_req,
  input   [31:0]       i_user_data,
  input                i_user_rd_ack,
  output               o_user_rd_req, 
  //user ddr i/f
  input    [255:0]     i_ddr_wr_data,
  input    [31:0]      i_ddr_wr_data_be_n,
  input                i_ddr_wr_data_valid,
  input    [31:0]      i_ddr_addr,
  input                i_ddr_rd,
  output   [255:0]     o_ddr_rd_data,
  output               o_ddr_rd_data_valid,
  output               o_ddr_wr_ack,
  output               o_ddr_rd_ack,
  //interrupt if       
  input                i_intr_req,
  output               o_intr_ack,
  //stream i/f         
  output               user_str1_data_valid_o,
  input                user_str1_ack_i,
  output [63:0]        user_str1_data_o,
  input                user_str1_data_valid_i,
  output               user_str1_ack_o,
  input  [63:0]        user_str1_data_i,
  
  output               user_str2_data_valid_o,
  input                user_str2_ack_i,
  output [63:0]        user_str2_data_o,
  input                user_str2_data_valid_i,
  output               user_str2_ack_o,
  input  [63:0]        user_str2_data_i,

  output               user_str3_data_valid_o,
  input                user_str3_ack_i,
  output [63:0]        user_str3_data_o,
  input                user_str3_data_valid_i,
  output               user_str3_ack_o,
  input  [63:0]        user_str3_data_i,
  
  output               user_str4_data_valid_o,
  input                user_str4_ack_i,
  output [63:0]        user_str4_data_o,
  input                user_str4_data_valid_i,
  output               user_str4_ack_o,
  input  [63:0]        user_str4_data_i,
  
  //ddr stream 1
  input                i_ddr_str1_data_valid,
  output               o_ddr_str1_ack,
  input       [63:0]   i_ddr_str1_data,
  output               o_ddr_str1_data_valid,
  input                i_ddr_str1_ack,
  output      [63:0]   o_ddr_str1_data,
  //ddr strm 2
  input                i_ddr_str2_data_valid,
  output               o_ddr_str2_ack,
  input       [63:0]   i_ddr_str2_data,
  output               o_ddr_str2_data_valid,
  input                i_ddr_str2_ack,
  output      [63:0]   o_ddr_str2_data,
  //ddr strm 3
  input                i_ddr_str3_data_valid,
  output               o_ddr_str3_ack,
  input       [63:0]   i_ddr_str3_data,
  output               o_ddr_str3_data_valid,
  input                i_ddr_str3_ack,
  output      [63:0]   o_ddr_str3_data,
  //ddr strm 4
  input                i_ddr_str4_data_valid,
  output               o_ddr_str4_ack,
  input       [63:0]   i_ddr_str4_data,
  output               o_ddr_str4_data_valid,
  input                i_ddr_str4_ack,
  output      [63:0]   o_ddr_str4_data
);

wire                ddr_clk;
wire                ddr_wr_req;
wire                ddr_wr_ack;
wire [255:0]        ddr_wr_data;
wire [31:0]         ddr_addr;
wire [31:0]         app_addr;
wire [255:0]        app_wdf_data;
wire [255:0]        app_rd_data;
wire [255:0]        fpmc_ddr_rd_data;
wire [2:0]          app_cmd;
wire [31:0]         ddr_wr_be;
wire [31:0]         app_wdf_mask;
wire                gclk;
wire                ddr_rd_valid;
wire                ddr_rst;
wire                user_soft_reset;
wire [255:0]        ddr_strm_rd_data;
wire [31:0]         fpmc_ddr_wr_addr;
wire [31:0]         fpmc_ddr_rd_addr;
wire [31:0]         ddr_strm1_addr;
wire [31:0]         ddr_user1_str_addr;
wire [31:0]         ddr_user1_str_len;
wire [31:0]         ddr_str1_wr_addr;
wire [255:0]        ddr_str1_wr_data;
wire [31:0]         ddr_str1_wr_be;
wire [31:0]         ddr_strm2_addr;
wire [31:0]         ddr_user2_str_addr;
wire [31:0]         ddr_user2_str_len;
wire [31:0]         ddr_str2_wr_addr;
wire [255:0]        ddr_str2_wr_data;
wire [31:0]         ddr_str2_wr_be;
wire [31:0]         ddr_strm3_addr;
wire [31:0]         ddr_user3_str_addr;
wire [31:0]         ddr_user3_str_len;
wire [31:0]         ddr_str3_wr_addr;
wire [255:0]        ddr_str3_wr_data;
wire [31:0]         ddr_str3_wr_be;
wire [31:0]         ddr_strm4_addr;
wire [31:0]         ddr_user4_str_addr;
wire [31:0]         ddr_user4_str_len;
wire [31:0]         ddr_str4_wr_addr;
wire [255:0]        ddr_str4_wr_data;
wire [31:0]         ddr_str4_wr_be;
wire [255:0]        ddr_rd_data;
wire [31:0]         fpmc_ddr_wr_data_be;
wire [255:0]        fpmc_ddr_wr_data;
wire [255:0]        enet_ddr_rd_data;
wire [255:0]        enet_ddr_wr_data;
wire [31:0]         enet_ddr_wr_addr;
wire [31:0]         enet_ddr_rd_addr;
wire [31:0]         enet_ddr_be;
wire [31:0]         enet_send_data_size;
wire [31:0]         enet_rcv_data_size;
wire [31:0]         enet_ddr_src_addr;
wire [31:0]         enet_ddr_dest_addr;
wire                enet_rx_done;
wire                enet_tx_done;
wire [31:0]         enet_tx_cnt;
wire [31:0]         enet_rx_cnt;
wire                ddr_strm1_rd_req;
wire                ddr_strm2_rd_req;
wire                ddr_strm3_rd_req;
wire                ddr_strm4_rd_req;
wire                ddr_strm1_rd_ack;
wire                ddr_strm2_rd_ack;
wire                ddr_strm3_rd_ack;
wire                ddr_strm4_rd_ack;
wire                ddr_str1_wr_req;
wire                ddr_str2_wr_req;
wire                ddr_str3_wr_req;
wire                ddr_str4_wr_req;
wire                ddr_str1_wr_ack;
wire                ddr_str2_wr_ack;
wire                ddr_str3_wr_ack;
wire                ddr_str4_wr_ack;
wire                ddr_strm1_rd_data_valid;
wire                ddr_strm2_rd_data_valid;
wire                ddr_strm3_rd_data_valid;
wire                ddr_strm4_rd_data_valid;
wire                fpmc_ddr_rd_req;
wire                fpmc_ddr_rd_ack;
wire                fpmc_rd_data_valid;
wire                fpmc_ddr_wr_req;
wire                fpmc_ddr_wr_ack;
wire                ddr_user1_str_en;
wire                ddr_user2_str_en;
wire                ddr_user3_str_en;
wire                ddr_user4_str_en;
wire                ddr_user1_str_done;
wire                ddr_user2_str_done;
wire                ddr_user3_str_done;
wire                ddr_user4_str_done;
wire                ddr_user1_str_done_ack;
wire                ddr_user2_str_done_ack;
wire                ddr_user3_str_done_ack;
wire                ddr_user4_str_done_ack;
wire                user1_ddr_str_en;
wire                user2_ddr_str_en;
wire                user3_ddr_str_en;
wire                user4_ddr_str_en;
wire                user1_ddr_str_done;
wire                user2_ddr_str_done;
wire                user3_ddr_str_done;
wire                user4_ddr_str_done;
wire                user1_ddr_str_done_ack;
wire                user2_ddr_str_done_ack;
wire                user3_ddr_str_done_ack;
wire                user4_ddr_str_done_ack;
wire    [31:0]      user1_ddr_str_addr;
wire    [31:0]      user2_ddr_str_addr;
wire    [31:0]      user3_ddr_str_addr;
wire    [31:0]      user4_ddr_str_addr;
wire    [31:0]      user1_ddr_str_len; 
wire    [31:0]      user2_ddr_str_len; 
wire    [31:0]      user3_ddr_str_len; 
wire    [31:0]      user4_ddr_str_len; 
wire                enet_clk;
wire                enet_enable;
wire                enet_done;
wire                enet_ddr_wr_req;
wire                enet_ddr_rd_req;
wire                enet_ddr_wr_ack;
wire                enet_ddr_rd_ack;
wire                enet_rd_data_valid;

assign o_ddr_clk  = ddr_clk;
assign o_slow_clk = gclk;
assign o_rst      = user_soft_reset;//ddr_rst|


//Xilinx PCIe endpoint
pcie_top #(
    .NUM_PCIE_STRM(NUM_PCIE_STRM),
    .RECONFIG_ENABLE(RECONFIG_ENABLE),
    .RCM_ENABLE(RCM_ENABLE)
    )
     pcie_top (
    .pci_exp_txp(pci_exp_txp), 
    .pci_exp_txn(pci_exp_txn), 
    .pci_exp_rxp(pci_exp_rxp), 
    .pci_exp_rxn(pci_exp_rxn), 
    .sys_clk_p(sys_clk_p), 
    .sys_clk_n(sys_clk_n), 
    .sys_reset_n(sys_reset_n), 
    .i_ddr_clk(ddr_clk),
    .o_ddr_wr_req(ddr_wr_req), 
    .o_ddr_wr_data(ddr_wr_data), 
    .o_ddr_wr_be(ddr_wr_be), 
    .i_ddr_wr_ack(ddr_wr_ack), 
    .o_ddr_addr(ddr_addr),
    .ddr_rd_req_o(ddr_rd_req),
    .ddr_rd_ack_i(ddr_rd_ack),
    .ddr_rd_data_i(ddr_rd_data),
    .ddr_rd_valid_i(ddr_rd_valid),
    .user_clk_o(o_user_clk),
    .pcie_clk_o(o_pcie_clk),
    .user_reset_o(user_soft_reset),
    .user_data_o(o_user_data),
    .user_addr_o(o_user_addr),
    .user_wr_req_o(o_user_wr_req),
    //.user_wr_ack_i(i_user_wr_ack),
    .user_data_i(i_user_data),
    .user_rd_ack_i(i_user_rd_ack),
    .user_rd_req_o(o_user_rd_req),
    .user_intr_req_i(i_intr_req),
    .user_intr_ack_o(o_intr_ack),
    .user_str1_data_valid_o(user_str1_data_valid_o),
    .user_str1_ack_i(user_str1_ack_i),
    .user_str1_data_o(user_str1_data_o),
    .user_str1_data_valid_i(user_str1_data_valid_i),
    .user_str1_ack_o(user_str1_ack_o),
    .user_str1_data_i(user_str1_data_i),
    .user_str2_data_valid_o(user_str2_data_valid_o),
    .user_str2_ack_i(user_str2_ack_i),
    .user_str2_data_o(user_str2_data_o),
    .user_str2_data_valid_i(user_str2_data_valid_i),
    .user_str2_ack_o(user_str2_ack_o),
    .user_str2_data_i(user_str2_data_i),
    .user_str3_data_valid_o(user_str3_data_valid_o),
    .user_str3_ack_i(user_str3_ack_i),
    .user_str3_data_o(user_str3_data_o),
    .user_str3_data_valid_i(user_str3_data_valid_i),
    .user_str3_ack_o(user_str3_ack_o),
    .user_str3_data_i(user_str3_data_i),
    .user_str4_data_valid_o(user_str4_data_valid_o),
    .user_str4_ack_i(user_str4_ack_i),
    .user_str4_data_o(user_str4_data_o),
    .user_str4_data_valid_i(user_str4_data_valid_i),
    .user_str4_ack_o(user_str4_ack_o),
    .user_str4_data_i(user_str4_data_i),
    .o_ddr_user1_str_en(ddr_user1_str_en),
    .i_ddr_user1_str_done(ddr_user1_str_done),
    .o_ddr_user1_str_done_ack(ddr_user1_str_done_ack),
    .o_ddr_user1_str_addr(ddr_user1_str_addr),
    .o_ddr_user1_str_len(ddr_user1_str_len),
    .o_user1_ddr_str_en(user1_ddr_str_en),
    .i_user1_ddr_str_done(user1_ddr_str_done),
    .o_user1_ddr_str_done_ack(user1_ddr_str_done_ack),
    .o_user1_ddr_str_addr(user1_ddr_str_addr),
    .o_user1_ddr_str_len(user1_ddr_str_len), 	 
    .o_ddr_user2_str_addr(ddr_user2_str_addr),
    .o_ddr_user2_str_len(ddr_user2_str_len),
    .o_ddr_user2_str_en(ddr_user2_str_en),
    .i_ddr_user2_str_done(ddr_user2_str_done),
    .o_ddr_user2_str_done_ack(ddr_user2_str_done_ack),
    .o_user2_ddr_str_en(user2_ddr_str_en),
    .i_user2_ddr_str_done(user2_ddr_str_done),
    .o_user2_ddr_str_done_ack(user2_ddr_str_done_ack),
    .o_user2_ddr_str_addr(user2_ddr_str_addr),
    .o_user2_ddr_str_len(user2_ddr_str_len), 
    .o_ddr_user3_str_addr(ddr_user3_str_addr),
    .o_ddr_user3_str_len(ddr_user3_str_len),
    .o_ddr_user3_str_en(ddr_user3_str_en),
    .i_ddr_user3_str_done(ddr_user3_str_done),
    .o_ddr_user3_str_done_ack(ddr_user3_str_done_ack),
    .o_user3_ddr_str_en(user3_ddr_str_en),
    .i_user3_ddr_str_done(user3_ddr_str_done),
    .o_user3_ddr_str_done_ack(user3_ddr_str_done_ack),
    .o_user3_ddr_str_addr(user3_ddr_str_addr),
    .o_user3_ddr_str_len(user3_ddr_str_len), 
    .o_ddr_user4_str_addr(ddr_user4_str_addr),
    .o_ddr_user4_str_len(ddr_user4_str_len),
    .o_ddr_user4_str_en(ddr_user4_str_en),
    .i_ddr_user4_str_done(ddr_user4_str_done),
    .o_ddr_user4_str_done_ack(ddr_user4_str_done_ack),
    .o_user4_ddr_str_en(user4_ddr_str_en),
    .i_user4_ddr_str_done(user4_ddr_str_done),
    .o_user4_ddr_str_done_ack(user4_ddr_str_done_ack),
    .o_user4_ddr_str_addr(user4_ddr_str_addr),
    .o_user4_ddr_str_len(user4_ddr_str_len),   
    .pcie_link_status(pcie_link_status),
    .i_ddr_link_stat(phy_init_done),
    .i_enet_link_stat(linkup),
    .clk_sysmon_i(clk_sysmon),
    .o_enet_clk(enet_clk),
    .o_enet_enable(enet_enable),
    .o_enet_loopback(loopback_enable),
    .o_enet_send_data_size(enet_send_data_size),
    .o_enet_rcv_data_size(enet_rcv_data_size),
    .o_enet_ddr_src_addr(enet_ddr_src_addr),
    .o_enet_ddr_dest_addr(enet_ddr_dest_addr),
    .i_enet_rx_cnt(enet_rx_cnt),
    .i_enet_tx_cnt(enet_tx_cnt),
    .i_enet_rx_done(enet_rx_done),
    .i_enet_tx_done(enet_tx_done)
    
);

//DDR controller top
ddr_top ddr_top(
   .clk_ref_p(clk_ref_p),     //differential iodelayctrl clk
   .clk_ref_n(clk_ref_n),
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
   .pll_lock(pll_lock),   // ML605 GPIO LED
   .heartbeat(heartbeat),  // ML605 GPIO LED
   .sys_rst(!sys_reset_n),   //sys_rst System reset
   .gclk(gclk),
   .ui_clk(ddr_clk),
   .ui_clk_sync_rst(ddr_rst),
   .app_wdf_wren(app_wdf_wren),
   .app_wdf_data(app_wdf_data),
   .app_wdf_mask(app_wdf_mask),
   .app_wdf_end(app_wdf_end),
   .app_addr(app_addr),
   .app_cmd(app_cmd),
   .app_en(app_en),
   .app_rdy(app_rdy),
   .app_wdf_rdy(app_wdf_rdy),
   .app_rd_data(app_rd_data),
   .app_rd_data_end(app_rd_data_end),
   .app_rd_data_valid(app_rd_data_valid),
   .clk_sysmon(clk_sysmon)
  );
  
  
generate
   if(ENET_ENABLE == 1)
   begin:enet
    ethernet_top et(
    .i_rst(ddr_rst), 
    .i_clk_125(enet_clk), 
    .i_clk_200(ddr_clk), 
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
    
    .mdio_out(mdio_out),
    .mdio_in(mdio_in),
    .mdc_out(mdc_out),
    .mdio_t(mdio_t), 
    .i_enet_enable(enet_enable),
    .i_enet_loopback(loopback_enable),
    .i_enet_ddr_source_addr(enet_ddr_src_addr), 
    .i_enet_ddr_dest_addr(enet_ddr_dest_addr), 
    .i_enet_rcv_data_size(enet_rcv_data_size), 
    .i_enet_snd_data_size(enet_send_data_size), 
    .o_enet_rx_cnt(enet_rx_cnt),
    .o_enet_tx_cnt(enet_tx_cnt),
    .o_enet_rx_done(enet_rx_done),
    .o_enet_tx_done(enet_tx_done),
    .o_ddr_wr_req(enet_ddr_wr_req), 
    .o_ddr_rd_req(enet_ddr_rd_req), 
    .o_ddr_wr_data(enet_ddr_wr_data), 
    .o_ddr_wr_be(enet_ddr_be), 
    .o_ddr_wr_addr(enet_ddr_wr_addr), 
    .o_ddr_rd_addr(enet_ddr_rd_addr), 
    .i_ddr_rd_data(enet_ddr_rd_data), 
    .i_ddr_wr_ack(enet_ddr_wr_ack), 
    .i_ddr_rd_ack(enet_ddr_rd_ack), 
    .i_ddr_rd_data_valid(enet_rd_data_valid)
    ); 
  end
endgenerate  


four_port_ddr_ctrl fpdc (
    .i_clk(ddr_clk), 
    .i_rst(ddr_rst), 
    .app_wdf_wren(app_wdf_wren), 
    .app_wdf_data(app_wdf_data), 
    .app_wdf_mask(app_wdf_mask), 
    .app_wdf_end(app_wdf_end), 
    .app_addr(app_addr), 
    .app_cmd(app_cmd), 
    .app_en(app_en), 
    .app_rdy(app_rdy), 
    .app_wdf_rdy(app_wdf_rdy), 
    .app_rd_data(app_rd_data), 
    .app_rd_data_end(app_rd_data_end), 
    .app_rd_data_valid(app_rd_data_valid), 
    .i_port0_wr_data(ddr_wr_data), 
    .i_port0_wr_data_valid(ddr_wr_req),
    .i_port0_wr_data_be(ddr_wr_be), 
    .i_port0_wr_addr(ddr_addr), 
    .i_port0_rd_addr(ddr_addr),
    .o_port0_wr_ack(ddr_wr_ack), 
    .i_port0_rd(ddr_rd_req), 
    .o_port0_rd_data(ddr_rd_data), 
    .o_port0_rd_ack(ddr_rd_ack), 
    .o_port0_rd_data_valid(ddr_rd_valid), 
    .i_port1_wr_data(fpmc_ddr_wr_data), 
    .i_port1_wr_data_be(fpmc_ddr_wr_data_be), 
    .i_port1_wr_data_valid(fpmc_ddr_wr_req), 
    .i_port1_wr_addr(fpmc_ddr_wr_addr), 
    .i_port1_rd(fpmc_ddr_rd_req), 
    .o_port1_rd_data(fpmc_ddr_rd_data), 
    .o_port1_rd_data_valid(fpmc_rd_data_valid), 
    .i_port1_rd_addr(fpmc_ddr_rd_addr),
    .o_port1_wr_ack(fpmc_ddr_wr_ack), 
    .o_port1_rd_ack(fpmc_ddr_rd_ack), 
    .i_port2_wr_data(i_ddr_wr_data), 
    .i_port2_wr_data_be(i_ddr_wr_data_be_n), 
    .i_port2_wr_data_valid(i_ddr_wr_data_valid), 
    .i_port2_wr_addr(i_ddr_addr), 
    .i_port2_rd_addr(i_ddr_addr), 
    .i_port2_rd(i_ddr_rd), 
    .o_port2_rd_data(o_ddr_rd_data), 
    .o_port2_rd_data_valid(o_ddr_rd_data_valid), 
    .o_port2_wr_ack(o_ddr_wr_ack), 
    .o_port2_rd_ack(o_ddr_rd_ack), 
    .i_port3_wr_data(enet_ddr_wr_data), 
    .i_port3_wr_data_be(enet_ddr_be), 
    .i_port3_wr_data_valid(enet_ddr_wr_req), 
    .i_port3_wr_addr(enet_ddr_wr_addr), 
    .i_port3_rd_addr(enet_ddr_rd_addr), 
    .i_port3_rd(enet_ddr_rd_req), 
    .o_port3_rd_data(enet_ddr_rd_data), 
    .o_port3_rd_data_valid(enet_rd_data_valid), 
    .o_port3_wr_ack(enet_ddr_wr_ack), 
    .o_port3_rd_ack(enet_ddr_rd_ack)
    );


generate
  if(NUM_DDR_STRM >= 1)
  begin:gen1
    user_ddr_stream_generator udsg1 (
    .i_ddr_clk(ddr_clk), 
    .i_user_clk(o_user_clk), 
    .i_rst_n(~ddr_rst),
    .i_ddr_stream_rd_en(ddr_user1_str_en), 
    .o_ddr_stream_rd_done(ddr_user1_str_done),
    .i_ddr_stream_rd_done_ack(ddr_user1_str_done_ack),
    .i_ddr_stream_rd_start_addr(ddr_user1_str_addr), 
    .i_ddr_stream_rd_len(ddr_user1_str_len), 	 
    .i_ddr_stream_wr_en(user1_ddr_str_en),
    .o_ddr_stream_wr_done(user1_ddr_str_done),
    .i_ddr_stream_wr_done_ack(user1_ddr_str_done_ack),
    .i_ddr_stream_wr_start_addr(user1_ddr_str_addr),
    .i_ddr_stream_wr_len(user1_ddr_str_len),
    .o_ddr_rd_req(ddr_strm1_rd_req), 
    .i_ddr_rd_ack(ddr_strm1_rd_ack), 
    .o_ddr_rd_addr(ddr_strm1_addr), 
    .i_ddr_rd_data_valid(ddr_strm1_rd_data_valid), 
    .i_ddr_rd_data(ddr_strm_rd_data), 
    .o_ddr_stream_valid(o_ddr_str1_data_valid), 
    .i_ddr_stream_tready(i_ddr_str1_ack), 
    .o_ddr_stream_data(o_ddr_str1_data),
    .o_ddr_wr_req(ddr_str1_wr_req),
    .i_ddr_wr_ack(ddr_str1_wr_ack),
    .o_ddr_wr_addr(ddr_str1_wr_addr),
    .o_ddr_wr_data(ddr_str1_wr_data),
    .o_ddr_wr_be_n(ddr_str1_wr_be),
    .i_ddr_str_data_valid(i_ddr_str1_data_valid),    
    .o_ddr_str_ack(o_ddr_str1_ack),
    .i_ddr_str_data(i_ddr_str1_data)  
    );
  end 
  
  if(NUM_DDR_STRM >= 2)
  begin:gen2 
    user_ddr_stream_generator udsg2 (
    .i_ddr_clk(ddr_clk), 
    .i_user_clk(o_user_clk), 
    .i_rst_n(~ddr_rst),
    .i_ddr_stream_rd_en(ddr_user2_str_en), 
    .o_ddr_stream_rd_done(ddr_user2_str_done),
    .i_ddr_stream_rd_done_ack(ddr_user2_str_done_ack),
    .i_ddr_stream_rd_start_addr(ddr_user2_str_addr),
    .i_ddr_stream_rd_len(ddr_user2_str_len),
    .i_ddr_stream_wr_en(user2_ddr_str_en),
    .o_ddr_stream_wr_done(user2_ddr_str_done),
    .i_ddr_stream_wr_done_ack(user2_ddr_str_done_ack),
    .i_ddr_stream_wr_start_addr(user2_ddr_str_addr),
    .i_ddr_stream_wr_len(user2_ddr_str_len),
    .o_ddr_rd_req(ddr_strm2_rd_req), 
    .i_ddr_rd_ack(ddr_strm2_rd_ack), 
    .o_ddr_rd_addr(ddr_strm2_addr), 
    .i_ddr_rd_data_valid(ddr_strm2_rd_data_valid), 
    .i_ddr_rd_data(ddr_strm_rd_data), 
    .o_ddr_stream_valid(o_ddr_str2_data_valid), 
    .i_ddr_stream_tready(i_ddr_str2_ack), 
    .o_ddr_stream_data(o_ddr_str2_data),
    .o_ddr_wr_req(ddr_str2_wr_req),
    .i_ddr_wr_ack(ddr_str2_wr_ack),
    .o_ddr_wr_addr(ddr_str2_wr_addr),
    .o_ddr_wr_data(ddr_str2_wr_data),
    .o_ddr_wr_be_n(ddr_str2_wr_be),
    .i_ddr_str_data_valid(i_ddr_str2_data_valid),    
    .o_ddr_str_ack(o_ddr_str2_ack),
    .i_ddr_str_data(i_ddr_str2_data) 
    );
  end

  if(NUM_DDR_STRM >= 3)
  begin:gen3  
    user_ddr_stream_generator udsg3 (
    .i_ddr_clk(ddr_clk), 
    .i_user_clk(o_user_clk), 
    .i_rst_n(~ddr_rst),
    .i_ddr_stream_rd_en(ddr_user3_str_en), 
    .o_ddr_stream_rd_done(ddr_user3_str_done),
    .i_ddr_stream_rd_done_ack(ddr_user3_str_done_ack),
    .i_ddr_stream_rd_start_addr(ddr_user3_str_addr),
    .i_ddr_stream_rd_len(ddr_user3_str_len),
    .i_ddr_stream_wr_en(user3_ddr_str_en),
    .o_ddr_stream_wr_done(user3_ddr_str_done),
    .i_ddr_stream_wr_done_ack(user3_ddr_str_done_ack),
    .i_ddr_stream_wr_start_addr(user3_ddr_str_addr),
    .i_ddr_stream_wr_len(user3_ddr_str_len),
    .o_ddr_rd_req(ddr_strm3_rd_req), 
    .i_ddr_rd_ack(ddr_strm3_rd_ack), 
    .o_ddr_rd_addr(ddr_strm3_addr), 
    .i_ddr_rd_data_valid(ddr_strm3_rd_data_valid), 
    .i_ddr_rd_data(ddr_strm_rd_data), 
    .o_ddr_stream_valid(o_ddr_str3_data_valid), 
    .i_ddr_stream_tready(i_ddr_str3_ack), 
    .o_ddr_stream_data(o_ddr_str3_data),
    .o_ddr_wr_req(ddr_str3_wr_req),
    .i_ddr_wr_ack(ddr_str3_wr_ack),
    .o_ddr_wr_addr(ddr_str3_wr_addr),
    .o_ddr_wr_data(ddr_str3_wr_data),
    .o_ddr_wr_be_n(ddr_str3_wr_be),
    .i_ddr_str_data_valid(i_ddr_str3_data_valid),    
    .o_ddr_str_ack(o_ddr_str3_ack),
    .i_ddr_str_data(i_ddr_str3_data) 
   );
  end

  if(NUM_DDR_STRM >= 4)
  begin:gen4
   user_ddr_stream_generator udsg4 (
    .i_ddr_clk(ddr_clk), 
    .i_user_clk(o_user_clk), 
    .i_rst_n(~ddr_rst),
    .i_ddr_stream_rd_en(ddr_user4_str_en), 
    .o_ddr_stream_rd_done(ddr_user4_str_done),
    .i_ddr_stream_rd_done_ack(ddr_user4_str_done_ack),
    .i_ddr_stream_rd_start_addr(ddr_user4_str_addr),
    .i_ddr_stream_rd_len(ddr_user4_str_len),
    .i_ddr_stream_wr_en(user4_ddr_str_en),
    .o_ddr_stream_wr_done(user4_ddr_str_done),
    .i_ddr_stream_wr_done_ack(user4_ddr_str_done_ack),
    .i_ddr_stream_wr_start_addr(user4_ddr_str_addr),
    .i_ddr_stream_wr_len(user4_ddr_str_len),
    .o_ddr_rd_req(ddr_strm4_rd_req), 
    .i_ddr_rd_ack(ddr_strm4_rd_ack), 
    .o_ddr_rd_addr(ddr_strm4_addr), 
    .i_ddr_rd_data_valid(ddr_strm4_rd_data_valid), 
    .i_ddr_rd_data(ddr_strm_rd_data), 
    .o_ddr_stream_valid(o_ddr_str4_data_valid), 
    .i_ddr_stream_tready(i_ddr_str4_ack), 
    .o_ddr_stream_data(o_ddr_str4_data),
    .o_ddr_wr_req(ddr_str4_wr_req),
    .i_ddr_wr_ack(ddr_str4_wr_ack),
    .o_ddr_wr_addr(ddr_str4_wr_addr),
    .o_ddr_wr_data(ddr_str4_wr_data),
    .o_ddr_wr_be_n(ddr_str4_wr_be),
    .i_ddr_str_data_valid(i_ddr_str4_data_valid),    
    .o_ddr_str_ack(o_ddr_str4_ack),
    .i_ddr_str_data(i_ddr_str4_data) 
   );
  end

  if(NUM_DDR_STRM >= 1)
  begin:gen9
  user_ddr_strm_arbitrator #(
    .NUM_SLAVES(NUM_DDR_STRM)
    )
    udsa
    (
    .i_clk(ddr_clk),
    .i_rst_n(~ddr_rst),
    .i_ddr_rd_req({ddr_strm4_rd_req,ddr_strm3_rd_req,ddr_strm2_rd_req,ddr_strm1_rd_req}),
    .o_ddr_rd_ack({ddr_strm4_rd_ack,ddr_strm3_rd_ack,ddr_strm2_rd_ack,ddr_strm1_rd_ack}),
    .i_ddr_rd_addr({ddr_strm4_addr,ddr_strm3_addr,ddr_strm2_addr,ddr_strm1_addr}),
    .o_ddr_rd_data_valid({ddr_strm4_rd_data_valid,ddr_strm3_rd_data_valid,ddr_strm2_rd_data_valid,ddr_strm1_rd_data_valid}),
    .o_ddr_rd_data(ddr_strm_rd_data),
    .i_ddr_wr_req({ddr_str4_wr_req,ddr_str3_wr_req,ddr_str2_wr_req,ddr_str1_wr_req}),
    .o_ddr_wr_ack({ddr_str4_wr_ack,ddr_str3_wr_ack,ddr_str2_wr_ack,ddr_str1_wr_ack}),
    .i_ddr_wr_addr({ddr_str4_wr_addr,ddr_str3_wr_addr,ddr_str2_wr_addr,ddr_str1_wr_addr}),
    .i_ddr_wr_data({ddr_str4_wr_data,ddr_str3_wr_data,ddr_str2_wr_data,ddr_str1_wr_data}),
    .i_ddr_wr_be_n({ddr_str4_wr_be,ddr_str3_wr_be,ddr_str2_wr_be,ddr_str1_wr_be}), 
     //
    .o_ddr_rd_req(fpmc_ddr_rd_req),
    .i_ddr_rd_ack(fpmc_ddr_rd_ack),
    .i_ddr_data(fpmc_ddr_rd_data),
    .i_ddr_rd_data_valid(fpmc_rd_data_valid),
    .o_ddr_wr_addr(fpmc_ddr_wr_addr),  
    .o_ddr_rd_addr(fpmc_ddr_rd_addr),  
    .o_ddr_wr_req(fpmc_ddr_wr_req),
    .i_ddr_wr_ack(fpmc_ddr_wr_ack),
    .o_ddr_data(fpmc_ddr_wr_data),
    .o_ddr_be_n(fpmc_ddr_wr_data_be)
    );
  end
  endgenerate

endmodule
