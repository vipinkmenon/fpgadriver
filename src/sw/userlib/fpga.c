/*******************************************************************************
 * Copyright (c) 2012, Matthew Jacobsen
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met: 
 * 
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer. 
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution. 
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * The views and conclusions contained in the software and documentation are those
 * of the authors and should not be interpreted as representing official policies, 
 * either expressed or implied, of the FreeBSD Project.
 */

/*
 * Filename: fpga.c
 * Version: 1.0
 * Description: Linux PCIe communications API for RIFFA. Uses RIFFA kernel
 *  driver defined in "fpga_driver.h".
 * History: @mattj: Initial pre-release. Version 0.9.
 * Updated the file to support the new multiport swich
 * Author : Vipin K
 */

#define _GNU_SOURCE
#define ERRINUSE -2
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <fcntl.h>
#include <math.h>
#include <string.h>
#include <sys/mman.h>
#include <linux/sched.h>
#include <pthread.h>
#include "fpga.h"


struct fpga_dev
{
    int fd;
    unsigned char * cfgMem;
    unsigned char * bufMem[NUM_CHANNEL];
    int numBuffers;
    int intrFds[NUM_CHANNEL];
    pthread_t sendThreads[NUM_CHANNEL];
    pthread_t recvThreads[NUM_CHANNEL];
};

//global variables
struct fpga_dev *fpgaDev;
bool fpgaInUse = false;

/* Initialize/finalize functions. */
__attribute__((constructor))
int fpga_init() {

	if(!fpgaInUse){
			int fd;
			int i = 0;
			char buf[50];
			int timeout = 10*1000; //10 sec
            unsigned int stat;

			// Allocate space for the fpga_dev
			fpgaDev = malloc(sizeof(fpga_dev));
			if (fpgaDev == NULL) {
				fprintf(stderr, "Failed to malloc fpga_dev\n");
				exit(EXIT_FAILURE);
				//return -ENOMEM;
			}
			
			
			// Open the device file.
			fd = open(FPGA_DEV_PATH, O_RDWR | O_SYNC);
			if(fd < 0) {
				return fd;
			}
			
			// Map the DMA regions.
			for (i = NUM_CHANNEL-1; i >= 0; i--) {
				fpgaDev->bufMem[i] = mmap(NULL, BUF_SIZE, PROT_READ | PROT_WRITE, 
					MAP_FILE | MAP_SHARED, fd, PCI_BAR_0_SIZE + (BUF_SIZE*i));
				if(fpgaDev->bufMem[i] == MAP_FAILED)
					break;
			}
			fpgaDev->numBuffers = NUM_CHANNEL-1 - i;
			if(fpgaDev->numBuffers == 0)
				exit(EXIT_FAILURE);
				//return -ENOMEM;
			
			// Map the config region.
			fpgaDev->cfgMem = mmap(NULL, PCI_BAR_0_SIZE, PROT_READ | PROT_WRITE, 
				MAP_FILE | MAP_SHARED, fd, 0);
			if(fpgaDev->cfgMem == MAP_FAILED) {
				fprintf(stderr, "mmap() failed to map fpga config region\n");
				exit(EXIT_FAILURE);
				//return -ENOMEM;
			}

			// Initialize the channel fds
			for (i = 0; i < NUM_CHANNEL; i++)
				fpgaDev->intrFds[i] = -1;


			for (i = 0; i < NUM_CHANNEL; i++){
				fpga_channel_open(i,timeout);
			}

			//automatic exit function
			fpgaInUse = true;
            		//Read the status register to get the link status
		        stat = fpga_reg_rd(STA_REG);
		        if(stat==0xFFFFFFFF){
                		printf("Fatal Error: The FPGA not detected by the host\n");
				exit(EXIT_FAILURE);
	    		}		
			if(!(stat&0x40000000))
				printf("Fatal Error: The DRAM memory not detected by FPGA\n");             
			fprintf(stderr,"fpga initiated \n");
			atexit(fpga_close);
			return 0;
	}
	else{
		fprintf(stderr,"FPGA is already in use\n");
		return ERRINUSE;
	}
}



/* Channel opening/closing/configuring functions. */
int fpga_channel_open(int channel, int timeout) {
    int fd;
    char buf[50];
    
    if (fpgaDev->intrFds[channel] >= 0)
        return 0;
    sprintf(buf, "%s/%s%02d", FPGA_INTR_PATH, IRQ_FILE, channel);
    fd = open(buf, O_RDWR);
    if (fd < 0)
        return fd;
    fpgaDev->intrFds[channel] = fd;
    
    if (timeout >= 0)
        return ioctl(fpgaDev->intrFds[channel], IOCTL_SET_TIMEOUT, timeout);
    
    return 0;
}

/*Read the system parameters such as temperature, voltage etc from the FPGA system monitor. 
  Uses predefined Xilinx transfer functions to conver them to absolute values
  Function returns a structure (sys_stat) which contains core voltage,current,temperature, IO voltage, 
  board voltage,current, core power consumption and total power consumption*/

sys_stat fpga_read_sys_param()
{
    sys_stat tmp;
    int rtn;
    float v_shnt;
    rtn = fpga_reg_rd(SMT);
    tmp.temp = ((rtn/65536.0)/0.00198421639)-273.15;
    rtn = fpga_reg_rd(SMA);
    tmp.v_int = (rtn*3.0)/65536.0;
    rtn = fpga_reg_rd(SMV);
    tmp.v_aux = (rtn*3.0)/65536.0;
    rtn = fpga_reg_rd(SMP);
    v_shnt =  (rtn*1000.0)/65536.0;
    tmp.i_int = (v_shnt*200.0)/1000;
    tmp.p_int = tmp.v_int*tmp.i_int;
    rtn = fpga_reg_rd(SAC);
    tmp.v_board = (rtn*350.0)/65536.0;
    rtn = fpga_reg_rd(SBV);
    tmp.i_board = (rtn/(15.0*1e-3))/65536.0;
    tmp.p_board = tmp.v_board*tmp.i_board;
    return tmp;
}


void fpga_close() {
	if(fpgaInUse){
		int i;
			
		// Unmap the memory regions.
		for (i = fpgaDev->numBuffers-1; i >= 0; i--) {
			if (fpgaDev->bufMem[i] != NULL)
				munmap(fpgaDev->bufMem[i], BUF_SIZE);
				fpgaDev->bufMem[i] = NULL;
		}
		if (fpgaDev->cfgMem != NULL)
			munmap(fpgaDev->cfgMem, PCI_BAR_0_SIZE);
		fpgaDev->cfgMem = NULL;
			
		// Close the device file.
		if (fpgaDev->fd >= 0)
			close(fpgaDev->fd);
		fpgaDev->fd = -1;
		fprintf(stderr,"fpga closed \n");
		fpgaInUse=false;
	}
	else{
		fprintf(stderr,"cannot close fpga, it was never opened");
	}
}


