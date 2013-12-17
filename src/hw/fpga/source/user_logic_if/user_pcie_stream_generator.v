//--------------------------------------------------------------------------------
// Project    : SWITCH
// File       : user_pcie_stream_generator.v
// Version    : 0.1
// Author     : Vipin.K
//
// Description: PCIe user stream i/f controller
//
//--------------------------------------------------------------------------------


module user_pcie_stream_generator
#(
  parameter TAG = 8'd0
)
(
input              clk_i,
input              user_clk_i,
input              rst_n,
//Register Set I/f
input              sys_user_strm_en_i,
input              user_sys_strm_en_i,
output  reg        dma_done_o,
input              dma_done_ack_i,
input       [31:0] dma_src_addr_i,
input       [31:0] dma_len_i,
input       [31:0] stream_len_i,
output reg         user_sys_strm_done_o,
input              user_sys_strm_done_ack,
input      [31:0]  dma_wr_start_addr_i,
//To pcie arbitrator
output  reg        dma_rd_req_o,
input              dma_req_ack_i,
//Rx engine
input       [7:0]  dma_tag_i,
input              dma_data_valid_i,
input       [63:0] dma_data_i,
//User stream output
output             stream_data_valid_o,
input              stream_data_ready_i,
output      [63:0] stream_data_o,
//User stream input
input              stream_data_valid_i,
output             stream_data_ready_o,
input       [63:0] stream_data_i, 
//To Tx engine  
output  reg [11:0] dma_rd_req_len_o,
output      [7:0]  dma_tag_o,
output  reg [31:0] dma_rd_req_addr_o,
output  reg        user_stream_data_avail_o, 
input              user_stream_data_rd_i,
output      [63:0] user_stream_data_o,
output  reg [4:0]  user_stream_data_len_o,
output      [31:0] user_stream_wr_addr_o,
input              user_stream_wr_ack_i
);

localparam IDLE          = 'd0,
           WAIT_ACK      = 'd1,
           START         = 'd2,
           WAIT_DEASSRT  = 'd3;
          

reg [1:0]  state;
reg [1:0]  wr_state;
reg        last_flag;
reg [31:0] rd_len;
reg [31:0] wr_len;
reg [31:0] rcvd_data_cnt;
reg [31:0] expected_data_cnt;
wire[9:0]  rd_data_count;
reg        clr_rcv_data_cntr;
reg [31:0] dma_wr_addr;
reg [63:0] dma_data_p;


wire       fifo_full_i;
reg        fifo_wr_en;
wire       fifo_ready;

always @(posedge clk_i)
begin
  if(dma_data_valid_i & (dma_tag_i == TAG))
      fifo_wr_en             =  1'b1;
  else
    fifo_wr_en             =  1'b0;
    dma_data_p  <= dma_data_i;
end

assign dma_tag_o              = TAG;
assign user_stream_wr_addr_o  = dma_wr_addr;

