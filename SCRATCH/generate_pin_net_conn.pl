#!/usr/bin/perl
use Benchmark;
my $t0 = new Benchmark;
my $noOfArg = @ARGV;
if($ARGV[0] eq "-h" || $ARGV[0] eq "-help" || $ARGV[0] eq "-HELP"){
  print "Usage : generate_pin_net_conn.pl\n";
  print "      : -input_file <fileName>\n";
}else {
  my $input_file = "";
  for(my $xx=0; $xx<$noOfArg; $xx++){
    if($ARGV[$xx] eq "-input_file"){$input_file = $ARGV[$xx+1];} 
  }#for
  open(READ,"$input_file");
  open(WRITE,">net_conn_info.txt");
  while(<READ>){
    chomp();
    s/^\s*//;
    s/\s+/ /g;
    s/\(//;
    s/\)//;
    my @net_info = (split(/\s+:\s+/,$_));
    my $net = shift @net_info;
    foreach my $data (@net_info){
      my ($inst,$pin) = (split(/\s+/,$data))[0,1];
      if($inst =~ /PIN/i){
        print WRITE "$pin $net\n";
      }else {
        print WRITE "$inst/$pin $net\n";
      }
    }
  }#while
  close(WRITE);
}#else 
my $t1 = new Benchmark;
my $td = timediff($t1, $t0);
print "generate_pin_net_conn took:",timestr($td),"\n";
