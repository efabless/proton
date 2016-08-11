#!/usr/bin/perl
use Benchmark;
my $t0 = new Benchmark;
my $drupal_temp_path; 
my $fileName = "";
my $cloud_share_path; 
for(my $i =0; $i<=$#ARGV;$i++){
  if($ARGV[$i] eq "-lib"){$fileName = $ARGV[$i+1];}
  if($ARGV[$i] eq "-cloud_share_path"){$cloud_share_path = $ARGV[$i+1];} 
  if($ARGV[$i] eq "-drupal_temp_storage_path"){ $drupal_temp_path = $ARGV[$i+1];}
}#for
my @path_of_file = (split(/\//,$fileName));
my $file_name = pop (@path_of_file);
$file_name =~ s/\..*//g;

if(-e $fileName){
  open(WRITE,">script");
  print WRITE "read_lib -lib $fileName\n";
  print WRITE "create_cell_info_frm_lib\n";
  print WRITE "exit\n";
  system("$cloud_share_path/apps/content/drupal_app/proton_for_gschematic -f script --nolog");
#  system("/home/mansis/Projects/proton/proton -f script --nolog");
  system("mv cell_info.txt $file_name");
  system("cp $file_name $drupal_temp_path/");
  system("rm -rf $file_name");
}else {
  open (WRITE_INFO,">cell_info");
  close(WRITE_INFO);
  system("cp cell_info $drupal_temp_path/");
  system("rm -rf cell_info");
}

my $t1 = new Benchmark;
my $td = timediff($t1,$t0);
print "create_temp_lib_for_gschematic :",timestr($td),"\n";

