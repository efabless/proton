#!/usr/bin/perl
my $rpt_data = "";
my @lef_list = ();
my @verilog_list = ();
my @libfile_list = ();
my @def_list = ();

for(my $i =0 ;$i<=$#ARGV;$i++){
  if($ARGV[$i] eq "-lef"){my $lef_file = $ARGV[$i+1];
                          @lef_list = split(/\,/,$lef_file);
                         }
  if($ARGV[$i] eq "-v"){my $verilogfile = $ARGV[$i+1];
                        @verilog_list = split(/\,/,$verilogfile);
                       }
  if($ARGV[$i] eq "-lib"){my $libfile = $ARGV[$i+1];
                          @libfile_list = split(/\,/,$libfile);
                         }
  if($ARGV[$i] eq "-def"){my $def_file = $ARGV[$i+1];
                          @def_list = split(/\,/,$def_file);
                         }
  if($ARGV[$i] eq "-rpt"){my $rpt = $ARGV[$i+1];
                          my @rpt_list = split(/\,/,$rpt);
                           foreach my $info (@rpt_list){
                             $rpt_data = $rpt_data." --".$info;
                           }
                         }
}#for
#--------------------------------creating tcl file from user input's--------------------------------#
open(WRITE,">rpt.tcl");
foreach my $lef_fileName (@lef_list){
  print WRITE"read_lef -lef $lef_fileName -tech also\n" if($lef_fileName  ne "");
}
foreach my $def_fileName (@def_list){
  print WRITE"read_def -def $def_fileName --all\n"if($def_fileName ne "");
}
foreach my $verilog_fileName (@verilog_list){
  print WRITE"read_verilog -v $verilog_fileName\n"if($verilog_fileName ne "");
}
foreach my $lib_fileName (@libfile_list){
  print WRITE"read_lib -lib $libfile\n"if($lib_fileName ne "");
}
print WRITE"report_netlist_qor $rpt_data\n"if($rpt_data ne "");
print WRITE"exit\n";
#---------------------------------------------------------------------------------------------------#
system("~/Projects/proton/proton -f rpt.tcl");
#---------------------------------------------------------------------------------------------------#
