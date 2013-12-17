/*
 * Filename: socket_send.c
 * Version: 1.0
 * Description: Linux socket function for transmitting RAW Ethernet Frames
 * Author : Shreejith S
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <linux/if.h>
#include <linux/if_ether.h>
#include <linux/if_packet.h>
#include <sys/ioctl.h>
#include <netinet/ether.h>
#include <arpa/inet.h>
#include "enet.h"
#define frame_size 1024

union ethframe
{
  struct
  {
    struct ethhdr    header;
    unsigned char    data[frame_size];
  } field;
  unsigned char    buffer[frame_size+14];
};

int socket_send(int num_rx_pack) {
  char *iface = "eth0";
  unsigned char dest[ETH_ALEN]
           = { 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF };
  unsigned short proto = 0x0400; // Length field
  //unsigned char *data = "hello world";
  unsigned char data [1024];

  int i,num;
  // Initialise Data with Incremental Pattern
  for (i = 0; i<1024; i++) {
    data[i] = (uint8_t)i; }
  unsigned short data_len = 1024; 
 // Open a RAW Socket
  int s;
  if ((s = socket(AF_PACKET, SOCK_RAW, IPPROTO_RAW)) < 0) {
    printf("Error: could not open socket\n");
    return -1;
  }
 
 // Find the Interface with Interface Name iface (which is eth0)
  struct ifreq buffer;
  int ifindex;
  memset(&buffer, 0x00, sizeof(buffer));
  strncpy(buffer.ifr_name, iface, IFNAMSIZ);
  if (ioctl(s, SIOCGIFINDEX, &buffer) < 0) {
    printf("Error: could not get interface index\n");
    close(s);
    return -1;
  }
  ifindex = buffer.ifr_ifindex;
 
 // Get the Host EMAC address
  unsigned char source[ETH_ALEN];
  if (ioctl(s, SIOCGIFHWADDR, &buffer) < 0) {
    printf("Error: could not get interface address\n");
    close(s);
    return -1;
  }
  memcpy((void*)source, (void*)(buffer.ifr_hwaddr.sa_data),
         ETH_ALEN);
 
  union ethframe frame;
  // Start building the FRAME
  memcpy(frame.field.header.h_dest, dest, ETH_ALEN); // DEST EMAC ADDRESS
  memcpy(frame.field.header.h_source, source, ETH_ALEN); // SOURCE EMAC ADDRESS
  frame.field.header.h_proto = htons(proto); // PROTOCOL / LENGTH Field
  memcpy(frame.field.data, data, data_len); // DATA Field

 
  unsigned int frame_len = data_len + ETH_HLEN; // FRAME LENGTH = 1024 + 14 = 1038
	//printf("Frame Length: %d\n",frame_len);
  // SOCKET_II
  struct sockaddr_ll saddrll;
  memset((void*)&saddrll, 0, sizeof(saddrll));
  saddrll.sll_family = PF_PACKET;   
  saddrll.sll_ifindex = ifindex;
  saddrll.sll_halen = ETH_ALEN;
  memcpy((void*)(saddrll.sll_addr), (void*)dest, ETH_ALEN);
  num = 0;
  for (i = 0; i< num_rx_pack; i++){
 
  if (sendto(s, frame.buffer, frame_len, 0,
             (struct sockaddr*)&saddrll, sizeof(saddrll)) > 0){
    num++;}
 
 }
  close(s);
 
  return (num);
}
