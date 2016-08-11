#!/usr/bin/perl
#use warnings;
use GDS2;
use Math::Clipper ':all';
use Math::Polygon;
use Math::Polygon::Calc;
use Math::Polygon::Transform;
use XML::Simple;
use XML::SAX::PurePerl;
use Benchmark;
my $t0 = new Benchmark;

my $noOfArg = @ARGV;
my ($gdsFile, $outFile, $layerMapFile, $configFile, $tolerance,$shift_at_origin, $repeate_pin) = ("", "", "", "", 0.0001, 0, 0);
my ($uu,$dbu,$refX,$refY) = (1, 1, 0, 0);
my $blkgAsRect = 0;
if($noOfArg < 6 || $ARGV[0] eq '-h' || $ARGV[0] eq '-help' || $ARGV[0] eq '-HELP') {
   print "usage : ./gds2def.pl   -gds < gds file >\n";
   print "                       -layer_map_file <input layer map file>\n";
   print "                       -config_file <input config file>\n";
   print "                       -out <output file name(default is temp.lef)>\n";
   print "                       -tolerance <tolerance for floating numbers (default value is 0.0001)>\n";
   print "                       --shift_at_origin (minx & min y will be at (0, 0))>\n";
   print "                       --repeate_pin (write pins with .extra1,.extra2... if repeating)>\n";
   print "                       --blkgAsRect >\n";
}else {
   for(my $i=0 ; $i<$noOfArg; $i++){
       if($ARGV[$i] eq "-gds"){$gdsFile = $ARGV[$i+1];} 
       if($ARGV[$i] eq "-out"){$outFile = $ARGV[$i+1];} 
       if($ARGV[$i] eq "-layer_map_file"){$layerMapFile = $ARGV[$i+1];} 
       if($ARGV[$i] eq "-config_file"){$configFile = $ARGV[$i+1];} 
       if($ARGV[$i] eq "-tolerance"){$tolerance = $ARGV[$i+1];} 
       if($ARGV[$i] eq "--shift_at_origin"){$shift_at_origin = 1;} 
       if($ARGV[$i] eq "--repeate_pin"){$repeate_pin = 1;} 
       if($ARGV[$i] eq "--blkgAsRect"){$blkgAsRect = 1;} 
   }#for correct no.of Arguments

   if($outFile eq ""){ 
      my ($gds_file_name) = (split(/\//,$gdsFile))[-1];
      my ($file_name) = (split(/\./,$gds_file_name))[0];
      $outFile = $file_name.".def";
   }#if file(lef) name is not given
   if($tolerance eq ""){
      $tolerance = 0.0001;
   }

   my %cell_size = ();
   my %boundary_layer_hash = ();
   my %layer_group_hash = ();
   my @final_groups = ();
   my %pin_poly_hash = ();

   my %overlap_layer_hash = ();
   my %via_hash = ();
   my %rev_overlap_layer_hash = ();
   my %rev_via_hash = ();
   my %temp_layer_map = ();
   my %text_layer_hash = ();
   my %layer_vs_dir = ();
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
           my $dir = $layerHash{dir};
           $layer_vs_dir{$layerNum} = $dir;
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
             my $dir = $layerInfoHash{dir};
             $layer_vs_dir{$layerNum} = $dir;
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
          #my ($width, $height) = (0, 0);
          @X_COORDS = sort{$a<=>$b}@X_COORDS;
          @Y_COORDS = sort{$a<=>$b}@Y_COORDS;
          #$width = $X_COORDS[-1] - $X_COORDS[0] if(@X_COORDS > 0);
          #$height = $Y_COORDS[-1] - $Y_COORDS[0] if(@Y_COORDS > 0);
          #$cell_size{$string_name} = [$layer_name, $width, $height];
          $cell_size{$string_name} = [$layer_name, $X_COORDS[0], $Y_COORDS[0], $X_COORDS[-1], $Y_COORDS[-1]];
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
                    #my $width = $x_coords[-1] - $x_coords[0];
                    #my $height = $y_coords[-1] - $y_coords[0];
                    #$cell_size{$string_name} = [$layer_name, $width, $height]; 
                    $cell_size{$string_name} = [$layer_name, $x_coords[0], $y_coords[0], $x_coords[-1], $y_coords[-1]]; 
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
              push(@total_poly, [$layer_name, -1, @poly_coords]);
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
              push(@total_poly, [$path_layer, -1, xformPathSegToPolygon(\@path_coords,$path_data_type, $path_type, $path_width, $path_bgnExtn, $path_endExtn)]);
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
   my $via_group_cnt = 0;
   
   #my $len =  @{$CELL_POLYGONS{$top_module}};
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
                   my $group = shift @poly;
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
                   #push(@{$CELL_POLYGONS{$cell}}, [$layer,$via_group_cnt, @trans_poly]);
                   push(@{$CELL_POLYGONS{$cell}}, [$layer, -1, @trans_poly]);
                   ## adding this line to assign group different for each via poly
                   #print "NOTE: I have changed line 58 to assign different group to each polygon\n" if($via_group_cnt == 0);
                   #$via_group_cnt++;
                 }
             }#foreach col
          }#foreach row
          #$via_group_cnt++;#### commented this line and adding line number:458
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
        my %temp_grp = ();
        my $count = 0;
        my $assigned_grp = 0;
        foreach my $polygon (@poly_data){
          my @poly = @$polygon;
          my $layer = shift @poly; #1st element of @poly is layer
          my $group = shift @poly; #2nd element of @poly is group
         
          if(!exists $boundary_layer_hash{$layer}){next;}
          
          if((!exists $temp_grp{$group}) && $group != -1){
             $temp_grp{$group} = 1;
             $count = 0;
          }

          if((exists $repeat_via_group{$group}) && $group != -1 && $count == 0){
              $assigned_grp = $via_group_cnt;
              $via_group_cnt++;
              $count++;
          }elsif((exists $repeat_via_group{$group}) && $group != -1 && $count > 0){
          }elsif($group != -1){
              $assigned_grp = $group;
              $repeat_via_group{$group} = 1; 
              $count++;
          }else{
              $assigned_grp = $group;
          }

          push(@{$CELL_POLYGONS{$top_module}}, [$layer, $assigned_grp, &transform_sref_inst($strans, $mag, $angle, $shiftX, $shiftY, \@poly)]);
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
   
   my $t1 = new Benchmark;
   my $td = timediff($t1, $t0);
   print "INFO 03:flattening is completed in :",timestr($td),"\n";

   ############ transfer the polygons in %boundary_layer_hash #############
   my %poly_minX_hash = ();
   my %poly_minY_hash = ();
   my %poly_maxX_hash = ();
   my %poly_maxY_hash = ();
   my %poly_maxY_length = ();

   my @data_arr = @{$CELL_POLYGONS{$top_module}};
   foreach my $poly (@data_arr){
     my @polygon = @$poly;
     my $layer = shift @polygon;
     my $group = shift @polygon;
     if(exists $boundary_layer_hash{$layer}){
        #---Making minx,miny,maxx & maxy hash for each layer---#
        if(exists $via_hash{$layer}){
           if($group == -1){
              push(@{$layer_group_hash{$layer}[$via_group_cnt]}, [$layer, @polygon]);
              $via_group_cnt++;
           }else{
              push(@{$layer_group_hash{$layer}[$group]}, [$layer, @polygon]);
           }
        }else{
           my $len = @{$boundary_layer_hash{$layer}};
           push(@{$boundary_layer_hash{$layer}}, [$layer, @polygon]);
           my @x_coords = ();
           my @y_coords = ();
           for(my $i=0; $i<=$#polygon; $i=$i+2){
               push(@x_coords, $polygon[$i]);
               push(@y_coords, $polygon[$i+1]);
           }
           @x_coords = sort{$a<=>$b}@x_coords;
           @y_coords = sort{$a<=>$b}@y_coords;
           
           $poly_minX_hash{$layer}{$len} = $x_coords[0];
           $poly_minY_hash{$layer}{$len} = $y_coords[0];
           $poly_maxX_hash{$layer}{$len} = $x_coords[-1];
           $poly_maxY_hash{$layer}{$len} = $y_coords[-1];
           my $y_length = $y_coords[-1] - $y_coords[0];
           if(!exists $poly_maxY_length{$layer}){
              $poly_maxY_length{$layer} = $y_length;
           }else{
              if($y_length > $poly_maxY_length{$layer}){
                 $poly_maxY_length{$layer} = $y_length;
              }
           }
           ################ added to find refX & refY #################
           if($shift_at_origin == 1){
              if($len == 0){
                 $refX = $x_coords[0];
                 $refY = $y_coords[0];
              }else{
                 if($x_coords[0] < $refX){
                    $refX = $x_coords[0];
                 }
                 if($y_coords[0] < $refY){
                    $refY = $y_coords[0];
                 }
              }
           }
           ############################################################
        }#if Routing layer
        #-----------------------------------------------------#
     }
   }
   
   ########################## added this code to find PIN polygon #######################
   undef %CELL_POLYGONS; #making hash empty

   my $t2 = new Benchmark;
   my $td1 = timediff($t2, $t1);
   #print "transfer data in boundary_layer_hash is completed in :",timestr($td1),"\n";

   ######################################################################################
   ######################## Making groups of Overlapping  Polygon #######################
   ######################################################################################
   my @poly_arr = ();
   my @minY_keys = ();
   my %MINX = ();
   my %MINY = ();
   my %MAXX = ();
   my %MAXY = ();
   my $maxYlen;
   my @total_ovl_poly = ();
   foreach my $l(keys %overlap_layer_hash){
      @poly_arr = @{$boundary_layer_hash{$l}}; ##Global

      %MINX = %{$poly_minX_hash{$l}};
      %MINY = %{$poly_minY_hash{$l}};
      %MAXX = %{$poly_maxX_hash{$l}};
      %MAXY = %{$poly_maxY_hash{$l}};
      $maxYlen = $poly_maxY_length{$l};

      @minY_keys = sort{$MINY{$a}<=>$MINY{$b}} (keys %MINY);
      my @maxY_keys = sort{$MAXY{$a}<=>$MAXY{$b}} (keys %MAXY);

      my @group_arr = ();
      foreach my $maxY_poly_num (@maxY_keys){
          if(ref $poly_arr[$maxY_poly_num] eq ""){next;}
          my $minx = $MINX{$maxY_poly_num};
          my $miny = $MINY{$maxY_poly_num};
          my $maxx = $MAXX{$maxY_poly_num};
          my $maxy = $MAXY{$maxY_poly_num};

          my @sub_poly = @{$poly_arr[$maxY_poly_num]};
          my @overlapped_poly = ();
          my @overlapped_poly_num = ();
          @total_ovl_poly = ();
          my @p = ();
          for(my $k=1; $k<=$#sub_poly; $k=$k+2){
              push(@p,[$sub_poly[$k],$sub_poly[$k+1]]);
          }
          my $num = $miny - $maxYlen;
          my $low_limit = &get_partition(0, $#minY_keys, $num);
          for(my $i=$low_limit; $i<=$#minY_keys; $i++){
              my $minY_poly_num = $minY_keys[$i];
              if(ref $poly_arr[$minY_poly_num] eq ""){next;}

              my $minx1 = $MINX{$minY_poly_num};
              my $miny1 = $MINY{$minY_poly_num};
              my $maxx1 = $MAXX{$minY_poly_num};
              #my $maxy1 = $MAXY{$minY_poly_num};
              #if($maxx < $minx1 || $minx > $maxx1 || $maxY_poly_num == $minY_poly_num){next;}
              #if($maxy < $miny1){last;}
              if(($minx1 - $maxx) > $tolerance || ($minx - $maxx1) > $tolerance || $maxY_poly_num == $minY_poly_num){next;}
              if(($miny1 - $maxy) > $tolerance){last;}

              my @clip_poly = @{$poly_arr[$minY_poly_num]};     
              my @p1 = ();
              for(my $l=1; $l<=$#clip_poly; $l=$l+2){
                  push(@p1,[$clip_poly[$l],$clip_poly[$l+1]]);
              }

              my $clipper = Math::Clipper->new;
              $clipper->add_subject_polygon([@p]);
              $clipper->add_clip_polygon([@p1]);
              my $result = $clipper->execute(CT_INTERSECTION);
              my @result_arr = @$result;
              my $result_arr_len = @result_arr;
              if($result_arr_len > 0){
                 push(@overlapped_poly,[@clip_poly]);
                 push(@overlapped_poly_num,$minY_poly_num);
                 delete $poly_arr[$minY_poly_num];
              }else{
                 my @new_poly = polygon_move(dx=>.0001, @p);
                 my $clip = Math::Clipper->new;
                 $clip->add_subject_polygon([@new_poly]);
                 $clip->add_clip_polygon([@p1]);
                 my $res = $clip->execute(CT_INTERSECTION);
                 my @res_arr = @$res;
                 my $res_arr_len = @res_arr;
                 if($res_arr_len > 0){
                    push(@overlapped_poly,[@clip_poly]);
                    push(@overlapped_poly_num,$minY_poly_num);
                    delete $poly_arr[$minY_poly_num];
                 }else{
                    my @new_poly1 = polygon_move(dx=>-.0001, @p);
                    my $clip1 = Math::Clipper->new;
                    $clip1->add_subject_polygon([@new_poly1]);
                    $clip1->add_clip_polygon([@p1]);
                    my $res1 = $clip1->execute(CT_INTERSECTION);
                    my @res_arr1 = @$res1;
                    my $res_arr_len1 = @res_arr1;
                    if($res_arr_len1 > 0){
                       push(@overlapped_poly,[@clip_poly]);
                       push(@overlapped_poly_num,$minY_poly_num);
                       delete $poly_arr[$minY_poly_num];
                    }else{
                       my @new_poly2 = polygon_move(dy=>.0001, @p);
                       my $clip2 = Math::Clipper->new;
                       $clip2->add_subject_polygon([@new_poly2]);
                       $clip2->add_clip_polygon([@p1]);
                       my $res2 = $clip2->execute(CT_INTERSECTION);
                       my @res_arr2 = @$res2;
                       my $res_arr_len2 = @res_arr2;
                       if($res_arr_len2 > 0){
                          push(@overlapped_poly,[@clip_poly]);
                          push(@overlapped_poly_num,$minY_poly_num);
                          delete $poly_arr[$minY_poly_num];
                       }else{
                          my @new_poly3 = polygon_move(dy=>-.0001, @p);
                          my $clip3 = Math::Clipper->new;
                          $clip3->add_subject_polygon([@new_poly3]);
                          $clip3->add_clip_polygon([@p1]);
                          my $res3 = $clip3->execute(CT_INTERSECTION);
                          my @res_arr3 = @$res3;
                          my $res_arr_len3 = @res_arr3;
                          if($res_arr_len3 > 0){
                             push(@overlapped_poly,[@clip_poly]);
                             push(@overlapped_poly_num,$minY_poly_num);
                             delete $poly_arr[$minY_poly_num];
                          }
                       }
                    }
                 }
              }#if touch
          }
          if($#overlapped_poly >= 0){
             delete $poly_arr[$maxY_poly_num];
             &get_overlap_poly(\@overlapped_poly_num, \@overlapped_poly);
             push(@overlapped_poly, @total_ovl_poly);
             unshift(@overlapped_poly,[@sub_poly]);
             #-------- making group array ------#
             push(@group_arr,[@overlapped_poly]);
          }else{
             delete $poly_arr[$maxY_poly_num];
             push(@group_arr,[[@sub_poly]]);
          }
      }
      @{$layer_group_hash{$l}} = @group_arr;
   }
    
   ###################### Removing from memory ######################
   undef @poly_arr;
   undef @total_ovl_poly;
   undef %poly_minX_hash;
   undef %poly_minY_hash;
   undef %poly_maxX_hash;
   undef %poly_maxY_hash;
   undef %poly_maxY_length;
   undef %MINX;
   undef %MINY;
   undef %MAXX;
   undef %MAXY;
   undef %boundary_layer_hash = (); 
   #################################################################

   ########## Recursive function to get groups of polygons for indivisual layer #########
   sub get_overlap_poly{
     my @sub_poly_num_arr = @{$_[0]};
     my @ovl_poly_coords_arr = @{$_[1]};

     foreach my $maxY_poly_num(@sub_poly_num_arr){
         my $minx = $MINX{$maxY_poly_num};
         my $miny = $MINY{$maxY_poly_num};
         my $maxx = $MAXX{$maxY_poly_num};
         my $maxy = $MAXY{$maxY_poly_num};

         my @sub_poly = @{shift @ovl_poly_coords_arr};
         my @ovl_poly = ();
         my @ovl_poly_num = ();
         my @p = ();
         for(my $k=1; $k<=$#sub_poly; $k=$k+2){
             push(@p,[$sub_poly[$k],$sub_poly[$k+1]]);
         }
         my $num = $miny - $maxYlen;
         my $low_limit = &get_partition(0, $#minY_keys, $num); 
         for(my $i=$low_limit; $i<=$#minY_keys; $i++){
             my $minY_poly_num = $minY_keys[$i];
             if(ref $poly_arr[$minY_poly_num] eq ""){next;}

             my $minx1 = $MINX{$minY_poly_num};
             my $miny1 = $MINY{$minY_poly_num};
             my $maxx1 = $MAXX{$minY_poly_num};
             #my $maxy1 = $MAXY{$minY_poly_num};
             #if($maxx < $minx1 || $minx > $maxx1 || $maxY_poly_num == $minY_poly_num){print "next\n";next;}
             #if($maxy < $miny1){ print "$maxy < $miny1 last\n";last;}
             if(($minx1 - $maxx) > $tolerance || ($minx - $maxx1) > $tolerance || $maxY_poly_num == $minY_poly_num){next;}
             if(($miny1 - $maxy) > $tolerance){last;}

             my @clip_poly = @{$poly_arr[$minY_poly_num]};     
             my @p1 = ();
             for(my $l=1; $l<=$#clip_poly; $l=$l+2){
                 push(@p1,[$clip_poly[$l],$clip_poly[$l+1]]);
             }
             my $clipper = Math::Clipper->new;
             $clipper->add_subject_polygon([@p]);
             $clipper->add_clip_polygon([@p1]);
             my $result = $clipper->execute(CT_INTERSECTION);
             my @result_arr = @$result;
             my $result_arr_len = @result_arr;
             if($result_arr_len > 0){
                push(@ovl_poly,[@clip_poly]);
                push(@ovl_poly_num,$minY_poly_num);
                delete $poly_arr[$minY_poly_num];
             }else{
                my @new_poly = polygon_move(dx=>.0001, @p);
                my $clip = Math::Clipper->new;
                $clip->add_subject_polygon([@new_poly]);
                $clip->add_clip_polygon([@p1]);
                my $res = $clip->execute(CT_INTERSECTION);
                my @res_arr = @$res;
                my $res_arr_len = @res_arr;
                if($res_arr_len > 0){
                   push(@ovl_poly,[@clip_poly]);
                   push(@ovl_poly_num,$minY_poly_num);
                   delete $poly_arr[$minY_poly_num];
                }else{
                   my @new_poly1 = polygon_move(dx=>-.0001, @p);
                   my $clip1 = Math::Clipper->new;
                   $clip1->add_subject_polygon([@new_poly1]);
                   $clip1->add_clip_polygon([@p1]);
                   my $res1 = $clip1->execute(CT_INTERSECTION);
                   my @res_arr1 = @$res1;
                   my $res_arr_len1 = @res_arr1;
                   if($res_arr_len1 > 0){
                      push(@ovl_poly,[@clip_poly]);
                      push(@ovl_poly_num,$minY_poly_num);
                      delete $poly_arr[$minY_poly_num];
                   }else{
                      my @new_poly2 = polygon_move(dy=>.0001, @p);
                      my $clip2 = Math::Clipper->new;
                      $clip2->add_subject_polygon([@new_poly2]);
                      $clip2->add_clip_polygon([@p1]);
                      my $res2 = $clip2->execute(CT_INTERSECTION);
                      my @res_arr2 = @$res2;
                      my $res_arr_len2 = @res_arr2;
                      if($res_arr_len2 > 0){
                         push(@ovl_poly,[@clip_poly]);
                         push(@ovl_poly_num,$minY_poly_num);
                         delete $poly_arr[$minY_poly_num];
                      }else{
                         my @new_poly3 = polygon_move(dy=>-.0001, @p);
                         my $clip3 = Math::Clipper->new;
                         $clip3->add_subject_polygon([@new_poly3]);
                         $clip3->add_clip_polygon([@p1]);
                         my $res3 = $clip3->execute(CT_INTERSECTION);
                         my @res_arr3 = @$res3;
                         my $res_arr_len3 = @res_arr3;
                         if($res_arr_len3 > 0){
                            push(@ovl_poly,[@clip_poly]);
                            push(@ovl_poly_num,$minY_poly_num);
                            delete $poly_arr[$minY_poly_num];
                         }
                      }
                   }
                }
             }
         }
         if($#ovl_poly >= 0){
            push(@total_ovl_poly, @ovl_poly);
            &get_overlap_poly(\@ovl_poly_num, \@ovl_poly);
         }
     }
   }#sub get_overlap_poly

   sub get_partition{
     my $min_ele = $_[0];
     my $max_ele = $_[1];
     my $num = $_[2];
     my $length = $max_ele - $min_ele + 1;
     if($length <= 2){return $min_ele;}
     
     my $mid_num = $length/2;
     my $int_mid_num = int($mid_num);
     if($num <= $MINY{$minY_keys[$min_ele]}){
        return $min_ele;
     }elsif($num > $MINY{$minY_keys[$max_ele]}){
        return $max_ele;
     }elsif($num  <= $MINY{$minY_keys[$min_ele + $int_mid_num]}){
        return get_partition($min_ele, $min_ele + $int_mid_num , $num);
     }else{
        return get_partition($min_ele+$int_mid_num+1, $max_ele, $num);
     }   
   }#sub get_partition


   my $t3 = new Benchmark;
   my $td2 = timediff($t3, $t2);
   #print "Making group in same layer complete :",timestr($td2),"\n";
   
   ############### making hashs of groups for minx, maxx, miny & maxy ################
   my %group_poly_minX_hash = ();
   my %group_poly_minY_hash = ();  
   my %group_poly_maxX_hash = ();  
   my %group_poly_maxY_hash = ();  
   my %group_poly_maxY_length = ();

   foreach my $layer (keys %layer_group_hash){
      my @groups = @{$layer_group_hash{$layer}};
      my $group_cnt = 0;
      foreach my $group (@groups){
         if(ref $group eq ""){$group_cnt++; next;}
         my @poly = @$group;
         my $poly_cnt = 0;
         foreach my $p (@poly){
           my @polygon = @$p;
           my @x_coords = ();
           my @y_coords = ();
           for(my $i=1; $i<=$#polygon; $i=$i+2){
               push(@x_coords, $polygon[$i]);
               push(@y_coords, $polygon[$i+1]);
           }
           @x_coords = sort{$a<=>$b}@x_coords;
           @y_coords = sort{$a<=>$b}@y_coords;
           if(exists $via_hash{$layer}){
              $group_poly_minX_hash{$layer}{$group_cnt} = $x_coords[0];
              $group_poly_minY_hash{$layer}{$group_cnt} = $y_coords[0];
              $group_poly_maxX_hash{$layer}{$group_cnt} = $x_coords[-1];
              $group_poly_maxY_hash{$layer}{$group_cnt} = $y_coords[-1];
              my $y_length = $y_coords[-1] - $y_coords[0];
              if(!exists $group_poly_maxY_length{$layer}){
                 $group_poly_maxY_length{$layer} = $y_length;
              }else{
                 if($y_length > $group_poly_maxY_length{$layer}){
                    $group_poly_maxY_length{$layer} = $y_length;
                 }
              }
              last;
           }else{
              $group_poly_minX_hash{$layer}{$group_cnt}{$poly_cnt} = $x_coords[0];
              $group_poly_minY_hash{$layer}{$group_cnt}{$poly_cnt} = $y_coords[0];
              $group_poly_maxX_hash{$layer}{$group_cnt}{$poly_cnt} = $x_coords[-1];
              $group_poly_maxY_hash{$layer}{$group_cnt}{$poly_cnt} = $y_coords[-1];
              my $y_length = $y_coords[-1] - $y_coords[0];
              if(!exists $group_poly_maxY_length{$layer}{$group_cnt}){
                 $group_poly_maxY_length{$layer}{$group_cnt} = $y_length;
              }else{
                 if($y_length > $group_poly_maxY_length{$layer}{$group_cnt}){
                    $group_poly_maxY_length{$layer}{$group_cnt} = $y_length;
                 }
              }
           } 
           $poly_cnt++;
         }
         $group_cnt++;
      }
   }
   my $t4 = new Benchmark;
   my $td3 = timediff($t4, $t3);
   #print "Making hashes complete :",timestr($td3),"\n";

   ###################################################################################
   ################# Making Final groups of polygons (combined layers) ############### 
   ###################################################################################
   my @group_poly = ();
   foreach my $layer (sort{$a<=>$b}keys %overlap_layer_hash){
     @layer_group = @{$layer_group_hash{$layer}}; ##Global
     for(my $i=0; $i<=$#layer_group; $i++){
         if(ref $layer_group[$i] eq ""){next;}
         @group_poly = ();
         delete $layer_group_hash{$layer}[$i];
         push(@group_poly, @{$layer_group[$i]});
         &get_hier_overlap($layer, $layer_group[$i], $layer);
         #&get_rev_hier_overlap($layer, $layer_group[$i], $layer);
         push(@final_groups, [@group_poly]);
     }#foreach group
   }#foreach layer
   
   ######## Removing from memory ##########
   undef %group_poly_minX_hash;
   undef %group_poly_minY_hash;
   undef %group_poly_maxX_hash;
   undef %group_poly_maxY_hash;
   undef %group_poly_maxY_length;

   ########################################
   sub get_hier_overlap {
     my $layer = $_[0];
     my $group = $_[1];
     my $starting_layer = $_[2];

     my @via_overlapped = ();

     my $via_layer = $overlap_layer_hash{$layer};
     if(!exists $via_hash{$via_layer}){return;}
     my @via_poly_grp = @{$layer_group_hash{$via_layer}};
     my %VIA_MINX = %{$group_poly_minX_hash{$via_layer}};
     my %VIA_MINY = %{$group_poly_minY_hash{$via_layer}};
     my %VIA_MAXX = %{$group_poly_maxX_hash{$via_layer}};
     #my %VIA_MAXY = %{$group_poly_maxY_hash{$via_layer}};
     #my @minY_rect = sort{$VIA_MINY{$a}<=>$VIA_MINY{$b}} (keys %VIA_MINY);

     my $max_len = $group_poly_maxY_length{$via_layer};

     foreach my $poly (@$group){
        my @sub_poly = @$poly;
        my @p = ();
        for(my $i=1; $i<=$#sub_poly; $i=$i+2){
            push(@p,[$sub_poly[$i],$sub_poly[$i+1]]);
        }

        my ($minx, $miny, $maxx, $maxy) = polygon_bbox @p;

        my @minY_rect = sort{$VIA_MINY{$a}<=>$VIA_MINY{$b}} (keys %VIA_MINY);
        my $num = $miny - $max_len;
        my $lower_limit = &get_lower_limit(0, $#minY_rect, $num, \%VIA_MINY, \@minY_rect);

        for(my $j=$lower_limit; $j<=$#minY_rect; $j++){
            my $minY_poly_num = $minY_rect[$j];
            if(ref $via_poly_grp[$minY_poly_num] eq ""){next;}

            my $minx1 = $VIA_MINX{$minY_poly_num};
            my $miny1 = $VIA_MINY{$minY_poly_num};
            my $maxx1 = $VIA_MAXX{$minY_poly_num};
            #my $maxy1 = $VIA_MAXY{$minY_poly_num};
            #if($maxx < $minx1 || $minx > $maxx1){next;}
            #if($maxy < $miny1){last;}
            if(($minx1 - $maxx) > $tolerance || ($minx - $maxx1) > $tolerance){next;}
            if(($miny1 - $maxy) > $tolerance){last;}

            my @clip_poly = @{$via_poly_grp[$minY_poly_num][0]};
            my @p1 = ();
            for(my $k=1; $k<=$#clip_poly; $k=$k+2){
                push(@p1,[$clip_poly[$k],$clip_poly[$k+1]]);
            }

            my $clipper = Math::Clipper->new;
            $clipper->add_subject_polygon([@p]);
            $clipper->add_clip_polygon([@p1]);

            my $result = $clipper->execute(CT_INTERSECTION);
            my @result_arr = @$result;
            my $result_arr_len = @result_arr;
            if($result_arr_len > 0){
               push(@via_overlapped,[@clip_poly]);
               push(@group_poly, @{$via_poly_grp[$minY_poly_num]});
               delete $layer_group_hash{$via_layer}[$minY_poly_num];
               delete $group_poly_minX_hash{$via_layer}{$minY_poly_num};
               delete $group_poly_minY_hash{$via_layer}{$minY_poly_num};
               delete $group_poly_maxX_hash{$via_layer}{$minY_poly_num};
               delete $group_poly_maxY_hash{$via_layer}{$minY_poly_num};
               delete $via_poly_grp[$minY_poly_num];
               delete $VIA_MINX{$minY_poly_num}; 
               delete $VIA_MINY{$minY_poly_num}; 
               delete $VIA_MAXX{$minY_poly_num}; 
               delete $VIA_MAXY{$minY_poly_num}; 
            }
        }#for each poly
     }#foreach polygon
     #my $second_layer = $via_hash{$via_layer};
     #my @second_lgrp = @{$layer_group_hash{$second_layer}};
     for(my $i=0; $i<=$#via_overlapped; $i++){
         my @via_poly = @{$via_overlapped[$i]}; 
         my $second_layer = $via_hash{$via_layer};
         my @second_lgrp = @{$layer_group_hash{$second_layer}};

         my @p = ();
         for(my $k=1; $k<=$#via_poly; $k=$k+2){
             push(@p,[$via_poly[$k],$via_poly[$k+1]]);
         }
         my ($minx, $miny, $maxx, $maxy) = polygon_bbox @p;

         LOOPA: for(my $j=0; $j<=$#second_lgrp; $j++){
	     if(ref $second_lgrp[$j] eq ""){next;}
             my %POLY_MINX = %{$group_poly_minX_hash{$second_layer}{$j}};
             my %POLY_MINY = %{$group_poly_minY_hash{$second_layer}{$j}};
             my %POLY_MAXX = %{$group_poly_maxX_hash{$second_layer}{$j}};
             #my %POLY_MAXY = %{$group_poly_maxY_hash{$second_layer}{$j}};
             my @minY_rect = sort{$POLY_MINY{$a}<=>$POLY_MINY{$b}} (keys %POLY_MINY);

             my $max_len = $group_poly_maxY_length{$second_layer}{$j};
             my $num = $miny - $max_len;
             my $lower_limit = &get_lower_limit(0, $#minY_rect, $num, \%POLY_MINY, \@minY_rect);

             for(my $l=$lower_limit; $l<=$#minY_rect; $l++){
                 my $minY_poly_num = $minY_rect[$l];
                 my $minx1 = $POLY_MINX{$minY_poly_num};
                 my $miny1 = $POLY_MINY{$minY_poly_num};
                 my $maxx1 = $POLY_MAXX{$minY_poly_num};
                 #my $maxy1 = $POLY_MAXY{$minY_poly_num};
                 #if($maxx < $minx1 || $minx > $maxx1){next;}
                 #if($maxy < $miny1){last;}
                 if(($minx1 - $maxx) > $tolerance || ($minx - $maxx1) > $tolerance){next;}
                 if(($miny1 - $maxy) > $tolerance){last;}

                 my @clip_poly = @{$second_lgrp[$j][$minY_poly_num]};
                 my @p1 = ();
                 for(my $k=1; $k<=$#clip_poly; $k=$k+2){
                     push(@p1,[$clip_poly[$k],$clip_poly[$k+1]]);
                 }

                 my $clipper = Math::Clipper->new;
                 $clipper->add_subject_polygon([@p]);
                 $clipper->add_clip_polygon([@p1]);
                 my $result = $clipper->execute(CT_INTERSECTION);
                 my @result_arr = @$result;
                 my $result_arr_len = @result_arr;
                 if($result_arr_len > 0){
                    push(@group_poly, @{$second_lgrp[$j]});
                    delete $layer_group_hash{$second_layer}[$j];
                    my $grp = $second_lgrp[$j];
                    delete $second_lgrp[$j];
                    delete $group_poly_minX_hash{$second_layer}{$j};
                    delete $group_poly_minY_hash{$second_layer}{$j};
                    delete $group_poly_maxX_hash{$second_layer}{$j};
                    delete $group_poly_maxY_hash{$second_layer}{$j};
                    &get_rev_hier_overlap($second_layer, $grp, $starting_layer);
                    &get_hier_overlap($second_layer, $grp, $starting_layer);
                    last LOOPA;
	         }
	    }
      }
     }
   }#sub get_hier_overlap

   sub get_rev_hier_overlap {
     my $layer = $_[0];
     my $group = $_[1];
     my $starting_layer = $_[2];

     my @rev_via_overlapped = ();

     my $rev_via_layer = $rev_overlap_layer_hash{$layer};
     if(!exists $via_hash{$rev_via_layer}){return;}
     my @rev_via_poly_grp = @{$layer_group_hash{$rev_via_layer}};
     my %VIA_MINX = %{$group_poly_minX_hash{$rev_via_layer}};
     my %VIA_MINY = %{$group_poly_minY_hash{$rev_via_layer}};
     my %VIA_MAXX = %{$group_poly_maxX_hash{$rev_via_layer}};
     #my %VIA_MAXY = %{$group_poly_maxY_hash{$rev_via_layer}};
     #my @minY_rect = sort{$VIA_MINY{$a}<=>$VIA_MINY{$b}} (keys %VIA_MINY);

     my $max_len = $group_poly_maxY_length{$rev_via_layer};

     foreach my $poly (@$group){
        my @sub_poly = @$poly;
        my @p = ();
        for(my $i=1; $i<=$#sub_poly; $i=$i+2){
            push(@p,[$sub_poly[$i],$sub_poly[$i+1]]);
        }

        my ($minx, $miny, $maxx, $maxy) = polygon_bbox @p;

        my @minY_rect = sort{$VIA_MINY{$a}<=>$VIA_MINY{$b}} (keys %VIA_MINY);
        my $num = $miny - $max_len;
        my $lower_limit = &get_lower_limit(0, $#minY_rect, $num, \%VIA_MINY, \@minY_rect);

        for(my $j=$lower_limit; $j<=$#minY_rect; $j++){
            my $minY_poly_num = $minY_rect[$j];
            if(ref $rev_via_poly_grp[$minY_poly_num] eq ""){next;}

            my $minx1 = $VIA_MINX{$minY_poly_num};
            my $miny1 = $VIA_MINY{$minY_poly_num};
            my $maxx1 = $VIA_MAXX{$minY_poly_num};
            #my $maxy1 = $VIA_MAXY{$minY_poly_num};
            #if($maxx < $minx1 || $minx > $maxx1){next;}
            #if($maxy < $miny1){last;}
            if(($minx1 - $maxx) > $tolerance || ($minx - $maxx1) > $tolerance){next;}
            if(($miny1 - $maxy) > $tolerance){last;}

            my @clip_poly = @{$rev_via_poly_grp[$minY_poly_num][0]};
            my @p1 = ();
            for(my $k=1; $k<=$#clip_poly; $k=$k+2){
                push(@p1,[$clip_poly[$k],$clip_poly[$k+1]]);
            }

            my $clipper = Math::Clipper->new;
            $clipper->add_subject_polygon([@p]);
            $clipper->add_clip_polygon([@p1]);
            my $result = $clipper->execute(CT_INTERSECTION);
            my @result_arr = @$result;
            my $result_arr_len = @result_arr;
            if($result_arr_len > 0){
               push(@rev_via_overlapped,[@clip_poly]);
               push(@group_poly, @{$rev_via_poly_grp[$minY_poly_num]});
               delete $layer_group_hash{$rev_via_layer}[$minY_poly_num];
               delete $group_poly_minX_hash{$rev_via_layer}{$minY_poly_num};
               delete $group_poly_minY_hash{$rev_via_layer}{$minY_poly_num};
               delete $group_poly_maxX_hash{$rev_via_layer}{$minY_poly_num};
               delete $group_poly_maxY_hash{$rev_via_layer}{$minY_poly_num};
               delete $rev_via_poly_grp[$minY_poly_num];
               delete $VIA_MINX{$minY_poly_num}; 
               delete $VIA_MINY{$minY_poly_num}; 
               delete $VIA_MAXX{$minY_poly_num}; 
               delete $VIA_MAXY{$minY_poly_num}; 
            }
        }
     }#foreach polygon
     #my $first_layer = $rev_via_hash{$rev_via_layer};
     #my @first_lgrp = @{$layer_group_hash{$first_layer}};
     for(my $i=0; $i<=$#rev_via_overlapped; $i++){
         my @via_poly = @{$rev_via_overlapped[$i]}; 
         my $first_layer = $rev_via_hash{$rev_via_layer};
         my @first_lgrp = @{$layer_group_hash{$first_layer}};

         my @p = ();
         for(my $j=1; $j<=$#via_poly; $j=$j+2){
             push(@p,[$via_poly[$j],$via_poly[$j+1]]);
         }
         my ($minx, $miny, $maxx, $maxy) = polygon_bbox @p;

         LOOPB:for(my $j=0; $j<=$#first_lgrp; $j++){
             if(ref $first_lgrp[$j] eq ""){next;}
             my %POLY_MINX = %{$group_poly_minX_hash{$first_layer}{$j}};
             my %POLY_MINY = %{$group_poly_minY_hash{$first_layer}{$j}};
             my %POLY_MAXX = %{$group_poly_maxX_hash{$first_layer}{$j}};
             #my %POLY_MAXY = %{$group_poly_maxY_hash{$first_layer}{$j}};
             my @minY_rect = sort{$POLY_MINY{$a}<=>$POLY_MINY{$b}} (keys %POLY_MINY);

             my $max_len = $group_poly_maxY_length{$first_layer}{$j};
             my $num = $miny - $max_len;
             my $lower_limit = &get_lower_limit(0, $#minY_rect, $num, \%POLY_MINY, \@minY_rect);

             for(my $l=$lower_limit; $l<=$#minY_rect; $l++){
                 my $minY_poly_num = $minY_rect[$l];
                 my $minx1 = $POLY_MINX{$minY_poly_num};
                 my $miny1 = $POLY_MINY{$minY_poly_num};
                 my $maxx1 = $POLY_MAXX{$minY_poly_num};
                 #my $maxy1 = $POLY_MAXY{$minY_poly_num};
                 #if($maxx < $minx1 || $minx > $maxx1){next;}
                 #if($maxy < $miny1){last;}
                 if(($minx1 - $maxx) > $tolerance || ($minx - $maxx1) > $tolerance){next;}
                 if(($miny1 - $maxy) > $tolerance){last;}

                 my @clip_poly = @{$first_lgrp[$j][$minY_poly_num]};
                 my @p1 = ();
                 for(my $k=1; $k<=$#clip_poly; $k=$k+2){
                     push(@p1,[$clip_poly[$k],$clip_poly[$k+1]]);
                 }

                 my $clipper = Math::Clipper->new;
                 $clipper->add_subject_polygon([@p]);
                 $clipper->add_clip_polygon([@p1]);
                 my $result = $clipper->execute(CT_INTERSECTION);
                 my @result_arr = @$result;
                 my $result_arr_len = @result_arr;
                 if($result_arr_len > 0){
                    push(@group_poly, @{$first_lgrp[$j]});
                    delete $layer_group_hash{$first_layer}[$j];
                    my $grp = $first_lgrp[$j];
                    delete $first_lgrp[$j];
                    if($starting_layer == $first_layer){
                       delete $layer_group[$j];
                    }
                    delete $group_poly_minX_hash{$first_layer}{$j};
                    delete $group_poly_minY_hash{$first_layer}{$j};
                    delete $group_poly_maxX_hash{$first_layer}{$j};
                    delete $group_poly_maxY_hash{$first_layer}{$j};
                    &get_hier_overlap($first_layer, $grp, $starting_layer);
                    &get_rev_hier_overlap($first_layer, $grp, $starting_layer);
                    last LOOPB;
                 }
             }
         }
     }
   }#sub get_rev_hier_overlap

   sub get_lower_limit{
     my $min_ele = $_[0];
     my $max_ele = $_[1];
     my $num = $_[2];
     my %TEMP = %{$_[3]};
     my @y_arr = @{$_[4]};

     my $max = $TEMP{$y_arr[$max_ele]};
     my $length = $max_ele - $min_ele + 1;

     if($length <= 2){return $min_ele;}
     
     my $mid_num = $length/2;
     my $int_mid_num = int($mid_num);

     if($num <= $TEMP{$y_arr[$min_ele]}){
        return $min_ele;
     }elsif($num > $TEMP{$y_arr[$max_ele]}){
        return $max_ele;
     }elsif($num <= $TEMP{$y_arr[$min_ele + $int_mid_num]}){
        &get_lower_limit($min_ele, $min_ele + $int_mid_num , $num, \%TEMP, \@y_arr);
     }else{
        &get_lower_limit($min_ele+$int_mid_num+1, $max_ele, $num, \%TEMP, \@y_arr);
     }   

   }#sub get_lower_limit

   my $t5 = new Benchmark;
   my $td4 = timediff($t5, $t4);
   #print "Making final group complete :",timestr($td4),"\n";
   
   ######################################################################
   ####################### Making pin's group ########################### 
   ######################################################################
   my @pins = ();
   if($label_level eq "" || $label_level eq "top"){
      push(@pins, @{$PIN_TEXT_COORDS{$top_module}});
   }else{
      foreach my $cell (keys %PIN_TEXT_COORDS){
        push(@pins, @{$PIN_TEXT_COORDS{$cell}});
      }
   }
   
   ###############################################################
   my %pin_exact_polygon = ();
   my @blkg_poly = ();
   for(my $i=0; $i<=$#final_groups; $i++){
       #print "FINAL_GROUP:$i\n";
       if($final_groups[$i] eq ""){next;}
       my $group = $final_groups[$i];
       my $isInside = 0;
       LOOPC:foreach my $poly (@$group){
         my @poly_coords = @$poly;
         my $poly_layer = $poly_coords[0];
         my @p = ();
         for(my $j=1; $j<=$#poly_coords; $j=$j+2){
             push(@p,[$poly_coords[$j],$poly_coords[$j+1]]);
         }
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
           if($isInside !=1){
              $isInside = $polygon->contains([$pin_point[0] + 0.0001, $pin_point[1] + 0.0001]);
              if($isInside ==  1){
              }else{
                 $isInside = $polygon->contains([$pin_point[0] - 0.0001, $pin_point[1] + 0.0001]);
                 if($isInside ==  1){
                 }else{
                    $isInside = $polygon->contains([$pin_point[0] + 0.0001, $pin_point[1] - 0.0001]);
                    if($isInside ==  1){
                    }else{
                       $isInside = $polygon->contains([$pin_point[0] - 0.0001, $pin_point[1] - 0.0001]);
                    }   
                 }   
              }   
           }
           if($isInside == 1){
              if(exists $pin_poly_hash{$pin}){
                 push(@{$pin_poly_hash{$pin}}, @{$final_groups[$i]});
                 push(@{$pin_exact_polygon{$pin}} ,[$pin_layer, @pin_point, @poly_coords]);
                 #print "rpin:$pin rpoly:@poly_coords\n";
              }else{
                 @{$pin_poly_hash{$pin}} = @{$final_groups[$i]};
                 @{$pin_exact_polygon{$pin}} = ([$pin_layer, @pin_point, @poly_coords]);
                 #print "pin:$pin poly:@poly_coords\n";
              }
              delete $final_groups[$i];
              splice @pins,$count,1;
              last LOOPC;
           }
         }#foreach pin
       }#foreach polygon
       if($isInside == 0){
          push(@blkg_poly, @{$final_groups[$i]});
       }
   }#foreach group
  
   my $t6 = new Benchmark;
   my $td5 = timediff($t6, $t5);
   #print "Making pin group complete :",timestr($td5),"\n";

   @final_groups = (); #making array empty
   
   ################### making hash of routing blkg ###################
   #my $numOfPoly = @blkg_poly;
   #print "num_of_poly $numOfPoly\n";
   my %routing_blkg_hash = ();
   while(@blkg_poly > 0){
     my @poly = @{shift @blkg_poly};
     my $poly_layer = shift @poly;
     if(exists $overlap_layer_hash{$poly_layer}){
        push(@{$routing_blkg_hash{$poly_layer}}, [@poly]);
     } 
   }

   ######################################################################
   #my ($layerName,$width, $height) = @{$cell_size{$top_module}};
   #print "ref:$refX,$refY\n";
   my ($layerName,$chip_llx, $chip_lly, $chip_urx, $chip_ury) = @{$cell_size{$top_module}};
   my $chip_width = ($chip_urx - $chip_llx);
   my $chip_height = ($chip_ury - $chip_lly);
   my $unit_distance = 1/$uu;
   
   open ( WRITE, ">$outFile");
   print WRITE "VERSION 5.5 \;\n";
   print WRITE "NAMESCASESENSITIVE ON \;\n";
   print WRITE "DIVIDERCHAR \"\/\" \;\n";
   print WRITE "BUSBITCHARS \"\[\]\" \;\n";
   print WRITE "DESIGN $top_module \;\n";
   print WRITE "UNITS DISTANCE MICRONS $unit_distance \;\n";
   print WRITE "DIEAREA ( 0 0 ) ( $chip_width $chip_height ) \;\n";
   
   ################ writing  pins #########################
   my $pinCnt = 0;
   foreach my $orig_pin (keys %pin_exact_polygon){
     my @val = @{$pin_exact_polygon{$orig_pin}};
     $pinCnt += @val;
   }
   print WRITE "PINS $pinCnt \;\n";
   foreach my $orig_pin (keys %pin_exact_polygon){
     my @poly_line = @{$pin_exact_polygon{$orig_pin}};
     for($i=0; $i<@poly_line; $i++){
         my $orient = "N";
         my $dir = "input";
         my $route_width = 0;
         my $dup_pin = $orig_pin;
         if($i > 0){$dup_pin .= '.extra'.$i;}
         my @polygon = @{$poly_line[$i]};
         my $pin_layer = shift @polygon;
         my $pin_llx = shift @polygon;
         my $pin_lly = shift @polygon;
         my $poly_layer = shift @polygon;
         my @p = ();
         for(my $j=0; $j<=$#polygon; $j=$j+2){
             push(@p,[$polygon[$j],$polygon[$j+1]]);
         }
         my ($llx, $lly, $urx, $ury) = polygon_bbox @p;
         if($layer_vs_dir{$poly_layer} eq 'HORIZONTAL'){ 
            $route_width = abs($ury - $lly); 
         }elsif($layer_vs_dir{$poly_layer} eq 'VERTICAL'){
            $route_width = abs($urx - $llx); 
         } 
         $pin_llx -= $refX;
         $pin_lly -= $refY;
         my @rect_coord = (-$route_width/2, 0, $route_width/2, $route_width);

         print WRITE "\- $dup_pin \+ NET $dup_pin \+ DIRECTION $dir \+ USE SIGNAL\n";
         print WRITE " \+ LAYER $temp_layer_map{$poly_layer} \( $rect_coord[0] $rect_coord[1] \) \( $rect_coord[2] $rect_coord[3] \)\n";
         print WRITE " \+ PLACED \( $pin_llx $pin_lly \) $orient \;\n";
         if($repeate_pin == 0){last;}
     }
   }
   print WRITE "END PINS\n\n";

   #################### writing blockage #########################
   my $rBlkgCnt = keys %routing_blkg_hash;
   print WRITE "BLOCKAGES $rBlkgCnt \;\n";
   foreach my $rBlkg (keys %routing_blkg_hash){
      print WRITE "  - LAYER $temp_layer_map{$rBlkg}\n";
      my @polygons = @{$routing_blkg_hash{$rBlkg}};
      while(@polygons > 0){
         my @poly = @{shift @polygons};
         if($blkgAsRect == 1){
            if(($poly[8] == $poly[10]) && ($poly[9] == $poly[11])){#exceptional case (bug)
                @poly = ($poly[0], $poly[1], $poly[2], $poly[3], $poly[4], $poly[5], $poly[6], $poly[7], $poly[12], $poly[13]);
            }
            my @rectArr = &break_polygon_into_rects(\@poly);
            while(@rectArr > 0){
               my @coords = @{shift @rectArr};
               if(@rectArr == 0 && @polygons == 0){
                  print WRITE "\t RECT ( $coords[0] $coords[1] ) ( $coords[2] $coords[3] ) ;\n";
               }else{
                  print WRITE "\t RECT ( $coords[0] $coords[1] ) ( $coords[2] $coords[3] )\n";
               }
            }
         }else{
            for(my $i=0; $i<@poly; $i=$i+2){
                if($i == 0){
                   print WRITE "\t POLYGON ( $poly[$i] $poly[$i+1] )";
                }else{
                   if($poly[$i] == $poly[$i-2]){
                      print WRITE " ( * $poly[$i+1] )";
                   }elsif($poly[$i+1] == $poly[$i-1]){
                      print WRITE " ( $poly[$i] * )";
                   }else{
                      print WRITE " ( $poly[$i] $poly[$i+1] )";
                   }
                }
                if($i == ($#poly - 1) && @polygons == 0){
                   print WRITE " ; \n";
                }elsif($i == ($#poly - 1)){
                   print WRITE "\n";
                }
            }
         }
      }
   }
   print WRITE "END BLOCKAGES\n\n";

   ################ writing special nets #########################
   my $spnetCnt = keys %pin_poly_hash;
   print WRITE "SPECIALNETS $spnetCnt \;\n";
   foreach my $pin(keys %pin_poly_hash){
     my $signal_type = 'SIGNAL';
     if($pin =~ /vss|gnd/i){
        $signal_type = 'GROUND';
     }elsif($pin =~ /vdd/i){
        $signal_type = 'POWER';
     }

     print WRITE "  - $pin\n";
     my @poly = @{$pin_poly_hash{$pin}};
     my $write_first_seg = 0;
     for(my $i=0; $i<@poly; $i++){
       my @polygon = @{$poly[$i]};
       #print "polygon:@polygon\n";
       my $layer = shift @polygon;
       if(@polygon <= 10){
          my @p = ();
          for(my $j=0; $j<=$#polygon; $j=$j+2){
              push(@p,[$polygon[$j],$polygon[$j+1]]);
          }

          my ($llx, $lly, $urx, $ury) = polygon_bbox @p;
          $llx -= $refX;
          $lly -= $refY;
          $urx -= $refX;
          $ury -= $refY;
          
          #print "bbox:$llx, $lly, $urx, $ury\n";
          if($layer_vs_dir{$layer} eq 'HORIZONTAL'){
             my $midy = $lly + ($ury - $lly)/2;
             my $width = ($ury - $lly);
             if($write_first_seg == 0){
                print WRITE "\t \+ ROUTED $temp_layer_map{$layer} $width + SHAPE COREWIRE ( $llx $midy ) ( $urx * )\n";
                $write_first_seg = 1;
             }else{
                print WRITE "\t NEW $temp_layer_map{$layer} $width + SHAPE COREWIRE ( $llx $midy ) ( $urx * )\n";
             }
          }elsif($layer_vs_dir{$layer} eq 'VERTICAL'){
             my $midx =  $llx + ($urx - $llx)/2;
             my $width = ($urx - $llx);
             if($write_first_seg == 0){
                print WRITE "\t \+ ROUTED $temp_layer_map{$layer} $width + SHAPE COREWIRE ( $midx $lly ) ( * $ury )\n";
                $write_first_seg = 1;
             }else{
                print WRITE "\t NEW $temp_layer_map{$layer} $width + SHAPE COREWIRE ( $midx $lly ) ( * $ury )\n";
             }
          }else{
             #print "$temp_layer_map{$layer} @polygon\n"; #via polygons
          }
       }else{
          print "WARN:It is not a rectangel:@polygon\n";
       }
     }
     print WRITE "\t + USE $signal_type\n";
     print WRITE " \t\;\n";
   }  
   
   print WRITE "END SPECIALNETS\n";

   print WRITE "END DESIGN\n";
   close WRITE;

   ####################### End of Script ##########################
}#if correct num of arg

my $tfinal = new Benchmark;
my $tdfinal = timediff($tfinal, $t0);
print "script gds2def took:",timestr($tdfinal),"\n";


#######################################################################################################
############################# Code to break polygon in rectangles #####################################
#######################################################################################################
sub break_polygon_into_rects{
 my @x_y_combined_list = @{$_[0]};
 my @rect_list = @{$_[1]} ;
 
 my @rect_point_list = () ;
 my $number_of_points = @x_y_combined_list/2;
 my %point_vs_xval = ();
 my %point_vs_yval = ();
 my %xval_vs_pointlist = ();
 my %yval_vs_pointlist = ();
 my $curr_x_val ;
 my $curr_y_val ;
 
 if($number_of_points == 5){
    my @xx = ();
    my @yy = ();
    for(my $i=0; $i<$number_of_points; $i++){
        push(@xx, $x_y_combined_list[$i*2]);
        push(@yy, $x_y_combined_list[$i*2+1]);
    }
    @xx = sort{$a<=>$b} @xx;
    @yy = sort{$a<=>$b} @yy;
    push(@rect_list, [$xx[0], $yy[0], $xx[-1], $yy[-1]]);
    return @rect_list;
 }
 
 for(my $i=0;$i<$number_of_points;$i++) {
   $curr_x_val = $x_y_combined_list[$i*2];
   $curr_y_val = $x_y_combined_list[$i*2+1];
   if(exists $point_vs_xval{$curr_x_val.",".$curr_y_val}){next;}
   $point_vs_xval{$curr_x_val.",".$curr_y_val} = $curr_x_val;
   $point_vs_yval{$curr_x_val.",".$curr_y_val} = $curr_y_val;
   if(exists $xval_vs_pointlist{$curr_x_val}){
      push(@{$xval_vs_pointlist{$curr_x_val}}, $curr_x_val.",".$curr_y_val);
   }else{
      $xval_vs_pointlist{$curr_x_val} = [$curr_x_val.",".$curr_y_val];
   }
   if(exists $yval_vs_pointlist{$curr_y_val}){
      push(@{$yval_vs_pointlist{$curr_y_val}}, $curr_x_val.",".$curr_y_val);
   }else{
      $yval_vs_pointlist{$curr_y_val} = [$curr_x_val.",".$curr_y_val];
   }
 }
 
 my @sorted_point_vs_yval = sort {$a<=>$b} (keys(%yval_vs_pointlist));
 my $min_y_val = $sorted_point_vs_yval[0];
 my @array_points_with_min_y_val = @{$yval_vs_pointlist{$min_y_val}};
 
 my @sorted_array_points_by_x_val_with_min_y_val = sort{(split(/\,/,$a))[0]<=> (split(/\,/,$b))[0]} @array_points_with_min_y_val; #sorting array using x value of point
 
 my $first_minx_point_for_min_y_val = $sorted_array_points_by_x_val_with_min_y_val[0];
 my $first_minx = (split(/\,/, $first_minx_point_for_min_y_val))[0];
 my @array_points_with_first_min_x_val = @{$xval_vs_pointlist{$first_minx}};
 my @sorted_array_points_by_y_val_with_first_min_x_val =  sort{(split(/\,/,$a))[1]<=> (split(/\,/,$b))[1]} @array_points_with_first_min_x_val; #sorting array using y value of point
 my $second_miny_point_for_first_minx = $sorted_array_points_by_y_val_with_first_min_x_val[1];
 my $second_miny_for_first_minx = (split(/\,/, $second_miny_point_for_first_minx))[1];
 
 my $second_minx_point_for_min_y_val = $sorted_array_points_by_x_val_with_min_y_val[1];
 my $second_minx = (split(/\,/, $second_minx_point_for_min_y_val))[0];
 my @array_points_with_second_min_x_val = @{$xval_vs_pointlist{$second_minx}};
 my @sorted_array_points_by_y_val_with_second_min_x_val =  sort{(split(/\,/,$a))[1]<=> (split(/\,/,$b))[1]} @array_points_with_second_min_x_val; #sorting array using y value of point
 my $second_miny_point_for_second_minx = $sorted_array_points_by_y_val_with_second_min_x_val[1];
 my $second_miny_for_second_minx = (split(/\,/, $second_miny_point_for_second_minx))[1];
 
 if($second_miny_for_first_minx <= $second_miny_for_second_minx){
    my $insideY = check_point_inside_rect(\@sorted_point_vs_yval,\%yval_vs_pointlist,[$first_minx, $min_y_val, $second_minx, $second_miny_for_first_minx]);
    if($insideY ne ""){
       push(@rect_point_list, $first_minx, $min_y_val, $second_minx, $insideY);
    }else{
       push(@rect_point_list, $first_minx, $min_y_val, $second_minx, $second_miny_for_first_minx);
    }
 }elsif($second_miny_for_first_minx > $second_miny_for_second_minx){
    my $insideY = check_point_inside_rect(\@sorted_point_vs_yval,\%yval_vs_pointlist,[$first_minx, $min_y_val, $second_minx, $second_miny_for_second_minx]);
    if($insideY ne ""){
       push(@rect_point_list, $first_minx, $min_y_val, $second_minx, $insideY);
    }else{
       push(@rect_point_list, $first_minx, $min_y_val, $second_minx, $second_miny_for_second_minx);
    }
 }
 
 push(@rect_list, [@rect_point_list]);
 
 my @new_x_y_combined_list = ();
 my ($point_1_found, $point_2_found, $point_3_found, $point_4_found) = (0,0,0,0);
 for(my $i=0; $i<$#x_y_combined_list; $i=$i+2){
     if($x_y_combined_list[$i] == $rect_point_list[0] && $x_y_combined_list[$i+1] == $rect_point_list[1]){
        $point_1_found = 1;
     }elsif($x_y_combined_list[$i] == $rect_point_list[2] && $x_y_combined_list[$i+1] == $rect_point_list[1]){
        $point_2_found = 1;
     }elsif($x_y_combined_list[$i] == $rect_point_list[2] && $x_y_combined_list[$i+1] == $rect_point_list[3]){
        $point_3_found = 1;
     }elsif($x_y_combined_list[$i] == $rect_point_list[0] && $x_y_combined_list[$i+1] == $rect_point_list[3]){
        $point_4_found = 1;
     }else{
        push(@new_x_y_combined_list,$x_y_combined_list[$i],$x_y_combined_list[$i+1]);  
     }
 }
 if($point_1_found == 0){
    push(@new_x_y_combined_list,$rect_point_list[0],$rect_point_list[1]);  
 }
 if($point_2_found == 0 ){
    push(@new_x_y_combined_list,$rect_point_list[2],$rect_point_list[1]);  
 }
 if($point_3_found == 0 ){
    push(@new_x_y_combined_list,$rect_point_list[2],$rect_point_list[3]);  
 }
 if($point_4_found == 0 ){
    push(@new_x_y_combined_list,$rect_point_list[0],$rect_point_list[3]);  
 }
 
 if(@new_x_y_combined_list > 7){ return &break_polygon_into_rects(\@new_x_y_combined_list, \@rect_list);}
 return @rect_list;
}#sub break_polygon_into_rects

sub check_point_inside_rect{
 my @sorted_point_vs_yval = @{$_[0]};
 my %yval_vs_pointlist = %{$_[1]};
 my @bbox = @{$_[2]};
 #print "@sorted_point_vs_yval | @bbox\n"; 
 my @inside_minY = ();
 foreach my $y_val (@sorted_point_vs_yval){
   if($y_val > $bbox[1] && $y_val < $bbox[3]){
      my @array_points = @{$yval_vs_pointlist{$y_val}};
      #print "$y_val => @array_points\n";
      foreach my $p (@array_points){
        my $x_val = (split(/\,/,$p))[0];
        if($x_val > $bbox[0] && $x_val < $bbox[2]){
           push(@inside_minY, $y_val);
        }
      }
   }
 }
 @inside_minY = sort{$a<=>$b} @inside_minY;
 return $inside_minY[0];
}#sub check_point_inside_rect

