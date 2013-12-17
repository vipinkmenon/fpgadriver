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

	
    fpga_reg_wr(0x400,0xA5A5A5A5);
    rtn = fpga_reg_rd(0x400);          //Read version register
    printf("Register : %0x\n",rtn);


	return 0;
}                 
