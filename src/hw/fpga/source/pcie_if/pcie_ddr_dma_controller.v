//--------------------------------------------------------------------------------
// Project    : SWITCH
// File       : user_pcie_stream_generator.v
// Version    : 0.1
// Author     : Vipin.K
//
// Description: PCIe to DRAM DMA controller
//
//--------------------------------------------------------------------------------

module pcie_ddr_dma_controller(
    input              pcie_clk_i,
    input              ddr_clk_i,
    input              rst_n,
    //Register Set I/f
    input              ctrl_en_i,
    output  reg        dma_done_o,
    input              dma_done_ack_i,
    input       [31:0] dma_src_addr_i,
    input       [31:0] dma_len_i, 
    //Tx engine
    output  reg        dma_rd_req_o,
    input              dma_req_ack_i,
    output  reg [11:0] dma_rd_req_len_o,
    output  reg [31:0] dma_rd_req_addr_o,	 
    output  reg [7:0]  dma_rd_tag_o,
    //Rx engine
    input       [7:0]  dma_tag_i,
    input              dma_data_valid_i,
    input       [63:0] dma_data_i,
    //Mem Ctrl
    input              fifo_rd_i,
    output  reg        fifo_empty_o, 
    output  reg [255:0]ddr_data_o, 
    input       [255:0]ddr_data_i,
    input              ddr_rd_valid_i,
    input              ddr_fifo_rd_i,
    output  reg [63:0] pcie_data_o,
    output             ddr_fifo_empty_o,
    output      [10:0] ddr_fifo_data_cnt_o,
    output             ddr_fifo_full_o,
    input              i_clr_recv_buffer,
    input              i_switch_recv_buffer
);


parameter IDLE            = 'd0,
          REQ_BUF1        = 'd1,
          WAIT_BUF1_ACK   = 'd2,
          REQ_BUF2        = 'd3,
          WAIT_BUF2_ACK   = 'd4,
          REQ_BUF3        = 'd5,
          WAIT_BUF3_ACK   = 'd6,
          REQ_BUF4        = 'd7,
          WAIT_BUF4_ACK   = 'd8,
          INT_RESET       = 'd9,
          CLR_CNTR        = 'd10;

reg [3:0]    state;
reg          last_flag;
reg [31:0]   rd_len;
reg [28:0]   rcvd_data_cnt;
reg [31:0]   expected_data_cnt;
reg [9:0]    fifo_1_expt_cnt;
reg [9:0]    fifo_2_expt_cnt;
reg [9:0]    fifo_3_expt_cnt;
reg [9:0]    fifo_4_expt_cnt;
reg [9:0]    fifo_1_rcv_cnt;
reg [9:0]    fifo_2_rcv_cnt;
reg [9:0]    fifo_3_rcv_cnt;
reg [9:0]    fifo_4_rcv_cnt;
reg          clr_rcv_data_cntr;
reg          current_read_fifo;
wire         fifo1_rd_en;
wire         fifo2_rd_en;
wire [255:0] fifo1_rd_data;
wire [255:0] fifo2_rd_data;
wire [255:0] fifo3_rd_data;
wire [255:0] fifo4_rd_data;
wire         fifo1_empty;
wire         fifo2_empty;
wire         fifo3_empty;
wire         fifo4_empty;
reg          fifo1_empty_p;
reg          fifo1_empty_p1;
reg          fifo2_empty_p;
reg          fifo2_empty_p1;
reg          fifo3_empty_p;
reg          fifo3_empty_p1;
reg          fifo4_empty_p;
reg          fifo4_empty_p1;
reg          clr_fifo1_data_cntr;
reg          clr_fifo2_data_cntr;
reg          clr_fifo3_data_cntr;
reg          clr_fifo4_data_cntr;
reg  [63:0]  dma_data_p;
reg  [255:0] fifo1_rd_data_p;
reg  [255:0] fifo2_rd_data_p;
reg  [255:0] fifo3_rd_data_p;
reg  [255:0] fifo4_rd_data_p;


wire       fifo_full;
reg        fifo1_wr_en;
reg        fifo2_wr_en;
reg        fifo3_wr_en;
reg        fifo4_wr_en;
reg  [3:0] fifo_rd_en;
wire       all_fifos_empty;
wire[63:0] pcie_rd_fifo_data;

