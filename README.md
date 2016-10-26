      /-----------------------------------------------------------------------------\
      |                                                                             |
      |  Proton is a full feature hierarchical ASIC place and route system          |
      |                                                                             |
      |  Copyright (C) 2014 - 2016  efabless corp                                   |
      |                                                                             |
      |  Permission to use, copy, modify, and/or distribute this software for any   |
      |  purpose with or without fee is hereby granted, provided that the above     |
      |  copyright notice and this permission notice appear in all copies.          |
      |                                                                             |
      |  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES   |
      |  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF           |
      |  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR    |
      |  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES     |
      |  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN      |
      |  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF    |
      |  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.             |
      |                                                                             |
      \-----------------------------------------------------------------------------/

Proton : ASIC Place and Route Suite
===================================

This is a framework for ASIC Place and Route. It uses other open source tools like Iverilog, Yosys, Gray Wolf and Qrouter as engines.
Proton provides a platform to import and export chip data in standard formats ( LEF / DEF/ Verilog / GDS2 ). 
Proton is written in perl and uses many of the packages available on CPAN. The GUI is written in Perl-TK. 


Web Site
========

More information and documentation can be found on the Yosys web site:

	http://www.efabless.com/opensource/proton


Getting Started
===============
clone the latest code from this git repository. You will need to install Iverilog, Yosys, Graywolf and Qrouter separately on your system. Install the perl packages needed by proton from CPAN.
set the following environment variables 
export $PROTON_HOME=/<your-install-dir>/proton
cd $PROTON_HOME
./UTILS/make_tool

Proton can be invoked using the following commands
export PATH=$PROTON_HOME:$PATH
$: proton                    ===> launches proton in shell mode
$: proton --nolog --win      ===> launches proton in GUI mode
$: proton --help             ===> prints the launch help message

By default, proton open in non-gui mode. To open GUI from shell mode type "win" or "gui" 



Unsupported Verilog-2005 Features
=================================


Building the documentation
==========================

Contact GitHub API Training Shop Blog About
© 2016 GitHub, Inc. Terms Privacy Security Status Help
