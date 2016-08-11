#!/usr/bin/perl
use XML::Simple;
#use Devel::Size qw(size total_size);
use Benchmark;
my $t0 = new Benchmark;

################################## for testing ##########################################
use Tk;
use Tk::WorldCanvas;
my $mw = MainWindow->new();
my $canvas = $mw->Scrolled('WorldCanvas', -scrollbars=>'se',-bg =>'black',-width=>540, -height=>540)->pack(qw/-side left -expand 1 -fill both/);
my @colors = ('green', 'yellow', 'magenta', 'blue', 'tan', 'violet', 'orange', 'purple', 'pink');
#########################################################################################

my $noOfArg = @ARGV;
my $layerMapFile;
my @fileList = ();
my $tolerance = 0.0001;

if($noOfArg < 4 || $ARGV[0] eq '-h' || $ARGV[0] eq '-help' || $ARGV[0] eq '-HELP') {
   print "usage : ./create_pin_groups.pl -group_file_list < file1,file2,file3... >\n";
   print "                               -layer_map_file < layer map file >\n";
}else {
   for(my $i=0 ; $i<$noOfArg; $i++){
       if($ARGV[$i] eq "-group_file_list"){
          my $fileListStr = $ARGV[$i+1];
          @fileList = split(/\,/,$fileListStr);
       } 
       if($ARGV[$i] eq "-layer_map_file"){$layerMapFile = $ARGV[$i+1];} 
       if($ARGV[$i] eq "-tolerance"){$tolerance = $ARGV[$i+1];} 
   }#for correct no.of Arguments

   #########################################################################################
   ################################ Reading layer Map file #################################
   #########################################################################################
   my %overlap_layer_hash = ();
   my %via_hash = ();
   my %rev_overlap_layer_hash = ();
   my %rev_via_hash = ();
   
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
   
   #########################################################################################
   #################### creating array of routing & via layer polys ########################
   #########################################################################################
   my %routing_layer_polys = ();
   my %via_layer_polys = ();
   my $group;
   foreach my $file (@fileList){
      my $current_routing_layer = $file;
      $current_routing_layer =~ s/gds_layer_groups_//;   
      open(READ, $file);
        while(<READ>){
           chomp();
           if($_ =~ /^\s*#/ ){next ;}
           if($_ =~ /^GROUP/ ){
              $group = (split(/\:/, $_))[1];
              next;
           }
           my ($layer_type, $layer, @poly_coords) = split(/\s+/, $_);
         
           ######## removing last point which is same as fist point ########
           #pop @poly_coords;
           #pop @poly_coords;
      
           if($layer_type eq "P"){
              push (@{$routing_layer_polys{$current_routing_layer}{$group}}, [$layer, @poly_coords]);
           }else{
              my $coord_str = $layer."_".join('_',@poly_coords);
              $via_layer_polys{$current_routing_layer}{$group}{$coord_str} = 1;
           }
      
        }
      close(READ);
   }
   
   #print "INFO-GDS2LEF : 201 : reading files completed...\n";    
   my $t1 = new Benchmark;
   my $td0 = timediff($t1, $t0);
   print "INFO-GDS2LEF-TIME: 201 : reading files completed in :",timestr($td0),"\n";
     
   open(WRITE,">gds_layer_final_groups");
   my $grp_cnt = 0;
   my %temp_dup_via = ();
   foreach my $routing_layer (sort{$a<=>$b}keys %overlap_layer_hash){
      foreach my $group(keys %{$routing_layer_polys{$routing_layer}}){
         if(exists $routing_layer_polys{$routing_layer}{$group}){
            print WRITE "GROUP:$grp_cnt\n";
            foreach my $p (@{$routing_layer_polys{$routing_layer}{$group}}){
               print WRITE "@$p\n";
            }
            
            delete $routing_layer_polys{$routing_layer}{$group};
            #@{$routing_layer_polys{$routing_layer}{$group}} = ();
            &get_hier_overlap($routing_layer, $group);
            $grp_cnt++;
         }
      }#foreach group
   }#foreach layer
   close(WRITE);


   my $t2 = new Benchmark;
   my $td1 = timediff($t2, $t1);
   print "INFO-GDS2LEF-TIME: 202 : final group completed in :",timestr($td1),"\n";
   my $td2 = timediff($t2, $t0);
   print "INFO-GDS2LEF-TIME: 203 : script create_pin_groups took :",timestr($td2),"\n";
   
   ###**************** for testing ********************###
   #$canvas->viewAll();
   #my @box_org = $canvas->getView();
   #&canvas_zoomIn_zoomOut($canvas,\@box_org);
   #MainLoop();
   ###*************************************************###
   #########################################################################################
   ######################### function to get connectivity forth ############################
   #########################################################################################
   sub get_hier_overlap {
     my $layer = $_[0];
     my $group = $_[1];
   
     my $via_layer = $overlap_layer_hash{$layer};
     if(!exists $via_hash{$via_layer}){return;}
   
     foreach my $via (keys %{$via_layer_polys{$layer}{$group}}){
        if(!exists $via_layer_polys{$layer}{$group}{$via}){next;}
        my ($via_layer1) = $via =~ /(\d+)/;
        if($via_layer1 != $via_layer){next;};
        if(!exists $temp_dup_via{$via}){
           $temp_dup_via{$via} = 1;
           my @via_poly = split(/\_/,$via);
           print WRITE "@via_poly\n";
        }else{
           delete $temp_dup_via{$rev_via};
        }
        delete $via_layer_polys{$layer}{$group}{$via};
        my $up_routing_layer = $via_hash{$via_layer1}; 
        foreach $up_group (keys %{$routing_layer_polys{$up_routing_layer}}){
           if(exists $via_layer_polys{$up_routing_layer}{$up_group}{$via}){
              foreach my $p (@{$routing_layer_polys{$up_routing_layer}{$up_group}}){
                 print WRITE "@$p\n";
              }
              delete $routing_layer_polys{$up_routing_layer}{$up_group};
              #@{$routing_layer_polys{$up_routing_layer}{$up_group}} = ();
              #undef $routing_layer_polys{$up_routing_layer}{$up_group};
              delete $via_layer_polys{$up_routing_layer}{$up_group}{$via};
              &get_hier_overlap($up_routing_layer, $up_group);
              &get_rev_hier_overlap($up_routing_layer, $up_group);
              last;
           }
        }
     }
   }#sub get_hier_overlap
   
   #########################################################################################
   ########################## function to get connectivity back ############################
   #########################################################################################
   sub get_rev_hier_overlap {
     my $layer = $_[0];
     my $group = $_[1];
   
     my $rev_via_layer = $rev_overlap_layer_hash{$layer};
     if(!exists $via_hash{$rev_via_layer}){return;}
   
     foreach my $rev_via (keys %{$via_layer_polys{$layer}{$group}}){
        if(!exists $via_layer_polys{$layer}{$group}{$rev_via}){next;}
        my ($rev_via_layer1) = $rev_via =~ /(\d+)/;
        if($rev_via_layer1 != $rev_via_layer){next;};
        if(!exists $temp_dup_via{$rev_via}){
           $temp_dup_via{$rev_via} = 1;
           my @rev_via_poly = split(/\_/,$rev_via);
           print WRITE "@rev_via_poly\n";
        }else{
           delete $temp_dup_via{$rev_via};
        }
        delete $via_layer_polys{$layer}{$group}{$rev_via};
        my $down_routing_layer = $rev_via_hash{$rev_via_layer1};
        foreach my $down_group (keys %{$routing_layer_polys{$down_routing_layer}}){
           if(exists $via_layer_polys{$down_routing_layer}{$down_group}{$rev_via}){
              foreach my $p (@{$routing_layer_polys{$down_routing_layer}{$down_group}}){
                 print WRITE "@$p\n";
              }
              delete $routing_layer_polys{$down_routing_layer}{$down_group};
              #@{$routing_layer_polys{$down_routing_layer}{$down_group}} = ();
              #undef $routing_layer_polys{$down_routing_layer}{$down_group};
              delete $via_layer_polys{$down_routing_layer}{$down_group}{$rev_via};
              &get_rev_hier_overlap($down_routing_layer, $down_group);
              &get_hier_overlap($down_routing_layer, $down_group);
              last;
           }
        }
     }
   }#sub get_rev_hier_overlap
      
}#if correct num of arg

#########################################################################################
######################## function to zoomIn & zoomOut canvas ############################
#########################################################################################
sub canvas_zoomIn_zoomOut{
  my @arg = @_;
  my $canvas = $arg[0];
  my @view_bbox = @{$arg[1]};
  #$canvas->CanvasFocus;
  #$canvas->configure(-bandColor => 'red');
  $canvas->CanvasBind('<3>'               => sub {$canvas->configure(-bandColor => "");
                                                  $canvas->configure(-bandColor => 'red');
                                                  $canvas->rubberBand(0)});
  $canvas->CanvasBind('<B3-Motion>'       => sub {$canvas->rubberBand(1)});
  $canvas->CanvasBind('<ButtonRelease-3>' => sub {my @box = $canvas->rubberBand(2);
                                                  $canvas->viewArea(@box, -border => 0);
                                                  });
  $canvas->CanvasBind('<2>'               => sub {$canvas->viewArea(@view_bbox, -border => 0);});               
  
  $canvas->CanvasBind('<i>' => sub {$canvas->zoom(1.25);});
  $canvas->CanvasBind('<o>' => sub {$canvas->zoom(0.80);});
  $canvas->CanvasBind('<f>' => sub {$canvas->viewArea(@view_bbox, -border => 0);});
  
  $mw->bind('WorldCanvas',    '<Up>' => "");
  $mw->bind('WorldCanvas',  '<Down>' => "");
  $mw->bind('WorldCanvas',  '<Left>' => "");
  $mw->bind('WorldCanvas', '<Right>' => "");
  
  $canvas->CanvasBind('<KeyPress-Up>'   => sub {$canvas->panWorld(0,  200);});
  $canvas->CanvasBind('<KeyPress-Down>' => sub {$canvas->panWorld(0, -200);});
  $canvas->CanvasBind('<KeyPress-Left>' => sub {$canvas->panWorld(-200, 0);});
  $canvas->CanvasBind('<KeyPress-Right>'=> sub {$canvas->panWorld( 200, 0);});
}#sub canvas_zoomIn_zoomOut
