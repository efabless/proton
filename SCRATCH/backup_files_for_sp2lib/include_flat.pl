#!/usr/bin/perl

my $file = $ARGV[0];
&include_spi_files($file);

sub include_spi_files{
  my $spFile = $_[0];
  my @dir_path = split(/\//,$spFile);
  my $sp_file_name = pop @dir_path;
  my $in_file_dir = join "/", @dir_path if(@dir_path > 0); 
  &call_include_spi_files($spFile, $in_file_dir, $sp_file_name, 0);

}#sub include_spi_files

sub call_include_spi_files{
 my $in_file = $_[0];
 my $dir_path = $_[1];
 my $out_file = $_[2];
 my $count = $_[3];
print "in $in_file | $dir_path | $out_file | $count\n";
 my $read_fh;
 my $write_fh;

 open($read_fh,"$in_file");
 open($write_fh,">$out_file$count");
 while(<$read_fh>){
   chomp();
   print "$_\n";
   if($_ =~ /^\s*\.include\s+/){
      my $include_file = (split(/\s+/,$_))[1];
      $include_file =~ s/\"//g;
      $include_file = $dir_path."/".$include_file if($dir_path ne "");
      if(-e $include_file){
         my $status = &check_include_found($include_file);
         if($status == 1){
            my $has_include = &write_data_in_file($write_fh, $include_file);
            print "has include $has_include\n";
            if($has_include == 1){
               &call_include_spi_files($out_file.$count, $dir_path, $out_file, $count+1);
            }
         }else{
            print $write_fh ".include \"$include_file\"\n";
         }
      }else{
         print "WARN: file  $include_file does not exists\n";
      }
   }else{
      print $write_fh "$_\n";
   }
 }#while
 close $write_fh;
 close $read_fh;
}#sub call_include_spi_files


sub check_include_found{
 my $file = $_[0];
 my $read_fh;
 open($read_fh, $file);
 while(<$read_fh>){
   chomp();
   if($_ =~ (/^\s*\.subckt/i) || (/^\s*x\s*/i)){
      return 1;
   }
 }
 close $read_fh;
 return 0;
}#sub check_include_found

sub write_data_in_file{
 my $file_handle = $_[0];
 my $data_file = $_[1];
 my $has_include = 0;
 my $read_fh;
 open($read_fh, $data_file);
 while(<$read_fh>){
   chomp();
   if($_ =~ /^\s*\.include\s+/){
      $has_include = 1;
   }
   print $file_handle "$_\n";
 }
 close $read_fh;
 return $has_include;
}#sub write_data_in_file
