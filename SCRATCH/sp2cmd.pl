#!/usr/bin/perl
use Benchmark;
my $t0 = new Benchmark;

my $fileName = "";
my $output = "";
my $max_number_of_pattern = 1000;
for(my $i =0; $i<=$#ARGV;$i++){
  if($ARGV[$i] eq "-spice_file"){$fileName = $ARGV[$i+1];}
  elsif($ARGV[$i] eq "-output"){$output = $ARGV[$i+1];}
  elsif($ARGV[$i] eq "-max_number_of_pattern"){$max_number_of_pattern = $ARGV[$i+1];}
  elsif($ARGV[$i] eq "-help"){ print "Usage : -spice_file <spice fileName>\n";
                               print "      : -output <fileName>\n";
                               print "      : -max_number_of_pattern <digit>\n";
                             }
}#for
if($max_number_of_pattern > 1000){
  $max_number_of_pattern = 1000;
}
my $out_file = "";
if($output eq ""){
  $out_file = "silverline.cmd";
}else {
  if($output =~ /\.cmd$/){
    $out_file = $output;
  }else {
    $out_file = "$output.cmd";
  }
}
open(WRITE,">script");
print WRITE "read_spice_new -sp $fileName\n";
print WRITE "elaborate\n";
print WRITE "write_spice_file -output silversim.sp --flat --overwrite\n";
print WRITE "create_cmd_file_from_spice -sp silversim.sp -cmd $out_file -max_number_of_pattern $max_number_of_pattern --overwrite\n";
print WRITE "exit\n";
close (WRITE);
system("/home/mansis/Projects/proton/proton -f script --nolog");
#system("/apps/content/drupal_app/proton -f script --nolog");
my $t1 = new Benchmark;
my $td = timediff($t1,$t0);
print "sp2cmd :",timestr($td),"\n";
