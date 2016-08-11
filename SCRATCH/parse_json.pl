#!/usr/bin/perl
use JSON;

my $filename = './library_new.config';
my $data;
if (open (my $json_str, $filename))
{
  local $/ = undef;
  my $json = JSON->new;
  $data = $json->decode(<$json_str>);
  close($json_stream);
}

use Tk;
use Tk::Frame;
use Tk::Pane;  
my $subWin = MainWindow->new();
   $subWin->title ("Design Hierarchy Display");

my $techFrame= $subWin->Frame()->pack(-side => 'top',-anchor=>'n', -expand=>1, -fill=>'x');
my $stdCellFrame= $subWin->Frame()->pack(-side => 'top',-anchor=>'e', -expand=>1, -fill=>'x');
my $MainFrame= $subWin->Frame()->pack(-side => 'top',-anchor=>'n', -expand=>1, -fill=>'both');
my $buttonFrame= $subWin->Frame()->pack(-side => 'bottom');

my $techLabel = $techFrame->Label(-text=>"Tech File    :")->pack(-side=>'left');
$techEntry = $techFrame->Entry(-textvariable => \$techPath )->pack(-expand=>1, -fill=>'x',-side=>'left');
my $stdCellLabel = $stdCellFrame->Label(-text=>"StdCell File:")->pack(-side=>'left');
$stdCellEntry = $stdCellFrame->Entry(-textvariable => \$stdCellPath )->pack(-expand=>1, -fill=>'x',-side=>'left');

$techPathEntry = $techFrame->Entry(-textvariable => \$techFullPath )->pack(-expand=>1, -fill=>'x',-side=>'left');
$stdCellPathEntry = $stdCellFrame->Entry(-textvariable => \$stdCellFullPath )->pack(-expand=>1, -fill=>'x',-side=>'left');
$techPathEntry->packForget(); 
$stdCellPathEntry->packForget();


my $top_pane = $MainFrame->Scrolled(qw/Pane -width 400 -height 400 -scrollbars se -sticky nsew/);
   $top_pane->Subwidget("xscrollbar")->configure(-width=>15,-borderwidth=>1);
   $top_pane->Subwidget("yscrollbar")->configure(-width=>15,-borderwidth=>1);
   $top_pane->pack(qw/-side left -anchor w -fill both -expand 1/);
my $exitButton = $buttonFrame->Button(-text=>"Exit", -command=>sub{$subWin->destroy;})->pack(-side=>"left");;
my $importButton = $buttonFrame->Button(-text=>"Import", -command=>sub{&import_sel_library();})->pack(-side=>"left");;


my $cf = $top_pane->Frame(-relief=>"groove", -borderwidth=>4,-background=>"light gray");
$cf->pack(qw/-fill both -expand 1 -side left -anchor w /);
my $foundryLabel = $cf->Label(-text=>"FOUNDRY", -background=>'dark grey', -foreground=>'blue', -height=>2)->pack(-side=>'top', -fill=>'x');

foreach my $lib (keys %$data){
   ${"button".$lib} = $cf->Button(-text=>$lib,-relief=>"flat", -foreground=>"orange2",-background=>"light gray", 
                                  -command=>sub{&delete_frame(0); 
                                                &displayLibrary($lib, "", $top_pane,0);
                                                &highlight_selected_lib($lib, "", "");
                                  })->pack(-side=>'top',-fill=>'x');
}


MainLoop();

