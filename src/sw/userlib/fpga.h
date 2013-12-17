/*
 * Filename: fpga_comm.h
 * Version: 0.9
 * Description: Linux PCIe communications API for RIFFA. Uses RIFFA kernel
 *  driver defined in "fpga_driver.h".
 * History: @mattj: Initial pre-release. Version 0.9.
 */

#ifndef FPGA_COMM_H
#define FPGA_COMM_H

#include <fpga_driver.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif


/* Paths in proc and dev filesystems */
#define FPGA_INTR_PATH "/proc/" DEVICE_NAME
#define FPGA_DEV_PATH "/dev/" DEVICE_NAME

#define impact "impact -batch "
#define DDR_CACHE_SIZE 256  //First 256 bytes of Data to be restored

struct thread_args;
typedef struct thread_args thread_args;
struct fpga_dev;
struct sys_stat;
typedef struct fpga_dev fpga_dev;

typedef enum dma_point {HOST,DRAM,USERPCIE1,USERPCIE2,USERPCIE3,USERPCIE4,USERDRAM1,USERDRAM2,USERDRAM3,USERDRAM4,ETHERNET} DMA_PNT;
typedef enum bit_dest {FPGA_V6,FLASH_V6,FPGA_V7,FLASH_V7} BIT_DEST;

struct sys_stat
{
    float temp;
    float v_int;
    float v_aux;
    float v_board;
    float i_int;
    float i_board;
    float p_int;
    float p_board;
};

typedef struct sys_stat sys_stat;

//memory allocator stuff
typedef struct memalloc_node {
	long long unsigned int start_address;
	long long unsigned int size;
	struct memalloc_node* prev;
	struct memalloc_node* next;
} memalloc_node_t;

//shared memory manager state
memalloc_node_t* memalloc_root;
int MAX_SIZE;
int FREE_SPACE;
bool DEBUG_MEMALLOC;

/**
 * Initializes the FPGA memory/resources and updates the pointers in the 
 * fpga_dev struct. Returns 0 on success.
 * On error, returns:
 * -1 if could not open the virtual device file (check errno for details).
 * -ENOMEM if could not map the internal buffer memory to user space.
 */
int fpga_init();

/**
 * Cleans up memory/resources for the FPGA virtual files.
 */
void fpga_close();


/**
 * Writes data to the FPGA on channel, channel. All sendlen bytes from the 
 * senddata pointer will be written (possibly over multiple transfers). After 
 * each transfer, the IP core connected to the channel will receive a doorbell 
 * with the transfer length (in bytes). If start == 1, then after the final 
 * transfer, the IP core will receive a zero length doorbell to signal start. 
 * Returns 0 on success.
 * The endianness of sent data is not changed.
 * On error, returns:
 * -EACCES if the channel is not open.
 * -ETIMEDOUT if timeout is non-zero and expires before all data is received.
 * -EREMOTEIO if the transfer sequence takes too long, data is lost/dropped,
 * or some other error is encountered during transfer.
 * -ERESTARTSYS if a signal interrupts the thread.
 * -ENOMEM if the driver runs out of buffers for data transfers.
 * -EFAULT if internal queues are exhausted or on bad address access.
 */
int fpga_send_data(DMA_PNT dest, unsigned char * senddata, int sendlen, unsigned int addr);

/**
 * Reads data from the FPGA on channel, channel, to the recvdata pointer. Up to 
 * recvlen bytes will be copied to the recvdata pointer (possibly over multiple 
 * transfers). Therefore, recvdata must accomodate at least recvlen bytes. The 
 * number of bytes actually received on the channel are returned. The number of 
 * bytes written to the recvdata pointer will be the minimum of return value and
 * recvlen.
 * The endianness of received data is not changed.
 * On error, returns:
 * -EACCES if the channel is not open.
 * -ETIMEDOUT if timeout is non-zero and expires before all data is received.
 * -EREMOTEIO if the transfer sequence takes too long, data is lost/dropped,
 * or some other error is encountered during transfer.
 * -ERESTARTSYS if a signal interrupts the thread.
 * -ENOMEM if the driver runs out of buffers for data transfers.
 * -EFAULT if internal queues are exhausted or on bad address access.
 */
int fpga_recv_data(DMA_PNT dest, unsigned char * recvdata, int recvlen, unsigned int addr);

/**
 * Waits for an interrupt to be recieved on the channel. Equivalent to waiting 
 * for a zero length receive data interrupt. Returns 0 on success.
 * On error, returns:
 * -EACCES if the channel is not open.
 * -ETIMEDOUT if timeout is non-zero and expires before all data is received.
 * -EREMOTEIO if the transfer sequence takes too long, data is lost/dropped,
 * or some other error is encountered during transfer.
 * -ERESTARTSYS if a signal interrupts the thread.
 * -ENOMEM if the driver runs out of buffers for data transfers.
 * -EFAULT if internal queues are exhausted or on bad address access.
 */
int fpga_wait_interrupt(DMA_TYPE);

int fpga_transfer_data(DMA_PNT src, DMA_PNT dst, unsigned char * tranfer_buff, unsigned int len, unsigned int addr, unsigned int block);

int fpga_send_ddr_user_data(DMA_PNT dst, unsigned int addr, unsigned char * tranfer_buff, unsigned int len);

int ddr_user_send_data(DMA_PNT dest,int sendlen,unsigned int addr,unsigned int block);

int user_ddr_send_data(DMA_PNT src,int sendlen, unsigned int addr,unsigned int block);

int fpga_reboot(unsigned int boot_addr);

int enet_send_data(int sendlen, unsigned int addr,unsigned int block);

int enet_recv_data(int recvlen, unsigned int addr,unsigned int block);

int fpga_reg_wr(unsigned int regaddr, unsigned int regdata);

int fpga_reg_rd(unsigned int regaddr);

int fpga_ddr_pio_wr(unsigned int addr, unsigned int data);

int fpga_ddr_pio_rd(unsigned int addr);

void fpga_channel_close(int channel);

sys_stat fpga_read_sys_param();

void user_soft_reset(unsigned int polarity);

int user_set_clk(unsigned int freq);

//memory allocator functions
void init_allocator(long long unsigned int size, bool debug);

long long unsigned int fpga_malloc(long long unsigned int size);

int fpga_free(long long unsigned int start_address);

// Load Bitstream functions
int load_bitstream (char* filename, BIT_DEST dest);

#ifdef __cplusplus
}
#endif

#endif
