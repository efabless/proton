#!/usr/bin/perl
use Math::Clipper ':all';
use Benchmark;
my $t0 = new Benchmark;

my $noOfArg = @ARGV;
my ($originalLef, $generatedLef) = ("", "");
if($noOfArg < 4 || $_[0] eq '-h' || $_[0] eq '-help' || $_[0] eq '-HELP') {
   print "usage : ./verify_gds2lef.pl   -original_lef < original lef file >\n";
   print "                              -gds2lef < lef generated from gds >\n";
}else {
   for(my $i=0 ; $i<=$noOfArg; $i++){
       if($ARGV[$i] eq "-original_lef"){$originalLef = $ARGV[$i+1];} 
       if($ARGV[$i] eq "-gds2lef"){$generatedLef = $ARGV[$i+1];} 
   }#for correct no.of Arguments

   ######################### Reading original lef #############################
   my %macro_pin_hash = &read_lef_file($originalLef);

   ######################### Reading generated lef ############################
   my %gds2lef_macro_pin_hash = &read_lef_file($generatedLef);

   ############################## comparison ##################################
   foreach my $macro (keys %macro_pin_hash){
     my %pin_poly_hash = %{$macro_pin_hash{$macro}};
     if(exists $gds2lef_macro_pin_hash{$macro}){
        my %gds2lef_pin_poly_hash = %{$gds2lef_macro_pin_hash{$macro}};
        print "comparison for Macro $macro\n";
        foreach my $pin (keys %pin_poly_hash){
           my @poly = @{$pin_poly_hash{$pin}};
           my @gds2lef_poly = @{$gds2lef_pin_poly_hash{$pin}};
           foreach my $poly_line (@poly){
              my $match_found = 0;
              my @coords = split(/\s+/,$poly_line);
              my $layerName = shift @coords;
              my @p = ();
              for(my $i=0; $i<=$#coords; $i=$i+2){
                  push(@p,[$coords[$i],$coords[$i+1]]);
              }
              foreach my $gds2lef_poly_line(@gds2lef_poly){
                 my @g2l_coords = split(/\s+/,$gds2lef_poly_line);
                 my $g2l_layer = shift @g2l_coords;
                 if($layerName eq $g2l_layer){
                    my @p1 = ();
                    for(my $j=0; $j<=$#g2l_coords; $j=$j+2){
                        push(@p1,[$g2l_coords[$j],$g2l_coords[$j+1]]);
                    }
                    my $clipper = Math::Clipper->new;
                    $clipper->add_subject_polygon([@p]);
                    $clipper->add_clip_polygon([@p1]);
                    my $result = $clipper->execute(CT_DIFFERENCE);
                    my @result_arr = @$result;
                    my $result_arr_len = @result_arr;
                    if($result_arr_len == 0){
                       $match_found = 1;
                       last;
                    }
                 }#if layers are equal
              }#for each gds2lef polygon 
              if($match_found == 0){
                 print "WARN: PIN $pin Polygon \"$poly_line\" not found in gds2lef\n"; 
              }
           }#for each orig. lef polygon           
        }#foreach pin of macro 
     }else{
       print "WARN: Macro $macro does not found in gds2lef\n";
     }
   }
   ############################################################################
   
}#if correct num of arg

my $t1 = new Benchmark;
my $td = timediff($t1, $t0);
print "script gds2lef took:",timestr($td),"\n";


