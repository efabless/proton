#!/usr/bin/perl
use Benchmark;
my $t0 = new Benchmark;
my $noOfArg = @ARGV;
if($ARGV[0] eq "-h" || $ARGV[0] eq "-help" || $ARGV[0] eq "-HELP"){
  print "Usage : generate_sdef_for_inst.pl\n";
  print "      : -input_file<fileName>\n";
}else {
  my $input_file = "";
  for(my $xx=0; $xx<$noOfArg; $xx++){
    if($ARGV[$xx] eq "-input_file"){$input_file = $ARGV[$xx+1];} 
  }#for
  open(READ,"$input_file");
  open(WRITE,">inst_bbox.sdef");
  while(<READ>){
    chomp();
    s/^\s*//;
    s/\s+/ /g;
    s/\(//;
    s/\)//;
    my ($inst,$cellref,$status,$llx,$lly,$orient) = (split(/\s+/,$_))[0,1,2,3,4,5];
    my $urx = $llx+2000; 
    my $ury = $lly+2000; 
    print WRITE "INST $inst $cellref $llx $lly $urx $ury $status\n"; 
  }#while
  close(WRITE);
}#else 
my $t1 = new Benchmark;
my $td = timediff($t1, $t0);
print "generate_sdef_for_inst took:",timestr($td),"\n";

