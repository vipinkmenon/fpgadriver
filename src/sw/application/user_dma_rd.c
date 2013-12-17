#include <stdio.h>
#include <stdlib.h>
#include "fpga.h"
#include "papi.h"
#include <assert.h>
#include <sys/time.h>
#include <unistd.h>

#define DATA_POINTS (1024*1024*1024)  //Size of current DMA write

long_long PAPI_get_real_usec(void);

unsigned int gDATA[DATA_POINTS];  //Buffer to hold the send data

int main(int argc, char* argv[]) 
{
	int rtn,i;
    long usecs;
    //unsigned int test_size = 1024;
    unsigned int test_size = atoi(argv[1]);
    long_long s;
    long_long e;
	
    printf("# Testing dma read from User logic to host for different data size\n");
    printf("# Transfer Size(Bytes), Transfer Time (s),Throughput: (MB/s)\n"); 

	//while(test_size <= DATA_POINTS) {
			s = PAPI_get_real_usec(); 
        	rtn = fpga_transfer_data(USERPCIE1,HOST,(unsigned char *) gDATA, test_size ,0, 1);
	        e = PAPI_get_real_usec();         
	        //printf("%d \t\t\t\t\t\t %f\n", test_size,(double)(test_size*1000000.0)/(1024.0*1024.0*(double)(e-s))); 
		printf("%d, %f, %f\n", test_size,(e-s)*1e-6,(double)(test_size*1000000.0)/(1024.0*1024.0*(double)(e-s)));
	//	test_size *= 2;
	//}

	return 0;
}                 