/* Function to read a single 32-bit value from the FPGA */
unsigned int fpga_read_word(unsigned char * mptr) {
    return *((unsigned int *)mptr);
}

/* Function to write a single 32-bit value to the FPGA */
void fpga_write_word(unsigned char * mptr, unsigned int val) {
    *((unsigned int *)mptr) = val;
}


/*The main function used to send PCIe data to the SWITCH DRAM interface and the PCIe user stream interfaces
    inputs :  destination type (ddr, user1, user2 etc)
            data buffer holdin the send data
            total length of the transfer
            target address in case of data transfer to DRAM and blocking-non blocking indication in case of user data transfer
    output :  Returns total number of bytes sent
    The function rounds the transfer size to 64byte boundary for PCIe packet requirement
    The total transfer data is divided into 4MB chunks to fit into the host DMA buffers.
*/
int fpga_send_data(DMA_PNT dest, unsigned char * senddata, int sendlen, unsigned int addr) {
        unsigned int rtn;
        unsigned int len;
        unsigned int ddr_addr;
        unsigned int size = BUF_SIZE;
        unsigned int amt;
        unsigned int buf;
        unsigned int pre_buf;
        unsigned int tmp_buf;
        int sent = 0;
        if(dest == DRAM){
            buf = 0;
            pre_buf = 1;
            ddr_addr = addr;
            len = (sendlen+63)&0xFFFFFFC0;                         //Align length to 64 bytes
            // Send initial transfer request.
            amt = len < size ? len : size;
            rtn = write(fpgaDev->intrFds[0], senddata, amt);
            fpga_reg_wr(PC_DDR_DMA_SYS_REG,rtn);
            fpga_reg_wr(PC_DDR_DMA_FPGA_REG,ddr_addr); 
            fpga_reg_wr(PC_DDR_DMA_LEN_REG,amt);
            fpga_reg_wr(CTRL_REG,SEND_DDR_DATA);
            ddr_addr += amt;
            sent += amt;
            // Still more data, send to next buffer
            if (sent < len) {
                amt = (len-sent < size ? len-sent : size);
                rtn = write(fpgaDev->intrFds[1], senddata+sent, amt);         
            }
            while(1){
               fpga_wait_interrupt(hostddr);          //Wait for interrupt from first buffer
               if (sent < len) {
                   fpga_reg_wr(PC_DDR_DMA_SYS_REG,rtn);
                   fpga_reg_wr(PC_DDR_DMA_FPGA_REG,ddr_addr); 
                   fpga_reg_wr(PC_DDR_DMA_LEN_REG,amt);
                   fpga_reg_wr(CTRL_REG,SEND_DDR_DATA); 
                   ddr_addr += amt;
                   sent += amt;
                   tmp_buf = buf;
                   buf = pre_buf;
                   pre_buf = tmp_buf;                                 
                   if (sent < len) {
                       amt = (len-sent < size ? len-sent : size);
                       rtn = write(fpgaDev->intrFds[pre_buf], senddata+sent, amt);
                   }
               }
               else{
                   return sent;
               }
            }
        }
        else if(dest == USERPCIE1){
            buf = 0;
            pre_buf = 1;
            len = sendlen;
            amt = len < size ? len : size;
            rtn = write(fpgaDev->intrFds[0], senddata, amt);
            fpga_reg_wr(PC_USER1_DMA_SYS,rtn);
            fpga_reg_wr(PC_USER1_DMA_LEN,amt);
            fpga_reg_wr(CTRL_REG,SEND_USER1_DATA); 
            sent += amt; 
            // Still more data, send to next buffer
            if (sent < len) {
                amt = (len-sent < size ? len-sent : size);
                rtn = write(fpgaDev->intrFds[1], senddata+sent, amt);         
            }            
            if(addr != 0){
                while(1){
                    fpga_wait_interrupt(hostuser1);  
                    if (sent < len) {
                        fpga_reg_wr(PC_USER1_DMA_SYS,rtn);
                        fpga_reg_wr(PC_USER1_DMA_LEN,amt);
                        fpga_reg_wr(CTRL_REG,SEND_USER1_DATA); 
                        sent += amt;
                        tmp_buf = buf;
                        buf = pre_buf;
                        pre_buf = tmp_buf;     
                        if (sent < len){                         
                            amt = (len-sent < size ? len-sent : size);
                            rtn = write(fpgaDev->intrFds[pre_buf], senddata+sent, amt);
                        }
                    }
                    else
                       return sent;
                }
            }
        }
        else if(dest == USERPCIE2){
            buf = 2;
            pre_buf = 3;
            len = sendlen;
            amt = len < size ? len : size;
            rtn = write(fpgaDev->intrFds[2], senddata, amt);
            fpga_reg_wr(PC_USER2_DMA_SYS,rtn);
            fpga_reg_wr(PC_USER2_DMA_LEN,amt);
            fpga_reg_wr(CTRL_REG,SEND_USER2_DATA); 
            sent += amt; 
            // Still more data, send to next buffer
            if (sent < len) {
                amt = (len-sent < size ? len-sent : size);
                rtn = write(fpgaDev->intrFds[3], senddata+sent, amt);         
            }            
            if(addr != 0){
                while(1){
                    fpga_wait_interrupt(hostuser2);  
                    if (sent < len) {
                        fpga_reg_wr(PC_USER2_DMA_SYS,rtn);
                        fpga_reg_wr(PC_USER2_DMA_LEN,amt);
                        fpga_reg_wr(CTRL_REG,SEND_USER2_DATA); 
                        sent += amt;
                        tmp_buf = buf;
                        buf = pre_buf;
                        pre_buf = tmp_buf;     
                        if (sent < len){                         
                            amt = (len-sent < size ? len-sent : size);
                            rtn = write(fpgaDev->intrFds[pre_buf], senddata+sent, amt);
                        }
                    }
                    else
                       return sent;
                }
            }
        }
        else if(dest == USERPCIE3){
            buf = 4;
            pre_buf = 5;
            len = sendlen;
            amt = len < size ? len : size;
            rtn = write(fpgaDev->intrFds[4], senddata, amt);
            fpga_reg_wr(PC_USER3_DMA_SYS,rtn);
            fpga_reg_wr(PC_USER3_DMA_LEN,amt);
            fpga_reg_wr(CTRL_REG,SEND_USER3_DATA); 
            sent += amt; 
            // Still more data, send to next buffer
            if (sent < len) {
                amt = (len-sent < size ? len-sent : size);
                rtn = write(fpgaDev->intrFds[5], senddata+sent, amt);         
            }            
            if(addr != 0){
                while(1){
                    fpga_wait_interrupt(hostuser3);  
                    if (sent < len) {
                        fpga_reg_wr(PC_USER3_DMA_SYS,rtn);
                        fpga_reg_wr(PC_USER3_DMA_LEN,amt);
                        fpga_reg_wr(CTRL_REG,SEND_USER3_DATA); 
                        sent += amt;
                        tmp_buf = buf;
                        buf = pre_buf;
                        pre_buf = tmp_buf;     
                        if (sent < len){                         
                            amt = (len-sent < size ? len-sent : size);
                            rtn = write(fpgaDev->intrFds[pre_buf], senddata+sent, amt);
                        }
                    }
                    else
                       return sent;
                }
            }
        }
        else if(dest == USERPCIE4){
            buf = 6;
            pre_buf = 7;
            len = sendlen;
            amt = len < size ? len : size;
            rtn = write(fpgaDev->intrFds[6], senddata, amt);
            fpga_reg_wr(PC_USER4_DMA_SYS,rtn);
            fpga_reg_wr(PC_USER4_DMA_LEN,amt);
            fpga_reg_wr(CTRL_REG,SEND_USER4_DATA); 
            sent += amt; 
            // Still more data, send to next buffer
            if (sent < len) {
                amt = (len-sent < size ? len-sent : size);
                rtn = write(fpgaDev->intrFds[7], senddata+sent, amt);         
            }            
            if(addr != 0){
                while(1){
                    fpga_wait_interrupt(hostuser4);  
                    if (sent < len) {
                        fpga_reg_wr(PC_USER4_DMA_SYS,rtn);
                        fpga_reg_wr(PC_USER4_DMA_LEN,amt);
                        fpga_reg_wr(CTRL_REG,SEND_USER4_DATA); 
                        sent += amt;
                        tmp_buf = buf;
                        buf = pre_buf;
                        pre_buf = tmp_buf;     
                        if (sent < len){                         
                            amt = (len-sent < size ? len-sent : size);
                            rtn = write(fpgaDev->intrFds[pre_buf], senddata+sent, amt);
                        }
                    }
                    else
                       return sent;
                }
            }
        }
        else
            printf("Wrong destination\n");
    return 0;
}



