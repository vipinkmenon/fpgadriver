//--------------------------------------------------------------------------------
// Project    : SWITCH
// File       : eth_rcr_unpack.v
// Version    : 0.2
// Author     : Shreejith S
//
// Description: Ethernet Rx Module Unpacker
//
//--------------------------------------------------------------------------------


module eth_rcr_unpack #(parameter unpack_dst_addr = 48'hAABBCCDDEEFF)(
//from ethernet client fifo
input    	      i_axi_rx_clk,
input    	      i_axi_rx_rst_n,
input    	      i_rx_axis_fifo_tvalid,
input  [7:0]      i_rx_axis_fifo_tdata,
input             i_rx_axis_fifo_tlast,
output            o_rx_axis_fifo_tready,
//to the user
output            o_axi_rx_clk,
output            o_axi_rx_rst_n,
output reg [7:0]  o_axi_rx_tdata,
output reg        o_axi_rx_data_tvalid,
input             i_axi_rx_data_tready,
output reg        o_axi_rx_data_tlast,
input             loop_back
);

assign o_axi_rx_clk   =   i_axi_rx_clk;
assign o_axi_rx_rst_n =   i_axi_rx_rst_n;
assign o_rx_axis_fifo_tready = i_axi_rx_data_tready;

reg [3:0] pkt_len_cntr;
reg [7:0] dest_addr [5:0];
reg [47:0] destination_addr;
reg state;
reg no_filter;

parameter idle       = 1'b0,
          stream_pkt = 1'b1;
 
always @(posedge i_axi_rx_clk)
begin
    if(~i_axi_rx_rst_n)
	begin
	    o_axi_rx_data_tvalid   <=    1'b0;
		state                  <=    idle;
		pkt_len_cntr           <=    4'd0;
        o_axi_rx_tdata         <=    8'd0;
        no_filter              <=    1'b0;
        dest_addr[0]           <=    8'd0;
        dest_addr[1]           <=    8'd0;
        dest_addr[2]           <=    8'd0;
        dest_addr[3]           <=    8'd0;
        dest_addr[4]           <=    8'd0;
        dest_addr[5]           <=    8'd0;
        
	end
	else
	begin
	    case(state)
	        idle:begin
			     o_axi_rx_data_tvalid <= 1'b0;
				  o_axi_rx_data_tlast  <= 1'b0;
	           if(i_rx_axis_fifo_tvalid & i_axi_rx_data_tready) //valid data transaction
		        begin
		            pkt_len_cntr <= pkt_len_cntr+1'b1;  //count the size of the pkt.
		            if(pkt_len_cntr == 'd13)            //ethernet header is 14 bytes
		            begin
                        if (((~loop_back) && (destination_addr == unpack_dst_addr)) || loop_back)
				            no_filter   <= 1'b1;
                        else
                            no_filter   <= 1'b0;
				        pkt_len_cntr <= 0;	
                        state <= stream_pkt;
				    end	
                    if(pkt_len_cntr < 'd6)
                        dest_addr[pkt_len_cntr] <= i_rx_axis_fifo_tdata; //store the destination address for filtering  
		        end
            end
			stream_pkt:begin
			   o_axi_rx_data_tvalid    <=    i_rx_axis_fifo_tvalid & no_filter;
				o_axi_rx_tdata          <=    i_rx_axis_fifo_tdata;
				o_axi_rx_data_tlast     <=    i_rx_axis_fifo_tlast & no_filter;
				if(i_rx_axis_fifo_tlast)
				begin
					state                  <=  idle;
				end	
			end
	    endcase
	end
end

always @(posedge i_axi_rx_clk)
begin
    destination_addr <= {dest_addr[0],dest_addr[1],dest_addr[2],dest_addr[3],dest_addr[4],dest_addr[5]};
end	 

endmodule
