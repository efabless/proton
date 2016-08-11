#!/usr/bin/perl
use lib "/home/adityap/SOFTWARE/GDS2-2.09/lib";
use GDS2;
use Math::Polygon;

my $noOfArg = @ARGV;
my ($gdsFile, $outFile) = ("", "out1.log");
if($noOfArg < 2 || $_[0] eq '-h' || $_[0] eq '-help' || $_[0] eq '-HELP') {
   print "usage : ./gdsPinCoords -gds < gds file >\n";
   print "                       -out <output file name(default is out1.log)>\n";
}else {
   for(my $i=0 ; $i<=$noOfArg; $i++){
       if($ARGV[$i] eq "-gds"){$gdsFile = $ARGV[$i+1];} 
       if($ARGV[$i] eq "-out"){$outFile = $ARGV[$i+1];} 
   }#for correct no.of Arguments
   my $compact = 0;
   my $text_found = 0;
   my @xy = ();
   my %pin_coords = ();
   my $gds2File = new GDS2(-fileName=>"$gdsFile");
   while ($gds2File -> readGds2Record) {
      my $string = $gds2File-> returnRecordAsString(-compact=>$compact);
      if ($string =~ m/^\s*TEXT/){
          $text_found = 1;
      }elsif($string =~m/^\s*ENDEL/){
          $text_found = 0;
      }
      if($text_found == 1){
         if($gds2File->isXy){
            @xy = $gds2File->returnXyAsArray;
         }elsif($gds2File->isString){
             my $pinName = $gds2File->returnString;
             if(exists $pin_coords{$pinName}){
                my $dup_pin = (split(/\:/,$pinName))[0];
                @{$pin_coords{$dup_pin}} = @xy;
             }else{
                @{$pin_coords{$pinName}} = @xy;
             }
          }else{next;}
      }
   }#while
   my $start_reading = 0;
   my $boundary_found = 0;
   my $layer = "";
   my %pin_poly_coords = ();
   my $gds2File1 = new GDS2(-fileName=>"$gdsFile");
   while ($gds2File1 -> readGds2Record) {
      my $string = $gds2File1-> returnRecordAsString(-compact=>$compact);
      if($string =~ m/^BGNSTR/){
          $start_reading = 1; 
      }elsif($string =~ m/^ENDSTR/){
          $start_reading = 0;
      }elsif(($string =~ m/^\s*BOUNDARY/) && $start_reading == 1){
          $boundary_found = 1; 
      }elsif(($string =~ m/^\s*ENDEL/) && $start_reading == 1){
          $boundary_found = 0;
      }
      if($boundary_found == 1 && $start_reading == 1){
         if($gds2File1->isLayer){
            $layer = $gds2File1->returnLayer;
         }elsif($gds2File1->isXy){
            my @pin_xy = $gds2File1->returnXyAsArray;
            my @p = ();
            for(my $i=0; $i<=$#pin_xy; $i=$i+2){
                push(@p,[$pin_xy[$i],$pin_xy[$i+1]]);
            }
            my $poly = Math::Polygon->new( @p);
            foreach my $pin(keys %pin_coords){
                my @coords = @{$pin_coords{$pin}};
                my $isInside = $poly->contains([$coords[0],$coords[1]]);
                if($isInside == 1){
                   if(exists $pin_poly_coords{$pin}){
                      my @poly_coords = @{$pin_poly_coords{$pin}};
                      push(@poly_coords, [$layer, @pin_xy]);
                      @{$pin_poly_coords{$pin}} = @poly_coords; 
                   }else{
                      @{$pin_poly_coords{$pin}} = ([$layer, @pin_xy]); 
                   }
                }
            }
         }else{next;}
      }#if boundary found 
   }#while
   open (WRITE, ">$outFile");
   foreach my $pin (keys %pin_poly_coords){
     print WRITE"PIN $pin\n";
     my @val = @{$pin_poly_coords{$pin}};
     foreach(@val){
        print WRITE" POLYGON @$_\n";
     }
   }
   close WRITE;
}


