#!/usr/bin/perl
#use warnings;
use GDS2;
use Math::Clipper ':all';
use Math::Polygon;
use Math::Polygon::Calc;
use Math::Polygon::Transform;
use XML::Simple;
use Benchmark;
my $t0 = new Benchmark;

my $noOfArg = @ARGV;
my ($gdsFile, $outFile, $layerMapFile, $configFile, $tolerance) = ("", "", "", "", 0.0001);
my ($uu,$dbu);
if($noOfArg < 6 || $ARGV[0] eq '-h' || $ARGV[0] eq '-help' || $ARGV[0] eq '-HELP') {
   print "usage : ./gds2lef.pl   -gds < gds file >\n";
   print "                       -layer_map_file <input layer map file>\n";
   print "                       -config_file <input config file>\n";
   print "                       -out <output file name(default is temp.lef)>\n";
   print "                       -tolerance <tolerance for floating numbers (default value is 0.0001)>\n";
}else {
   for(my $i=0 ; $i<$noOfArg; $i++){
       if($ARGV[$i] eq "-gds"){$gdsFile = $ARGV[$i+1];} 
       if($ARGV[$i] eq "-out"){$outFile = $ARGV[$i+1];} 
       if($ARGV[$i] eq "-layer_map_file"){$layerMapFile = $ARGV[$i+1];} 
       if($ARGV[$i] eq "-config_file"){$configFile = $ARGV[$i+1];} 
       if($ARGV[$i] eq "-tolerance"){$tolerance = $ARGV[$i+1];} 
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
   my %layer_group_hash = ();
   my @final_groups = ();
   my %pin_poly_hash = ();

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
   my $text_found = 0;
   my $aref_found = 0;
   my $sref_found = 0;
   my $compact = 0;

  
   my $gds2File = new GDS2(-fileName=>"$gdsFile");
   my ($string_name, $layer_name, $data_type);
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
        $data_type = "";
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
              $data_type = $gds2File->returnDatatype;
           }elsif($gds2File->isXy){
              my @poly_coords = $gds2File->returnXyAsArray;
              $_ *= $uu for @poly_coords;

              ############ calculating cellsize ##############
              if($boundary_layer ne "" && $boundary_layer_data_type ne ""){
                 if($layer_name == $boundary_layer && $data_type == $boundary_layer_data_type){
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
              push(@total_poly, [$layer_name, -1, @poly_coords]);
           }else{next;}
        }elsif($text_found == 1){
           if($gds2File->isXy){
              @xy = $gds2File->returnXyAsArray;
              $_ *= $uu for @xy;
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

   undef %cell_hash; #removing from memory

   ######################## Flatten AREF data ########################
   my $via_group_cnt = 0;
   foreach my $cell (keys %AREF_DATA){
     my @aref_data = @{$AREF_DATA{$cell}};
     foreach my $line(@aref_data){
       my ($sname, $strans, $scale, $angle, $col, $row, @poly_coords) = @$line;
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
                   push(@{$CELL_POLYGONS{$cell}}, [$layer,$via_group_cnt, @trans_poly]);
                 }
             }#foreach col
          }#foreach row
          $via_group_cnt++;
        }#if cell poly found
     }#foreach line 
   }#foreach cell

   undef %AREF_DATA; #making hash empty

   ######################## Flatten SREF data ########################
   my %repeat_via_group = ();

   &get_flat_data;
   sub get_flat_data{
     if(exists $SREF_DATA{$top_module}){
        my @sref_data = @{$SREF_DATA{$top_module}};
        foreach my $line(@sref_data){
          my ($sname, $strans, $mag, $angle, $llx, $lly) = @$line;
          &replace_sref_data($sname, [$strans], [$mag], [$angle], [$llx], [$lly]);
        }
     }
   }#sub get_flat_data

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
   print "flattening is completed in :",timestr($td),"\n";

   ############ transfer the polygons in %boundary_layer_hash #############
   my %poly_minX_hash = ();
   my %poly_minY_hash = ();
   my %poly_maxX_hash = ();
   my %poly_maxY_hash = ();
   my %poly_maxY_length = ();

   my @data_arr = @{$CELL_POLYGONS{$top_module}};
   #my @data_arr = ([16, -1,  1,10,2,10,2,13,1,13,1,10],[16, -1, 2,10,4,10,4,11,2,11,2,10],[16, -1,  4,10,6,10,6,11,4,11,4,10],  
   #                [16, -1,  1,7,4,7,4,8,1,8,1,7],  
   #                [16, -1,  7,5,8,5,8,6,7,6,7,5],
   #                [16, -1,  1,3,5,3,5,4,1,4,1,3],

   #                [18, -1, 5,7,6,7,6,11,5,11,5,7],[18, -1, 3,7,5,7,5,8,3,8,3,7],  
   #                [18, -1, 7,5,8,5,8,8,7,8,7,5],  
   #                [18, -1, 10,12,12,12,12,13,10,13,10,12],[18, -1, 12,10,13,10,13,13,12,13,12,10],  
   #                [18, -1, 14,8,15,8,15,11,14,11,14,8],
   #                [18, -1, 9,1,10,1,10,4,9,4,9,1],

   #                [20, -1, 5,7,8,7,8,8,5,8,5,7],  
   #                [20, -1, 12,10,15,10,15,11,12,11,12,10],

   #                [17, 0, 5.4,10.2,5.6,10.2,5.6,10.4,5.4,10.4,5.4,10.2],[17, 0, 5.4,10.6,5.6,10.6,5.6,10.8,5.4,10.8,5.4,10.6],  
   #                [17, 1, 3.4,7.2,3.6,7.2,3.6,7.4,3.4,7.4,3.4,7.2],[17, 1, 3.4,7.6,3.6,7.6,3.6,7.8,3.4,7.8,3.4,7.6],  
   #                [17, 2, 7.4,5.2,7.6,5.2,7.6,5.4,7.4,5.4,7.4,5.2],[17, 2, 7.4,5.6,7.6,5.6,7.6,5.8,7.4,5.8,7.4,5.6],

   #                [19, 0, 5.4,7.2,5.6,7.2,5.6,7.4,5.4,7.4,5.4,7.2],[19, 0, 5.4,7.6,5.6,7.6,5.6,7.8,5.4,7.8,5.4,7.6],  
   #                [19, 1, 7.4,7.2,7.6,7.2,7.6,7.4,7.4,7.4,7.4,7.2],[19, 1, 7.4,7.6,7.6,7.6,7.6,7.8,7.4,7.8,7.4,7.6],  
   #                [19, 2, 12.4,10.2,12.6,10.2,12.6,10.4,12.4,10.4,12.4,10.2],[19, 2, 12.4,10.6,12.6,10.6,12.6,10.8,12.4,10.8,12.4,10.6],  
   #                [19, 3, 14.4,10.2,14.6,10.2,14.6,10.4,14.4,10.4,14.4,10.2],[19, 3, 14.4,10.6,14.6,10.6,14.6,10.8,14.4,10.8,14.4,10.6]
   #               );

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
        }#if Routing layer
        #-----------------------------------------------------#
     }
   }
   
   undef %CELL_POLYGONS; #making hash empty

   my $t2 = new Benchmark;
   my $td1 = timediff($t2, $t1);
   print "transfer data in boundary_layer_hash is completed in :",timestr($td1),"\n";

   #####################################################################
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
         my @polygon = @{$poly[0]};
         my @x_coords = ();
         my @y_coords = ();
         for(my $i=1; $i<=$#polygon; $i=$i+2){
             push(@x_coords, $polygon[$i]);
             push(@y_coords, $polygon[$i+1]);
         }
         @x_coords = sort{$a<=>$b}@x_coords;
         @y_coords = sort{$a<=>$b}@y_coords;
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
         $group_cnt++;
      }
   }
   my $t4 = new Benchmark;
   my $td3 = timediff($t4, $t2);
   print "Making hashes complete :",timestr($td3),"\n";
   ######################################################################################
   ######################## Making groups of Overlapping  Polygon #######################
   ######################################################################################
   my %via_vs_layer_grp = ();   
   my $grp_cnt = 0;
   #my $metal_layer;

   my @poly_arr = ();
   my @minY_keys = ();
   my %MINX = ();
   my %MINY = ();
   my %MAXX = ();
   my %MAXY = ();
   my $maxYlen;

   my @via_poly_grp = ();
   my @via_minY_rect = ();
   my %VIA_MINX = ();
   my %VIA_MINY = ();
   my %VIA_MAXX = ();
   my %VIA_MAXY = ();
   my $via_max_len;

   my @rev_via_poly_grp = ();
   my @rev_via_minY_rect = ();
   my %REV_VIA_MINX = ();
   my %REV_VIA_MINY = ();
   my %REV_VIA_MAXX = ();
   my %REV_VIA_MAXY = ();
   my $rev_via_max_len;
   my $via_layer;
   my $rev_via_layer;

   my @total_ovl_poly = ();
   foreach $metal_layer(keys %overlap_layer_hash){
      $via_layer = $overlap_layer_hash{$metal_layer};
      $rev_via_layer = $rev_overlap_layer_hash{$metal_layer};

      @poly_arr = @{$boundary_layer_hash{$metal_layer}}; ##Global

      %MINX = %{$poly_minX_hash{$metal_layer}};
      %MINY = %{$poly_minY_hash{$metal_layer}};
      %MAXX = %{$poly_maxX_hash{$metal_layer}};
      %MAXY = %{$poly_maxY_hash{$metal_layer}};
      $maxYlen = $poly_maxY_length{$metal_layer};

      @minY_keys = sort{$MINY{$a}<=>$MINY{$b}} (keys %MINY);
      my @maxY_keys = sort{$MAXY{$a}<=>$MAXY{$b}} (keys %MAXY);

      ################## for via layer #####################
      if(exists $via_hash{$via_layer}){
         @via_poly_grp = @{$layer_group_hash{$via_layer}};
         %VIA_MINX = %{$group_poly_minX_hash{$via_layer}};
         %VIA_MINY = %{$group_poly_minY_hash{$via_layer}};
         %VIA_MAXX = %{$group_poly_maxX_hash{$via_layer}};
         %VIA_MAXY = %{$group_poly_maxY_hash{$via_layer}};
         @via_minY_rect = sort{$VIA_MINY{$a}<=>$VIA_MINY{$b}} (keys %VIA_MINY);
         $via_max_len = $group_poly_maxY_length{$via_layer};
      }

      if(exists $via_hash{$rev_via_layer}){
         @rev_via_poly_grp = @{$layer_group_hash{$rev_via_layer}};
         %REV_VIA_MINX = %{$group_poly_minX_hash{$rev_via_layer}};
         %REV_VIA_MINY = %{$group_poly_minY_hash{$rev_via_layer}};
         %REV_VIA_MAXX = %{$group_poly_maxX_hash{$rev_via_layer}};
         %REV_VIA_MAXY = %{$group_poly_maxY_hash{$rev_via_layer}};
         @rev_via_minY_rect = sort{$REV_VIA_MINY{$a}<=>$REV_VIA_MINY{$b}} (keys %REV_VIA_MINY);
         $rev_via_max_len = $group_poly_maxY_length{$rev_via_layer};
      }
      ######################################################

      my @group_arr = ();
      $grp_cnt = 0;
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
                 delete $MINX{$minY_poly_num};
                 delete $MINY{$minY_poly_num};
                 delete $MAXX{$minY_poly_num};
                 delete $MAXY{$minY_poly_num};
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
                    delete $MINX{$minY_poly_num};
                    delete $MINY{$minY_poly_num};
                    delete $MAXX{$minY_poly_num};
                    delete $MAXY{$minY_poly_num};
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
                       delete $MINX{$minY_poly_num};
                       delete $MINY{$minY_poly_num};
                       delete $MAXX{$minY_poly_num};
                       delete $MAXY{$minY_poly_num};
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
                          delete $MINX{$minY_poly_num};
                          delete $MINY{$minY_poly_num};
                          delete $MAXX{$minY_poly_num};
                          delete $MAXY{$minY_poly_num};
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
                             delete $MINX{$minY_poly_num};
                             delete $MINY{$minY_poly_num};
                             delete $MAXX{$minY_poly_num};
                             delete $MAXY{$minY_poly_num};
                          }
                       }
                    }
                 }
              }#if touch
          }
          if(exists $via_hash{$via_layer}){
             @via_minY_rect = sort{$VIA_MINY{$a}<=>$VIA_MINY{$b}} (keys %VIA_MINY);
             my $via_num = $miny - $via_max_len;
             my $via_lower_limit = &get_lower_limit(0, $#via_minY_rect, $via_num, \%VIA_MINY, \@via_minY_rect);

             for(my $i=$via_lower_limit; $i<=$#via_minY_rect; $i++){
                 my $minY_poly_num = $via_minY_rect[$i];
                 if(ref $via_poly_grp[$minY_poly_num] eq ""){next;}

                 my $minx1 = $VIA_MINX{$minY_poly_num};
                 my $miny1 = $VIA_MINY{$minY_poly_num};
                 my $maxx1 = $VIA_MAXX{$minY_poly_num};
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
                    push(@total_ovl_poly, $via_layer."_".$minY_poly_num); 
                    push(@{$via_vs_layer_grp{$via_layer."_".$minY_poly_num}}, $metal_layer."_".$grp_cnt); 
                    delete $VIA_MINX{$minY_poly_num};
                    delete $VIA_MINY{$minY_poly_num};
                    delete $VIA_MAXX{$minY_poly_num};
                    delete $VIA_MAXY{$minY_poly_num};
                 }
             }#for each poly
          }
          if(exists $via_hash{$rev_via_layer}){
             @rev_via_minY_rect = sort{$REV_VIA_MINY{$a}<=>$REV_VIA_MINY{$b}} (keys %REV_VIA_MINY);
             my $rev_via_num = $miny - $rev_via_max_len;
             my $rev_via_lower_limit = &get_lower_limit(0, $#rev_via_minY_rect, $rev_via_num, \%REV_VIA_MINY, \@rev_via_minY_rect);
             for(my $i=$rev_via_lower_limit; $i<=$#rev_via_minY_rect; $i++){
                 my $minY_poly_num = $rev_via_minY_rect[$i];
                 if(ref $rev_via_poly_grp[$rev_minY_poly_num] eq ""){next;}

                 my $minx1 = $REV_VIA_MINX{$minY_poly_num};
                 my $miny1 = $REV_VIA_MINY{$minY_poly_num};
                 my $maxx1 = $REV_VIA_MAXX{$minY_poly_num};
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
                    push(@total_ovl_poly, $rev_via_layer."_".$minY_poly_num); 
                    push(@{$via_vs_layer_grp{$rev_via_layer."_".$minY_poly_num}}, $metal_layer."_".$grp_cnt); 
                    delete $REV_VIA_MINX{$minY_poly_num};
                    delete $REV_VIA_MINY{$minY_poly_num};
                    delete $REV_VIA_MAXX{$minY_poly_num};
                    delete $REV_VIA_MAXY{$minY_poly_num};
                 }
             }#for each poly
          }
          if($#overlapped_poly >= 0){
             delete $poly_arr[$maxY_poly_num];
             delete $MINX{$maxY_poly_num};
             delete $MINY{$maxY_poly_num};
             delete $MAXX{$maxY_poly_num};
             delete $MAXY{$maxY_poly_num};
             @minY_keys = sort{$MINY{$a}<=>$MINY{$b}} (keys %MINY);
             &get_overlap_poly(\@overlapped_poly_num, \@overlapped_poly);
             push(@overlapped_poly, @total_ovl_poly);
             unshift(@overlapped_poly,[@sub_poly]);
             push(@group_arr,[@overlapped_poly]);
          }elsif($#overlapped_poly < 0 && $#total_ovl_poly >= 0){
             delete $poly_arr[$maxY_poly_num];
             delete $MINX{$maxY_poly_num};
             delete $MINY{$maxY_poly_num};
             delete $MAXX{$maxY_poly_num};
             delete $MAXY{$maxY_poly_num};
             @minY_keys = sort{$MINY{$a}<=>$MINY{$b}} (keys %MINY);
             push(@total_ovl_poly, [@sub_poly]);
             push(@group_arr,[@total_ovl_poly]);
          }else{
             delete $poly_arr[$maxY_poly_num];
             delete $MINX{$maxY_poly_num};
             delete $MINY{$maxY_poly_num};
             delete $MAXX{$maxY_poly_num};
             delete $MAXY{$maxY_poly_num};
             @minY_keys = sort{$MINY{$a}<=>$MINY{$b}} (keys %MINY);
             push(@group_arr,[[@sub_poly]]);
          }
          $grp_cnt++;
      }
      @{$layer_group_hash{$metal_layer}} = @group_arr;
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
         my @ovl_poly = ();
         my @ovl_poly_num = ();

         my @sub_poly = @{shift @ovl_poly_coords_arr};

         my @p = ();
         for(my $k=1; $k<=$#sub_poly; $k=$k+2){
             push(@p,[$sub_poly[$k],$sub_poly[$k+1]]);
         }

         my ($minx, $miny, $maxx, $maxy) = polygon_bbox @p;

         my $num = $miny - $maxYlen;
         my $low_limit = &get_partition(0, $#minY_keys, $num); 

         for(my $i=$low_limit; $i<=$#minY_keys; $i++){
             my $minY_poly_num = $minY_keys[$i];
             if(ref $poly_arr[$minY_poly_num] eq ""){next;}

             my $minx1 = $MINX{$minY_poly_num};
             my $miny1 = $MINY{$minY_poly_num};
             my $maxx1 = $MAXX{$minY_poly_num};
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
                delete $MINX{$minY_poly_num};
                delete $MINY{$minY_poly_num};
                delete $MAXX{$minY_poly_num};
                delete $MAXY{$minY_poly_num};
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
                   delete $MINX{$minY_poly_num};
                   delete $MINY{$minY_poly_num};
                   delete $MAXX{$minY_poly_num};
                   delete $MAXY{$minY_poly_num};
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
                      delete $MINX{$minY_poly_num};
                      delete $MINY{$minY_poly_num};
                      delete $MAXX{$minY_poly_num};
                      delete $MAXY{$minY_poly_num};
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
                         delete $MINX{$minY_poly_num};
                         delete $MINY{$minY_poly_num};
                         delete $MAXX{$minY_poly_num};
                         delete $MAXY{$minY_poly_num};
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
                            delete $MINX{$minY_poly_num};
                            delete $MINY{$minY_poly_num};
                            delete $MAXX{$minY_poly_num};
                            delete $MAXY{$minY_poly_num};
                         }
                      }
                   }
                }
             }
         }
         if(exists $via_hash{$via_layer}){
            @via_minY_rect = sort{$VIA_MINY{$a}<=>$VIA_MINY{$b}} (keys %VIA_MINY);
            my $via_num = $miny - $via_max_len;
            my $via_lower_limit = &get_lower_limit(0, $#via_minY_rect, $via_num, \%VIA_MINY, \@via_minY_rect);
            for(my $i=$via_lower_limit; $i<=$#via_minY_rect; $i++){
                my $minY_poly_num = $via_minY_rect[$i];
                if(ref $via_poly_grp[$minY_poly_num] eq ""){next;}

                my $minx1 = $VIA_MINX{$minY_poly_num};
                my $miny1 = $VIA_MINY{$minY_poly_num};
                my $maxx1 = $VIA_MAXX{$minY_poly_num};
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
                   push(@total_ovl_poly, $via_layer."_".$minY_poly_num); 
                   push(@{$via_vs_layer_grp{$via_layer."_".$minY_poly_num}}, $metal_layer."_".$grp_cnt); 
                   delete $VIA_MINX{$minY_poly_num};
                   delete $VIA_MINY{$minY_poly_num};
                   delete $VIA_MAXX{$minY_poly_num};
                   delete $VIA_MAXY{$minY_poly_num};
                }
            }#for each poly
         }
         if(exists $via_hash{$rev_via_layer}){
            @rev_via_minY_rect = sort{$REV_VIA_MINY{$a}<=>$REV_VIA_MINY{$b}} (keys %REV_VIA_MINY);
            my $rev_via_num = $miny - $rev_via_max_len;
            my $rev_via_lower_limit = &get_lower_limit(0, $#rev_via_minY_rect, $rev_via_num, \%REV_VIA_MINY, \@rev_via_minY_rect);
            for(my $i=$rev_via_lower_limit; $i<=$#rev_via_minY_rect; $i++){
                my $minY_poly_num = $rev_via_minY_rect[$i];
                if(ref $rev_via_poly_grp[$rev_minY_poly_num] eq ""){next;}

                my $minx1 = $REV_VIA_MINX{$minY_poly_num};
                my $miny1 = $REV_VIA_MINY{$minY_poly_num};
                my $maxx1 = $REV_VIA_MAXX{$minY_poly_num};
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
                   push(@total_ovl_poly, $rev_via_layer."_".$minY_poly_num); 
                   push(@{$via_vs_layer_grp{$rev_via_layer."_".$minY_poly_num}}, $metal_layer."_".$grp_cnt); 
                   delete $REV_VIA_MINX{$minY_poly_num};
                   delete $REV_VIA_MINY{$minY_poly_num};
                   delete $REV_VIA_MAXX{$minY_poly_num};
                   delete $REV_VIA_MAXY{$minY_poly_num};
                }
            }#for each poly
         }
         if($#ovl_poly >= 0){
            push(@total_ovl_poly, @ovl_poly);
            @minY_keys = sort{$MINY{$a}<=>$MINY{$b}} (keys %MINY);
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
     }elsif($num >= $MINY{$minY_keys[$max_ele]}){
        return $max_ele;
     }elsif($num > $MINY{$minY_keys[$min_ele]} && $num < $MINY{$minY_keys[$min_ele + $int_mid_num]}){
        &get_partition($min_ele, $min_ele + $int_mid_num , $num);
     }else{
        &get_partition($min_ele+$int_mid_num+1, $max_ele, $num);
     }   
   }#sub get_partition

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
     }elsif($num >= $TEMP{$y_arr[$max_ele]}){
        return $max_ele;
     }elsif($num > $TEMP{$y_arr[$min_ele]} && $num < $TEMP{$y_arr[$min_ele + $int_mid_num]}){
        &get_lower_limit($min_ele, $min_ele + $int_mid_num , $num, \%TEMP, \@y_arr);
     }else{
        &get_lower_limit($min_ele+$int_mid_num+1, $max_ele, $num, \%TEMP, \@y_arr);
     }   

   }#sub get_lower_limit


   my $t3 = new Benchmark;
   my $td2 = timediff($t3, $t4);
   print "Making group in same layer complete :",timestr($td2),"\n";
   
   foreach my $layer(keys %overlap_layer_hash){
     my @layer_groups = @{$layer_group_hash{$layer}};
     my $cnt = -1;
     foreach my $grp (@layer_groups){
        $cnt++;
        @temp_grp = ();
        if(ref $grp ne "ARRAY"){next;}
        my @poly = @$grp;
        delete $layer_group_hash{$layer}[$cnt];
        delete $layer_groups[$cnt]; 
        foreach my $p (@poly){
          if(ref $p eq "ARRAY"){
             push(@temp_grp, [@$p]);
          }else{
             my ($via_layer, $via_group) = split(/\_/,$p);
             push(@temp_grp, @{$layer_group_hash{$via_layer}[$via_group]});
             delete $layer_group_hash{$via_layer}[$via_group];
             @layer_groups = &find_overlap_grp($p,$layer,\@layer_groups); 
          }
        }
        push(@final_groups, [@temp_grp]);
     }
   }#foreach routing layer

   sub find_overlap_grp{
     my $via_grp = $_[0];
     my $start_layer = $_[1];
     my @layer_groups = @{$_[2]};

     my @via_existing_grp = @{$via_vs_layer_grp{$via_grp}};
     delete $via_vs_layer_grp{$via_grp};

     foreach my $grp_str (@via_existing_grp){
        my ($layer, $group) = split(/\_/,$grp_str);
        my @group_poly = @{$layer_group_hash{$layer}[$group]};
        if(@group_poly eq ""){next;}
        delete $layer_group_hash{$layer}[$group];
        delete $layer_groups[$group] if($layer == $start_layer);
        foreach my $p (@group_poly){
          if($p eq $via_grp){next;}
          if(ref $p eq "ARRAY"){
             push(@temp_grp, [@$p]);
          }else{
             my ($via_layer, $via_group) = split(/\_/,$p);
             push(@temp_grp, @{$layer_group_hash{$via_layer}[$via_group]});
             delete $layer_group_hash{$via_layer}[$via_group];
             @layer_groups = &find_overlap_grp($p, $start_layer,\@layer_groups); 
          }
        }
     } 
     return @layer_groups;
   }#sub find_overlap_grp


   foreach my $layer (keys %layer_group_hash){
      my @grp = @{$layer_group_hash{$layer}};
      if($#grp <= 0){next;}
      push(@final_groups, [@grp]);
   }

   #######################################################################
   ######################## Making pin's group ########################### 
   #######################################################################
   my @obs_poly = ();
   my @pins = ();
   if($label_level eq "" || $label_level eq "top"){
      push(@pins, @{$PIN_TEXT_COORDS{$top_module}});
   }else{
      foreach my $cell (keys %PIN_TEXT_COORDS){
        push(@pins, @{$PIN_TEXT_COORDS{$cell}});
      }
   }
   
   ###############################################################
   for(my $i=0; $i<=$#final_groups; $i++){
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
           }elsif($pin_layer != $poly_layer){
              next;
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
  
   my $t6 = new Benchmark;
   my $td5 = timediff($t6, $t3);
   print "Making pin group complete :",timestr($td5),"\n";

   @final_groups = (); #making array empty
   
   ######################################################################
   my ($layerName,$width, $height) = @{$cell_size{$top_module}};
   
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


