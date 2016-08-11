#!/usr/bin/perl 
my $fileName_1 = "";
my $fileName_2 = "";
my $file_1_given = 0;
my $file_2_given = 0;
my $comp_given = 0;
my $pin_given = 0;
my $net_given = 0;
my $spnet_given = 0;
my $group_given = 0;
my $blockage_given = 0;
my $summary = 0;
my $detailed = 0;
my $xml = 0;
my $noOfPins_file_1 = ""; 
my $noOfPins_file_2 = ""; 
my $noOfComponents_file_1 = "";
my $noOfComponents_file_2 = "";
my $noOfNets_file_1 = "";
my $noOfNets_file_2 = "";
my $noOfSPNets_file_1 = "";
my $noOfSPNets_file_2 = "";
my $noOfBlockages_of_file_1 = "";
my $noOfBlockages_of_file_2 = "";
my $noOfGroups_of_file_1 = "";
my $noOfGroups_of_file_2 = "";
my @unmatched_pin = ();
my @unmatched_inst = ();
my %unmatched_net = ();
my %unmatched_spnet = ();
my %matched_spnet = ();
my %matched_net = ();
my %unmatched_inst_of_net = ();
my %unmatched_pin_of_net = ();
my %unmatched_layer_of_net = ();
my %unmatched_via_of_net = ();
my @pinName_list = ();
my @inst_list = ();
my @net_list = ();
my @spnet_list = ();
my %PORT_DATA_file_1 = ();
my %PORT_DATA_file_2 = ();
my %COMP_DATA_file_1 = ();
my %COMP_DATA_file_2 = ();
my %NET_DATA_HASH_file_1 = ();
my %NET_DATA_HASH_file_2 = ();
my %NET_ROUTING_DATA_HASH_file_1 = ();
my %NET_ROUTING_DATA_HASH_file_2 = ();
my %NET_ROUTING_WITH_LAYER_NAME_OF_FILE_1 = ();
my %NET_ROUTING_WITH_LAYER_NAME_OF_FILE_2 = ();
my %NET_ROUTING_WITH_VIA_NAME_OF_FILE_1 = ();
my %NET_ROUTING_WITH_VIA_NAME_OF_FILE_2 = ();

my %SPNET_DATA_HASH_file_1 = ();
my %SPNET_DATA_HASH_file_2 = ();
my %SPNET_ROUTING_DATA_HASH_file_1 = ();
my %SPNET_ROUTING_DATA_HASH_file_2 = ();

my %SPNET_ROUTING_WITH_LAYER_NAME_OF_FILE_1 = ();
my %SPNET_ROUTING_WITH_WIDTH_NAME_OF_FILE_1 = ();
my %SPNET_ROUTING_WITH_SHAPE_NAME_OF_FILE_1 = ();
my %SPNET_ROUTING_WITH_VIA_NAME_OF_FILE_1 = ();

my %SPNET_ROUTING_WITH_LAYER_NAME_OF_FILE_2 = ();
my %SPNET_ROUTING_WITH_WIDTH_NAME_OF_FILE_2 = ();
my %SPNET_ROUTING_WITH_SHAPE_NAME_OF_FILE_2 = ();
my %SPNET_ROUTING_WITH_VIA_NAME_OF_FILE_2 = ();

my %unmatched_inst_of_spnet = ();
my %unmatched_pin_of_spnet = ();
my %unmatched_routing_co_ord_spnet = ();
my %unmatched_layer_of_spnet = ();
my %unmatched_via_of_spnet = ();
my %unmatched_width_of_spnet = ();
my %unmatched_shapeName_of_spnet = ();

my %GROUP_INST_HASH_of_file_1 = ();
my %GROUP_REGION_HASH_of_file_1 = ();
my %GROUP_INST_HASH_of_file_2 = ();
my %GROUP_REGION_HASH_of_file_2 = ();

my %matched_grp = ();
my %unmatched_grp = ();
my %unmatched_inst_of_grp = ();
my %unmatched_region_of_grp = ();

my %BLOCKAGE_LAYER_HASH_OF_FILE_1 = ();
my %BLOCKAGE_RECT_HASH_OF_FILE_1 = ();
my %BLOCKAGE_RECT_WITH_LAYER_NAME_OF_FILE_1 = ();
my %BLOCKAGE_LAYER_HASH_OF_FILE_2 = ();
my %BLOCKAGE_RECT_HASH_OF_FILE_2 = ();
my %BLOCKAGE_RECT_WITH_LAYER_NAME_OF_FILE_2 = ();

my %matched_blk = ();
my %unmatched_blk = ();
my %unmatched_layer_of_blk = ();
my %unmatched_co_ord_of_blk = ();


