//--------------------------------------------------------------------------------
// Project    : SWITCH
// File       : eth_tcr_pack.v
// Version    : 0.2
// Author     : Shreejith S
//
// Description: Ethernet Tx Module Packer
//
//--------------------------------------------------------------------------------
module eth_tcr_pack #(parameter dst_addr = 48'h001F293A10FD,src_addr = 48'hAABBCCDDEEFF,max_data_size = 16'd1024)
(
//uer i/f
output            o_axi_tx_clk,
output            o_axi_tx_rst_n,
input      [7:0]  i_axi_tx_tdata,
input             i_axi_tx_data_tvalid,
output            o_axi_tx_data_tready,
input             i_axi_tx_data_tlast,
//from ethernet client fifo
input    	      i_axi_tx_clk,
input    	      i_axi_tx_rst_n,
output reg 	      o_tx_axis_fifo_tvalid,
output reg  [7:0] o_tx_axis_fifo_tdata,
output reg        o_tx_axis_fifo_tlast,
input             i_tx_axis_fifo_tready
);

wire [11:0] fifo_data_cnt;
reg [15:0] pkt_len_cnt;
reg [7:0] addr [11:0];
reg pkt_fifo_rd;
reg [2:0] state;
wire [7:0] pkt_fifo_data;
reg tx_data_tlast_registered;
reg clr_last_tcr;
reg [15:0] eth_pkt_len;

parameter idle          = 3'b000,
          send_dst_addr = 3'b001,
			 send_src_addr = 3'b010,
			 send_len      = 3'b011,
			 send_data     = 3'b100; 
//parameter max_data_size = 16'd1024;

initial
begin
    addr[0]  <= dst_addr[47:40];
    addr[1]  <= dst_addr[39:32];
    addr[2]  <= dst_addr[31:24];
    addr[3]  <= dst_addr[23:16];
    addr[4]  <= dst_addr[15:8];
    addr[5]  <= dst_addr[7:0];
	 addr[6]  <= src_addr[47:40];
	 addr[7]  <= src_addr[39:32];
	 addr[8]  <= src_addr[31:24];
	 addr[9]  <= src_addr[23:16];
	 addr[10] <= src_addr[15:8];
	 addr[11] <= src_addr[7:0];
end

assign o_axi_tx_clk = i_axi_tx_clk;
assign o_axi_tx_rst_n = i_axi_tx_rst_n;

dp_ram pkt_fifo (
  .s_aclk(i_axi_tx_clk), 
  .s_aresetn(i_axi_tx_rst_n), 
  .s_axis_tvalid(i_axi_tx_data_tvalid), 
  .s_axis_tready(o_axi_tx_data_tready), 
  .s_axis_tdata(i_axi_tx_tdata),
  
  .m_axis_tvalid(), // output m_axis_tvalid
  .m_axis_tready(pkt_fifo_rd), // input m_axis_tready
  .m_axis_tdata(pkt_fifo_data), // output [7 : 0] m_axis_tdata
  .axis_data_count(fifo_data_cnt) // output [11 : 0] axis_data_count
);


always @(posedge i_axi_tx_clk)
begin
    if(~i_axi_tx_rst_n)
	     tx_data_tlast_registered    <=    1'b0;
	 else
    begin	 
        if(i_axi_tx_data_tlast)
	         tx_data_tlast_registered  <=   1'b1;
	     else if(clr_last_tcr)
	         tx_data_tlast_registered  <=   1'b0;
	 end			 
end

always @(posedge i_axi_tx_clk)
begin
    if(~i_axi_tx_rst_n)
	 begin
	     pkt_len_cnt    <=   0;
		  o_tx_axis_fifo_tlast <= 1'b0;
		  o_tx_axis_fifo_tvalid <= 1'b0;
		  state <= idle;
		  clr_last_tcr <= 1'b0;
		  eth_pkt_len <= 'd0;
          o_tx_axis_fifo_tdata <= 8'd0;
	 end
	 else
	 begin
	     case(state)
		      idle:begin
				    pkt_len_cnt           <=   0; 
					 o_tx_axis_fifo_tlast  <= 1'b0;
					 o_tx_axis_fifo_tvalid <= 1'b0;
					 /*if(fifo_data_cnt==1000 & tx_data_tlast_registered)
					 begin
					     state           <= send_dst_addr;
						  eth_pkt_len     <= 16'h03E8;
						  clr_last_tcr    <= 1'b1;
					 end
				    else*/ 
					 if(fifo_data_cnt>=max_data_size)
					 begin
					     state           <= send_dst_addr;
						  eth_pkt_len     <= max_data_size;
					 end
					 else if(tx_data_tlast_registered)
					 begin
					    state           <= send_dst_addr;
						 eth_pkt_len     <= fifo_data_cnt;
						 clr_last_tcr    <= 1'b1;
					 end
				end
				send_dst_addr:begin
				     clr_last_tcr    <= 1'b0;
				     if(i_tx_axis_fifo_tready)
					  begin
					      o_tx_axis_fifo_tvalid    <=    1'b1;
							o_tx_axis_fifo_tdata     <=    addr[pkt_len_cnt];
							pkt_len_cnt              <=    pkt_len_cnt + 1'b1;
							if(pkt_len_cnt==5)
							begin
							    state   <=   send_src_addr;
							end
					  end
				end
				send_src_addr:begin
				     if(i_tx_axis_fifo_tready)
					  begin
					      o_tx_axis_fifo_tvalid    <=    1'b1;
							o_tx_axis_fifo_tdata     <=    addr[pkt_len_cnt];
							pkt_len_cnt              <=    pkt_len_cnt + 1'b1;
							if(pkt_len_cnt==11)
							begin
							    state   <=   send_len;
							end
					  end
				end
				send_len:begin
					  if(i_tx_axis_fifo_tready)
					  begin
							pkt_len_cnt              <=    pkt_len_cnt + 1'b1;
							if(pkt_len_cnt == 12)               //need to add fifo counter here for last transaction.
							begin
							   o_tx_axis_fifo_tdata     <=    eth_pkt_len[15:8];
							end	
							else if(pkt_len_cnt == 13)  
							begin
							   o_tx_axis_fifo_tdata     <=    eth_pkt_len[7:0];
								state                    <=    send_data;
							end
					  end
				end
				send_data:begin
				    if(i_tx_axis_fifo_tready)
					 begin
					     pkt_len_cnt              <=    pkt_len_cnt + 1'b1;
				        if(pkt_len_cnt == (max_data_size+13))
					     begin
					         state        <=    idle;
								o_tx_axis_fifo_tlast <= 1'b1;
                                pkt_len_cnt <= 0;
					     end
						  o_tx_axis_fifo_tdata <= pkt_fifo_data;
					 end	
				end
		  endcase
	 end
end

always @(*)
begin
    if(pkt_len_cnt >= 14)
	     pkt_fifo_rd    <=   i_tx_axis_fifo_tready;
    else
	     pkt_fifo_rd    <=  1'b0;
end			


endmodule
