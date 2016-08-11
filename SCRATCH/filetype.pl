#!/usr/bin/perl
use File::Type;
my $ft = File::Type->new();
my $fileList = $ARGV[0];
my @file_list = split(/\,/,$fileList);
foreach my $file (@file_list){
  if(-e $file){
    my $type_from_file = "";
    $type_from_file = $ft->mime_type($file);
    if($type_from_file eq ""){$type_from_file = "UNKNOWN";}
    my @fileName_list = (split(/\//,$file));
    my $fileName = @fileName_list[-1];
    print "FileName: $fileName	Type:\"$type_from_file\"\n"
  }else{print "ERROR: File does not exists\n";}
}
