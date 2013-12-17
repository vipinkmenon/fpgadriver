/*
 * Filename: enet_rx_tester.c
 * Version: 1.0
 * Description: Ethernet Interface Test Function
 *  driver defined in "fpga.h".
 * Author : Shreejith S
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "fpga.h"
#include "enet.h"

#define DATA_SIZE (1024*1024*1024)  //Size of current DMA write
unsigned int senddata[DATA_SIZE/4];  

int main()
{
	float pkt_time;
	char buff[200] = "\0";
	char rd_len[15];
	int rtn,timeout,i,k;
    int packet_num;
	char pkt_num_str[15];
    unsigned int arg = 100;
    int rd_size = 1024*1;
    int wr_size = 1024*1; // 64 KByte is the buffer-limit
    int src_addr = 0x0;
    int dst_addr = 0x1024;
	int num_rx_pack; 
    timeout = 10*1000; // 10 secs.

   	FILE* ett = NULL;
		ett = fopen("Res_eth_rx_test.txt","w+");
		fclose(ett); 
    //Clear Memory
	printf("Initializing DRAM at %0x with 0  \n ",dst_addr);
	for(i = 0; i < DATA_SIZE/4; i++){
	    senddata[i] = 0x0;
    }
 
    rtn = fpga_send_data(DRAM,(unsigned char *) senddata,DATA_SIZE, src_addr);

	// Loop Tests
	for (i=1; i<1024*1024;i=i*2){
		rd_size = i * 1024;
        printf("Setting Read size to %0x\n", rd_size);
        rtn = fpga_reg_wr( ETH_RX_SIZE, rd_size);
        printf("Setting DRAM Dest address to %0x\n",dst_addr);
        rtn = fpga_reg_wr( ETH_DST_ADDR, dst_addr);
        printf("Enabling ethernet\n");
        rtn = fpga_reg_wr(0x8,0x00000004);
        rtn = fpga_reg_rd(0x8);
        printf("Control Reg %0x\n",rtn);
		k = socket_send(i);
		fpga_wait_interrupt(enet);
		printf("\n %d Packets Send from Host",k);
		rtn = fpga_reg_rd(ETH_RX_STAT);
		printf("\n Total Time (FPGA RX STAT) : %0f ns\n",rtn*5.0);
        pkt_time = rtn*5.0;
		printf("Tpt : %0f MBps\n", (float)(rd_size/pkt_time)*1000000000/1024/1024); 
		sprintf(rd_len,"%d",rd_size);
		strcpy (buff,rd_len);
		//	strcat (buff," Bytes \n");
		strcat (buff,",");
		//	strcat (buff,"Time : ");
		//	sprintf(rd_len,"%f",packet_time);
		//	strcat(buff,rd_len);
		//	strcat(buff,"\nTpt : ");
		sprintf(rd_len,"%f", (float)(rd_size/pkt_time)*1000000000/1024/1024);
		strcat(buff,rd_len);
		strcat(buff,"\n");
		ett = fopen("Res_eth_rx_test.txt","a");        
		fwrite(&buff,1,strlen(buff),ett);
		fclose(ett);
		strcpy(buff,"\0");
		//sleep(5);
	}

printf("Exiting...");
	
}
