//--------------------------------------------------------------------------------
// Project    : SWITCH
// File       : top.v
// Version    : 0.1
// Author     : Vipin.K
//
// Description: The multiboot controller. Generates IPROG command sequence to ICAP
//              to initiate a read from external memory
//
//--------------------------------------------------------------------------------


module multiboot_ctrl
    (
    input        i_clk,
    input        i_rst,
    input        i_ctrl_en,
    input [31:0] i_boot_addr
    );

localparam IDLE   =  'd0,
           S_ICAP =  'd1,
			  WAIT   =  'd2;

reg  [1:0]  state ;
reg         icap_en;
reg  [31:0] icap_wr_data;
reg         icap_wr_en;
reg  [3:0]  counter;
reg         ctrl_en;
reg         ctrl_en_p;
wire [31:0] reversed_address;

assign reversed_address = {2'b00,1'b1,i_boot_addr[24],i_boot_addr[25],3'b000,i_boot_addr[16],i_boot_addr[17],i_boot_addr[18],i_boot_addr[19],i_boot_addr[20],i_boot_addr[21],i_boot_addr[22],i_boot_addr[23],i_boot_addr[8],i_boot_addr[9],i_boot_addr[10],i_boot_addr[11],i_boot_addr[12],i_boot_addr[13],i_boot_addr[14],i_boot_addr[15],i_boot_addr[0],i_boot_addr[1],i_boot_addr[2],i_boot_addr[3],i_boot_addr[4],i_boot_addr[5],i_boot_addr[6],i_boot_addr[7]};
//for supporting v7, address pins [25:24] are mapped to the RS pins

ICAP_VIRTEX6 #(
  .DEVICE_ID('h4250093),
  .ICAP_WIDTH("X32"),
  .SIM_CFG_FILE_NAME("NONE")
)
ICAP_VIRTEX6_inst(
    .BUSY(),  // 1-bit Busy/Ready output
    .O(),     // 32-bit Configuration data output bus
    .CLK(i_clk), // 1-bit Clock Input
    .CSB(icap_en),// 1-bit Active-Low ICAP Enable
    .I(icap_wr_data),// 32-bit Configuration data input bus
    .RDWRB(icap_wr_en)//1-bit Read/Write Select
);


always @(posedge i_clk)
begin
   ctrl_en   <=  i_ctrl_en;
   ctrl_en_p <=  ctrl_en;
end


always @(posedge i_clk)
begin
    if(i_rst)
    begin
        state <=    IDLE;
        icap_wr_en <= 1'b1;
        icap_en    <= 1'b1;
    end
    else
    begin
        case(state)
            IDLE:begin
              if(ctrl_en_p)
              begin
                 state <= S_ICAP;
                 counter <= 0;
              end
              else
                 state <= IDLE;
            end 
            S_ICAP:begin
                counter <=   counter + 1'b1;
                icap_wr_en <= 1'b0;
                icap_en    <= 1'b0;
                case(counter)
                    'h0:begin
                        icap_wr_data <= 'hFFFFFFFF;//Dummy Word
                    end
                    'h1:begin
                        icap_wr_data <= 'h5599AA66; //Sync Word
                    end
                    'h2:begin
                       icap_wr_data <= 'h04000000;//type 1 NO OP
                    end
                    'h3:begin
                       icap_wr_data <= 'h0C400080;//Type 1 Write 1 Words to WBSTAR
                    end
                    'h4:begin 
                      icap_wr_data <= reversed_address;//Warm Boot Start Address 
                    end
                    'h5:begin
                      icap_wr_data <= 'h0C000180;     //Type 1 Write 1 Words to CMD
                    end
                    'h6:begin
                      icap_wr_data <= 'h000000F0; //IPROG Command
                    end
                    'h7:begin
                      icap_wr_data <= 'h04000000;//Type 1 NO OP
                    end
                    'h8:begin
                      icap_wr_en <= 1'b1;
                      icap_en    <= 1'b1;                    
                      state <= WAIT;
                    end
						  WAIT:begin
						    state <= WAIT;
						  end
                endcase
            end
        endcase
    end
end

endmodule
