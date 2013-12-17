module v7_emac_controller
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

		
      // Receiver (AXI-S) Interface
      //----------------------------------------
      output        rx_fifo_clk,
      output        rx_fifo_rstn,
      output [7:0]  rx_axis_fifo_tdata,
      output        rx_axis_fifo_tvalid,
      input         rx_axis_fifo_tready,
      output        rx_axis_fifo_tlast,


      // Transmitter (AXI-S) Interface
      //-------------------------------------------
      output        tx_fifo_clk,
      output        tx_fifo_rstn,
      input  [7:0]  tx_axis_fifo_tdata,
      input         tx_axis_fifo_tvalid,
      output        tx_axis_fifo_tready,
      input         tx_axis_fifo_tlast,
      input         loop_back_en,
      output        o_tx_mac_count
		
    );

endmodule