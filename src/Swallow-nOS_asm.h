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
 * Swallow-nOS_asm.h
 *
 *  Created on: 16 Apr 2013
 *      Author: harry
 */

#ifndef SWALLOW_NOS_ASM_H_
#define SWALLOW_NOS_ASM_H_

#define nOS_LISTENCHANNEL 31
#define MAXLOCALTHREADS 2   // max number of nonOS threads supported
#define MAXTHREADCHANNELS 8 // max number of channels/thread supported
#define THREADSTACKSIZE 2048 // number of words for each thread stack

enum nOS_action {nOS_allocateNewChannel_action, nOS_connectNewChannel_action, nOS_getChannelDest_action, nOS_updateChannelDest_action, nOS_releaseChannel_action, nOS_lookupChanend_action, nOS_createThread_action } ;
typedef struct chanMapping {unsigned chanID; } chanMapping ;

unsigned nOS_createThread(unsigned parentID, unsigned startAddress, unsigned childRank, unsigned stacks[MAXLOCALTHREADS][THREADSTACKSIZE]) ;
void nOS_waitForEvent() ;
void nOS_disableAllEvents() ;
unsigned nOS_getEventID() ;


#ifdef __XC__
void nOS_listenForAction(channel c, unsigned stacks[MAXLOCALTHREADS][THREADSTACKSIZE], chanMapping chanMap[MAXLOCALTHREADS][MAXTHREADCHANNELS]) ;
unsigned nOS_requestAction(endpoint dest, unsigned action, unsigned arg1, unsigned arg2, unsigned arg3) ;
void nOS_addEventHandler(channel c, unsigned handler) ;
void nOS_disableEvent(channel c) ;
void nOS_setChannelDest(channel c, unsigned dest) ;

#else
void nOS_listenForAction(unsigned c, unsigned stacks[MAXLOCALTHREADS][THREADSTACKSIZE], chanMapping chanMap[MAXLOCALTHREADS][MAXTHREADCHANNELS]) ;
unsigned nOS_requestAction(unsigned dest, unsigned action, unsigned arg1, unsigned arg2) ;
void nOS_addEventHandler(unsigned c, unsigned handler) ;
void nOS_disableEvent(unsigned c) ;
void nOS_setChannelDest(unsigned c, unsigned dest) ;

#endif

#endif /* SWALLOW_NOS_ASM_H_ */
