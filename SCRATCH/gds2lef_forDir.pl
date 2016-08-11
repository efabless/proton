#!/usr/bin/perl
my $noOfArg = @ARGV;
my ($path, $layerMapFile, $configFile, $tolerance) = ("", "", "", "", 0.0001);
my ($uu,$dbu);
if($noOfArg < 6 || $ARGV[0] eq '-h' || $ARGV[0] eq '-help' || $ARGV[0] eq '-HELP') {
   print "usage : ./gds2lef_forDir.pl   -path < gds file >\n";
   print "                              -layer_map_file <input layer map file>\n";
   print "                              -config_file <input config file>\n";
   print "                              -tolerance <tolerance for floating numbers (default value is 0.0001)>\n";
}else {
   for(my $i=0 ; $i<$noOfArg; $i++){
       if($ARGV[$i] eq "-path"){$path = $ARGV[$i+1];} 
       if($ARGV[$i] eq "-layer_map_file"){$layerMapFile = $ARGV[$i+1];} 
       if($ARGV[$i] eq "-config_file"){$configFile = $ARGV[$i+1];} 
       if($ARGV[$i] eq "-tolerance"){$tolerance = $ARGV[$i+1];} 
   }#for correct no.of Arguments
   my @gdsFiles = `find  $path -name \\*\\.gds`; 
   foreach my $file (@gdsFiles){
     chomp($file);
     #my ($file_name) = (split(/\//,$file))[-1];
     #my ($main) = (split(/\./,$file_name))[0];
     #print "read_lef -lef $main.lef\n";
     print "\ngds is $file\n";
     system("$ENV{PROTON_HOME}/SCRATCH/gds2lef_forBlock.pl -gds $file -layer_map_file $layerMapFile -config_file $configFile");
   }
}