###############################################################################
sub read_lef_file {
  my $file = $_[0];
  my %macro_pin_hash = ();
  my %pin_poly_hash = ();

  my $macroName = "";
  my $pinName = "";
  my $polygon_start = 0;
  my $polygon_data = "";
  my $layerName = "";
  my @pin_poly = ();  

  my $obs_polygon_start = 0;
  my $obs_polygon_data = "";
  my $obsLayer = "";
  my @obs_poly = ();
  
  open(READ_LEF, "$file");
  while(<READ_LEF>){
  chomp();
    $_ =~ s/^\s+//;
    if($_ =~ /^\s*#/) {next ; }
    if($_ =~ /\#/ )   {$_ =~ s/\s+#.*$//;}
    if($_ =~ /^MACRO/){ 
       $macroName = (split(/\s+/, $_))[1];
       %pin_poly_hash = ();
    }# if MACRO
    if(/^MACRO $macroName/ ... /^END $macroName\s*$/){
       if($_ =~ /^END $macroName\s*$/){
          %{$macro_pin_hash{$macroName}} = %pin_poly_hash;
       }
       if($_ =~ /^PIN/){
          $pinName=(split(/\s+/,$_))[1];
          @pin_poly = ();
          $polygon_start = 0;
          $polygon_data = "";
       }
       if($_ =~ /^OBS/){
          @obs_poly = ();
          $obs_polygon_start = 0;
          $obs_polygon_data = "";
       }
       if(/^PIN $pinName/ ... /^END $pinName/){
          if($_ =~ /^END $pinName/){ 
             @{$pin_poly_hash{$pinName}} = @pin_poly;
             $polygon_start = 0;
             $polygon_data = "";
          }#if end of PIN
          if($_ =~ /^LAYER / ) { 
             $layerName = (split(/\s+/,$_))[1]; 
             $polygon_start = 0;
             $polygon_data = "";
          }#if Layer
          if($_ =~ /^RECT/) {
             $polygon_start = 0;
             $polygon_data = "";
             my ($llx,$lly,$urx,$ury) = (split(/\s+/,$_))[1,2,3,4];
             my $data = "$layerName $llx $lly $urx $lly $urx $ury $llx $ury $llx $lly";
             push(@pin_poly, $data); 
          }#if Rect
          if($_ =~ /^POLYGON/){
             $polygon_start = 1;
             $polygon_data = "";
          }#if polygon 
          if($polygon_start == 1){
             if($_ =~ /\s*;\s*/){
                $polygon_data = $polygon_data." ".$_;
                $polygon_data =~ s/POLYGON//;
                $polygon_data =~ s/;//;
                my $polygon_layer_with_data = "$layerName $polygon_data";
                push(@pin_poly, $polygon_layer_with_data); 
             }else{
                $polygon_data = $polygon_data." ".$_;
             }
          }#if Polygon

       }#pin block
       if(/\bOBS\b/ ... /\bEND\b/ ) {
          if($_ =~ /\bEND\b/){ 
            @{$pin_poly_hash{OBS}} = @obs_poly;
          }elsif($_ =~ /^LAYER\b/){ 
             $obsLayer = (split(/\s+/,$_))[1]; 
             $obs_polygon_start = 0;
             $obs_polygon_data = "";
          }elsif($_ =~ /^RECT\b/) { 
             my ($llx,$lly,$urx,$ury) = (split(/\s+/,$_))[1,2,3,4];
             my $obsData = "$obsLayer $llx $lly $urx $lly $urx $ury $llx $ury $llx $lly";
             push(@obs_poly, $obsData);
             $obs_polygon_start = 0;
             $obs_polygon_data = "";
          }elsif($_ =~ /^POLYGON/) { 
            $obs_polygon_start = 1;
            $obs_polygon_data = "";
          }
          if($obs_polygon_start == 1){
             if($_ =~ /\s*;\s*/){
                $obs_polygon_data = $obs_polygon_data." ".$_;
                $obs_polygon_data =~ s/POLYGON//;
                $obs_polygon_data =~ s/;//;
                my $obs_poly_with_layer = "$obsLayer $obs_polygon_data";
                push(@obs_poly, $obs_poly_with_layer);
             }else{
                $obs_polygon_data = $obs_polygon_data." ".$_;
             }
          }#elsif obs
       }#if between the OBS statements
    }#if between the MACRO statements
  }#while reading file 
  close READ_LEF;
  return %macro_pin_hash;
}#sub read_lef_file

###############################################################################


