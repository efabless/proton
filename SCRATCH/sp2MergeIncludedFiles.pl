#!/usr/bin/perl 

my $in_sp_file = $ARGV[0];
if(!(-e $in_sp_file)){
  print "WARN: file  $in_sp_file does not exists\n";
  exit;
}
if(!(-r $in_sp_file)){
  print "WARN: file  $in_sp_file is not readable\n";
  exit;
}
my @in_sp_file_dir_parts = split(/\//,$in_sp_file);
my $sp_file_name = pop @in_sp_file_dir_parts;
my $in_sp_file_dir ;
if(@in_sp_file_dir_parts >0){
  $in_sp_file_dir = join "/", @in_sp_file_dir_parts;
}else {
  $in_sp_file_dir = ".";
}
&call_include_spi_files($in_sp_file, $in_sp_file_dir, $sp_file_name, 0);

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
      print $write_fh "*$_\n";
      my $include_file = (split(/\s+/,$_))[1];
      $include_file =~ s/\"//g;
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
          }else {
            print "WARN: file  $temp_include_file does not exists or it is not readable\n";
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
    system("mv $out_file$count $out_file-include-expanded");
 }
}#sub call_include_spi_files

sub write_data_in_file
{
 my $file_handle = $_[0];
 my $data_file = $_[1];
 my $has_include = 0;
 my $read_fh;
 open($read_fh, $data_file);
 while(<$read_fh>){
   chomp();
   if($_ =~ /^\s*\.include\s+/i){
      $has_include = 1;
   }
   print $file_handle "$_\n";
 }
 close $read_fh;
 return $has_include;
}#sub write_data_in_file
