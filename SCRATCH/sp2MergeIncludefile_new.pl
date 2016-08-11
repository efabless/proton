#!/usr/bin/perl 
use Benchmark;
my $t0 = new Benchmark;

my $fileName = "";
my $input_dir = "";
my @lib_arr = ();
for(my $i =0; $i<=$#ARGV;$i++){
  if($ARGV[$i] eq "-file"){$fileName = $ARGV[$i+1];}
  elsif($ARGV[$i] eq "-dir"){$input_dir = $ARGV[$i+1];}
  elsif($ARGV[$i] eq "-lib"){my $input_lib = $ARGV[$i+1];
	                     $input_lib =~ s/\{\s*//; 
	                     $input_lib =~ s/\s*\}//; 
	                     @lib_arr = split(/\,/,$input_lib);
                            }
}#for

my @spifiles = ();

if($input_dir ne ""){
  @spifiles = `find  -L $input_dir -name \\*\\.spi -o -name \\*\\.sp -o -name \\*\\.spx -o -name \\*\\.spx\\* ! -name \\*\\.pxi ! -name \\*\\.pex`;
}
if($fileName ne ""){
  push(@spifiles,$fileName);
}
my @cnt_arr = ();
foreach my $filename (@spifiles){
  chomp($filename);
#  my @dir_path = split(/\//,$filename);
#  pop @dir_path;
  my $include_flat = &include_spi_files($filename);
}#foreach
##################################################################################################################
sub include_spi_files{
  my $spFile = $_[0];
  my @dir_path = split(/\//,$spFile);
  my $sp_file_name = pop @dir_path;
  my $in_file_dir = join "/", @dir_path if(@dir_path > 0); 
  my $out_file = &call_include_spi_files($spFile, $in_file_dir, $sp_file_name, 0);
  return($out_file); 
}#sub include_spi_files

sub call_include_spi_files
{
 my $in_file = $_[0];
 my $in_file_dir = $_[1];
 my $out_file = $_[2];
 my $count = $_[3];
 my $hier = 0;
 my $read_fh;
 my $write_fh;

 open($read_fh,"$in_file");
 open($write_fh,">$out_file$count");
 while(<$read_fh>){
   chomp();
   if($_ =~ /^\s*\.include\s+/i){
      #print $write_fh "*$_\n";
      my $include_file = (split(/\s+/,$_))[1];
      $include_file =~ s/\"//g;
      $include_file =~ s/\'//g;
      $include_file =~ s/\s//g;
      if($include_file !~ /^\//){
        my $temp_include_file ;
        $temp_include_file = $in_file_dir."/".$include_file ;
        if((-e $temp_include_file) && (-r $temp_include_file)){
          $include_file = $temp_include_file ;
        }else {
          my $curr_work_dir = `pwd`;
          chomp($curr_work_dir);
          $temp_include_file = $curr_work_dir."/".$include_file ;
          if((-e $temp_include_file) && (-r $temp_include_file)){
            $include_file = $temp_include_file ;
          #}elsif(){
           }elsif ($#lib_arr >= 0){
            $temp_include_file = $include_file;
            foreach my $input_lib (@lib_arr){
              my @spifiles = `find  -L $input_lib -name \\*\\.spi -o -name \\*\\.sp -o -name \\*\\.spx -o -name \\*\\.spx\\* ! -name \\*\\.pxi ! -name \\*\\.pex`;
              foreach my $spi_file (@spifiles){
                if($spi_file eq "."|| $spi_file eq ".."){next;}
                chomp($spi_file);
                my $temp_full_file_name = $spi_file;
                my $temp_file_name = (split(/\//,$temp_full_file_name))[-1];
                print "$temp_$include_file => $temp_file_name\n";
                if($temp_include_file =~ /^$temp_file_name$/){ 
                  $include_file = $temp_full_file_name ;
                }else {
                  print "WARN : 001 : file $temp_include_file does not exists or it is not readable\n";
                }
              }#foreach 
            }#foreach 
          }else {
            print "WARN : 002 : file $temp_include_file does not exists or it is not readable\n";
            next;
          }
        }
      }
      my $next_has_include = &write_data_in_file($write_fh, $include_file);
      if($next_has_include == 1){
         $hier = 1;
      }
   }else{
      print $write_fh "$_\n";
   }
 }#while
 close $write_fh;
 close $read_fh;
 if($hier > 0){
    &call_include_spi_files($out_file.$count, $in_file_dir, $out_file, $count+1);
    system("rm -rf  $out_file$count");
 }else{
    my $cnt = `grep -iR subckt  $out_file$count | wc -l`;
    $cnt =~s/\s+//;
    push(@cnt_arr,$cnt); 
    my @sort_arr = sort{ $a <=> $b} @cnt_arr;
    if($sort_arr[-1] == $cnt){
      system("mv $out_file$count $out_file-include.sp");
    }else {
      system("rm -rf  $out_file$count");
    }
 }
}#sub call_include_spi_files

sub write_data_in_file
{
 my $file_handle = $_[0];
 my $data_file = $_[1];
 my @dir_path = split(/\//,$data_file);
 pop @dir_path;
 my $data_file_dir = join "/", @dir_path if(@dir_path > 0); 
 my $has_include = 0;
 my $read_fh;
 open($read_fh, $data_file);
 while(<$read_fh>){
   chomp();
   if($_ =~ /^\s*\.include\s+/i){
      my $include_file = (split(/\s+/,$_))[1];
      $include_file =~ s/\"//g;
      $include_file =~ s/\s//g;
      if($include_file !~ /^\//){
        my $temp_include_file ;
        $temp_include_file = $data_file_dir."/".$include_file ;
        if((-e $temp_include_file) && (-r $temp_include_file)){
          $include_file = $temp_include_file ;
          my $include_file_line = ".include " . $temp_include_file ;
          print $file_handle "$include_file_line\n";
          $has_include = 1;
          next;
        }
        $has_include = 1;
      }
   }
   print $file_handle "$_\n";
 }
 close $read_fh;
 return $has_include;
}#sub write_data_in_file
#------------------------------------------------------------------------------------------------------#
sub check_include {
my $file = $_[0];
my $include = 0;
open(READ,$file);
while (<READ>){
chomp();
if($_ =~ /^\s*\.include\s+/i){
  $include = 1;
}else {
  $include = 0;
}
}#while
return($include);
}#sub check_include
#------------------------------------------------------------------------------------------------------#

my $t1 = new Benchmark;
my $td = timediff($t1, $t0);
print "Command sp2MergeIncludefile.pl took:",timestr($td),"\n";

