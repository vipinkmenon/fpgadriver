/*
 * Filename: enet_rxr.c
 * Version: 1.0
 * Description: Socket receive for Ethernet - Packet sniffer & dumper
 * Author : Shreejith S
 */



#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>  
#include <unistd.h>
#include <sys/socket.h>
#include <sys/types.h>  
#include <linux/in.h>
#include <linux/if_ether.h>
#include <net/if.h>
#include <sys/ioctl.h>
#include "enet.h"

#define type 0x0400

int socket_receive (int num_packets) {
  int sock, n;
  char buffer[2048],rx_pack[1038];
  unsigned char *iphead, *ethhead;
  struct ifreq ethreq;
  if ( (sock=socket(PF_PACKET, SOCK_RAW, 
                    type))<0) {
    perror("socket");
    exit(1);
  }

  /* Set the network card in promiscuos mode */
  strncpy(ethreq.ifr_name,"eth0",IFNAMSIZ);
  if (ioctl(sock,SIOCGIFFLAGS,&ethreq)==-1) {
    perror("ioctl");
    close(sock);
    exit(1);
  }
  ethreq.ifr_flags|=IFF_PROMISC;
  if (ioctl(sock,SIOCSIFFLAGS,&ethreq)==-1) {
    perror("ioctl");
    close(sock);
    exit(1);
  }
	FILE* erp = NULL;
 erp = fopen("eth_rx_packets.txt","w+");
         fclose(erp); 

  int packs = 0;
  while (packs < num_packets) {
    n = recvfrom(sock,buffer,2048,0,NULL,NULL);


    ethhead = buffer;
    packs++;
	erp = fopen("eth_rx_packets.txt","a+");
	fwrite(&buffer,1,n,erp);
	fclose(erp);
    
    printf(" %d\n",packs);
    printf("Source MAC address: "
           "%02x:%02x:%02x:%02x:%02x:%02x\n",
           ethhead[0],ethhead[1],ethhead[2],
           ethhead[3],ethhead[4],ethhead[5]);
    printf("Destination MAC address: "
           "%02x:%02x:%02x:%02x:%02x:%02x\n",
           ethhead[6],ethhead[7],ethhead[8],
           ethhead[9],ethhead[10],ethhead[11]);

    
  }
  printf("Packs received %d ",packs);  
}

