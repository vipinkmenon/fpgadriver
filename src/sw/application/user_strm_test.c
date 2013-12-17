#include <stdio.h>
#include <stdlib.h>
#include "fpga.h"
#include <assert.h>
#include <sys/time.h>
#include <unistd.h>

#define DATA_POINTS (4*1024*1024)  //Total number of bytes

struct timeval start, end;


unsigned int senddata[DATA_POINTS/4];  //Buffer to hold the send data

int main(int argc, char* argv[]) 
{
	int rtn,i;
    	unsigned int test_size = 1024;
    	
        //Incremental Data for testing
	for(i = 0; i < DATA_POINTS/4; i++){
            senddata[i] = i;
	}

    printf("# Host to PCIE\n");
    printf("# Transfer Size(Bytes), Transfer Time (s),Throughput: (MB/s)\n"); 
	

    rtn = fpga_transfer_data(HOST,USERPCIE1,(unsigned char *) senddata,test_size,0, 1);
        //fpga_wait_interrupt();

	return 0;
}                 
