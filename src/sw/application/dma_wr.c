#include <stdio.h>
#include <stdlib.h>
#include "fpga.h"
#include <assert.h>
#include <sys/time.h>
#include <unistd.h>

#define DATA_POINTS (1024*1024*1024)  //Size of current DMA write


unsigned int senddata[DATA_POINTS/4];  //Buffer to hold the send data

int main(int argc, char* argv[]) 
{
	int rtn,i;
    unsigned int arg = 0;
    unsigned int test_size = atoi(argv[1]);
	//unsigned int test_size = 1024;
        
	
    printf("# DMA write to FPGA DRAM from Host\n");
    //printf("# Transfer Size(Bytes), Transfer Time (s),Throughput: (MB/s)\n"); 

    //Incremental Data for testing
	for(i = 0; i < DATA_POINTS/4; i++){
        senddata[i] = arg;
	    arg++;
	}

	//while(test_size <= DATA_POINTS) {
    rtn = fpga_transfer_data(HOST,DRAM, (unsigned char *) senddata, test_size, 0, 0);
	//test_size *= 2;
	//}
	return 0;
}                 
