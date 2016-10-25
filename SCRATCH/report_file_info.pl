#!/usr/bin/perl -w
use XML::Writer;
my @AGRV = @_;
my $read_all = 1;
my $read_lef = 0;
my $read_def = 0;
my $read_verilog = 0;
my $read_file = 0;
my $report_file = "report_file_info";
my $pathName = ".";
my $xmlout = "";
my $read_rtl = 0;
my @leffiles = ();
my @deffiles = ();
my @verilogfiles = ();
my @net_list_file = ();
my $fileName = "";
my $return_in_xml = 0;
my $xml = "";
  for(my $i = 0; $i <= $#ARGV; $i++) {
    if($ARGV[$i] eq "--path")       { $pathName = $ARGV[$i+1]; }
    if($ARGV[$i] eq "--file")      {$fileName = $ARGV[$i+1];
                                    $read_all = 0;$read_file = 1;$read_lef = 0; $read_def =0;$read_verilog =0;}
    if($ARGV[$i] eq "--name")       { $report_file = $ARGV[$i+1]; }
    if($ARGV[$i] eq "--lef")       { $read_lef=1; $read_all = 0; }
    if($ARGV[$i] eq "--def")       { $read_def=1; $read_all = 0; }
    if($ARGV[$i] eq "--v")         { $read_verilog =1; $read_all = 0;}
    if($ARGV[$i] eq "--xml")       { $return_in_xml = 1;}
  }
if($return_in_xml == 1){
$xml = new XML::Writer(OUTPUT => \$xmlout);
$xml->startTag("root");
$xmlout .= "\n";
}
  if($return_in_xml == 0){
    print "INFO : $report_file has been generated : pathName $pathName\n";
    open (WRITE,">$report_file");
  }
