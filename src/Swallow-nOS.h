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
 * Swallow-nOS.h
 *
 *  Created on: 18 Apr 2013
 *      Author: harry
 */

#ifndef SWALLOW_NOS_H_
#define SWALLOW_NOS_H_

//enum processNames { p_begin1, p_begin2, p_begin3, p_sobel_child,p_prim_child } ;
#define get_startAddress(f, var) asm("ldap r11, " #f "; mov %0, r11":"=r"(var)::"r11");
#define conc_macro(str1,str2) #str1#str2
#define get_stackSize_macro2(f, var) asm("ldc %0, " f :"=r"(var):);
#define get_stackSize(f, var) get_stackSize_macro2(conc_macro(f, .nstackwords),var)



#ifdef __XC__
#include "Swallow-helpers.h"
#include "Swallow-nOS_asm.h"


void addNewChanMapEntry(chanMapping chanMap[MAXLOCALTHREADS][MAXTHREADCHANNELS], channel c, unsigned owner, unsigned index) ;
channel lookupChanMapEntry(chanMapping chanMap[MAXLOCALTHREADS][MAXTHREADCHANNELS], unsigned owner, unsigned index) ;
void deleteChanMapEntry(chanMapping chanMap[MAXLOCALTHREADS][MAXTHREADCHANNELS], unsigned owner, unsigned index) ;
unsigned nOS_doAction(unsigned action, unsigned arg1, unsigned arg2, unsigned arg3, unsigned stacks[MAXLOCALTHREADS][THREADSTACKSIZE], chanMapping chanMap[MAXLOCALTHREADS][MAXTHREADCHANNELS]) ;
void nOS_start(chanend c) ;
void begin1(unsigned parentID, unsigned rank) ;
void begin2(unsigned parentID, unsigned rank) ;
void begin3(unsigned parentID, unsigned rank) ;

void select1B(chanend c1, chanend c2) ;

#else
void begin1(unsigned parentID, unsigned rank) ;
void begin2(unsigned parentID, unsigned rank) ;
void begin3(unsigned parentID, unsigned rank) ;

void select1B(unsigned c1, unsigned c2) ;
#endif



#endif /* SWALLOW_NOS_H_ */
