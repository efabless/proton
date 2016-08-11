#!/usr/bin/perl
my $noOfArg = @ARGV;
my ($path) = (".");
if($ARGV[0] eq "h" || $ARGV[0] eq "help"){
   print "Usage: ./all_gds2lef.pl -path <path of dir containing spi files (default path is CWD)>\n";
}else{
   for(my $i=0; $i<$noOfArg; $i++){
       if($ARGV[$i] eq "-path"){$path = $ARGV[$i+1];}
   }
   my @gds_files = `find $path -name \\*\\.sp`;
   $count = 0;
   foreach my $file(@gds_files){
      if($count == 1){last;}
      $file =~ s/\s*$//g;
      my $dir = (split(/\//,$file))[-1];
      system("mkdir $dir");
      system("cd $dir");
      system("/home/mansis/Projects/proton/SCRATCH/spice2lib.pl -f $file -p ../user_input_parameter");
      system("cd ..");$count++;
   }
}
