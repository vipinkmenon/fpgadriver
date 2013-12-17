//--------------------------------------------------------------------------------
// Project    : SWITCH
// File       : reg_file.v
// Version    : 0.1
// Author     : Vipin.K
//
// Description: Global register set
//
//--------------------------------------------------------------------------------

//Register address definition
`define VER                'h00      // Version
`define SCR                'h04      // Scratch pad
`define CTRL               'h08      // Control
//0C reserved
`define STA                'h10      // Status
`define EER_STAT           'h14      // Error Status register
`define UCTR               'h18      // User control register
//1C reserved
`define PIOA               'h20      // PIO address
`define PIOD               'h24      // PIO read/write register
`define PC_DDR_DMA_SYS     'h28      // System to DDR DMA system memory address
`define PC_DDR_DMA_FPGA    'h2C      // System to DDR DMA local DDR address
`define PC_DDR_DMA_LEN     'h30      // System to DDR DMA length (bytes)
`define DDR_PC_DMA_SYS     'h34      // DDR to system DMA system memory address
`define DDR_PC_DMA_FPGA    'h38      // DDR to system DMA local DDR address
`define DDR_PC_DMA_LEN     'h3C      // DDR to system DMA length (bytes)
`define ETH_SEND_DATA_SIZE 'h40      // Ethernet send data size(bytes)
`define ETH_RCV_DATA_SIZE  'h44      // Ethernet receive data size(bytes)
`define ETH_DDR_SRC_ADDR   'h48      // Ethernet send data DDR start address 
`define ETH_DDR_DST_ADDR   'h4C      // Ethernet receive data DDR start address
`define RECONFIG_ADDR      'h50      // Reconfiguration address
//50-5C Reserved
`define PC_USER1_DMA_SYS   'h60      // System to user stream i/f 1 DMA, system memory address
`define PC_USER1_DMA_LEN   'h64      // System to user stream i/f 1 DMA, length (bytes)
`define USER1_PC_DMA_SYS   'h68      // User stream i/f 1 to system DMA, system memory address
`define USER1_PC_DMA_LEN   'h6C      // User stream i/f 1 to system DMA, length (bytes)
`define USER1_DDR_STR_ADDR 'h70      // User ddr stream i/f 1 to DDR, DDR starting address
`define USER1_DDR_STR_LEN  'h74
`define DDR_USER1_STR_ADDR 'h78      // DDR to user ddr stream i/f 1, DDR starting address
`define DDR_USER1_STR_LEN  'h7C      // DDR to user ddr stream i/f 1, length (bytes)
`define PC_USER2_DMA_SYS   'h80
`define PC_USER2_DMA_LEN   'h84
`define USER2_PC_DMA_SYS   'h88
`define USER2_PC_DMA_LEN   'h8C
`define USER2_DDR_STR_ADDR 'h90
`define USER2_DDR_STR_LEN  'h94
`define DDR_USER2_STR_ADDR 'h98
`define DDR_USER2_STR_LEN  'h9C
`define PC_USER3_DMA_SYS   'hA0
`define PC_USER3_DMA_LEN   'hA4
`define USER3_PC_DMA_SYS   'hA8
`define USER3_PC_DMA_LEN   'hAC
`define USER3_DDR_STR_ADDR 'hB0
`define USER3_DDR_STR_LEN  'hB4
`define DDR_USER3_STR_ADDR 'hB8
`define DDR_USER3_STR_LEN  'hBC
`define PC_USER4_DMA_SYS   'hC0
`define PC_USER4_DMA_LEN   'hC4
`define USER4_PC_DMA_SYS   'hC8
`define USER4_PC_DMA_LEN   'hCC
`define USER4_DDR_STR_ADDR 'hD0
`define USER4_DDR_STR_LEN  'hD4
`define DDR_USER4_STR_ADDR 'hD8
`define DDR_USER4_STR_LEN  'hDC
//DC-1FC reserved 
`define ETH_RX_STATISTIC   'h134     // For Performance Monitoring - Ethernet Rx
`define ETH_TX_STATISTIC   'h138     // For Performance Monitoring - Ethernet Tx

`define SMT                'h200     // System monitor temperature
`define SMA                'h204     // System monitor Vccint
`define SMV                'h208     // System monitor VccAux
`define SMP                'h20C     // System monitor Iccint
`define SBV                'h270     // Board 12V supply current
`define SAC                'h274     // Board 12V Voltage

module reg_file(
 input                clk_i,                     // 250Mhz clock from PCIe core
 input                rst_n,                     // Active low reset
 //Rx engine
 input      [9:0]     addr_i,                    // Register address
 input      [31:0]    data_i,                    // Register write data
 input                data_valid_i,              // Register write data valid
 output               fpga_reg_wr_ack_o,         // Register write ack
 input                fpga_reg_rd_i,             // Register read request
 output reg           fpga_reg_rd_ack_o,         // Register read ack
 output reg [31:0]    data_o,                    // Register read data
 //Tx engine
 output reg           ddr_pc_dma_sys_addr_load_o,// Signalling Tx engine that a new is available for DDR to PC DMA system memory address
 output     [31:0]    ddr_sys_dma_wr_addr_o,     // System memory address for DMA operation
 //To user pcie stream controllers
 //PSG-1
 output               o_user_str1_en,            // Enable signal to the system to user stream i/f 1 controller
 input                i_user_str1_done,          // Stream done signal
 output               o_user_str1_done_ack,      // Ack the done signal. Needed since status register is accessed by both PC and FPGA. So should not miss the done.
 output [31:0]        o_user_str1_dma_addr,      // System memory start address for streaming data
 output [31:0]        o_user_str1_dma_len,       // Length of streaming operation (bytes)
 output               user1_sys_strm_en_o,       // Enable signal to the user stream i/f 1 to system controller
 output [31:0]        user1_sys_dma_wr_addr_o,   // System memory address for DMA operation
 output [31:0]        user1_sys_stream_len_o,    // Stream length for DMA
 input                user1_sys_strm_done_i,     // Stream done signal
 output               user1_sys_strm_done_ack_o, // Ack the done due to multiple STAT reg access.
 //PSG-2
 output               o_user_str2_en,
 input                i_user_str2_done,
 output               o_user_str2_done_ack,
 output [31:0]        o_user_str2_dma_addr,
 output [31:0]        o_user_str2_dma_len,
 output               user2_sys_strm_en_o,
 output [31:0]        user2_sys_dma_wr_addr_o,   
 output [31:0]        user2_sys_stream_len_o,
 input                user2_sys_strm_done_i,
 output               user2_sys_strm_done_ack_o,
 //PSG-3
 output               o_user_str3_en,
 input                i_user_str3_done,
 output               o_user_str3_done_ack,
 output [31:0]        o_user_str3_dma_addr,
 output [31:0]        o_user_str3_dma_len,
 output               user3_sys_strm_en_o,
 output [31:0]        user3_sys_dma_wr_addr_o,   
 output [31:0]        user3_sys_stream_len_o,
 input                user3_sys_strm_done_i,
 output               user3_sys_strm_done_ack_o,
 //PSG-4
 output               o_user_str4_en,
 input                i_user_str4_done,
 output               o_user_str4_done_ack,
 output [31:0]        o_user_str4_dma_addr,
 output [31:0]        o_user_str4_dma_len,
 output               user4_sys_strm_en_o,
 output [31:0]        user4_sys_dma_wr_addr_o,   
 output [31:0]        user4_sys_stream_len_o,
 input                user4_sys_strm_done_i,
 output               user4_sys_strm_done_ack_o,
 //To user ddr stream controllers
 //UDSG-1
 output               o_ddr_user1_str_en,        // Enable DDR to user stream 
 input                i_ddr_user1_str_done,      // Stream done signal.  
 output               o_ddr_user1_str_done_ack,  // ack the done signal 
 output [31:0]        o_ddr_user1_str_addr,      // DDR starting address of the stream
 output [31:0]        o_ddr_user1_str_len,       // Stream length
 output               o_user1_ddr_str_en,
 input                i_user1_ddr_str_done,
 output               o_user1_ddr_str_done_ack,
 output [31:0]        o_user1_ddr_str_addr,      // User ddr stream-1 to DDR start address
 output [31:0]        o_user1_ddr_str_len, 
//UDSG-2
 output               o_ddr_user2_str_en,        // Enable DDR to user stream 
 input                i_ddr_user2_str_done,      // Stream done signal. Should add ack??  
 output               o_ddr_user2_str_done_ack,  // ack the done signal 
 output [31:0]        o_ddr_user2_str_addr,      // DDR starting address of the stream
 output [31:0]        o_ddr_user2_str_len,       // Stream length
 output               o_user2_ddr_str_en,
 input                i_user2_ddr_str_done,
 output               o_user2_ddr_str_done_ack,
 output [31:0]        o_user2_ddr_str_addr, // User ddr stream-2 to DDR start address
 output [31:0]        o_user2_ddr_str_len, 
 //UDSG-3
 output               o_ddr_user3_str_en,        // Enable DDR to user stream 
 input                i_ddr_user3_str_done,      // Stream done signal. Should add ack?? 
 output               o_ddr_user3_str_done_ack,  // ack the done signal 
 output [31:0]        o_ddr_user3_str_addr,      // DDR starting address of the stream
 output [31:0]        o_ddr_user3_str_len,       // Stream length
 output               o_user3_ddr_str_en,
 input                i_user3_ddr_str_done,
 output               o_user3_ddr_str_done_ack,
 output [31:0]        o_user3_ddr_str_addr, // User ddr stream-3 to DDR start address
 output [31:0]        o_user3_ddr_str_len, 
 //UDSG-4
 output               o_ddr_user4_str_en,        // Enable DDR to user stream 
 input                i_ddr_user4_str_done,      // Stream done signal. Should add ack?? 
 output               o_ddr_user4_str_done_ack,  // ack the done signal 
 output [31:0]        o_ddr_user4_str_addr,      // DDR starting address of the stream
 output [31:0]        o_ddr_user4_str_len,       // Stream length
 output               o_user4_ddr_str_en,
 input                i_user4_ddr_str_done,
 output               o_user4_ddr_str_done_ack,
 output [31:0]        o_user4_ddr_str_addr, // User ddr stream-4 to DDR start address
 output [31:0]        o_user4_ddr_str_len, 
 //To pcie_ddr controller
 output               o_pcie_ddr_ctrl_en,        // Enable the controller
 input                i_pcie_ddr_dma_done,       // DMA transfer done
 output               o_pcie_ddr_dma_done_ack,   // Ack the done signal
 output      [31:0]   o_pcie_ddr_dma_src_addr,   // System to DDR DMA system start address
 output      [31:0]   o_pcie_ddr_dma_len,        // DMA length (bytes)
 //To memory controller
 output               fpga_system_dma_req_o,     // DMA write request to system memory
 input                fpga_system_dma_ack_i,     // DMA write ack
 output wire [31:0]   sys_fpga_dma_addr_o,       // System to DDR DMA, DDR address
 output wire [31:0]   fpga_sys_dma_addr_o,       // DDR to System DMA, DDR address
 output wire [31:0]   ddr_pio_addr_o,            // PIO operation DDR address
 output      [31:0]   ddr_pio_data_o,            // PIO write data
 output reg           ddr_pio_data_valid_o,      // PIO write data valid
 input                ddr_pio_wr_ack_i,          // PIO write ack
 output reg           ddr_pio_rd_req_o,          // PIO read request
 input                ddr_pio_rd_ack_i,          // PIO read ack
 input  wire [31:0]   ddr_rd_data_i,             // PIO read data
 output      [31:0]   dma_len_o,                 // DDR to system DMA length 
 //interrupt
 output reg           intr_req_o,                // Interrupt request to Tx engine
 input                intr_req_done_i,           // Interrupt done ack from Tx engine
 input                user_intr_req_i,           // User interrupt request
 output               user_intr_ack_o,           // Interrupt ack to user logic
 //Misc
 output               user_reset_o,              // User soft reset
 output               system_soft_reset_o,       // Complete system soft reset
 //link status
 input                i_pcie_link_stat,
 input                i_ddr_link_stat,
 input                i_enet_link_stat,
 //Dynamic clock manager
 output reg           user_clk_swch_o,           // Change the user clock frequency
 output wire [1:0]    user_clk_sel_o,            // User clock frequency selection ; 00 - 250Mhz, 01 - 200MHz, 10 - 150 MHz, 11 - 100 MHz.
 //Multiboot control
 output               o_load_bitstream,          // Load new bitstream from flash
 output      [31:0]   o_boot_address,            // Address for the next bitstream in flash
 //system monitor
 input                sys_mon_clk_i,             // System monitor clock. Clock sync. is done in this module
 output         [6:0] sys_mon_addr_o,            // System monitor address
 output reg           sys_mon_en_o,              // System monitor enable
 input        [15:0]  sys_mon_data_i,            // Data from system monitor
 input                sys_mon_rdy_i,             // System monitor data valid
 //enet
 output               o_enet_enable,             // Ethernet controller enable
 output               o_enet_loopback,
 output       [31:0]  o_enet_send_data_size,     // Length to data to be sent from DDR
 output       [31:0]  o_enet_rcv_data_size,      // Length to data to be written into DDR
 output       [31:0]  o_enet_ddr_src_addr,       // DDR source address for send data
 output       [31:0]  o_enet_ddr_dest_addr,      // DDR destination address for receive data
 input        [31:0]  i_enet_rx_cnt,
 input        [31:0]  i_enet_tx_cnt,
 input                i_enet_rx_done,
 input                i_enet_tx_done
 
 );
 
 parameter  VER = 32'h00000005;                   // Present Version Number. 16 bit major version and 16 bit minor version

 //Interrupt state machine state variables.
 localparam INTR_IDLE =  'd0,
            WAIT_ACK  =  'd1;

//The global register set in the address of address
reg [31:0] SCR_PAD;                              
reg [31:0] CTRL_REG;
reg [31:0] STAT_REG;
reg [31:0] USR_CTRL_REG;
reg [31:0] PIO_ADDR;
reg [31:0] PIO_RD_DATA;
reg [31:0] PIO_WR_DATA;
reg [31:0] PC_DDR_DMA_SYS;
reg [31:0] PC_DDR_DMA_FPGA;
reg [31:0] PC_DDR_DMA_LEN;
reg [31:0] DDR_PC_DMA_SYS;
reg [31:0] DDR_PC_DMA_FPGA;
reg [31:0] DDR_PC_DMA_LEN;
reg [31:0] ETH_SEND_DATA_SIZE;
reg [31:0] ETH_RCV_DATA_SIZE; 
reg [31:0] ETH_DDR_SRC_ADDR; 
reg [31:0] ETH_DDR_DST_ADDR;  
reg [31:0] RECONFIG_ADDR;
reg [31:0] PC_USER1_DMA_SYS;
reg [31:0] PC_USER1_DMA_LEN;
reg [31:0] USER1_PC_DMA_SYS;
reg [31:0] USER1_PC_DMA_LEN;
reg [31:0] USER1_DDR_STR_ADDR;
reg [31:0] USER1_DDR_STR_LEN;
reg [31:0] DDR_USER1_STR_ADDR;
reg [31:0] DDR_USER1_STR_LEN;
reg [31:0] PC_USER2_DMA_SYS;
reg [31:0] PC_USER2_DMA_LEN;
reg [31:0] USER2_PC_DMA_SYS;
reg [31:0] USER2_PC_DMA_LEN;
reg [31:0] DDR_USER2_STR_ADDR;
reg [31:0] DDR_USER2_STR_LEN;
reg [31:0] USER2_DDR_STR_ADDR;
reg [31:0] USER2_DDR_STR_LEN;
reg [31:0] PC_USER3_DMA_SYS;
reg [31:0] PC_USER3_DMA_LEN;
reg [31:0] USER3_PC_DMA_SYS;
reg [31:0] USER3_PC_DMA_LEN;
reg [31:0] DDR_USER3_STR_ADDR;
reg [31:0] DDR_USER3_STR_LEN;
reg [31:0] USER3_DDR_STR_ADDR;
reg [31:0] USER3_DDR_STR_LEN;
reg [31:0] PC_USER4_DMA_SYS;
reg [31:0] PC_USER4_DMA_LEN;
reg [31:0] USER4_PC_DMA_SYS;
reg [31:0] USER4_PC_DMA_LEN;
reg [31:0] DDR_USER4_STR_ADDR;
reg [31:0] DDR_USER4_STR_LEN;
reg [31:0] USER4_DDR_STR_ADDR;
reg [31:0] USER4_DDR_STR_LEN;
reg [15:0] SYS_MON_DATA;
reg [31:0] ETH_RX_TIMER;  
reg [31:0] ETH_TX_TIMER;  

//local registers
reg        ddr_rd_ack;
reg        ddr_rd_ack_p;
reg        fpga_reg_wr_ack;
reg        ddr_pio_wr_ack;
reg        ddr_pio_wr_ack_p;
reg        system_dma_ack;
reg        system_dma_ack_p;
reg        clr_sys_ddr_dma_req;
reg        sys_ddr_dma_last_flag;
reg        sys_mon_rd_ack;
reg        sys_mon_rd_ack_p;
reg        sys_mon_en;
reg        sys_mon_en_p;
reg        intr_state;
reg        processor_clr_intr;
reg        ddr_user1_str_done;
reg        ddr_user1_str_done_p;
reg        user1_dma_done;
reg        user1_dma_done_f;
reg        ddr_user2_str_done;
reg        ddr_user2_str_done_p;
reg        user2_dma_done;
reg        user2_dma_done_f;
reg        ddr_user3_str_done;
reg        ddr_user3_str_done_p;
reg        user3_dma_done;
reg        user3_dma_done_f;
reg        ddr_user4_str_done;
reg        ddr_user4_str_done_p;
reg        user4_dma_done;
reg        user4_dma_done_f;

reg        enet_rx_done_sync_d1;
reg        enet_rx_done_sync;
reg        enet_tx_done_sync_d1;
reg        enet_tx_done_sync;

reg  [1:0] prev_user_clk; 
reg        user_swtch_clk_p;
reg        user_swtch_clk;
reg        user_clk_swtch_done;
reg        user_clk_swch_p;
wire       intr_pending;
reg        enet_done;
reg        enet_done_p;
reg        enet_intr;

reg        enet_link_stat;
reg        enet_link_stat_p;
reg        ddr_link_stat;
reg        ddr_link_stat_p;
reg        data_valid_p;
wire       sys_mon_access;
wire       data_valid_r;

assign  sys_mon_access            = ((addr_i== `SMT)|(addr_i== `SMA)|(addr_i== `SMV)|(addr_i== `SMP)|(addr_i== `SBV)|(addr_i== `SAC)) ? 1'b1 : 1'b0;

assign  ddr_sys_dma_wr_addr_o     = DDR_PC_DMA_SYS;

assign  o_pcie_ddr_ctrl_en        = CTRL_REG[0];
assign  o_pcie_ddr_dma_done_ack   = STAT_REG[0];
assign  o_pcie_ddr_dma_src_addr   = PC_DDR_DMA_SYS;
assign  o_pcie_ddr_dma_len        = PC_DDR_DMA_LEN;

assign  fpga_system_dma_req_o     = CTRL_REG[1];
assign  sys_fpga_dma_addr_o       = PC_DDR_DMA_FPGA;
assign  fpga_sys_dma_addr_o       = DDR_PC_DMA_FPGA;
assign  ddr_pio_addr_o            = PIO_ADDR;
assign  ddr_pio_data_o            = PIO_WR_DATA;
assign  dma_len_o                 = DDR_PC_DMA_LEN;

assign  o_enet_enable             = CTRL_REG[2];
assign  o_load_bitstream          = CTRL_REG[3];
assign  o_enet_loopback           = 1'b0;
assign  o_user_str1_en            = CTRL_REG[4];
assign  o_user_str1_done_ack      = STAT_REG[4];
assign  o_user_str1_dma_addr      = PC_USER1_DMA_SYS;
assign  o_user_str1_dma_len       = PC_USER1_DMA_LEN;
assign  user1_sys_strm_en_o       = CTRL_REG[5];
assign  user1_sys_strm_done_ack_o = STAT_REG[5];
assign  user1_sys_dma_wr_addr_o   = USER1_PC_DMA_SYS;
assign  user1_sys_stream_len_o    = USER1_PC_DMA_LEN;
assign  o_ddr_user1_str_en        = CTRL_REG[6];
assign  o_ddr_user1_str_done_ack  = STAT_REG[6];
assign  o_ddr_user1_str_addr      = DDR_USER1_STR_ADDR;
assign  o_ddr_user1_str_len       = DDR_USER1_STR_LEN;
assign  o_user1_ddr_str_en        = CTRL_REG[7];
assign  o_user1_ddr_str_done_ack  = STAT_REG[7];
assign  o_user1_ddr_str_len       = USER1_DDR_STR_LEN;
assign  o_user1_ddr_str_addr      = USER1_DDR_STR_ADDR;

assign  o_user_str2_en            = CTRL_REG[8];
assign  o_user_str2_done_ack      = STAT_REG[8];
assign  o_user_str2_dma_addr      = PC_USER2_DMA_SYS;
assign  o_user_str2_dma_len       = PC_USER2_DMA_LEN;
assign  user2_sys_strm_en_o       = CTRL_REG[9];
assign  user2_sys_strm_done_ack_o = STAT_REG[9];
assign  user2_sys_dma_wr_addr_o   = USER2_PC_DMA_SYS;
assign  user2_sys_stream_len_o    = USER2_PC_DMA_LEN;
assign  o_ddr_user2_str_en        = CTRL_REG[10];
assign  o_ddr_user2_str_done_ack  = STAT_REG[10];
assign  o_ddr_user2_str_addr      = DDR_USER2_STR_ADDR;
assign  o_ddr_user2_str_len       = DDR_USER2_STR_LEN;
assign  o_user2_ddr_str_en        = CTRL_REG[11];
assign  o_user2_ddr_str_done_ack  = STAT_REG[11];
assign  o_user2_ddr_str_len       = USER2_DDR_STR_LEN;
assign  o_user2_ddr_str_addr      = USER2_DDR_STR_ADDR;

assign  o_user_str3_en            = CTRL_REG[12];
assign  o_user_str3_done_ack      = STAT_REG[12];
assign  o_user_str3_dma_addr      = PC_USER3_DMA_SYS;
assign  o_user_str3_dma_len       = PC_USER3_DMA_LEN;
assign  user3_sys_strm_en_o       = CTRL_REG[13];
assign  user3_sys_strm_done_ack_o = STAT_REG[13];
assign  user3_sys_dma_wr_addr_o   = USER3_PC_DMA_SYS;
assign  user3_sys_stream_len_o    = USER3_PC_DMA_LEN;
assign  o_ddr_user3_str_en        = CTRL_REG[14];
assign  o_ddr_user3_str_done_ack  = STAT_REG[14];
assign  o_ddr_user3_str_addr      = DDR_USER3_STR_ADDR;
assign  o_ddr_user3_str_len       = DDR_USER3_STR_LEN;
assign  o_user3_ddr_str_en        = CTRL_REG[15];
assign  o_user3_ddr_str_done_ack  = STAT_REG[15];
assign  o_user3_ddr_str_len       = USER3_DDR_STR_LEN;
assign  o_user3_ddr_str_addr      = USER3_DDR_STR_ADDR;

assign  o_user_str4_en            = CTRL_REG[16];
assign  o_user_str4_done_ack      = STAT_REG[16];
assign  o_user_str4_dma_addr      = PC_USER4_DMA_SYS;
assign  o_user_str4_dma_len       = PC_USER4_DMA_LEN;
assign  user4_sys_strm_en_o       = CTRL_REG[17];
assign  user4_sys_strm_done_ack_o = STAT_REG[17];
assign  user4_sys_dma_wr_addr_o   = USER4_PC_DMA_SYS;
assign  user4_sys_stream_len_o    = USER4_PC_DMA_LEN;
assign  o_ddr_user4_str_en        = CTRL_REG[18];
assign  o_ddr_user4_str_done_ack  = STAT_REG[18];
assign  o_ddr_user4_str_addr      = DDR_USER4_STR_ADDR;
assign  o_ddr_user4_str_len       = DDR_USER4_STR_LEN;
assign  o_user4_ddr_str_en        = CTRL_REG[19];
assign  o_user4_ddr_str_done_ack  = STAT_REG[19];
assign  o_user4_ddr_str_len       = USER4_DDR_STR_LEN;
assign  o_user4_ddr_str_addr      = USER4_DDR_STR_ADDR;

assign  user_reset_o             = USR_CTRL_REG[0];
assign  user_clk_sel_o           = USR_CTRL_REG[2:1];

assign  o_enet_send_data_size    = ETH_SEND_DATA_SIZE;
assign  o_enet_rcv_data_size     = ETH_RCV_DATA_SIZE;
assign  o_enet_ddr_src_addr      = ETH_DDR_SRC_ADDR;
assign  o_enet_ddr_dest_addr     = ETH_DDR_DST_ADDR;

assign  o_boot_address           = RECONFIG_ADDR;

assign  fpga_reg_wr_ack_o        = fpga_reg_wr_ack|ddr_pio_wr_ack_p;
assign  sys_mon_addr_o           = addr_i[8:2];
assign  user_intr_ack_o          = processor_clr_intr & data_i[3];

assign  intr_pending             = |STAT_REG[19:0];

assign  data_valid_r             = data_valid_i & ~data_valid_p;


//Clock synchronizers for signals from DDR clock domain (200Mhz)
always @(posedge clk_i)
begin
    ddr_rd_ack           <=   ddr_pio_rd_ack_i;
    ddr_rd_ack_p         <=   ddr_rd_ack;
    system_dma_ack       <=   fpga_system_dma_ack_i;
    system_dma_ack_p     <=   system_dma_ack;
    ddr_pio_wr_ack       <=   ddr_pio_wr_ack_i;
    ddr_pio_wr_ack_p     <=   ddr_pio_wr_ack;
    sys_mon_rd_ack       <=   sys_mon_rdy_i;
    sys_mon_rd_ack_p     <=   sys_mon_rd_ack;
    ddr_user1_str_done   <=   i_ddr_user1_str_done;
    ddr_user1_str_done_p <=   ddr_user1_str_done;
    user1_dma_done       <=   i_user1_ddr_str_done;
    user1_dma_done_f     <=   user1_dma_done;
    ddr_user2_str_done   <=   i_ddr_user2_str_done;
    ddr_user2_str_done_p <=   ddr_user2_str_done; 
    user2_dma_done       <=   i_user2_ddr_str_done;
    user2_dma_done_f     <=   user2_dma_done;
    ddr_user3_str_done   <=   i_ddr_user3_str_done;
    ddr_user3_str_done_p <=   ddr_user3_str_done; 
    user3_dma_done       <=   i_user3_ddr_str_done;
    user3_dma_done_f     <=   user3_dma_done;	 
    ddr_user4_str_done   <=   i_ddr_user4_str_done;
    ddr_user4_str_done_p <=   ddr_user4_str_done; 
    user4_dma_done       <=   i_user4_ddr_str_done;
    user4_dma_done_f     <=   user4_dma_done;
    enet_done_p          <=   enet_done;
    enet_done            <=   i_enet_tx_done && i_enet_rx_done;
    enet_intr            <=   enet_done & ~enet_done_p;
    enet_link_stat       <=   i_enet_link_stat;
    enet_link_stat_p     <=   enet_link_stat;
    ddr_link_stat        <=   i_ddr_link_stat;
    ddr_link_stat_p      <=   ddr_link_stat;
	 data_valid_p         <=   data_valid_i;
end

//Clock synchronization for system monitor enable (50 MHz)
always @(posedge sys_mon_clk_i)
begin
    sys_mon_en_p <= sys_mon_en;
    sys_mon_en_o <= sys_mon_en_p;
end

// Read register data based on address. Registers for user stream interface are kept as write only so that
// when unused those are automatically optimised by the tool
always @(*)
begin
    case(addr_i)
        `VER:begin
            data_o  <=    VER;
        end
        `SCR:begin
            data_o  <=    SCR_PAD;
        end
        `CTRL:begin
            data_o  <=    CTRL_REG;
        end  
        `STA:begin
            data_o  <=    STAT_REG;
        end
        `PC_DDR_DMA_SYS:begin
            data_o  <=    PC_DDR_DMA_SYS;
         end
        `PC_DDR_DMA_FPGA:begin
            data_o  <=    PC_DDR_DMA_FPGA;
        end
        `PC_DDR_DMA_LEN:begin
            data_o  <=    PC_DDR_DMA_LEN; 
        end
        `DDR_PC_DMA_SYS:begin
            data_o  <=    DDR_PC_DMA_SYS;
        end
        `DDR_PC_DMA_FPGA:begin
            data_o  <=    DDR_PC_DMA_FPGA;
        end  
        `DDR_PC_DMA_LEN:begin
            data_o  <=    DDR_PC_DMA_LEN;
        end
        `PIOA:begin
            data_o  <=    PIO_ADDR; 
        end
        `PIOD:begin
            data_o  <=    PIO_RD_DATA;
        end
        `UCTR:begin
            data_o  <=    USR_CTRL_REG;
        end 
        `RECONFIG_ADDR:begin
            data_o   <=    RECONFIG_ADDR;
        end  
        `ETH_RX_STATISTIC: begin   
            data_o  <=    ETH_RX_TIMER;
        end
        `ETH_TX_STATISTIC: begin
            data_o  <=    ETH_TX_TIMER;
        end
        default:begin
            data_o  <=    SYS_MON_DATA;
        end
    endcase
end

// Write to global registers based on address and data valid and ack
always @(posedge clk_i)
begin
    fpga_reg_wr_ack              <=   1'b0;
    ddr_pc_dma_sys_addr_load_o   <=   1'b0;
    if(data_valid_r)
    begin
        fpga_reg_wr_ack   <=   1'b1;
        case(addr_i)
            `SCR:begin
                SCR_PAD  <=   data_i;
            end
            `UCTR:begin
                USR_CTRL_REG      <=   data_i;
            end
            `PIOA:begin
                PIO_ADDR          <=   data_i;
            end
            `PIOD:begin
                PIO_WR_DATA       <=   data_i;
                fpga_reg_wr_ack   <=   1'b0;
            end
                `PC_DDR_DMA_SYS:begin
                PC_DDR_DMA_SYS    <=  data_i;
            end
            `PC_DDR_DMA_FPGA:begin
                PC_DDR_DMA_FPGA   <=   data_i;
            end
            `PC_DDR_DMA_LEN:begin
                PC_DDR_DMA_LEN    <=   data_i;
            end
            `DDR_PC_DMA_SYS:begin
                DDR_PC_DMA_SYS     <= data_i;
                ddr_pc_dma_sys_addr_load_o  <=   1'b1;
            end
            `DDR_PC_DMA_FPGA:begin
                DDR_PC_DMA_FPGA <= data_i;
            end
            `DDR_PC_DMA_LEN:begin
                DDR_PC_DMA_LEN <= data_i;
            end
            `ETH_SEND_DATA_SIZE:begin
                ETH_SEND_DATA_SIZE  <=  data_i;
            end
            `ETH_RCV_DATA_SIZE:begin
                ETH_RCV_DATA_SIZE  <=  data_i;
            end  
            `ETH_DDR_SRC_ADDR:begin
                ETH_DDR_SRC_ADDR   <=  data_i;
            end
            `ETH_DDR_DST_ADDR:begin
                ETH_DDR_DST_ADDR   <=  data_i;
            end
            `RECONFIG_ADDR:begin
                RECONFIG_ADDR   <=    data_i;
            end
            `PC_USER1_DMA_SYS:begin
                PC_USER1_DMA_SYS   <=   data_i;
            end
            `PC_USER1_DMA_LEN:begin
                PC_USER1_DMA_LEN  <=   data_i;
            end
            `USER1_PC_DMA_SYS:begin
                USER1_PC_DMA_SYS  <= data_i;
            end
            `USER1_PC_DMA_LEN:begin
                USER1_PC_DMA_LEN  <= data_i;
            end
            `USER1_DDR_STR_ADDR:begin
                USER1_DDR_STR_ADDR <=  data_i;
            end
            `USER1_DDR_STR_LEN:begin
                USER1_DDR_STR_LEN <=  data_i;
            end
            `DDR_USER1_STR_ADDR:begin
                DDR_USER1_STR_ADDR <= data_i;
            end
            `DDR_USER1_STR_LEN:begin
                DDR_USER1_STR_LEN <= data_i; 
            end
            `PC_USER2_DMA_SYS:begin
                PC_USER2_DMA_SYS   <=   data_i;
            end
            `PC_USER2_DMA_LEN:begin
                PC_USER2_DMA_LEN  <=   data_i;
            end
            `USER2_PC_DMA_SYS:begin
                USER2_PC_DMA_SYS  <= data_i;
            end  
            `USER2_PC_DMA_LEN:begin
                USER2_PC_DMA_LEN  <= data_i;
            end
            `USER2_DDR_STR_ADDR:begin
                USER2_DDR_STR_ADDR <=  data_i;
            end
            `USER2_DDR_STR_LEN:begin
                USER2_DDR_STR_LEN <=  data_i;
            end
            `DDR_USER2_STR_ADDR:begin
                DDR_USER2_STR_ADDR <= data_i; 
            end  
            `DDR_USER2_STR_LEN:begin
                DDR_USER2_STR_LEN <= data_i;
            end
            `PC_USER3_DMA_SYS:begin
                PC_USER3_DMA_SYS   <=   data_i;
            end
            `PC_USER3_DMA_LEN:begin
                PC_USER3_DMA_LEN  <=   data_i;
            end
            `USER3_PC_DMA_SYS:begin
                USER3_PC_DMA_SYS  <= data_i;
            end  
            `USER3_PC_DMA_LEN:begin
                USER3_PC_DMA_LEN  <= data_i;
            end
            `USER3_DDR_STR_ADDR:begin
                USER3_DDR_STR_ADDR <=  data_i;
            end
            `USER3_DDR_STR_LEN:begin
                USER3_DDR_STR_LEN <=  data_i;
            end
            `DDR_USER3_STR_ADDR:begin
                DDR_USER3_STR_ADDR <= data_i; 
            end 
            `DDR_USER3_STR_LEN:begin
                DDR_USER3_STR_LEN <= data_i; 
            end
            `PC_USER4_DMA_SYS:begin
                PC_USER4_DMA_SYS   <=   data_i;
            end
            `PC_USER4_DMA_LEN:begin
                PC_USER4_DMA_LEN  <=   data_i;
            end
            `USER4_PC_DMA_SYS:begin
                USER4_PC_DMA_SYS  <= data_i;
            end  
            `USER4_PC_DMA_LEN:begin
                USER4_PC_DMA_LEN  <= data_i;
            end
            `USER4_DDR_STR_ADDR:begin
                USER4_DDR_STR_ADDR <=  data_i;
            end	
            `USER4_DDR_STR_LEN:begin
                USER4_DDR_STR_LEN <=  data_i;
            end
            `DDR_USER4_STR_ADDR:begin
                DDR_USER4_STR_ADDR <= data_i;
            end
            `DDR_USER4_STR_LEN:begin
                DDR_USER4_STR_LEN <= data_i; 
            end
            default:begin
                fpga_reg_wr_ack   <=   1'b1;				
            end				
        endcase
    end
end

//If the read register is not PIO register, ack immediately, else wait until data arrives from DDR
//Address bit 9 is to partiall decode the System monitor address. Be careful when modify the address
//due to this
always @(posedge clk_i)
begin
    if(fpga_reg_rd_i & (addr_i != `PIOD) & ~sys_mon_access)
        fpga_reg_rd_ack_o    <=   1'b1;
    else 
        fpga_reg_rd_ack_o    <=   ddr_rd_ack_p|sys_mon_rd_ack_p;
end

//Request the memory controller for DDR PIO data
always @(posedge clk_i)
begin
    if(ddr_rd_ack_p)
        ddr_pio_rd_req_o    <=   1'b0;
    else if((fpga_reg_rd_i & addr_i == `PIOD))
    begin
        ddr_pio_rd_req_o    <=   1'b1;
    end
end

//Latch the PIO data read from DDR
always @(posedge clk_i)
begin
    if(ddr_rd_ack_p)
	begin
       PIO_RD_DATA    <=    ddr_rd_data_i;
	end   
end


//Request the memory controller for DDR PIO data
always @(posedge clk_i)
begin
    if(sys_mon_rd_ack_p)
        sys_mon_en    <=   1'b0;
    else if((fpga_reg_rd_i & sys_mon_access) )
    begin
        sys_mon_en    <=   1'b1;
    end
end

always @(posedge clk_i)
begin
    if(sys_mon_rd_ack_p)
        SYS_MON_DATA <= sys_mon_data_i;
end


//Indicate the memory controller when PIO data is received
always @(posedge clk_i)
begin
    if(ddr_pio_wr_ack_p)
        ddr_pio_data_valid_o <=  1'b0;
    else if(data_valid_r & (addr_i == `PIOD))
        ddr_pio_data_valid_o <=  1'b1;
end


//control register updates
always @(posedge clk_i)
begin
    if(!rst_n)
        CTRL_REG    <=    32'd0;
    else
    begin
        if(data_valid_r & (addr_i == `CTRL))
        begin
            CTRL_REG    <=    CTRL_REG|data_i;   //Internall ored to keep the previously set bits
        end
        else
        begin
            if(i_pcie_ddr_dma_done)              
                CTRL_REG[0] <=    1'b0;
            if(system_dma_ack_p) 
                CTRL_REG[1] <=    1'b0;
            if (!(enet_rx_done_sync && enet_tx_done_sync))   //for enet
                    CTRL_REG[2] <=    1'b0;            
            if(i_user_str1_done)
                CTRL_REG[4] <=    1'b0; 
            if(user1_sys_strm_done_i) 
                CTRL_REG[5] <=    1'b0; 
            if(ddr_user1_str_done_p)
                CTRL_REG[6] <=    1'b0; 
            if(user1_dma_done_f)
                CTRL_REG[7] <=    1'b0; 
            if(i_user_str2_done)
                CTRL_REG[8] <=    1'b0; 
            if(user2_sys_strm_done_i) 
                CTRL_REG[9] <=    1'b0; 
            if(ddr_user2_str_done_p)
                CTRL_REG[10] <=    1'b0; 
            if(user2_dma_done_f)
                CTRL_REG[11] <=    1'b0; 
            if(i_user_str3_done)
                CTRL_REG[12] <=    1'b0; 
            if(user3_sys_strm_done_i) 
                CTRL_REG[13] <=    1'b0;
            if(ddr_user3_str_done_p)
                CTRL_REG[14] <=    1'b0; 
            if(user3_dma_done_f)
                CTRL_REG[15] <=    1'b0; 
            if(i_user_str4_done)
                CTRL_REG[16] <=    1'b0; 
            if(user4_sys_strm_done_i) 
                CTRL_REG[17] <=    1'b0; 
            if(ddr_user4_str_done_p)
                CTRL_REG[18] <=    1'b0; 
            if(user4_dma_done_f)
                CTRL_REG[19] <=    1'b0; 
        end 
    end
end


//status register updates
always @(posedge clk_i)
begin
    if(!rst_n)
    begin
        STAT_REG             <= 0;
        processor_clr_intr   <= 1'b0;
    end
    else
    begin
        processor_clr_intr   <= 1'b0;
        STAT_REG[31]         <= enet_link_stat_p;
        STAT_REG[30]         <= ddr_link_stat_p;
        STAT_REG[29]         <= i_pcie_link_stat;
        if(data_valid_r & (addr_i == `STA))
        begin
            STAT_REG[19:0]     <=   STAT_REG[19:0]^data_i[19:0];
            processor_clr_intr <=   1'b1;
        end
        else
        begin
            if(i_pcie_ddr_dma_done) 
                STAT_REG[0] <=    1'b1;  //indicates system to fpga dma is complete	
            if(system_dma_ack_p)
                STAT_REG[1] <=    1'b1;
            if(enet_intr)        //for enet
                STAT_REG[2] <=    1'b1;
            if(user_intr_req_i & ~user_intr_ack_o)
                STAT_REG[3] <=    1'b1;
            if(i_user_str1_done)
                STAT_REG[4] <=    1'b1; 
            if(user1_sys_strm_done_i) 
                 STAT_REG[5] <=    1'b1; 
            if(ddr_user1_str_done_p)
                STAT_REG[6] <=    1'b1;
            if(user1_dma_done_f)
                STAT_REG[7] <=    1'b1; 
            if(i_user_str2_done)
                STAT_REG[8] <=    1'b1; 
            if(user2_sys_strm_done_i) 
                STAT_REG[9] <=    1'b1; 
            if(ddr_user2_str_done_p)
                STAT_REG[10] <=    1'b1; 
            if(user2_dma_done_f)
                STAT_REG[11] <=    1'b1;
            if(i_user_str3_done)
                STAT_REG[12] <=    1'b1; 
            if(user3_sys_strm_done_i)
                 STAT_REG[13] <=    1'b1; 
            if(ddr_user3_str_done_p)
                STAT_REG[14] <=    1'b1; 
            if(user3_dma_done_f)
                STAT_REG[15] <=    1'b1;
            if(i_user_str4_done)
                STAT_REG[16] <=    1'b1; 
            if(user4_sys_strm_done_i) 
                STAT_REG[17] <=    1'b1; 
            if(ddr_user4_str_done_p)
                STAT_REG[18] <=    1'b1;
            if(user4_dma_done_f)
                STAT_REG[19] <=    1'b1;  
        end 
    end
end


//Interrupt control state machine. This is to make sure that the host PC doesn't miss any interrupt signal
//Once an interrupt is issued, the state machine waits until the host write into the status register indicating
//that it has received the interrupt.
always @(posedge clk_i)
begin
    if(!rst_n)
	 begin
	     intr_state  <=  INTR_IDLE;
		  intr_req_o  <=  1'b0;
	 end
	 else
	 begin
	     case(intr_state)
		      INTR_IDLE:begin
				    if(intr_pending)
					 begin
					     intr_req_o   <=   1'b1;
						  intr_state   <=  WAIT_ACK;
					 end
				end
				WAIT_ACK:begin
				    if(intr_req_done_i)
					     intr_req_o   <=   1'b0;
					 if(processor_clr_intr)
                   intr_state    <=    INTR_IDLE;					 
				end
		  endcase
	 end
end

// Clock Sync for Ethernet Done Signals 
always @(posedge clk_i)
begin   
    if(!rst_n)
    begin   
        enet_rx_done_sync_d1 <= 1'b1;
        enet_tx_done_sync_d1 <= 1'b1;
        enet_rx_done_sync    <= 1'b1;
        enet_tx_done_sync    <= 1'b1;
    end
    else begin  
        enet_rx_done_sync_d1 <= i_enet_rx_done;
        enet_rx_done_sync    <= enet_rx_done_sync_d1;
        enet_tx_done_sync_d1 <= i_enet_tx_done;
        enet_tx_done_sync    <= enet_tx_done_sync_d1;
    end
end


always @(posedge clk_i)
begin   
    if(!rst_n)
    begin   
        ETH_RX_TIMER <= 32'd0;    
        ETH_TX_TIMER <= 32'd0;
    end
    else begin
        if (CTRL_REG[2] && (~enet_rx_done_sync))
            ETH_RX_TIMER <= 32'd0; // Reset at start of a Test
        if (CTRL_REG[2] && (~enet_tx_done_sync))
            ETH_TX_TIMER <= 32'd0; // Reset at start of a Test
        if (enet_rx_done_sync)
            ETH_RX_TIMER <= i_enet_rx_cnt;
        if (enet_tx_done_sync)
            ETH_TX_TIMER <= i_enet_tx_cnt;
    end
end

always @(posedge clk_i)
begin
    if(prev_user_clk != USR_CTRL_REG[2:1])
	     user_swtch_clk  <=  1'b1;
	 else if(user_clk_swtch_done)
	     user_swtch_clk  <=  1'b0;
		  
	prev_user_clk   <=  USR_CTRL_REG[2:1];
	
	user_clk_swch_p <=  user_clk_swch_o;
	user_clk_swtch_done <=  user_clk_swch_p;
end

always @(posedge sys_mon_clk_i)
begin
    user_swtch_clk_p  <=  user_swtch_clk;
    user_clk_swch_o   <=  user_swtch_clk_p;
end

endmodule
