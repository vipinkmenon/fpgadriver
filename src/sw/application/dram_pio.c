#include <stdio.h>
#include <stdlib.h>
#include "fpga.h"
#include <assert.h>
#include <sys/time.h>
#include <unistd.h>



int main(int argc, char* argv[]) 
{

	int rtn,i;
        int arg = 0;
	int error_flag = 0;


        printf("Writing incremental data to DDR Memory Space\n");
 
        //Write 400000 byte incremental pattern to the DDR
        for(i=0;i<4000;i=i+4){                       
            rtn = fpga_ddr_pio_wr(i,arg);
	        arg++;
        }

        printf("Reading and comparing from DDR Memory Space\n");

        for(i=0;i<4000;i=i+4){                       
            rtn = fpga_ddr_pio_rd(i);
        }


	    arg =0;

        for(i=0;i<4000;i=i+4){                       
            rtn = fpga_ddr_pio_rd(i);
	    if(rtn != arg){
		printf("Error at memory location %d , Expected %d Received %d\n",i,arg,rtn);
		error_flag = 1;
	    }
	    arg++;
        }

	if(!error_flag)
		printf("Congratulations....Data comparison passed!!\n");

	printf("Exiting.\n");
        printf("_____________________________________________________________________________\n");
	return 0;
}                 
