/*
 * Filename: enet_tx_tester.c
 * Version: 1.0
 * Description: Ethernet Interface Test Function
 * Author : Shreejith S
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "fpga.h"
#include "enet.h"

#define DATA_SIZE (1024*1024)  //Size of current DMA write
unsigned int senddata[DATA_SIZE/4];  

int main()
{
	float packet_time;
	char buff[200] = "\0";
	char wr_len[15];
	int rtn,timeout,i,k;
        int packet_num;
	char pkt_num_str[15];
        unsigned int arg = 100;
        int rd_size = 1024*1;
        int wr_size = 1024*1; // 64 KByte is the buffer-limit
        int src_addr = 0x0;
        int dst_addr = 1024;
	int num_tx_pack = wr_size/1024;
        timeout = 10*1000; // 10 secs.


   	 FILE* ett = NULL;
         ett = fopen("Res_eth_tx_test.txt","w+");
         fclose(ett); 

	printf("Initializing DRAM at %0x with incremental pattern \n ",src_addr);
	int test_val = 0x0;
	for(i = 0; i < DATA_SIZE/4; i++){
			senddata[i] = test_val;
            test_val++;
        }
        rtn = fpga_send_data(DRAM, (unsigned char *) senddata,DATA_SIZE, src_addr);
// Loop Tests
	for (k = 1; k <= 1024*1024; k=k*2) {

		wr_size = 1024 * k;
	
		// Eth SND DATA
        printf("Setting Write size to %0x\n", wr_size);
        rtn = fpga_reg_wr(ETH_TX_SIZE, wr_size);
        printf("Setting DRAM source address to %0x\n",src_addr);
        rtn = fpga_reg_wr(ETH_SRC_ADDR, src_addr);

		rtn = fpga_reg_rd(0x40 );
		printf("FPGA TX SIZE %0x \n",rtn);
        
        printf("Enabling ethernet\n");

        rtn = fpga_reg_wr( 0x8,0x00000004);
		rtn = fpga_reg_rd( 0x10);

		fpga_wait_interrupt(enet);
		rtn = fpga_reg_rd(ETH_TX_STAT);
		printf("FPGA ENET STS %0x \n",rtn);	
		packet_time = rtn * 5.0;
		printf("Total Time : %0f ns\n",packet_time);
		printf("Tpt : %0f MBps\n", (float)(wr_size/packet_time)*1000000000/1024/1024); 
		sprintf(wr_len,"%d",wr_size);
		strcpy (buff,wr_len);
		//	strcat (buff," Bytes \n");
		strcat (buff,",");
		//	strcat (buff,"Time : ");
		//	sprintf(wr_len,"%f",packet_time);
		//	strcat(buff,wr_len);
		//	strcat(buff,"\nTpt : ");
		sprintf(wr_len,"%f", (float)(wr_size/packet_time)*1000000000/1024/1024);
		strcat(buff,wr_len);
		strcat(buff,"\n");
		ett = fopen("Res_eth_tx_test.txt","a");        
		fwrite(&buff,1,strlen(buff),ett);
		fclose(ett);
		strcpy(buff,"\0");
	//sleep(5);
	}

printf("Exiting...");
	
}
