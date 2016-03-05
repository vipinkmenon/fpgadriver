module fifo_128_8(
input wire         i_clk,
input wire         i_rst_n,
input wire         i_slv_valid,
output wire        o_slv_rdy,
input wire [63:0]  i_slv_data,
output reg [7:0]   o_mst_data,
output wire        o_mst_valid,
input              i_mst_rdy
);

reg [63:0]  mem [0:15];
reg [3:0]   wr_addr;
reg [6:0]   rd_addr;
reg [7:0]   data_count;

assign o_mst_valid = (data_count > 0) ? 1'b1 : 1'b0;
assign o_slv_rdy   = (data_count < 120) ? 1'b1 : 1'b0;
assign valid_wr    = i_slv_valid & o_slv_rdy;
assign valid_rd    = o_mst_valid & i_mst_rdy;

always @(posedge i_clk)
begin
    if(!i_rst_n)
	 begin
	    wr_addr <= 0;
	end
	else
	begin
	   if(valid_wr)
		begin
		    mem[wr_addr] <= i_slv_data;
			 wr_addr      <= wr_addr + 1;
		end	
	end
end


always @(posedge i_clk)
begin
   if(!i_rst_n)
	begin
	    rd_addr <= 0;
	end
	else
	begin
	    if(valid_rd)
		 begin
			rd_addr      <= rd_addr + 1'b1;
		end	
	end
end

always@(*)
begin
    case(rd_addr[2:0])
	    0:begin
		      o_mst_data <= mem[rd_addr[6:3]][7:0];
		 end
	    1:begin
		      o_mst_data <= mem[rd_addr[6:3]][15:8];
		 end
	    2:begin
		      o_mst_data <= mem[rd_addr[6:3]][23:16];
		 end
		 3:begin
		      o_mst_data <= mem[rd_addr[6:3]][31:24];
		 end
	    4:begin
		      o_mst_data <= mem[rd_addr[6:3]][39:32];
		 end
	    5:begin
		      o_mst_data <= mem[rd_addr[6:3]][47:40];
		 end
	    6:begin
		      o_mst_data <= mem[rd_addr[6:3]][55:48];
		 end
		 7:begin
		      o_mst_data <= mem[rd_addr[6:3]][63:56];
		 end	 
	 endcase
end

always @(posedge i_clk)
begin
    if(!i_rst_n)
	begin
	    data_count <= 0;
	end
	else
	begin
      if(valid_wr & !valid_rd)
		    data_count <= data_count + 8;
		else if(!valid_wr & valid_rd)
          data_count <= data_count - 1'b1;
		else if(valid_wr & valid_rd)
          data_count <= data_count + 7;			 
	end
end

endmodule