if($read_all == 1 || $read_lef == 1 || $read_file == 1){
   if($fileName eq ""){
     @leffiles = `find  -L $pathName -name \\*\\.lef\\*  | grep -v "\/\.svn\/"`;
   }else{
     @leffiles = `find  -L $fileName -name \\*\\.lef\\*  | grep -v "\/\.svn\/"`;
    }
  foreach my $file(@leffiles){
    if($return_in_xml == 0){
      print WRITE "LEF : $file";
    }
  }
}
if($read_all == 1 || $read_def == 1 || $read_file == 1){
   if($fileName eq ""){
     @deffiles = `find  -L $pathName -name \\*\\.def\\*  | grep -v "\/\.svn\/"`;
   }else{
     @deffiles = `find  -L $fileName -name \\*\\.def\\*  | grep -v "\/\.svn\/"`;
   }
   foreach my $file(@deffiles){
     if($return_in_xml == 0){ 
       print WRITE "DEF : $file";
     }
   }
}
if($read_all == 1 || $read_verilog == 1 || $read_file == 1){
  if($fileName eq ""){
    @verilogfiles = `find -L $pathName -name \\*\\.v -o -name \\*\\.gv -o -name \\*\\.vg`;
  }else {
    @verilogfiles = `find -L $fileName -name \\*\\.v -o -name \\*\\.gv -o -name \\*\\.vg`;
  }
  foreach my $file(@verilogfiles){
    open(READ, "$file");
    my $skip_comment = 0;
    while(<READ>){ 
      chomp($_);
      if ($_ =~ /\/\*(.*)\*\//){
        $_ =~s/\/\*(.*)\*\///;
      }
      if (($skip_comment == 1) && ($_ !~ /\*\//)){
        next;
      }
      if (($_ =~ /\/\*/) && ($_ !~ /\*\//) ){
        $skip_comment = 1; 
        $_ =~s/\/\*(.*)//;
      }
      if (($skip_comment == 1) && ($_ =~ /\*\//)){
        $_ =~s/(.*)\*\///;
        $skip_comment = 0;
      }
      if($_ =~ /\/\//){
        $_ =~s/\/\/(.*)//;
      }
      if($_ =~ /^\s*always\b/){
         #print "RTL: $file";
        $read_rtl = 1;
        last;
      }
    }
    close(READ);
    if($read_rtl == 0){
       push(@net_list_file,$file);
       if($return_in_xml == 0){
         print WRITE "VERILOG : $file";
       }
       next;
    }
  }
}
if($return_in_xml == 0){
  print WRITE "\n";
}
foreach my $file (@leffiles){
    chomp($file);
    $file =~ s/.*\///;
    my @new_file = (split(/\s+/,$file));
    if($return_in_xml == 1){
    $xml->startTag('file','name' => $file);
    &read_lef_data(@new_file);
    $xmlout .= "\n";
    $xml->endTag();
    $xmlout .= "\n";
    }else {
      print WRITE "$file\n";
      &read_lef_data(@new_file);
      print WRITE"\n";
    }
}
foreach my $file(@deffiles){
    chomp($file);
    $file =~ s/.*\///;
    my @new_file = (split(/\s+/,$file));
    if($return_in_xml == 1){
    $xml->startTag('file','name' => $file);
    &read_def_data(@new_file);
    $xmlout .= "\n";
    $xml->endTag();
    $xmlout .= "\n";
    }else{
      print WRITE "$file\n";
      &read_def_data(@new_file);
      print WRITE"\n";
    }
}
foreach my $file (@net_list_file){
    chomp($file);
    $file =~ s/.*\///;
    my @new_file = (split(/\s+/,$file));
    if($return_in_xml == 1){
    $xml->startTag('file','name' => $file);
    &read_verilog_data(@new_file);
    $xmlout .= "\n";
    $xml->endTag();
    $xmlout .= "\n";
    }else {
      print WRITE "$file\n";
      &read_verilog_data(@new_file);
      print WRITE"\n";
    }
}
if($return_in_xml == 1){
$xml->endTag();
$xml->end();
print "$xmlout\n";
}
#------------------------------------------------------------------------------------------------------------#
sub read_lef_data {
my @arg = @_;
my $INPUT_LEF  = $arg[-1];
if ((-e $INPUT_LEF) && (-r $INPUT_LEF)){
if($return_in_xml == 0){
  print WRITE "\t\tBegin reading the lef file\n";
}
open(READ_TECH, "$INPUT_LEF");
my $stop_reading_tech_lef = 0;
my $layerName = "";
my $siteName = "";
my $start_reading_tech_layers = 0;
my $start_reading_macro_lef = 0;
my $start_reading_site = 0;
my $start_reading_via_section = 0;
my $start_reading_viarule_section = 0;
my $total_layer_cnt = 0;
my %Class_Data = ();
my %Macro_Cnt = ();
my %SITE_DATA =();
while(<READ_TECH>){
chomp();
if($_ =~ /^\s*#/ ) { next ; }
if($_ =~ /\#/ ) { $_ =~ s/\s+#.*$//; }
$_ =~ s/\s+/ /g;
$_=~ s/\s+$//g;
if($_ =~ /^\s*MACRO/){
                  $stop_reading_tech_lef = 1;
                  $start_reading_macro_lef = 1;
                  my($macroName)=(split(/\s+/,$_))[1];
                  }
if(($macroName) && ($_ =~ /^END $macroName/)){
                  $stop_reading_tech_lef = 0;
                  next;
                  }
if($_ =~ /^\s*VIA / ) {
                     $start_reading_via_section = 1; 
                     $start_reading_tech_layers = 0;
                     ($viaName)=(split(/\s+/,$_))[1]; 
                     }
if($viaName && ($_ =~ /^END $viaName/ )) {
                     $start_reading_via_section = 0; 
                     $start_reading_tech_layers = 0;
                     if($newViaLayerInstance){
                     }
                      $newViaLayerInstance = "";
                     }
if($_ =~ /^\s*VIARULE / ){
                        $start_reading_viarule_section =1;
                        $start_reading_tech_layers = 0;
                        ($viaruleName) = (split(/\s+/,$_))[1];
                           }
if($viaruleName && ($_ =~ /^END $viaruleName/)){
                          $start_reading_viarule_section = 0;
                          $start_reading_tech_layers = 0;
                          if($newLayerInstance) {
                          }
                          $newLayerInstance = "" ;
                        }          
if($_ =~ /^\s*LAYER/){
                     ($layerName)=(split(/\s+/,$_))[1]; 
                      $start_reading_tech_layers = 1 ;
                     
if($_ =~ /^\s*END $layerName / ) {
                     $start_reading_tech_layers = 0;
                     }
                                          }

if ( $_ =~ /^\s*SITE/ ) {
                $siteName = (split(/\s+/,$_))[1];
                $TECHNOLOGY_PHYSICAL{$siteName}{TYPE} = SITE;
                  $stop_reading_tech_lef = 0;
                  $start_reading_via_section = 0;
                  $start_reading_viarule_section = 0;
                  $start_reading_site = 1;
                  $start_reading_macro_lef = 0;
                          }# if site
if (/^\s*SITE $siteName/ ... /END $siteName/ ) {
#               print "DBG : $start_reading_macro_lef\n" if ($DEBUG == 20); 
               next if ( $start_reading_macro_lef == 1 );
               if( $_ =~ /CLASS/ ) { $class = (split(/\s+/,$_))[2]; 
                                     $class =~ s/\;//;
                                     $TECHNOLOGY_PHYSICAL{$siteName}{CLASS} = $class;
                                     $SITE_DATA{$siteName} = $class;
#                                     print "INFO-PAR-LEF : 004 : class : $class\n";
                                   }
               elsif( $_ =~ /SIZE/ ) { ($width,$height) = (split(/\s+/,$_))[2,4];
                                        $height =~ s/\;//;
                                    $TECHNOLOGY_PHYSICAL{$siteName}{SIZE} = "$width $height"; 
#                                    print "INFO-PAR-LEF : 005 : $siteName $class $width $height\n";
                                  }
## fixed the issue Mantis-0000161 by Rajeev
              if ( $_ =~ /END $siteName/ ) {
              if( $width > 0 && $height > 0 && $class =~ /core/i ) {
                                  if ( $class eq "CORE" || $class eq "core" ) {
                                                          }
                                       next;  
                                                                    }# if both width and height of core is set
                                            }# if END of site statement 
                                                 }# if between the site info construct
#---------------------------------#
# Technology LAYERS Section       #
#---------------------------------#

if($stop_reading_tech_lef == 0 && $start_reading_tech_layers == 1){
   if(/LAYER $layerName/ ... /END $layerName/){
                    if($_ =~ /^\s*LAYER/){ ($layerName)=(split(/\s+/,$_))[1];
                       $total_layer_cnt++;
                       }
   elsif(($_ =~ /TYPE/)||($_ =~ /type/)){ ($layerType)=(split(/\s+/,$_))[2];
                                       ${$layerName}{'TYPE'} = $layerType;
                                     }
   elsif($_ =~ /^\s*\bDIRECTION\b\s+/){ ($layerDirection)=(split(/\s+/,$_))[2];
                                       ${$layerName}{'DIRECTION'} = $layerDirection;
                                          }
   elsif($_ =~ /^\s*\bWIDTH\b\s+/){
                           my @w =split(/\s+/, $_);
                           my $length = @w;
                           if($length == 4){
                           $layerWidth = $w[2];
                           ${$layerName}{WIDTH} = $layerWidth;
                           } else{}
                                     }
   elsif($_ =~ /\bPITCH/) { ($layerPitch)=(split(/\s+/,$_))[2];
                            ${$layerName}{'PITCH'} = $layerPitch;
                         }
   elsif($_ =~ /\bOFFSET/) { my ($layerOffset)=(split(/\s+/,$_))[2];
                           }
   elsif($_ =~ /\bSPACING/) { ($layerSpacing)=(split(/\s+/,$_))[2];
                                       if ( exists ${$layerName}{'SPACING'} ) { 
#                                       print "INFO-PAR-LEF : 007 : proton does not use Variable spacing rule .. ignoring data\n";
                                                                              }
                                       else {
                                       ${$layerName}{'SPACING'} = $layerSpacing;
                                            }
                                          }
   elsif($_ =~ /\bRESISTANCE/){ ($layerResistance)=(split(/\s+/,$_))[3];
                                       ${$layerName}{'RESISTANCE'} = $layerResistance;
                                          }
   elsif($_ =~ /\bCAPACITANCE/){ ($layerCapacitance)=(split(/\s+/,$_))[3];
                                       ${$layerName}{'CAPACITANCE'} = $layerCapacitance;
                                          }
                     elsif($_ =~ /\bEDGECAPACITANCE/){ ($layerEdgeCapacitance)=(split(/\s+/,$_))[2];
                                       ${$layerName}{'EDGECAPACITANCE'} = $layerEdgeCapacitance;
                                          }
                     }# if between the same layer
   }# if reading only the technology portion
#------------------------------VIA SECTION--------------------------------------#
if($stop_reading_tech_lef == 0 && $start_reading_via_section == 1){
                 if($_ =~ m/VIA /){
                   ($viaName)= (split(/\s+/,$_))[1];
                 }elsif($_ =~/RESISTANCE/){
                       my $p = (split(/\s+/,$_))[2];
                   }elsif($_ =~ /LAYER/){
                       if($newViaLayerInstance){
                   }
                        my($layer) = (split(/\s+/,$_))[2];
                        if($newViaLayerInstance){
                   }
                   }elsif($_ =~ /^\s*\bRECT\b\s+/){
                         ($rect[0],$rect[1],$rect[2],$rect[3]) = (split(/\s+/,$_))[2,3,4,5];
                         if($newViaLayerInstance){
                   }                  
                   }
                 }#if
#-----------------------------------------VIARULE SECTION---------------------#
if($stop_reading_tech_lef == 0 && $start_reading_viarule_section == 1){
                   if($_ =~ m/VIARULE /){
                      ($viaruleName) = (split(/\s+/,$_))[1];
                      }elsif($_ =~ /LAYER/){
                      if($newLayerInstance) {
                      }
                     my ($layerName) = (split(/\s+/,$_))[2];
                      if($newLayerInstance) {
                      }
                      }elsif($_ =~ /\bCUTSIZE\b/){
                         ($cutsize[0],$cutsize[1])= (split(/\s+/,$_))[2,3];
                         if($newLayerInstance){
                         }
                      }elsif($_ =~ /\bCUTSPACING\b/){
                            ($cutsp[0],$cutsp[1]) = (split(/\s+/,$_))[2,3];
                          if($newLayerInstance){
                          }
                      }elsif($_ =~ /\bOVERHANG\b/){
                         my ($overhang)= (split(/\s+/,$_))[2];
                        if($newLayerInstance){
                        }
                      }elsif($_ =~ /\bMETALOVERHANG\b/){
                         my ($metal_over_hang) = (split(/\s+/,$_))[2];
                        if($newLayerInstance){
                        } 
                      }elsif($_ =~ /\bENCLOSURE\b/){
                          ($e[0],$e[1]) = (split(/\s+/,$_))[2,3];
                        if($newLayerInstance){
                        }
                      }elsif($_ =~ /\bWIDTH\b/){
                         ($width[0],$width[1]) = (split(/\s+/,$_))[2,4];
                        if($newLayerInstance){
                        }
                      }elsif($_ =~ /DIRECTION/){
                         my ($dir) = (split(/\s+/,$_))[2];
                        if($newLayerInstance) {
                        }  
                      }elsif($_ =~ /SPACING/){
                         ($sp[0],$sp[1])= (split(/\s+/,$_))[2,4];
                        if($newLayerInstance) {
                        }
                      }elsif($_ =~ /RECT/){
                         ($rect[0],$rect[1],$rect[2],$rect[3]) = (split(/\s+/,$_))[2,3,4,5];
                        if($newLayerInstance) {
                        }
                      }
  }#if
}# while
close(READ_TECH);
#######################################################################################
####              read the macro from lef file                                     ####
#######################################################################################
         #####  INITIALLIZE #####

my $macroName = "";
open(READ_LEF, "$INPUT_LEF");
while(<READ_LEF>){
chomp;
$_ =~ s/^\s+//;
if($_ =~ /^\s*#/ ) { next ; }
if($_ =~ /\#/ ) { $_ =~ s/\s+#.*$//; }

if($_ =~ /^MACRO/){ ($macroName)=(split(/\s+/, $_))[1];
                     $Name = "SHIVA_PIN_IS_UNSET"
                  }# if MACRO
if(/^MACRO $macroName/ ... /^END $macroName\s*$/){
  if($_ =~ /^SIZE/){($width,$height)=(split(/\s+/, $_))[1,3];
  }
  if($_ =~ /^CLASS/){
  my @c =split(/\s+/, $_);
  my $len = @c;
  if ($len == 3) { $class=$c[1]; }
  elsif ($len == 4) { $class=$c[1]." ".$c[2]; }
  else {print "WARN-PAR-LEF : 009 : CLASS statement for $macroName has syntax problem\n";}
  $Class_Data{$macroName} = $class;
  }# if CLASS
  if($_ =~ /^ORIGIN/){
     my ($xOrig,$yOrig)=(split(/\s+/, $_))[1,2];
  }# if ORIGIN
  if($_ =~ /^PIN/){($Name)=(split(/\s+/,$_))[1];
            if($Name =~ /\[[0-9]+\]/){  $pinName = $Name; $Name =~ s/\]//;
                                        ($busName,$busBit)=(split(/\[/,$Name))[0,1];
#                                        print "DBG-PAR-LEF : 010 : busName $busName busbit $busBit \n" if ($DEBUG == 1);
                                        $pinHash = $macroName.$pinName; 
                                        ${$macroName}{$pinName} = \%{$pinHash};
                                        ${$pinHash}{'type'} = "BUS";
                                        ${$pinHash}{'footprint'} = $busName;
                                        ${$pinHash}{'bit'} = $busBit;
                                        } # if BUS
                                   else { $pinName = $Name; $pinHash = $macroName.$pinName;
                                        ${$macroName}{$pinName} = \%{$pinHash};
                                        ${$pinHash}{'type'} = "SINGLE";
                                        } # if NOT BUS
                          }# if PIN
           if($Name eq "SHIVA_PIN_IS_UNSET"){ } else {
           if(${$macroName}{$pinName}{'type'} eq "SINGLE"){
                                          #my $newpinName =~ s/\\\[/\\\\\[/;
                                          #my $newpinName =~ s/\\\]/\\\\\]/; 
#          if(/^PIN $newpinName/ ... /^END $newpinName/){
              if($_ =~ /DIRECTION/){ $dir = get_direction($_); 
                                   ${$macroName.$pinName}{'direction'} = $dir; 
                                   } # if DIRECTION
              if($_ =~ /\bUSE\b/){ $useType = (split(/\s+/, $_))[1];
                                   ${$macroName.$pinName}{'use'} = $useType;
                                   if ( $useType eq "SIGNAL"  || $useType eq "signal") {  }
                                   elsif ( $useType eq "POWER" || $useType eq "power" ) { }
                                   elsif ( $useType eq "GROUND" || $useType eq "ground" ) { }
                                   elsif ( $useType eq "CLOCK" || $useType eq "clock" ) { } 
                                   else { print "WARN-PAR-LEF : 011 : unknown use for macro $macroName\n"; }
                             }# if USE
              if($_ =~ /END $pinName/){ 
                          if(exists ${$macroName.$pinName}{'use'} ) { } 
                          else {${$macroName.$pinName}{'use'} = "SIGNAL"; } # setting default USE in LEF
                                      } # if no USE till end of PIN
              if($_ =~ /^LAYER / ) { ($layerName)=(split(/\s+/,$_))[1]; 
                $macroNamePinNameLayerName =  $macroName.$pinName.$layerName;
                if ( exists ${$macroName}{$pinName}{$macroNamePinNameLayerName} ) {
                                                  } else {
                @{$macroNamePinNameLayerName} = ();
                ${$macroName}{$pinName}{$layerName} =\@{$macroNamePinNameLayerName};
                                                  }
                                   }#Layer
              if( $_ =~ /^RECT/) {
               push(@{$macroNamePinNameLayerName}, $_);
               my $data = "$layerName $_";
                                 }#Rect
#--------------------------------------Added by Mansi------------------------------------------------------#
              if($_ =~ /^POLYGON/){
                 $_ =~ s/;//;
                 push(@{$macroNamePinNameLayerName}, $_);
                 my $polygon_data = "$layerName $_";
                                  }#if Polygon
#----------------------------------------------------------------------------------------------------------#
                                                 #}#if between the PIN
                                                     }
              if(${$macroName}{$pinName}{'type'} eq "BUS") {
          if(/^PIN $busName\[$busBit\]/ ... /^END $busName\[$busBit\]/){
              if($_ =~ /DIRECTION/){ $dir = get_direction($_); 
                                   ${$macroName.$pinName}{'direction'} = $dir; 
                                   } # if DIRECTION
              if($_ =~ /USE/){ $useType = (split(/\s+/, $_))[1];
                                   ${$macroName.$busName.$busBit}{'use'} = $useType;
                                   if ( $useType eq "SIGNAL"  || $useType eq "signal") {  }
                                   elsif ( $useType eq "POWER" || $useType eq "power" ) {  }
                                   elsif ( $useType eq "GROUND" || $useType eq "ground" ) {  }
                                   elsif ( $useType eq "CLOCK" || $useType eq "clock" ) {  }
                                   else { print "WARN-PAR-LEF : 012 : unknown use for macro $macroName\n"; }
                               }# if USE
              if($_ =~ /END $pinName /){
                        if(exists ${$macroName.$pinName}{'use'}){}
                        else {${$macroName.$pinName}{'use'} = "BUS";}
                              } 
              if($_ =~ /^LAYER /) { ($layerName) = (split(/\s+/,$_))[1];
                 $macroNamePinNameLayerName = $macroName.$pinName.$layerName;
                 if ( exists ${$macroName}{$pinName}{$macroNamePinNameLayerName}){
                                               } else {
                @{$macroNamePinNameLayerName} = ();
                ${$macroName}{$pinName}{$layerName} = \@{$macroNamePinNameLayerName};
                                            }
                                          }
              if( $_ =~ /^RECT/){
                 push(@{$macroNamePinNameLayerName},$_);
                 my $data = "$layerName $_ ";
                           }
              if($_ =~ /^POLYGON/){
                 $_ =~ s/;//;
                 push(@{$macroNamePinNameLayerName}, $_);
                 my $polygon_data = "$layerName $_";
                                  }#if Polygon
                                                 }#if between the PIN
                                                     }
               }
         if(/\bOBS\b/ ... /\bEND\b/ ) {
                   if ( $_ =~ /^LAYER\b/ ) { $obsLayer = (split(/\s+/,$_))[1]; }
                   elsif ($_ =~ /^RECT\b/ ) { my $obsLine = "$obsLayer $_";
                                            }
                   elsif($_ =~ /^POLYGON/) { $_ =~ s/;//;
                                             my $obs_data = "$obsLayer $_";
                                           }#elsif obs
                                         }#if between the OBS statements
                                       } # between macro limits
}# while
#---------------------------------------------------------------functionality of lef--------------------------------------------------#
foreach my $macroName (keys %Class_Data){
  my $get_class = $Class_Data{$macroName};
  $Macro_Cnt{$get_class} += 1;
}
if(($total_layer_cnt > 0 || (%SITE_DATA)) && (!%Macro_Cnt)){
  if($return_in_xml == 1){
  $xmlout .= "\n";
  $xml->startTag('lef','type' => 'only tech lef file','total_layer' => $total_layer_cnt);
  $xmlout .= "\n";
  $xml->endTag();
  }else{
    print WRITE "\t\tonly tech lef file\n";
    print WRITE "\t\tTotal Layers = $total_layer_cnt\n";
  }
}elsif(($total_layer_cnt == 0)&& (!%SITE_DATA) && (%Macro_Cnt)){
  if($return_in_xml == 1){
    $xmlout .= "\n";
    $xml->startTag('lef','type' => 'only macro lef file');
  }else {
    print WRITE "\t\tonly macro lef file\n" ;
  }
  foreach my $cl (keys %Macro_Cnt){
    if($return_in_xml == 1){
      $xmlout .= "\n";
      $xml->startTag('class','class' => $cl,'macro_cnt' => $Macro_Cnt{$cl});
      $xml->endTag();
    }else {
      print WRITE "\t\t$cl = $Macro_Cnt{$cl}\n";
    }
  }
    if($return_in_xml == 1){
      $xmlout .= "\n";
      $xml->endTag();
    }
}elsif(($total_layer_cnt > 0 || (%SITE_DATA))&&(%Macro_Cnt)){
       my $total_macro = keys %Class_Data;
       if($return_in_xml == 1){
       $xmlout .= "\n";
       $xml->startTag(  'lef','type' => 'tech and macro both','Total_macro' => $total_macro,'Total_layer' => $total_layer_cnt)if($total_layer_cnt > 0);
       $xmlout .= "\n";
       $xml->endTag();
       }else {
         print WRITE "\t\ttech and macro both\n";
         print WRITE "\t\tTotal macro = $total_macro\n";
         print WRITE "\t\tTotal Layer = $total_layer_cnt\n"if($total_layer_cnt > 0);
       }
}
if($return_in_xml == 0){
  print WRITE "\t\tEnd reading the lef file\n";
}
}else { 
  if($return_in_xml == 0){
    print WRITE "\t\tWARN FILE DOES NOT EXISTS OR IS NOT READABLE.\n";
    return;
  }
}
}#sub read_lef_data
#----------------------------------------------------------------------------------------------------------#
sub get_direction {

    $direction = (split(/\s+/,$_[0]))[1];
 if($direction eq "INPUT" || $direction eq "input") { $direction = "input";}
 if($direction eq "OUTPUT" || $direction eq "output") { $direction = "output";}
 if($direction eq "INOUT" || $direction eq "inout") { $direction = "inout";}

return($direction);

}# sub get_direction
#-----------------------------------------------------------------------------------------------------------#
sub read_def_data {
my @arg = @_;
my $INPUT_DEF_FILE = $arg[-1];
my $READ_COMPONENTS = 1;
my $READ_NETS = 1;
my $READ_SPNETS = 1;
my $READ_PINS = 1;
my $READ_FLPLAN = 0;
my $READ_VIAS = 0;
my $READ_ROUTES = 1;
my $READ_BLKGS = 0;
my $line = "";
my %PORTS_ALREADY = ();
my $reading_spnets = 0;
my $reading_vias = 0;
my $reading_blkgs = 0;
my $net_data_start = 0;
my @die_data = ();
my @row_data = ();
my %PIN_PLACED_DATA = ();
my $pin_placed_status = 0;
my %COMP_PLACED_DATA = ();
my $inst_placed_status = 0;
my %NET_ROUTED_DATA = ();
my $net_routed_status = 0;
my %SNET_ROUTED_DATA = ();
my $sp_net_routed_status = 0;
my $TOP_MODULE ="";
my $READ_SPROUTES = 1;
my @pin_name_list = ();
my @comp_name_list = ();
my @net_name_list = ();
my @sp_net_name_list = ();
my @partial_placed = ();
my @partial_routed = ();
open(READ_DEF_FILE, "$INPUT_DEF_FILE");
if($return_in_xml == 0 ){
  print WRITE "\t\tBegin reading the def file\n";
}
#($reading_spnets, $reading_vias, $reading_components ) = 0;
my $lineCount = 0;
while(<READ_DEF_FILE>){
#if($STOP_IMMEDIATELY == 1) { last; }
$lineCount++;
if($lineCount =~ /0$/) { 
	#print "$lineCount\n";
	 }
else {}

chomp($_);
$_ =~ s/^\s+//;

if( $_ =~ /^\s*#/ ) { next; }
elsif(/^PROPERTYDEFINITIONS/ ... /END PROPERTYDEFINITIONS/) { next;}
else {
if( $_ =~ /^DESIGN\b/) {
         $TOP_MODULE = (split(/\s+/, $_))[1];
                    }

########################### Reading Dia Area Statement  ###############
elsif( $_ =~ /^DIEAREA /) {
                     ($DIEAREA_llx,$DIEAREA_lly,$DIEAREA_urx,$DIEAREA_ury) = (split(/\s+/, $_))[2,3,6,7];
                      push(@die_data,$DIEAREA_llx,$DIEAREA_lly,$DIEAREA_urx,$DIEAREA_ury);
                     $DIEAREA[0]=$DIEAREA_llx;
                     $DIEAREA[1]=$DIEAREA_lly;
                     $DIEAREA[2]=$DIEAREA_urx;
                     $DIEAREA[3]=$DIEAREA_ury;
                     $DIE_ALREADY{dieArea}=\@DIEAREA;
my $llx = $DIE_ALREADY{dieArea}[0];
my $lly = $DIE_ALREADY{dieArea}[1];
my $urx = $DIE_ALREADY{dieArea}[2];
my $ury = $DIE_ALREADY{dieArea}[3];
####################################################################
# set floorplan values for the partition in the FLOORPLAN_ALREADY DB
####################################################################
if ( $llx + $urx == 0 ) { $dieIsCentre = 1; } else { $dieIsCentre = 0;}
my $ASPECT_RATIO =  ($ury - $lly ) / ( $urx - $llx );
############### hardcoding temporarily ################
my $UTILIZATION =  0.70;
                     }# if dieArea  
########################### Reading Rows ##############################

elsif( $_ =~ /^ROW\s+/ ) {
                  ($rowName, $sitename, $x0, $y0, $orient,$numX,$numY,$spaceX,$spaceY) = (split(/\s+/, $_))[1,2,3,4,5,7,9,11,12];
                  push(@row_data,$rowName, $sitename, $x0, $y0, $orient,$numX,$numY,$spaceX,$spaceY);
                   my $rowdata = $rowName ." $sitename ".$x0." ".$y0." ".$orient." $numX $numY $spaceX $spaceY";
#print "row data $rowdata\n";
#                   print "reading $TOP_MODULE $rowName\n";
                         }

########################### Reading Tracks ##############################
elsif ( $_ =~ /^TRACKS/) { 
              my @track_data = split(/\s+/, $_);
              my $axis  = 0 ;
              my $start = 0;
              my $do    = 0;
              my $step  = 0;
              while( defined ($track_tag = shift @track_data)){
                     if($track_tag eq "TRACKS"){ # if first token is TRACK
                     $axis  = shift @track_data;
                     $start = shift @track_data;
                                 shift @track_data;
                     $do    = shift @track_data;
                                 shift @track_data;
                     $step  = shift @track_data;
                                 shift @track_data;
                                                }
                     elsif ( $track_tag eq ";" ) {}
                     else { 
   if ( exists $TECHNOLOGY_PHYSICAL{$track_tag} ){
                    $track_metal = TRACK.$track_tag; 
                    $track_metal_dir = TRACK.$track_tag.$axis; 

                    if( exists $DEF_TRACKS_ALREADY{$track_tag}) { }else{ %{$track_metal} = ();}
                    $DEF_TRACKS_ALREADY{$track_tag} = \%{$track_metal};
                    %{$track_metal_dir} = ();
                    if ( $axis eq "X" ){ ${$track_metal}{Vertical} = \%{$track_metal_dir}; }
                    elsif ( $axis eq "Y" ) { ${$track_metal}{Horizontal} = \%{$track_metal_dir}; }

                          ${$track_metal_dir}{start} = $start;
                          ${$track_metal_dir}{do} = $do;
                          ${$track_metal_dir}{step} = $step;

                                          } # if the track layer exists in the lef technology 
                          }
                          
                                                              }#while
                      }# if track statement
elsif( $_ =~ /^UNITS/ ) { my $DEF_DATABASE_UNIT = (split(/\s+/, $_))[3];
                        }

################# begin the PIN section ###################
elsif(/^PINS\b/ ... /^END PINS\b/){ if ( $READ_PINS == 0 ) { next; } else {
if($_ =~ /^PINS/){ if ( $READ_PINS ==1 ) { $line = ""; my $noOfPins = (split(/\s+/, $_))[1]; 
if($return_in_xml == 0){
  print WRITE "\t\tTotal Pins = $noOfPins\n"; 
}
next;
} else { next; }}
if($_ =~ /^END PINS/){ #print "INFO-PAR-DEF : 003 : End reading pins\n";
                       next;}
if($_ =~ /\;\s*$/){ if ( $READ_PINS ==1 ) {
chomp();
$_ =~ s/^\s+//;
$line = $line." ".$_; # end of line
$moduleName = $TOP_MODULE;
###########################################################
####    insert the code                                ####
###########################################################
  $line =~ s/^\s+//;
  @port_data = split(/\s+/, $line);
            shift @port_data;
            $pin_Name = shift @port_data;
            push(@pin_name_list,$pin_Name);
            if ( exists $PORTS_ALREADY{$moduleName}{$pin_Name} ) {
               print "WARN-PAR-DEF : 004 : multiple definition of the same pin ... keeping previous\n";
                                                                }
            else { #$PORTS_ALREADY{$moduleName}{$pin_Name} = PortDB::new(); 

    while ( defined ($data = shift @port_data) ) {
            if ( $data eq "NET" ) { $netName = shift @port_data;
                   #                $PORTS_ALREADY{$moduleName}{$pin_Name}->dbPortSetConn($netName);
                                  }
            elsif ( $data eq "DIRECTION" ) { my $pinDirection = shift @port_data; 
                                   if ( $pin_Name eq "port_pad_data_in[14]" ) { #print "INFO-PAR-DEF : 005 : $pin_Name : $pinDirection\n"; 
                                                                              }
                   #                $PORTS_ALREADY{$moduleName}{$pin_Name}->dbPortSetDir($pinDirection);
                                           }
            elsif ( $data eq "USE" ) { #$SIGNAL = shift @port_data;
                   #                $PORTS_ALREADY{$moduleName}{$pin_Name}->dbPortSetSignal($SIGNAL);
                                     }
            elsif ( $data eq "PLACED" || $data eq "FIXED" ){
            #elsif ( $data eq "PLACED") 
                                    $pin_placed_status = 1;
                                    $PIN_PLACED_DATA{$pin_Name} = $pin_placed_status;
                   #                $PORTS_ALREADY{$moduleName}{$pin_Name}->dbPortSetStatus($data);
                                   shift @port_data;
#                                   $dbX = shift @port_data;
#                                   $dbY = shift @port_data;
                                   shift @port_data;
                   #                $PORTS_ALREADY{$moduleName}{$pin_Name}->dbPortSetLoc($dbX,$dbY);
#                                   $side = shift @port_data;
                   #                $PORTS_ALREADY{$moduleName}{$pin_Name}->dbPortSetSide($side);
                                        }
            elsif ( $data eq "LAYER" ) { my $layer = shift @port_data; 
                                                  shift @port_data; # shift out open bracket
                                         my $x1 = shift @port_data;
                                         my $y1 = shift @port_data;
                                         shift @port_data;
                                         shift @port_data;
                                         my $x2 = shift @port_data;
                                         my $y2 = shift @port_data;
#                                        my $W = $x2 - $x1;
#                                         my $H = $y2 - $y1;
                   #                      $PORTS_ALREADY{$moduleName}{$pin_Name}->dbPortSetLayer($layer);
                   #                      $PORTS_ALREADY{$moduleName}{$pin_Name}->dbPortSetSize($W,$H);
                                       }
            else {}
                                                 }#while

                            #       $PORTS_ALREADY{$moduleName}{$pin_Name}->dbPortSetBus($pinToFrom);
                                 }

                    
###########################################################
####    stop inserting the code                        ####
###########################################################
        $line = ""; } else { next;}
                 }else{
         
if ( $READ_PINS ==1 ) {chomp(); $_ =~ s/^\s+//; $line = $line." ".$_; }else {next;} } # if line does not end loop
                                       }# if READ_PINS is equal to 1
                        } # PINS section
################# end the PIN section #####################
############## begin the COMPONENT section ################
elsif(/^COMPONENTS/ ... /^END COMPONENTS/){ if ( $READ_COMPONENTS == 0 ) { next; } else {
if($_ =~ /^COMPONENTS/) { my $noOfComponents = (split(/\s+/, $_))[1]; 
  if($return_in_xml == 0 ){
    print WRITE "\t\tTotal Components = $noOfComponents\n"; 
  }
}
if($_ =~ /^END COMPONENTS/) { #print "INFO-DEF : 007 : end components\n"; 
                            }
if($_ =~ /\;\s*$/){ $line = $line." ".$_; # end of line
###########################################################
####    insert the code                                ####
###########################################################
chomp;
$line =~ s/^\s+//;
if( $line =~ /-/){
 my($instance, $cellref) = (split(/\s+/, $line))[1,2];
   $instance =~ s/\\//g;
   push(@comp_name_list,$instance);
  %{$instance} = ();
#  $CADB{$instance} = CompAttDB::new();
#  $CADB{$instance}->dbCadbSetCellref($cellref);
#  $COMP_ALREADY{$instance} = \%{$instance};
  #print "DBG-PAR-DEF : 008 : $instance : $cellref " if ($DEBUG == 21);

##########################################################
####     getting the location of component            ####
##########################################################

  @comp_placement_data = split(/\s+/, $line);
    while ( defined ($placement_data = shift @comp_placement_data) ) {
            #if( $placement_data eq "PLACED" || $placement_data eq "FIXED" || $placement_data eq "UNPLACED")
            if( $placement_data eq "PLACED" || $placement_data eq "FIXED") {
                $inst_placed_status = 1;
                $COMP_PLACED_DATA{$instance} = $inst_placed_status;
#        $CADB{$instance}->dbCadbSetStatus($placement_data);
#        $CADB{$instance}->dbgCadbGetStatus if ($DEBUG == 21);
        shift @comp_placement_data;
#        $location_x = shift @comp_placement_data;
#        $location_y = shift @comp_placement_data;
#        $CADB{$instance}->dbCadbSetLoc($location_x,$location_y); 
#        $CADB{$instance}->dbgCadbGetLoc if ($DEBUG == 21); 
        shift @comp_placement_data;
#        $orientation = shift @comp_placement_data;
#        $CADB{$instance}->dbCadbSetOrient($orientation);
#        $CADB{$instance}->dbgCadbGetOrient if ($DEBUG == 21);
                                                                            } 
            elsif( $placement_data eq "HALO" ) {
        my ($deltaL, $deltaB, $deltaR, $deltaT) = @comp_placement_data;
        my $delta = "$deltaL $deltaB $deltaR $deltaT";
#        $FLOORPLAN_ALREADY{$FLOORPLAN_LOOKUP{"$TOP_MODULE/_self_"}}->dbFlplanAddHalo($instance, $delta);
                                                                            }
                                            }# while analyzing placement

        
#print "\n" if ($DEBUG == 21);
                 }else {
                       # is not a valid line
                       }
                    
###########################################################
####    stop inserting the code                        ####
###########################################################
        $line = "";
                 }else{
chomp();
$line = $line." ".$_; } # if line does not end loop
                        }
                        } # COMPONENT section
############## end the COMPONENT section ##################
################# begin the NET section ###################
elsif(/^\s*NETS / ... /^\s*END NETS /){
if( $READ_NETS == 0 ) { next; } else { 
chomp();
$_ =~ s/^\s+//;
#$_ =~ s/$\s+//;
if ($_ =~/^$/ ) { next; }
if( $_ =~ /^NETS/) { my $noOfNets = (split(/\s+/,$_))[1]; 
  if($return_in_xml == 0){
    print WRITE "\t\tTotal Nets = $noOfNets\n";
  }
 next;
}
if( $_ =~ /^END NETS/) { #print "INFO-PAR-DEF : 010 : end Nets \n"; 
                        next;}
if($_ =~ /^\-/){
$net_data_start = 1;
#print "DBG-PAR-DEF : 011 : $_\n" if ($DEBUG == 20);
@net_data = ();
###########################################################
####    insert the code                                ####
###########################################################
$netName = (split(/\s+/, $_))[1];
push(@net_name_list,$netName);
#print "DBG-PAR-DEF : 012 : $netName\n"if ($DEBUG == 10) ;
if ( !defined $NETS_ALREADY{$netName} ) {
#$NETS_ALREADY{$netName} = NetDB::new();
#$NETS_ROUTING_ALREADY{$netName} = NetRoutingDB::new();
#$NADB{$netName} = NetsAttrDB::new();
#$NADB{$netName}->dbNadbSetNetType(0);
                                        } else {
#   my $currType = $NADB{$netName}->dbNadbGetNetType;
#   if ( $currType == 1 ) { #$NADB{$netName}->dbNadbSetNetType(2); 
#                         }
                                               }
#push(@net_data,$_);

###########################################################
####    stop inserting the code                        ####
###########################################################
                 }
if (( $net_data_start == 1) && ($_ =~ /\;\s*$/)) {
my $abort_current_net = 0;
my $process_routes = 0;
#print "DBG-PAR-DEF : 013 : $_\n" if ($DEBUG == 21);
push(@net_data, $_);
my $num = @net_data;
#print "DBG-PAR-DEF : 014 : lines in net data are $num \n" if ($DEBUG == 20);
    while ( defined ($line = shift @net_data) ) {
          if ($abort_current_net == 1 ) { last; }
          if ($process_routes == 1 ) {
#----------------------------------------------------------------#
# process routing of the net                                     #
                if ($line =~ /ROUTED/) { $route_type = R; 
                                         $net_routed_status = 1;
                                         $NET_ROUTED_DATA{$netName} = $net_routed_status;
                                         $line =~ s/\+*\s+ROUTED\s+//;
                        #                 $NETS_ROUTING_ALREADY{$netName}->dbNetRoutingDBSetRegularRoute($line);
#                                         print "DBG-PAR-DEF : 015 : $line\n" if ($DEBUG == 23);  
                                         }
                elsif ($line =~ /FIXED/) { $route_type = F; print "DBG-PAR-DEF : 016 : $line\n" if ($DEBUG == 23);  }
                elsif ($line =~ /COVER/) { $route_type = C; print "DBG-PAR-DEF : 017 : $line\n" if ($DEBUG == 23);  }
                elsif ($line =~ /NEW/) { 
                                         $line =~ s/NEW\s+//;
                        #                 $NETS_ROUTING_ALREADY{$netName}->dbNetRoutingDBSetRegularRoute($line);
                                         #print "DBG-PAR-DEF : 018 : $line\n" if ($DEBUG == 23); 
                                         }
#----------------------------------------------------------------#
                                     }
          else {
          my  @net_data_per_line = split(/\s+/, $line);
          while ( defined ($data = shift @net_data_per_line) ) {
          if ($process_routes == 0 ) {
            if ( $data eq "(" ) {
                 $inst = shift @net_data_per_line;
   $inst =~ s/\\//g;
#print "DBG-PAR-DEF : 019 : $inst\n" if ($DEBUG == 22);
                 $pin = shift @net_data_per_line;
                 shift @net_data_per_line;
$NETS_ALREADY{$netName}{$inst} = $pin;
if(exists $COMP_ALREADY{$inst}) { $COMP_ALREADY{$inst}{$pin} = $netName;} 
elsif( $inst eq "PIN"){ }
else { #print "ERROR-PAR-DEF : 020 : $netName : $inst not found\n"; 
     }
                                }
             elsif ( $data =~ /\+/ ) {
                                     if ( $READ_ROUTES == 0 ) { $abort_current_net = 1; last; }
                                     else { 
                                           $process_routes = 1; 
                                           }# read the routing
                                     }
                                     }# if connectivity
           else {
#----------------------------------------------------------------#
# process routing of the net                                     #
                if ($line =~ /ROUTED/) { $route_type = R; 
                                         $net_routed_status = 1;
                                         $NET_ROUTED_DATA{$netName} = $net_routed_status;
                                         $line =~ s/\+*\s+ROUTED\s+//;
                        #                 $NETS_ROUTING_ALREADY{$netName}->dbNetRoutingDBSetRegularRoute($line);
#                                         print "DBG-PAR-DEF : 021 : $line\n" if ($DEBUG == 23);  
                                         last; }
                elsif ($line =~ /FIXED/) { $route_type = F; print "DBG-PAR-DEF : 022 : $line\n" if ($DEBUG == 23);  last; }

                elsif ($line =~ /COVER/) { $route_type = C; print "DBG-PAR-DEF : 023 : $line\n" if ($DEBUG == 23);  last; }
                elsif ($line =~ /NEW/) { 
                                         $line =~ s/NEW\s+//;
                        #                 $NETS_ROUTING_ALREADY{$netName}->dbNetRoutingDBSetRegularRoute($line);
#                                         print "DBG-PAR-DEF : 024 : $line\n" if ($DEBUG == 23); 
                                         last; }
                }#process routing
                                           }#while
                    }# if processing connectivity
                                           }#while
                    } # if line does not end loop
else {
#print "DBG-PAR-DEF : 025 : $_\n" if ($DEBUG == 20);
push(@net_data,$_);
     }
                              }# if READ_NETS is equal to 1
                            }# NETS section
################# end   the NET section ###################

################# parsing SPNET section ###################
elsif($_ =~ /^\s*SPECIALNETS/) { my $count = (split(/\s+/,$_))[1];
                            if($return_in_xml == 0){
                              print WRITE "\t\tTotal Special Nets = $count\n";
                            }
                            $reading_spnets = 1;
                            }
elsif($_ =~ /^\s*END SPECIALNETS/) { 
#                                   print "INFO-PAR-DEF : 027 : end special nets\n";
                                   $reading_spnets = 0; 
                                   }
elsif($_ =~ /^\s*VIAS/) { my $count = (split(/\s+/,$_))[1];
#                                   print "INFO-PAR-DEF : 028 : Reading $count vias\n";
                                   $reading_vias = 1;
                                   }
elsif($_ =~ /^\s*END VIAS/) { 
#                                   print "INFO-PAR-DEF : 029 : end vias\n";
                                   $reading_vias = 0;
                                   }
elsif($_ =~ /^\s*BLOCKAGES/) { my $count = (split(/\s+/,$_))[1];
                                  $block_line = "";
                                  $blockage_count_no = 0;
#                                   print "INFO-PAR-DEF : 030 : Reading $count blockages\n";
                                   $reading_blkgs = 1;
                                   }
elsif($_ =~ /^\s*END BLOCKAGES/) {
#                                   print "INFO-PAR-DEF : 031 : end blockages\n";
                                   $reading_blkgs = 0;
                                   }

elsif($reading_spnets == 1 && $READ_SPNETS == 1) {
###########################################################
####    read only the connectivity if present          ####
###########################################################
if($_ =~ /^\-/){
@net_data = ();
$netName = (split(/\s+/, $_))[1];
push(@sp_net_name_list,$netName);
#print "DBG-PAR-DEF : 032 : $netName\n" if ($DEBUG > 10);
if ( !defined $NETS_ALREADY{$netName} ) {
#$NETS_ALREADY{$netName} = NetDB::new();
#$NETS_ROUTING_ALREADY{$netName} = NetRoutingDB::new();
#$NADB{$netName} = NetsAttrDB::new();
#$NADB{$netName}->dbNadbSetNetType(1);
                                        } else {
#$NADB{$netName}->dbNadbSetNetType(2);
#$SNETS_ALREADY{$netName} = $NETS_ALREADY{$netName};
                                               }
#$SNETS_ALREADY{$netName} = $NETS_ALREADY{$netName};
push(@net_data,$_);
                 }
elsif ( $_ =~ /\;\s*$/ ) {
my $abort_current_net = 0;
my $process_routes = 0;
#print "DBG-PAR-DEF : 033 : $_\n" if ($DEBUG == 24);
push(@net_data, $_);
my $num = @net_data;
#print "DBG-PAR-DEF : 034 : lines in net data are $num \n" if ($DEBUG == 24);
    while ( defined ($line = shift @net_data) ) {
          if ($abort_current_net == 1 ) { last; }
          my  @net_data_per_line = split(/\s+/, $line);
          while ( defined ($data = shift @net_data_per_line) ) {
          if ($process_routes == 0 ) {
            if ( $data eq "(" ) {
                 $inst = shift @net_data_per_line;
   $inst =~ s/\\//g;
#print "DBG-PAR-DEF : 035 : $inst\n" if ($DEBUG == 24);
                 $pin = shift @net_data_per_line;
                 shift @net_data_per_line;
$NETS_ALREADY{$netName}{$inst} = $pin;
if ( $netName =~ /\*/ ) { } else {
if(exists $COMP_ALREADY{$inst}) { $COMP_ALREADY{$inst}{$pin} = $netName;}
elsif( $inst eq "PIN"){ }
elsif( $inst eq "\*") {}
else { #print "ERROR-PAR-DEF : 036 : $netName : $inst not found\n"; 
}
                                }
                                 }
             elsif ( $data =~ /\+/ ) {
                                     if ( $READ_SPROUTES == 0 ) { $abort_current_net = 1; last; }
                                     else {
                                           $process_routes = 1;
                                           }# read the routing
                                     }
                                     }# if connectivity
           else {
#----------------------------------------------------------------#
# process routing of the net                                     #
                if ($line =~ /ROUTED/) { $route_type = R;
                                         my $sp_net_routed_status = 1;
                                         $SNET_ROUTED_DATA{$netName} = $sp_net_routed_status;
                                         $line =~ s/\+*\s+ROUTED\s+//;
                                         #print "DBG-PAR-DEF : 037 : $netName : $line\n" if ($DEBUG == 24);
#                                         $NETS_ROUTING_ALREADY{$netName}->dbNetRoutingDBSetSpecialRoute($line);
                                         last; }
                #elsif ($line =~ /FIXED/) { $route_type = F; print "$line\n" if ($DEBUG == 24);  last; }
                elsif ($line =~ /FIXED/) { $route_type = F; 
                                           $line =~ s/\+*\s+FIXED\s+//;
                                         #  print "DBG-PAR-DEF : 038 : $netName : $line\n" if ($DEBUG == 24);
#                                           $NETS_ROUTING_ALREADY{$netName}->dbNetRoutingDBSetSpecialRoute($line);
                                           last; }
                elsif ($line =~ /COVER/) { $route_type = C; print "DBG-PAR-DEF : 039 : $line\n" if ($DEBUG == 24);  last; }
                elsif ($line =~ /NEW/) {
                                         $line =~ s/NEW\s+//;
                                         #print "DBG-PAR-DEF : 040 : $line\n" if ($DEBUG == 24);
#                                         $NETS_ROUTING_ALREADY{$netName}->dbNetRoutingDBSetSpecialRoute($line);
                                         last; }
#---------------------------------------Added by Mansi------------------------------------------------------------------#
               elsif ($line =~/RECT/){
                                      my $shape_stripe = "SHAPE STRIPE";
                                      $line =~ s/\+*\s+RECT\s+//;
                                      $line =~ s/\(//g;
                                      $line =~ s/\)//g;
                                      my ($metal_layer,$X1,$Y1,$X2,$Y2) = (split(/\s+/,$line))[0,1,2,3,4];
                                      my $width_1 = abs($X2 -$X1);
                                      my $width_2 = abs($Y2 -$Y1);
                                      if ($width_2 < $width_1 ){
                                       my $get_width = int ($width_2);
                                       my $new_y1 = int ($Y1+$get_width/2); 
                                       my $new_x1 = int ($X1);
                                       my $new_x2 = int ($X2);
                                       my $co_ord_1 = "( ".$new_x1." ".$new_y1." )";
                                       my $co_ord_2 = "( ".$new_x2." * )";
                                       my $new_line_data = $metal_layer." ".$get_width." + ".$shape_stripe." ".$co_ord_1." ".$co_ord_2;
#                                       $NETS_ROUTING_ALREADY{$netName}->dbNetRoutingDBSetSpecialRoute($new_line_data);
                                      }else {
                                       my $get_width = int ($width_1);
                                       my $new_x1 = int($X1+$get_width/2);
                                       my $new_y1 = int($Y1);
                                       my $new_y2 = int($Y2);
                                       my $co_ord_1 = "( ".$new_x1." ".$new_y1." )";
                                       my $co_ord_2 = "( * ".$new_y2." )";
                                       my $new_line_data = $metal_layer." ".$get_width." + ".$shape_stripe." ".$co_ord_1." ".$co_ord_2;
#                                       $NETS_ROUTING_ALREADY{$netName}->dbNetRoutingDBSetSpecialRoute($new_line_data);
                                      }
                                     } 
#-----------------------------------------------------------------------------------------------------------------------#
               elsif ($line =~ /USE/) {
                                        $line =~ s/\+*\s+USE\s+//;
#                                        $NETS_ROUTING_ALREADY{$netName}->dbNetSetType($line);
                                        last; }
                }#process routing
                                           }#while
                                           }#while
                    } # if line end
else { 
push(@net_data,$_);
     }

                                                 }#if reading spnets
elsif ($reading_vias == 1 && $READ_VIAS == 1 ) { next; }
elsif ($reading_vias == 1 && $READ_VIAS == 0 ) { next; }
elsif ($reading_blkgs == 1 && $READ_BLKGS == 1 ) {
  chomp();
  if ($_ =~ /^$/ || $_ =~ /^#/) {next;}
    $block_line = $block_line." ".$_;
    if($_ =~ /\;\s*$/){
        my $routing_blockage_found = 0;
        my $placement_blockage_found = 0;
     my @blockages_string = ();
#print "LINE iS $block_line\n";
      my @blkg_data = split(/\s+/,$block_line);
      my $BlkgName;
      while ( defined ($data = shift @blkg_data) ) {
        if ( $data eq "-" ){ $BlkgName = "Blkg".$blockage_count_no; @rect = (); 
        }
        elsif ( $data eq "LAYER" ) { my $layerName = shift @blkg_data;
          $routing_blockage_found = 1;
          push (@blockages_string, $layerName);
        }
        elsif ( $data eq "PLACEMENT" ) { 
          $placement_blockage_found = 1;
        }
        elsif ( $data eq "RECT" ) { shift @blkg_data; # shift out open bracket
          my $x1 = shift @blkg_data;
          my $y1 = shift @blkg_data;
          shift @blkg_data;
          shift @blkg_data;
          my $x2 = shift @blkg_data;
          my $y2 = shift @blkg_data;
          push (@blockages_string,$x1,$y1,$x2,$y2);
        } 
        else{}

     }#while
my $st = join ",", @blockages_string;
  if ($routing_blockage_found == 1) {
    #$FLOORPLAN_ALREADY{"$TOP_MODULE/_self_"}->dbFlplanAddRblkg($st);
  } else { 
    #$FLOORPLAN_ALREADY{"$TOP_MODULE/_self_"}->dbFlplanAddPblkg($st);
  }
$blockage_count_no++;
$block_line = "";
   }
#-------------------------------------------------------------#
                                                  }
elsif ($reading_blkgs == 1 && $READ_BLKGS == 0 ) {next;}
else{next;}
   }# if line is not commented out

}#while
#---------------------------------functionality of def identify--------------------------------------------#
if($#die_data != -1 && $#row_data != -1){
  if($return_in_xml == 1){
    $xmlout .= "\n";
    $xml->startTag('def','type' => 'floorplan def file'); 
    $xmlout .= "\n";
    $xml->endTag();
  }else {
    print WRITE "\t\tfloorplan def file\n";
  }
}
if((!%PIN_PLACED_DATA) && (!%COMP_PLACED_DATA)){
  if($return_in_xml == 1){
    $xmlout .= "\n";
    $xml->startTag('def','type' => 'unplaced def file');
    $xmlout .= "\n";
    $xml->endTag();
  }else {
    print WRITE "\t\tunplaced def file\n";
  }
}else{
      foreach my $pin_name (@pin_name_list){
        if(!exists $PIN_PLACED_DATA{$pin_name}){
           push(@partial_placed,$pin_name);
        }
      }
      foreach my $comp_name (@comp_name_list){
        if(!exists $COMP_PLACED_DATA{$comp_name}){
           push(@partial_placed,$comp_name);
        }
      } 
     if($#partial_placed == -1){
        if($return_in_xml == 1){
          $xmlout .= "\n";
          $xml->startTag('def','type' => 'placed def file');
          $xmlout .= "\n";
          $xml->endTag();
        }else {
          print WRITE "\t\tplaced def file\n";
        }
     }else {
            if($return_in_xml == 1){
              $xmlout .= "\n";
              $xml->startTag('def','type' => 'partial def file');
              $xmlout .= "\n";
              $xml->endTag();
            }else {
               print WRITE "\t\tpartial def file\n";
            }
     }
}
if((!%NET_ROUTED_DATA) && (!%SNET_ROUTED_DATA)){
  if($return_in_xml == 1){
    $xmlout .= "\n";
    $xml->startTag('def','type' => 'unrouted def file');
    $xmlout .= "\n";
    $xml->endTag();
  }else{
    print WRITE "\t\tunrouted def file\n";
  }
}else {
       foreach my $net_name(@net_name_list){
         if(!exists $NET_ROUTED_DATA{$net_name}){
           if(exists $SNET_ROUTED_DATA{$net_name}){
             my $net_routed = $SNET_ROUTED_DATA{$net_name};
             if($net_routed != 1){
               push(@partial_routed,$net_name);
             }
           }else{push(@partial_routed,$net_name);}
         }
       }
       foreach my $net_name(@sp_net_name_list){
         if(!exists $SNET_ROUTED_DATA{$net_name}){
            push(@partial_routed,$net_name);
         }
       }
    if($#partial_routed == -1){
       if($return_in_xml == 1){
         $xmlout .= "\n";
         $xml->startTag('def','type' => 'routed def file');
         $xmlout .= "\n";
         $xml->endTag();
       }else {
         print WRITE "\t\trouted def file\n";
       }
    }else{
          if($return_in_xml == 1){
            $xmlout .= "\n";
            $xml->startTag('def','type' => 'partial routed def file');
            $xmlout .= "\n";
            $xml->endTag();
          }else {
             print WRITE "\t\tpartial routed def file\n";
          }
    }
}
#-----------------------------------------------------------------------------------------------------#
if($return_in_xml == 0){
  print WRITE "\t\tEnd reading the def file\n";
}
#&set_inst_box;
}#sub read_def_data
#-----------------------------------------------------------------------------------------------------------------------------#
sub read_verilog_data{
my @arg = @_;
my $INPUT_VERILOG_FILE = $arg[-1];
open (READ_INPUT_VERILOG, "$INPUT_VERILOG_FILE");
if($return_in_xml == 0){
  print WRITE "\t\tBegin reading the verilog file\n";
}
my $count = 0;
my $scaled_count = 0;
my $line_count = 0;
my $verilogModuleCount = 0;
my $line = "";
my $comment_line = "";
my $i = 0;
my $list_of_lm_pointers = "";
my $cellref = "";
my $remainder = "";
my @nets = ();
my $NON_UNIQUE_INSTANCE_NAME = 0;
my $pinDirection = "";
my $pinName = "";
my $pinToFrom = "";
my $skip_comment = 0;
my $no_of_added_inst = 0 ;
my @module_list = ();
my @top_module_list = ();
my %MODULE_DATA = ();
my $top_module = "";
my $total_module = "";
my $progBarMax = `wc -l $INPUT_VERILOG_FILE`;
while(<READ_INPUT_VERILOG>) {
#---------------- printing the line number ----------------#
$count = $count + 1;
if ($count =~ /0000$/){ 
  #print "$count ...\n";
}
chomp($_);
if ($_ =~ /\/\*(.*)\*\//){
  $_ =~s/\/\*(.*)\*\///;
}
if (($skip_comment == 1) && ($_ !~ /\*\//)){
  next;
}
if (($_ =~ /\/\*/) && ($_ !~ /\*\//) ){
  $skip_comment = 1; 
  $_ =~s/\/\*(.*)//;
}
if (($skip_comment == 1) && ($_ =~ /\*\//)){
  $_ =~s/(.*)\*\///;
  $skip_comment = 0;
}
if($_ =~ /\/\//){
  $_ =~s/\/\/(.*)//;
}
if($_ =~ /\`define/){next; }
                else {
if($_ =~ /\bendmodule\b *$/){
                             $list_of_lm_pointers = "";
                            } else {
if($_ =~ /\;\s*$/){ $line = $line.$_;
                        #print "DBG-PAR-VERI : 001 : $line\n" if ($DEBUG == 101);
                

##################################################################################################
####       make array for geting the top level module                                         ####
##################################################################################################

if($line =~ /\bmodule\b/){$module_line = $line; $module_line =~ s/^\s*//; $module_line =~ s/\((.*)\)\;//; $module_line =~ s/\(/ \(/;
                         ($moduleName) = (split(/\s+/,$module_line))[1];
                         #print "DBG-PAR-VERI : 002 : reading module : $moduleName \n" if ($DEBUG == 101);
                         $no_of_added_inst = 0 ;
                         if ( exists $MODULE_ALREADY{$moduleName} ) { } else {
                         #$MODULE_ALREADY{$moduleName} = VNOM::new();
                                                                             }
                         push(@module_list,$moduleName);
			} else {
if($line =~ /\bassign\b/) {
                           my $assign_line = $line;
                           $assign_line =~ s/^\s*assign\s*//;
                           $assign_line =~ s/\s*\;\s*$//;
#------ Added by Rajeev ----#
#--- first find the assign buffer from the PLDB library
#--- find its input / output ports and area 
#--- replace the assign statement with the buffer ... if buffer does not exist then leave the assign statement
#my $assignBufName = $GLOBAL->dbfGlobalGetBufForAssign;
#if ( $assignBufName ne "" ) {
##   my $assignIn  = $GLOBAL->dbfGlobalGetBufForAssignIn();
##   my $assignOut = $GLOBAL->dbfGlobalGetBufForAssignOut();
###   my $power  = $GLOBAL->dbfGlobalGetBufForAssignPower();
##   my $gnd = $GLOBAL->dbfGlobalGetBufForAssignGnd();
#                           my ($left_expr ,$right_expr) = (split(/=/,$assign_line))[0,1];
#                           $left_expr =~ s/\s+//;
#                           $right_expr =~ s/\s+//;
#                           my @left_pins_or_nets_array = &array_of_blasted_expr($left_expr,$moduleName);
#                           my @right_pins_or_nets_array = &array_of_blasted_expr($right_expr,$moduleName);
#                           if($#left_pins_or_nets_array == $#right_pins_or_nets_array) {
#                             foreach my $temp_left_bit (@left_pins_or_nets_array){
#                               my $temp_right_bit = shift(@right_pins_or_nets_array);
#                               if(($temp_right_bit !~ /'b/) && ( $temp_left_bit !~ /'b/)) {
#                                 my $temp_assign_component_name = "bt_assign_buf"."_".$no_of_added_inst;
#                                 my $temp_assign_component_port_expr = "("."\.".$assignOut."(".$temp_left_bit.")".","."\.".$assignIn."(".$temp_right_bit.")".","."\.".$power."(1'b1".")".","."\.".$gnd."(1'b0".")".")" ;
#                                 $no_of_added_inst++;
#                                 my $temp_conn_line = $assignBufName." ".$temp_assign_component_name.$temp_assign_component_port_expr;
#                                 $temp_conn_line =~ s/^\s*//;
#                                 
#                                 $temp_conn_line =~ s/\(/ \(/;
#                                 print "\nDBG-PAR-VERI : 003 : Added conn line $temp_conn_line to module $moduleName" if ($DEBUG == 300);
##                                 $MODULE_ALREADY{$moduleName}->dbVNOMAddConn($temp_conn_line);
##                                 my $area = $MODULE_ALREADY{$moduleName}->dbVNOMGetArea;
##                                 my @size = $PLDB{$assignBufName}->dbMdbGetSize;
#                                 my $delA = $size[0]*$size[1];
#                                 $area = $area + $delA;
##                                 $MODULE_ALREADY{$moduleName}->dbVNOMSetArea($area);
##                                 $MODULE_ALREADY{$moduleName}->dbVNOMAddLeafInst($temp_assign_component_name);
##                                 $MODULE_ALREADY{$moduleName}->dbVNOMSetLeafInstCell($temp_assign_component_name,$assignBufName);
#                               }
#                             }
#                           }
##print "$line\n" if ($DEBUG == 101);
#                                  }#if assign buffer exists
#else {print "DBG-PAR-VERI : 004 : Skipping assign statement\n" if ($DEBUG == 101);}
                        } else {
if($line =~ /endmodule/){
#print "$line\n" if ($DEBUG == 101);
                            } else {
#### assumption that input and output lines will have only one pin / bus entry
if($line =~ /\b[i,o][n,u]t*p*o*ut\b/){  $line =~ s/^\s+//;
                                  if($line =~ /\[\s*\-*\s*[0-9]+\s*\:\s*\-*\s*[0-9]+\s*\]/){ # if the pin is a BUS
#-------------------- added extra space after the closing bracket --------------------- CLIENT #
                                    $line =~ s/\]/ /; $line =~ s/\[/ /; $line =~ s/\:/ /; $line =~ s/\,/ /g; $line =~ s/\;//;
                                    my @tempStringList =(split(/\s+/, $line));
                                    ($pinDirection,$pinFrom,$pinTo) = @tempStringList[0,1,2];
                                    $pinToFrom = "[".$pinFrom.":".$pinTo."]" ;
                                    foreach $pinName (@tempStringList[3 .. $#tempStringList]) {
     if ($pinDirection eq 'input' ) { #$MODULE_ALREADY{$moduleName}->dbVNOMAddInput($pinName); 
#                          $MODULE_ALREADY{$moduleName}->dbVNOMSetInputType($pinName, 1);
#                          $MODULE_ALREADY{$moduleName}->dbVNOMSetInputBits($pinName, $pinToFrom);
#                                     print "DBG-PAR-VERI : 005 : Adding input bus $pinName to $moduleName\n" if ($DEBUG == 300);
                                    }
     elsif ($pinDirection eq 'output' ) {# $MODULE_ALREADY{$moduleName}->dbVNOMAddOutput($pinName); 
#                          $MODULE_ALREADY{$moduleName}->dbVNOMSetOutputType($pinName, 1);
#                          $MODULE_ALREADY{$moduleName}->dbVNOMSetOutputBits($pinName, $pinToFrom);
                                     #print "DBG-PAR-VERI : 006 : Adding output bus $pinName to $moduleName\n" if ($DEBUG == 300);
                                        }
    elsif ($pinDirection eq 'inout' ) { #$MODULE_ALREADY{$moduleName}->dbVNOMAddBidi($pinName);
#                          $MODULE_ALREADY{$moduleName}->dbVNOMSetBidiType($pinName, 1);
#                          $MODULE_ALREADY{$moduleName}->dbVNOMSetBidiBits($pinName, $pinToFrom);
                                     #print "DBG-PAR-VERI : 007 : Adding inout bus $pinName to $moduleName\n" if ($DEBUG == 300);
                                        }
                                                                                           }

                                    }# if pin is type BUS
                                  else {
                                     $line =~ s/\,/ /g; $line =~ s/\;//;
                                     my @pins = split(/\s+/, $line);
                                     my $len = @pins;
                                     if ($len >= 2) { 
                                            $pinDirection =  shift @pins;
                                                      }
                                     else { print "WARN-PAR-VERI : 008 : syntax issue at line $count\n"; } 
     if ($pinDirection eq 'input' ) { 
                                      foreach $pinName ( @pins ) {
                                      #$MODULE_ALREADY{$moduleName}->dbVNOMAddInput($pinName); 
                                      #$MODULE_ALREADY{$moduleName}->dbVNOMSetInputType($pinName,0);
                                      #print "DBG-PAR-VERI : 009 : Adding input pin $pinName to $moduleName\n" if ($DEBUG == 300);
                                                                 }
                                     }
     elsif ($pinDirection eq 'output' ) {
                                      foreach $pinName ( @pins ) {
                                      #$MODULE_ALREADY{$moduleName}->dbVNOMAddOutput($pinName); 
                                      #$MODULE_ALREADY{$moduleName}->dbVNOMSetOutputType($pinName,0);
                                      #print "DBG-PAR-VERI : 010 : Adding output pin $pinName to $moduleName\n" if ($DEBUG == 300);
                                                                 }
                                      }
     elsif ($pinDirection eq 'inout' ) {
                                      foreach $pinName ( @pins ) {
                                      #$MODULE_ALREADY{$moduleName}->dbVNOMAddBidi($pinName);
                                      #$MODULE_ALREADY{$moduleName}->dbVNOMSetBidiType($pinName,0);
                                      #print "DBG-PAR-VERI : 011 : Adding output pin $pinName to $moduleName\n" if ($DEBUG == 300);
                                                                 }
                                      }

                                     } # if pin is type single
#print "$line\n" if ($DEBUG == 101);
                            } else {
if($line =~ /\bwire\b/){
  $line =~ s/^\s+//;
  if($line =~ /\[\s*\-*\s*[0-9]+\s*\:\s*\-*\s*[0-9]+\s*\]/){ # if the wire is a BUS
    $line =~ s/\]/ /; $line =~ s/\[/ /; $line =~ s/\:/ /; $line =~ s/\,/ /g; $line =~ s/\;//;
    my @tempStringList =(split(/\s+/, $line));
    my ($netFrom,$netTo) = @tempStringList[1,2];
    my $netToFrom = "[".$netFrom.":".$netTo."]" ;
    foreach my $netName (@tempStringList[3 .. $#tempStringList]) {
      if ((!exists $MODULE_ALREADY{$moduleName}->{ins}{$netName}) 
       && (!exists $MODULE_ALREADY{$moduleName}->{outs}{$netName})
       && (!exists $MODULE_ALREADY{$moduleName}->{bidis}{$netName})) {
#        $MODULE_ALREADY{$moduleName}->dbVNOMAddNet($netName); 
#        $MODULE_ALREADY{$moduleName}->dbVNOMSetNetType($netName,1);
#        $MODULE_ALREADY{$moduleName}->dbVNOMSetNetBits($netName,$netToFrom);
        #print "DBG-PAR-VERI : 012 : Adding Net bus $netName to $moduleName\n" if ($DEBUG == 300);
      }
    }
  }# if net is type BUS
#print "$line\n" if ($DEBUG == 101);
                        } else {
if($line =~ /^$/){
#print "$line\n" if ($DEBUG == 101);
		} else {
$line =~ s/^\s*//;

$line =~ s/\(/ \(/;
my ($cellref, $instance) = (split(/\s+/, $line))[0,1];
$MODULE_DATA{$cellref} = $instance;
#           $MODULE_ALREADY{$moduleName}->dbVNOMAddConn($line);

#print "$cellref $instance \n" if ($DEBUG == 101);
#if( exists $PLDB{$cellref}) {
          #print "INFO-2 : $instance : $cellref is a leaf instance in $moduleName\n";
#          my $area = $MODULE_ALREADY{$moduleName}->dbVNOMGetArea;
#          my @size = $PLDB{$cellref}->dbMdbGetSize;
#          my $delA = $size[0]*$size[1];
#         $area = $area + $delA;
#          $MODULE_ALREADY{$moduleName}->dbVNOMSetArea($area);
#          $MODULE_ALREADY{$moduleName}->dbVNOMAddLeafInst($instance);
#          $MODULE_ALREADY{$moduleName}->dbVNOMSetLeafInstCell($instance,$cellref);
#                            }
#elsif ( exists $MODULE_ALREADY{$cellref} ) {
#          $MODULE_ALREADY{$cellref}->dbVNOMAddParent($moduleName);
#          $MODULE_ALREADY{$moduleName}->dbVNOMAddHierInst($instance);
#          $MODULE_ALREADY{$moduleName}->dbVNOMSetHierInstCell($instance,$cellref);
#} else { # Black box or a module that is defined later in the file
#          $MODULE_ALREADY{$moduleName}->dbVNOMAddHierInst($instance);
#          $MODULE_ALREADY{$moduleName}->dbVNOMSetHierInstCell($instance,$cellref);
#          $MODULE_ALREADY{$cellref}= VNOM::new();
#          $MODULE_ALREADY{$cellref}->dbVNOMAddParent($moduleName);
          #print "setting $moduleName as parent of $cellref\n";
#                                            }
} # empty lines loop
} # wire loop
} # input output loop
} # endmodule loop
} # assign loop
} # module loop
#############################
## reset the line variable ##
#############################
$line = "";
               } else { $line = $line.$_; 
#                        #print "$line\n" if ($DEBUG == 101);
                        } # if line does not end loop
                        } # endmodule line loop
			} # commented line loop
} # while

#$progress->update($progBarMax);
close(READ_INPUT_VERILOG);
#------------------------------------functionality of verilog------------------------------------------------------------------------------#
foreach my $mod_name (@module_list){
  if(exists $MODULE_DATA{$mod_name}){
  }else {push(@top_module_list,$mod_name);
}
}
my $np = @top_module_list;
if($np == 1){$top_module = $top_module_list[0];}
else{
  if($return_in_xml == 0){
    print WRITE "\t\tWARN : there are more than 1 possible top modules, please pick the correct one from the list below\n";
    print join ",", @top_module_list; print "\n";
  }
}
$total_module = @module_list;
if($return_in_xml == 1){
  $xmlout .= "\n";
  $xml->startTag('verilog','type' => 'netlist');
  $xmlout .= "\n";
  $xml->endTag();
  $xmlout .= "\n";
  $xml->startTag('netlist','no of module' => $total_module,'top module' => $top_module);
  $xmlout .= "\n";
  $xml->endTag();
}else{
  print WRITE "\t\tNumber of modules = $total_module\n";
  print WRITE "\t\tTOP MODULE = $top_module\n";
}
if($return_in_xml == 0){
  print WRITE "\t\tFinished reading the verilog file\n";
}

##################################################################################################
####    finding the top module                                                                ####
##################################################################################################
#my @TOP = ();
#foreach my $mod (keys %MODULE_ALREADY) { 
##       my @parents =  $MODULE_ALREADY{$mod}->dbVNOMGetParent;
##       my $np = @parents;
##       print "number of parents of $mod are $np\n";
#       if ( $np == 0 ) { push(@TOP,$mod); }
#       elsif ( $np > 1 ) { print "INFO-PAR-VERI : 014 : $mod has $np parents \n"; }
#                              }
#my $nT = @TOP;
#if ( $nT == 1 ) { print "INFO-PAR-VERI : 015 : Setting top module as $TOP[0]\n"; 
##                  $CURRENT_MODULE = $TOP[0];
#                  $TOP_MODULE = $TOP[0];
#		  $GLOBAL->dbfGlobalSetTOP($TOP_MODULE);
#                }
#elsif ( $nT > 1 ) { print "WARN-PAR-VERI : 016 : there are more than 1 possible top modules, please pick the correct one from the list below\n";
#                    print join ",", @TOP; #print "\n";
#                  }
#else { print "ERROR-PAR-VERI : 017 : something is wrong with the verilog file\n"; }
#---------------------------------------------------------------------------#
#  debugging ##
#my @inputs  = $MODULE_ALREADY{$TOP_MODULE}->dbVNOMGetInput ;
#print join(", ", @inputs ); #print "\n";
#my @outputs  = $MODULE_ALREADY{$TOP_MODULE}->dbVNOMGetOutput ;

#&dbgSummaryModules;
}#sub read_verilog_data
#-----------------------------------------------------------------------------------------------------------------------------#
