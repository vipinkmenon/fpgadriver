//--------------------------------------------------------------------------------
// Project    : SWITCH
// File       : mem_ctrl.v
// Version    : 0.1
// Author     : Vipin.K
//
// Description: The DDR DMA and PIO controller
//
//--------------------------------------------------------------------------------

module mem_ctrl(
   input                 ddr_clk_i,            //200Mhz DDR clock
   input                 rst_i,                //Active high reset
   //Register file
   input      [31:0]     pio_fpga_addr_i,      //DDR PIO address
   input                 pio_rd_req_i,         //PIO read request
   output reg            pio_rd_ack_o,         //PIO read ack
   input                 pio_wr_req_i,         //PIO write request
   output reg            pio_wr_ack_o,         //PIO write ack
   input      [31:0]     pio_data_i,           //PIO write data
   output reg [31:0]     pio_data_o,           //PIO read data
   input                 fpga_system_dma_req_i,//FPGA to system DMA request
   output reg            fpga_system_dma_ack_o,//FPGA to system DMA ack
   input      [31:0]     sys_fpga_dma_addr_i,  //PC to FPGA DMA FPGA address
   input      [31:0]     fpga_sys_dma_addr_i,  //FPGA to PC DMA FPGA address
   input      [31:0]     dma_len_i,            //DMA length
   input      [31:0]     sys_ddr_dma_len_i,    //DMA length
   //DMA Receive fifo (Wr_df fifo)
   input                 dma_data_avail_i,     //DMA data avail for sys mem read request
   input      [255:0]    dma_fifo_data_i,      //DMA data
   output reg            rd_dma_fifo_o,        //Read DMA receive fifo
	output reg            o_clr_recv_buffer,
	output reg            o_switch_recv_buffer,
   //DMA Transmit fifo (Rd_df fifo)
   input                 rd_fifo_empty_i,      //DMA transmit fifo empty
   input                 rd_fifo_full_i,       //DMA transmit fifo full
   //DDR
   output     [255:0]    ddr_data_o,           //DDR write data
   output reg [31:0]     ddr_wr_be_n_o,        //DDR byte enable
   input      [255:0]    ddr_data_i,           //DDR read data
   input                 ddr_data_valid_i,     //DDR read data valid
   output reg            ddr_wr_req_o,         //DDR write request
   input                 ddr_wr_ack_i,         //DDR write ack
   output reg            ddr_rd_req_o,         //DDR read request
   input                 ddr_rd_ack_i,         //DDR read ack
   output reg [31:0]     ddr_addr_o            //DDR read/write address
);

    // State Machine state declaration
   localparam IDLE       = 'd0,
              START      = 'd1,
              DDR_WR     = 'd2, 
              DDR_PW1    = 'd3,
              DDR_PW2    = 'd4,		  
              DDR_RD     = 'd5,
              RD_DAT1    = 'd6,
              RD_DAT2    = 'd7,
              CHLEN      = 'd8,
              RDDR       = 'd9,
              PACK       = 'd10;

    //Local register declarations
    
    reg [3:0]   state;
    reg         pio_rd_req_p;
    reg         pio_rd_req_p1;
    reg         pio_wr_req_p;
    reg         pio_wr_req_p1;
    reg [63:0]  ddr_be;
    reg [26:0]  rd_wr_len;
    reg [26:0]  data_len;
    reg [26:0]  rcv_data_cntr;
    reg [6:0]   buffer_space;
    reg         issue_rd;
    reg         last_read_flag;
    reg         system_dma_req;
    reg         system_dma_req_p;
    reg         rd_fifo_empty;
    reg         rd_fifo_empty_p;
    reg         clr_rcv_data_cntr;
    reg         reset_sync;
    reg         reset;
    reg  [6:0]  rd_data_cnt;
    
    
    assign ddr_data_o = (state == DDR_WR) ? dma_fifo_data_i : {pio_data_i,pio_data_i,pio_data_i,pio_data_i,pio_data_i,pio_data_i,pio_data_i,pio_data_i};

    //Clock synchronisers for PCIe clock (250Mhz) to DDR clock (200Mhz)
    always @(posedge ddr_clk_i)
    begin
        pio_rd_req_p    <=   pio_rd_req_i;
        pio_rd_req_p1   <=   pio_rd_req_p;
        pio_wr_req_p    <=   pio_wr_req_i;
        pio_wr_req_p1   <=   pio_wr_req_p;
        system_dma_req  <=   fpga_system_dma_req_i;
        system_dma_req_p<=   system_dma_req;
        rd_fifo_empty   <=   rd_fifo_empty_i;
        rd_fifo_empty_p <=   rd_fifo_empty;
        reset_sync      <=   rst_i;
        reset           <=   reset_sync;
    end


    //Generate the DDR write byte enable based on input address
    always @(*)
    begin
        case(pio_fpga_addr_i[5:2])
            'd0:begin
                ddr_be  <=  'h0FFFFFFFFFFFFFFF;
            end
            'd1:begin
                ddr_be  <=  'hF0FFFFFFFFFFFFFF;
            end
            'd2:begin
                ddr_be  <=  'hFF0FFFFFFFFFFFFF;
            end
            'd3:begin
                ddr_be  <=  'hFFF0FFFFFFFFFFFF;
            end
            'd4:begin
                ddr_be  <=  'hFFFF0FFFFFFFFFFF;
            end
            'd5:begin
                ddr_be  <=  'hFFFFF0FFFFFFFFFF;
            end
            'd6:begin
                ddr_be  <=  'hFFFFFF0FFFFFFFFF;
            end
            'd7:begin
                ddr_be  <=  'hFFFFFFF0FFFFFFFF;
            end
            'd8:begin
                ddr_be  <=  'hFFFFFFFF0FFFFFFF;
            end
            'd9:begin
                ddr_be  <=  'hFFFFFFFFF0FFFFFF;
            end
            'd10:begin
                ddr_be  <=  'hFFFFFFFFFF0FFFFF;
            end
            'd11:begin
                ddr_be  <=  'hFFFFFFFFFFF0FFFF;
            end
            'd12:begin
                ddr_be  <=  'hFFFFFFFFFFFF0FFF;
            end
            'd13:begin
                ddr_be  <=  'hFFFFFFFFFFFFF0FF;
            end
            'd14:begin
                ddr_be  <=  'hFFFFFFFFFFFFFF0F;
            end
            'd15:begin
                ddr_be  <=  'hFFFFFFFFFFFFFFF0;
            end
        endcase
    end

    //Memory controller state machine
    always @(posedge ddr_clk_i)
    begin
        if(reset)
        begin
            ddr_wr_req_o          <= 1'b0;
            ddr_rd_req_o          <= 1'b0;
            pio_rd_ack_o          <= 1'b0;
            pio_wr_ack_o          <= 1'b0;
            state                 <= IDLE;
            fpga_system_dma_ack_o <= 1'b0;
            clr_rcv_data_cntr     <= 1'b0;
            rd_wr_len             <=  0;
            last_read_flag        <= 1'b0;
            o_clr_recv_buffer     <= 1'b1;
            o_switch_recv_buffer  <= 1'b0;
        end
        else
        begin
            case(state)
                IDLE:begin
                    clr_rcv_data_cntr  <= 1'b0;
                    o_clr_recv_buffer  <= 1'b0;
                    if(dma_data_avail_i)       
                    begin
                        ddr_addr_o    <= {3'h0,sys_fpga_dma_addr_i[31:6],3'h0};
                        rd_wr_len     <= sys_ddr_dma_len_i[31:5];
                        state         <= START;
                        rd_data_cnt   <= 0;
                    end
                    else if(system_dma_req_p)
                    begin
                        ddr_addr_o   <= {3'h0,fpga_sys_dma_addr_i[31:6],3'h0};
                        state        <= CHLEN;
                        data_len     <= dma_len_i[31:5];
                        rd_wr_len    <= dma_len_i[31:5];
                    end
                    else if(pio_wr_req_p1)
                    begin
                        ddr_wr_req_o  <= 1'b1;
                        ddr_wr_be_n_o <= ddr_be[63:32];
                        ddr_addr_o    <= {3'h0,pio_fpga_addr_i[31:6],3'h0};
                        state         <= DDR_PW1;
                    end
                    else if(pio_rd_req_p1)
                    begin
                        ddr_addr_o    <= {3'h0,pio_fpga_addr_i[31:6],3'h0};
                        state     <= DDR_RD;
                        ddr_rd_req_o  <= 1'b1;
                    end
                end
                START:begin
                    o_switch_recv_buffer  <=   1'b0;
                    if(dma_data_avail_i)
                    begin
                        rd_dma_fifo_o <= 1'b1;
                        state         <= DDR_WR;
                        rd_data_cnt   <= rd_data_cnt + 1'b1;
                    end
                end
                DDR_WR:begin
                    ddr_wr_req_o  <= 1'b1;
                    rd_dma_fifo_o <= 1'b0;
                    ddr_wr_be_n_o <= 32'h00000000;
                    o_switch_recv_buffer  <=   1'b0;
                    if(ddr_wr_ack_i)
                    begin
                        ddr_wr_req_o  <= 1'b0;
                        ddr_addr_o    <= ddr_addr_o + 3'd4;
                        rd_wr_len     <= rd_wr_len - 1'b1;
                        if(rd_wr_len > 1)
                        begin
                            if(dma_data_avail_i)
                            begin
                                rd_dma_fifo_o <= 1'b1;
                                state         <= DDR_WR;
                                rd_data_cnt   <= rd_data_cnt + 1'b1;
                            end
                            else 
                                state    <=    START;
                            if(rd_data_cnt == 0)
                                o_switch_recv_buffer  <=   1'b1;
                        end
                        else
                        begin
                            state    <=    IDLE;
                            o_clr_recv_buffer  <=  1'b1;
                        end 
                    end
                end
                DDR_PW1:begin
                    if(ddr_wr_ack_i)
                    begin
                        ddr_wr_req_o  <= 1'b1;
                        ddr_wr_be_n_o <= ddr_be[31:0];;
                        state     <= DDR_PW2;
                    end
                end	
                DDR_PW2:begin
                    if(ddr_wr_ack_i)
                    begin
                        ddr_wr_req_o  <= 1'b0;
                        pio_wr_ack_o <= 1'b1;
                    end
    			        if(~pio_wr_req_p1)
    			        begin
    			            state    <=   IDLE;
    				         pio_wr_ack_o <= 1'b0;
    			        end	
    			    end	
                DDR_RD:begin
                    if(ddr_rd_ack_i)
                    begin
                        ddr_rd_req_o <= 1'b0; 
                        state    <= RD_DAT1;
                    end
                end
    		    	 RD_DAT1:begin
					     if(ddr_data_valid_i)
    			        begin
					         case(pio_fpga_addr_i[5:2])
                            'd0:begin
                                pio_data_o  <=  ddr_data_i[255:224];
                            end
                            'd1:begin
                                pio_data_o  <=  ddr_data_i[223:192];
                            end
                            'd2:begin
                                pio_data_o  <=  ddr_data_i[191:160];
                            end
                            'd3:begin
                                pio_data_o  <=  ddr_data_i[159:128];
                            end
                            'd4:begin
                                pio_data_o  <=  ddr_data_i[127:96];
                            end
                            'd5:begin
                                pio_data_o  <=  ddr_data_i[95:64];
                            end
                            'd6:begin
                                pio_data_o  <=  ddr_data_i[63:32];
                            end
                            'd7:begin
                                pio_data_o  <=  ddr_data_i[31:0];
					             end
					         endcase
   			            state             <=    RD_DAT2;								    
    			        end	
    			    end
                RD_DAT2:begin
    			        if(ddr_data_valid_i)
    				     begin
                        pio_rd_ack_o    <=    1'b1;
								case(pio_fpga_addr_i[5:2])
	                         'd8:begin
                                pio_data_o  <=  ddr_data_i[255:224];
                            end
                            'd9:begin
                                pio_data_o  <=  ddr_data_i[223:192];
                            end
                            'd10:begin
                                pio_data_o  <=  ddr_data_i[191:160];
                            end
                            'd11:begin
                                pio_data_o  <=  ddr_data_i[159:128];
                            end
                            'd12:begin
                                pio_data_o  <=  ddr_data_i[127:96];
                            end
                            'd13:begin
                                pio_data_o  <=  ddr_data_i[95:64];
                            end
                            'd14:begin
                                pio_data_o  <=  ddr_data_i[63:32];
                            end
                            'd15:begin
                                pio_data_o  <=  ddr_data_i[31:0];
                            end							
								endcase
                    end
    				    if(~pio_rd_req_p1)
    				    begin
    				       state   <=   IDLE;
    				       pio_rd_ack_o  <=   1'b0;
                      clr_rcv_data_cntr <= 1'b1;
    				    end
    			    end	
                CHLEN:begin
    			        if(rd_wr_len <= 2)
    		           begin
    				         last_read_flag <= 1'b1;
    				     end
                    if(buffer_space >= 2 & ~rd_fifo_full_i)
                    begin
    				         state  <= RDDR;
                        issue_rd <= 1'b1;
								ddr_rd_req_o  <= 1'b1;
                    end
                end
    			    RDDR:begin    			        
                    issue_rd  <= 1'b0;
    				     if(ddr_rd_ack_i)
    				     begin
    				         ddr_rd_req_o  <= 1'b0;
                        ddr_addr_o    <= ddr_addr_o + 4'd8;
    				         if(last_read_flag)
    					      begin
    					         state       <= PACK;
                           last_read_flag <= 1'b0;
    					      end		
    					      else if(buffer_space >= 2 & ~rd_fifo_full_i)	
                        begin
								    issue_rd <= 1'b1;
									 ddr_rd_req_o  <= 1'b1;
									 state  <= RDDR;		
                            if(rd_wr_len == 4)
    		                   begin
    				                 last_read_flag <= 1'b1;
									 end	  
    				         end	 								
                        else								
    					          state     <= CHLEN;
									 									 
    					      if(rd_wr_len >= 2)
    					          rd_wr_len <= rd_wr_len - 2'd2;
    				     end
    			    end
                PACK:begin
                    fpga_system_dma_ack_o <= 1'b0;
                    if(rcv_data_cntr >= data_len)
                    begin
                        if(rd_fifo_empty_p)
                            fpga_system_dma_ack_o   <=   1'b1;
                    end
                    if(fpga_system_dma_ack_o & ~system_dma_req_p)
                    begin
                         fpga_system_dma_ack_o  <=    1'b0;
                         state             <=    IDLE;
                         clr_rcv_data_cntr <=    1'b1;
                    end
                end
            endcase
        end
    end

    //Since the DDR IP receives back to back read requests and acks, there should be some way to prevent the receive
    //fifos from over flowing. This block prevents queing more than 8 read requests. For better performance increase
    //the initial buffer space, then the config buffer depth should be also increased
    always @(posedge ddr_clk_i)
    begin
        if(reset)
        begin
            buffer_space    <=  'd64;  
        end
        else
        begin
            if(clr_rcv_data_cntr)
                buffer_space    <=  'd64;
            else if(issue_rd & ~ddr_data_valid_i)
                buffer_space <= buffer_space - 2'd2;
            else if(issue_rd & ddr_data_valid_i)
                buffer_space <= buffer_space - 1'd1;
            else if(ddr_data_valid_i)
                buffer_space <= buffer_space + 1'd1;
        end
    end

    //Counts the number of bytes received
    always @(posedge ddr_clk_i)
    begin
        if(reset)
            rcv_data_cntr    <=    0;
        else
        begin
            if(clr_rcv_data_cntr)
                rcv_data_cntr    <=    'd0;
            else if(ddr_data_valid_i)
                rcv_data_cntr    <=    rcv_data_cntr + 1'd1;
        end
    end

endmodule
