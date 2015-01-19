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

#include <platform.h>
#include <xs1.h>
#include <print.h>
#include <math.h>
#include <stdlib.h> // for exit()

#include "Swallow-helpers.h"
#include "Swallow-nOS_asm.h"
#include "Swallow-nOS.h"
#include "Swallow-nOS_client.h"
#include "Swallow-nOS_initialFunctions.h"

#define LOCALnOSCHANEND 0x1f02 // hard-coded for core[0] only. TODO: generalise
#define IMG_WIDTH 64
#define IMG_LENGTH 64
#define DIV_DEGREE 4 // the degree to which the image is divided along each dimension (can only result in a square number of small images)
#define NUM_CHILDREN 16 //num_children must equal DIV_DEGREE^2
#define THRESHOLD 30 // threshold for gradient to be labeled as an edge

void addNewChanMapEntry(chanMapping chanMap[MAXLOCALTHREADS][MAXTHREADCHANNELS], channel c, unsigned owner, unsigned index)
{
	owner = owner & 0xff ;
	chanMap[owner][index].chanID = c ;
}

channel lookupChanMapEntry(chanMapping chanMap[MAXLOCALTHREADS][MAXTHREADCHANNELS], unsigned owner, unsigned index)
{
	owner = owner & 0xff ;
	return chanMap[owner][index].chanID ;
}

void deleteChanMapEntry(chanMapping chanMap[MAXLOCALTHREADS][MAXTHREADCHANNELS], unsigned owner, unsigned index)
{
	owner = owner & 0xff ;
	chanMap[owner][index].chanID = 0 ;
}

unsigned nOS_doAction(unsigned action, unsigned arg1, unsigned arg2, unsigned arg3, unsigned stacks[MAXLOCALTHREADS][THREADSTACKSIZE], chanMapping chanMap[MAXLOCALTHREADS][MAXTHREADCHANNELS])
{
	channel c ;
	unsigned result ;
	static unsigned startadr ;

	startadr = arg2 ;

	switch(action) {

	// allocate a new channel of the given index and connect it
	// useful for active / outgoing connection channels
	// arg1 { connecting ThreadID_16 , connecting thread's channel Index_16}
	// arg2 destination chanend
	case nOS_connectNewChannel_action :
		c = getNewChannel() ;
		connectChannel(c, arg2) ;
		addNewChanMapEntry(chanMap, c, arg1 >> 16, arg1 & 0xffff) ;
		return c ;

	// allocate a new channel of provided index, but do not connect it
	// useful for listen channels
	// arg1 { connecting threadID_16 , connecting thread Index_16}
	// arg2 <unused>
	case nOS_allocateNewChannel_action :
		c = getNewChannel() ;
		addNewChanMapEntry(chanMap, c, arg1 >> 16, arg1 & 0xffff) ;
		return c ;

	// find the destintation of a (hopefully) in-use channel
	// arg1 requested channel's owner and index { threadID_16 , thread Index_16}
	// arg2 <unused>
	case nOS_getChannelDest_action :
		c = lookupChanMapEntry(chanMap, arg1 >> 16, arg1 & 0xffff) ;
		asm("getd %0, res[%1]" : "=r"(result) : "r"(c)) ;
		return result ;

	// update the destination of a channel based on the thread's ID and channel index
	// arg1 { connecting threadID_16 , connecting thread Index_16}
	// arg2 new destination chanend
	case nOS_updateChannelDest_action :
		c = lookupChanMapEntry(chanMap, arg1 >> 16, arg1 & 0xffff) ;
		asm("setd res[%0], %1" : : "r"(c), "r"(arg2)) ;
		return 0 ;

	// release control of a channel
	// arg1 { connecting threadID_16 , connecting thread Index_16}
	// arg2 <unused>
	case nOS_releaseChannel_action :
		c = lookupChanMapEntry(chanMap, arg1 >> 16, arg1 & 0xffff) ;
		asm("freer res[%0]" : : "r"(c)) ;
		deleteChanMapEntry(chanMap, arg1 >> 16, arg1 & 0xffff) ;
		return 0 ;

	// find out the chanend of a certain thread + index
	// useful for the remote clients to interrogate their parents about what channel to connect back on
	// arg1 { connecting threadID_16 , connecting thread Index_16}
	// arg2 <unused>
	case nOS_lookupChanend_action :
		c = lookupChanMapEntry(chanMap, arg1 >> 16, arg1 & 0xffff) ;
		return c ;

	// create a new thread of execution on this core
	// arg1 { connecting threadID_16 , connecting thread Index_16}
	// arg2 := PC start address for new thread
	// arg3 := child thread rank, passed from parent call
	// returns the globally unique node + thread identifier for the thread
	case nOS_createThread_action :
		result = nOS_createThread(arg1, startadr, arg3, stacks) ;
		return result ;
	}
}

// global stacks variable

//unsigned threadStacks[1][1] ;

