`define NUM_MAPPERS 64

module user_logic(
    input              i_pcie_clk, //250Mhz
    input              i_ddr_clk,  //200Mhz
    input              i_user_clk,  //configurable
    input              i_rst,
    //reg i/f 
    input    [31:0]    i_user_data,
    input    [19:0]    i_user_addr,
    input              i_user_wr_req,
    output      [31:0] o_user_data,
    output  reg        o_user_rd_ack,
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
    input        [63:0]i_ddr_str1_data,
    output             o_ddr_str1_data_valid,
    input              i_ddr_str1_ack,
    output       [63:0]o_ddr_str1_data,
    //ddr strm 2
    input              i_ddr_str2_data_valid,
    output             o_ddr_str2_ack,
    input        [63:0]i_ddr_str2_data,
    output             o_ddr_str2_data_valid,
    input              i_ddr_str2_ack,
    output       [63:0]o_ddr_str2_data,
    //ddr strm 3
    input              i_ddr_str3_data_valid,
    output             o_ddr_str3_ack,
    input        [63:0]i_ddr_str3_data,
    output             o_ddr_str3_data_valid,
    input              i_ddr_str3_ack,
    output       [63:0]o_ddr_str3_data,	 
    //ddr strm 4
    input              i_ddr_str4_data_valid,
    output             o_ddr_str4_ack,
    input        [63:0]i_ddr_str4_data,
    output             o_ddr_str4_data_valid,
    input              i_ddr_str4_ack,
    output       [63:0]o_ddr_str4_data,
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

assign o_intr_req             = 1'b0;
assign o_pcie_str1_data_valid = 1'b1;
assign o_pcie_str2_data_valid = 1'b1;
assign o_pcie_str3_data_valid = 1'b1;
assign o_pcie_str4_data_valid = 1'b1;
assign o_ddr_str1_data_valid  = 1'b1;
assign o_ddr_str2_data_valid  = 1'b1;
assign o_ddr_str3_data_valid  = 1'b1;
assign o_ddr_str4_data_valid  = 1'b1;

//User register read
always @(posedge i_user_clk)
begin
   o_user_rd_ack  <= i_user_rd_req;
end

map_reducer #(
    .NUM_MAPPERS(64)
    )
     mr1(
    .i_clk(i_pcie_clk), 
    .i_rst(i_rst), 
    .i_strm_data(i_pcie_str1_data), 
    .i_strm_data_valid(i_pcie_str1_data_valid), 
    .o_strm_data_rdy(o_pcie_str1_ack), 
    .o_data_count(o_pcie_str1_data)
    );
	 
map_reducer #(
    .NUM_MAPPERS(64)
    )mr2 (
    .i_clk(i_pcie_clk), 
    .i_rst(i_rst), 
    .i_strm_data(i_pcie_str2_data), 
    .i_strm_data_valid(i_pcie_str2_data_valid), 
    .o_strm_data_rdy(o_pcie_str2_ack), 
    .o_data_count(o_pcie_str2_data)
    );
	 
map_reducer #(
    .NUM_MAPPERS(64)
    )mr3 (
    .i_clk(i_pcie_clk), 
    .i_rst(i_rst), 
    .i_strm_data(i_pcie_str3_data), 
    .i_strm_data_valid(i_pcie_str3_data_valid), 
    .o_strm_data_rdy(o_pcie_str3_ack), 
    .o_data_count(o_pcie_str3_data)
    );
	 
map_reducer #(
    .NUM_MAPPERS(64)
    )mr4 (
    .i_clk(i_pcie_clk), 
    .i_rst(i_rst), 
    .i_strm_data(i_pcie_str4_data), 
    .i_strm_data_valid(i_pcie_str4_data_valid), 
    .o_strm_data_rdy(o_pcie_str4_ack), 
    .o_data_count(o_pcie_str4_data)
    );


map_reducer #(
    .NUM_MAPPERS(64)
    )mr5 (
    .i_clk(i_ddr_clk), 
    .i_rst(i_rst), 
    .i_strm_data(i_ddr_str1_data), 
    .i_strm_data_valid(i_ddr_str1_data_valid), 
    .o_strm_data_rdy(o_ddr_str1_ack), 
    .o_data_count(o_ddr_str1_data)
    );
	 
map_reducer #(
    .NUM_MAPPERS(64)
    )mr6 (
    .i_clk(i_ddr_clk), 
    .i_rst(i_rst), 
    .i_strm_data(i_ddr_str2_data), 
    .i_strm_data_valid(i_ddr_str2_data_valid), 
    .o_strm_data_rdy(o_ddr_str2_ack), 
    .o_data_count(o_ddr_str2_data)
    );
	 
map_reducer #(
    .NUM_MAPPERS(64)
    )mr7 (
    .i_clk(i_ddr_clk), 
    .i_rst(i_rst), 
    .i_strm_data(i_ddr_str3_data), 
    .i_strm_data_valid(i_ddr_str3_data_valid), 
    .o_strm_data_rdy(o_ddr_str3_ack), 
    .o_data_count(o_ddr_str3_data)
    );
	 
map_reducer #(
    .NUM_MAPPERS(64)
    )mr8 (
    .i_clk(i_ddr_clk), 
    .i_rst(i_rst), 
    .i_strm_data(i_ddr_str4_data), 
    .i_strm_data_valid(i_ddr_str4_data_valid), 
    .o_strm_data_rdy(o_ddr_str4_ack), 
    .o_data_count(o_ddr_str4_data)
    );

assign o_user_data = o_pcie_str1_data;

endmodule
