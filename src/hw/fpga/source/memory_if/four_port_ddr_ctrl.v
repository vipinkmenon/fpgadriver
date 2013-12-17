//--------------------------------------------------------------------------------
// Project    : SWITCH
// File       : four_port_ddr_ctrl.v
// Version    : 0.1
// Author     : Vipin.K
//
// Description: The four port DDR controller.
//              Port 0 : System to DDR DMA controller
//              Port 1 : User DDR PIO interface
//              Port 2 : User stream arbitrator
//              Port 3 : Ethernet 
//--------------------------------------------------------------------------------

module four_port_ddr_ctrl(
input                 i_clk,
input                 i_rst,
//to ddr controller
output     reg        app_wdf_wren,
output     reg [255:0]app_wdf_data,
output     reg [31:0] app_wdf_mask,
output     reg        app_wdf_end,
output     reg [31:0] app_addr,
output     reg [2:0]  app_cmd,
output     reg        app_en,
input                 app_rdy,
input                 app_wdf_rdy,
input      [255:0]    app_rd_data,
input                 app_rd_data_end,
input                 app_rd_data_valid,
//port0 
input      [255:0]    i_port0_wr_data,
input      [31:0]     i_port0_wr_data_be,
input                 i_port0_wr_data_valid,
input      [31:0]     i_port0_wr_addr,
output     reg        o_port0_wr_ack,
input                 i_port0_rd,
input      [31:0]     i_port0_rd_addr,
output     [255:0]    o_port0_rd_data,
output     reg        o_port0_rd_ack,
output     reg        o_port0_rd_data_valid,
//port1 
input      [255:0]    i_port1_wr_data,
input      [31:0]     i_port1_wr_data_be,
input                 i_port1_wr_data_valid,
input      [31:0]     i_port1_wr_addr,
input                 i_port1_rd,
output     [255:0]    o_port1_rd_data,
input      [31:0]     i_port1_rd_addr,
output     reg        o_port1_rd_data_valid,
output     reg        o_port1_wr_ack,
output     reg        o_port1_rd_ack,
//port2
input      [255:0]    i_port2_wr_data,
input      [31:0]     i_port2_wr_data_be,
input                 i_port2_wr_data_valid,
input      [31:0]     i_port2_wr_addr,
input                 i_port2_rd,
output     [255:0]    o_port2_rd_data,
input      [31:0]     i_port2_rd_addr,
output     reg        o_port2_rd_data_valid,
output     reg        o_port2_wr_ack,
output     reg        o_port2_rd_ack,
//port3
input      [255:0]    i_port3_wr_data,
input      [31:0]     i_port3_wr_data_be,
input                 i_port3_wr_data_valid,
input      [31:0]     i_port3_wr_addr,
input                 i_port3_rd,
output     [255:0]    o_port3_rd_data,
input      [31:0]     i_port3_rd_addr,
output     reg        o_port3_rd_data_valid,
output     reg        o_port3_wr_ack,
output     reg        o_port3_rd_ack
);

reg [1:0]   cur_srvd_port;
reg [255:0] wr_data;
reg [31:0]  wr_be;
reg [31:0]  wr_addr;
reg [31:0]  rd_addr;
reg         data_avail;
reg         rd_req;
reg         rd_ack;
wire        wr_ack;
wire [1:0]  expected_buff;
reg         track_buff_wr;
reg  [1:0]  track_data;
reg  [2:0]  state;
reg         go_idle_flag;
reg         app_wr_done;
reg         app_en_done;

wire        some_other_request;

assign o_port0_rd_data = app_rd_data;
assign o_port1_rd_data = app_rd_data;
assign o_port2_rd_data = app_rd_data;
assign o_port3_rd_data = app_rd_data;
assign some_other_request = i_port0_wr_data_valid|i_port1_wr_data_valid|i_port2_wr_data_valid|i_port3_wr_data_valid|i_port0_rd|i_port1_rd|i_port2_rd|i_port3_rd;
assign wr_ack = (((data_avail & app_wdf_rdy & app_rdy)|(data_avail & app_wr_done & app_rdy)|(data_avail & app_wdf_rdy & app_en_done)) & (state == WR_DATA1))|(data_avail & app_wdf_rdy & (state == WR_DATA2));
//assign wr_ack = (data_avail & app_wdf_rdy & app_rdy & (state == WR_DATA1))|(data_avail & app_wdf_rdy & (state == WR_DATA2));


localparam    IDLE     = 'd0,
              WR_DATA1 = 'd1,
              WR_DATA2 = 'd2,
              RD_CMD   = 'd3;


always @(*)
begin
    case(cur_srvd_port)
        2'b00:begin
            data_avail <=     i_port0_wr_data_valid;
            wr_data    <=     i_port0_wr_data;
            wr_be      <=     i_port0_wr_data_be;
            wr_addr    <=     i_port0_wr_addr;
            rd_addr    <=     i_port0_rd_addr;
            rd_req     <=     i_port0_rd;
        end
        2'b01:begin
            data_avail <=     i_port1_wr_data_valid;
            wr_data    <=     i_port1_wr_data;
            wr_be      <=     i_port1_wr_data_be;
            wr_addr    <=     i_port1_wr_addr;
            rd_addr    <=     i_port1_rd_addr;
            rd_req     <=     i_port1_rd;
        end
        2'b10:begin
            data_avail <=     i_port2_wr_data_valid;
            wr_data    <=     i_port2_wr_data;
            wr_be      <=     i_port2_wr_data_be;
            wr_addr    <=     i_port2_wr_addr;
            rd_addr    <=     i_port2_rd_addr;
            rd_req     <=     i_port2_rd;
        end
        2'b11:begin
            data_avail <=     i_port3_wr_data_valid;
            wr_data    <=     i_port3_wr_data;
            wr_be      <=     i_port3_wr_data_be;
            wr_addr    <=     i_port3_wr_addr;
            rd_addr    <=     i_port3_rd_addr;
            rd_req     <=     i_port3_rd;
        end
    endcase
