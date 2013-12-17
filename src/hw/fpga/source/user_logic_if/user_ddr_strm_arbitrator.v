//--------------------------------------------------------------------------------
// Project    : SWITCH
// File       : user_ddr_strm_arbitrator.v
// Version    : 0.1
// Author     : Vipin.K
//
// Description: Arbitrator for user DDR stream generator
//--------------------------------------------------------------------------------


`define MAX_SLAVE 16
module  user_ddr_strm_arbitrator #(
    parameter NUM_SLAVES = 'd4,
    parameter ADDR_WIDTH = 'd32,
    parameter DATA_WIDTH = 'd256,
	 parameter BE_WIDTH   = 'd32
    )
    (
    input                                     i_clk,
    input                                     i_rst_n,
	 //Read request ports
    input      [NUM_SLAVES-1:0]               i_ddr_rd_req,
    output reg [NUM_SLAVES-1:0]               o_ddr_rd_ack,
    input      [ADDR_WIDTH*NUM_SLAVES-1 : 0]  i_ddr_rd_addr,
    output reg [DATA_WIDTH-1:0]               o_ddr_rd_data,
    output reg [NUM_SLAVES-1:0]               o_ddr_rd_data_valid,
    //Write request ports
    input      [NUM_SLAVES-1:0]               i_ddr_wr_req,
    output reg [NUM_SLAVES-1:0]               o_ddr_wr_ack,
    input      [ADDR_WIDTH*NUM_SLAVES-1 : 0]  i_ddr_wr_addr,
    input      [DATA_WIDTH*NUM_SLAVES-1:0]    i_ddr_wr_data,
    input      [BE_WIDTH*NUM_SLAVES-1:0]      i_ddr_wr_be_n,                         
    //To ddr
    input      [DATA_WIDTH-1:0]               i_ddr_data,
    output     [DATA_WIDTH-1:0]               o_ddr_data,
    output     [BE_WIDTH-1:0]                 o_ddr_be_n,
    output reg                                o_ddr_rd_req,
    output     [ADDR_WIDTH-1:0]               o_ddr_wr_addr,
    output     [ADDR_WIDTH-1:0]               o_ddr_rd_addr,
    input                                     i_ddr_rd_ack,
    input                                     i_ddr_rd_data_valid,
    output                                    o_ddr_wr_req,
    input                                     i_ddr_wr_ack	 
    );
   
reg  [$clog2(NUM_SLAVES)-1:0] current_wr_slave_served;
reg  [$clog2(NUM_SLAVES)-1:0] current_rd_slave_served;

wire [$clog2(NUM_SLAVES)-1:0] fifo_wr_data;
wire [$clog2(NUM_SLAVES)-1:0] expected_buff;
wire some_other_wr_req;
wire some_other_rd_req;
wire wr_strm_fifo_rdy;
reg  fifo_wr;
wire fifo_rdy;
reg  ddr_wr_ack;

assign o_ddr_rd_addr = i_ddr_rd_addr[current_rd_slave_served*ADDR_WIDTH+:ADDR_WIDTH];
assign some_other_wr_req = |i_ddr_wr_req[NUM_SLAVES-1:0];
assign some_other_rd_req = |i_ddr_rd_req[NUM_SLAVES-1:0];

always @(*)
begin
    ddr_wr_ack      =  wr_strm_fifo_rdy & i_ddr_wr_req[current_wr_slave_served];
    o_ddr_rd_ack    =  {NUM_SLAVES{1'b0}};
    o_ddr_rd_ack[current_rd_slave_served] = i_ddr_rd_ack;
    o_ddr_rd_req    =  i_ddr_rd_req[current_rd_slave_served];  
    o_ddr_wr_ack    =  {NUM_SLAVES{1'b0}};
    o_ddr_wr_ack[current_wr_slave_served] = ddr_wr_ack;
end

always @(*)
begin
    o_ddr_rd_data                        <= i_ddr_data;
    o_ddr_rd_data_valid                  <= {NUM_SLAVES{1'b0}};
    o_ddr_rd_data_valid[expected_buff]   <= i_ddr_rd_data_valid;
end

localparam  IDLE       =  'd0,
            DDR_RD_REQ =  'd1;

reg        rd_state;
reg [1:0]  wr_state;

assign  fifo_wr_data   =    current_rd_slave_served;

always @(posedge i_clk)
begin
    if(!i_rst_n)
    begin
        current_wr_slave_served <= 0;
    end
    else
    begin
        if(i_ddr_wr_req[current_wr_slave_served])
        begin
            current_wr_slave_served  <=   current_wr_slave_served;
		  end	  
        else if(some_other_wr_req)
        begin
            current_wr_slave_served  <=   current_wr_slave_served + 1'b1;
        end
    end
end	 

always @(posedge i_clk)
begin
    if(!i_rst_n)
    begin
        rd_state                <= IDLE;
        current_rd_slave_served <= 0;
        fifo_wr                 <= 1'b0;
    end
    else
    begin
        case(rd_state)
            IDLE:begin
                fifo_wr  <=    1'b0;
                if(i_ddr_rd_req[current_rd_slave_served])
                begin
                   rd_state          <=    DDR_RD_REQ;
                   fifo_wr           <=    1'b1; 
                end
                else if(some_other_rd_req)
                begin
                    current_rd_slave_served  <=   current_rd_slave_served + 1'b1;
                end
            end
            DDR_RD_REQ:begin
                fifo_wr           <=    1'b0;
                if(i_ddr_rd_ack)
                begin
                   fifo_wr           <=    1'b1;
                   rd_state          <=    IDLE; 
                end
            end
        endcase
    end
end


ddr_wr_stream_fifo ddr_wr_stream_fifo (
  .s_aclk(i_clk), // input s_aclk
  .s_aresetn(i_rst_n), // input s_aresetn
  .s_axis_tvalid(i_ddr_wr_req[current_wr_slave_served]), // input s_axis_tvalid
  .s_axis_tready(wr_strm_fifo_rdy), // output s_axis_tready
  .s_axis_tdata({i_ddr_wr_be_n[current_wr_slave_served*BE_WIDTH+:BE_WIDTH],i_ddr_wr_addr[current_wr_slave_served*ADDR_WIDTH+:ADDR_WIDTH],i_ddr_wr_data[current_wr_slave_served*DATA_WIDTH+:DATA_WIDTH]}), // input [511 : 0] s_axis_tdata
  .m_axis_tvalid(o_ddr_wr_req), // output m_axis_tvalid
  .m_axis_tready(i_ddr_wr_ack), // input m_axis_tready
  .m_axis_tdata({o_ddr_be_n,o_ddr_wr_addr,o_ddr_data}) // output [511 : 0] m_axis_tdata
);

track_fifo track_fifo (
  .s_aclk(i_clk), // input s_aclk
  .s_aresetn(i_rst_n), // input s_aresetn
  .s_axis_tvalid(fifo_wr), // input s_axis_tvalid
  .s_axis_tready(), // output s_axis_tready fifo_rdy
  .s_axis_tdata(fifo_wr_data), // input [7 : 0] s_axis_tdata
  .m_axis_tvalid(), // output m_axis_tvalid
  .m_axis_tready(i_ddr_rd_data_valid), // input m_axis_tready
  .m_axis_tdata(expected_buff) // output [7 : 0] m_axis_tdata
);

endmodule
