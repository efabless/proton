#!/usr/bin/perl 
use Benchmark;
my $t0 = new Benchmark;

my $fileName = ""; 
for(my $i =0; $i<=$#ARGV;$i++){
  if($ARGV[$i] eq "-file"){$fileName = $ARGV[$i+1];}
}#for
my $read_subckt = 0;
my $library_name = "";
my $cell_name = "";
my $view_name = "";
my $read_end = 0;

open (READ,$fileName);
  while(<READ>){
  chomp();
  if($_ =~ /^\s+$/){next;}
  $_ =~s/\s+$//;
  if($_ =~ /^\* Library Name:/i){
    $library_name = $_;
    $read_subckt = 0;
    $read_end=0;
  }
  if($_ =~ /^\* Cell Name:/i){
    $cell_name = $_;
    $read_subckt = 0;
    $read_end=0;
  }
  if($_ =~ /^\* View Name:/i){
    $view_name = $_;
    $read_subckt = 0;
    $read_end=0;
  }
  if($_ =~ /^\*\*\*/){
    $read_end =0;
    $read_subckt = 0
  }
  if($_ =~ /^\s*\.subckt/i){
    my $subckt_name = (split(/\s+/,$_))[1];
    open(WRITE,">$subckt_name.sp");
    print WRITE "***************************************************************************\n";
    print WRITE "$library_name\n";
    print WRITE "$cell_name\n";
    print WRITE "$view_name\n";
    print WRITE "***************************************************************************\n";
    $read_subckt = 1;
    $read_end = 0;
  }if($_=~ /^\s*\.ends/i){
    $read_end = 1;
    $read_subckt = 0;
  }
  if($read_subckt == 1 && $read_end == 0){
    print WRITE "$_\n";
  }elsif($read_end == 1){
    print WRITE "$_\n";
  }
}#while
  close(WRITE);                   


my $t1 = new Benchmark;
my $td = timediff($t1,$t0);
print "create_spice_file :",timestr($td),"\n";