/* Receiving data functions. */
int fpga_recv_data(DMA_PNT dest, unsigned char * recvdata, int recvlen, unsigned int addr) {
        unsigned int rtn;
        unsigned int len;
        unsigned int size;
        unsigned int amt;
        unsigned int buf = 10;
        unsigned int pre_buf = 11;
        unsigned int tmp_buf;
        unsigned int ddr_addr;
        int copyd = 0;
        int sent = 0;
        int pre_amt = 0;
        if(dest == DRAM) {
            ddr_addr = addr;
            len = (recvlen+127)&0xFFFFFF80;
            size = BUF_SIZE;
            amt = len < size ? len : size;
            rtn = write(fpgaDev->intrFds[buf], NULL, 0);  //just to get the DMA buffer address
            fpga_reg_wr(DDR_PC_DMA_SYS_REG,rtn);
            fpga_reg_wr(DDR_PC_DMA_FPGA_REG,ddr_addr);
            fpga_reg_wr(DDR_PC_DMA_LEN_REG,amt);
            fpga_reg_wr(CTRL_REG,RECV_DDR_DATA);
            ddr_addr += amt;
            sent += amt;   
            pre_amt = amt;     
            while(1){
               fpga_wait_interrupt(ddrhost);          //Wait for interrupt from first buffer
               if (sent < len) {
                   rtn = write(fpgaDev->intrFds[pre_buf], NULL, 0);  //just to get the DMA buffer address
                   amt = (len-sent < size ? len-sent : size); 
                   fpga_reg_wr(DDR_PC_DMA_SYS_REG,rtn);             //Issue the next buffer
                   fpga_reg_wr(DDR_PC_DMA_FPGA_REG,ddr_addr); 
                   fpga_reg_wr(DDR_PC_DMA_LEN_REG,amt);
                   fpga_reg_wr(CTRL_REG,RECV_DDR_DATA);
                   ddr_addr += amt;
                   sent += amt;            
               }
               rtn = read(fpgaDev->intrFds[buf],recvdata+copyd,pre_amt);
               copyd += pre_amt;
               if (copyd >= len) {
                   return copyd;
               }
               pre_amt = amt;              
               tmp_buf = buf;
               buf = pre_buf;
               pre_buf = tmp_buf;  
            }
        }
        else if(dest == USERPCIE1){
            len = recvlen;
            size = BUF_SIZE;
            amt = len < size ? len : size;
            rtn = write(fpgaDev->intrFds[buf], NULL, 0);
            fpga_reg_wr(USER1_PC_DMA_SYS,rtn);
            fpga_reg_wr(USER1_PC_DMA_LEN,amt);
            fpga_reg_wr(CTRL_REG,RECV_USER1_DATA);
            sent += amt;
            pre_amt = amt; 
            while(1){
               fpga_wait_interrupt(user1host);          //Wait for interrupt from first buffer
               if (sent < len) { 
                   rtn = write(fpgaDev->intrFds[pre_buf], NULL, 0);  //just to get the DMA buffer address
                   amt = (len-sent < size ? len-sent : size); 
                   fpga_reg_wr(USER1_PC_DMA_SYS,rtn);
                   fpga_reg_wr(USER1_PC_DMA_LEN,amt);
                   fpga_reg_wr(CTRL_REG,RECV_USER1_DATA);
                   sent += amt;               
               }
               rtn = read(fpgaDev->intrFds[buf],recvdata+copyd,pre_amt);
               copyd += pre_amt;
               if (copyd >= len) {
                   return copyd;
               }
               pre_amt = amt;              
               tmp_buf = buf;
               buf = pre_buf;
               pre_buf = tmp_buf; 
            }
        }        
        else if(dest == USERPCIE2){
            copyd = 0;
            len = recvlen;
            size = BUF_SIZE;
            amt = len < size ? len : size;
            rtn = write(fpgaDev->intrFds[buf], NULL, 0);
            fpga_reg_wr(USER2_PC_DMA_SYS,rtn);
            fpga_reg_wr(USER2_PC_DMA_LEN,amt);
            fpga_reg_wr(CTRL_REG,RECV_USER2_DATA);
            sent += amt;
            pre_amt = amt; 
            while(1){
                fpga_wait_interrupt(user2host);          //Wait for interrupt from first buffer
                if (sent < len) { 
                    rtn = write(fpgaDev->intrFds[pre_buf], NULL, 0);  //just to get the DMA buffer address
                    amt = (len-sent < size ? len-sent : size); 
                    fpga_reg_wr(USER2_PC_DMA_SYS,rtn);
                    fpga_reg_wr(USER2_PC_DMA_LEN,amt);
                    fpga_reg_wr(CTRL_REG,RECV_USER2_DATA);
                    sent += amt;               
               }
               rtn = read(fpgaDev->intrFds[buf],recvdata+copyd,pre_amt);
               copyd += pre_amt;
               if (copyd >= len) {
                   return copyd;
               }
               pre_amt = amt;              
               tmp_buf = buf;
               buf = pre_buf;
               pre_buf = tmp_buf; 
            } 
        }   
        else if(dest == USERPCIE3){
            len = recvlen;
            size = BUF_SIZE;
            amt = len < size ? len : size;
            rtn = write(fpgaDev->intrFds[buf], NULL, 0);
            fpga_reg_wr(USER3_PC_DMA_SYS,rtn);
            fpga_reg_wr(USER3_PC_DMA_LEN,amt);
            fpga_reg_wr(CTRL_REG,RECV_USER3_DATA);
            sent += amt;
            pre_amt = amt; 
            while(1){
               fpga_wait_interrupt(user3host);          //Wait for interrupt from first buffer
               if (sent < len) { 
                   rtn = write(fpgaDev->intrFds[pre_buf], NULL, 0);  //just to get the DMA buffer address
                   amt = (len-sent < size ? len-sent : size); 
                   fpga_reg_wr(USER3_PC_DMA_SYS,rtn);
                   fpga_reg_wr(USER3_PC_DMA_LEN,amt);
                   fpga_reg_wr(CTRL_REG,RECV_USER3_DATA);
                   sent += amt;               
               }
               rtn = read(fpgaDev->intrFds[buf],recvdata+copyd,pre_amt);
               copyd += pre_amt;
               if (copyd >= len) {
                   return copyd;
               }
               pre_amt = amt;              
               tmp_buf = buf;
               buf = pre_buf;
               pre_buf = tmp_buf; 
            } 
        }
        else if(dest == USERPCIE4){
            len = recvlen;
            size = BUF_SIZE;
            amt = len < size ? len : size;
            rtn = write(fpgaDev->intrFds[buf], NULL, 0);
            fpga_reg_wr(USER4_PC_DMA_SYS,rtn);
            fpga_reg_wr(USER4_PC_DMA_LEN,amt);
            fpga_reg_wr(CTRL_REG,RECV_USER4_DATA);
            sent += amt;
            pre_amt = amt; 
            while(1){
               fpga_wait_interrupt(user4host);          //Wait for interrupt from first buffer
               if (sent < len) { 
                   rtn = write(fpgaDev->intrFds[pre_buf], NULL, 0);  //just to get the DMA buffer address
                   amt = (len-sent < size ? len-sent : size); 
                   fpga_reg_wr(USER4_PC_DMA_SYS,rtn);
                   fpga_reg_wr(USER4_PC_DMA_LEN,amt);
                   fpga_reg_wr(CTRL_REG,RECV_USER4_DATA);
                   sent += amt;               
               }
               rtn = read(fpgaDev->intrFds[buf],recvdata+copyd,pre_amt);
               copyd += pre_amt;
               if (copyd >= len) {
                   return copyd;
               }
               pre_amt = amt;              
               tmp_buf = buf;
               buf = pre_buf;
               pre_buf = tmp_buf; 
            } 
        }
        else
            printf("Wrong destination\n");
    return 0;                
}


