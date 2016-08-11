#!/usr/bin/perl -w 
use GDS2;
my $noOfArg = @ARGV;
if($noOfArg < 4 || $ARGV[0] eq '-h' || $ARGV[0] eq '-help' || $ARGV[0] eq '-HELP') {
   print "usage : ./gds2txt.pl   -gds < gds file >\n";
   print "                       -out <output file name>\n";
}else {
   my ($gdsFile, $outFile);
   for(my $i=0; $i<$noOfArg; $i++){
       if($ARGV[$i] eq "-gds"){$gdsFile = $ARGV[$i+1];} 
       if($ARGV[$i] eq "-out"){$outFile = $ARGV[$i+1];} 
   }
   open(WRITE,">$outFile");
   my $gds2File = new GDS2(-fileName=>"$gdsFile");
   while($gds2File -> readGds2Record){
        my $line = $gds2File->returnRecordAsString;
        print WRITE "$line\n";
   }
   $gds2File -> close;
   close(WRITE);
}

