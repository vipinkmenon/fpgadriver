module mapper(
input         i_clk,
input         i_rst,
input         i_data_valid,
output        o_data_rdy,
input  [63:0] i_data,
output [31:0] o_count
);

assign o_count = word_count;


wire         char_valid;
wire [7:0]   char;
reg  [127:0] in_word;
wire [127:0] word;
reg  [31:0]  word_count;
	

assign word = 128'h68656c6c6F0000000000000000000000;


always @(posedge i_clk)
begin
    if(i_rst)
	 begin
	     in_word    <=  128'd0;
		  word_count <=  0;
	 end
    else if(char_valid & (char >= 97 & char <= 122))
	     in_word    <=  {char,in_word[127:8]};
	 else if(char_valid)
	 begin
	     in_word    <=  128'd0;
		  if(word == in_word)
		      word_count <= word_count + 1;
	 end	  
end

fifo_128_8 mapper_fifo (
    .i_clk(i_clk), 
    .i_rst_n(!i_rst), 
    .i_slv_valid(i_data_valid), 
    .o_slv_rdy(o_data_rdy), 
    .i_slv_data(i_data), 
    .o_mst_data(char), 
    .o_mst_valid(char_valid), 
    .i_mst_rdy(1'b1)
);

endmodule