void nOS_start(chanend c)
{
	chan d ;
	char threadNoChildren[MAXLOCALTHREADS] ; // track its children so we know if we can migrate

	// declare the listen channel early so that it can try to receive all necessary messages
	unsigned listenChannel = getSpecificLocalChannel( (LOCALnOSCHANEND & 0xff00) >> 8) ;

	unsigned myID = get_logical_core_id() ;

	unsigned startAddress, stackSize ;

	unsigned nOS_threadStacks[MAXLOCALTHREADS][THREADSTACKSIZE] ;

	chanMapping chanMap[MAXLOCALTHREADS][MAXTHREADCHANNELS] ; // the table containing the channel to thread mapping and IDs


/*	get_stackSize(nOS_start, stackSize) ;
	get_startAddress(nOS_start, startAddress) ;
	printhexln(startAddress) ;
	printhexln(stackSize) ; */

	// synchronisation needed since messages sent before the local channel is acquired may be lost
	c <: 42 ;

	if (myID != 0) {
		printstrln("nOS not running as Thread 0. Exiting") ;
		exit(-1) ;
	}
	else printstrln("nOS initialising...") ;

	// initialise chanMap to null values
	for (int i = 0 ; i < MAXLOCALTHREADS ; i++)
		{
		threadNoChildren[i] = 0 ;
		for (int j = 0 ; j < MAXTHREADCHANNELS ; j++)
			chanMap[i][j].chanID = 0 ;
		}

	// touch the stacks, so the compiler knows they're alive
	//threadStacks[0][0] = 0 ;

	while(1){
		nOS_listenForAction(listenChannel, nOS_threadStacks, chanMap) ;
	//	nOS_createThread(getStartAddress(p_begin1)) ;
	//	nOS_createThread(getStartAddress(p_begin2)) ;
	//	nOS_createThread(getStartAddress(p_begin3)) ;
	}

}



void eventTestA()
{
	channel c, d ;
	c = getNewChannel() ;
	d = getNewChannel() ;

	nOS_setChannelDest(c, 0x2) ;
	nOS_setChannelDest(d, 0x2) ;

	installHandlerToFoo(c) ;
	installHandlerToFoo(d) ;

	nOS_waitForEvent() ; // wait for a transmission from eventTestB, which is handled in the Foo handler.

	nOS_disableEvent(c) ;
	nOS_disableEvent(d) ;


	select1A(c, d) ;

}

void select1B(chanend c1, chanend c2)
{
	unsigned a ;
	select
	{
		case c1 :> a :
		break ;

		case c2 :> a :
		break ;
	}
}



unsigned food ;

void eventTestB()
{
	channel e ;
	e = getNewChannel() ;
	for (int i = 0 ; i < 100 ; i++)  food ++ ;

	nOS_setChannelDest(e, 0x102) ;

	channelSendWord(e, 42) ;

}


void begin1(unsigned parentID, unsigned rank)
{
	printstrln("Begin1!") ;
	printintln(parentID) ;
	printintln(rank) ;
}

void begin2(unsigned parentID, unsigned rank)
{
	printstrln("Begin2!") ;
}

void begin3(unsigned parentID, unsigned rank)
{
	printstrln("Begin3!") ;
}




void chanTestParent(chanend c)
{
	unsigned dest ;
	unsigned childID ;
	unsigned childStart ;
	unsigned childStack ;
	unsigned data ;
	channel myChanA ;

	c :> dest ;

	printstrln("Starting channel test parent") ;
	myChanA = client_allocateNewLocalChannel(1) ;
	printstr("Channel allocated with ID: ") ;
	printhexln(myChanA) ;
	printstrln("Starting child") ;
	// use rank here to supply connection index for child to connect back to

	get_startAddress(chanTestChild, childStart) ;
	get_stackSize(chanTestChild, childStack) ;
	childID = client_createThread(childStart, childStack, 1, 0) ;
	printstr("Child started. ID is : ") ;
	printhexln(childID) ;
	printstrln("Now listening on channel") ;
	dest = channelListen(myChanA) ;
	printstrln("Listened.") ;
	data = channelReceiveWord(myChanA) ;
	printstr("Done. Data received was: ") ;
	printintln(data) ;

}


#define CHILDFIRSTCHANNEL 1 // first channel

void chanTestChild(unsigned parentID, unsigned rank)
{
	channel myChanB ;
	endpoint dest ;
	//myChanB = client_allocateNewLocalChannel(CHILDFIRSTCHANNEL) ;
	dest = client_lookupParentChanend(parentID, rank) ;
	//client_updateLocalChannelDest(CHILDFIRSTCHANNEL, dest) ; //TODO: Fix initial channel connetion and synchronisation

	myChanB = client_connectNewLocalChannel(CHILDFIRSTCHANNEL, dest) ;

	//connectChannel(myChanB, dest) ;
	printstrln("chanTestChild sending word.") ;
	channelSendWord(myChanB, 42) ;
	printstrln("chanTestChild done.") ;
}

void sinkSync(chanend c)
{
	unsigned foo ;
	c :> foo ;
}


// Run the OS!
int main()
{
	chan c, c1, c2,c3, c4, c5 ;
	par{
		on stdcore[0] : nOS_start(c) ;
		// Add your application main functions for a core here
		on stdcore[0] : sinkSync(c) ;
		on stdcore[1] : nOS_start(c1) ;
		// Add your application main functions for a core here
		on stdcore[1] : sinkSync(c1) ;
		on stdcore[2] : nOS_start(c2) ;
		// Add your application main functions for a core here
		on stdcore[2] : sinkSync(c5) ;
		//on stdcore[0] : eventTestA() ;
		//on stdcore[0] : eventTestB() ;
	}
	return 0 ;
}
