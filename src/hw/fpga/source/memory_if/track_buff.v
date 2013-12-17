//--------------------------------------------------------------------------------
// Project    : UPRA
// File       : track_buff.v
// Version    : 0.1
// Author     : Vipin.K
//
// Description: Buffer to track the back to back DDR read operation
//
//--------------------------------------------------------------------------------
module track_buff(
input i_clk,
input i_data,
input [7:0] i_wr_ptr,
input [7:0] i_rd_ptr,
input i_wr_en,
output o_data
);

reg [0:0] mem[255:0];

always @(posedge i_clk)
begin
  if(i_wr_en)
      mem[i_wr_ptr] <= i_data;
end


assign o_data = mem[i_rd_ptr];

endmodule