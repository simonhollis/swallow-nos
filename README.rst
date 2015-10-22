Swallow nOS Readme
.............

:Version: 0.3
:Status: Beta
:Maintainer: http://github.com/simonhollis
:Description: nano-sized operating system for University of Bristol Swallow system.


Overview
========

* This repository contains the source of the nOS (nano-Operating System) project.
nOS is a tiny, distributed OS designed to run on the Swallow many-core system
developed by Simon Hollis at the University of Bristol 
[http://swallow-project.github.io/]

* Swallow wiki: [http://swallow-project.github.io/wiki-swallow/index.html]
(old site: http://www.cs.bris.ac.uk/Research/Micro/swallow.jsp)


Documentation
=============

*API*
doxygen-based documentation for the nOS API is available in this repository in the 'doxygen' folder:
[http://swallow-project.github.io/doxygen-swallow-nos/html/files.html]
(old website: http://www.cs.bris.ac.uk/Research/Micro/swallow.jsp)


Build requisites
================

* XMOS XDE Tools for compilation: http://www.xmos.com/products/tools

* To build nOS, you will also need the swallow_comms.h and swallow_comms.S files from the
swallow communication module provided by Steve Kerrison.
https://github.com/stevekerrison/sc_swallow_communication