module map_reducer #(
NUM_MAPPERS = 64
)
(
input                    i_clk,
input                    i_rst,
input  [63:0]            i_strm_data,
input                    i_strm_data_valid,
output                   o_strm_data_rdy,
output [31:0]            o_data_count
);

wire [NUM_MAPPERS-1:0] mapper_rdy;
wire [NUM_MAPPERS-1:0] data_valid;
wire [(32*NUM_MAPPERS)-1:0] data_count;
wire [31:0] reduced_data_count;

mapper_controller 
  #(
   .NUM_MAPPERS(NUM_MAPPERS)
  )
  mc(
  .i_clk(i_clk),
  .i_rst(i_rst),
  .i_mapper_rdy(mapper_rdy),
  .i_pcie_strm_valid(i_strm_data_valid),
  .o_pcie_strm_valid(data_valid),
  .o_pcie_strm_rdy(o_strm_data_rdy)
);

reducer  #(
   .NUM_MAPPERS(NUM_MAPPERS)
)
reducer(
  .i_clk(i_clk), 
  .i_rst(i_rst), 
  .i_data_count(data_count), 
  .o_data_count(o_data_count)
);



generate
  genvar i;
   for (i=0; i < NUM_MAPPERS; i=i+1) begin : Mapper
       mapper map(
		 .i_clk(i_clk),
		 .i_rst(i_rst),
		 .i_data_valid(data_valid[i]),
		 .o_data_rdy(mapper_rdy[i]),
		 .i_data(i_strm_data),
		 .o_count(data_count[(i*32)+31:i*32])
		 );
   end
endgenerate


endmodule