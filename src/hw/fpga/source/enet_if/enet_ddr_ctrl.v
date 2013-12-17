//--------------------------------------------------------------------------------
// Project    : SWITCH
// File       : enet_ddr_ctrl.v
// Version    : 0.3
// Author     : Shreejith S, Vipin K
//
// Description: Ethernet DDR Interface Controller
//
//--------------------------------------------------------------------------------



module enet_ddr_ctrl( 
input                i_clk,                  // 200 MHz clock
input                i_rst,                  // Active low reset
//Reg file
input                i_enet_enable,          // Enable the ethernet core
input   [31:0]       i_enet_ddr_source_addr, // Where is data for ethernet
input   [31:0]       i_enet_ddr_dest_addr,   // Where to store ethernet data
input   [31:0]       i_enet_rcv_data_size,   // How much data should be received from enet
input   [31:0]       i_enet_snd_data_size,   // How much data should be sent through enet
output  [31:0]       o_enet_rx_cnt,
output  [31:0]       o_enet_tx_cnt,
output               o_enet_rx_done,
output               o_enet_tx_done,
//Ethernet controller
output  reg          o_enet_enable,
input                i_enet_data_avail,
output  reg          o_core_ready,
input       [63:0]   i_data,
output      [63:0]   o_data,
output  reg          o_core_data_avail,
input                i_enet_ready,
//To DDR controller
output  reg          o_ddr_wr_req,
output  reg          o_ddr_rd_req,
output      [255:0]  o_ddr_wr_data,
output      [31:0]   o_ddr_wr_be,
output      [31:0]   o_ddr_wr_addr,
output      [31:0]   o_ddr_rd_addr,
input       [255:0]  i_ddr_rd_data,
input                i_ddr_wr_ack,
input                i_ddr_rd_ack,
input                i_ddr_rd_data_valid,
input                i_tx_mac_count
);



localparam SEND_IDLE   = 3'd0,
           RD_DDR_DATA = 3'd1,
           RD_DAT1     = 3'd2,
           RD_DAT2     = 3'd3,
           WR_DAT      = 3'd4,
			  WAIT_DONE   = 3'd5;
			  
localparam RCV_IDLE    = 3'd0,
           CHK_LEN     = 3'd1,
           RD_ENET_DAT = 3'd2,
           WR_DAT1     = 3'd3,
           WR_DAT2     = 3'd4;
              

reg [31:0]  send_size;
reg [31:0]  rcv_size;
reg [511:0] ddr_rd_data;
reg [511:0] ddr_wr_data;
reg [2:0]   ddr_wr_pntr;
reg [2:0]   ddr_rd_pntr;
reg         last_flag;
reg [2:0]   send_sm;
reg [31:0]  ddr_rd_addr; 
reg [31:0]  ddr_wr_addr; 
reg         rd_state_idle;
reg [2:0]   rcv_sm;
reg         enet_rx_done;
reg         enet_tx_done;
reg [31:0]  enet_tx_cnt;
reg [31:0]  enet_rx_cnt;
reg [31:0]  tx_count_val;
reg [31:0]  enet_enable;
reg [31:0]  enet_enable_p;
reg         tx_mac_count,tx_mac_count_reg,tx_mac_count_reg_d1;
assign o_data        =  ddr_rd_data[(((8-ddr_rd_pntr)*64)-1)-:64];
assign o_ddr_wr_addr =  ddr_wr_addr;
assign o_ddr_rd_addr =  ddr_rd_addr;
assign o_ddr_wr_be   =  32'h00000000; 
assign o_ddr_wr_data =  (rcv_sm == WR_DAT1) ? ddr_wr_data[511:256] : ddr_wr_data[255:0];
assign o_enet_rx_cnt = enet_rx_cnt;
assign o_enet_tx_cnt = enet_tx_cnt;
assign o_enet_rx_done= enet_rx_done;
assign o_enet_tx_done= enet_tx_done;

