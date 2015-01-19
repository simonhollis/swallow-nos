/*
    This file is part of the swallow-nos project, which can be found at:
    https//github.com/simonhollis/swallow-nos
    Copyright (C) 2015 Simon J. Hollis
    The author can be contacted at simon ATSYMBOL bristol.ac.uk

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <xs1.h>
#include <print.h>
#include <math.h>
#include "Swallow-helpers.h"
#include "Swallow-nOS_asm.h"
#include "Swallow-nOS.h"
#include "Swallow-nOS_initialFunctions.h"
#include "Swallow-nOS_client.h"



#define LOCALnOSCHANEND 0x1f02 // hard-coded for core[0] only. TODO: generalise


// specify the start address, stack size, rank and the tile (by index) to allocate the thread on
unsigned client_createThread(unsigned startAddress, unsigned stackSize, unsigned childRank, unsigned tileIndex)
{
	unsigned myCore = get_local_tile_id() ;    // returns node ID
	unsigned myThread = get_logical_core_id() ;  // returns 0--7
	unsigned myID = (myCore << 16) | myThread ;   // a unique ID for this thread
	//return nOS_requestAction(LOCALnOSCHANEND, nOS_createThread_action, myID, startAddress, childRank) ;
	//return nOS_requestAction((nodeIndexToId(tileIndex) | LOCALnOSCHANEND), nOS_createThread_action, myID, startAddress, childRank) ;
	unsigned destTile ;
	if (tileIndex == 1) destTile = 0x40000000 ;
	else if (tileIndex == 2) destTile = 0x60000000 ;
	else destTile = 0 ;

	return nOS_requestAction((destTile | LOCALnOSCHANEND), nOS_createThread_action, myID, startAddress, childRank) ;
}

channel client_connectNewLocalChannel(unsigned channelIndex, endpoint destination)
{
	unsigned myCore = get_local_tile_id() ;
	unsigned myThread = get_logical_core_id() ;
	unsigned chanID = (myThread << 16) | channelIndex ;
	return nOS_requestAction(myCore << 16 | LOCALnOSCHANEND, nOS_connectNewChannel_action, chanID, destination, 0) ;
}

channel client_allocateNewLocalChannel(unsigned channelIndex)
{
	unsigned myCore = get_local_tile_id() ;
	unsigned myThread = get_logical_core_id() ;
	unsigned chanID = (myThread << 16) | channelIndex ;
	return nOS_requestAction(myCore << 16 | LOCALnOSCHANEND, nOS_allocateNewChannel_action, chanID, 0, 0) ;
}

endpoint client_getLocalChannelDest(unsigned channelIndex)
{
	unsigned myCore = get_local_tile_id() ;
	unsigned threadID = get_logical_core_id() ;
	unsigned chanID = (threadID << 16 ) | channelIndex ;
	return nOS_requestAction(myCore << 16 | LOCALnOSCHANEND, nOS_getChannelDest_action, chanID, 0, 0) ;
}

void client_updateLocalChannelDest(unsigned channelIndex, endpoint destination)
{
	unsigned myCore = get_local_tile_id() ;
	unsigned threadID = get_logical_core_id() ;
	unsigned chanID = (threadID << 16) | channelIndex ;
	nOS_requestAction(myCore << 16 | LOCALnOSCHANEND, nOS_updateChannelDest_action, chanID, destination, 0) ;
}


void client_releaseLocalChannel(unsigned channelIndex)
{
	unsigned myCore = get_local_tile_id() ;
	unsigned threadID = get_logical_core_id() ;
	unsigned chanID = (threadID << 16) | channelIndex ;
	nOS_requestAction(myCore << 16 | LOCALnOSCHANEND, nOS_releaseChannel_action, chanID, 0, 0) ;
}

endpoint client_lookupLocalChanend(unsigned channelIndex)
{
	unsigned myCore = get_local_tile_id() ;
	unsigned threadID = get_logical_core_id() ;
	unsigned chanID = (threadID << 16) | channelIndex ;
	return nOS_requestAction(myCore << 16 | LOCALnOSCHANEND, nOS_lookupChanend_action, chanID, 0, 0) ;
}


endpoint client_lookupParentChanend(unsigned parentID, unsigned channelIndex)
{
	// parentID is (COREID_16, THREADINDEX_16}
	// for the lookup, we need to send to the OS on COREID with an argument of the {threadIndex_16, channelIndex_16}
	unsigned destOS = (parentID & 0xffff0000) | LOCALnOSCHANEND ;
	unsigned indices = (parentID << 16) | (channelIndex & 0x0000ffff) ;

	return nOS_requestAction(destOS, nOS_lookupChanend_action, indices , 0, 0) ;
}

// TODO: Add lookup remote chanend. Easy, just need to replace LOCALnOSCHANEND with the remote node's port.
// the remainder should be the same.

unsigned get_address_p1()
{
	unsigned addr ;
//	get_address_macro(p1) ; // the argument to this macro is a textual label
	return addr ;
}

unsigned get_address_begin1()
{
	unsigned addr ;
//	get_address_macro(begin1) ; // the argument to this macro is a textual label
	return addr ;
}

void p1(chanend c)
{
	unsigned childID ;
	unsigned foo ;

	c :> foo ;

	// create a child thread by making a nOS call. We get the child's thread ID from this
	// SUPERCEDED:
	//childID = nOS_requestAction(LOCALnOSCHANEND, nOS_createThread_action, myID, getStartAddress(p_begin1)) ;
	// NEW IMPLEMENTATION:
	//childID = client_createThread(p_begin1, 42) ;
	// NEWER IMPLEMENTATION USING MACROS, advice courtesy of Dave Lacey
	childID = client_createThread(get_address_begin1(), 100, 42, 0) ;

}

// a child process. The create process routine passes its parent's ID as the first argument
void child1(unsigned parentID)
{
	unsigned myValue ;
	// declare a communication channel
	channel parentCommunicationChannel ;
	// find from the OS what the channel identifier for your parent is
	//parentCommunicationChannel = nOS_requestAction(LOCALnOSCHANEND, nOS_lookupChanend_action, myID) ;

	// now connect to the parent by creating and connecting a fresh channel
	//nOS_requestAction(LOCALnOSCHANEND, nOS_connectNewChannel_action, myID, parentCommunicationChannel) ;

	// now, according to whatever the task is, communicate with the parent
	channelSendWord(parentCommunicationChannel, myValue) ;
	//value = channelReceiveWord(parentCommunicationChannel) ;

}
