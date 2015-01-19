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
 
/*
 * helpers.xc
 *
 *  Created on: 23 Mar 2013
 *      Author: harry
 */
#include <string.h> // for strlen()
#include <platform.h>
#include "Swallow-helpers.h"
//#define SWXLB_POS_BOTTOM          0
//#include "../../sw_swallow_etherboot/app_swallow_etherboot/src/swallow_etherboot_conf.h" // for swxlb_cfg
#include "swallow_comms.h" // for Steve's tools
//#include "../../sc_swallow_communication/module_swallow_comms/src/swallow_comms.h" // for swallow_cvt_chanend()

#define BOARDS_W 5

#define DEBUG_STRING_MAXLENGTH 1024

/*
 * "chanend" means native xc chan with chanend
 * "channel" means chanends being treated as unsigned
 */

// not tested
unsigned rowColToNodeId(unsigned row, unsigned column, unsigned layer)
{
	unsigned id ;
	// first generate node index, then convert to id
	//id = row * swxlb_cfg.boards.w ;
	id = row * BOARDS_W * 4 ;
	id += 2 * column ;
	id += layer ;
	id = id << 16 ;
	return swallow_cvt_chanend(id) >> 16 ;
}

// convert a node index (i.e. 0-N) to it's row and column-based ID
// tested
unsigned nodeIndexToId(unsigned node)
{
	return swallow_cvt_chanend(node << 16) ;
}


// tested on a small network
endpoint buildChanId(unsigned node, unsigned chanIndex)
{
	node = nodeIndexToId(node) ;
	return (node) | (chanIndex << 8) | 0x2 ;
}

//(unsigned, unsigned) getNodeandChan(chanend c)
//{

//}
channel getNewChannel()
{
	channel localEndpoint ;
	asm("getr %0, 0x2" : "=r" (localEndpoint) : ) ; // get a fresh local endpoint
	return localEndpoint ;
}


// checked :)
void connectChanend(chanend c, endpoint dest)
{
	asm("setd res[%0], %1" : :  "r"(c) , "r"(dest)) ; // point the endpoint to the destination
	asm("outct res[%0], 0x1" : : "r"(c)) ; // output an END token to synchronise but not keep the channel open whilst waiting for other end
	asm("out res[%0], %1" : : "r"(c), "r"(c)) ;  // send the origin channel
	asm("chkct res[%0], 0x1" : : "r"(c)) ; // receive an END as the ack. Also frees the route from other end
	asm("outct res[%0], 0x1" : : "r"(c) ) ; // send an END control token, freeing up the route from this end.
}


void connectChannel(channel c, endpoint dest)
{
	asm("setd res[%0], %1" : :  "r"(c) , "r"(dest)) ; // point the endpoint to the destination
	asm("outct res[%0], 0x1" : : "r"(c)) ; // output an END token to synchronise but not keep the channel open whilst waiting for other end
	asm("out res[%0], %1" : : "r"(c), "r"(c)) ;  // send the origin channel
	asm("outct res[%0], 0x1" : : "r"(c) ) ; // send an END control token, freeing up the route from this end.
	asm("chkct res[%0], 0x1" : : "r"(c)) ; // receive an END as the ack. Also frees the route from other end
}

/*
channel connectNewChannel(endpoint dest)
{
	unsigned localEndpoint ;
	asm("getr %0, 0x2" : "=r" (localEndpoint) : ) ; // get a fresh local endpoint
	asm("setd res[%0], %1" : :  "r"(localEndpoint) , "r"(dest)) ; // point the endpoint to the destination
	return localEndpoint ;
}
*/
// checked :)
// N.B. Don't use with channelConnect/channelListen, since the resource shouldn't be freed
// name clash with one of steve's functions...
void freeChanend_sjh(chanend c)
{
	asm("freer res[%0]" :  : "r" (c) ) ; // free the local endpoint
}

void freeChannel(channel c)
{
	asm("freer res[%0]" :  : "r" (c) ) ;
}

// checked :)
endpoint chanendListen(chanend c)
{
	endpoint sender ;
	asm("chkct res[%0], 0x1" : : "r"(c)) ; // wait for an END token to arrive
	asm("in %0, res[%1]" : "=r"(sender)  : "r"(c)) ; // received the destination
	asm("setd res[%0], %1" : :  "r"(c) , "r"(sender)) ; // point the endpoint to the sender so that we can synchronise
	asm("outct res[%0], 0x1" : : "r"(c)) ; // send END token, freeing up the route from this end
	asm("chkct res[%0], 0x1" : : "r"(c)) ; // receive an END as the ack. Also frees the route from other end
	return sender ;
}

