//--------------------------------------------------------------------------------
// Project    : SWITCH
// File       : user_logic.v
// Version    : 0.1
// Author     : Vipin.K
//
// Description: A dummy user logic for testing purpose
//--------------------------------------------------------------------------------

module user_logic(
    input              i_pcie_clk, //250Mhz
    input              i_ddr_clk,  //200Mhz
    input              i_user_clk,  //configurable
    input              i_rst,
    //reg i/f 
    input    [31:0]    i_user_data,
    input    [19:0]    i_user_addr,
    input              i_user_wr_req,
    output  reg [31:0] o_user_data,
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
    input    [63:0]    i_ddr_str1_data,
    output             o_ddr_str1_data_valid,
    input              i_ddr_str1_ack,
    output   reg [63:0]o_ddr_str1_data,
    //ddr strm 2
    input              i_ddr_str2_data_valid,
    output             o_ddr_str2_ack,
    input    [63:0]    i_ddr_str2_data,
    output             o_ddr_str2_data_valid,
    input              i_ddr_str2_ack,
    output   reg [63:0]o_ddr_str2_data,
    //ddr strm 3
    input              i_ddr_str3_data_valid,
    output             o_ddr_str3_ack,
    input    [63:0]    i_ddr_str3_data,
    output             o_ddr_str3_data_valid,
    input              i_ddr_str3_ack,
    output   reg [63:0]o_ddr_str3_data,	 
    //ddr strm 4
    input              i_ddr_str4_data_valid,
    output             o_ddr_str4_ack,
    input    [63:0]    i_ddr_str4_data,
    output             o_ddr_str4_data_valid,
    input              i_ddr_str4_ack,
    output   reg [63:0]o_ddr_str4_data,
    //stream i/f 1
    input              i_pcie_str1_data_valid,
    output             o_pcie_str1_ack,
    input    [63:0]    i_pcie_str1_data,
    output             o_pcie_str1_data_valid,
    input              i_pcie_str1_ack,
    output   reg [63:0]o_pcie_str1_data,
    //stream i/f 2       
    input              i_pcie_str2_data_valid,
    output             o_pcie_str2_ack,
    input    [63:0]    i_pcie_str2_data,
    output             o_pcie_str2_data_valid,
    input              i_pcie_str2_ack,
    output   reg [63:0]o_pcie_str2_data,
    //stream i/f 3
    input              i_pcie_str3_data_valid,
    output             o_pcie_str3_ack,
    input    [63:0]    i_pcie_str3_data,
    output             o_pcie_str3_data_valid,
    input              i_pcie_str3_ack,
    output   reg [63:0]o_pcie_str3_data,
    //stream i/f 4
    input              i_pcie_str4_data_valid,
    output             o_pcie_str4_ack,
    input    [63:0]    i_pcie_str4_data,
    output             o_pcie_str4_data_valid,
    input              i_pcie_str4_ack,
    output   reg [63:0]o_pcie_str4_data,
    //interrupt if
    output             o_intr_req,
    input              i_intr_ack
);

reg [31:0] user_control;
assign o_intr_req             = 1'b0;
assign o_ddr_wr_data          = 0;
assign o_ddr_wr_data_be_n     = 0;
assign o_ddr_wr_data_valid    = 0;
assign o_ddr_addr             = 0;
assign o_ddr_rd               = 0;
assign o_ddr_str1_ack         = 1'b1;
assign o_ddr_str2_ack         = 1'b1;
assign o_ddr_str3_ack         = 1'b1;
assign o_ddr_str4_ack         = 1'b1;
assign o_pcie_str1_ack        = 1'b1;
assign o_pcie_str2_ack        = 1'b1;
assign o_pcie_str3_ack        = 1'b1;
assign o_pcie_str4_ack        = 1'b1;
assign o_pcie_str1_data_valid = 1'b1;
assign o_pcie_str2_data_valid = 1'b1;
assign o_pcie_str3_data_valid = 1'b1;
assign o_pcie_str4_data_valid = 1'b1;
assign o_ddr_str1_data_valid  = 1'b1;
assign o_ddr_str2_data_valid  = 1'b1;
assign o_ddr_str3_data_valid  = 1'b1;
assign o_ddr_str4_data_valid  = 1'b1;

always @(posedge i_user_clk)
begin
    o_pcie_str1_data       <= i_pcie_str1_data;
    o_pcie_str2_data       <= i_pcie_str2_data;
    o_pcie_str3_data       <= i_pcie_str3_data;
    o_pcie_str4_data       <= i_pcie_str4_data;
    o_ddr_str1_data        <= i_ddr_str1_data;
    o_ddr_str2_data        <= i_ddr_str2_data;
    o_ddr_str3_data        <= i_ddr_str3_data;
    o_ddr_str4_data        <= i_ddr_str4_data;
end

//User register write
always @(posedge i_pcie_clk)
begin
    if(i_user_wr_req)
    begin
        case(i_user_addr)
          'h400:begin
              user_control <= i_user_data;  
          end
        endcase
    end
end

//User register read
always @(posedge i_pcie_clk)
begin
   case(i_user_addr)
     'h400:begin
         o_user_data <= user_control;
     end
   endcase
   o_user_rd_ack  <= i_user_rd_req;
end

endmodule