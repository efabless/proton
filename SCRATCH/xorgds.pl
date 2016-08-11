#!/usr/bin/perl
#use warnings;
use GDS2;
use Math::Clipper ':all';
use Math::Polygon;
use Math::Polygon::Calc;
use Math::Polygon::Transform;
use Benchmark;
my $t0 = new Benchmark;

my $noOfArg = @ARGV;

my @gdsFiles = ();
my $layerStr = "";
my $outFile = 'xor';

if($noOfArg < 4 || $ARGV[0] eq '-h' || $ARGV[0] eq '-help' || $ARGV[0] eq '-HELP') {
   print "usage : ./xorgds.pl   -gds <gds1,gds2>\n";
   print "                      -layer <num1,num2,num3,.....>\n";
   print "                      -output <out gds file>\n";
}else {
   for(my $i=0 ; $i<$noOfArg; $i++){
       if($ARGV[$i] eq "-gds"){
          my $gdsFileStr = $ARGV[$i+1];
          $gdsFileStr =~ s/\{|\}//g;
          @gdsFiles =  split(/\,/, $gdsFileStr);
       } 
       if($ARGV[$i] eq "-layer"){
          $layerStr = $ARGV[$i+1];
       } 
       if($ARGV[$i] eq "-output"){
          $outFile = $ARGV[$i+1];
       } 
   }#for correct no.of Arguments
     
   my ($libName, $uu, $dbu, $cell) = ("", "", "", "");
   for(my $i=0; $i<2; $i++){
       ($libName, $uu, $dbu, $cell) = &read_gds_layer_polygon('-gds', $gdsFiles[$i], '-layer', $layerStr);
   }

   my @layers = split(/\,/, $layerStr);
   #----------------------------- commented after adding CT_XOR Math::Clipper function ------------------------------#
   #my $script = $ENV{PROTON_HOME}."/SCRATCH/rect2polygon_diff_two_files.pl";
   ##my $script = "/apps/content/drupal_app/rect2polygon_diff_two_files";
   #foreach my $layer(@layers){
   #   my $fileName1 = (split(/\//,$gdsFiles[0]))[-1];
   #   my $fileName2 = (split(/\//,$gdsFiles[1]))[-1];
   #   my $cmdLine = $script." ".$fileName1."_layer_".$layer." ".$fileName2."_layer_".$layer." xor xorOutLayer".$layer;
   #   system("$cmdLine");
   #}
   foreach my $layer(@layers){
      my $fileName1 = (split(/\//,$gdsFiles[0]))[-1];
      my $fileName2 = (split(/\//,$gdsFiles[1]))[-1];
      write_layer_xor($fileName1."_layer_".$layer, $fileName2."_layer_".$layer,  "xorOutLayer".$layer);
   }
   #-----------------------------------------------------------------------------------------------------------------#
   
   &write_xor_gds($libName, $uu, $dbu, $cell, \@layers, $outFile); 
   

}#if correct num of arg

my $tfinal = new Benchmark;
my $tdfinal = timediff($tfinal, $t0);
print "script xorgds took:",timestr($tdfinal),"\n";

##############################################################################################
################### subroutine to read given layer polygons  of GDS file #####################
##############################################################################################
sub read_gds_layer_polygon{
 my $noOfArg = @_;
 my $gds_read_start_time = new Benchmark;
 if($noOfArg < 4 || $_[0] eq '-h' || $_[0] eq '-help' || $_[0] eq '-HELP') {
    print "usage :read_gds_layer_polygon  -gds <gds1,gds2>\n";
    print "                               -layer <num1,num2,num3,.....>\n";
 }else {
    my $gdsFile = "";
    my %gdsLayerHash = ();
    for(my $i=0 ; $i<$noOfArg; $i++){
        if($_[$i] eq "-gds"){
           $gdsFile = $_[$i+1];
        } 
        if($_[$i] eq "-layer"){
           my $layerStr = $_[$i+1];
           $layerStr =~ s/\{|\}//g;
           my @gdsLayers =  split(/\,/, $layerStr);

           foreach my $layer(@gdsLayers){
              $gdsLayerHash{$layer} = 0;
           }
        } 
    }#for correct no.of Arguments
   
    my ($fileName) = (split(/\//,$gdsFile))[-1];
   
    my %CELL_POLYGONS = ();
    my %PIN_TEXT_COORDS = ();
    my %AREF_DATA = ();
    my %SREF_DATA = ();
    my %cell_hash = ();

    my $string_found = 0;
    my $boundary_found = 0;
    my $path_found = 0;
    my $node_found = 0;
    my $box_found = 0;
    my $text_found = 0;
    my $aref_found = 0;
    my $sref_found = 0;
    my $compact = 0;



    my $gds2File = new GDS2(-fileName=>"$gdsFile");
    my ($libName, $uu, $dbu) = ("", 1, 1);
    my ($string_name, $layer_name, $boundary_data_type, $path_layer, $path_data_type, $path_type, $path_width, $path_bgnExtn, $path_endExtn, $path_unitWidth, $path_xyInt);
    my ($sname, $text_layer, $textType, $presentation, $strans, $mag, $angle, $col, $row, $sname1, $sref_strans, $sref_mag, $sref_angle);
    my @pin_coords = ();
    my @total_poly = ();
    my @aref_data = ();
    my @sref_data = ();
    my @xy = ();

    while ($gds2File->readGds2Record) {
      if($gds2File->isLibname){
         $libName = (split(/\s+/,$gds2File->returnRecordAsString))[1];
         $libName =~ s/\'//g;
      }elsif($gds2File->isUnits){
        ($uu,$dbu) = $gds2File->returnUnitsAsArray;
      }elsif($gds2File->isBgnstr){
         $string_found = 1;
         $string_name = "";
         @pin_coords = ();
         @total_poly = ();
         @aref_data = ();
         @sref_data = ();
      }elsif($gds2File->isEndstr){
         @{$CELL_POLYGONS{$string_name}}= @total_poly if(@total_poly > 0);
         @{$PIN_TEXT_COORDS{$string_name}}= @pin_coords if(@pin_coords > 0);
         @{$AREF_DATA{$string_name}}= @aref_data if(@aref_data > 0);
         @{$SREF_DATA{$string_name}}= @sref_data if(@sref_data > 0);
         $string_found = 0;
      }elsif($gds2File->isBoundary){
         $boundary_found = 1;
         $layer_name = "";
         $boundary_data_type = "";
      }elsif($gds2File->isPath){
         $path_found = 1;
         $path_layer = 0;
         $path_data_type = "";
         $path_type = 0;
         $path_width = 0.0;
         $path_bgnExtn = 0;
         $path_endExtn = 0;
         #$path_unitWidth = "";
         #$path_xyInt = "";
      }elsif($gds2File->isNode){
         $node_found = 1;
         print "WARN:NODE format is found. We are not supporting this\n";
      }elsif($gds2File->isBox){
         $box_found = 1;
         print "WARN:BOX format is found. We are not supporting this\n";
      }elsif($gds2File->isText){
         $text_found = 1;
         $text_layer = "";
         $textType = "";
         $presentation = 0000000000000000;
         $strans = 0000000000000000;
         $mag = 1;
         @xy = ();
      }elsif($gds2File->isAref){
         $aref_found = 1;
         $sname = "";
         $strans = 0000000000000000;
         $mag = 1;
         $angle = 0;
         $col = 0;
         $row = 0;
      }elsif($gds2File->isSref){
         $sref_found = 1;
         $sname1 = "";
         $sref_strans = 0000000000000000;
         $sref_mag = 1;
         $sref_angle = 0;
      }elsif($gds2File->isEndel){
         $boundary_found = 0;
         $path_found = 0;
         $node_found = 0;
         $box_found = 0;
         $text_found = 0;
         $aref_found = 0;
         $sref_found = 0;
      }
      if($string_found == 1){
         if($gds2File->isStrname){
            $string_name = $gds2File->returnStrname;
            if(exists $cell_hash{$string_name}){
               my $val = $cell_hash{$string_name};
               $cell_hash{$string_name} = $val+1;
            }else{
               $cell_hash{$string_name} = 0;
            }
         }elsif($boundary_found == 1){
            if($gds2File->isLayer){
               $layer_name = $gds2File->returnLayer;
               if(!exists $gdsLayerHash{$layer_name}){
                  $boundary_found = 0;
               }
            }elsif($gds2File->isDatatype){
               $boundary_data_type = $gds2File->returnDatatype;
            }elsif($gds2File->isXy){
               my @poly_coords = $gds2File->returnXyAsArray;
               $_ *= $uu for @poly_coords;
               push(@total_poly, [$layer_name,  @poly_coords]);
            }else{next;}
         }elsif($path_found == 1){
            if($gds2File->isLayer){
               $path_layer = $gds2File->returnLayer;
               if(!exists $gdsLayerHash{$layer_name}){
                  $path_found = 0;
               }
            }elsif($gds2File->isDatatype){
               $path_data_type = $gds2File->returnDatatype;
            }elsif($gds2File->isPathtype){
               $path_type = $gds2File->returnPathtype;
            }elsif($gds2File->isWidth){
               $path_width = $gds2File->returnWidth;
               $path_width = $path_width * $uu;
            }elsif($gds2File->isBgnextn){
               $path_bgnExtn = $gds2File->returnBgnextn;
               $path_bgnExtn = $path_bgnExtn * $uu;
            }elsif($gds2File->isEndextn){
               $path_endExtn = $gds2File->returnEndextn;
               $path_endExtn = $path_endExtn * $uu;
            }elsif($gds2File->isXy){
               my @path_coords = $gds2File->returnXyAsArray;
               $_ *= $uu for @path_coords;
               push(@total_poly, [$path_layer, xformPathSegToPolygon(\@path_coords,$path_data_type, $path_type, $path_width, $path_bgnExtn, $path_endExtn)]);
            }else{next;}
         }elsif($text_found == 1){
            if($gds2File->isXy){
               @xy = $gds2File->returnXyAsArray;
               $_ *= $uu for @xy;
            }elsif($gds2File->isLayer){
               $text_layer = $gds2File->returnLayer;
            }elsif($gds2File->isTexttype){
               $textType = $gds2File->returnTexttype;
            }elsif($gds2File->isPresentation){
               my $string = $gds2File->returnRecordAsString(-compact=>$compact);
               $string =~ s/^\s+//g;
               $presentation = (split(/\s+/,$string))[1]; 
            }elsif($gds2File->isStrans){
               my $string = $gds2File->returnRecordAsString(-compact=>$compact);
               $string =~ s/^\s+//g;
               $strans = (split(/\s+/,$string))[1]; 
            }elsif($gds2File->isMag){
               my $string = $gds2File->returnRecordAsString(-compact=>$compact);
               $string =~ s/^\s+//g;
               $mag = (split(/\s+/,$string))[1]; 
            }elsif($gds2File->isString){
               my $pinName = $gds2File->returnString;
               push(@pin_coords, [$pinName, $text_layer, $textType, $presentation, $strans, $mag, @xy]);
            }else{next;}
         }elsif($aref_found == 1){
            if($gds2File->isSname){
               $sname = $gds2File->returnSname;
               if(exists $cell_hash{$sname}){
                  my $val = $cell_hash{$sname};
                  $cell_hash{$sname} = $val+1;
               }else{
                  $cell_hash{$sname} = 0;
               }
            }elsif($gds2File->isStrans){
               my $string = $gds2File->returnRecordAsString(-compact=>$compact);
               $string =~ s/^\s+//g;
               $strans = (split(/\s+/,$string))[1]; 
            }elsif($gds2File->isMag){
               my $string = $gds2File->returnRecordAsString(-compact=>$compact);
               $string =~ s/^\s+//g;
               $mag = (split(/\s+/,$string))[1]; 
            }elsif($gds2File->isAngle){
               my $string = $gds2File->returnRecordAsString(-compact=>$compact);
               $string =~ s/^\s+//g;
               $angle = (split(/\s+/,$string))[1]; 
            }elsif($gds2File->isColrow){
               my $string = $gds2File->returnRecordAsString(-compact=>$compact);
               $string =~ s/^\s+//g;
               ($col,$row) = (split(/\s+/,$string))[1,2]; 
            }elsif($gds2File->isXy){
               my @poly_coords = $gds2File->returnXyAsArray;
               $_ *= $uu for @poly_coords;
               push(@aref_data, [$sname, $strans, $mag, $angle, $col, $row, @poly_coords]);
            }else{next;}
         }elsif($sref_found == 1){
            if($gds2File->isSname){
               $sname1 = $gds2File->returnSname;
               if(exists $cell_hash{$sname1}){
                  my $val = $cell_hash{$sname1};
                  $cell_hash{$sname1} = $val+1;
               }else{
                  $cell_hash{$sname1} = 0;
               }
            }elsif($gds2File->isStrans){
               my $string = $gds2File->returnRecordAsString(-compact=>$compact);
               $string =~ s/^\s+//g;
               $sref_strans = (split(/\s+/,$string))[1]; 
            }elsif($gds2File->isMag){
               my $string = $gds2File->returnRecordAsString(-compact=>$compact);
               $string =~ s/^\s+//g;
               $sref_mag = (split(/\s+/,$string))[1]; 
            }elsif($gds2File->isAngle){
               my $string = $gds2File->returnRecordAsString(-compact=>$compact);
               $string =~ s/^\s+//g;
               $sref_angle = (split(/\s+/,$string))[1]; 
            }elsif($gds2File->isXy){
               my @poly_coords = $gds2File->returnXyAsArray;
               $_ *= $uu for @poly_coords;
               push(@sref_data, [$sname1, $sref_strans, $sref_mag, $sref_angle, @poly_coords]);
            }else{next;}
         }else{next;}
      }else{next;}
    }#while
    
    ####################### Finding TOP Module ########################
    my @keys = sort{$cell_hash{$a}<=>$cell_hash{$b}} (keys %cell_hash);
    my $top_module = $keys[0];
    print "INFO 01: top cell is $top_module\n";

    undef %cell_hash; #removing from memory
    ######################## Flatten AREF data ########################
    foreach my $cell (keys %AREF_DATA){ 
      %CELL_POLYGONS = %{&get_aref_flat_data($cell, \%AREF_DATA, \%CELL_POLYGONS)};
    }
    print "INFO 02: AREF flattening completed ...\n";
    undef %AREF_DATA; #making hash empty
    
    ######################## Flatten SREF data ########################
    my ($a, $b) = &get_sref_flat_data($top_module, \%SREF_DATA, \%CELL_POLYGONS, \%PIN_TEXT_COORDS);;
    %CELL_POLYGONS = %{$a};
    %PIN_TEXT_COORDS = %{$b};
    print "INFO 03: SREF flattening completed ...\n";
    undef %SREF_DATA; #removing from memory

    ###################################################################
    my $gds_read_end_time = new Benchmark;
    my $gds_read_total_time = timediff($gds_read_end_time, $gds_read_start_time);
    print "INFO 04:flattening is completed in :",timestr($gds_read_total_time),"\n";

    ###################################################################
    my @polygon = @{$CELL_POLYGONS{$top_module}};
    my %layer_vs_poly = ();
    foreach my $p (@polygon){
       my $layer = shift @$p;
       push(@{$layer_vs_poly{$layer}}, [@$p]);  
    }

    foreach my $layer (keys %layer_vs_poly){
       my @poly = @{$layer_vs_poly{$layer}};
       my $outFile = $fileName."_layer_".$layer;
       open(WRITE ,">$outFile");
         foreach my $p (@poly){
            #--- commented after adding CT_XOR Math::Clipper function ---#
            #my @coords = @$p;
            #for(my $i=0; $i<$#coords; $i=$i+2){
            #    if($i == ($#coords -1)){
            #       print WRITE "($coords[$i],$coords[$i+1])";
            #    }else{
            #       print WRITE "($coords[$i],$coords[$i+1]),";
            #    }
            #}
            #print WRITE "\n";
            print WRITE "@$p\n";
            #------------------------------------------------------------#
         }
       close(WRITE); 
    }
    
    return($libName, $uu, $dbu, $top_module);
    ###################################################################
 }#if correct num of arg
}#sub read_gds_layer_polygon

##################### subroutine to convert PATH as POLYGON #######################
sub xformPathSegToPolygon{
 my @pathPoints = @{$_[0]};
 my $dataType = $_[1];;
 my $pathType = $_[2];
 my $pathWidth = $_[3];
 my $bgnExt = $_[4];
 my $endExt = $_[5];
 my ($bgnExtVal, $endExtVal) = (0, 0);
 ############# default value of PATHTYPE is 0. It means zero exension ############
 if($pathType == 1){
    print "WARN:PATHTYPE is $path_type. We are not supporting this\n";
 }elsif($pathType == 2){
    $bgnExtVal = $pathWidth/2;
    $endExtVal = $pathWidth/2;
 }elsif($pathType == 4){
    $bgnExtVal = $bgnExt;
    $endExtVal = $endExt;
 }
 my $seg_dir = '';
 my @poly_coords = ();
 my $maxEleInPolygon = @pathPoints * 2 - 1;
 for(my $i=0; $i<@pathPoints; $i=$i+2){
     if($i == ($#pathPoints-1)){
        if($seg_dir eq 'LTR'){
           $poly_coords[$i] = $pathPoints[$i] + $endExtVal;
           $poly_coords[$i+1] = $pathPoints[$i+1] - $pathWidth/2;
           $poly_coords[$maxEleInPolygon - ($i+1)] = $poly_coords[$i];
           $poly_coords[$maxEleInPolygon - $i] = $pathPoints[$i+1] + $pathWidth/2;
        }elsif($seg_dir eq 'RTL'){
           $poly_coords[$i] = $pathPoints[$i] - $endExtVal;
           $poly_coords[$i+1] = $pathPoints[$i+1] + $pathWidth/2;
           $poly_coords[$maxEleInPolygon - ($i+1)] = $poly_coords[$i];
           $poly_coords[$maxEleInPolygon - $i] = $pathPoints[$i+1] - $pathWidth/2;
        }elsif($seg_dir eq 'BTT'){
           $poly_coords[$i] = $pathPoints[$i] + $pathWidth/2;
           $poly_coords[$i+1] = $pathPoints[$i+1] + $endExtVal;
           $poly_coords[$maxEleInPolygon - ($i+1)] = $pathPoints[$i] - $pathWidth/2;
           $poly_coords[$maxEleInPolygon - $i] = $poly_coords[$i+1];
        }elsif($seg_dir eq 'TTB'){
           $poly_coords[$i] = $pathPoints[$i] - $pathWidth/2;
           $poly_coords[$i+1] = $pathPoints[$i+1] - $endExtVal;
           $poly_coords[$maxEleInPolygon - ($i+1)] = $pathPoints[$i] + $pathWidth/2;
           $poly_coords[$maxEleInPolygon - $i] = $poly_coords[$i+1];
        }
        push(@poly_coords, $poly_coords[0], $poly_coords[1]);
        #print "new:@poly_coords\n";
        return @poly_coords;
     }else{
        if($pathPoints[$i] == $pathPoints[$i+2]){ #vertical segment
           if($pathPoints[$i+1] < $pathPoints[$i+3]){ #from bottom to top
              if($i == 0){
                 $poly_coords[$i] = $pathPoints[$i] + $pathWidth/2;
                 $poly_coords[$i+1] = $pathPoints[$i+1] - $bgnExtVal;
                 $poly_coords[$maxEleInPolygon - ($i+1)] = $pathPoints[$i] - $pathWidth/2;
                 $poly_coords[$maxEleInPolygon - $i] = $poly_coords[$i+1];
              }else{
                 if($seg_dir eq 'RTL'){
                    $poly_coords[$i] = $pathPoints[$i] + $pathWidth/2;
                    $poly_coords[$i+1] = $pathPoints[$i+1] + $pathWidth/2;
                    $poly_coords[$maxEleInPolygon - ($i+1)] = $pathPoints[$i] - $pathWidth/2;
                    $poly_coords[$maxEleInPolygon - $i] =  $pathPoints[$i+1] - $pathWidth/2;
                 }elsif($seg_dir eq 'LTR'){
                    $poly_coords[$i] = $pathPoints[$i] + $pathWidth/2;
                    $poly_coords[$i+1] = $pathPoints[$i+1] - $pathWidth/2;
                    $poly_coords[$maxEleInPolygon - ($i+1)] = $pathPoints[$i] - $pathWidth/2;
                    $poly_coords[$maxEleInPolygon - $i] = $pathPoints[$i+1] + $pathWidth/2;
                 }
              }
              $seg_dir = 'BTT';
           }else{ #from top to bottom
              if($i == 0){
                 $poly_coords[$i] = $pathPoints[$i] - $pathWidth/2;
                 $poly_coords[$i+1] = $pathPoints[$i+1] + $bgnExtVal;
                 $poly_coords[$maxEleInPolygon - ($i+1)] = $pathPoints[$i] + $pathWidth/2;
                 $poly_coords[$maxEleInPolygon - $i] = $poly_coords[$i+1];
              }else{
                 if($seg_dir eq 'RTL'){
                    $poly_coords[$i] = $pathPoints[$i] - $pathWidth/2;
                    $poly_coords[$i+1] = $pathPoints[$i+1] + $pathWidth/2;
                    $poly_coords[$maxEleInPolygon - ($i+1)] = $pathPoints[$i] + $pathWidth/2;
                    $poly_coords[$maxEleInPolygon - $i] =  $pathPoints[$i+1] - $pathWidth/2;
                 }elsif($seg_dir eq 'LTR'){
                    $poly_coords[$i] = $pathPoints[$i] - $pathWidth/2;
                    $poly_coords[$i+1] = $pathPoints[$i+1] - $pathWidth/2;
                    $poly_coords[$maxEleInPolygon - ($i+1)] = $pathPoints[$i] + $pathWidth/2;
                    $poly_coords[$maxEleInPolygon - $i] = $pathPoints[$i+1] + $pathWidth/2;
                 }
              }
              $seg_dir = 'TTB';
           }
        }else{#horizontal segment
           if($pathPoints[$i] < $pathPoints[$i+2]){ #from left to right
              if($i == 0){
                 $poly_coords[$i] = $pathPoints[$i] - $bgnExtVal;
                 $poly_coords[$i+1] = $pathPoints[$i+1] - $pathWidth/2;
                 $poly_coords[$maxEleInPolygon - ($i+1)] = $poly_coords[$i];
                 $poly_coords[$maxEleInPolygon - $i] = $pathPoints[$i+1] + $pathWidth/2;
              }else{
                 if($seg_dir eq 'TTB'){
                    $poly_coords[$i] = $pathPoints[$i] - $pathWidth/2;
                    $poly_coords[$i+1] = $pathPoints[$i+1] - $pathWidth/2;
                    $poly_coords[$maxEleInPolygon - ($i+1)] = $pathPoints[$i] + $pathWidth/2;
                    $poly_coords[$maxEleInPolygon - $i] = $pathPoints[$i+1] + $pathWidth/2;
                 }elsif($seg_dir eq 'BTT'){
                    $poly_coords[$i] = $pathPoints[$i] + $pathWidth/2;
                    $poly_coords[$i+1] = $pathPoints[$i+1] - $pathWidth/2;
                    $poly_coords[$maxEleInPolygon - ($i+1)] = $pathPoints[$i] - $pathWidth/2;
                    $poly_coords[$maxEleInPolygon - $i] = $pathPoints[$i+1] + $pathWidth/2;
                 }
              }
              $seg_dir = 'LTR';
           }else{ #from right to left
              if($i == 0){
                 $poly_coords[$i] = $pathPoints[$i] + $bgnExtVal;
                 $poly_coords[$i+1] = $pathPoints[$i+1] + $pathWidth/2;
                 $poly_coords[$maxEleInPolygon - ($i+1)] = $poly_coords[$i];
                 $poly_coords[$maxEleInPolygon - $i] = $pathPoints[$i+1] - $pathWidth/2;
              }else{
                 if($seg_dir eq 'TTB'){
                    $poly_coords[$i] = $pathPoints[$i] - $pathWidth/2;
                    $poly_coords[$i+1] = $pathPoints[$i+1] + $pathWidth/2;
                    $poly_coords[$maxEleInPolygon - ($i+1)] = $pathPoints[$i] + $pathWidth/2;
                    $poly_coords[$maxEleInPolygon - $i] =  $pathPoints[$i+1] - $pathWidth/2;
                 }elsif($seg_dir eq 'BTT'){
                    $poly_coords[$i] = $pathPoints[$i] + $pathWidth/2;
                    $poly_coords[$i+1] = $pathPoints[$i+1] + $pathWidth/2;
                    $poly_coords[$maxEleInPolygon - ($i+1)] = $pathPoints[$i] - $pathWidth/2;
                    $poly_coords[$maxEleInPolygon - $i] =  $pathPoints[$i+1] - $pathWidth/2;
                 }
              }
              $seg_dir = 'RTL';
           }
        }
     }
 }
}#sub xformPathSegToPolygon

############################ subroutine to flat AREF ##############################
sub get_aref_flat_data {
 my $cell = $_[0];
 my %AREF_DATA = %{$_[1]};
 my %CELL_POLYGONS = %{$_[2]};

 my @aref_data = @{$AREF_DATA{$cell}};
 foreach my $line(@aref_data){
   my ($sname, $strans, $scale, $angle, $col, $row, @poly_coords) = @$line;
   if(exists $AREF_DATA{$sname}){
      %CELL_POLYGONS = %{&get_aref_flat_data($sname, \%AREF_DATA, \%CELL_POLYGONS)};
   }
   if(exists $CELL_POLYGONS{$sname}){
      my @poly_data = @{$CELL_POLYGONS{$sname}};
      ## @poly_coords has three points 
      #1.Reference point 
      #2.coordinate that is displaced from the reference point by the inter-column spacing times the number of columns, after all transformations have been applied.
      #3.coordinate that is displaced from the reference point by the inter-row spacing times the number of row, after all transformations have been applied.
      # so to calculate array row length & column height, we have to take vector distance or we should retransform 2nd & 3rd point.
      
      if(@poly_data < 1){next;}
      my $locX = $poly_coords[0];
      my $locY = $poly_coords[1];
  
      my $array_width = sqrt(($poly_coords[2] - $locX)*($poly_coords[2] - $locX) +  ($poly_coords[3] - $locY)*($poly_coords[3] - $locY));
      my $array_height = sqrt(($poly_coords[4] - $locX)*($poly_coords[4] - $locX) +  ($poly_coords[5] - $locY)*($poly_coords[5] - $locY));
      my $inter_col_spacing = $array_width/$col;
      my $inter_row_spacing = $array_height/$row;

      my @strans_bits = split(//,$strans);

      if($strans_bits[13] == 1){ #absolute magnification
         $scale = abs($scale);
      }
      if($strans_bits[14] == 1){ #absolute angle
         $angle = abs($angle);
      }
      #### since polygon_rotate rotates clockwise. To rotate anticlockwise, we should take -ve angle #### 
      $angle = $angle%360;
      $angle = 360 - $angle; ##### to make anticlockwise angle to clockwise

      for(my $i=0; $i< $row; $i++){
         my $shiftY = $inter_row_spacing*$i;
         for(my $j=0; $j< $col; $j++){
             my $shiftX = $inter_col_spacing*$j;
             foreach my $polygon (@poly_data){
               my @poly = @$polygon;
               my $layer = shift @poly; #1st element of @poly is layer
               my @new_poly = (); #making array in the form of Math:Polygon
               for(my $i=0; $i<=$#poly; $i=$i+2){ 
                  push(@new_poly, [$poly[$i], $poly[$i+1]]);
               }
               @new_poly = polygon_move(dx => $shiftX, dy=> $shiftY, @new_poly);
               #### 1st step is scaling ####
               if($scale != 1){
                  @new_poly = polygon_resize(scale => $scale,  @new_poly); 
               }
               #### 2nd step is mirroring if 0'bit is high ####
               if($strans_bits[0] == 1){ #mirroring along x-axis
                  @new_poly = polygon_mirror(y => 0.0, @new_poly);
               }
               #### 3rd step is rotation counter clockwise #####
               if($angle != 0 && $angle != 360){
                  @new_poly = polygon_rotate(degrees=>$angle, @new_poly);
               }
               #### insertion at given point ####
               @new_poly = polygon_move(dx => $locX, dy=> $locY, @new_poly);
               my @trans_poly = ();
               foreach my $p (@new_poly){
                  my @point = @$p;
                  push (@trans_poly, @point);
               }
               push(@{$CELL_POLYGONS{$cell}}, [$layer, @trans_poly]);
               ## adding this line to assign group different for each via poly
             }
         }#foreach col
      }#foreach row
    }#if cell poly found
 }#foreach line 
 return (\%CELL_POLYGONS);
}#sub get_aref_flat_data

############################ subroutine to flat SREF ##############################
sub get_sref_flat_data{
 my $top_module = $_[0];
 my %SREF_DATA = %{$_[1]};
 my %CELL_POLYGONS = %{$_[2]};
 my %PIN_TEXT_COORDS = %{$_[3]};

 if(exists $SREF_DATA{$top_module}){
    my @sref_data = @{$SREF_DATA{$top_module}};
    foreach my $line(@sref_data){
       my ($sname, $strans, $mag, $angle, $llx, $lly) = @$line;
       ($x, $y) = &replace_sref_data($sname, [$strans], [$mag], [$angle], [$llx], [$lly], $top_module, \%SREF_DATA, \%CELL_POLYGONS, \%PIN_TEXT_COORDS);
       %CELL_POLYGONS = %$x;
       %PIN_TEXT_COORDS = %$y;
    }
 }
 return(\%CELL_POLYGONS, \%PIN_TEXT_COORDS);
}#sub get_sref_flat_data

sub replace_sref_data{
 my $sname = $_[0];
 my $strans = $_[1];
 my $mag = $_[2];
 my $angle = $_[3];
 my $shiftX = $_[4];
 my $shiftY = $_[5];
 my $top_module = $_[6];
 my %SREF_DATA = %{$_[7]};
 my %CELL_POLYGONS = %{$_[8]};
 my %PIN_TEXT_COORDS = %{$_[9]};

 if(exists $CELL_POLYGONS{$sname}){
    my @poly_data = @{$CELL_POLYGONS{$sname}};
    my %temp_grp = ();
    my $count = 0;
    my $assigned_grp = 0;
    foreach my $polygon (@poly_data){
      my @poly = @$polygon;
      my $layer = shift @poly; #1st element of @poly is layer
      push(@{$CELL_POLYGONS{$top_module}}, [$layer, &transform_sref_inst($strans, $mag, $angle, $shiftX, $shiftY, \@poly)]);
    }#foreach polygon

    ################ transform TEXT coords ###############
    if(exists $PIN_TEXT_COORDS{$sname}){
       my @new_pin_line = ();
       my @current_cell_pin = @{$PIN_TEXT_COORDS{$sname}};
       foreach my $pin_line (@current_cell_pin){
          my $text = @$pin_line[0];
          my $x = @$pin_line[6];
          my $y = @$pin_line[7];
          my @trans_poly = &transform_sref_inst($strans, $mag, $angle, $shiftX, $shiftY, [$x,$y,$x,$y,$x,$y,$x,$y]);
          push(@new_pin_line, [$text,@$pin_line[1],@$pin_line[2],@$pin_line[3],@$pin_line[4],@$pin_line[5],$trans_poly[0],$trans_poly[1]]);
       } 
       @{$PIN_TEXT_COORDS{$top_module}} = @new_pin_line;
    }
    ######################################################

 }#if string exists in CELL_POLYGONS hash
 if(exists $SREF_DATA{$sname}){
    my @sref_data = @{$SREF_DATA{$sname}};
    foreach my $line(@sref_data){
       my ($sname1,  $strans1, $mag1, $angle1, $llx, $lly) = @$line;
       ($x, $y) = &replace_sref_data($sname1, [@$strans,$strans1],[@$mag,$mag1], [@$angle, $angle1], [@$shiftX, $llx], [@$shiftY,$lly], $top_module,\%SREF_DATA, \%CELL_POLYGONS, \%PIN_TEXT_COORDS);
       %CELL_POLYGONS = %$x;
       %PIN_TEXT_COORDS = %$y;
    }
 }
 return(\%CELL_POLYGONS, \%PIN_TEXT_COORDS);
}#sub replace_sref_data

sub transform_sref_inst{
 my @strans_arr = @{$_[0]};
 my @scale_arr = @{$_[1]};
 my @angle_arr = @{$_[2]};
 my @shiftX_arr = @{$_[3]};
 my @shiftY_arr = @{$_[4]};
 my @poly = @{$_[5]};

 my @trans_poly = ();
 my @new_poly = (); #making array in the form of Math:Polygon
 for(my $i=0; $i<=$#poly; $i=$i+2){ 
    push(@new_poly, [$poly[$i], $poly[$i+1]]);
 }
 
 for(my $i=$#strans_arr; $i>=0; $i--){
     my $strans = $strans_arr[$i];
     my @strans_bits = split(//,$strans);
     my $scale = $scale_arr[$i];
     my $angle = $angle_arr[$i];
     my $shiftX = $shiftX_arr[$i];
     my $shiftY = $shiftY_arr[$i];
     #### 1st step is scaling ####
     if($strans_bits[13] == 1){ #absolute magnification
        $scale = abs($scale);
     }
     if($scale != 1){
        @new_poly = polygon_resize(scale => $scale,  @new_poly); 
     }
     #### 2nd step is mirroring if 0'bit is high ####
     if($strans_bits[0] == 1){ #mirroring along x-axis
        @new_poly = polygon_mirror(y => 0.0, @new_poly);
     }
     #### 3rd step is rotation counter clockwise #####
     if($strans_bits[14] == 1){ #absolute angle
        $angle = abs($angle);
     }
     #### since polygon_rotate rotates clockwise. To rotate anticlockwise, we should take -ve angle #### 
     $angle = $angle%360;
     $angle = 360 - $angle; ##### to make anticlockwise angle to clockwise
     if($angle != 0 && $angle != 360){
        @new_poly = polygon_rotate(degrees=>$angle, @new_poly);
     }
     #### insertion at given point ####
     @new_poly = polygon_move(dx => $shiftX, dy=> $shiftY, @new_poly);
 }

 foreach my $p (@new_poly){
    my @point = @$p;
    push (@trans_poly, @point);
 }

 return @trans_poly;
}#sub transform_sref_inst


##############################################################################################
################ subroutine to write xor of layes polygons of two GDS files ##################
##############################################################################################
sub write_layer_xor{
  my $file_name1 = $_[0];
  my $file_name2 = $_[1];
  my $output_file = $_[2];

  my @rect_array1 = ();
  my @rect_array2 = ();

  my $clipper = Math::Clipper->new;

  open(READ1,"<$file_name1");
  while(<READ1>){
    my @points = split(/\s+/);
    my @rect = ();
    for(my $i=0; $i<=$#points; $i=$i+2){
      push(@rect,[$points[$i], $points[$i+1]]);
    }
    push(@rect_array1, [@rect]);
  }
  close(READ1);

  open(READ2,"<$file_name2");
  while(<READ2>){
    my @points = split(/\s+/);;
    my @rect = ();
    for(my $i=0; $i<=$#points; $i=$i+2){
      push(@rect,[$points[$i], $points[$i+1]]);
    }
    push(@rect_array2, [@rect]);
  }
  close(READ2);

  my $scale_rect_array1 = integerize_coordinate_sets(@rect_array1);
  my $count = 0;
  foreach my $r (@rect_array1){
     my @rect = @$r;
     my $direction = is_counter_clockwise([@rect]);
     if($direction == 0){
        @rect = reverse @rect;
     }
     if($count == 0){
        $clipper->add_subject_polygon([@rect]);
        $count++;
     }else{
        $clipper->add_clip_polygon([@rect]);
     }
  }
  my @rect_array_new1 = @{$clipper->execute(CT_UNION,PFT_NONZERO,PFT_NONZERO)};
  unscale_coordinate_sets($scale_rect_array1, [@rect_array_new1]) if(@rect_array_new1 > 0);

  $clipper->clear();
  my $scale_rect_array2 = integerize_coordinate_sets(@rect_array2);
  $count = 0;
  foreach my $r (@rect_array2){
     my @rect = @$r;
     my $direction = is_counter_clockwise([@rect]);
     if($direction == 0){
        @rect = reverse @rect;
     }
     if($count == 0){
        $clipper->add_subject_polygon([@rect]);
        $count++;
     }else{
        $clipper->add_clip_polygon([@rect]);
     }
  }
  my @rect_array_new2 = @{$clipper->execute(CT_UNION,PFT_NONZERO,PFT_NONZERO)};
  unscale_coordinate_sets( $scale_rect_array2, [@rect_array_new2]) if(@rect_array_new2 > 0);

  my $scale = integerize_coordinate_sets(@rect_array_new1,@rect_array_new2);
  my $clipper = Math::Clipper->new;
  $clipper->add_subject_polygons([@rect_array_new1]);
  $clipper->add_clip_polygons([@rect_array_new2]);
  my @xor_rect1_rect2 = @{$clipper->execute(CT_XOR)};
  unscale_coordinate_sets( $scale, [@xor_rect1_rect2]) if(@xor_rect1_rect2 > 0);

  open(WRITE,">$output_file");
  my $is_first_point;
  my $is_first_axis;
  for(my $j=0; $j<=$#xor_rect1_rect2; $j++){
    my @p = @{$xor_rect1_rect2[$j]};
    $is_first_point = 1;
    foreach my $point_arr_ref (@p){
      if($is_first_point != 1){
        print WRITE ",";
      }else{
        $is_first_point = 0;
      }
      my @point_arr = @$point_arr_ref;
      print WRITE "(";
      $is_first_axis = 1;
      foreach my $point (@point_arr){
        if($is_first_axis != 1){
          print WRITE ",";
        }else{
          $is_first_axis = 0;
        }
        print WRITE "$point";
      }
      print WRITE ")";
    }
    print WRITE "\n";
  }
  close(WRITE);


}#sub write_layer_xor

##############################################################################################
############################# subroutine to write xor GDS file ###############################
##############################################################################################
sub write_xor_gds{
  my $libName = $_[0];
  my $uu = $_[1];
  my $dbu = $_[2];
  my $cellName = $_[3];
  my @layers = @{$_[4]};
  my $outFile = $_[5];

  my $gds2File = new GDS2(-fileName=>">$outFile.gds");
  $gds2File -> printInitLib(-name=> $libName, 
                            -uUnit=>$uu,
                            -dbUnit=>$dbu);

  $gds2File -> printBgnstr(-name=>$cellName);

  foreach my $layer(@layers){
    open(READ, "xorOutLayer$layer");
      while(<READ>){
        s/\s+//g;
        s/\(|\)//g;
        my @poly_coords = split(/\,/);
        $gds2File -> printBoundary(
                     -layer=>$layer,
                     -xy=>[@poly_coords],
                  );
      }
    close(READ);
  }

  $gds2File -> printEndstr;
  $gds2File -> printEndlib();

}#sub write_xor_gds



