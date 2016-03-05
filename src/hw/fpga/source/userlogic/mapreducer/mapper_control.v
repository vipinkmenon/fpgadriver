module mapper_controller #
(
parameter NUM_MAPPERS = 2
)
(
input                         i_clk,
input                         i_rst,
input [NUM_MAPPERS-1:0]       i_mapper_rdy,
input                         i_pcie_strm_valid,
output reg [NUM_MAPPERS-1:0]  o_pcie_strm_valid,
output                        o_pcie_strm_rdy
);

reg [$clog2(NUM_MAPPERS)-1:0] curr_mapper;

assign o_pcie_strm_rdy = i_mapper_rdy[curr_mapper];

always @(*)
begin
    o_pcie_strm_valid   <= {NUM_MAPPERS{1'd0}};
	 o_pcie_strm_valid[curr_mapper] <= i_pcie_strm_valid;
end

always @(posedge i_clk)
begin
    if(i_rst)
	     curr_mapper <=  0;
	 else
    begin
		  curr_mapper    <=    curr_mapper + 1'b1;
    end	 
end

endmodule
