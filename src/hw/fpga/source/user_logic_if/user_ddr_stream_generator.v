//--------------------------------------------------------------------------------
// Project    : SWITCH
// File       : user_ddr_stream_generator.v
// Version    : 0.1
// Author     : Vipin.K
//
// Description: User DDR stream generator module 
//--------------------------------------------------------------------------------

module user_ddr_stream_generator(
    input              i_ddr_clk,
    input              i_user_clk,
    input              i_rst_n,
    input              i_ddr_stream_rd_en,
    output reg         o_ddr_stream_rd_done,
    input              i_ddr_stream_rd_done_ack,
    input      [31:0]  i_ddr_stream_rd_start_addr,
    input      [31:0]  i_ddr_stream_rd_len,	 
    input              i_ddr_stream_wr_en,
    output reg         o_ddr_stream_wr_done,
    input              i_ddr_stream_wr_done_ack,
    input      [31:0]  i_ddr_stream_wr_start_addr,
    input      [31:0]  i_ddr_stream_wr_len,
    //To DDR
    output reg         o_ddr_rd_req,
    input              i_ddr_rd_ack,
    output wire[31:0]  o_ddr_rd_addr,
    input              i_ddr_rd_data_valid,
    input      [255:0] i_ddr_rd_data,
    output reg         o_ddr_wr_req,
    input              i_ddr_wr_ack,
    output     [31:0]  o_ddr_wr_addr,
    output     [255:0] o_ddr_wr_data,
    output     [31:0]  o_ddr_wr_be_n,
   //To user logic write port 
    output             o_ddr_stream_valid, 
    input              i_ddr_stream_tready,
    output     [63:0]  o_ddr_stream_data,
    //To user read port
    input              i_ddr_str_data_valid,    
    output             o_ddr_str_ack,
    input      [63:0]  i_ddr_str_data
);

localparam   IDLE       = 'd0,
             CHLEN      = 'd1,
             RDDR       = 'd2,
             PACK       = 'd3;

localparam   WAIT_DATA  = 'd1,
             WR_FIRST   = 'd2,
             WR_SECOND  = 'd3;
 
localparam   WAIT_RD_DATA  = 'd0,
             WR_DATA       = 'd1;

localparam   WAIT_WR_DATA  = 'd0,
             STORE_DATA    = 'd1;

reg   [2:0]    state;
reg   [2:0]    wr_state;
reg            tx_state;
reg            rx_state;
reg   [28:0]   rd_addr;
reg   [28:0]   wr_addr;
reg   [28:0]   data_len;
reg   [28:0]   wr_data_len;
reg   [1:0]    wr_cntr;
reg   [1:0]    rd_cntr;
reg   [63:0]   wr_fifo_data;
reg            wr_fifo_valid;
reg            ddr_stream_rd_en;
reg            ddr_stream_rd_en_p;
reg            ddr_stream_wr_en;
reg            ddr_stream_wr_en_p;
reg            fifo_rd;
reg            addr_valid;
reg            addr_valid_p;
reg            data_got;
reg            single_wr_flag;
reg            rd_done_ack;
reg            rd_done_ack_p;
reg            wr_done_ack;
reg            wr_done_ack_p;
reg   [8:0]    buffer_space;
wire           wr_fifo_ready;
wire  [9:0]    data_count;
wire  [9:0]    wr_data_count;
wire           data_avail;
wire           txr_buffer_full;
wire  [63:0]   ddr_wr_data;
wire           rd_fifo_full;
wire           ddr_rd_data_avail;
wire           wr_data_avail;
wire           transfer_buffer_ready;
reg            issue_rd;
reg            fifo_wr;
reg            clr_rcv_data_cntr;
reg            ddr_rd_fifo_ack;
reg            last_read_flag;
wire  [255:0]  ddr_rd_data;
reg   [255:0]  ddr_rd_tmp_data;
reg   [255:0]  ddr_wr_tmp_data;


