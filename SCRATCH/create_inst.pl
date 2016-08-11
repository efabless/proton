#!/usr/bin/perl
use Benchmark;
my $t0 = new Benchmark;

my $no_of_inst;
my @lef_list;
my $inst_name = "sfuc_inst";
my $net_name_1 = "scan_net";
my $net_name_3 = "cell_out";
my $top_in_pin_name = "in";
my $top_out_pin_name = "out";
my $top_module_name = "";
for(my $i =0; $i<=$#ARGV;$i++){
  if($ARGV[$i] eq "-no_of_inst"){
    $no_of_inst = $ARGV[$i+1];
  }
  if($ARGV[$i] eq "-lef"){
    my $lef = $ARGV[$i+1];
    $lef =~ s/\{|\}//g;
    push(@lef_list, split(/\,/, $lef));
  }
  if($ARGV[$i] eq "-top_module_name"){
    $top_module_name = $ARGV[$i+1];
  }
}
open (WRITE,">t.tcl");
foreach my $lef_file (@lef_list){
  print WRITE "read_lef -lef $lef_file -tech also\n"; 
}
print WRITE "createPseudoTopModule -top $top_module_name -H 2000 -W 2000\n";
print WRITE "createPseudoNet -parentModule $top_module_name -prefix out_1 -source PIN -type wire -wireWidth 1 \n";
my $reset_pin_string = "createPseudoNet -parentModule $top_module_name -prefix reset -source PIN ";
my $CLK_pin_string = "createPseudoNet -parentModule $top_module_name -prefix CLK -source PIN ";
my $Reset_n_pin_string = "createPseudoNet -parentModule $top_module_name -prefix Reset_n -source PIN ";
my $load_pin_string = "createPseudoNet -parentModule $top_module_name -prefix load -source PIN ";
my $prev_inst = "PIN";
my $prev_row = 0;
my $prev_col = 0;
for(my $row=1;$row<=$no_of_inst;$row++){
  my $in_name = "in_".$row;
  my $in_pin_string = "createPseudoNet -parentModule $top_module_name -prefix $in_name -source PIN ";
  for(my $col=$row+1;$col<=$no_of_inst;$col++){
    my $new_inst_1 = $inst_name."_".$row."_".$col;
    print WRITE "createPseudoInstance -inst $new_inst_1 -parent $top_module_name -cell sfuc\n";
    if ($prev_inst eq "PIN"){
      my $new_net_1 = "scan_in";
      print WRITE "createPseudoNet -parentModule $top_module_name -prefix $new_net_1 -source PIN -sink $new_inst_1 -pin D -type wire -wireWidth 1 \n";
    }else{
      my $new_net_1 = $net_name_1."_".$prev_row."_".$prev_col."_".$row."_".$col;
      print WRITE "createPseudoNet -parentModule $top_module_name -prefix $new_net_1 -source $prev_inst -pin Q -sink $new_inst_1 -pin D -type wire -wireWidth 1 \n";
    }
    $in_pin_string .=  " -sink $new_inst_1 -pin in ";
    $prev_inst = $new_inst_1;
    $prev_row = $row;
    $prev_col = $col;
    $reset_pin_string .= " -sink $new_inst_1 -pin reset";
    $CLK_pin_string .= " -sink $new_inst_1 -pin CLK";
    $Reset_n_pin_string .= " -sink $new_inst_1 -pin Reset_n";
    $load_pin_string .= " -sink $new_inst_1 -pin load";
  }
  $in_pin_string .= " -type wire -wireWidth 1 \n";
  print WRITE $in_pin_string;
}
my $new_net_1 = "scan_out";
print WRITE "createPseudoNet -parentModule $top_module_name -prefix $new_net_1 -source $prev_inst -pin Q -sink PIN -type wire -wireWidth 1 \n";
$reset_pin_string .= " -type wire -wireWidth 1 \n";
$CLK_pin_string .= " -type wire -wireWidth 1 \n";
$Reset_n_pin_string .= " -type wire -wireWidth 1 \n";
$load_pin_string .= " -type wire -wireWidth 1 \n";
print WRITE $reset_pin_string;
print WRITE $CLK_pin_string;
print WRITE $Reset_n_pin_string;
print WRITE $load_pin_string;
for(my $col=2;$col<=$no_of_inst;$col++){
  my $out_name = "out_".$col;
  my $out_pin_string = "createPseudoNet -parentModule $top_module_name -prefix $out_name -source PIN ";
  for(my $row=$col-1;$row>=1;$row--){
    my $new_inst_1 = $inst_name."_".$row."_".$col;
    $out_pin_string .=  " -sink $new_inst_1 -pin out ";
  }
  $out_pin_string .= " -type wire -wireWidth 1 \n";
  print WRITE $out_pin_string;
}
print WRITE "commit_module -module $top_module_name\n"; 

print WRITE "write_verilog -output switchfabric.v --hier --overwrite\n";
print WRITE "exit\n";
close (WRITE);
system ("/ef/home/mas/Project/proton/proton -f t.tcl");

my $t1 = new Benchmark;
my $td = timediff($t1,$t0);
print "create_inst :",timestr($td),"\n";
