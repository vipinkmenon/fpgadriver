/*
 * Filename: enet.h
 * Version: 1.0
 * Description: Ethernet functions Header
 * Author : Shreejith S
 */

#ifndef ENET_H
#define ENET_H

#ifdef __cplusplus
extern "C" {
#endif

#define MY_DEST_MAC0	0xaa
#define MY_DEST_MAC1	0xbb
#define MY_DEST_MAC2	0xcc
#define MY_DEST_MAC3	0xdd
#define MY_DEST_MAC4	0xee
#define MY_DEST_MAC5	0xff

#define DEFAULT_IF	"eth1"

#define BUF_SIZ		1060
      
#define ETH_RX_STAT 0x134
#define ETH_TX_STAT 0x138
#define ETH_SRC_ADDR 0x48
#define ETH_DST_ADDR 0x4c
#define ETH_TX_SIZE 0x40
#define ETH_RX_SIZE 0x44

int socket_send(int);
int socket_receive(int);


#ifdef __cplusplus
}
#endif

#endif
