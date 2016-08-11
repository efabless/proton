#!/usr/bin/perl
use Benchmark;
my $t0 = new Benchmark;
my $t1 = new Benchmark;

my $noOfArg = @ARGV;
if($ARGV[0] eq "-h" || $ARGV[0] eq "-help" || $ARGV[0] eq "-HELP"){
}else { 
my $spicefile;
my $inputslew;
my $opcap;
my $output;
  for(my $xx=0;$xx<$noOfArg;$xx++){
    if($ARGV[$xx] eq "-spice_file"){$spicefile= $ARGV[$xx+1];}
    elsif($ARGV[$xx] eq "-input_slew"){$inputslew= $ARGV[$xx+1];} 
    elsif($ARGV[$xx] eq "-opcap"){$opcap = $ARGV[$xx+1];}
    elsif($ARGV[$xx] eq "-output"){$output = $ARGV[$xx+1];} 
  }#for
open(WRITE,">$output");
print WRITE "vin\n";
open(READ,$spicefile);
while(<READ>){
 chomp();
 if($_ =~ /^\s*\*/){next;}
 if($_ =~ /^\s*$/){next;}
 if($_ =~ /^\s*\+/){
   s/\s+$//;
   s/^\s*\+\s*//;
   $previous_line = $previous_line." ".$_;
   next;
 }
 $next_line = $_;
 $previous_line =~ s/^\s*//;
 $previous_line =~ s/\s*$//;
 if($previous_line =~ /.model/i){
   print WRITE "$previous_line\n"; 
 }elsif($previous_line =~ /\.include/){
   print WRITE "$previous_line\n";
 }elsif($previous_line =~ /^\s*.subckt/i){
   print WRITE "$previous_line\n"; 
 }elsif($previous_line =~ /^\s*m/i){
   print WRITE "$previous_line\n";
 }elsif($previous_line =~ /^\s*.end/i){
   print WRITE "$previous_line\n";
 }elsif($previous_line =~ /^\s*.tran/i){
   print WRITE "$previous_line\n";
 } 
 $previous_line = $next_line;
}#while
close(WRITE);
close(READ);
}
my $td = timediff($t1,$t0);
print "script spiceconvert took:",timestr($td),"\n";
