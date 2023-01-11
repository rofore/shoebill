//
//  VMInterface.m
//  EmbeddedTalk
//
//  Created by Robin Reutimann on 08.09.22.
//

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                           *
 * BASED UPON  https://github.com/adnsio/qemu-vmnet/blob/main/pkg/vmnet/     *
 * which is licensed under GNU Affero General Public License v3.0            *
 *                                                                           *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#include "VMNet.h"
#include "shoebill.h"
#include <string.h>
#include <assert.h>

#if (1 == USE_VMNET)

void VMNet_init(VMNet_t *vmNet) {
	pthread_mutex_init(&vmNet->mutex, NULL);
	pthread_mutex_lock(&vmNet->mutex);
	vmNet->maxPacketSize = ( 2500UL );
}

void VMNet_start(VMNet_t *vmNet, const char *interface) {	

	xpc_object_t interface_desc = xpc_dictionary_create(NULL, NULL, 0);

	xpc_dictionary_set_uint64(interface_desc, vmnet_operation_mode_key,
							  VMNET_BRIDGED_MODE);


	xpc_dictionary_set_string(interface_desc, vmnet_shared_interface_name_key, interface);

	
	dispatch_queue_t interface_start_queue = dispatch_queue_create("vmnet-start", DISPATCH_QUEUE_SERIAL);

	dispatch_semaphore_t interface_start_semaphore = dispatch_semaphore_create(0);
	
	__block interface_ref _interface;
	__block vmnet_return_t interface_status;
	__block uint64_t _max_packet_size = 0;
	
	assert(NULL != _interface);
	assert(NULL != interface_desc);

	_interface = vmnet_start_interface(
									   interface_desc, interface_start_queue,
									   ^(vmnet_return_t status, xpc_object_t interface_param) {

										   interface_status = status;
										   
										   if (status == VMNET_SUCCESS) {
											   _max_packet_size = xpc_dictionary_get_uint64(
																							interface_param, vmnet_max_packet_size_key);
										   }

										   dispatch_semaphore_signal(interface_start_semaphore);
									   });
	


	dispatch_semaphore_wait(interface_start_semaphore, DISPATCH_TIME_FOREVER);

	dispatch_release(interface_start_queue);
	xpc_release(interface_desc);

	if (interface_status != VMNET_SUCCESS) {
		printf("VMNet Interface startup failed.\n");
		return;
	} else {
		printf("Started VMNet\n");
	}
	
	vmNet->iface = _interface;
	vmNet->maxPacketSize = _max_packet_size;
	assert(_max_packet_size >= 1500);
	pthread_mutex_unlock(&vmNet->mutex);
}

void VMNet_stop(VMNet_t *vmNet) {
	dispatch_queue_t interface_stop_queue =
	dispatch_queue_create("vmnet-stop", DISPATCH_QUEUE_SERIAL);
	dispatch_semaphore_t interface_stop_semaphore = dispatch_semaphore_create(0);
	
	vmnet_stop_interface(vmNet->iface, interface_stop_queue,
						 ^(vmnet_return_t status) {
		dispatch_semaphore_signal(interface_stop_semaphore);
	});
	
	dispatch_semaphore_wait(interface_stop_semaphore, DISPATCH_TIME_FOREVER);
	dispatch_release(interface_stop_queue);
	pthread_mutex_destroy(&vmNet->mutex);
}

#endif