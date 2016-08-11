#!/usr/bin/perl
my ($inFile, $outFile);
my $dbu = 1000;
my $offsetX = 0.68; #in micron
my $offsetY = 0.68; #in micron
my $gridSpacing = 0.48; #in micron
my $extLen = 8;#in micron

if(@ARGV < 4 || $ARGV[0] eq "-help" || $ARGV[0] eq "-h" || $ARGV[0] eq "-HELP"){
   print "Usage: ./preIRoute.pl -input <data file>\n";
   print "                      -output <output def file>\n";
   print "                      -dbu <db unit>>\n";
   print "                      -offset <routing grid offset>>\n";
   print "                      -spacing <routing grid spacing>>\n";
}else{
   for(my $i=0; $i<=$#ARGV; $i++){
       if($ARGV[$i] eq "-input"){$inFile = $ARGV[$i+1];}
       if($ARGV[$i] eq "-output"){$outFile = $ARGV[$i+1];}
       if($ARGV[$i] eq "-dbu"){$dbu = $ARGV[$i+1];}    
       if($ARGV[$i] eq "-offsetX"){$offsetX = $ARGV[$i+1];}    
       if($ARGV[$i] eq "-offsetY"){$offsetY = $ARGV[$i+1];}    
       if($ARGV[$i] eq "-spacing"){$gridSpacing = $ARGV[$i+1];}    
   }
   
   $offsetX *= $dbu;
   $offsetY *= $dbu;
   $gridSpacing *= $dbu;
   $extLen *= $dbu;

   open(WRITE_DEF, ">$outFile");
   open(READ_DATA, "$inFile");

   print WRITE_DEF "VERSION 5.7 \;\n";
   print WRITE_DEF "NAMESCASESENSITIVE ON \;\n";
   print WRITE_DEF "DIVIDERCHAR \"\/\" \;\n";
   print WRITE_DEF "BUSBITCHARS \"\[\]\" \;\n";
   print WRITE_DEF "DESIGN test \;\n";
   print WRITE_DEF "UNITS DISTANCE MICRONS $dbu \;\n";
   #print WRITE_DEF "DIEAREA ( 0 0 ) ( 15500000 11510000 ) \;\n";

   print WRITE_DEF "VIAS 2 \;\n";
   print WRITE_DEF "- via1Array_m \n \+ VIARULE via1Array \n \+ CUTSIZE 360 360 \n \+ LAYERS METAL1 VIA12 METAL2 \n \+ CUTSPACING 0 0 \n \+ ENCLOSURE 0 0 0 0 \n \+ ORIGIN 0 0 \n\;\n ";
   print WRITE_DEF "- via1Array_t \n \+ VIARULE via1Array \n \+ CUTSIZE 360 360 \n \+ LAYERS METAL1 VIA12 METAL2 \n \+ CUTSPACING 0 0 \n \+ ENCLOSURE 0 0 0 0 \n \+ ORIGIN 0 -250 \n \;\n ";
   print WRITE_DEF " \n END VIAS \n";

   my $lines;
   $lines++ while<READ_DATA>;
   print WRITE_DEF "SPECIALNETS $lines \;\n";
   close READ_DATA;

   open(READ_DATA, "$inFile");
   while(<READ_DATA>){
     chomp();  
     if($_ =~ /^\s*#/){ 
        next;
     }
     if($_ =~ /^\s*$/){
        next;
     }
     my ($netName, $x1, $y1, $x2, $y2, $routeSep, $routeWidth, $shieldWidth, $shieldSep, $layerHor, $layerVer, @netExts) = split(/\s+/,$_);
     $x1 *= $dbu;
     $y1 *= $dbu;
     $x2 *= $dbu;
     $y2 *= $dbu;
     $routeSep *= $dbu;
     $routeWidth *= $dbu;
     $shieldWidth *= $dbu;
     $shieldSep *= $dbu;
     $_ *= $dbu for @netExts; 
  
     my $signal_type = 'SIGNAL';
     if($netName =~ /vss|gnd/i){
        $signal_type = 'GROUND';
     }elsif($netName =~ /vdd/i){
        $signal_type = 'POWER';
     }

     print WRITE_DEF "  - $netName\n";

     if($y1 == $y2){ #for horizontal stripe

        if(($x1 - $offsetX)%$gridSpacing != 0){
            $x1 = int(($x1 -$offsetX)/$gridSpacing + 0.5)*$gridSpacing + $offsetX; #added 0.5 to round the value
            $x2 = int(($x2 -$offsetX)/$gridSpacing + 0.5)*$gridSpacing + $offsetX; #added 0.5 to round the value
        }

        ################### added for special case ######################
        if($netName =~ /clkn/){
           $x1 += (2*$gridSpacing);
           $x2 += (2*$gridSpacing);
        }
        #################################################################

        if(($y1 - $offsetY)%$gridSpacing != 0){
            $y1 = int(($y1 -$offsetY)/$gridSpacing + 0.5)*$gridSpacing + $offsetY; #added 0.5 to round the value
        }

        my $midX = ($x1+$x2)/2;
        my $ury = $y1+$routeSep;
        #my $shieldY = $ury + $shieldSep;

        if(($midX - $offsetX)%$gridSpacing != 0){
            $midX = int(($midX -$offsetX)/$gridSpacing + 0.5)*$gridSpacing + $offsetX; #added 0.5 to round the value
        }
        
        print WRITE_DEF "\t \+ ROUTED $layerHor $routeWidth + SHAPE COREWIRE ( $x1 $y1 ) ( $midX * ",sprintf("%.0f",$x2-$midX)," ) via1Array_m\n"; #lower horizontal stripe
        print WRITE_DEF "\t NEW $layerVer $routeWidth + SHAPE COREWIRE ( $midX ",$y1-$routeWidth/2," ) ( * ",$ury+$routeWidth/2," ) via1Array_t\n";#middle vertical stripe
        print WRITE_DEF "\t NEW $layerHor $routeWidth + SHAPE COREWIRE ( $x1 $ury ) ( $x2 * )\n";#upper horizontal stripe
        
        my $yy = $y1 - $extLen;
        foreach my $xx (@netExts){
           if(($xx - $offsetX)%$gridSpacing != 0){
               $xx = int(($xx -$offsetX)/$gridSpacing + 0.5)*$gridSpacing + $offsetX; #added 0.5 to round the value
           }
           if(($xx-$routeWidth/2) < $x1){ 
              $xx += $gridSpacing while(($xx-$routeWidth/2) < $x1);
           }elsif(($xx+$routeWidth/2) > $x2){ 
              $xx -= $gridSpacing while(($xx+$routeWidth/2) > $x2);
           }
           print WRITE_DEF "\t NEW $layerVer $routeWidth + SHAPE COREWIRE ( $xx ",$yy-$routeWidth/2," ) ( * ",$y1+$routeWidth/2," ) via1Array_t\n";
        }
        
        #print WRITE_DEF "\t \+ SHIELD VSS $layerHor $shieldWidth ( $x1 $shieldY ) ( $x2 * )\n";#shielded net

     }elsif($x1 == $x2){ #for vertical stripe

        if(($y1 - $offsetY)%$gridSpacing != 0){
            $y1 = int(($y1 -$offsetY)/$gridSpacing + 0.5)*$gridSpacing + $offsetY; #added 0.5 to round the value
            $y2 = int(($y2 -$offsetY)/$gridSpacing + 0.5)*$gridSpacing + $offsetY; #added 0.5 to round the value
        }

        if(($x1 - $offsetX)%$gridSpacing != 0){
            $x1 = int(($x1 -$offsetX)/$gridSpacing + 0.5)*$gridSpacing + $offsetX; #added 0.5 to round the value
        }

        my $midY = ($y1+$y2)/2;
        my $urx = $x1+$routeSep;
        #my $shieldX = $urx + $shieldSep;

        if(($midY - $offsetY)%$gridSpacing != 0){
            $midY = int(($midY -$offsetY)/$gridSpacing + 0.5)*$gridSpacing + $offsetY; #added 0.5 to round the value
        }

        print WRITE_DEF "\t \+ ROUTED $layerVer $routeWidth + SHAPE COREWIRE ( $x1 $y1 ) ( * $midY ",sprintf("%.0f",$y2-$midY)," ) via1Array_m\n"; #left vertical stripe
        print WRITE_DEF "\t NEW $layerHor $routeWidth + SHAPE COREWIRE ( ",$x1-$routeWidth/2," $midY ) ( ",$urx+$routeWidth/2," * ) via1Array_t\n";#middle horizontal stripe
        print WRITE_DEF "\t NEW $layerVer $routeWidth + SHAPE COREWIRE ( $urx $y1 ) ( * $y2 )\n";#right vertical stripe

        my $xx = $x1 - $extLen;
        foreach my $yy (@netExts){
           if(($yy - $offsetY)%$gridSpacing != 0){
               $yy = int(($yy -$offsetY)/$gridSpacing + 0.5)*$gridSpacing + $offsetY; #added 0.5 to round the value
           }
           if(($yy-$routeWidth/2) < $y1){ 
              $yy += $gridSpacing;
           }elsif(($yy+$routeWidth/2) > $y2){ 
              $yy -= $gridSpacing;
           }
           print WRITE_DEF "\t NEW $layerVer $routeWidth + SHAPE COREWIRE ( ",$xx-$routeWidth/2," $yy ) ( ",$x1+$routeWidth/2," * ) via1Array_t\n";
        }

        #print WRITE_DEF "\t \+ SHIELD VSS $layerVer $shieldWidth ( $shieldX $y1 ) ( * $y2 )\n";#shielded net
     }

     print WRITE_DEF "\t + USE $signal_type\n";
     print WRITE_DEF " \t\;\n";
     
   }
   print WRITE_DEF "END SPECIALNETS\n";
   print WRITE_DEF "END DESIGN\n";

   close(READ_DATA);
   close(WRITE_DEF);

}
