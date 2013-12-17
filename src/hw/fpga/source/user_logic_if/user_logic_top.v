//--------------------------------------------------------------------------------
// Project    : SWITCH
// File       : user_logic_top.v
// Version    : 0.1
// Author     : Vipin.K
//
// Description: User logic wrapper
//
//--------------------------------------------------------------------------------

module user_logic_top(
    input              i_pcie_clk, //250Mhz
    input              i_ddr_clk,  //200Mhz
	 input              i_user_clk,
    input              i_rst,
    //reg i/f 
    input    [31:0]    i_user_data,
    input    [19:0]    i_user_addr,
    input              i_user_wr_req,
    output   [31:0]    o_user_data,
    output             o_user_rd_ack,
    input              i_user_rd_req, 
    //ddr i/f
    output   [255:0]   o_ddr_wr_data,
    output   [31:0]    o_ddr_wr_data_be_n,
    output             o_ddr_wr_data_valid,
    output   [26:0]    o_ddr_addr,
    output             o_ddr_rd,
    input    [255:0]   i_ddr_rd_data,
    input              i_ddr_rd_data_valid,
    input              i_ddr_wr_ack,
    input              i_ddr_rd_ack,
    //ddr strm 1
    input              i_ddr_str1_data_valid,
    output             o_ddr_str1_ack,
    input    [63:0]    i_ddr_str1_data,
    output             o_ddr_str1_data_valid,
    input              i_ddr_str1_ack,
    output   [63:0]    o_ddr_str1_data,
    //ddr strm 2
    input              i_ddr_str2_data_valid,
    output             o_ddr_str2_ack,
    input    [63:0]    i_ddr_str2_data,
    output             o_ddr_str2_data_valid,
    input              i_ddr_str2_ack,
    output   [63:0]    o_ddr_str2_data,
    //ddr strm 3
    input              i_ddr_str3_data_valid,
    output             o_ddr_str3_ack,
    input    [63:0]    i_ddr_str3_data,
    output             o_ddr_str3_data_valid,
    input              i_ddr_str3_ack,
    output   [63:0]    o_ddr_str3_data,	 
    //ddr strm 4
    input              i_ddr_str4_data_valid,
    output             o_ddr_str4_ack,
    input    [63:0]    i_ddr_str4_data,
    output             o_ddr_str4_data_valid,
    input              i_ddr_str4_ack,
    output   [63:0]    o_ddr_str4_data,
    //stream i/f 1
    input              i_pcie_str1_data_valid,
    output             o_pcie_str1_ack,
    input    [63:0]    i_pcie_str1_data,
    output             o_pcie_str1_data_valid,
    input              i_pcie_str1_ack,
    output   [63:0]    o_pcie_str1_data,
    //stream i/f 2       
    input              i_pcie_str2_data_valid,
    output             o_pcie_str2_ack,
    input    [63:0]    i_pcie_str2_data,
    output             o_pcie_str2_data_valid,
    input              i_pcie_str2_ack,
    output   [63:0]    o_pcie_str2_data,
    //stream i/f 3
    input              i_pcie_str3_data_valid,
    output             o_pcie_str3_ack,
    input    [63:0]    i_pcie_str3_data,
    output             o_pcie_str3_data_valid,
    input              i_pcie_str3_ack,
    output   [63:0]    o_pcie_str3_data,
    //stream i/f 4
    input              i_pcie_str4_data_valid,
    output             o_pcie_str4_ack,
    input    [63:0]    i_pcie_str4_data,
    output             o_pcie_str4_data_valid,
    input              i_pcie_str4_ack,
    output   [63:0]    o_pcie_str4_data,
    //interrupt if
    output             o_intr_req,
    input              i_intr_ack
);



