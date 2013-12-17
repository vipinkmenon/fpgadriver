#include <stdio.h>
#include <stdlib.h>
#include "fpga.h"
#include <assert.h>
#include <sys/time.h>
#include <unistd.h>

#define DATA_SIZE 1024*1024*1024  //Total number of bytes

#define GETTIME(t) gettimeofday(&t, NULL)
#define GETUSEC(e,s) e.tv_usec - s.tv_usec 


int main(int argc, char* argv[]) 
{
    int rtn,i;
    long usecs;
    unsigned int test_size = 256;
    
	printf("# data transfer between FPGA DRAM to user logic for different data size\n");
   // 	printf("# Transfer Size(Bytes), Transfer Time (s),Throughput: (MB/s)\n"); 
	//printf("Transfer Size(Bytes)\t\t\t\tThroughput: MB/s,\n"); 

	//while(test_size <= DATA_SIZE) {
   		user_ddr_send_data(USERDRAM1,test_size,0x0,0);
		user_ddr_send_data(USERDRAM2,test_size,0x0,0);
		user_ddr_send_data(USERDRAM3,test_size,0x0,0);
		user_ddr_send_data(USERDRAM4,test_size,0x0,0);
		fpga_wait_interrupt(user1ddr);   
		fpga_wait_interrupt(user2ddr); 
		fpga_wait_interrupt(user3ddr); 
		fpga_wait_interrupt(user4ddr); 
		//printf("%d, %f, %f\n", test_size,(e-s)*1e-6,(double)(test_size*1000000.0)/(1024.0*1024.0*(double)(e-s)));
	    //printf("%d \t\t\t\t\t\t %f\n", 4*test_size,(double)(4*test_size*1000000.0)/(1024.0*1024.0*(double)(e-s))); 
	//	test_size *= 2;
	//}


	return 0;
}                 