int fpga_send_ddr_user_data(DMA_PNT dst,  unsigned int addr, unsigned char * senddata, unsigned int sendlen) {
        unsigned int rtn;
        unsigned int len;
        unsigned int ddr_addr;
        unsigned int size = BUF_SIZE;
        unsigned int amt;
        unsigned int buf = 0;
        unsigned int pre_buf = 1;
        unsigned int tmp_buf;
        unsigned int ddr_tx_amt=0;
        unsigned int ddr_prev_addr;
        int sent = 0;
        ddr_addr = addr;
        len = (sendlen+63)&0xFFFFFFC0;                         //Align length to 64 bytes
        // Send initial transfer request.
        amt = len < size ? len : size;
        rtn = write(fpgaDev->intrFds[0], senddata, amt);
        fpga_reg_wr(PC_DDR_DMA_SYS_REG,rtn);
        fpga_reg_wr(PC_DDR_DMA_FPGA_REG,ddr_addr); 
        fpga_reg_wr(PC_DDR_DMA_LEN_REG,amt);
        fpga_reg_wr(CTRL_REG,SEND_DDR_DATA);
        ddr_prev_addr = ddr_addr;
        ddr_tx_amt = amt;
        ddr_addr += amt;
        sent += amt;
        // Still more data, send to next buffer
        if (sent < len) {
            amt = (len-sent < size ? len-sent : size);
            rtn = write(fpgaDev->intrFds[1], senddata+sent, amt);         
        }
        while(1){
           fpga_wait_interrupt(hostddr);          //Wait for interrupt from first buffer
	   ddr_user_send_data(dst,ddr_tx_amt,ddr_prev_addr,0);
           if (sent < len) {
               fpga_reg_wr(PC_DDR_DMA_SYS_REG,rtn);
               fpga_reg_wr(PC_DDR_DMA_FPGA_REG,ddr_addr); 
               fpga_reg_wr(PC_DDR_DMA_LEN_REG,amt);
               fpga_reg_wr(CTRL_REG,SEND_DDR_DATA); 
               //ddr_user_send_data(dst,ddr_tx_amt,ddr_prev_addr,1); //Enable the user stream logic 
               ddr_prev_addr = ddr_addr;
               ddr_tx_amt = amt;
               ddr_addr += amt;
               sent += amt;
               tmp_buf = buf;
               buf = pre_buf;
               pre_buf = tmp_buf;                                 
               if (sent < len) {
                   amt = (len-sent < size ? len-sent : size);
                   rtn = write(fpgaDev->intrFds[pre_buf], senddata+sent, amt);
               }
               if(dst == USERDRAM1)
                   fpga_wait_interrupt(ddruser1);
               else if(dst == USERDRAM2)
                   fpga_wait_interrupt(ddruser2);
               else if(dst == USERDRAM3)
                   fpga_wait_interrupt(ddruser3);
               else if(dst == USERDRAM4)
                   fpga_wait_interrupt(ddruser4);
	       else
		   printf("Some thing wrong with destination %d\n",dst);
           }
           else{
               ddr_user_send_data(dst,ddr_tx_amt,ddr_prev_addr,1);
               return sent;
           }
        }
    return sent;
}



