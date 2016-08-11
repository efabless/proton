#!/usr/bin/perl 
use Benchmark;
my $t0 = new Benchmark;
my $noOfArg = @ARGV;
if($noOfArg < 1 || $ARGV[0] eq '-h' || $ARGV[0] eq '-help' || $ARGV[0] eq '-HELP') {
   print "Usage : ./evaluate_param.pl\n";
   print "                      -file <fileName>\n";
   print "                      -output <output>\n";
   print "                      -top_subckt <top_subckt>\n";
}else{
  my $file;
  my $output;
#  my $dir;
#  my $lib;
  my $top_subckt;
  for(my $i =0; $i<=$#ARGV;$i++){
    if($ARGV[$i] eq "-file"){
      $file = $ARGV[$i+1];
    }elsif($ARGV[$i] eq "-output"){
      $output = $ARGV[$i+1];
    #}elsif($ARGV[$i] eq "-dir"){
    #  $dir = $ARGV[$i+1];
    #}elsif($ARGV[$i] eq "-lib"){
    #  $lib = $ARGV[$i+1]; 
    }elsif($ARGV[$i] eq "-top_subckt"){
      $top_subckt = $ARGV[$i+1]; 
    }
  }#for
  my @dir_path = split(/\//,$file);
  my $sp_file_name = pop @dir_path;

#  if($dir ne "" ){
#    system("/ef/home/mas/Project/proton/SCRATCH/sp2MergeIncludefile_new.pl -dir $dir -lib $lib");
#  }else{
    system("/ef/home/mas/Project/proton/SCRATCH/sp2MergeIncludefile_new.pl -file $file -lib $lib");
#  }
  open (WRITE,">t.tcl");
  print WRITE "read_spice_new -sp $sp_file_name-include.sp\n";
  if($top_subckt ne "" ){
    print WRITE "set_top_module $top_subckt\n";
  }
  print WRITE "elaborate\n";
  print WRITE "evaluate_of_parameter_expression\n";
  print WRITE "write_spice_file -output $output.sp --flat --overwrite\n";
  print WRITE "exit\n";
  system("/ef/home/mas/Project/proton/proton -f t.tcl");
  system ("rm -rf proton.*");
}
my $t1 = new Benchmark;
my $td = timediff($t1, $t0);
print "script evaluate_param took: ",timestr($td),"\n";