always @(posedge i_clk)
begin
  enet_enable   <= i_enet_enable;
  enet_enable_p <= enet_enable;
end

always @(posedge i_clk)
begin
    if(i_rst)
    begin
        ddr_rd_pntr    <=  3'd0;
        last_flag      <=  1'b0;
        o_ddr_rd_req   <=  1'b0;
        send_sm        <=  SEND_IDLE;
        o_core_data_avail <= 1'b0;
    end
    else
    begin
        case(send_sm)
            SEND_IDLE:begin
                last_flag      <=  1'b0;
                ddr_rd_pntr    <=  3'd0;
                if(enet_enable_p)
                begin
                    send_size    <=    i_enet_snd_data_size;
                    ddr_rd_addr  <=    {i_enet_ddr_source_addr[31:6],3'h0};
                    if(i_enet_snd_data_size > 'd0)
                    begin
                        send_sm         <=   RD_DDR_DATA;
                    end        
                end
            end
            RD_DDR_DATA:begin
                o_ddr_rd_req   <=  1'b1;
                if(i_ddr_rd_ack)
                begin
                    o_ddr_rd_req  <=  1'b0;
                    ddr_rd_addr   <=  ddr_rd_addr + 4'd8;
                    send_sm         <=  RD_DAT1;
                    if(send_size <= 'd64)
                        last_flag <= 1'b1;
                    else
                        send_size  <=  send_size - 'd64;
                end
            end
            RD_DAT1:begin
                if(i_ddr_rd_data_valid)
                begin
                    ddr_rd_data[255:0]  <=  i_ddr_rd_data;
                    send_sm             <=  RD_DAT2;
                end
            end
            RD_DAT2:begin
                if(i_ddr_rd_data_valid)
                begin
                    ddr_rd_data[511:256]  <=  i_ddr_rd_data;
                    send_sm               <=  WR_DAT;
                end
            end
            WR_DAT:begin
               o_core_data_avail <= 1'b1;
               if(o_core_data_avail & i_enet_ready)
               begin
                   ddr_rd_pntr  <=  ddr_rd_pntr +1'b1;
                   if(ddr_rd_pntr == 3'd7)
                   begin
                       o_core_data_avail <= 1'b0;       
                       if(last_flag)         
                           send_sm    <= WAIT_DONE;
                       else
                       begin
                           send_sm         <=   RD_DDR_DATA;
                       end        
                   end
               end
            end
				WAIT_DONE : begin
					if (enet_tx_done)
						send_sm <= SEND_IDLE;
				end
        endcase
    end
end



always @(posedge i_clk)
begin
    if(i_rst)
    begin
        ddr_wr_pntr    <=  3'd0;
        rcv_sm         <=  RCV_IDLE;
        o_ddr_wr_req   <= 1'b0;
        o_core_ready   <= 1'b0;
        ddr_wr_data    <= 256'd0;
    end
    else
    begin
        o_ddr_wr_req   <= 1'b0;
        case(rcv_sm)
            RCV_IDLE:begin
                ddr_wr_pntr    <=  3'd0;
                if(enet_enable_p)
                begin
                    rcv_size     <=    i_enet_rcv_data_size;
                    ddr_wr_addr  <=    {i_enet_ddr_dest_addr[31:6],3'b000};
                    if(i_enet_rcv_data_size > 'd0)
                    begin
                        rcv_sm          <=   CHK_LEN;
                    end
                end
            end
            CHK_LEN:begin
                if(rcv_size >= 64)
                begin
                    rcv_sm  <=  RD_ENET_DAT;
                    rcv_size <= rcv_size - 64;
                end
                else
                    rcv_sm   <= RCV_IDLE;
            end
            RD_ENET_DAT:begin
                o_core_ready  <=  1'b1;
                if(o_core_ready & i_enet_data_avail)
                begin
                    ddr_wr_pntr  <=  ddr_wr_pntr +1'b1;
                    ddr_wr_data[(((8-ddr_wr_pntr)*64)-1)-:64]  <=  i_data;
                    if(ddr_wr_pntr == 3'd7)
                    begin
                        o_core_ready  <=  1'b0;      
                        rcv_sm        <=  WR_DAT1;    
                    end
                end
            end
            WR_DAT1:begin
                o_ddr_wr_req <=  1'b1;
                if(i_ddr_wr_ack)
                begin
                   rcv_sm   <=  WR_DAT2;
                   ddr_wr_addr <= ddr_wr_addr + 3'd4;
                end
            end                
            WR_DAT2:begin
                if(i_ddr_wr_ack)
                begin
                   o_ddr_wr_req <=  1'b0;
                   rcv_sm       <=  CHK_LEN;
                   ddr_wr_addr  <= ddr_wr_addr + 3'd4;
                end
            end 
        endcase
    end
end

// Performance Counters for Ethernet
always @ (posedge i_clk)
begin
    if(i_rst)
    begin
        enet_rx_done <= 1'b1;
        enet_tx_done <= 1'b1;
        enet_tx_cnt  <= 32'd0;
        enet_rx_cnt  <= 32'd0;
		  tx_count_val <= 32'd0;
    end
    else begin
        //enet_rx_done <= 1'b0;
        //enet_tx_done <= 1'b0;
        case(send_sm)
            SEND_IDLE:begin
                if(enet_enable_p && (i_enet_snd_data_size > 'd0)) begin
                    enet_tx_cnt <= 32'd0;
						  enet_tx_done <= 1'b0;
						  tx_count_val <= 32'd1024;
            	end
				end
				default : begin
					 if (tx_mac_count_reg && (~tx_mac_count_reg_d1)) begin
						  if (tx_count_val == i_enet_snd_data_size)
							   enet_tx_done <= 1'b1;
						  else 
							   tx_count_val <= tx_count_val + 32'd1024; // Increment by packet size
					 end
			
					 if (~enet_tx_done) begin
						  if (!(&enet_tx_cnt))
							   enet_tx_cnt <= enet_tx_cnt + 1'b1;
					 end
				end
		  endcase
		  
        case(rcv_sm)
            RCV_IDLE:begin
                if(enet_enable_p && (i_enet_rcv_data_size > 'd0)) begin
                    enet_rx_cnt <= 32'd0;
					enet_rx_done <= 1'b0;
				end
            end
            CHK_LEN:begin
                if(rcv_size < 64)
                    enet_rx_done <= 1'b1;
                else
                    if (!(&enet_rx_cnt))
                        enet_rx_cnt  <= enet_rx_cnt + 1'b1;
            end
            RD_ENET_DAT:begin
                if (!(&enet_rx_cnt))
                    enet_rx_cnt  <= enet_rx_cnt + 1'b1;
            end
            WR_DAT1:begin
                if (!(&enet_rx_cnt))                
                    enet_rx_cnt  <= enet_rx_cnt + 1'b1;
            end                
            WR_DAT2:begin
                if (!(&enet_rx_cnt))            
                    enet_rx_cnt  <= enet_rx_cnt + 1'b1;
            end 
        endcase
    end
end

// Generating IF enable

always @ (posedge i_clk) 
begin   
    if (i_rst)
        o_enet_enable <= 1'b0;
    else begin
        if (enet_enable_p)
            o_enet_enable <= 1'b1;
        if (~enet_enable_p && (enet_rx_done && enet_tx_done)) // If both RX & TX are done
            o_enet_enable <= 1'b0;
    end
end

always @ (posedge i_clk) begin
	tx_mac_count <= i_tx_mac_count;
	tx_mac_count_reg <= tx_mac_count;
    tx_mac_count_reg_d1 <= tx_mac_count_reg;
end
endmodule
