#!/usr/bin/perl
#use warnings;
use GDS2;
use Math::Clipper ':all';
use Math::Polygon;
use Math::Polygon::Calc;
use Math::Polygon::Transform;
use List::Part;
use List::Flatten;
use XML::Simple;
use Data::Dumper;
use Benchmark;
my $t0 = new Benchmark;

my $noOfArg = @ARGV;
my ($gdsFile, $outFile, $layerMapFile, $configFile, $tolerance, $singlePinPoly) = ("", "", "", "", 0.0001, 0);
my ($uu,$dbu);
if($noOfArg < 6 || $ARGV[0] eq '-h' || $ARGV[0] eq '-help' || $ARGV[0] eq '-HELP') {
   print "usage : ./gds2lef.pl   -gds < gds file >\n";
   print "                       -layer_map_file <input layer map file>\n";
   print "                       -config_file <input config file>\n";
   print "                       -out <output file name(default is temp.lef)>\n";
   print "                       -tolerance <tolerance for floating numbers (default value is 0.0001)>\n";
   print "                       --single_pin_poly <to write only pin text polygons>\n";
}else {
   for(my $i=0 ; $i<$noOfArg; $i++){
       if($ARGV[$i] eq "-gds"){$gdsFile = $ARGV[$i+1];} 
       if($ARGV[$i] eq "-out"){$outFile = $ARGV[$i+1];} 
       if($ARGV[$i] eq "-layer_map_file"){$layerMapFile = $ARGV[$i+1];} 
       if($ARGV[$i] eq "-config_file"){$configFile = $ARGV[$i+1];} 
       if($ARGV[$i] eq "-tolerance"){$tolerance = $ARGV[$i+1];} 
       if($ARGV[$i] eq "--single_pin_poly"){$singlePinPoly = 1;} 
   }#for correct no.of Arguments

   if($outFile eq ""){ 
      my ($gds_file_name) = (split(/\//,$gdsFile))[-1];
      my ($file_name) = (split(/\./,$gds_file_name))[0];
      $outFile = $file_name.".lef";
   }#if file(lef) name is not given
   if($tolerance eq ""){
      $tolerance = 0.0001;
   }

   my %cell_size = ();
   my %boundary_layer_hash = ();

   my %overlap_layer_hash = ();
   my %via_hash = ();
   my %rev_overlap_layer_hash = ();
   my %rev_via_hash = ();
   my %temp_layer_map = ();
   my %text_layer_hash = ();
   ####################### Reading layer Map file ###########################
   my $xml = new XML::Simple;
   my $layerConnData = $xml->XMLin("$layerMapFile");
   my %layerConnHash = %$layerConnData;
   foreach my $key (keys %layerConnHash){
     my %layerHash = %{$layerConnHash{$key}};
     if(exists $layerHash{name}){
        my $layer = $layerHash{name};
        my $type = $layerHash{type};
        my $layerNum = $layerHash{num};
        my $upLayer = $layerHash{uplayer};
        my $downLayer = $layerHash{downlayer};
        $temp_layer_map{$layerNum} = $layer;
        if($type eq "ROUTING"){
           $overlap_layer_hash{$layerNum} = $upLayer;
           $rev_overlap_layer_hash{$layerNum} = $downLayer;
        }elsif($type eq "VIA"){
           $via_hash{$layerNum} = $upLayer;
           $rev_via_hash{$layerNum} = $downLayer;
        }
     }else{
        foreach my $layer (keys %layerHash ){
          my %layerInfoHash = %{$layerHash{$layer}};
          my $type = $layerInfoHash{type};
          my $layerNum = $layerInfoHash{num};
          my $upLayer = $layerInfoHash{uplayer};
          my $downLayer = $layerInfoHash{downlayer};
          $temp_layer_map{$layerNum} = $layer;
          if($type eq "ROUTING"){
             $overlap_layer_hash{$layerNum} = $upLayer;
             $rev_overlap_layer_hash{$layerNum} = $downLayer;
          }elsif($type eq "VIA"){
             $via_hash{$layerNum} = $upLayer;
             $rev_via_hash{$layerNum} = $downLayer;
          }
        }#foreach layer
     }#if more than one layer
   }#foreach key

   ##--Adding all metal layers (routing+via) as keys in boundary_layer_hash--##
   foreach my $key(keys %overlap_layer_hash){
     my @temp = ();
     @{$boundary_layer_hash{$key}} = @temp ;
     my $value = $overlap_layer_hash{$key};
     if(!exists $boundary_layer_hash{$value}){
        my @temp1 = ();
        @{$boundary_layer_hash{$value}} = @temp1;
     }
   }

   ######################## Reading Congfig File #############################
   my $xml1 = new XML::Simple;
   my $configData = $xml1->XMLin("$configFile");
   my %configHash = %$configData;
   my $mustjoin_identifier = $configHash{mustjoin_identifier};
   my $boundary_layer = $configHash{boundary};
   my $boundary_layer_data_type = $configHash{boundary_layer_data_type};
   my $text_layers_str = $configHash{text_layer_map};
   my $label_level = $configHash{label_level};
   my @text_layers = split(/\,/,$text_layers_str);
   foreach (@text_layers){
     my ($textLayer, $metalLayer) = split(/\=\>/, $_);
     $text_layer_hash{$textLayer} = $metalLayer;
   }

   ######################### Reading GDS file ###############################
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
   my ($string_name, $layer_name, $boundary_data_type, $path_layer, $path_data_type, $path_type, $path_width, $path_bgnExtn, $path_endExtn, $path_unitWidth, $path_xyInt);
   my ($sname, $text_layer, $textType, $presentation, $strans, $mag, $angle, $col, $row, $sname1, $sref_strans, $sref_mag, $sref_angle);
   my @pin_coords = ();
   my @total_poly = ();
   my @aref_data = ();
   my @sref_data = ();
   my @X_COORDS = ();
   my @Y_COORDS = ();
   my @xy = ();

   while ($gds2File->readGds2Record) {
     if($gds2File->isUnits){
       ($uu,$dbu) = $gds2File->returnUnitsAsArray;
       print "UNITS: $uu $dbu\n";
     }elsif($gds2File->isBgnstr){
        $string_found = 1;
        $string_name = "";
        @pin_coords = ();
        @total_poly = ();
        @aref_data = ();
        @sref_data = ();
        @X_COORDS = ();
        @Y_COORDS = ();
     }elsif($gds2File->isEndstr){
        @{$CELL_POLYGONS{$string_name}}= @total_poly if(@total_poly > 0);
        @{$PIN_TEXT_COORDS{$string_name}}= @pin_coords if(@pin_coords > 0);
        @{$AREF_DATA{$string_name}}= @aref_data if(@aref_data > 0);
        @{$SREF_DATA{$string_name}}= @sref_data if(@sref_data > 0);
        if(!exists $cell_size{$string_name}){
          my ($width, $height) = (0, 0);
          @X_COORDS = sort{$a<=>$b}@X_COORDS;
          @Y_COORDS = sort{$a<=>$b}@Y_COORDS;
          $width = $X_COORDS[-1] - $X_COORDS[0] if(@X_COORDS > 0);
          $height = $Y_COORDS[-1] - $Y_COORDS[0] if(@Y_COORDS > 0);
          $cell_size{$string_name} = [$layer_name, $width, $height];
        }
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
              if((!exists $boundary_layer_hash{$layer_name}) && $layer_name != $boundary_layer){$boundary_found = 0;}
           }elsif($gds2File->isDatatype){
              $boundary_data_type = $gds2File->returnDatatype;
           }elsif($gds2File->isXy){
              my @poly_coords = $gds2File->returnXyAsArray;
              #$_ *= $uu for @poly_coords;

              ############ calculating cellsize ##############
              if($boundary_layer ne "" && $boundary_layer_data_type ne ""){
                 if($layer_name == $boundary_layer && $boundary_data_type == $boundary_layer_data_type){
                    my @x_coords = ();
                    my @y_coords = ();
                    for(my $i=0; $i<=$#poly_coords; $i=$i+2){
                        push(@x_coords, $poly_coords[$i]);
                        push(@y_coords, $poly_coords[$i+1]);
                    }
                    @x_coords = sort{$a<=>$b}@x_coords;
                    @y_coords = sort{$a<=>$b}@y_coords;
                    my $width = $x_coords[-1] - $x_coords[0];
                    my $height = $y_coords[-1] - $y_coords[0];
                    $cell_size{$string_name} = [$layer_name, $width, $height]; 
                 }else{
                    for(my $i=0; $i<=$#poly_coords; $i=$i+2){
                         push(@X_COORDS, $poly_coords[$i]);# if($poly_coords[$i] >= 0);
                         push(@Y_COORDS, $poly_coords[$i+1]);# if($poly_coords[$i+1] >= 0);
                    }
                 }
              }else{
                for(my $i=0; $i<=$#poly_coords; $i=$i+2){
                     push(@X_COORDS, $poly_coords[$i]);# if($poly_coords[$i] >= 0);
                     push(@Y_COORDS, $poly_coords[$i+1]);# if($poly_coords[$i+1] >= 0);
                 }
              }
              ################################################
              push(@total_poly, [$layer_name, @poly_coords]);
           }else{next;}
        }elsif($path_found == 1){
           if($gds2File->isLayer){
              $path_layer = $gds2File->returnLayer;
              if(!exists $boundary_layer_hash{$path_layer}){$path_found = 0;}
           }elsif($gds2File->isDatatype){
              $path_data_type = $gds2File->returnDatatype;
           }elsif($gds2File->isPathtype){
              $path_type = $gds2File->returnPathtype;
           }elsif($gds2File->isWidth){
              $path_width = $gds2File->returnWidth;
              #$path_width = $path_width * $uu;
           }elsif($gds2File->isBgnextn){
              $path_bgnExtn = $gds2File->returnBgnextn;
              #$path_bgnExtn = $path_bgnExtn * $uu;
           }elsif($gds2File->isEndextn){
              $path_endExtn = $gds2File->returnEndextn;
              #$path_endExtn = $path_endExtn * $uu;
           }elsif($gds2File->isXy){
              my @path_coords = $gds2File->returnXyAsArray;
              #$_ *= $uu for @path_coords;
              push(@total_poly, [$path_layer, xformPathSegToPolygon(\@path_coords,$path_data_type, $path_type, $path_width, $path_bgnExtn, $path_endExtn)]);
           }else{next;}
        }elsif($text_found == 1){
           if($gds2File->isXy){
              @xy = $gds2File->returnXyAsArray;
              #$_ *= $uu for @xy;
           }elsif($gds2File->isLayer){
              $text_layer = $gds2File->returnLayer;
              if($text_layers_str ne ""){     
                if(!exists $text_layer_hash{$text_layer}){
                   $text_found = 0;
                }#if exists in text_layer_hash
              }#if text_layer entry is given in config file
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
              #$_ *= $uu for @poly_coords;
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
              #$_ *= $uu for @poly_coords;
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
     &get_aref_flat_data($cell);
   }
   sub get_aref_flat_data {
     my $cell = $_[0];
     my @aref_data = @{$AREF_DATA{$cell}};
     foreach my $line(@aref_data){
       my ($sname, $strans, $scale, $angle, $col, $row, @poly_coords) = @$line;
       if(exists $AREF_DATA{$sname}){
          &get_aref_flat_data($sname);
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
                   if(!exists $boundary_layer_hash{$layer}){next;}
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
                 }
             }#foreach col
          }#foreach row
        }#if cell poly found
     }#foreach line 
   }#sub get_aref_flat_data

   print "INFO 02: AREF flattening completed ...\n";
   undef %AREF_DATA; #making hash empty

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

   ######################## Flatten SREF data ########################
   my %repeat_via_group = ();

   &get_sref_flat_data;
   sub get_sref_flat_data{
     if(exists $SREF_DATA{$top_module}){
        my @sref_data = @{$SREF_DATA{$top_module}};
        foreach my $line(@sref_data){
          my ($sname, $strans, $mag, $angle, $llx, $lly) = @$line;
          &replace_sref_data($sname, [$strans], [$mag], [$angle], [$llx], [$lly]);
        }
     }
   }#sub get_sref_flat_data

   sub replace_sref_data{
     my $sname = $_[0];
     my $strans = $_[1];
     my $mag = $_[2];
     my $angle = $_[3];
     my $shiftX = $_[4];
     my $shiftY = $_[5];
     if(exists $CELL_POLYGONS{$sname}){
        my @poly_data = @{$CELL_POLYGONS{$sname}};
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
           @{$PIN_TEXT_COORDS{$sname}} = @new_pin_line;
        }
        ######################################################

     }#if string exists in CELL_POLYGONS hash
     if(exists $SREF_DATA{$sname}){
        my @sref_data = @{$SREF_DATA{$sname}};
        foreach my $line(@sref_data){
          my ($sname1,  $strans1, $mag1, $angle1, $llx, $lly) = @$line;
          &replace_sref_data($sname1, [@$strans,$strans1],[@$mag,$mag1], [@$angle, $angle1], [@$shiftX, $llx], [@$shiftY,$lly]);
        }
     }
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
   
   undef %SREF_DATA; #removing from memory
   
   ################## Writing layer and via in file ##################
   ###################################################################
   
   my $t1 = new Benchmark;
   my $td0 = timediff($t1, $t0);
   print "INFO 03:flattening is completed in :",timestr($td0),"\n";

   my @data_arr = @{$CELL_POLYGONS{$top_module}};
   my %layer_vs_polygon = ();
   foreach my $poly (@data_arr){
      my @polygon = @$poly;
      my $layer = shift @polygon;
      push (@{$layer_vs_polygon{$layer}}, [@polygon]);
   }
   undef %CELL_POLYGONS; #removing from memory
   
   foreach my $layer (keys %layer_vs_polygon){
      if(exists $overlap_layer_hash{$layer}){
         my @routing_layer_polys = @{$layer_vs_polygon{$layer}};
         open(WRITE, ">layer_with_via_$layer");
           foreach my $poly (@routing_layer_polys){
              print WRITE "P $layer @$poly\n";
           }
           my $dwnLayer = $overlap_layer_hash{$layer}; 
           if(exists $layer_vs_polygon{$dwnLayer}){
              my @dwn_layer_polys = @{$layer_vs_polygon{$dwnLayer}};
              foreach my $poly (@dwn_layer_polys){
                 print WRITE "V $dwnLayer @$poly\n";
              }
           }
           my $upLayer = $rev_overlap_layer_hash{$layer}; 
           if(exists $layer_vs_polygon{$upLayer}){
              my @up_layer_polys = @{$layer_vs_polygon{$upLayer}};
              foreach my $poly (@up_layer_polys){
                 print WRITE "V $upLayer @$poly\n";
              }
           }
         close(WRITE);
         system("/vol5/testcase/adityap/gds2lefTest/create_group_of_polygons.pl layer_with_via_$layer");
      }
   }
   undef %layer_vs_polygon; #removing from memory

   my @gds_layer_group_files = ();
   foreach my $key (keys %overlap_layer_hash){
      push (@gds_layer_group_files, "gds_layer_groups_".$key);
   } 
   my $gds_layer_groups_str = join ",", @gds_layer_group_files;
   system("/vol5/testcase/adityap/gds2lefTest/create_pin_groups.pl -group_file_list $gds_layer_groups_str -layer_map_file $layerMapFile");
   
   ######################################################################
   my $t2 = new Benchmark;

   my @final_groups = ();
   my @group_polys = ();
   my $group;
   open(READ, "gds_layer_final_groups");
     while(<READ>){
        chomp();
        if($_ =~ /^\s*#/ ){next ;}
        if($_ =~ /^GROUP/ ){
           $group = (split(/\:/, $_))[1];
           push(@final_groups, [@group_polys]);
           @group_polys = ();
           next;
        }
        my ($layer, @poly)= split(/\s+/, $_);
        $_ *= $uu for @poly; #multiplying by db unit
        push(@group_polys, [$layer, @poly]);
     
     }
     push(@final_groups, [@group_polys]);
   close(READ);
 
   ######################################################################
   ####################### Making pin's group ########################### 
   ######################################################################
   my @obs_poly = ();
   my @pins = ();
   if($label_level eq "" || $label_level eq "top"){
      push(@pins, @{$PIN_TEXT_COORDS{$top_module}});
   }else{
      foreach my $cell (keys %PIN_TEXT_COORDS){
        push(@pins, @{$PIN_TEXT_COORDS{$cell}});
      }
   }

   ################### Multiplying by db unit ####################
   foreach my $p (@pins){
      @$p[6] = @$p[6]*$uu;
      @$p[7] = @$p[7]*$uu;
   }
   
   ###############################################################
   my %pin_poly_hash = ();
   for(my $i=0; $i<=$#final_groups; $i++){
       if($final_groups[$i] eq ""){next;}
       my $group = $final_groups[$i];
       my $isInside = 0;
       LOOPC:foreach my $poly (@$group){
         my @poly_coords = @$poly;
         my $poly_layer = $poly_coords[0];
         my $j=0;
         my @p = part { $j++/2 } @poly_coords[1 .. $#poly_coords];

         my $count = -1;
         foreach my $pin_line (@pins){
           $count++;
           if(ref $pin_line eq ""){next;}
           my $pin = @$pin_line[0];
           my $pin_layer = @$pin_line[1];
           if(exists $text_layer_hash{$pin_layer}){
              if($text_layer_hash{$pin_layer} != $poly_layer){next;}
           } 
           
           my @pin_point = (@$pin_line[6], @$pin_line[7]);
           my $polygon = Math::Polygon->new( @p);
           $isInside = $polygon->contains([@pin_point]);
           if($isInside == 1){
              if($pin =~ /$mustjoin_identifier/){
                $pin = (split(/$mustjoin_identifier/,$pin))[0];
              }
              if(exists $pin_poly_hash{$pin}){
                $pin = $pin.$mustjoin_identifier;
              }
              @{$pin_poly_hash{$pin}} = @{$final_groups[$i]};
              delete $final_groups[$i];
              splice @pins,$count,1;
              last LOOPC;
           }
         }#foreach pin
       }#foreach polygon
       if($isInside == 0){
          push(@obs_poly, @{$final_groups[$i]});
       }
   }#foreach group
   @{$pin_poly_hash{OBS}} = @obs_poly;
  
   my $t3 = new Benchmark;
   my $td1 = timediff($t3, $t2);
   print "Making pin group complete :",timestr($td1),"\n";

   @final_groups = (); #making array empty
   
   ######################################################################
   my ($layerName,$width, $height) = @{$cell_size{$top_module}};
   $width = $width*$uu;
   $height = $height*$uu;
   
   open ( WRITE_LEF, ">$outFile");
   print WRITE_LEF "MACRO $top_module\n";
   print WRITE_LEF "  CLASS CORE ;\n";
   print WRITE_LEF "  FOREIGN $top_module 0.0 0.0 ;\n";
   print WRITE_LEF "  ORIGIN 0 0 ;\n";
   print WRITE_LEF "  SIZE $width BY $height ;\n";
   print WRITE_LEF "  SYMMETRY X Y ;\n";
   #print WRITE_LEF "  SYMMETRY X Y R90 ;\n\n";
   print WRITE_LEF "  SITE tsm5site ;\n";
   
   foreach my $pin(keys %pin_poly_hash){
     my @poly = @{$pin_poly_hash{$pin}};
     if($pin eq "OBS" && $#poly < 0){next;}
     if($pin eq "OBS"){
        print WRITE_LEF "  $pin\n";
     }else{
        print WRITE_LEF "  PIN $pin\n";
        if($pin =~ /vss|gnd/i){
           print WRITE_LEF "    DIRECTION INOUT ;\n";
           print WRITE_LEF "    USE GROUND ;\n";
        }elsif($pin =~ /vdd/i){
           print WRITE_LEF "    DIRECTION INOUT ;\n";
           print WRITE_LEF "    USE POWER ;\n";
        }else{
           print WRITE_LEF "    DIRECTION INPUT ;\n";
           print WRITE_LEF "    USE SIGNAL ;\n";
        }
        print WRITE_LEF "    PORT\n";
     }
     my $prev_layer = "";
     foreach my $p(@poly){
       my @polygon = @$p;
       my $layer = shift @polygon;
       if($layer ne $prev_layer){
          print WRITE_LEF "    LAYER $temp_layer_map{$layer} ;\n";
          $prev_layer = $layer;
       }
       print WRITE_LEF"      POLYGON @polygon ;\n";
     }
     if($pin eq "OBS"){
        print WRITE_LEF "  END\n\n";
     }else{
        print WRITE_LEF "    END\n";
        print WRITE_LEF "  END $pin\n\n";
     }
   }
   print WRITE_LEF "END $top_module\n";
   close WRITE_LEF;

   ####################### End of Script ##########################
   
}#if correct num of arg

my $tfinal = new Benchmark;
my $tdfinal = timediff($tfinal, $t0);
print "script gds2lef took:",timestr($tdfinal),"\n";


