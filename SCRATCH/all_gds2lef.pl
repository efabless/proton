#!/usr/bin/perl
my $noOfArg = @ARGV;
my ($path, $layer_map, $config_file) = (".", "layermap", "configfile");
if($noOfArg < 2 || $ARGV[0] eq "h" || $ARGV[0] eq "help"){
   print "Usage: ./all_gds2lef.pl -path <path of dir containing gds files (default path is CWD)>\n";
   print "                        -layer_map_file <file name (default is layermap>\n";
   print "                        -config_file <file name (default is configfile>\n";
}else{
   for(my $i=0; $i<$noOfArg; $i++){
       if($ARGV[$i] eq "-path"){$path = $ARGV[$i+1];}
       if($ARGV[$i] eq "-layer_map_file"){$layer_map = $ARGV[$i+1];}
       if($ARGV[$i] eq "-config_file"){$config_file = $ARGV[$i+1];}
   }
   my @gds_files = `find $path -name \\*\\.gds`;
   foreach my $file(@gds_files){
      $file =~ s/\s*$//g;
      system("/home/adityap/proj/proton/SCRATCH/gds2lef.pl -layer_map_file $layer_map -config_file $config_file -gds $file");
   }
}