assign o_ddr_wr_addr  = {wr_addr,3'h0};
assign o_ddr_rd_addr  = {rd_addr,3'h0};
assign o_ddr_wr_be_n  = 32'h00000000;
assign data_avail     = data_count > 2 ? 1'b1 : 1'b0;
assign wr_data_avail  = wr_data_count > 4 ? 1'b1 : 1'b0;
assign transfer_buffer_ready = !txr_buffer_full;

always @(posedge i_ddr_clk)
begin
    ddr_stream_rd_en    <=  i_ddr_stream_rd_en;
    ddr_stream_rd_en_p  <=  ddr_stream_rd_en;
    rd_done_ack         <=  i_ddr_stream_rd_done_ack;
    rd_done_ack_p       <=  rd_done_ack;
    ddr_stream_wr_en    <=  i_ddr_stream_wr_en;
    ddr_stream_wr_en_p  <=  ddr_stream_wr_en;
    wr_done_ack         <=  i_ddr_stream_wr_done_ack;
    wr_done_ack_p       <=  wr_done_ack;
end

//Read request to DDR memory. The logic issues back to back read requests until the intermediate buffer
//to store the received data over flows
//
always @(posedge i_ddr_clk)
begin
    if(!i_rst_n)
    begin
      state                  <= IDLE;
      o_ddr_rd_req           <= 1'b0;
      o_ddr_stream_rd_done   <= 1'b0;
    end
    else
    begin
        case(state)
            IDLE:begin
                o_ddr_stream_rd_done   <=  1'b0;
                last_read_flag         <=  1'b0;
                clr_rcv_data_cntr      <=  1'b0;
                if(ddr_stream_rd_en_p) //Wait until control reg bit is set
                begin
                    rd_addr      <= i_ddr_stream_rd_start_addr[31:6];  //Latch the register values
                    data_len     <= i_ddr_stream_rd_len[31:5];
                    state        <= CHLEN;
                    //wr_cntr      <= i_ddr_stream_rd_start_addr[5:3];          //Make 64 bytes aligned. If aligned, counter will become 0.
                end
            end  
            CHLEN:begin
                if(data_len <= 2)
                begin
                    last_read_flag <= 1'b1;
                end
                if(buffer_space >= 2 & ~rd_fifo_full)
                begin
                   state  <= RDDR;
                   issue_rd <= 1'b1;
                   o_ddr_rd_req  <= 1'b1;
              end
            end  
            RDDR:begin    
                issue_rd  <= 1'b0;
                if(i_ddr_rd_ack)
                begin
                    o_ddr_rd_req  <= 1'b0;
                    rd_addr    <= rd_addr + 1'd1;
                    if(last_read_flag)
                    begin
                        state       <= PACK;
                        last_read_flag <= 1'b0;
                    end
                    else if(buffer_space >= 2 & ~rd_fifo_full)
                    begin
                        issue_rd <= 1'b1;
                        o_ddr_rd_req  <= 1'b1;
                        state  <= RDDR;
                        if(data_len == 4)
                        begin
                            last_read_flag <= 1'b1;
                        end  
                    end
                    else
                        state     <= CHLEN;

                    if(data_len >= 2)
                        data_len <= data_len - 2'd2;
                    end
            end
            PACK:begin
                o_ddr_stream_rd_done   <=  1'b1; 
                if(~ddr_stream_rd_en_p & rd_done_ack_p)
                begin
                    state             <=    IDLE;
                    clr_rcv_data_cntr <=    1'b1;
                end
            end
        endcase
    end
end

//This logic tracks the amount of free space in the intermediate buffer based on outstanding read
//requests and read completion signals. Total memory is 512 deep. Each read request will occupy two
//locations (512 bits). So maximum 128 out standing read requests. In worst case 128 read requests 
//fill data in the buffer and the user logic consumes only one and stops. In this case there can be
//another 128 read requests since the buffer full is asserted when it is 256 locations full.
always @(posedge i_ddr_clk)
begin
    if(!i_rst_n)
    begin
        buffer_space    <=  'd256;  
    end
    else
    begin
        if(clr_rcv_data_cntr)
            buffer_space    <=  'd256;
        else if(issue_rd & ~i_ddr_rd_data_valid)
            buffer_space <= buffer_space - 2'd2;
        else if(issue_rd & i_ddr_rd_data_valid)
            buffer_space <= buffer_space - 1'd1;
        else if(i_ddr_rd_data_valid)
            buffer_space <= buffer_space + 1'd1;
    end
end

//This logic transfers the 256 bit data from the intermediate buffer to the 64 bit wide user stream buffer
always @(posedge i_ddr_clk)
begin
    if(!i_rst_n)
    begin
        rx_state    <=  WAIT_RD_DATA; 
        ddr_rd_fifo_ack <=  1'b0;
        wr_fifo_valid <=    1'b0;
        wr_cntr       <=    0;  
    end
    else
    begin
        case(rx_state)
            WAIT_RD_DATA:begin
                ddr_rd_fifo_ack <=  1'b0;
                wr_fifo_valid   <=  1'b0;
                if(ddr_rd_data_avail)  //Wait until some valid data in the intermediate buffer
                begin   
                    rx_state          <=    WR_DATA;  
                    ddr_rd_tmp_data   <=    ddr_rd_data; //Store the data in a temp buffer and ack the FIFO to move to next location
                    ddr_rd_fifo_ack    <=   1'b1;
               end
            end
            WR_DATA:begin
                ddr_rd_fifo_ack    <=   1'b0;
                if(wr_fifo_ready) //Check whether the user stream FIFO is ready to accept data
                begin
                    wr_fifo_data <= ddr_rd_tmp_data[(((4-wr_cntr)*64)-1)-:64];
                    wr_cntr      <= wr_cntr+1'b1; 
                    wr_fifo_valid <= 1'b1;
                    if(wr_cntr == 3)          //While last data is being written into the user stream FIFO, prefetch the next data from        
                    begin                     //the intermediate buffer
                        if(ddr_rd_data_avail)
                        begin
                            ddr_rd_fifo_ack <=  1'b1;
                            ddr_rd_tmp_data <=  ddr_rd_data;
                            rx_state      <=    WR_DATA;
                        end 
                        else
                        begin
                            rx_state      <=    WAIT_RD_DATA;  
                        end  
                    end  
                end   
            end
        endcase  
    end
end

//This logic transfers user logic write data (64 bits) to the intermediate buffer
always @(posedge i_ddr_clk)
begin
    if(!i_rst_n)
    begin
        tx_state      <=  WAIT_WR_DATA; 
        rd_cntr       <=  0;
        fifo_wr       <=  1'b0;
        fifo_rd       <=  1'b0;
    end
    else
    begin
        case(tx_state) 
            WAIT_WR_DATA:begin
                fifo_wr  <= 1'b0;
                if((wr_data_count >= 4) & transfer_buffer_ready)  //Wait until there is sufficient data to transfer (256 bits or 64*4)
                begin                                      //and space in the transfer in the buffer
                    fifo_rd    <= 1'b1;
                    tx_state   <= STORE_DATA;
                end
            end
            STORE_DATA:begin
                rd_cntr    <= rd_cntr+1'b1;
                ddr_wr_tmp_data[(((4-rd_cntr)*64)-1)-:64] <= ddr_wr_data;
                fifo_wr    <= 1'b0;
                if(rd_cntr==3)
                begin
                    fifo_wr  <= 1'b1;
                    if(wr_data_avail & transfer_buffer_ready)
                    begin
                        tx_state <= STORE_DATA;
                    end
                    else
                    begin
                        tx_state <= WAIT_WR_DATA;
                        fifo_rd  <= 1'b0;
                    end
                end
            end
        endcase
    end
end

always @(posedge i_ddr_clk)
begin
    if(!i_rst_n)
    begin
        wr_state    <=    IDLE;
        o_ddr_wr_req <= 1'b0;
    end
    else
    begin
        case(wr_state)
            IDLE:begin
              o_ddr_stream_wr_done   <=  1'b0;
              if(ddr_stream_wr_en_p) //Wait until control reg bit is set
              begin
                   wr_addr      <= i_ddr_stream_wr_start_addr[31:6];
                   wr_data_len  <= i_ddr_stream_wr_len[31:5];//3
                   wr_state     <= WAIT_DATA;
              end
            end
            WAIT_DATA:begin
                if(wr_data_len < 2)
                begin
                    o_ddr_stream_wr_done   <=  1'b1; 
                    if(~ddr_stream_wr_en_p & wr_done_ack_p)
                    begin
                        wr_state    <=    IDLE;
                    end
                end 
                else if(data_count >= 2)
                begin
                    wr_state <= WR_FIRST; 
                    o_ddr_wr_req <= 1'b1;
                end
            end
            WR_FIRST:begin
                if(i_ddr_wr_ack)
                begin
                    wr_state <= WR_SECOND;  
                end
            end
            WR_SECOND:begin
                if(i_ddr_wr_ack)
                begin 
                    if(wr_data_len >= 2)
                        wr_data_len <= wr_data_len - 2'd2;
                    else
                        wr_data_len <= 0;
                    wr_addr    <=    wr_addr + 1'd1;
                    if(data_avail & (wr_data_len >= 4))
                        wr_state  <= WR_FIRST;
                    else
                    begin  
                        wr_state  <= WAIT_DATA;
                        o_ddr_wr_req <= 1'b0;
                    end
                end
            end
        endcase
    end
end


//DDR to user stream buffer intermediate buffer. stores the 256 bits
//received data from DDR
ddr_user_memory ddr_user_mem (
  .s_aclk(i_ddr_clk), // input s_aclk
  .s_aresetn(i_rst_n), // input s_aresetn
  .s_axis_tvalid(i_ddr_rd_data_valid), // input s_axis_tvalid
  .s_axis_tready(), // output s_axis_tready
  .s_axis_tdata(i_ddr_rd_data), // input [255 : 0] s_axis_tdata
  .m_axis_tvalid(ddr_rd_data_avail), // output m_axis_tvalid
  .m_axis_tready(ddr_rd_fifo_ack), // input m_axis_tready
  .m_axis_tdata(ddr_rd_data), // output [255 : 0] m_axis_tdata
  .axis_data_count(),
  .axis_prog_full(rd_fifo_full) // output axis_prog_full
);

// User stream read FIFO
ddr_stream_fifo ddr_rd_fifo (
  .m_aclk(i_user_clk), // input m_aclk
  .s_aclk(i_ddr_clk), // input s_aclk
  .s_aresetn(i_rst_n), // input s_aresetn
  .s_axis_tvalid(wr_fifo_valid), // input s_axis_tvalid
  .s_axis_tready(wr_fifo_ready), // output s_axis_tready
  .s_axis_tdata(wr_fifo_data), // input [63 : 0] s_axis_tdata
  .m_axis_tvalid(o_ddr_stream_valid), // output m_axis_tvalid
  .m_axis_tready(i_ddr_stream_tready), // input m_axis_tready
  .m_axis_tdata(o_ddr_stream_data), // output [63 : 0] m_axis_tdata
  .axis_wr_data_count()
);

//User logic to DDR stream write buffer
ddr_stream_fifo ddr_wr_fifo (
  .m_aclk(i_ddr_clk),                     // input m_aclk
  .s_aclk(i_user_clk),                    // input s_aclk
  .s_aresetn(i_rst_n),                    // input s_aresetn
  .s_axis_tvalid(i_ddr_str_data_valid),   // input s_axis_tvalid
  .s_axis_tready(o_ddr_str_ack),          // output s_axis_tready
  .s_axis_tdata(i_ddr_str_data),          // input [63 : 0] s_axis_tdata
  .m_axis_tvalid(),                       // output m_axis_tvalid
  .m_axis_tready(fifo_rd),                // input m_axis_tready
  .m_axis_tdata(ddr_wr_data),             // output [63 : 0] m_axis_tdata
  .axis_rd_data_count(wr_data_count)      // output [9 : 0] axis_rd_data_count
);

//Intermediate buffer between user logic stream buffer and arbitrator

ddr_user_memory user_mem_ddr (
  .s_aclk(i_ddr_clk), // input s_aclk
  .s_aresetn(i_rst_n), // input s_aresetn
  .s_axis_tvalid(fifo_wr), // input s_axis_tvalid
  .s_axis_tready(), // output s_axis_tready
  .s_axis_tdata(ddr_wr_tmp_data), // input [255 : 0] s_axis_tdata
  .m_axis_tvalid(), // output m_axis_tvalid
  .m_axis_tready(i_ddr_wr_ack), // input m_axis_tready
  .m_axis_tdata(o_ddr_wr_data), // output [255 : 0] m_axis_tdata
  .axis_data_count(data_count), 
  .axis_prog_full(txr_buffer_full) // output axis_prog_full
);

endmodule   