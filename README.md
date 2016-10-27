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

More information can be found on the efabless web site:

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

	: proton                    ===> launches proton in shell mode
	: proton --nolog --win      ===> launches proton in GUI mode
	: proton --help             ===> prints the launch help message
	: proton -f run.tcl         ===> executes the commands in run.tcl and returns to shell prompt

By default, proton open in non-gui mode. To open GUI from shell mode type "win" or "gui" 



Supported formats
=================================
Most of the popular backend ASIC file formats are supported. LEF, DEF, RTL ( Verilog 2005) , gate-level verilog, Spef etc are supported. 


Features
==========================
Proton has the many of the features of commercial Place and Route tools. We are developing many more actively and ask for community help in giving us feedback and also pitchin to help develop new features
Currently following features have been tested to work

import/read LEF(5.7) , DEF, gate level verilog ( hierarchical and flat), GDS2
export/write  LEF, DEF, gate level verilog, GDS2

	RTL Simulation
	Gate level simulation
	Synthesis
	Interactive Floorplan
	Hierarchical Floorplan and Partition Pin Assignment
	Power Plan
	Placement
	Signal Routing

Use Model
===========================
Proton can be used in following modes

	digital block implementation
	Hierarchical partitining
	digital block modelling for use in mixed signal designs 

Limitations
===========================
Proton has been used on many designs in tapeout mode but requires some understanding of the steps of the flow. It is not a push button tool yet. It offers complete flexibility to manage the design data and in some cases can allow users to delete objects/ instances and nets that can cause design logic to change. It also has limitation on the size of design it can handle , mostly limited by the placement and routing engines used inside the tool. It can be worked around by using proton in a hierarchical flow.

Pure Digital and Mixed Signal designs are handled well in proton. It is not geared to handle Multi Billion transistor SOCs flat. But with some ingenuity, a large design can be pushed through proton system using hierarchical implementation flow.



Contact GitHub API Training Shop Blog About
© 2016 GitHub, Inc. Terms Privacy Security Status Help
