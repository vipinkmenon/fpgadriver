//--------------------------------------------------------------------------------
// Project    : SWITCH
// File       : ethernet_controller_top.v
// Version    : 0.2
// Author     : Shreejith S, Vipin K
//
// Description: Ethernet Controller Module Top File
//
//--------------------------------------------------------------------------------




module v7_ethernet_controller_top	#(parameter tx_dst_addr = 48'h001F293A10FD,tx_src_addr = 48'hAABBCCDDEEFF,tx_max_data_size = 16'd1024,rx_dst_addr=48'hAABBCCDDEEFF)
(
    // asynchronous reset
      input         glbl_rst,

      // 200MHz clock input from board
      input         clkin200,
      
      output        phy_resetn,
     
     //added SGMII serial data and reference clock ports
      input            gtrefclk_p,            // Differential +ve of reference clock for MGT: 125MHz, very high quality.
      input            gtrefclk_n,            // Differential -ve of reference clock for MGT: 125MHz, very high quality.
      output           txp,                   // Differential +ve of serial transmission from PMA to PMD.
      output           txn,                   // Differential -ve of serial transmission from PMA to PMD.
      input            rxp,                   // Differential +ve for serial reception from PMD to PMA.
      input            rxn,                   // Differential -ve for serial reception from PMD to PMA.
      
      output           synchronization_done,
      output           linkup,

      // MDIO Interface
      //---------------
      input         mdio_i,
	  output        mdio_o,
	  output        mdio_t,
      output        mdc,
 
      input         enet_loopback,
      input         enet_wr_clk,
      input         enet_wr_data_valid,   // axi_tvalid
      input [63:0]  enet_wr_data,         // axi_tdata
      output        enet_wr_rdy,          // axi_tready
    
      input         enet_rd_clk,
      input         enet_rd_rdy,          // axi_tready
      output [63:0] enet_rd_data,         // axi_tdata
      output reg    enet_rd_data_valid,   // axi_tvalid
    
      input         if_enable,
	  output        o_tx_mac_count
);

wire       w_core_ip_clk;
wire       w_core_ip_rst_n;
wire [7:0] w_core_ip_data;
wire       w_core_ip_data_valid;
wire       w_core_ip_data_last;
wire       w_ip_core_data_ready;
wire [7:0] w_ip_core_data;
reg        ip_core_data_valid;
wire       w_core_ip_data_ready;
wire       w_ip_core_data_last;
wire [13:0] eth_tx_fifo_data_cnt;
wire [10:0] eth_tx_fifo_wr_data_cnt;
wire [7:0]  eth_rx_fifo_rd_data_cnt;

reg [2:0] rd_state;
reg       enet_rd_en;
reg [3:0] dat_cnt;
reg       tx_fifo_rd;

tx_fifo eth_tx_fifo
(
  .rst(glbl_rst), // input rst
  .wr_clk(enet_wr_clk), // input wr_clk
  .rd_clk(w_core_ip_clk), // input rd_clk
  .din(enet_wr_data), // input [63 : 0] din
  .wr_en(enet_wr_data_valid & enet_wr_rdy & if_enable), // input wr_en
  
  .rd_en(tx_fifo_rd || w_core_ip_data_ready), // input rd_en
  .dout(w_ip_core_data), /// output [7 : 0] dout
  .full(tx_full), // output full
  .empty(tx_fifo_empty), // output empty
  .rd_data_count(eth_tx_fifo_data_cnt), // output [13 : 0] rd_data_count
  .wr_data_count(eth_tx_fifo_wr_data_cnt)

);

assign enet_wr_rdy = ((eth_tx_fifo_wr_data_cnt > 2045) || (tx_full)) ? 1'b0 : 1'b1;


reg tx_fif_rd_state;

always @(posedge w_core_ip_clk)
begin
	if (~w_core_ip_rst_n) begin
		tx_fifo_rd <= 1'b0;
		ip_core_data_valid <= 1'b0;
		tx_fif_rd_state <= 'd0;
	end
	else begin
		tx_fifo_rd <= 1'b0;
        ip_core_data_valid <= 1'b0;
		case (tx_fif_rd_state)
			1'b0 : begin
				if (|eth_tx_fifo_data_cnt) begin
