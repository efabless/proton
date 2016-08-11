#!/usr/bin/perl
use Benchmark;
my $t0 = new Benchmark;

my @lefFileList = ();
my $tcl = "";
my $cloud_share_path = "";

for(my $i=0;$i<=$#ARGV;$i++){
  if($ARGV[$i] eq "-lef"){my $lefFileStr = $ARGV[$i+1];
                          $lefFileStr =~ s/\{|\}//g;
                          push(@lefFileList, split(/\,/, $lefFileStr));
  }
  if($ARGV[$i] eq "-tcl"){$tcl = $ARGV[$i+1];}
  if($ARGV[$i] eq "-cloud_share_path"){$cloud_share_path = $ARGV[$i+1];}
}#for

open(WRITE_TCL,">script");
foreach my $lef (@lefFileList){
  print WRITE_TCL "read_lef -lef $lef -tech also\n";
}
open(READ,$tcl);
while(<READ>){
 chomp();
 print WRITE_TCL "$_\n";
}
print WRITE_TCL "exit\n";
close(READ);
close(WRITE_TCL);

system("/home/mansis/Projects/proton/proton -f script --nolog");

my $t1 = new Benchmark;
my $td = timediff($t1,$t0);
print "script padFrame took:",timestr($td),"\n";