/*Function to send data from DRAM to user stream interface*/
int ddr_user_send_data(DMA_PNT dest,int sendlen,unsigned int addr,unsigned int block){
    int rtn;
    if(dest == USERDRAM1){
        rtn = fpga_reg_wr(DDR_USER1_STR_ADDR,addr);
        rtn = fpga_reg_wr(DDR_USER1_STR_LEN,sendlen);
        rtn = fpga_reg_wr(CTRL_REG,SEND_DDR_USER1_DATA);
        if(block)
            rtn = fpga_wait_interrupt(ddruser1);
    }
    if(dest == USERDRAM2){
        rtn = fpga_reg_wr(DDR_USER2_STR_ADDR,addr);
        rtn = fpga_reg_wr(DDR_USER2_STR_LEN,sendlen);
        rtn = fpga_reg_wr(CTRL_REG,SEND_DDR_USER2_DATA);
        if(block)
            rtn = fpga_wait_interrupt(ddruser2);
    }
    if(dest == USERDRAM3){
        rtn = fpga_reg_wr(DDR_USER3_STR_ADDR,addr);
        rtn = fpga_reg_wr(DDR_USER3_STR_LEN,sendlen);
        rtn = fpga_reg_wr(CTRL_REG,SEND_DDR_USER3_DATA);
        if(block)
            rtn = fpga_wait_interrupt(ddruser3);
    }
    if(dest == USERDRAM4){
        rtn = fpga_reg_wr(DDR_USER4_STR_ADDR,addr);
        rtn = fpga_reg_wr(DDR_USER4_STR_LEN,sendlen);
        rtn = fpga_reg_wr(CTRL_REG,SEND_DDR_USER4_DATA);
        if(block)
            rtn = fpga_wait_interrupt(ddruser4);
    }
    if(rtn < 0)
        return rtn;
    else
        return sendlen;
}

/*Function to send data from user stream interface to DRAM*/
int user_ddr_send_data(DMA_PNT src, int sendlen, unsigned int addr,unsigned int block){
    int rtn;
    if(src == USERDRAM1){
        rtn = fpga_reg_wr(USER1_DDR_STR_ADDR,addr);
        rtn = fpga_reg_wr(USER1_DDR_STR_LEN,sendlen);
        rtn = fpga_reg_wr(CTRL_REG,SEND_USER1_DDR_DATA);
        if(block)
            rtn = fpga_wait_interrupt(user1ddr);
    }
    if(src == USERDRAM2){
        rtn = fpga_reg_wr(USER2_DDR_STR_ADDR,addr);
        rtn = fpga_reg_wr(USER2_DDR_STR_LEN,sendlen);
        rtn = fpga_reg_wr(CTRL_REG,SEND_USER2_DDR_DATA);
        if(block)
            rtn = fpga_wait_interrupt(user2ddr);
    }
    if(src == USERDRAM3){
        rtn = fpga_reg_wr(USER3_DDR_STR_ADDR,addr);
        rtn = fpga_reg_wr(USER3_DDR_STR_LEN,sendlen);
        rtn = fpga_reg_wr(CTRL_REG,SEND_USER3_DDR_DATA);
        if(block)
            rtn = fpga_wait_interrupt(user3ddr);
    }
    if(src == USERDRAM4){
        rtn = fpga_reg_wr(USER4_DDR_STR_ADDR,addr);
        rtn = fpga_reg_wr(USER4_DDR_STR_LEN,sendlen);
        rtn = fpga_reg_wr(CTRL_REG,SEND_USER4_DDR_DATA);
        if(block)
            rtn = fpga_wait_interrupt(user4ddr);
    }
    if(rtn < 0)
        return rtn;
    else
        return sendlen;
}

/*Function to send data from DRAM to ethernet*/
int enet_send_data(int sendlen, unsigned int addr, unsigned int block) {
    int rtn;
    rtn = fpga_reg_wr(ETH_DDR_SRC_ADDR,addr);
    rtn = fpga_reg_wr(ETH_SEND_DATA_SIZE,sendlen);
    rtn = fpga_reg_wr(CTRL_REG,ENET);
    if(block)
        rtn = fpga_wait_interrupt(enet);
    if(rtn < 0)
        return rtn;
    else
        return sendlen;
}

/*Function to receive data from ethernet and store in DRAM*/
int enet_recv_data(int recvlen, unsigned int addr, unsigned int block) {
    int rtn;
    rtn = fpga_reg_wr(ETH_DDR_DST_ADDR,addr);
    rtn = fpga_reg_wr(ETH_SEND_DATA_SIZE,recvlen);
    rtn = fpga_reg_wr(CTRL_REG,ENET);
    if(rtn < 0)
        return rtn;
    else
        return recvlen;
}