always @(posedge pcie_clk_i)
begin
    if(ddr_fifo_rd_i)
        pcie_data_o   <= pcie_rd_fifo_data;

    if(dma_data_valid_i & (dma_tag_i == 8'd0))
        fifo1_wr_en <= 1'b1;
    else  
        fifo1_wr_en <= 1'b0;
  
    if(dma_data_valid_i & (dma_tag_i == 8'd1)) 
       fifo2_wr_en <= 1'b1;
    else
       fifo2_wr_en <= 1'b0;
      
    dma_data_p  <= dma_data_i;
end
 
assign all_fifos_empty = fifo1_empty_p1 & fifo2_empty_p1;

always @(*)
begin
    fifo_rd_en                         <=    4'h0;
    fifo_rd_en[current_read_fifo]      <=    fifo_rd_i;
end

always @(*)
begin
    case(current_read_fifo)
        1'b0:begin
            ddr_data_o    <=    fifo1_rd_data_p;
            fifo_empty_o  <=    fifo1_empty;
      end
        1'b1:begin
            ddr_data_o    <=    fifo2_rd_data_p;
            fifo_empty_o  <=    fifo2_empty;
      end
    endcase
end

always @(posedge ddr_clk_i)
begin
    if(fifo_rd_en[0])
        fifo1_rd_data_p <= fifo1_rd_data;
    if(fifo_rd_en[1])  
        fifo2_rd_data_p <= fifo2_rd_data;
end

always @(posedge pcie_clk_i)
begin
    if(!rst_n)
    begin
        state               <= IDLE;
        dma_rd_req_o        <= 1'b0;
        dma_done_o          <= 1'b0;
        last_flag           <= 1'b0; 
        clr_fifo1_data_cntr <= 1'b1;
        clr_fifo2_data_cntr <= 1'b1;
        clr_fifo3_data_cntr <= 1'b1;
        clr_fifo4_data_cntr <= 1'b1;
    end
    else
    begin
        case(state)
            IDLE:begin
                dma_done_o        <= 1'b0;
                last_flag         <= 1'b0; 
                clr_rcv_data_cntr <= 1'b1;
                expected_data_cnt <= dma_len_i;
                dma_rd_req_addr_o <= dma_src_addr_i;
                rd_len            <= dma_len_i;
                fifo_1_expt_cnt   <= 10'd0;
                fifo_2_expt_cnt   <= 10'd0;
                fifo_3_expt_cnt   <= 10'd0;
                fifo_4_expt_cnt   <= 10'd0;
                clr_fifo1_data_cntr <= 1'b0;
                clr_fifo2_data_cntr <= 1'b0;
                clr_fifo3_data_cntr <= 1'b0;
                clr_fifo4_data_cntr <= 1'b0;
                if(ctrl_en_i)  //DDR DMA is enabled
                begin
                    state         <= REQ_BUF1;
                end
            end
            REQ_BUF1:begin   
                clr_rcv_data_cntr <= 1'b0;
                if((fifo_1_rcv_cnt >= fifo_1_expt_cnt) & fifo1_empty_p1)  //If all data for the FIFO has arrived and written into DDR
                begin
                    state           <= WAIT_BUF1_ACK;
                    dma_rd_req_o    <= 1'b1;
                    dma_rd_tag_o    <= 8'd0;
                    clr_fifo1_data_cntr <= 1'b1;//Clear received cntr for FIFO1 since new request starting
                    if(rd_len <= 'd4096)
                    begin
                        dma_rd_req_len_o          <= rd_len[11:0];
                        //fifo_1_expt_cnt           <= rd_len[11:0];  
                        last_flag                 <= 1'b1;                     
                    end
                    else
                    begin
                        dma_rd_req_len_o         <= 0;
                        fifo_1_expt_cnt          <= 10'd512;
                    end
                end
            end
            WAIT_BUF1_ACK:begin
                clr_fifo1_data_cntr <= 1'b0;
                if(dma_req_ack_i)
                begin
                    dma_rd_req_o <= 1'b0;
                    if(last_flag)    //If all data is read, wait until complete data is received
                    begin
                        state             <= INT_RESET;      
                    end
                    else
                    begin
                        state               <= REQ_BUF2;
                        rd_len              <= rd_len - 'd4096;
                        dma_rd_req_addr_o   <= dma_rd_req_addr_o + 'd4096;
                    end
                end  
            end
            REQ_BUF2:begin
                if((fifo_2_rcv_cnt >= fifo_2_expt_cnt) & fifo2_empty_p1)  //If all data for the FIFO has arrived and written into DDR
                begin
                    state           <= WAIT_BUF2_ACK;
                    dma_rd_req_o    <= 1'b1;
                    dma_rd_tag_o    <= 8'd1;
                    clr_fifo2_data_cntr <= 1'b1;                          //Clear received cntr for FIFO1 since new request starting
                    if(rd_len <= 'd4096)
                    begin
                        dma_rd_req_len_o          <= rd_len[11:0];
                        //fifo_2_expt_cnt           <= rd_len[11:0];  
                        last_flag                 <= 1'b1;                     
                    end
                    else
                    begin
                        dma_rd_req_len_o         <= 0;
                        fifo_2_expt_cnt          <= 10'd512;
                    end
                end
            end
            WAIT_BUF2_ACK:begin
                clr_fifo2_data_cntr <= 1'b0;
                if(dma_req_ack_i)
                begin
                    dma_rd_req_o <= 1'b0;
                    if(last_flag)    //If all data is read, wait until complete data is received
                    begin
                        state             <= INT_RESET;     
                    end
                    else
                    begin
                        state               <= REQ_BUF1;//REQ_BUF3;
                        rd_len              <= rd_len - 'd4096;
                        dma_rd_req_addr_o   <= dma_rd_req_addr_o + 'd4096;
                    end
               end
            end 
            INT_RESET:begin
                if(rcvd_data_cnt >= expected_data_cnt[31:3])    //When both FIFOs are empty, go to idle
                begin
                   dma_done_o        <= 1'b1;
                end
                if(~ctrl_en_i & dma_done_ack_i)
                begin
                    state               <= CLR_CNTR;
                    dma_done_o          <= 1'b0;
                end 
            end
            CLR_CNTR:begin
                if(all_fifos_empty)
                begin
                    clr_rcv_data_cntr   <= 1'b1;
                    clr_fifo1_data_cntr <= 1'b1;
                    clr_fifo2_data_cntr <= 1'b1;
                    clr_fifo3_data_cntr <= 1'b1;
                    clr_fifo4_data_cntr <= 1'b1;
                    state               <= IDLE;
                end
            end
        endcase
    end
end



always @(posedge pcie_clk_i)
begin
    if(!rst_n)
        rcvd_data_cnt    <=  0;
    else
    begin
        if(clr_rcv_data_cntr)
            rcvd_data_cnt   <=    0;
        else if(fifo1_wr_en|fifo2_wr_en)
            rcvd_data_cnt   <=    rcvd_data_cnt + 1'd1; 
    end
end

always @(posedge pcie_clk_i)
begin
    if(!rst_n)
        fifo_1_rcv_cnt    <=  0;
    else
    begin
        if(clr_fifo1_data_cntr)
            fifo_1_rcv_cnt   <=    0;
        else if(fifo1_wr_en)
            fifo_1_rcv_cnt   <=    fifo_1_rcv_cnt + 1'd1; 
    end
end

always @(posedge pcie_clk_i)
begin
    if(!rst_n)
        fifo_2_rcv_cnt    <=  0;
    else
    begin
        if(clr_fifo2_data_cntr)
            fifo_2_rcv_cnt   <=    0;
        else if(fifo2_wr_en)
            fifo_2_rcv_cnt   <=    fifo_2_rcv_cnt + 1'd1; 
    end
end


always @(posedge ddr_clk_i)
begin
   if(i_clr_recv_buffer)
        current_read_fifo    <=    1'b0;
   else if(i_switch_recv_buffer)
        current_read_fifo    <=    current_read_fifo + 1'b1;;
end

always @(posedge pcie_clk_i)
begin
   fifo1_empty_p   <=  fifo1_empty;
   fifo1_empty_p1  <=  fifo1_empty_p;
   fifo2_empty_p   <=  fifo2_empty;
   fifo2_empty_p1  <=  fifo2_empty_p;
end

  //DMA receive fifo
data_fifo wr_df_1(
  .rst(~rst_n),
  .wr_clk(pcie_clk_i),
  .rd_clk(ddr_clk_i), 
  .din(dma_data_p),
  .wr_en(fifo1_wr_en),
  .rd_en(fifo_rd_en[0]), 
  .dout(fifo1_rd_data),//ddr_data_o
  .full(),//fifo1_full
  .empty(fifo1_empty)
);

  //DMA receive fifo
data_fifo wr_df_2(
  .rst(~rst_n),
  .wr_clk(pcie_clk_i),
  .rd_clk(ddr_clk_i), 
  .din(dma_data_p),
  .wr_en(fifo2_wr_en),
  .rd_en(fifo_rd_en[1]), 
  .dout(fifo2_rd_data), //ddr_data_o
  .full(), //fifo_full
  .empty(fifo2_empty) //
);

//DMA transmit fifo
ddr_rd_fifo rd_df (
  .rst(~rst_n),
  .wr_clk(ddr_clk_i),
  .rd_clk(pcie_clk_i),
  .din(ddr_data_i),
  .wr_en(ddr_rd_valid_i),
  .rd_en(ddr_fifo_rd_i),
  .dout(pcie_rd_fifo_data),
  .full(),
  .empty(ddr_fifo_empty_o),
  .rd_data_count(ddr_fifo_data_cnt_o),
  .prog_full(ddr_fifo_full_o)
);

endmodule
