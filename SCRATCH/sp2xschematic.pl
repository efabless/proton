#!/usr/bin/perl
use Benchmark;
my $t0 = new Benchmark;

my $noOfArg = @ARGV; 
my ($spFile_str,$drupal_temp_path,$outfile) = ("","","");
my $output = "";
my $module;
my $loc_value;

if($ARGV[0] eq "-h" || $ARGV[0] eq "-help" || $ARGV[0] eq "-HELP"){
   print"Usage: sp2xschematic -spice_file <sp file name>\n";
}else{
  for(my $xx=0; $xx<$noOfArg; $xx++){
    if($ARGV[$xx] eq "-spice_file"){$spFile_str = $ARGV[$xx+1];}
    if($ARGV[$xx] eq "-output"){
      $outfile = $ARGV[$xx+1];
      if($outfile =~ /\.xschematic/){
        $output = $outfile;
      }else {
        if($outfile eq ""){
          $output = "silversim.xschematic";
        }else {
          $output = "$outfile.xschematic";
        }
      }
    }
    if($ARGV[$xx] eq "-drupal_temp_storage_path"){
      $drupal_temp_path = $ARGV[$xx+1];
    }
  }
open(WRITE,">script_0");
print WRITE "read_spice_new -sp $spFile_str\n";
print WRITE "check_location_exists_in_spice\n";
print WRITE "exit\n";
system("/apps/content/drupal_app/proton -f script_0 --nolog");

open(READ,"loc_check");
while(<READ>){
  chomp();
  if($_ =~/location/){
    ($module,$loc_value) = (split(/\s+/,$_))[0,1];
  }#if
}#while
close(READ);
if(-e "loc_check"){
  system("rm loc_check");
}

if($loc_value == 1){
  open(WRITE,">script_1");
  print WRITE "read_spice_new -sp $spFile_str\n"; 
  print WRITE "set_spice_loc_in_flplan -utilization 10\n";
  print WRITE "edit_module -module $module\n";
  print WRITE "write_edp_dia_for_spice -output $output -W 800 -H 500\n";
  print WRITE "exit\n";
  close(WRITE);
  system("/apps/content/drupal_app/proton -f script_1 --nolog");
}else{
  open(WRITE,">script_1");
  print WRITE "read_spice_new -sp $spFile_str\n"; 
  print WRITE "calc_loc_of_without_run_placement -W 800 -H 500\n";
  print WRITE "set_spice_loc_in_flplan -utilization 10\n";
  print WRITE "edit_module -module $module\n";
  print WRITE "write_edp_dia_for_spice -output $output -W 800 -H 500\n";
  print WRITE "exit\n";
  close(WRITE);
  system("/apps/content/drupal_app/proton -f script_1 --nolog");
}
#system("scp -i /apps/scp_key -o StrictHostKeyChecking=no *.xschematic root\@192.168.20.20:/var/www/html/drupal/$drupal_temp_path/");
#system("ssh -i /apps/scp_key -o StrictHostKeyChecking=no root\@192.168.20.20 'chown apache:apache /var/www/html/drupal/$drupal_temp_path/*'");
}#else
my $t1 = new Benchmark;
my $td = timediff($t1, $t0);
print "script sp2xschematic took:",timestr($td),"\n";
