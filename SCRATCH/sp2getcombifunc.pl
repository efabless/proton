#!/usr/bin/perl 
use Benchmark;
my $t0 = new Benchmark;

my $file = "";
my $in_unit = "";
my $drupal_temp_path; 

for(my $i =0; $i<=$#ARGV;$i++){
  if($ARGV[$i] eq "-spice_file"){$file = $ARGV[$i+1];}
  elsif($ARGV[$i] eq "-in_unit"){$in_unit = $ARGV[$i+1];}
  elsif($ARGV[$i] eq "-drupal_temp_storage_path"){$drupal_temp_path = $ARGV[$i+1];}
  elsif($ARGV[$i] eq "--help"){ print "Usage : spGetCombiFunc\n"; 
                                print "      : -spice_file <spice fileName>\n";
                                print "      : -in_unit\n";
                                print "      : --help\n";
                              }
}#for
#------------------------------------------------------------------------------------#
open(WRITE_SCRIPT,">script");
print WRITE_SCRIPT "read_spice_new -sp $file\n";
print WRITE_SCRIPT "check_file_is_sp -sp $file\n";
print WRITE_SCRIPT "write_spice_file -output silversim.sp --hier --vector_bit_blast --add_top_instance --add_spice_missing_port --global_change_pin_vss_to_gnd --add_first_blank_line --notWriteEmptyModule --add_global_vdd_and_gnd -in_unit $in_unit -out_unit micron\n";
print WRITE_SCRIPT "exit\n";
close (WRITE_SCRIPT);
system("/home/mansis/Projects/proton/proton -f script --nolog");

system("/home/mansis/Projects/proton/SCRATCH/sp2func.pl -spice_file $file");
#system("scp -i /apps/scp_key -o StrictHostKeyChecking=no funcgenlib root\@192.168.20.20:/var/www/html/drupal/$drupal_temp_path/");
#system("ssh -i /apps/scp_key -o StrictHostKeyChecking=no root\@192.168.20.20 'chown apache:apache /var/www/html/drupal/$drupal_temp_path/*'");
my @file_list = (split(/\//,$file));
my $fileName = pop (@file_list);
system("rm -rf $fileName*");
my $t1 = new Benchmark;
my $td = timediff($t1, $t0);
print "script sp2getcombifunc took: ",timestr($td),"\n";
