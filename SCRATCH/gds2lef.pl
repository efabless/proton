#!/usr/bin/perl
use GDS2;
use Math::Clipper ':all';
use Math::Polygon;
use Math::Polygon::Transform;
use XML::Simple;
use Benchmark;
my $t0 = new Benchmark;

my $noOfArg = @ARGV;
my ($gdsFile, $outFile, $layerMapFile, $configFile) = ("", "", "", "");
if($noOfArg < 6 || $_[0] eq '-h' || $_[0] eq '-help' || $_[0] eq '-HELP') {
   print "usage : ./gds2lef.pl   -gds < gds file >\n";
   print "                       -layer_map_file <input layer map file>\n";
   print "                       -config_file <input config file>\n";
   print "                       -out <output file name(default is temp.lef)>\n";
}else {
   for(my $i=0 ; $i<=$noOfArg; $i++){
       if($ARGV[$i] eq "-gds"){$gdsFile = $ARGV[$i+1];} 
       if($ARGV[$i] eq "-out"){$outFile = $ARGV[$i+1];} 
       if($ARGV[$i] eq "-layer_map_file"){$layerMapFile = $ARGV[$i+1];} 
       if($ARGV[$i] eq "-config_file"){$configFile = $ARGV[$i+1];} 
   }#for correct no.of Arguments

   if($outFile eq ""){ 
      my ($gds_file_name) = (split(/\//,$gdsFile))[-1];
      my ($file_name) = (split(/\./,$gds_file_name))[0];
      $outFile = $file_name.".lef";
   }#if file(lef) name is not given

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

   ######################## Reding Congfig File #############################
   my $xml1 = new XML::Simple;
   my $configData = $xml1->XMLin("$configFile");
   my %configHash = %$configData;
   my $mustjoin_identifier = $configHash{mustjoin_identifier};
   my $boundary_layer = $configHash{boundary};
   my $boundary_layer_data_type = $configHash{boundary_layer_data_type};
   my $text_layers_str = $configHash{text_layer};
   my @text_layers = split(/\,/,$text_layers_str);
   foreach (@text_layers){
     $text_layer_hash{$_} = 1;
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
   my ($sname, $angle, $col, $row, $sname1, $sref_angle);
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
          @X_COORDS = sort{$a<=>$b}@X_COORDS;
          @Y_COORDS = sort{$a<=>$b}@Y_COORDS;
          my $width = $X_COORDS[-1] - $X_COORDS[0];
          my $height = $Y_COORDS[-1] - $Y_COORDS[0];
          $cell_size{$string_name} = [$layer_name, $width, $height];
        }
        $string_found = 0;
     }elsif($gds2File->isBoundary){
        $boundary_found = 1;
        $layer_name = "";
        $data_type = "";
     }elsif($gds2File->isText){
        $text_found = 1;
        @xy = ();
     }elsif($gds2File->isAref){
        $aref_found = 1;
        $sname = "";
        $angle = 0;
        $col = 0;
        $row = 0;
     }elsif($gds2File->isSref){
        $sref_found = 1;
        $sname1 = "";
        $sref_angle = "";
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
              unshift(@poly_coords,$layer_name);
              push(@total_poly, [@poly_coords]);
           }else{next;}
        }elsif($text_found == 1){
           if($gds2File->isXy){
              @xy = $gds2File->returnXyAsArray;
              $_ *= $uu for @xy;
           }elsif($gds2File->isLayer){
              my $text_layer = $gds2File->returnLayer;
              if($text_layers_str ne ""){     
                if(!exists $text_layer_hash{$text_layer}){
                   $text_found = 0;
                }#if exists in text_layer_hash
              }#if text_layer entry is given in config file
           }elsif($gds2File->isString){
              my $pinName = $gds2File->returnString;
              push(@pin_coords, [$pinName, @xy]);
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
              push(@aref_data, [$sname, $angle, $col, $row, @poly_coords]);
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
           }elsif($gds2File->isAngle){
              my $string = $gds2File->returnRecordAsString(-compact=>$compact);
              $string =~ s/^\s+//g;
              $sref_angle = (split(/\s+/,$string))[1]; 
           }elsif($gds2File->isXy){
              my @poly_coords = $gds2File->returnXyAsArray;
              $_ *= $uu for @poly_coords;
              push(@sref_data, [$sname1, $sref_angle,@poly_coords]);
           }else{next;}
        }else{next;}
     }else{next;}
   }#while

   ####################### Finding TOP Module ########################
   my @keys = sort{$cell_hash{$a}<=>$cell_hash{$b}} (keys %cell_hash);
   my $top_module = $keys[0];
   %cell_hash = (); # making hash empty

   ######################## Flatten AREF data ########################
   foreach my $cell (keys %AREF_DATA){
     my @aref_data = @{$AREF_DATA{$cell}};
     foreach my $line(@aref_data){
       my ($sname, $angle, $col, $row, @poly_coords) = @$line;
       my ($via_layer,$width, $height) = @{$cell_size{$sname}};
       if(!exists $boundary_layer_hash{$via_layer}){next;}
       my $locX = $poly_coords[0];
       my $locY = $poly_coords[1];
       my ($xgap, $ygap);
       if($angle == 90){
          my $x = $col;
          $col = $row;
          $row = $x;
          $xgap = (abs($poly_coords[4] - $locX) - $col*$width)/$col;
          $ygap = ($poly_coords[3] - $locY - $row*$height)/$row;
          if($poly_coords[4] < $locX){
             $xgap = -$xgap;
             $width = -$width;
          }
       }elsif($angle == 180){
          $xgap = ($poly_coords[2] - $locX + $col*$width)/$col;
          $ygap = (abs($poly_coords[5] - $locY) - $row*$height)/$row;
          $width = -$width;
          if($poly_coords[5] < $locY){
             $ygap = -$ygap;
             $height = -$height;
          }
       }elsif($angle == 270){
          my $x = $col;
          $col = $row;
          $row = $x;
          $xgap = (abs($poly_coords[2] - $locX) - $col*$width)/$col;
          $ygap = ($poly_coords[3] - $locY + $row*$height)/$row;
          $height = -$height;
          if($poly_coords[2] < $locX){
             $xgap = -$xgap;
             $width = -$width;
          }
       }else{
          $xgap = ($poly_coords[2] - $locX - $col*$width)/$col;
          $ygap = (abs($poly_coords[5] - $locY) - $row*$height)/$row;
          if($poly_coords[5] < $locY){
             $ygap = -$ygap;
             $height = -$height;
          } 
       }
       for(my $i=0; $i< $row; $i++){
          for(my $j=0; $j< $col; $j++){
              my $llx = $locX + ($xgap + $width)*$j;
              my $lly = $locY + ($ygap + $height)*$i;
              my $urx = $llx + $width;
              my $ury = $lly + $height;
              my @poly = ($via_layer, $llx,$lly,$urx,$lly,$urx,$ury,$llx,$ury,$llx,$lly);
              push(@{$CELL_POLYGONS{$cell}}, [@poly]);
          }#foreach col
       }#foreach row
     }#foreach line 
   }#foreach cell

   %AREF_DATA = (); #making hash empty

   ######################## Flatten SREF data ########################
   &get_flat_data;
   sub get_flat_data{
     if(exists $SREF_DATA{$top_module}){
        my @sref_data = @{$SREF_DATA{$top_module}};
        foreach my $line(@sref_data){
          my ($sname, $angle, $llx, $lly) = @$line;
          &replace_sref_data($top_module, $sname, $angle, $llx, $lly);
        }
     }
   }#sub get_flat_data

   sub replace_sref_data{
     my $sref = $_[0];
     my $sname = $_[1];
     my $angle = $_[2];
     my $shiftX = $_[3];
     my $shiftY = $_[4];

     if(exists $CELL_POLYGONS{$sname}){
        my @poly_data = @{$CELL_POLYGONS{$sname}};
        foreach my $polygon (@poly_data){
          my @poly = @$polygon;
          my @new_coords = ();
          my $layer = shift @poly; #1st eleemnt of @poly is layer
          if(!exists $boundary_layer_hash{$layer}){next;}
          push(@new_coords, $layer); 
          if($angle ne ""){
             @poly = &transform_sref_inst($angle, \@poly);
          }
          for(my $i=0; $i<@poly; $i=$i+2){
              my $x = $shiftX + $poly[$i];
              my $y = $shiftY + $poly[$i+1];
              push(@new_coords, $x, $y);
          }
          push(@{$CELL_POLYGONS{$top_module}}, [@new_coords]);
        }#foreach polygon
     }#if string exists in CELL_POLYGONS hash
     if(exists $SREF_DATA{$sname}){
        my @sref_data = @{$SREF_DATA{$sname}};
        foreach my $line(@sref_data){
          my ($sname1, $angle1, $llx, $lly) = @$line;
          &replace_sref_data($sname, $sname1, $angle1+$angle, $shiftX+$llx, $shiftY+$lly);
        }
     }
   }#sub replace_sref_data

   sub transform_sref_inst{
     my $angle = $_[0];
     my @poly = @{$_[1]};
     my ($new_llx, $new_lly, $new_urx, $new_ury);
     ############ We assume that poly will be rectangle #####
     my $llx = $poly[0];
     my $lly = $poly[1];
     my $urx = $poly[4];
     my $ury = $poly[5];
     ######## First we take mirror image along x-axis #######
     my $llx1 = $llx;
     my $lly1 = -$ury;
     my $urx1 = $urx;
     my $ury1 = -$lly;
     if($angle == 90){
        $new_llx = -$ury1;
        $new_lly = $llx1;
        $new_urx = -$lly1;
        $new_ury = -$urx1;
     }elsif($angle == 180){
        $new_llx = -$urx1;
        $new_lly = -$ury1;
        $new_urx = -$llx1;
        $new_ury = -$lly1;
     }elsif($angle == 270){
        $new_llx = $lly1;
        $new_lly = -$urx1;
        $new_urx = $ury1;
        $new_ury = -$llx1;
     }else{
        $new_llx = $llx;
        $new_lly = $lly;
        $new_urx = $urx;
        $new_ury = $ury;
      }
      return($new_llx, $new_lly, $new_urx, $new_lly, $new_urx, $new_ury, $new_llx, $new_ury, $new_llx, $new_lly);
   }#sub transform_sref_inst
   
   %SREF_DATA = (); #making hash empty

   ############ transfer the polygons in %boundary_layer_hash #############
   my @data_arr = @{@CELL_POLYGONS{$top_module}};
   foreach my $poly (@data_arr){
     my @polygon = @$poly;
     if(exists $boundary_layer_hash{$polygon[0]}){
        push(@{$boundary_layer_hash{$polygon[0]}}, [@polygon]);
     }
   }

   %CELL_POLYGONS = (); #making hash empty

   ####################### Making groups of Overlapping  Polygon #######################
   foreach my $l(keys %overlap_layer_hash){
      @poly_arr = @{$boundary_layer_hash{$l}}; ##Global
      my @group_arr = ();
      for(my $i=0; $i<=$#poly_arr; $i++){
          if($poly_arr[$i] eq ""){next;}
          my @sub_poly = @{$poly_arr[$i]};
          my @overlapped_poly = ();
          my @p = ();
          for(my $k=1; $k<=$#sub_poly; $k=$k+2){
              push(@p,[$sub_poly[$k],$sub_poly[$k+1]]);
          }
          for(my $j=$i+1; $j<=$#poly_arr; $j++){
              if($poly_arr[$j] eq ""){next;}
              my @clip_poly = @{$poly_arr[$j]};     
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
                 delete $poly_arr[$j];
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
                    delete $poly_arr[$j];
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
                       delete $poly_arr[$j];
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
                          delete $poly_arr[$j];
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
                             delete $poly_arr[$j];
                          }
                       }
                    }
                 }
              }#if touch
          }
          if($#overlapped_poly >= 0){
             unshift(@overlapped_poly,[@sub_poly]);
             delete $poly_arr[$i];
             push(@overlapped_poly,&get_overlap_poly(\@overlapped_poly));
             #-------- making group array ------#
             push(@group_arr,[@overlapped_poly]);
          }else{
             push(@group_arr,[[@sub_poly]]);
          }
      }
      @{$layer_group_hash{$l}} = @group_arr;
   }
   ########## Recursive function to get groups of polygons for indivisual layer #########
   sub get_overlap_poly{
     my @sub_poly_arr = @{$_[0]};
     my @ovl_poly = ();
     for(my $i=0; $i<=$#sub_poly_arr; $i++){
         my @sub_poly = @{$sub_poly_arr[$i]};
         my @p = ();
         for(my $k=1; $k<=$#sub_poly; $k=$k+2){
             push(@p,[$sub_poly[$k],$sub_poly[$k+1]]);
         }
         for(my $j=0; $j<=$#poly_arr; $j++){
             if($poly_arr[$j] eq ""){next;}
             my @clip_poly = @{$poly_arr[$j]};     
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
                delete $poly_arr[$j];
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
                   delete $poly_arr[$j];
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
                      delete $poly_arr[$j];
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
                         delete $poly_arr[$j];
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
                            delete $poly_arr[$j];
                         }
                      }
                   }
                }
             }
         }
         if($#ovl_poly >= 0){
           push(@ovl_poly, &get_overlap_poly(\@ovl_poly));
         }
     }
     return @ovl_poly;
   }#sub get_overlap_poly

   ################# Making Final groups of polygons (combined layers) ############### 
   foreach my $layer (sort{$a<=>$b}keys %overlap_layer_hash){
     @layer_group = @{$layer_group_hash{$layer}}; ##Global
     for(my $i=0; $i<=$#layer_group; $i++){
         if($layer_group[$i] eq ""){next;}
         my @group_poly = ();
         my $group = $layer_group[$i];
         push(@group_poly, @$group);
         delete $layer_group[$i];
         push(@group_poly, &get_hier_overlap($layer, $group, $layer));
         push(@final_groups, [@group_poly]);
     }#foreach group
     @{$layer_group_hash{$layer}} = @layer_group;
   }#foreach layer

   sub get_hier_overlap {
     my $layer = $_[0];
     my $group = $_[1];
     my $starting_layer = $_[2];

     my $via_layer = $overlap_layer_hash{$layer};
     my @via_overlapped = ();
     my @group_poly = ();
     foreach my $poly (@$group){
        my @via_poly_arr = @{$boundary_layer_hash{$via_layer}};
        my @sub_poly = @$poly;
        my @p = ();
        for(my $i=1; $i<=$#sub_poly; $i=$i+2){
            push(@p,[$sub_poly[$i],$sub_poly[$i+1]]);
        }
        for(my $j=0; $j<=$#via_poly_arr; $j++){
            if($via_poly_arr[$j] == ""){next;}
            my @clip_poly = @{$via_poly_arr[$j]};
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
               push(@group_poly, [@clip_poly]);
               delete $via_poly_arr[$j];
               @{$boundary_layer_hash{$via_layer}} = @via_poly_arr;
            }
        }
     }#foreach polygon
     my $second_layer = $via_hash{$via_layer};
     for(my $i=0; $i<=$#via_overlapped; $i++){
         my @via_poly = @{$via_overlapped[$i]}; 
         my @second_lgrp = @{$layer_group_hash{$second_layer}};
         my @p = ();
         for(my $j=1; $j<=$#via_poly; $j=$j+2){
             push(@p,[$via_poly[$j],$via_poly[$j+1]]);
         }
         LOOPA:for(my $j=0; $j<=$#second_lgrp; $j++){
             my $group = $second_lgrp[$j];
             foreach my $polygon (@$group){
               my @clip_poly = @$polygon;
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
                  push(@group_poly, @$group);
                  delete $second_lgrp[$j];
                  @{$layer_group_hash{$second_layer}} = @second_lgrp;
                  push(@group_poly, &get_rev_hier_overlap($second_layer, $group, $starting_layer));
                  push(@group_poly, &get_hier_overlap($second_layer, $group, $starting_layer));
                  last LOOPA;
               }
             }
         }
     }
     return @group_poly;
   }#sub get_hier_overlap
   
   sub get_rev_hier_overlap {
     my $layer = $_[0];
     my $group = $_[1];
     my $starting_layer = $_[2];
   
     my $rev_via_layer = $rev_overlap_layer_hash{$layer};
     my @rev_via_overlapped = ();
     my @group_poly = ();
     foreach my $poly (@$group){
        my @sub_poly = @$poly;
        my @rev_via_poly_arr = @{$boundary_layer_hash{$rev_via_layer}};
        my @p = ();
        for(my $i=1; $i<=$#sub_poly; $i=$i+2){
            push(@p,[$sub_poly[$i],$sub_poly[$i+1]]);
        }
        for(my $j=0; $j<=$#rev_via_poly_arr; $j++){
            if($rev_via_poly_arr[$j] == ""){next;}
            my @clip_poly = @{$rev_via_poly_arr[$j]};
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
               push(@group_poly, [@clip_poly]);
               delete $rev_via_poly_arr[$j];
               @{$boundary_layer_hash{$rev_via_layer}} = @rev_via_poly_arr;
            }
        }
     }#foreach polygon
     my $first_layer = $rev_via_hash{$rev_via_layer};
     for(my $i=0; $i<=$#rev_via_overlapped; $i++){
         my @via_poly = @{$rev_via_overlapped[$i]}; 
         my @first_lgrp = @{$layer_group_hash{$first_layer}};
         my @p = ();
         for(my $j=1; $j<=$#via_poly; $j=$j+2){
             push(@p,[$via_poly[$j],$via_poly[$j+1]]);
         }
         LOOPB:for(my $j=0; $j<=$#first_lgrp; $j++){
             my $group = $first_lgrp[$j];
             foreach my $polygon (@$group){
               my @clip_poly = @$polygon;
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
                  push(@group_poly, @$group);
                  delete $first_lgrp[$j];
                  @{$layer_group_hash{$first_layer}} = @first_lgrp;
                  if($starting_layer == $first_layer){
                     delete $layer_group[$j];
                  }
                  push(@group_poly, &get_hier_overlap($first_layer, $group, $starting_layer));
                  push(@group_poly, &get_rev_hier_overlap($first_layer, $group, $starting_layer));
                  last LOOPB;
               }
             }
         }
     }
     return @group_poly;
   }#sub get_rev_hier_overlap

   my @obs_poly = ();
   my @top_pins = @{$PIN_TEXT_COORDS{$top_module}};

   %boundary_layer_hash = (); #making hash empty

   for(my $i=0; $i<=$#final_groups; $i++){
       if($final_groups[$i] eq ""){next;}
       my $group = $final_groups[$i];
       my $isInside = 0;
       foreach my $poly (@$group){
         my @poly_coords = @$poly;
         my @p = ();
         for(my $j=1; $j<=$#poly_coords; $j=$j+2){
             push(@p,[$poly_coords[$j],$poly_coords[$j+1]]);
         }
         my $count = -1;
         foreach my $pin_line (@top_pins){
           $count++;
           if($pin_line eq ""){next;}
           my ($pin, @pin_point) = @$pin_line;
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
              delete $top_pins[$count];
              last;
           }
         }#foreach pin
       }#foreach polygon
       if($isInside == 0){
          push(@obs_poly, @{$final_groups[$i]});
       }
   }#foreach group
   @{$pin_poly_hash{OBS}} = @obs_poly;

   @final_groups = (); #making array empty
   
   my ($layer_name,$width, $height) = @{$cell_size{$top_module}};
   
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
        if($pin =~ /vss/i){
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

   ######################## End of Script ##########################
}#if correct num of arg

my $t1 = new Benchmark;
my $td = timediff($t1, $t0);
print "script gds2lef took:",timestr($td),"\n";