//State machine for user logic to system data transfer
always @(posedge clk_i)
begin
    if(!rst_n)
    begin
          wr_state                   <=  IDLE;
          user_stream_data_avail_o   <=  1'b0;
          user_sys_strm_done_o       <=  1'b0;
    end
    else
    begin
        case(wr_state)
             IDLE:begin
                 user_sys_strm_done_o    <=    1'b0;
                 if(user_sys_strm_en_i)                       //If the controller is enabled
                 begin
                     dma_wr_addr    <=  dma_wr_start_addr_i;  //Latch the destination address and transfer size
                     wr_len         <=  stream_len_i[31:3];
                     if(stream_len_i > 0)                     //If forgot to set the transfer size, do not hang!!
                         wr_state  <=  START;
                     else
                         wr_state  <=  WAIT_DEASSRT;                     
                 end
             end
             START:begin
                if((rd_data_count >= 'd16) & (wr_len >= 16 )) //For efficient transfer, if more than 64 bytes to data is still remaining, wait.
                begin
                    user_stream_data_avail_o   <=  1'b1;    //Once data is available, request to the arbitrator.
                    user_stream_data_len_o     <=  5'd16;
                    wr_state                   <=  WAIT_ACK;
                    wr_len                     <=  wr_len - 5'd16;
                end
                else if(rd_data_count >= wr_len)
                begin
                    wr_state                   <=  WAIT_ACK;
                    wr_len                     <=  0;
                    user_stream_data_avail_o   <=  1'b1;                  //Once data is in the FIFO, request the arbitrator    
                    user_stream_data_len_o     <=  wr_len;     
                end
             end
             WAIT_ACK:begin
                if(user_stream_wr_ack_i)                                  //Once the arbitrator acks, remove the request and increment sys mem address
                begin
                    user_stream_data_avail_o   <=  1'b0;
                    dma_wr_addr          <=  dma_wr_addr + 8'd128;
                    if(wr_len == 0)
                        wr_state                   <=  WAIT_DEASSRT;      //If all data is transferred, wait until it is updated in the status reg.
                    else if((rd_data_count >= 'd16) & (wr_len >= 16 ))
                    begin
                       user_stream_data_avail_o   <=  1'b1;    //Once data is available, request to the arbitrator.
                       user_stream_data_len_o     <=  5'd16;
                       wr_state                   <=  WAIT_ACK;
                       wr_len                     <=  wr_len - 5'd16;
                    end
                    else
                        wr_state             <=  START;    
                end
             end
             WAIT_DEASSRT:begin
                 user_sys_strm_done_o    <=    1'b1;
                 if(~user_sys_strm_en_i & user_sys_strm_done_ack)
                     wr_state    <=    IDLE;
             end
         endcase
    end
end 


always @(posedge clk_i)
begin
    if(!rst_n)
    begin
        state                 <= IDLE;
        dma_rd_req_o          <= 1'b0;
        dma_done_o            <= 1'b0;
        last_flag             <= 1'b0; 
    end
    else
    begin
        case(state)
            IDLE:begin
                dma_done_o        <= 1'b0;
                last_flag         <= 1'b0; 
                clr_rcv_data_cntr <= 1'b1;
                dma_rd_req_addr_o   <= dma_src_addr_i;
                rd_len              <= dma_len_i;
                expected_data_cnt   <= 0;
                if(sys_user_strm_en_i)                      //If system to user dma is enabled
                begin
                    state               <= START;
                end
            end
            START:begin    
                clr_rcv_data_cntr <= 1'b0;
                if(fifo_ready)                              //If there is space in receive fifo make a request
                begin
                    state         <= WAIT_ACK;
                    dma_rd_req_o  <= 1'b1;
                    if(rd_len <= 'd4096)
                    begin
                        dma_rd_req_len_o          <= rd_len[11:0];
                        expected_data_cnt         <= expected_data_cnt + rd_len;  
                        last_flag                 <= 1'b1;                     
                    end
                    else
                    begin
                        dma_rd_req_len_o         <= 0;
                        expected_data_cnt        <= expected_data_cnt + 4096;
                    end
                end
            end
            WAIT_ACK:begin
                if(dma_req_ack_i)
                begin
                    dma_rd_req_o <= 1'b0;
                end
                if(rcvd_data_cnt >= expected_data_cnt[31:3])
                begin
                    rd_len            <= rd_len - 'd4096;
                    dma_rd_req_addr_o <= dma_rd_req_addr_o + 'd4096;
                    if(dma_done_ack_i & ~sys_user_strm_en_i)
                    begin
                        state             <= IDLE; 
                    end       
                    else if(last_flag)
                    begin 
                        dma_done_o <= 1'b1;
                        state      <=  WAIT_ACK;
                    end
                    else
                        state      <=  START;     
                end
            end
        endcase
    end
end


always @(posedge clk_i)
begin
    if(!rst_n)
        rcvd_data_cnt    <=  0;
    else
    begin
        if(clr_rcv_data_cntr)
            rcvd_data_cnt   <=    0;
        else if(fifo_wr_en)
            rcvd_data_cnt   <=    rcvd_data_cnt + 1; 
    end
end


//user_logic_stream_wr_fifo
user_fifo user_wr_fifo (
  .s_aclk(clk_i), 
  .s_aresetn(rst_n), 
  .s_axis_tvalid(fifo_wr_en), //
  .s_axis_tready(fifo_ready),
  .s_axis_tdata(dma_data_p),
  .m_aclk(user_clk_i),
  .m_axis_tvalid(stream_data_valid_o),
  .m_axis_tready(stream_data_ready_i), 
  .m_axis_tdata(stream_data_o)
);

  //user_logic_stream_rd_fifo
user_strm_fifo user_rd_fifo (
  .s_aclk(user_clk_i), // input s_aclk
  .s_aresetn(rst_n), // input s_aresetn
  .s_axis_tvalid(stream_data_valid_i), // input s_axis_tvalid
  .s_axis_tready(stream_data_ready_o), // output s_axis_tready
  .s_axis_tdata(stream_data_i), // input [63 : 0] s_axis_tdata
  .m_aclk(clk_i),
  .m_axis_tvalid(), // output m_axis_tvalid
  .m_axis_tready(user_stream_data_rd_i), // input m_axis_tready
  .m_axis_tdata(user_stream_data_o), // output [63 : 0] m_axis_tdata
  .axis_rd_data_count(rd_data_count)
);

endmodule