// tested :)
endpoint channelListen(channel c)
{
	endpoint sender ;
	asm("chkct res[%0], 0x1" : : "r"(c)) ; // wait for an END token to arrive
	asm("in %0, res[%1]" : "=r"(sender)  : "r"(c)) ; // received the destination
	asm("chkct res[%0], 0x1" : : "r"(c)) ; // receive an END as the ack. Also frees the route from other end
	asm("setd res[%0], %1" : :  "r"(c) , "r"(sender)) ; // point the endpoint to the sender so that we can synchronise
	asm("outct res[%0], 0x1" : : "r"(c)) ; // send END token, freeing up the route from this end
	return sender ;
}

void channelSendWord(channel c, unsigned value)
{
	asm("outct res[%0], 0x1" : : "r"(c)) ; // send END token, freeing up the route from this end
	asm("chkct res[%0], 0x1" : : "r"(c)) ; // receive an END as the ack. Also frees the route from other end
	asm("out res[%0], %1" : : "r"(c), "r"(value)) ;
	asm("outct res[%0], 0x1" : : "r"(c)) ; // send END token, freeing up the route from this end
	asm("chkct res[%0], 0x1" : : "r"(c)) ; // receive an END as the ack. Also frees the route from other end
}

// tested :)  and <: infix compatible :)
unsigned channelReceiveWord(channel c)
{
	unsigned value ;
	asm("chkct res[%0], 0x1" : : "r"(c)) ; // receive an END as the ack. Also frees the route from other end
	asm("outct res[%0], 0x1" : : "r"(c)) ; // send END token, freeing up the route from this end
	asm("in %0, res[%1]" : "=r"(value) : "r"(c)) ;
	asm("chkct res[%0], 0x1" : : "r"(c)) ; // receive an END as the ack. Also frees the route from other end
	asm("outct res[%0], 0x1" : : "r"(c)) ; // send END token, freeing up the route from this end
	return value ;
}


// return length
void channelReceiveWords(channel c, unsigned &length, unsigned buffer[])
{
	asm("chkct res[%0], 0x3" : : "r"(c)) ; //  receive an ACK to allocate reverse route
	asm("outct res[%0], 0x3" : : "r"(c)) ; // send ACK token, grabbing the route
	asm("in %0, res[%1]" : "=r"(length) : "r"(c)) ; // receive length
	for (int i = 0 ; i < length ; i++)
	{
		asm("in %0, res[%1]" : "=r"(buffer[i]) : "r"(c)) ; // receive data
	}
	asm("chkct res[%0], 0x1" : : "r"(c)) ; // receive an END as the ack. Also frees the route from other end
	asm("outct res[%0], 0x1" : : "r"(c)) ; // send END token, freeing up the route from this end
	return ;
}


// send some words on a channel
void channelSendWords(channel c, unsigned &length, unsigned buffer[])
{
	asm("outct res[%0], 0x3" : : "r"(c)) ; // send ACK token, grabbing the route
	asm("chkct res[%0], 0x3" : : "r"(c)) ; // receive an ACK to allocate reverse route
	asm("out res[%1], %0" : : "r"(length),  "r"(c)) ; // receive length
	for (int i = 0 ; i < length ; i++)
	{
		asm("out res[%1], %0" : : "r"(buffer[i]), "r"(c) ) ; // receive data
	}
	asm("outct res[%0], 0x1" : : "r"(c)) ; // send END token, freeing up the route from this end
	asm("chkct res[%0], 0x1" : : "r"(c)) ; // receive an END as the ack. Also frees the route from other end
	return ;
}

void printReceiveWords(channel c, unsigned &length, unsigned buffer[])
{
	unsigned sender ;
	asm("chkct res[%0], 0x3" : : "r"(c)) ; //  receive an ACK to allocate reverse route
	asm("in %0, res[%1]" : "=r"(sender) : "r"(c)) ; // receive destination
	asm("setd res[%0], %1" : :  "r"(c) , "r"(sender)) ; // point the endpoint to the destination
	asm("outct res[%0], 0x3" : : "r"(c)) ; // send ACK token, grabbing the route
	asm("in %0, res[%1]" : "=r"(length) : "r"(c)) ; // receive length
	for (int i = 0 ; i < length ; i++)
	{
		asm("in %0, res[%1]" : "=r"(buffer[i]) : "r"(c)) ; // receive data
	}
	asm("chkct res[%0], 0x1" : : "r"(c)) ; // receive an END as the ack. Also frees the route from other end
	asm("outct res[%0], 0x1" : : "r"(c)) ; // send END token, freeing up the route from this end
	return ;
}