// Instantiate the module
user_logic ul (
    .i_pcie_clk(i_pcie_clk), 
    .i_ddr_clk(i_ddr_clk), 
	 .i_user_clk(i_user_clk),
    .i_rst(i_rst), 
    .i_user_data(i_user_data), 
    .i_user_addr(i_user_addr), 
    .i_user_wr_req(i_user_wr_req), 
    .o_user_data(o_user_data), 
    .o_user_rd_ack(o_user_rd_ack), 
    .i_user_rd_req(i_user_rd_req), 
    .o_ddr_wr_data(o_ddr_wr_data), 
    .o_ddr_wr_data_be_n(o_ddr_wr_data_be_n), 
    .o_ddr_wr_data_valid(o_ddr_wr_data_valid), 
    .o_ddr_addr(o_ddr_addr), 
    .o_ddr_rd(o_ddr_rd), 
    .i_ddr_rd_data(i_ddr_rd_data), 
    .i_ddr_rd_data_valid(i_ddr_rd_data_valid), 
    .i_ddr_wr_ack(i_ddr_wr_ack), 
    .i_ddr_rd_ack(i_ddr_rd_ack), 
    .i_ddr_str1_data_valid(i_ddr_str1_data_valid), 
    .o_ddr_str1_ack(o_ddr_str1_ack), 
    .i_ddr_str1_data(i_ddr_str1_data), 
    .o_ddr_str1_data_valid(o_ddr_str1_data_valid), 
    .i_ddr_str1_ack(i_ddr_str1_ack), 
    .o_ddr_str1_data(o_ddr_str1_data), 
    .i_ddr_str2_data_valid(i_ddr_str2_data_valid), 
    .o_ddr_str2_ack(o_ddr_str2_ack), 
    .i_ddr_str2_data(i_ddr_str2_data), 
    .o_ddr_str2_data_valid(o_ddr_str2_data_valid), 
    .i_ddr_str2_ack(i_ddr_str2_ack), 
    .o_ddr_str2_data(o_ddr_str2_data), 
    .i_ddr_str3_data_valid(i_ddr_str3_data_valid), 
    .o_ddr_str3_ack(o_ddr_str3_ack), 
    .i_ddr_str3_data(i_ddr_str3_data), 
    .o_ddr_str3_data_valid(o_ddr_str3_data_valid), 
    .i_ddr_str3_ack(i_ddr_str3_ack), 
    .o_ddr_str3_data(o_ddr_str3_data),  
    .i_ddr_str4_data_valid(i_ddr_str4_data_valid), 
    .o_ddr_str4_ack(o_ddr_str4_ack), 
    .i_ddr_str4_data(i_ddr_str4_data), 
    .o_ddr_str4_data_valid(o_ddr_str4_data_valid), 
    .i_ddr_str4_ack(i_ddr_str4_ack), 
    .o_ddr_str4_data(o_ddr_str4_data), 
    .i_pcie_str1_data_valid(i_pcie_str1_data_valid), 
    .o_pcie_str1_ack(o_pcie_str1_ack), 
    .i_pcie_str1_data(i_pcie_str1_data), 
    .o_pcie_str1_data_valid(o_pcie_str1_data_valid), 
    .i_pcie_str1_ack(i_pcie_str1_ack), 
    .o_pcie_str1_data(o_pcie_str1_data), 
    .i_pcie_str2_data_valid(i_pcie_str2_data_valid), 
    .o_pcie_str2_ack(o_pcie_str2_ack), 
    .i_pcie_str2_data(i_pcie_str2_data), 
    .o_pcie_str2_data_valid(o_pcie_str2_data_valid), 
    .i_pcie_str2_ack(i_pcie_str2_ack), 
    .o_pcie_str2_data(o_pcie_str2_data), 
    .i_pcie_str3_data_valid(i_pcie_str3_data_valid), 
    .o_pcie_str3_ack(o_pcie_str3_ack), 
    .i_pcie_str3_data(i_pcie_str3_data), 
    .o_pcie_str3_data_valid(o_pcie_str3_data_valid), 
    .i_pcie_str3_ack(i_pcie_str3_ack), 
    .o_pcie_str3_data(o_pcie_str3_data),
    .i_pcie_str4_data_valid(i_pcie_str4_data_valid), 
    .o_pcie_str4_ack(o_pcie_str4_ack), 
    .i_pcie_str4_data(i_pcie_str4_data), 
    .o_pcie_str4_data_valid(o_pcie_str4_data_valid), 
    .i_pcie_str4_ack(i_pcie_str4_ack), 
    .o_pcie_str4_data(o_pcie_str4_data),
    .o_intr_req(o_intr_req), 
    .i_intr_ack(i_intr_ack)
    );
 

endmodule