/*The top API for data transfer
 Calls appropriate lower level functions to get the data transfer done
 Inputs : DMA source type
          DMA destination type
          (uchar *) Data buffer
          (uint)    Transfer length
          (uint)    Address in case of transfer to/from DRAM
          (uint)    To enable/disable blocking transfer
 Before scheduling the transfer, first the FPGA status is checked to make sure that it is ready to accept the transfer
*/
int fpga_transfer_data(DMA_PNT src, DMA_PNT dst, unsigned char * tranfer_buff, unsigned int len, unsigned int addr, unsigned int block)
{
    int rtn;
    rtn = fpga_reg_rd(CTRL_REG); //Read the control register to check the current FPGA state
    switch(src){
        case HOST:
            switch(dst){
                case DRAM:
                    if(rtn & SEND_DDR_DATA){
                        printf("Cannot send data to DRAM, already busy\n");
                        return -1;
                    }
                    else {
                        fpga_send_data(dst, tranfer_buff, len, addr);
                    }
                    break;      
                case USERPCIE1:
                    if(rtn & SEND_USER1_DATA){
                        printf("Cannot send data to User PCIe 1 interface, already busy\n");
                        return -1;
                    }
                    else {
                        fpga_send_data(dst, tranfer_buff, len, block);
                    }
                    break;        
                case USERPCIE2:
                    if(rtn & SEND_USER2_DATA){
                        printf("Cannot send data to User PCIe 2 interface, already busy\n");
                        return -1;
                    }
                    else {
                    fpga_send_data(dst, tranfer_buff, len, block);
                    }
                    break;       
                case USERPCIE3:
                    if(rtn & SEND_USER3_DATA){
                        printf("Cannot send data to User PCIe 3 interface, already busy\n");
                        return -1;
                    }
                    else {
                    fpga_send_data(dst, tranfer_buff, len, block);
                    }
                    break;        
                case USERPCIE4:
                    if(rtn & SEND_USER4_DATA){
                        printf("Cannot send data to User PCIe 4 interface, already busy\n");
                        return -1;
                    }
                    else {
                    fpga_send_data(dst, tranfer_buff, len, block);
                    }
                    break;        
                case USERDRAM1:
                    if(rtn & SEND_DDR_DATA){
                        printf("Cannot send data to DRAM, already busy\n");
                        return -1;
                    }
                    else {
                        fpga_send_ddr_user_data(dst, addr, tranfer_buff, len);
                    }
                    break;        
                case USERDRAM2:
                    if(rtn & SEND_DDR_DATA){
                        printf("Cannot send data to DRAM, already busy\n");
                        return -1;
                    }
                    else {
                        fpga_send_ddr_user_data(dst, addr, tranfer_buff, len);
                    }
                    break;        
                case USERDRAM3:
                    if(rtn & SEND_DDR_DATA){
                        printf("Cannot send data to DRAM, already busy\n");
                        return -1;
                    }
                    else {
                        fpga_send_ddr_user_data(dst, addr, tranfer_buff, len);
                    }
                    break;        
                case USERDRAM4:
                    if(rtn & SEND_DDR_DATA){
                        printf("Cannot send data to DRAM, already busy\n");
                        return -1;
                    }
                    else {
                        fpga_send_ddr_user_data(dst, addr, tranfer_buff, len);
                    }
                    break;
                default:
                    printf("unsupported transfer destination \n");
                    return -1;
                    break;
            }
        break;

        case DRAM:
            switch(dst){   
                case HOST:
                    if(rtn & RECV_DDR_DATA){
                        printf("Cannot receive data from DRAM, already busy\n");
                        return -1;
                    }
                    else {
                        fpga_recv_data(src, tranfer_buff, len, addr);
                    }
                    break;
                case USERDRAM1:
                    if(rtn & SEND_DDR_USER1_DATA){
                        printf("Cannot send data to User DRAM 1, already busy\n");
                        return -1;
                    }
                    else {
                        ddr_user_send_data(dst, len, addr , block);
                    }
                    break;        
                case USERDRAM2:
                    if(rtn & SEND_DDR_USER2_DATA){
                        printf("Cannot send data to User DRAM 2, already busy\n");
                        return -1;
                    }
                    else {
                        ddr_user_send_data(dst, len, addr , block);
                    }
                    break;        
                case USERDRAM3:
                    if(rtn & SEND_DDR_USER3_DATA){
                        printf("Cannot send data to User DRAM 3, already busy\n");
                        return -1;
                    }
                    else {
                        ddr_user_send_data(dst, len, addr , block);
                    }
                    break;        
                case USERDRAM4:
                    if(rtn & SEND_DDR_USER4_DATA){
                        printf("Cannot send data to User DRAM 4, already busy\n");
                        return -1;
                    }
                    else {
                        ddr_user_send_data(dst, len, addr , block);
                    }
                    break;
                case ETHERNET:
                    enet_send_data(len, addr, block);
                    break;
                default:
                    printf("unsupported transfer destination \n");
                    return -1;
                    break;
            }
        break;

        case USERPCIE1:
            switch(dst){
                case HOST:
                    if(rtn & RECV_USER1_DATA){
                        printf("Cannot receive data from User PCIe 1, already busy\n");
                        return -1;
                    }
                    else {
                        fpga_recv_data(src, tranfer_buff, len, addr);
                    }
                    break;     
                default:
                    printf("unsupported transfer destination \n");
                    return -1;
                    break;
            }
        break;

        case USERPCIE2:
            switch(dst){
                case HOST:
                    if(rtn & RECV_USER2_DATA){
                        printf("Cannot receive data from User PCIe 2, already busy\n");
                        return -1;
                    }
                    fpga_recv_data(src, tranfer_buff, len, addr);
                    break;     
                default:
                    printf("unsupported transfer destination \n");
                    return -1;
                    break;
            }
        break;

        case USERPCIE3:
            switch(dst){
                case HOST:
                    if(rtn & RECV_USER3_DATA){
                        printf("Cannot receive data from User PCIe 3, already busy\n");
                        return -1;
                    }
                    else {
                        fpga_recv_data(src, tranfer_buff, len, addr);
                    }
                    break;     
                default:
                    printf("unsupported transfer destination \n");
                    return -1;
                    break;
            }
        break;

        case USERPCIE4:
            switch(dst){
                case HOST:
                    if(rtn & RECV_USER4_DATA){
                        printf("Cannot receive data from User PCIe 4, already busy\n");
                        return -1;
                    }
                    else {
                        fpga_recv_data(src, tranfer_buff, len, addr);
                    }
                    break;    
                default:
                    printf("unsupported transfer destination \n");
                    return -1;
                    break;
            }
        break;

        case USERDRAM1:
            switch(dst){
                case DRAM:
                    if(rtn & SEND_USER1_DDR_DATA){
                        printf("Cannot send data from User DRAM 1, already busy\n");
                        return -1;
                    }
                    else {
                        user_ddr_send_data(src, len, addr,block);
                    }
                    break;     
                default:
                    printf("unsupported transfer destination \n");
                    return -1;
                    break;
            }
        break;

        case USERDRAM2:
            switch(dst){
                case DRAM:
                    if(rtn & SEND_USER2_DDR_DATA){
                        printf("Cannot send data from User DRAM 2, already busy\n");
                        return -1;
                    }
                    else{
                        user_ddr_send_data(src, len, addr,block);
                    }
                    break;    
                default:
                    printf("unsupported transfer destination \n");
                    return -1;
                    break;
            }
        break;

        case USERDRAM3:
            switch(dst){
                case DRAM:
                    if(rtn & SEND_USER3_DDR_DATA){
                        printf("Cannot send data from User DRAM 3, already busy\n");
                        return -1;
                    }
                    else {
                        user_ddr_send_data(src, len, addr,block);
                    }
                    break;    
                default:
                    printf("unsupported transfer destination \n");
                    return -1;
                    break;
            }
        break;

        case USERDRAM4:
            switch(dst){
                case DRAM:
                    if(rtn & SEND_USER4_DDR_DATA){
                        printf("Cannot send data from User DRAM 4, already busy\n");
                        return -1;
                    }
                    else {
                        user_ddr_send_data(src, len, addr, block);
                    }
                    break;    
                default:
                    printf("unsupported transfer destination \n");
                    return -1;
                    break;
            }
        break;

        case ETHERNET:
            switch(dst){
                case DRAM:
                    enet_recv_data(len, addr, block); 
                    break;     
                default:
                    printf("unsupported transfer destination \n");
                    return -1;
                    break;
            }
        break;
    }
}

