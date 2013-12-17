#include <stdio.h>
#include <stdlib.h>
#include "fpga.h"
#include <assert.h>
#include <sys/time.h>
#include <unistd.h>

#define DATA_SIZE (4*1024*1024)  //Total number of bytes
#define DATA_POINTS (128*1024*1024)  //Size of current DMA write

struct timeval start, end;

#define GETTIME(t) gettimeofday(&t, NULL)
#define GETUSEC(e,s) e.tv_usec - s.tv_usec 

unsigned int senddata[DATA_POINTS/4];  //Buffer to hold the send data

int main(int argc, char* argv[]) 
{
	int rtn,i;
        long usecs;
        unsigned int arg = 0;
        
        fpga_wait_interrupt(hostuser2); 

}