//					if (w_core_ip_data_ready) begin
						//tx_fifo_rd <= 1'b1;
						tx_fif_rd_state <= 1'b1;
                        ip_core_data_valid <= 1'b1;
	//				end
				end
			end
			1'b1 : begin
                
				if (w_core_ip_data_ready && (eth_tx_fifo_data_cnt>14'd2)) begin
					//tx_fifo_rd <= 1'b1;
                    tx_fif_rd_state <= 1'b1;
                    ip_core_data_valid <= 1'b1;
                end
				else begin 
                    ip_core_data_valid <= 1'b1;
                    if (tx_fifo_empty) begin
                        tx_fifo_rd <= 1'b0;
                        tx_fif_rd_state <= 1'b0;
                    end
                end
			end
		endcase
	end
end

v7_ethernet_controller 
	#(.tx_dst_addr(tx_dst_addr),
	.tx_src_addr(tx_src_addr),
	.tx_max_data_size(tx_max_data_size),
	.rx_dst_addr(rx_dst_addr))
ec
   (
    .glbl_rst(glbl_rst),
    .clkin200(clkin200),
    
    .phy_resetn(phy_resetn),
    
    .gtrefclk_p(gtrefclk_p),
    .gtrefclk_n(gtrefclk_n),
    .txp(txp),
    .txn(txn),
    .rxp(rxp),
    .rxn(rxn),
    
    .synchronization_done(synchronization_done),
    .linkup(linkup),
    
    
    .mdio_i(mdio_i),
    .mdio_t(mdio_t),
    .mdio_o(mdio_o),
    .mdc(mdc),
	.o_axi_rx_clk(w_core_ip_clk),
    .o_axi_rx_rst_n(w_core_ip_rst_n),
    .o_axi_rx_tdata(w_core_ip_data),
    .o_axi_rx_data_tvalid(w_core_ip_data_valid),
    .o_axi_rx_data_tlast(w_core_ip_data_last),
    .loop_back_en(enet_loopback),
	.i_axi_rx_data_tready(1'b1),
	.o_axi_tx_clk(),
    .o_axi_tx_rst_n(),
    .i_axi_tx_tdata(w_ip_core_data),
    .i_axi_tx_data_tvalid(ip_core_data_valid),
    .o_axi_tx_data_tready(w_core_ip_data_ready),
    .i_axi_tx_data_tlast(1'b0),
	 .o_tx_mac_count(o_tx_mac_count)
);


wire rx_fifo_rd_en = (enet_rd_en || ((rd_state == 1'b1) && (enet_rd_en || enet_rd_rdy)));

rx_fifo eth_rx_fifo	
(
  .rst(glbl_rst), // input rst
  .wr_clk(w_core_ip_clk), // input wr_clk
  .rd_clk(enet_rd_clk), // input rd_clk
  .din(w_core_ip_data), // input [7 : 0] din
  .wr_en(w_core_ip_data_valid && if_enable), // input wr_en
  
  .rd_en(rx_fifo_rd_en), // input rd_en
  .dout(enet_rd_data), // output [63 : 0] dout
  .full(), // output full
  .empty(), // output empty
  .rd_data_count(eth_rx_fifo_rd_data_cnt) // output [7 : 0] rd_data_count

);

always @ (posedge enet_rd_clk) 
begin
    if (glbl_rst) begin
        enet_rd_data_valid <= 1'b0;
        rd_state <= 2'd0;
        enet_rd_en <= 1'b0;
        dat_cnt <= 'd0;
    end
    else begin
        enet_rd_en <= 1'b0;
        case (rd_state)
            2'd0 : begin
                if (eth_rx_fifo_rd_data_cnt >= 8) begin
                    enet_rd_en <= 1'b1;
                    rd_state   <= 2'd1;
                    if (enet_rd_rdy)
                        dat_cnt <= 4'd0;
                    else
                        dat_cnt    <= 4'd1;
                end
            end
            2'd1 : begin
                enet_rd_data_valid <= 1'b1;
                if (enet_rd_rdy) begin
                    enet_rd_en <= 1'b1;
                    dat_cnt    <= dat_cnt + 1'b1;
                end
                else
                    enet_rd_en <= 1'b0;
                    
                if (dat_cnt == 8) begin
                    enet_rd_data_valid <= 1'b0;
                    enet_rd_en <= 1'b0;
                    rd_state <= 2'd2;
                end
                    
            end
            2'd2 : begin
                rd_state <= 2'd0;
            end
        endcase
    end
end


endmodule