/*Function to reconfigure the FPGA from external flash
  Input : Starting address of the bitstream in the flash
*/
int fpga_reboot(unsigned int boot_addr){
    int rtn;
    rtn = fpga_reg_wr(RECONFIG_ADDR,boot_addr);
    rtn = fpga_reg_wr(CTRL_REG,REBOOT);
    return 0;
}

/*Function to sync interrupt on a specified channel. The channels can be hostddr, ddrhost, hostuser1 to 4, user1 to 4 to host, ddruser1 to 4, user1 to 4 to ddr, userhost and enet*/
int fpga_wait_interrupt(DMA_TYPE dma_type) {
    int rtn;
    rtn= read(fpgaDev->intrFds[0], NULL,dma_type);      
} 



/* Low level data transferring and buffer management functions. */
int fpga_reg_wr(unsigned int regaddr, unsigned int regdata) {
	fpga_write_word(fpgaDev->cfgMem + regaddr, regdata);
	return 0;
}

/* Low level data transferring and buffer management functions. */
int fpga_reg_rd(unsigned int regaddr) {
	return fpga_read_word(fpgaDev->cfgMem + regaddr);
}

/*Function for indirect write to a DRAM location*/
int fpga_ddr_pio_wr(unsigned int addr, unsigned int data){
    int rtn;
    rtn = fpga_reg_wr(PIOA_REG,addr);
    return fpga_reg_wr(PIOD_REG,data);
}

/*Function for indirect read from a DRAM location*/
int fpga_ddr_pio_rd(unsigned int addr){
    int rtn;
    rtn = fpga_reg_wr(PIOA_REG,addr);
    return fpga_reg_rd(PIOD_REG);
}

/*Function to issue a soft reset to the user logic
  Input : Reset active polarity
  The function initially deasserts the reset, then asserts and again deasserts*/
void user_soft_reset(unsigned int polarity) {
   int rtn;
   rtn = fpga_reg_rd(UCTR_REG); 
   if(polarity == 0) {
      fpga_reg_wr(UCTR_REG,rtn & 0xFFFFFFFF);
      fpga_reg_wr(UCTR_REG,rtn & 0xFFFFFFFE);
      fpga_reg_wr(UCTR_REG,rtn & 0xFFFFFFFF);
  }
  else {
      fpga_reg_wr(UCTR_REG,rtn & 0xFFFFFFFE);
      fpga_reg_wr(UCTR_REG,rtn & 0xFFFFFFFF);
      fpga_reg_wr(UCTR_REG,rtn & 0xFFFFFFFE);
  }
}


/*Function to configure the clock frequency to the user logic
  Input : Required frequency. Currently supports 250, 200, 150 and 100
*/
int user_set_clk(unsigned int freq){
   int rtn;
   rtn = fpga_reg_rd(UCTR_REG);            //Read the current control register value since both soft reset and clock config are in the same register
   switch(freq){
       case 250:
           fpga_reg_wr(UCTR_REG, rtn & 0xFFFFFFF9);
       break;
       case 200:
           fpga_reg_wr(UCTR_REG, rtn & 0xFFFFFFFB);
       break;
       case 150:
           fpga_reg_wr(UCTR_REG, rtn & 0xFFFFFFFD);
       break;
       case 100:
           fpga_reg_wr(UCTR_REG, rtn & 0xFFFFFFFF);
       break;
       default:
           printf("unsupported frequency\n");
           return -1;
       break;
   }
   return 0;
}


void init_allocator(long long unsigned int size, bool debug) {


	// initialize empty memory allocation table
	memalloc_root = malloc(sizeof(memalloc_node_t));
	memalloc_root->start_address=0;
	memalloc_root->size=0;
	memalloc_root->prev=NULL;
	memalloc_root->next=NULL;

	// set maximum size limit
	MAX_SIZE = size;
	FREE_SPACE = size;

	// set debug mode
	DEBUG_MEMALLOC = debug;
}

long long unsigned int fpga_malloc(long long unsigned int size) {

	if(size==0) {
		printf("Idiotically attempting to allocate a 0-sized FPGA memory object. Please go back to school.\n");
		fflush(stdout);
		return;
	}
	if(size>FREE_SPACE) {
		//printf("Morons are running the world asking to allocate more space that is available. Please go back to kindergarten and resume your incomplete education.\n");
		printf("Out of FPGA Memory Error\n"); // todo send this to stderr
		exit(1); // what should be the exit code?
		fflush(stdout);
		return;
	}

	// Look at current memory allocation table
	memalloc_node_t* current_node = memalloc_root;
	memalloc_node_t* memalloc_newnode = malloc(sizeof(memalloc_node_t));
	
	bool success=false;
	while(current_node!=NULL) {
		if(DEBUG_MEMALLOC)
			printf("[Malloc] Address=%x\n",current_node);

		long long unsigned int current_start_address = current_node->start_address;
		long long unsigned int current_size = current_node->size;
		long long unsigned int current_valid_start_address = current_start_address + current_size;

		// 64-byte boundary alignment code
		if(current_valid_start_address%64!=0) {
			if(DEBUG_MEMALLOC)
				printf("[Malloc] Adjusting for 64-byte boundary addr=%llu, size=%llu\n",current_valid_start_address,size);
			current_valid_start_address += (64 - current_valid_start_address%64);
			if(DEBUG_MEMALLOC)
				printf("[Malloc] Adjusted addr=%llu\n",current_valid_start_address);
		}


		if(current_node->next==NULL) {
			if(DEBUG_MEMALLOC)
				printf("[Malloc] Created (end) node at addr=%llu, size=%llu\n",current_valid_start_address,size);

			// create new node
			memalloc_newnode->start_address = current_valid_start_address;
			memalloc_newnode->size = size;
			if(current_valid_start_address+size>=MAX_SIZE) {
				printf("Out of FPGA Memory Error\n"); // todo send this to stderr
				exit(1); // what should be the exit code?
				fflush(stdout);
				return;
			}

			// insert new node
			current_node->next = memalloc_newnode;
			memalloc_newnode->prev = current_node;
			memalloc_newnode->next = NULL;
			success=true;
			break;
		} else {
			long long unsigned int next_start_address = current_node->next->start_address;
			if(current_valid_start_address+size<=next_start_address) {
				if(DEBUG_MEMALLOC)
					printf("[Malloc] Created (internal) node at addr=%llu, size=%llu\n",current_valid_start_address,size);
				// we have a fragment that we can fill..
				memalloc_newnode->start_address = current_valid_start_address;
				memalloc_newnode->size = size;
				// insert new node
				memalloc_newnode->next = current_node->next;
				current_node->next->prev = memalloc_newnode;
				current_node->next = memalloc_newnode;
				memalloc_newnode->prev = current_node;
				success=true;
				break;
			}
		}
		
		
		current_node = current_node->next; 
	}
	if(!success) {
		printf("Out of FPGA Memory Error due to excessive fragmentation\n"); // todo send this to stderr
		exit(1); // exit code?
	}
	// Find the fragment in memory that satisfies request
	// Return that pointer and mark region as allocated
	FREE_SPACE -= size;
	return memalloc_newnode->start_address;
}

