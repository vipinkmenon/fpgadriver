#include <stdio.h>
#include <stdlib.h>
#include "fpga.h"
#include <assert.h>
#include <sys/time.h>
#include <unistd.h>

#define DATA_SIZE 1024*1024*1024  //Total number of bytes


int main(int argc, char* argv[]) 
{
    int rtn,i;
    long usecs;
    unsigned int test_size = atoi(argv[1]);
    //unsigned int test_size = 256;
        

	printf("# Testing data transfer between FPGA DRAM to user logic for different data size\n");
    //	printf("# Transfer Size(Bytes), Transfer Time (s),Throughput: (MB/s)\n"); 

	//while(test_size <= DATA_SIZE) {
   		ddr_user_send_data(USERDRAM1,test_size,0x0,0);
		ddr_user_send_data(USERDRAM2,test_size,0x0,0);
		ddr_user_send_data(USERDRAM3,test_size,0x0,0);
		ddr_user_send_data(USERDRAM4,test_size,0x0,0);
		fpga_wait_interrupt(ddruser1);   
		fpga_wait_interrupt(ddruser2); 
		fpga_wait_interrupt(ddruser3); 
		fpga_wait_interrupt(ddruser4);       
		//test_size *= 2;
	//}

	return 0;
}                 