end

always @(*)
begin
    o_port0_wr_ack  <=   1'b0;
    o_port1_wr_ack  <=   1'b0;
    o_port2_wr_ack  <=   1'b0;
    o_port3_wr_ack  <=   1'b0;
    o_port0_rd_ack  <=   1'b0;
    o_port1_rd_ack  <=   1'b0;
    o_port2_rd_ack  <=   1'b0;
    o_port3_rd_ack  <=   1'b0;
    case(cur_srvd_port)
        2'b00:begin
            o_port0_rd_ack    <=    rd_ack;
            o_port0_wr_ack    <=    wr_ack;
        end
        2'b01:begin
            o_port1_rd_ack    <=    rd_ack;
            o_port1_wr_ack    <=    wr_ack;
        end
        2'b10:begin
            o_port2_rd_ack    <=    rd_ack;
            o_port2_wr_ack    <=    wr_ack;
        end
        2'b11:begin
            o_port3_rd_ack    <=    rd_ack;
            o_port3_wr_ack    <=    wr_ack;
        end
    endcase
end


always @(posedge i_clk)
begin
    if(i_rst)
    begin
        state             <= IDLE;
        app_wdf_wren      <= 1'b0;
        track_buff_wr     <= 1'b0;
        cur_srvd_port     <= 2'b00;
        app_wdf_end       <= 1'b0;
        app_en            <= 1'b0;
        app_wr_done       <= 1'b0;
        app_en_done       <= 1'b0;
    end
    else
    begin
        case(state)
            IDLE:begin
                track_buff_wr  <=  1'b0;
                if(data_avail)
                begin
                    state        <= WR_DATA1;
                    app_wr_done  <= 1'b1;
                    app_en_done  <= 1'b1;
                end 
                else if(rd_req)
                begin
                    app_en        <= 1'b1;
                    app_addr      <= rd_addr;
                    app_cmd       <= 3'b001;
                    track_data    <= cur_srvd_port;
                    track_buff_wr <= 1'b1;
                    state         <= RD_CMD;
                    rd_ack        <= 1'b1;
                end 
                else if(some_other_request)
                    cur_srvd_port        <= cur_srvd_port + 1'b1;
            end
            WR_DATA1:begin
                if(app_wdf_rdy)
                begin 
                    app_wdf_wren <= 1'b0;
                    app_wr_done  <= 1'b1;
                end
                if(app_rdy)
                begin
                    app_en       <= 1'b0;
                    app_wdf_end  <= 1'b0;
                    app_en_done  <= 1'b1;
                end
                if((data_avail & app_wdf_rdy & app_rdy)|(data_avail & app_wr_done & app_rdy)|(data_avail & app_wdf_rdy & app_en_done))
                begin
                    app_wdf_wren <= 1'b1;
                    app_wdf_data <= wr_data;
                    app_wdf_mask <= wr_be;
						  app_addr     <= wr_addr;
                    state        <= WR_DATA2;
                    app_wr_done  <= 1'b0;
                    app_en_done  <= 1'b0;
                end
                else if(app_wr_done & app_en_done)
                begin
                    state        <= IDLE;
                end
            end
            WR_DATA2:begin
                if(data_avail & app_wdf_rdy)
                begin
                    app_wdf_wren <= 1'b1;
                    app_wdf_end  <= 1'b1;
                    app_wdf_data <= wr_data;
                    app_wdf_mask <= wr_be;
                    app_en       <= 1'b1;
                    app_cmd      <= 3'b000;
                    state        <= WR_DATA1;
                end
                else if(app_wdf_rdy)
                begin
                    app_wdf_wren <= 1'b0;
                end     
            end
            RD_CMD:begin
                track_buff_wr <= 1'b0;
                rd_ack        <= 1'b0;
                if(app_rdy)
                begin
                    app_en         <= 1'b0;
                    track_buff_wr  <= 1'b1;
                    track_data     <= cur_srvd_port;
                    state          <= IDLE;  
                end
            end
        endcase
    end
end


always @(*)
begin
    o_port0_rd_data_valid = 1'b0;
    o_port1_rd_data_valid = 1'b0;
    o_port2_rd_data_valid = 1'b0;
    o_port3_rd_data_valid = 1'b0;
    case(expected_buff)
        2'b00:begin
            o_port0_rd_data_valid    =    app_rd_data_valid;
        end
        2'b01:begin
            o_port1_rd_data_valid    =    app_rd_data_valid;
        end
        2'b10:begin
            o_port2_rd_data_valid    =    app_rd_data_valid;
        end
        2'b11:begin
            o_port3_rd_data_valid    =    app_rd_data_valid;
        end
    endcase           
end  


track_fifo track_fifo (
  .s_aclk(i_clk), // input s_aclk
  .s_aresetn(~i_rst), // input s_aresetn
  .s_axis_tvalid(track_buff_wr), // input s_axis_tvalid
  .s_axis_tready(), // output s_axis_tready fifo_rdy
  .s_axis_tdata({6'h00,track_data}), // input [7 : 0] s_axis_tdata
  .m_axis_tvalid(), // output m_axis_tvalid
  .m_axis_tready(app_rd_data_valid), // input m_axis_tready
  .m_axis_tdata(expected_buff) // output [7 : 0] m_axis_tdata
);


endmodule