for(my $i =0; $i<=$#ARGV;$i++){
  if($ARGV[$i] eq "-f1"){$fileName_1 = $ARGV[$i+1];$file_1_given = 1;}
  if($ARGV[$i] eq "-f2"){$fileName_2 = $ARGV[$i+1];$file_2_given = 1;}
  if($ARGV[$i] eq "-pin"){$pin_given = 1;}
  if($ARGV[$i] eq "-comp"){$comp_given = 1;}
  if($ARGV[$i] eq "-net"){$net_given = 1;}
  if($ARGV[$i] eq "-spnet"){$spnet_given = 1;}
  if($ARGV[$i] eq "-grp"){$group_given = 1;}
  if($ARGV[$i] eq "-blk"){$blockage_given = 1;}
  if($ARGV[$i] eq "-summary"){$summary = 1;}
  if($ARGV[$i] eq "-detailed"){$detailed = 1;}
  if($ARGV[$i] eq "-xml"){$xml = 1;}
}
if($file_1_given == 1){
my $READ_PINS = 1;
my $READ_COMPONENTS = 1;
my $READ_NETS = 1;
my $READ_SPNETS = 1;
my $READ_ROUTES = 1;
my $READ_SPROUTES = 1;
my $READ_REGION = 1;
my $READ_GROUPS = 1;
my $READ_BLKGS = 1;
my $net_data_start = 0;
my $spnet_data_start = 0;
my $reading_spnets = 0;
my $reading_nets = 0;
my $reading_groups = 0;
my $reading_blkgs = 0;
$line = "";
open(READ_DEF_FILE_1,"$fileName_1");
my $lineCount = 0;
while(<READ_DEF_FILE_1>){
if($STOP_IMMEDIATELY == 1) { last; }
$lineCount++;
if($lineCount =~ /0$/) {
}
else {}
chomp($_);
$_ =~ s/^\s+//;
if( $_ =~ /^\s*#/ ) { next; }
elsif(/^PROPERTYDEFINITIONS/ ... /END PROPERTYDEFINITIONS/) { next;}
else {
  if($pin_given == 1){
    if(/^PINS\b/.../^END PINS\b/){ 
      if ( $READ_PINS == 0 ) { next; } 
        else {
          if($_ =~ /^PINS/){ if ( $READ_PINS ==1 ) { $line = "";$noOfPins_file_1 = (split(/\s+/, $_))[1]; next;} else { next; }}
          if($_ =~ /^END PINS/){next;}
          if($_ =~ /\;\s*$/){ 
            if ( $READ_PINS ==1 ) {
              chomp();
              $_ =~ s/^\s+//;
              $line = $line." ".$_;
              $line =~ s/^\s+//;
              @port_data = split(/\s+/, $line);
              shift @port_data;
              my $pinName = shift @port_data;
              push(@pinName_list,$pinName);
              my $pin_data = "";
              while ( defined ($data = shift @port_data) ) {
                if ( $data eq "NET" ) { $net_Name = shift @port_data;
                }elsif ( $data eq "DIRECTION"){ $pinDirection = shift @port_data;
                                               $pin_data = $pin_data." ".$pinDirection;
                }elsif ( $data eq "USE" ) { $SIGNAL = shift @port_data;
                                            $pin_data = $pin_data." ".$SIGNAL;
                }elsif ( $data eq "PLACED" || $data eq "FIXED" ) {
                                                           shift @port_data;
                                                           $dbX = shift @port_data;
                                                           $dbY = shift @port_data;
                                                           my $loc = $dbX." ".$dbY;
                                                           shift @port_data;
                                                           $side = shift @port_data;
                                                           $pin_data = $pin_data." ".$side;
                                                           $pin_data = $pin_data." ".$loc;
               }elsif ( $data eq "LAYER" ) { $layer = shift @port_data; 
                                           $pin_data = $pin_data." ".$layer;
                                           shift @port_data;
                                           my $x1 = shift @port_data;
                                           my $y1 = shift @port_data;
                                           shift @port_data;
                                           shift @port_data;
                                           my $x2 = shift @port_data;
                                           my $y2 = shift @port_data;
                                           my $W = $x2 - $x1;
                                           my $H = $y2 - $y1;
              }else {}
            }#while
            $PORT_DATA_file_1{$pinName} = $pin_data;
            $line = ""; 
          } else { next;}
    }else{
      if ( $READ_PINS ==1 ) {chomp(); $_ =~ s/^\s+//; $line = $line." ".$_; }else {next;} 
    }
  }
}#if pins
}#if pin given
#----------------------------------------------------------------------------------------------------------------------------------#
elsif($comp_given == 1){
  if(/^COMPONENTS/ ... /^END COMPONENTS/){
    if ( $READ_COMPONENTS == 0 ) { next; 
    }else {
      if($_ =~ /^COMPONENTS/) { $noOfComponents_file_1 = (split(/\s+/, $_))[1];}
      if($_ =~ /^END COMPONENTS/) {}
      if($_ =~ /\;\s*$/){ $line = $line." ".$_;
        chomp;
        $line =~ s/^\s+//;
          if( $line =~ /-/){
            my ($instance, $cellref) = (split(/\s+/, $line))[1,2];
            my $comp_data = "";
            $instance =~ s/\\//g;
            push (@inst_list,$instance);
            @comp_placement_data = split(/\s+/, $line);
            while ( defined ($placement_data = shift @comp_placement_data) ) {
              if( $placement_data eq "PLACED" || $placement_data eq "FIXED" || $placement_data eq "UNPLACED") {
                $comp_data = $comp_data." ".$placement_data;
                shift @comp_placement_data;
                $location_x = shift @comp_placement_data;
                $location_y = shift @comp_placement_data;
                my $location = $location_x." ".$location_y;
                $comp_data = $comp_data." ".$location; 
                shift @comp_placement_data;
                $orientation = shift @comp_placement_data;
                $comp_data = $comp_data." ".$orientation;
              }
            }#while
            $COMP_DATA_file_1{$instance} = $comp_data;
          }else {}
          $line = "";
        }else{
          chomp();
          $line = $line." ".$_; 
        }
    }
  }#if comp
}#if comp given
#------------------------------------------------------------------------------------------------------------------------#
elsif($net_given == 1 ){
if($_ =~ /^\s*\bNETS\b/){ $noOfNets_file_1 = (split(/\s+/,$_))[1];$reading_nets = 1;}
elsif($_ =~ /^\s*\bEND NETS\b/){$reading_nets = 0;}
if($reading_nets == 1 && $READ_NETS == 1){
  my $net_inst_data = "";
  my @net_routing_data = ();
  if($_ =~ /^\-/){
    $net_data_start = 1;
    @net_data = ();
    $netName = (split(/\s+/, $_))[1];
    push(@net_list,$netName);
  }
  if (( $net_data_start == 1) && ($_ =~ /\;\s*$/)) {
    my $abort_current_net = 0;
    my $process_routes = 0;
    push(@net_data, $_);
    my $num = @net_data;
    while ( defined ($line = shift @net_data) ) {
      if ($abort_current_net == 1 ) { last; }
        if ($process_routes == 1 ) {
          if ($line =~ /ROUTED/) { $route_type = R;
            $line =~ s/\+*\s+ROUTED\s+//;
            push(@net_routing_data,$line);
            @{$NET_ROUTING_DATA_HASH_file_1{$netName}} = @net_routing_data;
          }elsif ($line =~ /FIXED/) { $route_type = F;
          }elsif ($line =~ /COVER/) { $route_type = C;
          }elsif ($line =~ /NEW/) { 
             $line =~ s/NEW\s+//;
             push(@net_routing_data,$line);
             @{$NET_ROUTING_DATA_HASH_file_1{$netName}} = @net_routing_data;
          }
        }else {
          my  @net_data_per_line = split(/\s+/, $line);
          while ( defined ($data = shift @net_data_per_line) ) {
            if ($process_routes == 0 ) {
              if ( $data eq "(" ) {
                   $inst = shift @net_data_per_line;
                   $inst =~ s/\\//g;
                   $pin = shift @net_data_per_line;
                   my $data_inst = $inst." ".$pin;
                   $net_inst_data = $net_inst_data." ".$data_inst;
                   $NET_DATA_HASH_file_1{$netName} = $net_inst_data;
                   shift @net_data_per_line;
               }elsif ( $data =~ /\+/ ) {
                 if ( $READ_ROUTES == 0 ) { $abort_current_net = 1; last; }
                 else {$process_routes = 1;} 
               }
            }else {
              if ($line =~ /ROUTED/) { $route_type = R; 
                $line =~ s/\+*\s+ROUTED\s+//;
                push(@net_routing_data,$line);
                @{$NET_ROUTING_DATA_HASH_file_1{$netName}} = @net_routing_data;
                last; 
              }elsif ($line =~ /FIXED/) { $route_type = F; last; 
              }elsif ($line =~ /COVER/) { $route_type = C; last; 
              }elsif ($line =~ /NEW/) { 
                $line =~ s/NEW\s+//;
                push(@net_routing_data,$line);
                @{$NET_ROUTING_DATA_HASH_file_1{$netName}} = @net_routing_data;
                last; 
              }
            }
          }#while
        }# if processing connectivity
    }#while
  }else {
    push(@net_data,$_);
  }
}# if READ_NETS is equal to 1
}#if net given
#------------------------------------------------------------------------------------------------------------------------------------------#
if($spnet_given == 1){
  if($_ =~ /^\s*SPECIALNETS/) { $noOfSPNets_file_1 = (split(/\s+/,$_))[1];$reading_spnets = 1;}
  elsif($_ =~ /^\s*END SPECIALNETS/) {$reading_spnets = 0;} 
  elsif($reading_spnets == 1 && $READ_SPNETS == 1) {
    my $spnet_inst_data = "";
    my @spnet_routing_data = ();
    if($_ =~ /^\-/){
      @spnet_data = ();
      $spnetName = (split(/\s+/, $_))[1];
      push(@spnet_data,$_);
      push(@spnet_list,$spnetName);
    }elsif ( $_ =~ /\;\s*$/ ) {
      my $abort_current_net = 0;
      my $process_routes = 0;
      push(@spnet_data, $_);
      while ( defined ($line = shift @spnet_data) ) {
        if ($abort_current_net == 1 ) { last; }
        my  @net_data_per_line = split(/\s+/, $line);
        while ( defined ($data = shift @net_data_per_line) ) {
          if ($process_routes == 0 ) {
            if ( $data eq "(" ) {
              $inst = shift @net_data_per_line;
              $inst =~ s/\\//g;
              $pin = shift @net_data_per_line;
              my $data_inst = $inst." ".$pin;
              $spnet_inst_data = $spnet_inst_data." ".$data_inst;
              $SPNET_DATA_HASH_file_1{$spnetName} = $spnet_inst_data;
            }elsif ( $data =~ /\+/ ) {
            if ( $READ_SPROUTES == 0 ) { $abort_current_net = 1; last; }
            else {$process_routes = 1;}
            }
          }else {
            if ($line =~ /ROUTED/) { $route_type = R;
                                     $line =~ s/\+*\s+ROUTED\s+//;
                                     push(@spnet_routing_data,$line);
                                     @{$SPNET_ROUTING_DATA_HASH_file_1{$spnetName}} = @spnet_routing_data;
                                     last;
            }elsif ($line =~ /FIXED/) { $route_type = F; 
                                       $line =~ s/\+*\s+FIXED\s+//;
                                       last;
            }elsif ($line =~ /COVER/) { $route_type = C; last; 
            }elsif ($line =~ /NEW/) {
                                     $line =~ s/NEW\s+//;
                                     push(@spnet_routing_data,$line);
                                     @{$SPNET_ROUTING_DATA_HASH_file_1{$spnetName}} = @spnet_routing_data;
                                     last; 
            }elsif ($line =~ /USE/) {
                                    $line =~ s/\+*\s+USE\s+//;
                                    last; 
            }
          }
        }#while
      }
    }else { 
      push(@spnet_data,$_);
    }
  }#if reading spnets
}#if spnet given
#-----------------------------------------------------------------------------------------------------------------#
if($group_given == 1){
if($_ =~ /^\s*\bGROUPS\b/){$noOfGroups_of_file_1 = (split(/\s+/,$_))[1];$reading_groups = 1;} 
elsif($_ =~ /^\s*\bEND GROUPS\b/){$reading_groups = 0;}
  elsif($reading_groups == 1 && $READ_GROUPS == 1){
    my @grp_inst_data = ();
    if($_ =~/^\-/){
      @group_data = ();
      push (@group_data,$_);
      $grpName = (split(/\s+/,$_))[1];
      push(@grpName_list,$grpName);
    }elsif($_ =~ /\;\s*$/){
      my $abort_current_grp = 0;
      my $process_grp = 0;
      push (@group_data,$_);
      while (defined ($line = shift @group_data)){
        if ($abort_current_grp == 1 ) { last; }
        my @grp_data_per_line = split(/\s+/, $line);
        while ( defined ($data = shift @grp_data_per_line) ) { 
            if($process_grp == 0){
              if($data =~ /\-/){next;}
              elsif($data eq $grpName){next;}
              elsif($data =~ /\+/){
                if($READ_REGION == 0){$abort_current_grp = 1;last;}
                else {$process_grp = 1;}
              }else {
                push (@grp_inst_data,$data);
                @{$GROUP_INST_HASH_of_file_1{$grpName}} = @grp_inst_data;
              }
            }else {
              if($line =~ /REGION/){my $region_type = (split(/\s+/,$line))[2];
                                    $GROUP_REGION_HASH_of_file_1{$grpName} = $region_type; 
                                    last;
              }
            }
        }#while
      }#while
    }else {
      push (@group_data,$_);
    }
  }
}#if group given
#-----------------------------------------------------------------------------------------------------------------#
if($blockage_given == 1){
if($_ =~ /^\s*\bBLOCKAGES\b/){$noOfBlockages_of_file_1 = (split(/\s+/,$_))[1];
                              $block_line = "";$blockage_count_no = 0;
                              $reading_blkgs = 1;
}elsif($_ =~ /^\s*\bEND BLOCKAGES\b/){$reading_blkgs = 0;}
elsif ($reading_blkgs == 1 && $READ_BLKGS == 1 ) {
chomp();
  if ($_ =~ /^$/ || $_ =~ /^#/) {next;}
    $block_line = $block_line." ".$_;
    if($_ =~ /\;\s*$/){
      my $routing_blockage_found = 0;
      my $placement_blockage_found = 0;
      my @blockages_string = ();
      my @blkg_data = split(/\s+/,$block_line);
      my $BlkgName;
      while ( defined ($data = shift @blkg_data) ) {
        if ( $data eq "-" ){ $BlkgName = "Blkg".$blockage_count_no; @rect = (); 
        }elsif ( $data eq "LAYER" ) { my $layerName = shift @blkg_data;
          $routing_blockage_found = 1;
          $BLOCKAGE_LAYER_HASH_OF_FILE_1{$BlkgName} = $layerName;
        }elsif ( $data eq "PLACEMENT" ) { 
          $placement_blockage_found = 1;
        }elsif ( $data eq "RECT" ) { 
          shift @blkg_data; 
          my $x1 = shift @blkg_data;
          my $y1 = shift @blkg_data;
          shift @blkg_data;
          shift @blkg_data;
          my $x2 = shift @blkg_data;
          my $y2 = shift @blkg_data;
          push (@blockages_string,$x1,$y1,$x2,$y2);
          @{$BLOCKAGE_RECT_HASH_OF_FILE_1{$BlkgName}} = @blockages_string; 
        }else{}
      }#while
    my $st = join ",", @blockages_string;
    if ($routing_blockage_found == 1) {} else {}
      $blockage_count_no++;
      $block_line = "";
    }elsif ($reading_blkgs == 1 && $READ_BLKGS == 0 ) {next;}
    else{next;}
}#elsif
}#if blockage_given
}#else
}#while
close(READ_DEF_FILE_1);
}#if file 1 given
#-----------------------------------------------------------------------------------------------------------------#
if($file_2_given == 1){
my $READ_PINS = 1;
my $READ_COMPONENTS = 1;
my $READ_NETS = 1;
my $READ_SPNETS = 1;
my $READ_ROUTES = 1;
my $READ_SPROUTES = 1;
my $READ_GROUPS = 1;
my $READ_REGION = 1;
my $READ_BLKGS = 1;
my $net_data_start = 0;
my $spnet_data_start = 0;
my $reading_nets = 0;
my $reading_groups = 0;
my $reading_blkgs = 0;
$line = "";
open(READ_DEF_FILE_2,"$fileName_2");
my $lineCount = 0;
while(<READ_DEF_FILE_2>){
if($STOP_IMMEDIATELY == 1) { last; }
$lineCount++;
if($lineCount =~ /0$/) {
}
else {}
chomp($_);
$_ =~ s/^\s+//;
if( $_ =~ /^\s*#/ ) { next; }
elsif(/^PROPERTYDEFINITIONS/ ... /END PROPERTYDEFINITIONS/) { next;}
else {
  if($pin_given == 1){ 
    if(/^PINS\b/.../^END PINS\b/){ 
      if ( $READ_PINS == 0 ) { next; } 
        else {
          if($_ =~ /^PINS/){ if ( $READ_PINS ==1 ) { $line = ""; $noOfPins_file_2 = (split(/\s+/, $_))[1]; next;} else { next; }}
          if($_ =~ /^END PINS/){ next;}
          if($_ =~ /\;\s*$/){ 
            if ( $READ_PINS ==1 ) {
              chomp();
              $_ =~ s/^\s+//;
              $line = $line." ".$_;
              $line =~ s/^\s+//;
              @port_data = split(/\s+/, $line);
              shift @port_data;
              my $pinName = shift @port_data;
              push(@pinName_list,$pinName);
              my $pin_data = "";
              while ( defined ($data = shift @port_data) ) {
                if ( $data eq "NET" ) { $net_Name = shift @port_data;
                }elsif ( $data eq "DIRECTION"){ $pinDirection = shift @port_data;
                                                $pin_data = $pin_data." ".$pinDirection;
                }elsif ( $data eq "USE" ) { $SIGNAL = shift @port_data;
                                            $pin_data = $pin_data." ".$SIGNAL;
                }elsif ( $data eq "PLACED" || $data eq "FIXED" ) {
                                                                 shift @port_data;
                                                                 $dbX = shift @port_data;
                                                                 $dbY = shift @port_data;
                                                                 my $loc = $dbX." ".$dbY;
                                                                 shift @port_data;
                                                                 $side = shift @port_data;
                                                                 $pin_data = $pin_data." ".$side;
                                                                 $pin_data = $pin_data." ".$loc;
                }elsif ( $data eq "LAYER" ) { $layer = shift @port_data; 
                                             $pin_data = $pin_data." ".$layer;
                                             shift @port_data;
                                             my $x1 = shift @port_data;
                                             my $y1 = shift @port_data;
                                             shift @port_data;
                                             shift @port_data;
                                             my $x2 = shift @port_data;
                                             my $y2 = shift @port_data;
                                             my $W = $x2 - $x1;
                                             my $H = $y2 - $y1;
                }else {}
              }#while
          $PORT_DATA_file_2{$pinName} = $pin_data;
          $line = ""; 
        } else { next;}
      }else{
        if ( $READ_PINS ==1 ) {chomp(); $_ =~ s/^\s+//; $line = $line." ".$_; }else {next;} 
      }
    }
   }#if pins
}#if pin given
#-------------------------------------------------------------------------------------------------------------------------------------#
if($comp_given == 1){
  if(/^COMPONENTS/ ... /^END COMPONENTS/){ 
   if ( $READ_COMPONENTS == 0 ) { next; } 
    else {
      if($_ =~ /^COMPONENTS/) { $noOfComponents_file_2 = (split(/\s+/, $_))[1];}
      if($_ =~ /^END COMPONENTS/) {}
      if($_ =~ /\;\s*$/){ $line = $line." ".$_;
      chomp;
      $line =~ s/^\s+//;
      if( $line =~ /-/){
        my ($instance, $cellref) = (split(/\s+/, $line))[1,2];
        my $comp_data = "";
        $instance =~ s/\\//g;
        push(@inst_list,$instance);
        @comp_placement_data = split(/\s+/, $line);
        while ( defined ($placement_data = shift @comp_placement_data) ) {
          if( $placement_data eq "PLACED" || $placement_data eq "FIXED" || $placement_data eq "UNPLACED") {
            $comp_data = $comp_data." ".$placement_data;
            shift @comp_placement_data;
            $location_x = shift @comp_placement_data;
            $location_y = shift @comp_placement_data;
            my $location = $location_x." ".$location_y;
            $comp_data = $comp_data." ".$location;
            shift @comp_placement_data;
            $orientation = shift @comp_placement_data;
            $comp_data = $comp_data." ".$orientation;
          }
        }
        $COMP_DATA_file_2{$instance} = $comp_data;
      }else{}
        $line = "";
      }else{
        chomp();
        $line = $line." ".$_;
      }
    }      
  }#if comp
}#if comp given
#----------------------------------------------------------------------------------------------------------------------#
if($net_given == 1){
if($_ =~ /^\s*\bNETS\b/){ $noOfNets_file_2 = (split(/\s+/,$_))[1];$reading_nets = 1;}
elsif($_ =~ /^\s*\bEND NETS\b/){$reading_nets = 0;}
if($reading_nets == 1 && $READ_NETS == 1){
  my $net_inst_data = "";
  my @net_routing_data = ();
  if($_ =~ /^\-/){
    $net_data_start = 1;
    @net_data = ();
    $netName = (split(/\s+/, $_))[1];
    push(@net_list,$netName);
  }
  if (( $net_data_start == 1) && ($_ =~ /\;\s*$/)) {
    my $abort_current_net = 0;
    my $process_routes = 0;
    push(@net_data, $_);
    my $num = @net_data;
    while ( defined ($line = shift @net_data) ) {
      if ($abort_current_net == 1 ) { last; }
      if ($process_routes == 1 ) {
        if ($line =~ /ROUTED/) { $route_type = R;
          $line =~ s/\+*\s+ROUTED\s+//;
          push(@net_routing_data,$line);
          @{$NET_ROUTING_DATA_HASH_file_2{$netName}} = @net_routing_data;
        }elsif ($line =~ /FIXED/) { $route_type = F; 
        }elsif ($line =~ /COVER/) { $route_type = C;
        }elsif ($line =~ /NEW/) { 
          $line =~ s/NEW\s+//;
          push(@net_routing_data,$line);
          @{$NET_ROUTING_DATA_HASH_file_2{$netName}} = @net_routing_data;
        }
      }else {
        my  @net_data_per_line = split(/\s+/, $line);
        while ( defined ($data = shift @net_data_per_line) ) {
          if ($process_routes == 0 ) {
            if ( $data eq "(" ) {
              $inst = shift @net_data_per_line;
              $inst =~ s/\\//g;
              $pin = shift @net_data_per_line;
              my $data_inst = $inst." ".$pin; 
              $net_inst_data = $net_inst_data." ".$data_inst;
              $NET_DATA_HASH_file_2{$netName} = $net_inst_data;
              shift @net_data_per_line;
            }elsif ( $data =~ /\+/ ) {
              if ( $READ_ROUTES == 0 ) { $abort_current_net = 1; last; }
              else {$process_routes = 1;} 
            }
          }else {
            if ($line =~ /ROUTED/) { $route_type = R; 
              $line =~ s/\+*\s+ROUTED\s+//;
              push(@net_routing_data,$line);
              @{$NET_ROUTING_DATA_HASH_file_2{$netName}} = @net_routing_data;
              last; 
            }elsif ($line =~ /FIXED/) { $route_type = F; last;
            }elsif ($line =~ /COVER/) { $route_type = C; last; 
            }elsif ($line =~ /NEW/) { 
              $line =~ s/NEW\s+//;
              push(@net_routing_data,$line);
              @{$NET_ROUTING_DATA_HASH_file_2{$netName}} = @net_routing_data;
              last; 
            }
          }
        }#while
      }# if processing connectivity
    }#while
  }else {
    push(@net_data,$_);
  }
}# if READ_NETS is equal to 1
}#if net given
#--------------------------------------------------------------------------------------------------------#
if($spnet_given == 1){
  if($_ =~ /^\s*SPECIALNETS/) { $noOfSPNets_file_2 = (split(/\s+/,$_))[1];$reading_spnets = 1;}
  elsif($_ =~ /^\s*END SPECIALNETS/) {$reading_spnets = 0;} 
  elsif($reading_spnets == 1 && $READ_SPNETS == 1) {
    my $spnet_inst_data = "";
    my @spnet_routing_data = ();
    if($_ =~ /^\-/){
      @spnet_data = ();
      $spnetName = (split(/\s+/, $_))[1];
      push(@spnet_data,$_);
      push(@spnet_list,$spnetName);
    }elsif ( $_ =~ /\;\s*$/ ) {
      my $abort_current_net = 0;
      my $process_routes = 0;
      push(@spnet_data, $_);
      my $num = @net_data;
      while ( defined ($line = shift @spnet_data) ) {
        if ($abort_current_net == 1 ) { last; }
        my  @net_data_per_line = split(/\s+/, $line);
        while ( defined ($data = shift @net_data_per_line) ) {
          if ($process_routes == 0 ) {
            if ( $data eq "(" ) {
              $inst = shift @net_data_per_line;
              $inst =~ s/\\//g;
              $pin = shift @net_data_per_line;
              my $data_inst = $inst." ".$pin;
              $spnet_inst_data = $spnet_inst_data." ".$data_inst;
              $SPNET_DATA_HASH_file_2{$spnetName} = $spnet_inst_data;
              shift @net_data_per_line;
            }elsif ( $data =~ /\+/ ) {
              if ( $READ_SPROUTES == 0 ) { $abort_current_net = 1; last; }
              else {$process_routes = 1;}
            }
          }# if connectivity
          else {
            if ($line =~ /ROUTED/) { $route_type = R;
              $line =~ s/\+*\s+ROUTED\s+//;
              push(@spnet_routing_data,$line);
              @{$SPNET_ROUTING_DATA_HASH_file_2{$spnetName}} = @spnet_routing_data;
              last;
            }elsif ($line =~ /FIXED/) { $route_type = F; 
              $line =~ s/\+*\s+FIXED\s+//;
              last; 
            }elsif ($line =~ /COVER/) { $route_type = C; last; 
            }elsif ($line =~ /NEW/) {
              $line =~ s/NEW\s+//;
              push(@spnet_routing_data,$line);
              @{$SPNET_ROUTING_DATA_HASH_file_2{$spnetName}} = @spnet_routing_data;
              last;
            }elsif ($line =~ /USE/) {
              $line =~ s/\+*\s+USE\s+//;
              last; 
            }
          }#process routing
        }#while
      }#while
    }else { 
      push(@spnet_data,$_);
    }
  }#if reading spnets
}#if spnet given
#-----------------------------------------------------------------------------------------------------------------------#
if($group_given == 1){
if($_ =~ /^\s*\bGROUPS\b/){$noOfGroups_of_file_2 = (split(/\s+/,$_))[1];$reading_groups = 1;} 
elsif($_ =~ /^\s*\bEND GROUPS\b/){$reading_groups = 0;}
  elsif($reading_groups == 1 && $READ_GROUPS == 1){
    my @grp_inst_data = ();
    if($_ =~/^\-/){
      @group_data = ();
      push (@group_data,$_);
      $grpName = (split(/\s+/,$_))[1];
      push(@grpName_list,$grpName);
    }elsif($_ =~ /\;\s*$/){
      my $abort_current_grp = 0;
      my $process_grp = 0;
      push (@group_data,$_);
      while (defined ($line = shift @group_data)){
        if ($abort_current_grp == 1 ) { last; }
        my @grp_data_per_line = split(/\s+/, $line);
        while ( defined ($data = shift @grp_data_per_line) ) { 
            if($process_grp == 0){
              if($data =~ /\-/){next;}
              elsif($data eq $grpName){next;}
              elsif($data =~ /\+/){
                if($READ_REGION == 0){$abort_current_grp = 1;last;}
                else {$process_grp = 1;}
              }else {
                push (@grp_inst_data,$data);
                @{$GROUP_INST_HASH_of_file_2{$grpName}} = @grp_inst_data;
              }
            }else {
              if($line =~ /REGION/){my $region_type = (split(/\s+/,$line))[2];
                                    $GROUP_REGION_HASH_of_file_2{$grpName} = $region_type; 
                                    last;
              }
            }
        }#while
      }#while
    }else {
      push (@group_data,$_);
    }
  }
}#if group given
#-----------------------------------------------------------------------------------------------------------------------#
if($blockage_given == 1){
if($_ =~ /^\s*\bBLOCKAGES\b/){$noOfBlockages_of_file_2 = (split(/\s+/,$_))[1];
                              $block_line = "";$blockage_count_no = 0;
                              $reading_blkgs = 1;
}elsif($_ =~ /^\s*\bEND BLOCKAGES\b/){$reading_blkgs = 0;}
elsif ($reading_blkgs == 1 && $READ_BLKGS == 1 ) {
chomp();
  if ($_ =~ /^$/ || $_ =~ /^#/) {next;}
    $block_line = $block_line." ".$_;
    if($_ =~ /\;\s*$/){
      my $routing_blockage_found = 0;
      my $placement_blockage_found = 0;
      my @blockages_string = ();
      my @blkg_data = split(/\s+/,$block_line);
      my $BlkgName;
      while ( defined ($data = shift @blkg_data) ) {
        if ( $data eq "-" ){ $BlkgName = "Blkg".$blockage_count_no; @rect = (); 
        }elsif ( $data eq "LAYER" ) { my $layerName = shift @blkg_data;
          $routing_blockage_found = 1;
          $BLOCKAGE_LAYER_HASH_OF_FILE_2{$BlkgName} = $layerName;
        }elsif ( $data eq "PLACEMENT" ) { 
          $placement_blockage_found = 1;
        }elsif ( $data eq "RECT" ) { 
          shift @blkg_data; 
          my $x1 = shift @blkg_data;
          my $y1 = shift @blkg_data;
          shift @blkg_data;
          shift @blkg_data;
          my $x2 = shift @blkg_data;
          my $y2 = shift @blkg_data;
          push (@blockages_string,$x1,$y1,$x2,$y2);
          @{$BLOCKAGE_RECT_HASH_OF_FILE_2{$BlkgName}} = @blockages_string; 
        }else{}
      }#while
    if ($routing_blockage_found == 1) {} else {}
      $blockage_count_no++;
      $block_line = "";
    }elsif ($reading_blkgs == 1 && $READ_BLKGS == 0 ) {next;}
    else{next;}
}#elsif
}#if blockage_given
}#else
}#while
close(READ_DEF_FILE_2);
}#if file 2 given
#-----------------------------------------------------------------------------------------------------------------------#
open(WRITE,">data.txt");
print WRITE "filename		$fileName_1				$fileName_2\n"if($summary == 1 || $detailed == 1);
if($pin_given == 1){
  my $dir_1 = "";
  my $signal_1 = "";
  my $layerName_1 = "";
  my $orient_1 = "";
  my $xloc_1 = "";
  my $yloc_1 = "";
  my $dir_2 = "";
  my $signal_2 = "";
  my $layerName_2 = "";
  my $orient_2 = "";
  my $xloc_2 = "";
  my $yloc_2 = "";
  my $matched_pinCnt = 0;
  my $unmatched_pinCnt = 0;
  print WRITE "num of pins        	$noOfPins_file_1					$noOfPins_file_2\n"if($summary == 1 || $detailed == 1); 
  foreach my $pin_Name (keys %PORT_DATA_file_1){
    my $port_data_1 = $PORT_DATA_file_1{$pin_Name};
    my ($dir1,$signal1,$layerName1,$orient1,$xloc1,$yloc1) = (split(/\s+/,$port_data_1))[1,2,3,4,5,6];
    if(exists $PORT_DATA_file_2{$pin_Name}){
      my $port_data_2 = $PORT_DATA_file_2{$pin_Name};
      my ($dir2,$signal2,$layerName2,$orient2,$xloc2,$yloc2) = (split(/\s+/,$port_data_2))[1,2,3,4,5,6];
      if($dir1 eq $dir2 && $signal1 eq $signal2 && $layerName1 eq $layerName2 && $xloc1 == $xloc2 && $yloc1 == $yloc2){
        $matched_pinCnt++;
      }else {
         $unmatched_pinCnt++;
         push(@unmatched_pin,$pin_Name);
      }
    }
  }#foreach
      print WRITE "matched pin		$matched_pinCnt					$matched_pinCnt\n" if($summary == 1 || $detailed == 1);
      print WRITE "unmatched pin		$unmatched_pinCnt					$unmatched_pinCnt\n" if($summary == 1 || $detailed == 1);
  foreach my $pin (@unmatched_pin){
    if(exists $PORT_DATA_file_1{$pin}){
      my $port_data_1 = $PORT_DATA_file_1{$pin};
      ($dir_1,$signal_1,$layerName_1,$orient_1,$xloc_1,$yloc_1) = (split(/\s+/,$port_data_1))[1,2,3,4,5,6];
    }
    if(exists $PORT_DATA_file_2{$pin}){
      my $port_data_2 = $PORT_DATA_file_2{$pin};
      ($dir_2,$signal_2,$layerName_2,$orient_2,$xloc_2,$yloc_2) = (split(/\s+/,$port_data_2))[1,2,3,4,5,6];
    }
    if($dir_1 ne $dir_2){print WRITE "	$pin 	$dir_1					$dir_2\n"if($detailed == 1);}
    if((($xloc_1 != $xloc_2) ||($yloc_1 != $yloc_2)) && ($orient_1 ne $orient_2)){print WRITE "	$pin 	$orient_1					$orient_2\n"if($detailed == 1);}
    if((($xloc_1 != $xloc_2) ||($yloc_1 != $yloc_2)) && ($orient_1 eq $orient_2)){my $x_diff = abs ($xloc_2 - $xloc_1);
                                                                                  my $y_diff = abs ($yloc_2 - $yloc_1);
                                                                                  print WRITE "	$pin 	$xloc_1,$yloc_1				$xloc_2,$yloc_2	diff $x_diff,$y_diff\n"if($detailed == 1);}
    if($layerName_1 ne $layerName_2){print WRITE "	$pin 	$layerName_1					$layerName_2\n"if($detailed == 1);}
  }
  print WRITE "non corresponding pin\n"if($summary == 1 || $detailed == 1);
  foreach my $pin (@pinName_list){
    if(!exists $PORT_DATA_file_2{$pin}){
      print WRITE "	$pin x\n"if($summary == 1 || $detailed == 1);
    }elsif(!exists $PORT_DATA_file_1{$pin}){
      print WRITE "								$pin x\n"if($summary == 1 || $detailed == 1);
    }else {print WRITE "		none\n"if($summary == 1 || $detailed == 1);}
  }
}#if pin given
#----------------------------------------------------------------------------------------------------------------------------------------------#
if($comp_given == 1){
  my $status_1 = "";
  my $status_2 = "";
  my $location_x1 = "";
  my $location_x2 = "";
  my $location_y1 = "";
  my $location_y2 = "";
  my $orientation_1 = "";
  my $orientation_2 = "";
  my $matched_instcnt = 0;
  my $unmatched_instcnt = 0;
  foreach my $inst (keys %COMP_DATA_file_1){
    my $comp_data1 = $COMP_DATA_file_1{$inst};
    my ($status1,$locationx1,$locationy1,$orientation1) = (split(/\s+/,$comp_data1))[1,2,3,4];
    if(exists $COMP_DATA_file_2{$inst}){
      my $comp_data2 = $COMP_DATA_file_2{$inst};
      my ($status2,$locationx2,$locationy2,$orientation2) = (split(/\s+/,$comp_data2))[1,2,3,4];
      if($status1 eq $status2 && $locationx1 == $locationx2 && $locationy1 == $locationy2 && $orientation1 eq $orientation2){
        $matched_instcnt++;
      }else{
        $unmatched_instcnt++;
        push(@unmatched_inst,$inst); 
      }    
    }
  }#foreach
     print WRITE "num of inst 		$noOfComponents_file_1					$noOfComponents_file_2\n"if($summary == 1 || $detailed == 1);
     print WRITE "matched inst 		$matched_instcnt 					$matched_instcnt\n"if($summary == 1 || $detailed == 1);
     print WRITE "unmatched inst 		$unmatched_instcnt 					$unmatched_instcnt\n"if($summary == 1 || $detailed == 1);
  foreach my $inst (@unmatched_inst){
    if(exists $COMP_DATA_file_1{$inst}){
      my $comp_data_1 = $COMP_DATA_file_1{$inst};
      ($status_1,$location_x1,$location_y1,$orientation_1) = (split(/\s+/,$comp_data_1))[1,2,3,4];
    }
    if(exists $COMP_DATA_file_2{$inst}){
      my $comp_data_2 = $COMP_DATA_file_2{$inst};
      ($status_2,$location_x2,$location_y2,$orientation_2) = (split(/\s+/,$comp_data_2))[1,2,3,4];
    }
    if($status_1 ne $status_2){print WRITE "		$inst 	$status_1			$status_2\n"if($detailed == 1);}
    if((($location_x1 != $location_x2) || ($location_y1 != $location_y2)) && ($orientation_1 ne $orientation_2)){print WRITE "		$inst $orientation_1			$orientation_2\n"if($detailed == 1);} 
    if((($location_x1 != $location_x2) || ($location_y1 != $location_y2)) && ($orientation_1 eq $orientation_2)){my $x_diff = abs ($location_x2 - $location_x1);
                                                                                                                 my $y_diff = abs ($location_y2 - $location_y1);
                                                                                                                 print WRITE " 		$inst      $location_x1, $location_y1	$location_x2,$location_y2 diff $x_diff ,$y_diff\n"if($detailed == 1);}
  } 
  print WRITE "non corresponding inst\n"if($summary == 1 || $detailed == 1);
  foreach my $inst (@inst_list){
    if(!exists $COMP_DATA_file_2{$inst}){
      print WRITE "	$inst x\n"if($summary == 1 || $detailed == 1);
    }elsif(!exists $COMP_DATA_file_1{$inst}){
      print WRITE "								$inst x\n"if($summary == 1 || $detailed == 1);
    }else {print WRITE "	none\n"if($summary == 1 || $detailed == 1);}
  } 
}#if comp given
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
if( $net_given == 1){
  my $netmatched_cnt = 0;
  my $netunmatched_cnt = 0;
  my @non_corresponding_net = ();
  my $number_of_non_corresponding_net = "";
  foreach my $net (keys %NET_DATA_HASH_file_1){
    my $inst_list_1 = $NET_DATA_HASH_file_1{$net};
    my @instList_1 = (split(/\s+/,$inst_list_1)); 
    shift @instList_1;
    if(exists $NET_DATA_HASH_file_2{$net}){
      my $inst_list_2 = $NET_DATA_HASH_file_2{$net};
      my @instList_2 = (split(/\s+/,$inst_list_2));
      shift @instList_2;
      my $instname_file_1 = "";
      my $instname_file_2 = "";     
      my $pinname_file_1 = "";
      my $pinname_file_2 = "";
      for(my $i =0; $i<=$#instList_1; $i=$i+2){
        $instname_file_1 = $instList_1[$i]; 
        $pinname_file_1 = $instList_1[$i+1]; 
        $instname_file_2 = $instList_2[$i]; 
        $pinname_file_2 = $instList_2[$i+1]; 
      }#for
      if(($instname_file_1 eq $instname_file_2) && ($pinname_file_1 eq $pinname_file_2)){
        $matched_net{$net} = 1;
      }else {
        $unmatched_net{$net} = 1;
        if($instname_file_1 ne $instname_file_2){
          my $instName = $instname_file_1." ".$instname_file_2;
          $unmatched_inst_of_net{$instName} = $net;
        }elsif ($pinname_file_1 ne $pinname_file_2){
          my $pinName = $pinname_file_1." ".$pinname_file_2;
          $unmatched_pin_of_net{$pinName} = $net;
        }
      }
    }
  }#foreach 
#---------------------------------------------------------after-------------------------------------------------------------------------#
foreach my $net (keys %NET_DATA_HASH_file_1){
  if(exists $NET_ROUTING_DATA_HASH_file_1{$net}){
    my @routing_value_file_1 = @{$NET_ROUTING_DATA_HASH_file_1{$net}};
    for(my $i=0; $i <=$#routing_value_file_1; $i++){
      my $new_routing_value_file_1 = $routing_value_file_1[$i];
      my $routeLayer = (split(/\s+/,$new_routing_value_file_1))[0];
      my ($co_ord_of_file_1,$via_of_file_1) = &convert_co_ord_for_nets_routing($new_routing_value_file_1);
      $NET_ROUTING_WITH_LAYER_NAME_OF_FILE_1{$net}{$co_ord_of_file_1} = $routeLayer;
      $NET_ROUTING_WITH_VIA_NAME_OF_FILE_1{$net}{$co_ord_of_file_1} = $via_of_file_1;
    }#for
  }#if exists
}#foreach
#---------------------------------------------------------------------------------------------------------------------------------------#
foreach my $net (keys %NET_DATA_HASH_file_2){
  if(exists $NET_ROUTING_DATA_HASH_file_2{$net}){
    my @routing_value_file_2 = @{$NET_ROUTING_DATA_HASH_file_2{$net}};
    for(my $i=0; $i <=$#routing_value_file_2; $i++){
      my $new_routing_value_file_2 = $routing_value_file_2[$i];
      my $routeLayer = (split(/\s+/,$new_routing_value_file_2))[0];
      my ($co_ord_of_file_2,$via_of_file_2) = &convert_co_ord_for_nets_routing($new_routing_value_file_2);
      $NET_ROUTING_WITH_LAYER_NAME_OF_FILE_2{$net}{$co_ord_of_file_2} = $routeLayer;
      $NET_ROUTING_WITH_VIA_NAME_OF_FILE_2{$net}{$co_ord_of_file_2} = $via_of_file_2;
    }#for
  }#if exists
}#foreach 
#---------------------------------------------------------------------------------------------------------------------------------------#
foreach my $net (keys %NET_ROUTING_WITH_LAYER_NAME_OF_FILE_1){
  if(exists $NET_ROUTING_WITH_LAYER_NAME_OF_FILE_2{$net}){ 
    foreach my $co_ord (keys %{$NET_ROUTING_WITH_LAYER_NAME_OF_FILE_2{$net}}){
      my ($layerName_of_file_2) = $NET_ROUTING_WITH_LAYER_NAME_OF_FILE_2{$net}{$co_ord}; 
      my ($viaName_of_file_2) = $NET_ROUTING_WITH_VIA_NAME_OF_FILE_2{$net}{$co_ord}; 
      if(exists $NET_ROUTING_WITH_LAYER_NAME_OF_FILE_1{$net}{$co_ord}){
        my ($layerName_of_file_1) = $NET_ROUTING_WITH_LAYER_NAME_OF_FILE_1{$net}{$co_ord};
        my ($viaName_of_file_1) = $NET_ROUTING_WITH_VIA_NAME_OF_FILE_1{$net}{$co_ord};
        if(($layerName_of_file_1 eq $layerName_of_file_2) && ($viaName_of_file_1 eq $viaName_of_file_2)){
          $matched_net{$net} = 1; 
        }else{
          $unmatched_net{$net} = 1;
          if ($layerName_of_file_1 ne $layerName_of_file_2){
            my $layerName = $layerName_of_file_1." ".$layerName_of_file_2;
            $unmatched_layer_of_net{$layerName} = $net; 
          }
          if ($viaName_of_file_1 ne $viaName_of_file_2){
            my $viaName = $viaName_of_file_1." ".$viaName_of_file_2;
            $unmatched_via_of_net{$viaName} = $net; 
          }
        }
      }else {
        $unmatched_net{$net} = 1;
        $unmatched_routing_co_ord_net{$co_ord} = $net;
      }
    }
  }   
}#foreach
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------#
foreach my $net (keys %matched_net){
  if(!exists $unmatched_net{$net}) {
    $netmatched_cnt++;
  }
}
foreach my $net (keys %unmatched_net){
  $netunmatched_cnt++;
}
      print WRITE "noOfNets 	 	$noOfNets_file_1				$noOfNets_file_2\n"if($summary == 1 || $detailed == 1);
      print WRITE "matched net 		$netmatched_cnt				$netmatched_cnt\n"if($summary == 1 || $detailed == 1);
      print WRITE "unmatched net		$netunmatched_cnt				$netunmatched_cnt\n"if($summary == 1 || $detailed == 1);
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------#
foreach my $instName (keys %unmatched_inst_of_net){
  my $net = $unmatched_inst_of_net{$instName};
  my ($instName_of_file_1,$instName_of_file_2) = (split(/\s+/,$instName))[0,1];
  print WRITE " 	$net	    $instName_of_file_1				$instName_of_file_2\n"if($detailed == 1);
}#foreach
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------#
foreach my $pinName (keys %unmatched_pin_of_net){
  my $net = $unmatched_pin_of_net{$pinName};
  my ($pinName_of_file_1,$pinName_of_file_2) = (split(/\s+/,$pinName))[0,1];
  print WRITE " 	$net		$pinName_of_file_1				$pinName_of_file_2\n"if($detailed == 1);	
}#foreach
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------#
foreach my $co_ord_of_file_2 (keys %unmatched_routing_co_ord_net){
  my $net = $unmatched_routing_co_ord_net{$co_ord_of_file_2};  
  my $layerName_of_file_2 = $NET_ROUTING_WITH_LAYER_NAME_OF_FILE_2{$net}{$co_ord_of_file_2};
  my $viaName_of_file_2 = $NET_ROUTING_WITH_VIA_NAME_OF_FILE_2{$net}{$co_ord_of_file_2};
  if(exists $NET_ROUTING_WITH_LAYER_NAME_OF_FILE_1{$net}){
    foreach my $co_ord_of_file_1 (keys %{$NET_ROUTING_WITH_LAYER_NAME_OF_FILE_1{$net}}){
      if(!exists $NET_ROUTING_WITH_LAYER_NAME_OF_FILE_2{$net}{$co_ord_of_file_1}){
        my $layerName_of_file_1 = $NET_ROUTING_WITH_LAYER_NAME_OF_FILE_1{$net}{$co_ord_of_file_1};
        my $viaName_of_file_1 = $NET_ROUTING_WITH_VIA_NAME_OF_FILE_1{$net}{$co_ord_of_file_1};
        if(($layerName_of_file_1 eq $layerName_of_file_2) && ($viaName_of_file_1 eq $viaName_of_file_2)){
          my ($llx_1,$lly_1,$urx_1,$ury_1) = (split(/\s+/,$co_ord_of_file_1))[0,1,2,3];
          my ($llx_2,$lly_2,$urx_2,$ury_2) = (split(/\s+/,$co_ord_of_file_2))[0,1,2,3];
          if($llx_1 != $llx_2){
            my $diff = abs ($llx_2 - $llx_1);
            print WRITE "	$net 	     $llx_1 				$llx_2 			$diff\n"if($detailed == 1);
          }elsif($urx_1 != $urx_2){
            my $diff = abs ($urx_2 - $urx_1);
            print WRITE "	$net 	     $urx_1 				$urx_2 			$diff\n"if($detailed == 1);
          }elsif($lly_1 != $lly_2){
            my $diff = abs ($lly_2 - $lly_1);
            print WRITE "	$net         $lly_1 				$lly_2 			$diff\n"if($detailed == 1);
          }elsif($ury_1 != $ury_2){
            my $diff = abs ($ury_2 - $ury_1);
            print WRITE "	$net	        $ury_1 				$ury_2 			$diff\n"if($detailed == 1);
          }
        }
      }
    }
  }
}#foreach
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------#
foreach my $layerName (keys %unmatched_layer_of_net){
  my $net = $unmatched_layer_of_net{$layerName}; 
  my ($layerName_of_file_1,$layerName_of_file_2) = (split(/\s+/,$layerName))[0,1];
  print WRITE "	$net		$layerName_of_file_1				$layerName_of_file_2\n"if($detailed == 1);
}#foreach 
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------#
foreach my $viaName (keys %unmatched_via_of_net){
  my $net = $unmatched_via_of_net{$viaName};
  my ($viaName_of_file_1,$viaName_of_file_2) = (split(/\s+/,$viaName))[0,1];
  print WRITE "	$net	$viaName_of_file_1				$viaName_of_file_2\n"if($detailed == 1); 
}#foreach
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------#
print WRITE "non corresponding net\n"if($summary == 1 || $detailed == 1);
foreach  my $net (@net_list){
  if(!exists $NET_DATA_HASH_file_1{$net}){
     print WRITE " 							$net 1x\n"if($summary == 1 || $detailed == 1);
     push (@non_corresponding_net,$net);
  }elsif(!exists $NET_DATA_HASH_file_2{$net}){
     push (@non_corresponding_net,$net);
     print WRITE " 	$net 2x\n"if($summary == 1 || $detailed == 1);
  }
}#foreach
$number_of_non_corresponding_net = @non_corresponding_net;
if($number_of_non_corresponding_net == 0){
   print WRITE "			none\n"if($summary == 1 || $detailed == 1);
}
}#if net given
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------#
if($spnet_given == 1){
  my $spnetmatched_cnt = 0;
  my $spnetunmatched_cnt = 0;
  my @non_corresponding_spnet = ();
  my $number_of_non_corresponding_spnet = "";
  foreach my $net (keys %SPNET_DATA_HASH_file_1){
    my $inst_list_1 = $SPNET_DATA_HASH_file_1{$net};
    my @instList_1 = (split(/\s+/,$inst_list_1)); 
    shift @instList_1;
    if(exists $SPNET_DATA_HASH_file_2{$net}){
      my $inst_list_2 = $SPNET_DATA_HASH_file_2{$net};
      my @instList_2 = (split(/\s+/,$inst_list_2));
      shift @instList_2;
      my $instname_file_1 = "";
      my $instname_file_2 = "";     
      my $pinname_file_1 = "";
      my $pinname_file_2 = "";
      for(my $i =0; $i<=$#instList_1; $i=$i+2){
        $instname_file_1 = $instList_1[$i]; 
        $pinname_file_1 = $instList_1[$i+1]; 
        $instname_file_2 = $instList_2[$i]; 
        $pinname_file_2 = $instList_2[$i+1]; 
      }#for
      if(($instname_file_1 eq $instname_file_2) && ($pinname_file_1 eq $pinname_file_2)){
        $matched_spnet{$net} = 1;
      }else {
        $unmatched_spnet{$net} = 1;
      }
    }
  }#foreach 
#--------------------------------------------------------creating hashes for special net routing------------------------------#
foreach my $net (keys %SPNET_DATA_HASH_file_1){
  if(exists $SPNET_ROUTING_DATA_HASH_file_1{$net}){
    my @routing_value_of_file_1 = @{$SPNET_ROUTING_DATA_HASH_file_1{$net}};
    for(my $i =0; $i <= $#routing_value_of_file_1; $i++){
      my $new_routing_value_of_file_1 = "";
      $new_routing_value_of_file_1 =  $routing_value_of_file_1[$i];
      $new_routing_value_of_file_1 =~ s/\+//; 
      my @routed_data = (split(/\s+/,$new_routing_value_of_file_1));
      my $routeLayer = shift @routed_data;
      my $width = shift @routed_data;
      my $shape = shift @routed_data;
      my $shapeName = shift @routed_data;
      $new_routing_value_of_file_1 =~ s/$routeLayer//; 
      $new_routing_value_of_file_1 =~ s/$width//; 
      $new_routing_value_of_file_1 =~ s/\s+$shape//; 
      $new_routing_value_of_file_1 =~ s/\s+$shapeName\s+//; 
      my ($co_ord_of_file_1,$via_of_file_1) = &convert_co_ord_for_nets_routing($new_routing_value_of_file_1);
      $SPNET_ROUTING_WITH_LAYER_NAME_OF_FILE_1{$net}{$co_ord_of_file_1} = $routeLayer; 
      $SPNET_ROUTING_WITH_WIDTH_NAME_OF_FILE_1{$net}{$co_ord_of_file_1} = $width; 
      $SPNET_ROUTING_WITH_SHAPE_NAME_OF_FILE_1{$net}{$co_ord_of_file_1} = $shapeName; 
      $SPNET_ROUTING_WITH_VIA_NAME_OF_FILE_1{$net}{$co_ord_of_file_1} = $via_of_file_1;
    }#for
  }#if exists
}#foreach
#------------------------------------------------------------------------------------------------------------------------------#
foreach my $net (keys %SPNET_DATA_HASH_file_2){
  if(exists $SPNET_ROUTING_DATA_HASH_file_2{$net}){
    my @routing_value_of_file_2 = @{$SPNET_ROUTING_DATA_HASH_file_2{$net}};
    for (my $i =0; $i <= $#routing_value_of_file_2;$i++){
      my $new_routing_value_of_file_2 = "";
      $new_routing_value_of_file_2 = $routing_value_of_file_2[$i];
      $new_routing_value_of_file_2 =~ s/\+//; 
      my @routed_data = (split(/\s+/,$new_routing_value_of_file_2)); 
      my $routeLayer = shift @routed_data;
      my $width = shift @routed_data;
      my $shape = shift @routed_data;
      my $shapeName = shift @routed_data;
      $new_routing_value_of_file_2 =~ s/$routeLayer//;
      $new_routing_value_of_file_2 =~ s/$width//;
      $new_routing_value_of_file_2 =~ s/\s+$shape//;
      $new_routing_value_of_file_2 =~ s/\s+$shapeName\s+//;
      my ($co_ord_of_file_2,$via_of_file_2) = &convert_co_ord_for_nets_routing($new_routing_value_of_file_2);
      $SPNET_ROUTING_WITH_LAYER_NAME_OF_FILE_2{$net}{$co_ord_of_file_2} = $routeLayer; 
      $SPNET_ROUTING_WITH_WIDTH_NAME_OF_FILE_2{$net}{$co_ord_of_file_2} = $width; 
      $SPNET_ROUTING_WITH_SHAPE_NAME_OF_FILE_2{$net}{$co_ord_of_file_2} = $shapeName; 
      $SPNET_ROUTING_WITH_VIA_NAME_OF_FILE_2{$net}{$co_ord_of_file_2} = $via_of_file_2; 
    }#for
  }#if exists
}#foreach
#------------------------------------------------------------------------------------------------------------------------------#
foreach my $net (keys %SPNET_ROUTING_WITH_LAYER_NAME_OF_FILE_1){
  if(exists $SPNET_ROUTING_WITH_LAYER_NAME_OF_FILE_2{$net}){
   foreach my $co_ord (keys %{$SPNET_ROUTING_WITH_LAYER_NAME_OF_FILE_2{$net}}){
     my ($layerName_of_file_2) = $SPNET_ROUTING_WITH_LAYER_NAME_OF_FILE_2{$net}{$co_ord};
     my ($viaName_of_file_2) = $SPNET_ROUTING_WITH_VIA_NAME_OF_FILE_2{$net}{$co_ord};   
     my ($width_of_file_2) = $SPNET_ROUTING_WITH_WIDTH_NAME_OF_FILE_2{$net}{$co_ord};   
     my ($shapeName_of_file_2) = $SPNET_ROUTING_WITH_SHAPE_NAME_OF_FILE_2{$net}{$co_ord};   
     if(exists $SPNET_ROUTING_WITH_LAYER_NAME_OF_FILE_1{$net}{$co_ord}){
       my ($layerName_of_file_1) = $SPNET_ROUTING_WITH_LAYER_NAME_OF_FILE_1{$net}{$co_ord};
       my ($viaName_of_file_1) = $SPNET_ROUTING_WITH_VIA_NAME_OF_FILE_1{$net}{$co_ord}; 
       my ($width_of_file_1) = $SPNET_ROUTING_WITH_WIDTH_NAME_OF_FILE_1{$net}{$co_ord}; 
       my ($shapeName_of_file_1) = $SPNET_ROUTING_WITH_SHAPE_NAME_OF_FILE_1{$net}{$co_ord}; 
       if(($layerName_of_file_1 eq $layerName_of_file_2) && ($viaName_of_file_1 eq $viaName_of_file_2) && ($width_of_file_1 eq $width_of_file_2) && ($shapeName_of_file_1 eq $shapeName_of_file_2)){ 
         $matched_spnet{$net} = 1;
       }else {
          $unmatcehd_spnet{$net} = 1;
          if($layerName_of_file_1 ne $layerName_of_file_2){
            my $layerName = $layerName_of_file_1." ".$layerName_of_file_2; 
            $unmatched_layer_of_spnet{$layerName} = $net;
          }
          if($viaName_of_file_1 ne $viaName_of_file_2){
            my $viaName = $viaName_of_file_1." ".$viaName_of_file_2;
            $unmatched_via_of_spnet{$viaName} = $net;
          }
          if($width_of_file_1 ne $width_of_file_2){
            my $width = $width_of_file_1." ".$width_of_file_2;
            $unmatched_width_of_spnet{$width} = $net;
          }
          if($shapeName_of_file_1 ne $shapeName_of_file_2){
            my $shapeName = $shapeName_of_file_1." ".$shapeName_of_file_2;
            $unmatched_shapeName_of_spnet{$shapeName} = $net;
          }
       }
     }else{
       $unmatched_spnet{$net} = 1;
       $unmatched_routing_co_ord_spnet{$co_ord} = $net;
     } 
   }#foreach  
  } 
}#foreach
#--------------------------------------------------------------------------------------------------------------------------#
foreach my $net (keys %matched_spnet){
  if(!exists $unmatched_spnet{$net}){
    $spnetmatched_cnt++;
  }
}#foreach
foreach my $net (keys %unmatched_spnet){
  $spnetunmatched_cnt++;
}#foreach
     print WRITE "noOfSPNets		$noOfSPNets_file_1				$noOfSPNets_file_2\n"if($summary == 1 || $detailed == 1);
     print WRITE "matched spnet		$spnetmatched_cnt				$spnetmatched_cnt\n"if($summary == 1 || $detailed == 1);
     print WRITE "unmatched spnet 	      $spnetunmatched_cnt				$spnetunmatched_cnt\n"if($summary == 1 || $detailed == 1);
#------------------------------------------------------------------------------------------------------------------------------#
foreach my $instName (keys %unmatched_inst_of_spnet){
  my $net = $unmatched_inst_of_spnet{$instName};
  my ($instName_of_file_1,$instName_of_file_2) = (split(/\s+/,$instName))[0,1];
  print WRITE "		$net	    $instName_of_file_1				$instName_of_file_2\n"if($detailed == 1);
}#foreach 
#------------------------------------------------------------------------------------------------------------------------------#
foreach my $pinName (keys %unmatched_pin_of_spnet){
  my $net = $unmatched_pin_of_spnet{$pinName};
  my ($pinName_of_file_1,$pinName_of_file_2) = (split(/\s+/,$pinName))[0,1];
  print WRITE "		$net	        $pinName_of_file_1				$pinName_of_file_2\n"if($detailed == 1);				
}#foreach
#------------------------------------------------------------------------------------------------------------------------------#
foreach my $co_ord_of_file_2 (keys %unmatched_routing_co_ord_spnet){
  my $net = $unmatched_routing_co_ord_spnet{$co_ord_of_file_2};
  my $layerName_of_file_2 = $SPNET_ROUTING_WITH_LAYER_NAME_OF_FILE_2{$net}{$co_ord_of_file_2};
  my $viaName_of_file_2 = $SPNET_ROUTING_WITH_VIA_NAME_OF_FILE_2{$net}{$co_ord_of_file_2};
  my $width_of_file_2 = $SPNET_ROUTING_WITH_WIDTH_NAME_OF_FILE_2{$net}{$co_ord_of_file_2};
  my $shapeName_of_file_2 = $SPNET_ROUTING_WITH_SHAPE_NAME_OF_FILE_2{$net}{$co_ord_of_file_2};
  if(exists $SPNET_ROUTING_WITH_LAYER_NAME_OF_FILE_1{$net}){
    foreach my $co_ord_of_file_1 (keys %{$SPNET_ROUTING_WITH_LAYER_NAME_OF_FILE_1{$net}}){
      if(!exists $SPNET_ROUTING_WITH_LAYER_NAME_OF_FILE_2{$net}{$co_ord_of_file_1}){
        my $layerName_of_file_1 = $SPNET_ROUTING_WITH_LAYER_NAME_OF_FILE_1{$net}{$co_ord_of_file_1}; 
        my $viaName_of_file_1 = $SPNET_ROUTING_WITH_VIA_NAME_OF_FILE_1{$net}{$co_ord_of_file_1};
        my $width_of_file_1 = $SPNET_ROUTING_WITH_WIDTH_NAME_OF_FILE_1{$net}{$co_ord_of_file_1}; 
        my $shapeName_of_file_1 = $SPNET_ROUTING_WITH_SHAPE_NAME_OF_FILE_1{$net}{$co_ord_of_file_1};
        if(($layerName_of_file_1 eq $layerName_of_file_2) && ($viaName_of_file_1 eq $viaName_of_file_2) && ($width_of_file_1 eq $width_of_file_2) && ($shapeName_of_file_1 eq $shapeName_of_file_2)){
          my ($llx_1,$lly_1,$urx_1,$ury_1) = (split(/\s+/,$co_ord_of_file_1))[0,1,2,3];
          my ($llx_2,$lly_2,$urx_2,$ury_2) = (split(/\s+/,$co_ord_of_file_2))[0,1,2,3];
          if($llx_1 != $llx_2){
            my $diff = abs ($llx_2 - $llx_1);
            print WRITE "	$net		$llx_1				$llx_2			$diff\n"if($detailed == 1);
          }elsif($urx_1 != $urx_2){
            my $diff = abs ($urx_2 - $urx_1);
            print WRITE "	$net		$urx_1				$urx_2			$diff\n"if($detailed == 1);
          }elsif($lly_1 != $lly_2){
            my $diff = abs ($lly_2 -$lly_1);
            print WRITE "	$net		$lly_1				$lly_2			$diff\n"if($detailed == 1);
          }elsif($ury_1 != $ury_2){
            my $diff = abs ($ury_2 - $ury_1);
            print WRITE "	$net		$ury_1				$ury_2			$diff\n"if($detailed == 1);
          }   
        }#if equal   
      }#if not exists
    }#foreach
  }#if exists 
}#foreach
#----------------------------------------------------------------------------------------------------------------------------------------------#
foreach my $layerName (keys %unmatched_layer_of_spnet){
  my $net = $unmatched_layer_of_spnet{$layerName};
  my ($layerName_of_file_1,$layerName_of_file_2) = (split(/\s+/,$layerName))[0,1];
  print WRITE "	$net		$layerName_of_file_1				$layerName_of_file_2\n"if($detailed == 1); 
}#foreach 
#----------------------------------------------------------------------------------------------------------------------------------------------#
foreach my $viaName (keys %unmatched_via_of_spnet){
  my $net = $unmatched_via_of_spnet{$viaName};
  my ($viaName_of_file_1,$viaName_of_file_2) = (split(/\s+/,$viaName))[0,1]; 
  print WRITE "	$net 		$viaName_of_file_1				$viaName_of_file_2\n"if($detailed == 1);
}#foreach
#----------------------------------------------------------------------------------------------------------------------------------------------#
foreach my $width (keys %unmatched_width_of_spnet){
  my $net = $unmatched_width_of_spnet{$width};
  my ($width_of_file_1,$width_of_file_2) = (split(/\s+/,$width))[0,1]; 
  print WRITE "	$net		$width_of_file_1				$width_of_file_2\n"if($detailed == 1);
}#foreach
#----------------------------------------------------------------------------------------------------------------------------------------------#
foreach my $shapeName (keys %unmatched_shapeName_of_spnet){
  my $net = $unmatched_shapeName_of_spnet{$shapeName};   
  my ($shapeName_of_file_1,$shapeName_of_file_2) = (split(/\s+/,$shapeName))[0,1];
  print WRITE "	$net		$shapeName_of_file_1				$shapeName_of_file_2\n"if($detailed == 1);
}#foreach
#----------------------------------------------------------------------------------------------------------------------------------------------#
print WRITE "non corresponding spnet\n";
foreach my $net (@spnet_list){
  if(!exists $SPNET_DATA_HASH_file_1{$net}){
     print WRITE "						$net x\n"if($summary == 1 || $detailed == 1);
     push (@non_corresponding_spnet,$net);
  }elsif(!exists $SPNET_DATA_HASH_file_2{$net}){
     print WRTIE "	$net x\n"if($summary == 1 || $detailed == 1);
     push(@non_corresponding_spnet,$net);
  }
}#foreach
$number_of_non_corresponding_spnet = @non_corresponding_spnet;
if($number_of_non_corresponding_spnet == 0){
   print WRITE "			  none\n"if($summary == 1 || $detailed == 1);
}
}#if spnet given
#----------------------------------------------------------------------------------------------------------------------------------#
if($group_given == 1){
my $grpmatched_cnt = 0;
my $grpunmatched_cnt = 0;
foreach my $grp_Name (keys %GROUP_INST_HASH_of_file_1){
  my @inst_name_of_file_1 = @{$GROUP_INST_HASH_of_file_1{$grp_Name}};
  my $regionName_of_file_1 = $GROUP_REGION_HASH_of_file_1{$grp_Name};
  if(exists $GROUP_INST_HASH_of_file_2{$grp_Name}){
    my @inst_name_of_file_2 = @{$GROUP_INST_HASH_of_file_2{$grp_Name}}; 
    my $regionName_of_file_2 = $GROUP_REGION_HASH_of_file_2{$grp_Name};
    my $number_of_inst = @inst_name_of_file_1;
    for(my $j =0 ;$j<=$#inst_name_of_file_1; $j++){
      my $instName_of_file_1 = $inst_name_of_file_1[$j];
      my $instName_of_file_2 = $inst_name_of_file_2[$j];
      if(($instName_of_file_1 eq $instName_of_file_2) && ($regionName_of_file_1 eq $regionName_of_file_2)){
        $matched_grp{$grp_Name} = 1; 
      }else{
        $unmatched_grp{$grp_Name} = 1;
        if($instName_of_file_1 ne $instName_of_file_2){
          my $instName = $instName_of_file_1." ".$instName_of_file_2;
          $unmatched_inst_of_grp{$instName} = $grp_Name;
        }if($regionName_of_file_1 ne $regionName_of_file_2){
          my $regionName = $regionName_of_file_1." ".$regionName_of_file_2;
          $unmatched_region_of_grp{$regionName} = $grp_Name;
        }
      }
    }#for
  }#if exists
}#foreach 
#----------------------------------------------------------------------------------------------------------------------------------------------#
foreach my $grp (keys %matched_grp){
  if(!exists $unmatched_grp{$grp}){
    $grpmatched_cnt++;
  }
}#foreach
foreach my $grp (keys %unmatched_grp){
  $grpunmatched_cnt++;
}#foreach
   print WRITE "noOfgroups		$noOfGroups_of_file_1				$noOfGroups_of_file_2\n"if($summary == 1 || $detailed == 1);
   print WRITE "matched group		$grpmatched_cnt					$grpmatched_cnt\n"if($summary == 1 || $detailed == 1);
   print WRITE "unmatched group		$grpunmatched_cnt				$grpunmatched_cnt\n"if($summary == 1 || $detailed == 1);
#----------------------------------------------------------------------------------------------------------------------------------------------#
foreach my $instName (keys %unmatched_inst_of_grp){
  my $grp = $unmatched_inst_of_grp{$instName};   
  my($instName_of_file_1,$instName_of_file_2) = (split(/\s+/,$instName))[0,1];
  print WRITE "		$grp 		$instName_of_file_1			$instName_of_file_2\n"if($detailed == 1);
}#foreach
#----------------------------------------------------------------------------------------------------------------------------------------------#
foreach my $regionName (keys %unmatched_region_of_grp){
  my $grp = $unmatched_region_of_grp{$regionName};
  my($regionName_of_file_1,$regionName_of_file_2) = (split(/\s+/,$regionName))[0,1];  
  print WRITE "		$grp		$regionName_of_file_1				$regionName_of_file_2\n"if($detailed == 1);
}#foreach
}#if group given
#----------------------------------------------------------------------------------------------------------------------------------------------#
if($blockage_given == 1){
my $blkmatched_cnt = 0;
my $blkunmatched_cnt = 0;
foreach my $blkName (keys %BLOCKAGE_LAYER_HASH_OF_FILE_1){
  my $layerName_of_file_1 = $BLOCKAGE_LAYER_HASH_OF_FILE_1{$blkName};
  if(exists $BLOCKAGE_RECT_HASH_OF_FILE_1{$blkName}){
    my @rect_co_ord_of_file_1 = @{$BLOCKAGE_RECT_HASH_OF_FILE_1{$blkName}};
    for(my $i=0;$i<=$#rect_co_ord_of_file_1;$i=$i+4){
      my $llx= $rect_co_ord_of_file_1[$i];
      my $lly = $rect_co_ord_of_file_1[$i+1];
      my $urx = $rect_co_ord_of_file_1[$i+2];
      my $ury = $rect_co_ord_of_file_1[$i+3];
      my $co_ord_of_file_1 = $llx." ".$lly." ".$urx." ".$ury;
      $BLOCKAGE_RECT_WITH_LAYER_NAME_OF_FILE_1{$blkName}{$co_ord_of_file_1} = $layerName_of_file_1;
    } 
  }#if exists
}#foreach
#------------------------------------------------------------------------------------------------------------------------------------------------#
foreach my $blkName (keys %BLOCKAGE_LAYER_HASH_OF_FILE_2){
  my $layerName_of_file_2 = $BLOCKAGE_LAYER_HASH_OF_FILE_2{$blkName};
  if(exists $BLOCKAGE_RECT_HASH_OF_FILE_2{$blkName}){
    my @rect_co_ord_of_file_2 = @{$BLOCKAGE_RECT_HASH_OF_FILE_2{$blkName}};
    for(my $i=0;$i<=$#rect_co_ord_of_file_2;$i=$i+4){
      my $llx= $rect_co_ord_of_file_2[$i];
      my $lly = $rect_co_ord_of_file_2[$i+1];
      my $urx = $rect_co_ord_of_file_2[$i+2];
      my $ury = $rect_co_ord_of_file_2[$i+3];
      my $co_ord_of_file_2 = $llx." ".$lly." ".$urx." ".$ury;
      $BLOCKAGE_RECT_WITH_LAYER_NAME_OF_FILE_2{$blkName}{$co_ord_of_file_2} = $layerName_of_file_2;
    } 
  }#if exists
}#foreach
#-------------------------------------------------------------------------------------------------------------------------------------------------#
foreach my $blkName (keys %BLOCKAGE_RECT_WITH_LAYER_NAME_OF_FILE_1){
  foreach my $co_ord (keys %{$BLOCKAGE_RECT_WITH_LAYER_NAME_OF_FILE_1{$blkName}}){
    my $layerName_of_file_1 = $BLOCKAGE_RECT_WITH_LAYER_NAME_OF_FILE_1{$blkName}{$co_ord};
    if(exists $BLOCKAGE_RECT_WITH_LAYER_NAME_OF_FILE_2{$blkName}){
      foreach my $co_ord (keys %{$BLOCKAGE_RECT_WITH_LAYER_NAME_OF_FILE_2{$blkName}}){
        my $layerName_of_file_2 = $BLOCKAGE_RECT_WITH_LAYER_NAME_OF_FILE_2{$blkName}{$co_ord};
        if(exists $BLOCKAGE_RECT_WITH_LAYER_NAME_OF_FILE_1{$blkName}{$co_ord}){
          if($layerName_of_file_1 eq $layerName_of_file_2){
            $matched_blk{$blkName} = 1;
          }else{
            $unmatched_blk{$blkName} = 1;
            if($layerName_of_file_1 ne $layerName_of_file_2){
              my $layerName = $layerName_of_file_1." ".$layerName_of_file_2;
              $unmatched_layer_of_blk{$layerName} = $blkName;
            }
          }
        }else {
          $unmatched_blk{$blkName} = 1;
          $unmatched_co_ord_of_blk{$co_ord} = $blkName;
          if($layerName_of_file_1 ne $layerName_of_file_2){
            my $layerName = $layerName_of_file_1." ".$layerName_of_file_2;
            $unmatched_layer_of_blk{$layerName} = $blkName;
          }
        }
      }#foreach 
    }#if exists
  }
}#foreach
#----------------------------------------------------------------------------------------------------------------------------------------------#
foreach my $blk (keys %matched_blk){
  if(!exists $unmatched_blk{$blk}){
    $blkmatched_cnt++;
  }
}#foreach
foreach my $blk (keys %unmatched_blk){
  $blkunmatched_cnt++;
}#foreach
      print WRITE "noOfBlks		$noOfBlockages_of_file_1				$noOfBlockages_of_file_2\n";
      print WRITE "matched blks		$blkmatched_cnt				$blkmatched_cnt\n";
      print WRITE "unmatched blks		$blkunmatched_cnt				$blkunmatched_cnt\n";
#----------------------------------------------------------------------------------------------------------------------------------------------#
foreach my $co_ord_of_file_2 (keys %unmatched_co_ord_of_blk){
  my $blkName = $unmatched_co_ord_of_blk{$co_ord_of_file_2};
  my $layerName_of_file_2 = $BLOCKAGE_RECT_WITH_LAYER_NAME_OF_FILE_2{$blkName}{$co_ord_of_file_2};
  if(exists $BLOCKAGE_RECT_WITH_LAYER_NAME_OF_FILE_1{$blkName}){
    foreach my $co_ord_of_file_1 (keys %{$BLOCKAGE_RECT_WITH_LAYER_NAME_OF_FILE_1{$blkName}}){
      if(!exists $BLOCKAGE_RECT_WITH_LAYER_NAME_OF_FILE_2{$blkName}{$co_ord_of_file_1}){
        my $layerName_of_file_1 = $BLOCKAGE_RECT_WITH_LAYER_NAME_OF_FILE_1{$blkName}{$co_ord_of_file_1}; 
        if($layerName_of_file_1 eq $layerName_of_file_2){
          my ($llx_1,$lly_1,$urx_1,$ury_1) = (split(/\s+/,$co_ord_of_file_1))[0,1,2,3];
          my ($llx_2,$lly_2,$urx_2,$ury_2) = (split(/\s+/,$co_ord_of_file_2))[0,1,2,3];
          if($llx_1 != $llx_2){
            my $diff = abs ($llx_2 - $llx_1);
            print WRITE "	$blkName 	     	$llx_1 				$llx_2 			$diff\n"if($detailed == 1);
          }if($urx_1 != $urx_2){
            my $diff = abs ($urx_2 - $urx_1);
            print WRITE "	$blkName 	     	$urx_1 				$urx_2 			$diff\n"if($detailed == 1);
          }if($lly_1 != $lly_2){
            my $diff = abs ($lly_2 - $lly_1);
            print WRITE "	$blkName         	$lly_1 				$lly_2 			$diff\n"if($detailed == 1);
          }if($ury_1 != $ury_2){
            my $diff = abs ($ury_2 - $ury_1);
            print WRITE "	$blkName	        $ury_1 				$ury_2 			$diff\n"if($detailed == 1);
          }
        } 
      } 
    }#foreach 
  } 
}#foreach
#----------------------------------------------------------------------------------------------------------------------------------------------#
foreach my $layerName (keys %unmatched_layer_of_blk){
  my $blkName = $unmatched_layer_of_blk{$layerName};
  my ($layerName_of_file_1,$layerName_of_file_2) = (split(/\s+/,$layerName))[0,1];
  print WRITE "	$blkName		$layerName_of_file_1				$layerName_of_file_2\n"if($detailed == 1);
}#foreach
}#if blockage_given
close (WRITE);

#----------------------------------------------------------------------------------------------------------------------------------------------#
sub convert_co_ord_for_nets_routing {
my $netSeg = $_[0];
if ($netSeg =~ m/\( (\d+) (\d+) \) (\w+)/ ) {
  my $llx = $1;
  my $lly = $2;
  my $urx = $1;
  my $ury = $2;
  my $via = $3;
  #print "$llx => $lly => $urx => $ury\n";
  #my $co_ord = "(".$llx.",".$lly.")"."(".$urx.",".$ury.")";
  my $co_ord = $llx." ".$lly." ".$urx." ".$ury;
  return ($co_ord,$via);
}elsif ($netSeg =~ m/\( (\d+) (\d+) \) \( (\d+) \* \) (\w+)/ ) {
  my $llx = $1;
  my $lly = $2;
  my $urx = $3;
  my $ury = $2;
  my $via = $4;
#    print "$llx => $lly => $urx => $ury\n";
  #my $co_ord = "(".$llx.",".$lly.")"."(".$urx.",".$ury.")";
  my $co_ord = $llx." ".$lly." ".$urx." ".$ury;
  return ($co_ord,$via);
}elsif ($netSeg =~ m/\( (\d+) (\d+) \) \( (\d+) \* (\d+) \) (\w+)/ ) {
  my $llx = $1;
  my $lly = $2;
  my $urx = $3+$4;
  my $ury = $2;
  my $via = $5;
#    print "$llx => $lly => $urx => $ury\n"; 
#  my $co_ord = "(".$llx.",".$lly.")"."(".$urx.",".$ury.")";
  my $co_ord = $llx." ".$lly." ".$urx." ".$ury;
  return ($co_ord,$via);
}elsif ($netSeg =~ m/\( (\d+) (\d+) \) \( (\d+) \* (\d+) \)/ ) {
  my $llx = $1;
  my $lly = $2;
  my $urx = $3+$4;
  my $ury = $2;
  #my $co_ord = "(".$llx.",".$lly.")"."(".$urx.",".$ury.")";
  my $co_ord = $llx." ".$lly." ".$urx." ".$ury;
  return ($co_ord);
}elsif ($netSeg =~ m/\( (\d+) (\d+) (\d+) \) \( (\d+) \* \) (\w+)/ ) {
  my $llx = $1-$3;
  my $lly = $2;
  my $urx = $4;
  my $ury = $2;
  my $via = $5;
#    print "$llx =>> $lly => $urx => $ury\n";
  #my $co_ord = "(".$llx.",".$lly.")"."(".$urx.",".$ury.")";
  my $co_ord = $llx." ".$lly." ".$urx." ".$ury;
  return ($co_ord,$via);
}elsif ($netSeg =~ m/\( (\d+) (\d+) (\d+) \) \( (\d+) \* \)/ ) {
  my $llx = $1-$3;
  my $lly = $2;
  my $urx = $4;
  my $ury = $2;
#    print "$llx =>> $lly => $urx => $ury\n";
  #my $co_ord = "(".$llx.",".$lly.")"."(".$urx.",".$ury.")";
  my $co_ord = $llx." ".$lly." ".$urx." ".$ury;
  return ($co_ord);
}elsif ($netSeg =~ m/\( (\d+) (\d+) (\d+) \) \( (\d+) \* (\d+) \)/ ) {
  my $llx = $1-$3;
  my $lly = $2;
  my $urx = $4+$5;
  my $ury = $2;
#    print "$llx =>> $lly => $urx => $ury\n";
  #my $co_ord = "(".$llx.",".$lly.")"."(".$urx.",".$ury.")";
  my $co_ord = $llx." ".$lly." ".$urx." ".$ury;
  return ($co_ord);
}elsif ($netSeg =~ m/\( (\d+) (\d+) (\d+) \) \( (\d+) \* (\d+) \) (\w+)/ ) {
  my $llx = $1-$3;
  my $lly = $2;
  my $urx = $4+$5;
  my $ury = $2;
  my $via = $6;
#    print "$llx =>> $lly => $urx => $ury\n";
  #my $co_ord = "(".$llx.",".$lly.")"."(".$urx.",".$ury.")";
  my $co_ord = $llx." ".$lly." ".$urx." ".$ury;
  return ($co_ord,$via);
}elsif ($netSeg =~ m/\( (\d+) (\d+) \) \( (\d+) \* \)/ ) {
  my $llx = $1;
  my $lly = $2;
  my $urx = $3;
  my $ury = $2;
#    print "$llx =>> $lly => $urx => $ury\n";
    #my $co_ord = "(".$llx.",".$lly.")"."(".$urx.",".$ury.")";
  my $co_ord = $llx." ".$lly." ".$urx." ".$ury;
  return ($co_ord);
}elsif ($netSeg =~ m/\( (\d+) (\d+) \) \( \* (\d+) \) (\w+)/ ) {
  my $llx = $1;
  my $lly = $2;
  my $urx = $1;
  my $ury = $3;
  my $via = $4;
#   print "$llx =>> $lly => $urx => $ury\n";
  #my $co_ord = "(".$llx.",".$lly.")"."(".$urx.",".$ury.")";
  my $co_ord = $llx." ".$lly." ".$urx." ".$ury;
  return ($co_ord,$via);
}elsif ($netSeg =~ m/\( (\d+) (\d+) \) \( \* (\d+) (\d+) \) (\w+)/ ) {
  my $llx = $1;
  my $lly = $2;
  my $urx = $1;
  my $ury = $3+$4;
  my $via = $5;
#    print "$llx =>> $lly => $urx => $ury\n";
  #my $co_ord = "(".$llx.",".$lly.")"."(".$urx.",".$ury.")";
  my $co_ord = $llx." ".$lly." ".$urx." ".$ury;
  return ($co_ord,$via);
}elsif ($netSeg =~ m/\( (\d+) (\d+) \) \( \* (\d+) (\d+) \)/ ) {
  my $llx = $1;
  my $lly = $2;
  my $urx = $1;
  my $ury = $3+$4;
#    print "$llx =>> $lly => $urx => $ury\n";
  #my $co_ord = "(".$llx.",".$lly.")"."(".$urx.",".$ury.")";
  my $co_ord = $llx." ".$lly." ".$urx." ".$ury;
  return ($co_ord);
}elsif ($netSeg =~ m/\( (\d+) (\d+) (\d+) \) \( \* (\d+) \) (\w+)/ ) {
  my $llx = $1;
  my $lly = $2-$3;
  my $urx = $1;
  my $ury = $4;
  my $via = $5;
#    print "$llx =>> $lly => $urx => $ury\n";
  #my $co_ord = "(".$llx.",".$lly.")"."(".$urx.",".$ury.")";
  my $co_ord = $llx." ".$lly." ".$urx." ".$ury;
  return ($co_ord,$via);
}elsif ($netSeg =~ m/\( (\d+) (\d+) (\d+) \) \( \* (\d+) \)/ ) {
  my $llx = $1;
  my $lly = $2-$3;
  my $urx = $1;
  my $ury = $4;
#    print "$llx =>> $lly => $urx => $ury\n";
  #my $co_ord = "(".$llx.",".$lly.")"."(".$urx.",".$ury.")";
  my $co_ord = $llx." ".$lly." ".$urx." ".$ury;
  return ($co_ord);
}elsif ($netSeg =~ m/\( (\d+) (\d+) (\d+) \) \( \* (\d+) (\d+) \)/ ) {
  my $llx = $1;
  my $lly = $2-$3;
  my $urx = $1;
  my $ury = $4+$5;
#    print "$llx =>> $lly => $urx => $ury\n";
  #my $co_ord = "(".$llx.",".$lly.")"."(".$urx.",".$ury.")";
  my $co_ord = $llx." ".$lly." ".$urx." ".$ury;
  return ($co_ord);
}elsif ($netSeg =~ m/\( (\d+) (\d+) (\d+) \) \( \* (\d+) (\d+) \) (\w+)/ ) {
  my $llx = $1;
  my $lly = $2-$3;
  my $urx = $1;
  my $ury = $4+$5;
  my $via = $6;
#    print "$llx =>> $lly => $urx => $ury\n";
  #my $co_ord = "(".$llx.",".$lly.")"."(".$urx.",".$ury.")";
  my $co_ord = $llx." ".$lly." ".$urx." ".$ury;
  return ($co_ord,$via);
}elsif ($netSeg =~ m/\( (\d+) (\d+) \) \( \* (\d+) \)/ ) {
  my $llx = $1;
  my $lly = $2;
  my $urx = $1;
  my $ury = $3;
#    print "$llx =>> $lly => $urx => $ury\n";
  #my $co_ord = "(".$llx.",".$lly.")"."(".$urx.",".$ury.")";
  my $co_ord = $llx." ".$lly." ".$urx." ".$ury;
  return ($co_ord);
}
#--- temporary code to support jspeed routing text -------------------------#
elsif ($netSeg =~ m/\( (\d+) (\d+) \) \( (\d+) (\d+) \)/ ) {
  if ( $1 == $3 ) {
    my $llx = $1;
    my $lly = $2;
    my $urx = $3;
    my $ury = $4;
#      print "$llx =>> $lly => $urx => $ury\n";
    #my $co_ord = "(".$llx.",".$lly.")"."(".$urx.",".$ury.")";
  my $co_ord = $llx." ".$lly." ".$urx." ".$ury;
    return ($co_ord);
  }elsif ( $2 == $4 ) {
    my $llx = $1;
    my $lly = $2;
    my $urx = $3;
    my $ury = $4;
#      print "$llx =>> $lly => $urx => $ury\n";
    #my $co_ord = "(".$llx.",".$lly.")"."(".$urx.",".$ury.")";
  my $co_ord = $llx." ".$lly." ".$urx." ".$ury;
    return ($co_ord);
  }
}elsif ($netSeg =~ m/\( (\d+) (\d+) (\d+) \) \( (\d+) (\d+) (\d+) \)/ ) {
  if($1 == $4){
    my $llx = $1;
    my $lly = $2-$3;
    my $urx = $4;
    my $ury = $5+$6;
#      print "$llx =>> $lly => $urx => $ury\n";
    #my $co_ord = "(".$llx.",".$lly.")"."(".$urx.",".$ury.")";
  my $co_ord = $llx." ".$lly." ".$urx." ".$ury;
    return ($co_ord);
  }elsif($3 == $6){
    my $llx = $1-$3;
    my $lly = $2;
    my $urx = $4+$6;
    my $ury = $5;
#      print "$llx =>> $lly => $urx => $ury\n";
    #my $co_ord = "(".$llx.",".$lly.")"."(".$urx.",".$ury.")";
  my $co_ord = $llx." ".$lly." ".$urx." ".$ury;
    return ($co_ord);
  }
}elsif ($netSeg =~ m/\( (\d+) (\d+) (\d+) \) \( (\d+) (\d+) (\d+) \) (\w+)/ ) {
  if($1 == $4){
    my $llx = $1;
    my $lly = $2-$3;
    my $urx = $4;
    my $ury = $5+$6;
    my $via = $7; 
#      print "$llx =>> $lly => $urx => $ury\n";
    #my $co_ord = "(".$llx.",".$lly.")"."(".$urx.",".$ury.")";
  my $co_ord = $llx." ".$lly." ".$urx." ".$ury;
    return ($co_ord,$via);
  }elsif($3 == $6){
    my $llx = $1-$3;
    my $lly = $2;
    my $urx = $4+$6;
    my $ury = $5;
    my $via = $7;
#      print "$llx =>> $lly => $urx => $ury\n";
    #my $co_ord = "(".$llx.",".$lly.")"."(".$urx.",".$ury.")";
  my $co_ord = $llx." ".$lly." ".$urx." ".$ury;
    return ($co_ord,$via);
  }
}
}#sub convert_co_ord_for_nets_routing