int fpga_free(long long unsigned int start_address) {
	memalloc_node_t* current_node = memalloc_root;
	
	while(current_node!=NULL) {
		if(DEBUG_MEMALLOC)
			printf("[Free] Address=%x\n",current_node);
			
		if(current_node->start_address==start_address && current_node->size!=0) {
			// Delete entry in the memory allocation table
			if(current_node->next==NULL) {
				current_node->prev->next=NULL;
			} else {
				current_node->prev->next=current_node->next;
				current_node->next->prev=current_node->prev;
			}
			free(current_node);
			if(DEBUG_MEMALLOC)
				printf("[Free] Freed object at address=%llu\n",start_address);

			return 0;
		}
		current_node = current_node->next;
	}

	printf("I tried hard, but couldn't locate an FPGA memory object with that pointer address. Yeah, go back to school.\n");
	return 1;
}

int load_bitstream (char* filename, BIT_DEST dest)
{
    char buff[100] = "\0";
    unsigned int saved_data[DDR_CACHE_SIZE/4];  //Buffer to hold the received data

    strcpy(buff,"setmode -bscan \n");
    strcat(buff,"setCable -p auto \n");  
    strcat(buff,"identify \n\0");  
    int timeout = 10 * 1000; // 10 seconds timeout    
    int ret_val;
    // Initialize FPGA
   
    // Create the Command File with the bit file as arguement
    FILE* impact_cmd = NULL;
    if (dest == FPGA_V6) // Program FPGA 
        {   
            impact_cmd = fopen("download.cmd","w+");
            fwrite(&buff,1,strlen(buff),impact_cmd);
            strcpy(buff,"\0");  
            strcpy(buff,"assignfile -p 2 -file ");
            strcat(buff,filename);
            strcat(buff, "\n");
            strcat(buff,"program -p 2 \nquit \0");
            fwrite(&buff,1,strlen(buff),impact_cmd);
            fclose(impact_cmd);
        }
        else if (dest == FPGA_V7){
            impact_cmd = fopen("download.cmd","w+");
            fwrite(&buff,1,strlen(buff),impact_cmd);
            strcpy(buff,"\0");  
            strcpy(buff,"assignfile -p 1 -file ");
            strcat(buff,filename);
            strcat(buff, "\n");
            strcat(buff,"program -p 1 \nquit \0");
            fwrite(&buff,1,strlen(buff),impact_cmd);
            fclose(impact_cmd);
        }
        else if (dest == FLASH_V6){
            impact_cmd = fopen("download.cmd","w+");
            fwrite(&buff,1,strlen(buff),impact_cmd);
            strcpy(buff,"\0");  
            strcpy(buff,"attachflash -position 2 -bpi \"XCF128X\"");
            strcat(buff, "\n\0");
            fwrite(&buff,1,strlen(buff),impact_cmd);
            strcpy(buff,"\0");  
            strcpy(buff,"assignfiletoattachedflash -position 2 -file ");
            strcat(buff,filename);
            strcat(buff, "\n\0");
            fwrite(&buff,1,strlen(buff),impact_cmd);
            strcpy(buff,"\0");  
            strcpy(buff,"Erase -p 2 \n");
            strcat(buff,"Program -p 2 -dataWidth 16 -rs1 NONE -rs0 NONE -bpionly -e -v -loadfpga \n\0");
            fwrite(&buff,1,strlen(buff),impact_cmd);
            strcpy(buff,"\0");  
            strcpy(buff,"quit \0");
            fwrite(&buff,1,strlen(buff),impact_cmd);
            flose(impact_cmd);
        }
        else if (dest == FLASH_V7){
            impact_cmd = fopen("download.cmd","w+");
            fwrite(&buff,1,strlen(buff),impact_cmd);
            strcpy(buff,"\0");  
            strcpy(buff,"attachflash -position 1 -bpi \"28F00AG18F\""); // PART NUMBER TO BE VERIFIED
            strcat(buff, "\n\0");
            fwrite(&buff,1,strlen(buff),impact_cmd);
            strcpy(buff,"\0");  
            strcpy(buff,"assignfiletoattachedflash -position 1 -file ");
            strcat(buff,filename);
            strcat(buff, "\n\0");
            fwrite(&buff,1,strlen(buff),impact_cmd);
            strcpy(buff,"\0");  
            strcpy(buff,"Erase -p 2 \n");
            strcat(buff,"Program -p 2 -dataWidth 16 -rs1 25 -rs0 24 -bpionly -e -v -loadfpga \n\0");
            fwrite(&buff,1,strlen(buff),impact_cmd);
            strcpy(buff,"\0");  
            strcpy(buff,"quit \0");
            fwrite(&buff,1,strlen(buff),impact_cmd);
            flose(impact_cmd);
        }
        else {printf("\n Invalid Target Specified. Please enter FPGA_V6, FPGA_V7, FLASH_V6 or FLASH_V7 \n"); return 0;}

            // Save first 256 bytes of DDR
            ret_val = fpga_recv_data(DRAM,(unsigned char *)saved_data, DDR_CACHE_SIZE,0);
            if (ret_val < 0){
                printf("FPGA Receive Error ..!!");
                return 0;
            }
            
            // Call Impact
             ret_val = system("impact -batch download.cmd");
                if (ret_val == -1){
                    printf("System Call aborted ..!! Error Code %d",WEXITSTATUS(ret_val));
                    return 0;
                }
            
            // Restore PCI config by calng the restore script
            ret_val = system("./load_config.sh");  
                if (ret_val == -1){
                    printf("System Call aborted ..!! Error Code %d",WEXITSTATUS(ret_val));
                    return 0;
                }

            // Restore DDR Contents
            ret_val = fpga_send_data(DRAM, (unsigned char *) saved_data,DDR_CACHE_SIZE,0);
            if (ret_val < 0){
                printf("FPGA Send Error ..!!");
                return 0;
            }

      
  return 1; // If everything worked, return 1
}
