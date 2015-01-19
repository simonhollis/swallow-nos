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
 * Swallow-helpers.h
 *
 *  Created on: 24 Mar 2013
 *      Author: harry
 */

#ifndef SWALLOWHELPERS_H_
#define SWALLOWHELPERS_H_

typedef unsigned channel ; // software-defined channel (hardware resource)
typedef unsigned endpoint ;  // channel endpoint (target address)

unsigned nodeIndexToId(unsigned node) ;
endpoint buildChanId(unsigned node, unsigned chanIndex) ;
channel getNewChannel() ;
void connectChannel(channel c, endpoint dest) ;
unsigned connectNewChannel(endpoint dest) ;
unsigned getSpecificLocalChannel(unsigned channelNo) ;
endpoint channelListen(channel c) ;
void channelSendWord(channel c, unsigned value) ;
unsigned channelReceiveWord(channel c) ;
unsigned nodeIndexToId(unsigned node) ;
unsigned rowColToNodeId(unsigned row, unsigned column, unsigned layer) ;

void channelSendWords(channel c, unsigned &length, unsigned buffer[]) ;
void channelReceiveWords(channel c, unsigned &length, unsigned buffer[]) ;

#ifdef __XC__

void connectChanend(chanend c, endpoint dest) ;

void freeChanend_sjh(chanend c) ;
endpoint chanendListen(chanend c) ;

// wrapper functions for sending and receiving data streams using transactionServer and transactionClient
void coreSendWords(streaming chanend output, unsigned data[], unsigned length) ;
unsigned coreReceiveWords(streaming chanend input, unsigned data_buffer[]) ;
void coreSendBytes(streaming chanend output, char data[], unsigned data_length) ;

void freeChannel(channel c) ;
void printSendWords(channel c, channel dest, unsigned &length, unsigned buffer[]) ;
void printReceiveWords(channel c, unsigned &length, unsigned buffer[]) ;

// debug print routines
void SwPrintUnsigned(streaming chanend output, unsigned value) ;
void SwPrintString(streaming chanend output,  const char string[]) ;


#else
void connectChanend(unsigned c, endpoint dest) ;
void freeChanend_sjh(unsigned c) ;
endpoint chanendListen(unsigned c) ;

// wrapper functions for sending and receiving data streams using transactionServer and transactionClient
void coreSendWords(unsigned output, unsigned data[], unsigned length) ;
unsigned coreReceiveWords(unsigned input, unsigned data_buffer[]) ;
void coreSendBytes(unsigned output, char data[], unsigned data_length) ;

// debug print routines
void SwPrintUnsigned(unsigned output, unsigned value) ;
void SwPrintString(unsigned output,  const char string[]) ;

#endif


#endif /* SWALLOWHELPERS_H_ */
