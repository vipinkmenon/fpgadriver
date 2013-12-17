#include <stdio.h>
#include <stdlib.h>
#include "fpga.h"
#include <assert.h>
#include <sys/time.h>
#include <unistd.h>

#define DATA_POINTS (1024*1024*1024)  //Size of current DMA write


unsigned int gData[DATA_POINTS/4];  //Buffer to hold the received data

int main(int argc, char* argv[]) 
{

	int rtn,i;
    unsigned int test_size = atoi(argv[1]);
        
    printf("# DMA read from FPGA DRAM to Host\n");
    printf("# Transfer Size(Bytes), Transfer Time (s),Throughput: (MB/s)\n"); 
    rtn = fpga_transfer_data(DRAM,HOST,(unsigned char *)gData, test_size ,0, 0);

	return 0;
}                 
