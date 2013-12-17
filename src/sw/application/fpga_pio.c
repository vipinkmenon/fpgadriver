#include <stdio.h>
#include <stdlib.h>
#include "fpga.h"
#include <assert.h>
#include <sys/time.h>
#include <unistd.h>

int main(int argc, char* argv[]) 
{
        sys_stat stat;
		int rtn;

        rtn = fpga_reg_rd(0x0);          //Read version register
        printf("Version : %0x\n",rtn);

        printf("Write scratch pad with 0x5\n");   //Write and read back scratchpad register
        rtn = fpga_reg_wr(0x4,0x5);

        printf("Read scratch pad: ");
        rtn = fpga_reg_rd(0x4);
        printf("%0x\n",rtn);   

        printf("Reading system parameters\n");
        stat = fpga_read_sys_param();

        printf("Temperature %f C\n",stat.temp);
        printf("VCCint %f V\n",stat.v_int);
        printf("Vaux %f V\n",stat.v_aux);
        printf("V12s %f V\n",stat.v_board);
        printf("Iint %f A\n",stat.i_int);
        printf("Iboard %f A\n",stat.i_board);
        printf("FPGA Power %f Watt\n",stat.p_int);
        printf("Board Power %f Watt\n",stat.p_board);
       //close the virtual device and free all buffers

        /*printf("Reading from user logic\n");
        rtn = fpga_reg_rd(0x200);
        printf("%0x\n",rtn); */


	printf("Exiting.\n");
        printf("_____________________________________________________________________________\n");
	return 0;
}                 
