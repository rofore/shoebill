//
//  VMInterface.h
//  EmbeddedTalk
//
//  Created by Robin Reutimann on 08.09.22.
//

#ifndef VMNET_PKG
#define VMNET_PKG

//#include "EtherTalk.h"
#include <stdbool.h>
#include <stdint.h>
#include <vmnet/vmnet.h>

#define ETH_ADDRESS_LENGTH 			(  6U )
#define ETH_SNAP_DISCR_LENGTH		(  5U )

#define ETH_DST_ADDR_OFFSET 		(  0U )
#define ETH_SRC_ADDR_OFFSET 		(  6U )
#define ETH_LENGTH_OFFSET  			( 12U )
#define ETH_DST_SAP_OFFSET  		( 14U )
#define ETH_SRC_SAP_OFFSET  		( 15U )
#define ETH_CONTROL_BYTE_OFFSET  	( 16U )
#define ETH_SNAP_OFFSET  			( 17U )
#define ETH_START_OFFSET  			( 17U + ETH_SNAP_DISCR_LENGTH )

typedef uint8_t EthernetAddress_t[ETH_ADDRESS_LENGTH];

typedef struct vmnet_interface *VMNet_Interface_t;

typedef struct VMNet_TAG {
	VMNet_Interface_t iface;
	uint64_t maxPacketSize;
	pthread_mutex_t mutex;
} VMNet_t;

void VMNet_init(VMNet_t *vmNet);
void VMNet_start(VMNet_t *vmNet, const char *interface);
void VMNet_stop(VMNet_t *vmNet);

#endif /* VMNET_PKG */