// send some words on a channel
void printSendWords(channel c, channel dest, unsigned &length, unsigned buffer[])
{
	asm("setd res[%0], %1" : :  "r"(c) , "r"(dest)) ; // point the endpoint to the destination
	asm("outct res[%0], 0x3" : : "r"(c)) ; // send ACK token, grabbing the route
	asm("out res[%1], %0" :: "r"(c), "r"(c)) ; // send channelID
	asm("chkct res[%0], 0x3" : : "r"(c)) ; // receive an ACK to allocate reverse route
	asm("out res[%1], %0" : : "r"(length),  "r"(c)) ; // send length
	for (int i = 0 ; i < length ; i++)
	{
		asm("out res[%1], %0" : : "r"(buffer[i]), "r"(c) ) ; // receive data
	}
	asm("outct res[%0], 0x1" : : "r"(c)) ; // send END token, freeing up the route from this end
	asm("chkct res[%0], 0x1" : : "r"(c)) ; // receive an END as the ack. Also frees the route from other end
	return ;
}



// grab and return the specified channel number on the local core. Is a brute-force approach
// checked :)
unsigned getSpecificLocalChannel(unsigned channelNo)
{
	unsigned localEndpoint = 0 ;
	unsigned tileID ;
	unsigned endpointsTried[32] ;
	unsigned desiredEndpoint ;
	int noEndpointsTried = 0 ;

	tileID = get_local_tile_id() ;

	desiredEndpoint = ((tileID << 16) | (channelNo <<8) | 0x2) ;

	while (localEndpoint !=  desiredEndpoint)
	{
		asm("getr %0, 0x2" : "=r" (localEndpoint) : ) ; // get a fresh local endpoint
		endpointsTried[noEndpointsTried] = localEndpoint ;

		noEndpointsTried++ ;
	}
	// at this point, the last endpoint tried should be the one we want.
	// If we get an error 'cos we ran out of endpoints, it was already in use somewhere
	// now release the ones we didn't want...
	noEndpointsTried -= 2  ;

	while (noEndpointsTried >= 0)
	{
		asm ("freer res[%0]" :  : "r"(endpointsTried[noEndpointsTried])) ;
		noEndpointsTried -- ;
	}

	return localEndpoint ;
}


void coreSendWords(streaming chanend output, unsigned data[], unsigned data_length)
{
	startTransactionClient(output,0x80010402,0x4,data_length);
	for (int i = 0; i < data_length ; i += 1)
	{
	    output <: data[i] ;
	}
	endTransactionClient(output);

}



unsigned coreReceiveWords(streaming chanend input, unsigned receiveBuffer[])
{
	unsigned dst, format, length, value;

		//	odd_leds <: 1 ;
		    startTransactionServer(input,dst,format,length);
		 //   odd_leds <: 2 ;
		    //We assume we are format = 0x4, because we're lazy in this demo
		    for (int i = 0; i < length; i += 1)
		    {

		      //streamInWord(input,value);
		    	input :> receiveBuffer[i] ;
		    	// show value on LEDs
		 //   	odd_leds <: receiveBuffer[i] ;
		    }
		    endTransactionServer(input);
		    //coreSendWords(output, receiveBuffer, length) ;

		//    odd_leds <: 0 ;
		    return length ;
}


void coreSendBytes(streaming chanend output, char data[], unsigned data_length)
{
	startTransactionClient(output,0x80010402,0x1,data_length);
	for (int i = 0; i < data_length ; i += 1)
	{
	    output <: data[i] ;
	}
	endTransactionClient(output);
}





void SwPrintUnsigned(streaming chanend output, unsigned value)
{
	unsigned values[1] ;
	values[0] = value ;
	coreSendWords(output, values, 1) ;
}


unsigned stringToChars(const char s[], char c[])
{
	unsigned length = 0 ;
	while (s[length] != '\0' && length < DEBUG_STRING_MAXLENGTH )
	{
		c[length] = s[length] ;
		length++ ;
	}
	return length ;
}


void SwPrintString(streaming chanend output,  const char string[])
{
	unsigned length ;
	char charBuffer[DEBUG_STRING_MAXLENGTH] ; // longest string length is determined here
	length = stringToChars(string, charBuffer) ;
	coreSendBytes(output, charBuffer, length) ;
}

