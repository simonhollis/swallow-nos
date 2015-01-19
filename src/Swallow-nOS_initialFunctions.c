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

#include "Swallow-nOS.h"
#include "Swallow-nOS_client.h"
#include "Swallow-nOS_asm.h"
#include "Swallow-helpers.h"

#define NUMBEROFSTARTS 3

/* OBSOLETE WITH NEW client_createThread
unsigned getStartAddress(unsigned index)
{
	void (*starts[NUMBEROFSTARTS])(unsigned,unsigned) ; // void (void) function pointer
	void (*starts2[NUMBEROFSTARTS])(unsigned,unsigned);
	starts[p_begin1] = begin1 ;
	starts[p_begin2] = begin2 ;
	starts[p_begin3] = begin3 ;
	if(index<3) return (unsigned) starts[index] ;
	else return (unsigned) starts2[index];
}
*/

/*
 * Event handlers: akin to select statement in XC
 * Process: 1) get channel IDs
 *          2) install an event handler for each channel desired to select over
 *             using nOS_addEventHandler(c, (unsigned) pFoo) ;
 *          3) Events can then trigger asynchronously
 *          4) Can wait on an event by calling nOS_waitForEvent()
 *          5) After select is finished, call nOS_disableEvent(channel c) on each channel that was previously enabled
 *
 */



// Example event handler. Installed by an installHandlerTo... call (see below)
void fooEventHandler()
{
	unsigned theEventChannel ;
	unsigned someData ;
	theEventChannel = nOS_getEventID() ;
	// would implement the event handler code here
	// e.g.
	someData = channelReceiveWord(theEventChannel) ;
}


// Currently, for each event handler, we need to write a function that
// initalises that handler. This function is unfortunately unique for each handler,
// until the time that the compiler can be massaged more coherently.
void installHandlerToFoo(unsigned c) // the unsigned is a 'channel' type in XC
{
	void (*pFoo)(void) ; // function pointer
	pFoo = fooEventHandler ; // point to desired handler
	nOS_addEventHandler(c, (unsigned) pFoo) ; // install the handler
}

void select1A(unsigned a, unsigned b)
{
	select1B(a, b) ;
}


void allocateChanByRef(unsigned *c)
{
	*c = 0x02 ;
}