##############################################################################################################
############################################### display Library ##############################################
##############################################################################################################
sub displayLibrary {
  my $lib = $_[0];
  my $type = $_[1];
  my $topFrame = $_[2];
  my $level = $_[3];
  my $frame;
  if($level == 0){
     if(@{$data->{$lib}{node}} > 0){
         $frame = $topFrame->Frame(-relief=>"groove", -borderwidth=>4,-background=>"light gray");
         $frame->pack(qw/-fill both -expand 1 -side left -anchor w /);
         my $processLabel = $frame->Label(-text=>"PROCESS", -background=>'dark grey', -foreground=>'blue', -height=>2)->pack(-side=>'top', -fill=>'x');
         $FRAME_HASH{$lib} = $frame;
     }else{return;}
     foreach my $node (@{$data->{$lib}{node}}){
         my $nodeType = $node->{type};
         ${"button".$lib.$nodeType} = $frame->Button(-text=>$nodeType,-relief=>"flat", -foreground=>"orange2",-background=>"light gray", 
                                                     -command=>sub{&delete_frame(1); 
                                                                   &displayLibrary($lib,$nodeType,$topFrame, 1);
                                                                   &highlight_selected_lib($lib, $nodeType, "");
                                                     })->pack(-side=>'top',-fill=>'x');
     }#foreach node
  }elsif($level == 1){
     foreach my $node (@{$data->{$lib}{node}}){
        my $nodeType = $node->{type};
        if($nodeType eq $type){
           if(@{$node->{files}} > 0){
               $frame = $topFrame->Frame(-relief=>"groove", -borderwidth=>4,-background=>"light gray");
               $frame->pack(qw/-fill both -expand 1 -side left -anchor w /);
               my $layerLabel = $frame->Label(-text=>"LAYER", -background=>'dark grey', -foreground=>'blue', -height=>2)->pack(-side=>'top', -fill=>'x');
               $FRAME_HASH{$lib.$nodeType} = $frame;
           }else{return;}
           foreach my $file (@{$node->{files}}){
               my $layer = $file->{layer};
               my $techFile = $file->{tech};
               my $stdCellFile = $file->{'std-cells'};
               ${"button".$lib.$nodeType.$layer} = $frame->Button(-text=>$layer,-relief=>"flat", -foreground=>"orange2",-background=>"light gray", 
                                                              -command=>sub{ 
                                                                            &highlight_selected_lib($lib, $nodeType, $layer);
                                                                            $techPath = (split(/\//, $techFile))[-1];      
                                                                            $stdCellPath = (split(/\//, $stdCellFile))[-1];      
                                                                            $techFullPath = $techFile;
                                                                            $stdCellFullPath = $stdCellFile;
                                                              })->pack(-side=>'top',-fill=>'x');
           }#foreach file
        }#if nodeType
     }#foreach node
  }#if level 1
}#sub displayLibrary


##############################################################################################################
############################################# deleting the frames ############################################
##############################################################################################################
sub delete_frame {
  my $level = $_[0];
  foreach my $lib (keys %$data){
     if($level >= 0){
        foreach my $node (@{$data->{$lib}{node}}){
           my $type = $node->{type};
           if(Exists $FRAME_HASH{$lib.$type}){
              my $frame = $FRAME_HASH{$lib.$type};
              $frame->destroy;
           }
        }
     }
     if($level == 0){
        if(Exists $FRAME_HASH{$lib}){
           my $frame = $FRAME_HASH{$lib};
           $frame->destroy;
        }
     }  
  }
}#sub delete_frame

##############################################################################################################
########################################### highliting selected lib ##########################################
##############################################################################################################
sub highlight_selected_lib{
  my $lib = $_[0];
  my $type = $_[1];
  my $layer = $_[2];

  if($type eq "" && $layer eq ""){
     foreach my $library (keys %$data){
        if($library eq $lib){
           ${"button".$library}->configure(-background=>"white");
        }else{
           ${"button".$library}->configure(-background=>"light gray");
        }
     }#foreach library
  }else{
     foreach my $node (@{$data->{$lib}{node}}){
        my $nodeType = $node->{type};
        if($type ne "" && $layer eq ""){
           if($nodeType eq $type){
              ${"button".$lib.$nodeType}->configure(-background=>"white");
           }else{
              ${"button".$lib.$nodeType}->configure(-background=>"light gray");
           }
        }else{
           if($nodeType eq $type){
              foreach my $file (@{$node->{files}}){
                  my $nodeLayer = $file->{layer};
                  if($nodeLayer eq $layer){
                     ${"button".$lib.$nodeType.$nodeLayer}->configure(-background=>"white");
                  }else{
                     ${"button".$lib.$nodeType.$nodeLayer}->configure(-background=>"light gray");
                  }
              }#foreach file
           }
        }
     }#foreach node
  }
}#sub highlight_selected_lib

##############################################################################################################
################################################ import library ##############################################
##############################################################################################################
sub import_sel_library{
  my $techLef = $techPathEntry->cget('-text'); 
  my $stdCellsLef = $stdCellPathEntry->cget('-text');
  print "tech:$$techLef | stdcell:$$stdCellsLef\n";

  #&read_lef ("-lef", "$techLef", "-tech","only");
  #&read_lef ("-lef","$stdCellsLef");

  #&call_read_lef;
}#sub import_sel_library


