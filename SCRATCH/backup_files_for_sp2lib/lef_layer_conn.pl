#!/usr/bin/perl 
#my @ARGV = @_;
my $INPUT_LEF_FILE = "";
my $READ_TECHNOLOGY_SECTION = "";
for (my $i = 0; $i <= $#ARGV; $i++){
  if($ARGV[$i]  eq "-lef"){$INPUT_LEF_FILE = $ARGV[$i+1];}
  if($ARGV[$i] eq "-tech"){$READ_TECHNOLOGY_SECTION = $ARGV[$i+1];}
}
&create_conn;
if($READ_TECHNOLOGY_SECTION eq ""){
#&read_lef_file("-lef", $INPUT_LEF_FILE); 
}else {
#&read_lef_file("-lef" ,$INPUT_LEF_FILE, "-tech", $READ_TECHNOLOGY_SECTION); 
}
#--------------------------------------------------------------------------------------------------------------------------------------------#
sub read_lef_file {
use Benchmark;
my $t0 = new Benchmark;

my $noOfArguments = @_;

if( $noOfArguments < 2 || $_[0] eq '-h') { print "Usage : read_lef -lef <input_lef> \n";
                           print "                 [-tech < only / also / dont>]\n";
                         }
if( $noOfArguments > 4 || $_[0] eq '-h') { print "Usage : read_lef -lef <input_lef> \n";
                           print "                 [-tech < only / also / dont>]\n";
                         }
if( $noOfArguments == 2 || $noOfArguments == 4 ) {

my $READ_TECHNOLOGY = "dont";

for(my $i = 0; $i < $noOfArguments; $i++){
if($_[$i] eq "-lef"){$INPUT_LEF = $_[$i+1];}
if($_[$i] eq "-tech"){$READ_TECHNOLOGY = $_[$i+1];}
                                         } # for
#$GLOBAL->dbfGlobalSetFileName($INPUT_LEF,$READ_TECHNOLOGY);
if ( (-e $INPUT_LEF) && (-r $INPUT_LEF) ){
print "INFO-PAR-LEF : 001 : $INPUT_LEF FILE EXISTS AND IS READABLE!\n";



#######################################################################################
####              read the technology from lef file                                ####
#######################################################################################

if($READ_TECHNOLOGY eq "only" || $READ_TECHNOLOGY eq "also"){
print "INFO-PAR-LEF : 002 : reading technology section from $INPUT_LEF\n";
print "INFO-PAR-LEF : 003 : If there are multiple site statement but read only one site statement \n";
open(READ_TECH, "$INPUT_LEF");
$stop_reading_tech_lef = 0;
#%TECHNOLOGY_PHYSICAL = ();
#%PTDB = ();
#%VDB = ();
#%VLDB =();
#%VRDB = ();
#%VRLDB = ();
my $newViaLayerInstance = "";
my $newLayerInstance = ""; 
my $viaName = "";
my $layerName = "";
my $macroName = "";
my $siteName = "";
my $start_reading_tech_layers = 0;
my $start_reading_via_section = 0;
my $start_reading_viarule_section = 0;
# fixed mantis issue 0000231 by Rajeev on 12/30/08
# issue when tech lef is read after macro lef then start_reading_macro_lef has to be initialised to zero
my $start_reading_macro_lef = 0;
my $start_reading_site = 0;
my $polygon_start = 0;
my $polygon_data = "";
my $obs_polygon_start = 0;
my $obs_polygon_data = "";
my %MACRO_DATA = ();
my @new_data = ();
while(<READ_TECH>){
chomp();
if($_ =~ /^\s*#/ ) { next ; }
if($_ =~ /\#/ ) { $_ =~ s/\s+#.*$//; }
$_ =~ s/\s+/ /g;
$_=~ s/\s+$//g;
if($_ =~ /^\s*MACRO/){
                  $stop_reading_tech_lef = 1;
                  $start_reading_via_section = 0;
                  $start_reading_viarule_section = 0;
                  $start_reading_site = 0;
                  $start_reading_macro_lef = 1;
                  ($macroName)=(split(/\s+/,$_))[1];
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
#                        $VDB{$viaName}->dbSetViaLayer($newViaLayerInstance);
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
#                            $VRDB{$viaruleName}->dbSetViaRuleLayer($newLayerInstance);
                          }
                          $newLayerInstance = "" ;
                        }          
if($_ =~ /^\s*LAYER/){
                     if ($start_reading_via_section == 0) {
                       ($layerName)=(split(/\s+/,$_))[1]; 
                       $start_reading_tech_layers = 1 ;
                    } 
                     
                      
                        
if($_ =~ /^\s*END $layerName / ) {
                     $start_reading_via_section = 0; 
                     $start_reading_tech_layers = 0;
                     }
                                          }
#---------------------------------#
# Technology SITE Section       #
#---------------------------------#
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
                                     print "INFO-PAR-LEF : 004 : class : $class\n";
                                   }
               elsif( $_ =~ /SIZE/ ) { ($width,$height) = (split(/\s+/,$_))[2,4];
                                        $height =~ s/\;//;
                                    $TECHNOLOGY_PHYSICAL{$siteName}{SIZE} = "$width $height"; 
                                    print "INFO-PAR-LEF : 005 : $siteName $class $width $height\n";
                                  }
## fixed the issue Mantis-0000161 by Rajeev
              if ( $_ =~ /END $siteName/ ) {
              if( $width > 0 && $height > 0 && $class =~ /core/i ) {
                                  if ( $class eq "CORE" || $class eq "core" ) {
#                                    my $smallestRowHeight = $GLOBAL->dbGlobalGetRowHeight;
                                    if (($smallestRowHeight == -1) || ($smallestRowHeight > $height )) {
#                                    $GLOBAL->dbGlobalSetRowHeight($height);
                                    print "INFO-PAR-LEF : 006 : setting $siteName the row heignt to $height\n";
                                                                        }
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
                        $TECHNOLOGY_PHYSICAL{$layerName} = \%{$layerName}; 
                        if(!exists $PTDB{$layerName}) {
                        my $layerNum = keys %PTDB;
#                        $PTDB{$layerName} = TechDB::new();
#                        $PTDB{$layerName}->dbTechSetLayerName($layerName);
#                        $PTDB{$layerName}->dbTechSetLayerNum($layerNum);
# changed by Rajeev, pick up color of the layer from Aditya's HashCol has for colors
#                        my $layerColor = $COLOR_TABLE{$layerNum};
                        my $layerColor = $HashCol{$layerNum};
#                        $PTDB{$layerName}->dbTechSetLayerColor($layerColor);
                        }
                     }
                     elsif(($_ =~ /TYPE/)||($_ =~ /type/)){ ($layerType)=(split(/\s+/,$_))[2];
                                       ${$layerName}{'TYPE'} = $layerType;
#                        $PTDB{$layerName}->dbTechSetLayerType($layerType);
                                     }
                     elsif($_ =~ /^\s*\bDIRECTION\b\s+/){ ($layerDirection)=(split(/\s+/,$_))[2];
                                       ${$layerName}{'DIRECTION'} = $layerDirection;
#                        $PTDB{$layerName}->dbTechSetLayerDir($layerDirection);
                                          }
                     elsif($_ =~ /^\s*\bWIDTH\b\s+/){
                           my @w =split(/\s+/, $_);
                           my $length = @w;
                           if($length == 4){
                           $layerWidth = $w[2];
                           ${$layerName}{WIDTH} = $layerWidth;
#                           $PTDB{$layerName}->dbTechSetLayerWidth($layerWidth);
                           } else{}
                                         }
                     elsif($_ =~ /\bPITCH/) { ($layerPitch)=(split(/\s+/,$_))[2];
                                       ${$layerName}{'PITCH'} = $layerPitch;
#                        $PTDB{$layerName}->dbTechSetLayerPitch($layerPitch);
                                          }
                     elsif($_ =~ /\bOFFSET/) { ($layerOffset)=(split(/\s+/,$_))[2];
#                        $PTDB{$layerName}->dbTechSetLayerOffset($layerOffset);
                                          }
                     elsif($_ =~ /\bSPACING/) { ($layerSpacing)=(split(/\s+/,$_))[2];
                                       if ( exists ${$layerName}{'SPACING'} ) { 
                                       print "INFO-PAR-LEF : 007 : eQAtor does not use Variable spacing rule .. ignoring data\n";
                                                                              }
                                       else {
                                       ${$layerName}{'SPACING'} = $layerSpacing;
#                        $PTDB{$layerName}->dbTechSetLayerSpacing($layerSpacing);
                                            }
                                          }
                     elsif($_ =~ /\bRESISTANCE/){ ($layerResistance)=(split(/\s+/,$_))[3];
                                       ${$layerName}{'RESISTANCE'} = $layerResistance;
#                                        $PTDB{$layerName}->dbTechSetLayerResistance($layerResistance);
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
#   if(/VIA $viaName/.../END $viaName/){
                 if($_ =~ m/VIA /){
                   ($viaName)= (split(/\s+/,$_))[1];
                   my $viaNum = keys %VDB;
#                   $VDB{$viaName} = ViaDB::new();
#                   $VDB{$viaName}->dbViaSetViaName($viaName);
#                   $VDB{$viaName}->dbViaSetViaNum($viaNum);
                   }elsif($_ =~/RESISTANCE/){
                       $p = (split(/\s+/,$_))[2];
#                       $VDB{$viaName}->dbSetViaResistance($p);
                   }elsif($_ =~ /LAYER/){
                       if($newViaLayerInstance){
#                       $VDB{$viaName}->dbSetViaLayer($newViaLayerInstance);
                   }
                        my($layer) = (split(/\s+/,$_))[2];
#                           $newViaLayerInstance = ViaLayerDB::new();
                        if($newViaLayerInstance){
#                           $newViaLayerInstance->dbSetViaLayerName($layer);
                   }
                   }elsif($_ =~ /^\s*\bRECT\b\s+/){
                         ($rect[0],$rect[1],$rect[2],$rect[3]) = (split(/\s+/,$_))[2,3,4,5];
                         if($newViaLayerInstance){
#                            $newViaLayerInstance->dbSetViaRect($rect[0],$rect[1],$rect[2],$rect[3]);                      
                   }                  
                   }
                   # }#if VIA /END
                 }#if
#-----------------------------------------VIARULE SECTION---------------------#
  if($stop_reading_tech_lef == 0 && $start_reading_viarule_section == 1){
                   if($_ =~ m/VIARULE /){
                      ($viaruleName) = (split(/\s+/,$_))[1];
                      my $viaruleNum = keys %VRDB; 
#                      $VRDB{$viaruleName}=ViaRuleDB::new();
#                      $VRDB{$viaruleName}->dbSetViaRuleName($viaruleName);
#                      $VRDB{$viaruleName}->dbSetViaRuleNum($viaruleNum);  
                      }elsif($_ =~ /LAYER/){
                      if($newLayerInstance) {
#                        $VRDB{$viaruleName}->dbSetViaRuleLayer($newLayerInstance);
                      }
                     my ($layerName) = (split(/\s+/,$_))[2];
#                      $newLayerInstance = ViaRuleLayerDB::new();
                      if($newLayerInstance) {
#                         $newLayerInstance->dbSetViaRuleLayerName($layerName);
                      }
                      }elsif($_ =~ /\bCUTSIZE\b/){
                         ($cutsize[0],$cutsize[1])= (split(/\s+/,$_))[2,3];
                         if($newLayerInstance){
#                           $newLayerInstance->dbSetViaRulecutsize($cutsize[0],$cutsize[1]);
                         }
                      }elsif($_ =~ /\bCUTSPACING\b/){
                            ($cutsp[0],$cutsp[1]) = (split(/\s+/,$_))[2,3];
                          if($newLayerInstance){
#                             $newLayerInstance->dbSetViaRulecutspacing($cutsp[0],$cutsp[1]);
                          }
                      }elsif($_ =~ /\bOVERHANG\b/){
                         ($overhang)= (split(/\s+/,$_))[2];
                        if($newLayerInstance){
#                           $newLayerInstance->dbSetViaOverhang($overhang);
                        }
                      }elsif($_ =~ /\bMETALOVERHANG\b/){
                         ($metal_over_hang) = (split(/\s+/,$_))[2];
                        if($newLayerInstance){
#                           $newLayerInstance->dbSetViaMetalOverhang($metal_over_hang);
                        } 
                      }elsif($_ =~ /\bENCLOSURE\b/){
                          ($e[0],$e[1]) = (split(/\s+/,$_))[2,3];
                        if($newLayerInstance){
#                           $newLayerInstance->dbSetViaRuleEnclosure($e[0],$e[1]);
                        }
                      }elsif($_ =~ /\bWIDTH\b/){
                         ($width[0],$width[1]) = (split(/\s+/,$_))[2,4];
                        if($newLayerInstance){
#                           $newLayerInstance->dbSetViaRuleWidth($width[0],$width[1]);
                        }
                      }elsif($_ =~ /DIRECTION/){
                         ($dir) = (split(/\s+/,$_))[2];
                        if($newLayerInstance) {
#                           $newLayerInstance->dbSetViaDir($dir);
                        }  
                      }elsif($_ =~ /SPACING/){
                         ($sp[0],$sp[1])= (split(/\s+/,$_))[2,4];
                        if($newLayerInstance) {
#                           $newLayerInstance->dbSetViaSpacing($sp[0],$sp[1]);
                        }
                      }elsif($_ =~ /RECT/){
                         ($rect[0],$rect[1],$rect[2],$rect[3]) = (split(/\s+/,$_))[2,3,4,5];
                        if($newLayerInstance) {
#                           $newLayerInstance->dbSetViaRuleRect($rect[0],$rect[1],$rect[2],$rect[3]);
                        }
                      }
  }#if
}# while
    
close(READ_TECH);
}# read the technology file




#######################################################################################
####              read the macro from lef file                                     ####
#######################################################################################
         #####  INITIALLIZE #####
@MACROS = (\%MACROS_ALREADY, \%MACROS_NEWADDED);
my $macroName = "";

if($READ_TECHNOLOGY eq "dont" || $READ_TECHNOLOGY eq "also"){
print "INFO-PAR-LEF : 008 : reading macro section from $INPUT_LEF\n";

open(READ_LEF, "$INPUT_LEF");
while(<READ_LEF>){
chomp;
$_ =~ s/^\s+//;
if($_ =~ /^\s*#/ ) { next ; }
if($_ =~ /\#/ ) { $_ =~ s/\s+#.*$//; }

if($_ =~ /^MACRO/){ ($macroName)=(split(/\s+/, $_))[1];
                                  $polygon_start = 0;
                                  $polygon_data = "";
                                  $obs_polygon_start = 0;
                                  $obs_polygon_data = "";
                                  @new_data = ();
                                  %{$macroName}=(); 
#                                  $MACROS_ALREADY{$macroName} = \%{$macroName};
#                                  $PLDB{$macroName} = MacroDB::new();
 ####    saving the attributes of the macro 
                                  $macroAttr = $macroName."Attr";
                                  %{$macroAttr} = ();
                                  $MACROS_ATTRIBUTE_ALREADY{$macroName} = \%{$macroAttr};
                                  $Name = "SHIVA_PIN_IS_UNSET";
                  }# if MACRO
if(/^MACRO $macroName/ ... /^END $macroName\s*$/){
          if($_ =~ /^SIZE/){($width,$height)=(split(/\s+/, $_))[1,3]; 
                             # $area = $width*$height;
                             # ${$macroName}{'area'} = $area;
#                             $PLDB{$macroName}->dbMdbSetSize($width,$height);

                             $MACROS_ATTRIBUTE_ALREADY{$macroName}{size} = "$width $height";
                             #print "$MACROS_ATTRIBUTE_ALREADY{$macroName}{size}\n";
                           }# if SIZE
          if($_ =~ /^CLASS/){
                             my @c =split(/\s+/, $_);
                             my $len = @c;
                             if ($len == 3) { $class=$c[1]; }
                             elsif ($len == 4) { $class=$c[1]." ".$c[2]; }
                             else {print "WARN-PAR-LEF : 009 : CLASS statement for $macroName has syntax problem\n";}
#                             $PLDB{$macroName}->dbMdbSetClass($class);
                           }# if CLASS
  #-----------------------------------------------------------Added by Mansi-----------------------------------------------#
          if($_ =~/\bFOREIGN\b/i){my ($foreignCellName,$foreign_x,$foreign_y,$foreign_orient) = (split(/\s+/,$_))[1,2,3,4];
#                                  $PLDB{$macroName}->dbMdbSetForeignCoords($foreign_x,$foreign_y);
                                 }
  #------------------------------------------------------------------------------------------------------------------------#
          if($_ =~ /^ORIGIN/){
                             ($xOrig,$yOrig)=(split(/\s+/, $_))[1,2];
#                             $PLDB{$macroName}->dbMdbSetOrigin($xOrig,$yOrig);
                           }# if ORIGIN
          if($_ =~ /^PIN/){($Name)=(split(/\s+/,$_))[1];
                            $polygon_start = 0;
                            $polygon_data = "";
                            @new_data = ();
            if($Name =~ /\[[0-9]+\]/){  $pinName = $Name; $Name =~ s/\]//;
                                        ($busName,$busBit)=(split(/\[/,$Name))[0,1];
                                        print "DBG-PAR-LEF : 010 : busName $busName busbit $busBit \n" if ($DEBUG == 1);
                                        $pinHash = $macroName.$pinName; 
                                        ${$macroName}{$pinName} = \%{$pinHash};
                                        ${$pinHash}{'type'} = "BUS";
                                        ${$pinHash}{'footprint'} = $busName;
                                        ${$pinHash}{'bit'} = $busBit;
#                               $PLDB{$macroName}->dbMdbAddPin($pinName);
#                               $PLDB{$macroName}->dbMdbAddPinBusBaseName($pinName,$busName);
#                               $PLDB{$macroName}->dbMdbAddPinBusBit($pinName,$busBit);
#                               $PLDB{$macroName}->dbMdbAddPinBusWidth($pinName,1);
                                        } # if BUS
                                   else { $pinName = $Name; $pinHash = $macroName.$pinName;
                                        ${$macroName}{$pinName} = \%{$pinHash};
                                        ${$pinHash}{'type'} = "SINGLE";
#                               $PLDB{$macroName}->dbMdbAddPin($pinName);
#                               $PLDB{$macroName}->dbMdbAddPinBusWidth($pinName,0);
                                        } # if NOT BUS
                          }# if PIN
          if($Name eq "SHIVA_PIN_IS_UNSET"){ } else {
          if(${$macroName}{$pinName}{'type'} eq "SINGLE"){
                                          #my $newpinName =~ s/\\\[/\\\\\[/;
                                          #my $newpinName =~ s/\\\]/\\\\\]/; 
          if(/^PIN $newpinName/ ... /^END $newpinName/){
              if($_ =~ /DIRECTION/){ #$dir = get_direction($_); 
                                   ${$macroName.$pinName}{'direction'} = $dir; 
                                   #$PLDB{$macroName}->dbMdbSetPinDir($pinName,$dir);
                                   #$direction = $PLDB{$macroName}->dbMdbGetPinDir($pinName);
                                   } # if DIRECTION
#------------------------------------------------------------------------------------------------------------------------#
#          if($_ =~ /\bANTENNAPARTIALMETALAREA\b/i){$PLDB{$macroName}->dbMdbSetAntennaFound($pinName,1);}
#          if($_ =~ /\bANTENNAPARTIALMETALSIDEAREA\b/i){$PLDB{$macroName}->dbMdbSetAntennaFound($pinName,1);}
#          if($_ =~ /\bANTENNAPARTIALCUTAREA\b/i){$PLDB{$macroName}->dbMdbSetAntennaFound($pinName,1);}
#          if($_ =~ /\bANTENNADIFFAREA\b/i){$PLDB{$macroName}->dbMdbSetAntennaFound($pinName,1);}
#          if($_ =~ /\bANTENNAMODEL\b/i){$PLDB{$macroName}->dbMdbSetAntennaFound($pinName,1);}
#          if($_ =~ /\bANTENNAGATEAREA\b/i){$PLDB{$macroName}->dbMdbSetAntennaFound($pinName,1);}
#          if($_ =~ /\bANTENNAMAXAREACAR\b/i){$PLDB{$macroName}->dbMdbSetAntennaFound($pinName,1);}
#          if($_ =~ /\bANTENNAMAXSIDEAREACAR\b/i){$PLDB{$macroName}->dbMdbSetAntennaFound($pinName,1);}
#          if($_ =~ /\bANTENNAMAXCUTCAR\b/i){$PLDB{$macroName}->dbMdbSetAntennaFound($pinName,1);}
#------------------------------------------------------------------------------------------------------------------------#
              if($_ =~ /\bUSE\b/){ $useType = (split(/\s+/, $_))[1];
                                   ${$macroName.$pinName}{'use'} = $useType;
                                   if ( $useType eq "SIGNAL"  || $useType eq "signal") { #$PLDB{$macroName}->dbMdbSetPinIsSignal($pinName);
                                                                                       }
                                   elsif ( $useType eq "POWER" || $useType eq "power" ) {# $PLDB{$macroName}->dbMdbSetPinIsPower($pinName); 
                                                                                        }
                                   elsif ( $useType eq "GROUND" || $useType eq "ground" ) { #$PLDB{$macroName}->dbMdbSetPinIsGround($pinName); 
                                                                                          }
                                   elsif ( $useType eq "CLOCK" || $useType eq "clock" ) { #$PLDB{$macroName}->dbMdbSetPinIsClock($pinName);
#####################################################################################################################################################
# if any macro has a pin that is attributed at USE CLOCK then the macro can be safely assumed in PLDB as function "flop"
#commenting following two lines, because cell function will be set in read_lib command only
											#$PLDB{$macroName}->dbMdbSetFunction("flop");
											#$PLDB{$macroName}->dbMdbSetType("seq");
                                                                                        }
                                   
#####################################################################################################################################################
                                   else { print "WARN-PAR-LEF : 011 : unknown use for macro $macroName\n"; }
                             }# if USE
              if($_ =~ /END $pinName/){ 
                 $polygon_start = 0;
                 $polygon_data = "";
                 @new_data = ();
                          if(exists ${$macroName.$pinName}{'use'} ) { } 
                          else {${$macroName.$pinName}{'use'} = "SIGNAL"; } # setting default USE in LEF
                                      } # if no USE till end of PIN
              if($_ =~ /^LAYER / ) { ($layerName)=(split(/\s+/,$_))[1]; 
                 $polygon_start = 0;
                 $polygon_data = "";
                $macroNamePinNameLayerName =  $macroName.$pinName.$layerName;
                if ( exists ${$macroName}{$pinName}{$macroNamePinNameLayerName} ) {
                                                  } else {
                @{$macroNamePinNameLayerName} = ();
                ${$macroName}{$pinName}{$layerName} =\@{$macroNamePinNameLayerName};
                                                  }
                                   }#Layer
              if( $_ =~ /^RECT/) {
                  $polygon_start = 0;
                  $polygon_data = "";
               push(@{$macroNamePinNameLayerName}, $_);
               my $data = "$layerName $_";
               $data =~ s/;//;
               push (@new_data,$data);
                  @{$MACRO_DATA{$macroName}{$pinName}} = @new_data;
               #$PLDB{$macroName}->dbMdbAddPinRect($pinName,$data);
                                 }#Rect
#--------------------------------------Added by Mansi------------------------------------------------------#
              if($_ =~ /^POLYGON/){
                 $polygon_start = 1;
                 $polygon_data = "";
              }
              if($polygon_start == 1){
                 if($_ =~ /\s*;\s*/){
                 push(@{$macroNamePinNameLayerName}, $_);
                 $polygon_data = $polygon_data." ".$_;
                 $polygon_data =~ s/;//;
                 my $polygon_layer_with_data = "$layerName $polygon_data";
                 #$PLDB{$macroName}->dbMdbAddPinPolygon($pinName,$polygon_layer_with_data); 
                 }else{
                 $polygon_data = $polygon_data." ".$_;
                 push(@{$macroNamePinNameLayerName}, $_);
                 }
                 #push(@{$macroNamePinNameLayerName}, $_);
                 #my $polygon_data = "$layerName $_";
              }#if Polygon
#----------------------------------------------------------------------------------------------------------#
                                                 }#if between the PIN
                                                     } # if SINGLE
          if(${$macroName}{$pinName}{'type'} eq "BUS") {
          if(/^PIN $busName\[$busBit\]/ ... /^END $busName\[$busBit\]/){
#             if($_ =~ /DIRECTION/){ ${$macroName.$pinName}{'direction'} = get_direction($_); } # if DIRECTION
              if($_ =~ /DIRECTION/){ $dir = get_direction($_); 
                                   ${$macroName.$pinName}{'direction'} = $dir; 
                 #                  $PLDB{$macroName}->dbMdbSetPinDir($pinName,$dir);
                                   } # if DIRECTION
#------------------------------------------------------------------------------------------------------------------------#
          #if($_ =~ /\bANTENNAPARTIALMETALAREA\b/i){$PLDB{$macroName}->dbMdbSetAntennaFound($pinName,1);}
          #if($_ =~ /\bANTENNAPARTIALMETALSIDEAREA\b/i){$PLDB{$macroName}->dbMdbSetAntennaFound($pinName,1);}
          #if($_ =~ /\bANTENNAPARTIALCUTAREA\b/i){$PLDB{$macroName}->dbMdbSetAntennaFound($pinName,1);}
          #if($_ =~ /\bANTENNADIFFAREA\b/i){$PLDB{$macroName}->dbMdbSetAntennaFound($pinName,1);}
          #if($_ =~ /\bANTENNAMODEL\b/i){$PLDB{$macroName}->dbMdbSetAntennaFound($pinName,1);}
          #if($_ =~ /\bANTENNAGATEAREA\b/i){$PLDB{$macroName}->dbMdbSetAntennaFound($pinName,1);}
          #if($_ =~ /\bANTENNAMAXAREACAR\b/){$PLDB{$macroName}->dbMdbSetAntennaFound($pinName,1);}
          #if($_ =~ /\bANTENNAMAXSIDEAREACAR\b/){$PLDB{$macroName}->dbMdbSetAntennaFound($pinName,1);}
          #if($_ =~ /\bANTENNAMAXCUTCAR\b/){$PLDB{$macroName}->dbMdbSetAntennaFound($pinName,1);}
#------------------------------------------------------------------------------------------------------------------------#
              if($_ =~ /USE/){ $useType = (split(/\s+/, $_))[1];
                                   ${$macroName.$busName.$busBit}{'use'} = $useType;
                                   if ( $useType eq "SIGNAL"  || $useType eq "signal") { #$PLDB{$macroName}->dbMdbSetPinIsSignal($pinName); 
                                                                                       }
                                   elsif ( $useType eq "POWER" || $useType eq "power" ) {# $PLDB{$macroName}->dbMdbSetPinIsPower($pinName); 
                                                                                        }
                                   elsif ( $useType eq "GROUND" || $useType eq "ground" ) { #$PLDB{$macroName}->dbMdbSetPinIsGround($pinName); 
                                                                                          }
                                   elsif ( $useType eq "CLOCK" || $useType eq "clock" ) { #$PLDB{$macroName}->dbMdbSetPinIsClock($pinName); 
                                                                                        }
                                   else { print "WARN-PAR-LEF : 012 : unknown use for macro $macroName\n"; }
                               }# if USE
              if($_ =~ /END $pinName /){
                 $polygon_start = 0;
                 $polygon_data = "";
                        if(exists ${$macroName.$pinName}{'use'}){}
                        else {${$macroName.$pinName}{'use'} = "BUS";}
                              } 
              if($_ =~ /^LAYER /) { ($layerName) = (split(/\s+/,$_))[1];
                 $polygon_start = 0;
                 $polygon_data = "";
                 $macroNamePinNameLayerName = $macroName.$pinName.$layerName;
                 if ( exists ${$macroName}{$pinName}{$macroNamePinNameLayerName}){
                                               } else {
                @{$macroNamePinNameLayerName} = ();
                ${$macroName}{$pinName}{$layerName} = \@{$macroNamePinNameLayerName};
                                            }
                                          }
              if( $_ =~ /^RECT/){
                 $polygon_start = 0;
                 $polygon_data = "";
                 push(@{$macroNamePinNameLayerName},$_);
                 my $data = "$layerName $_ ";
#                 $PLDB{$macroName}->dbMdbAddPinRect($pinName,$data);
                           }
#----------------------------------------------------Added by Mansi-----------------------------------------------------------------------#
              if($_ =~ /^POLYGON/){
                 $polygon_start = 1;
                 $polygon_data = "";
              }
              if($polygon_start == 1){
                 if($_ =~ /\s*;\s*/){
                 push(@{$macroNamePinNameLayerName}, $_);
                 $polygon_data = $polygon_data." ".$_;
                 $polygon_data =~ s/;//;
                 my $polygon_layer_with_data = "$layerName $polygon_data";
                 #$PLDB{$macroName}->dbMdbAddPinPolygon($pinName,$polygon_layer_with_data); 
                 }else{
                 $polygon_data = $polygon_data." ".$_;
                 push(@{$macroNamePinNameLayerName}, $_);
                 }
                 #push(@{$macroNamePinNameLayerName}, $_);
                 #my $polygon_data = "$layerName $_";
              }#if Polygon
#------------------------------------------------------------------------------------------------------------------------------------------#
                                                 }#if between the PIN
                                                     } # if BUS
                                                 }   # if the PIN statement is reached
                                               
              if(/\bOBS\b/ ... /\bEND\b/ ) {
                     $obs_polygon_start = 0;
                     $obs_polygon_data = "";
                   if ( $_ =~ /^LAYER\b/ ) { $obsLayer = (split(/\s+/,$_))[1]; 
                                             $obs_polygon_start = 0;
                                             $obs_polygon_data = "";}
                   elsif ($_ =~ /^RECT\b/ ) { $obsLine = "$obsLayer $_";
                                              #$PLDB{$macroName}->dbMdbAddObs($obsLine);
                                              $obs_polygon_start = 0;
                                              $obs_polygon_data = "";
                                            }
#----------------------------------------------------Added by Mansi-----------------------------------------------------------------------#
                   elsif($_ =~ /^POLYGON/) { 
                     $obs_polygon_start = 1;
                     $obs_polygon_data = "";
                   }
                   if($obs_polygon_start == 1){
                      if($_ =~ /\s*;\s*/){
                      $obs_polygon_data = $obs_polygon_data." ".$_;
                      $obs_polygon_data =~ s/;//;
                      my $polygon_obs_layer_with_data = "$obsLayer $obs_polygon_data";
                      #$PLDB{$macroName}->dbMdbAddObsPolygon($polygon_obs_layer_with_data); 
                      }else{
                      $obs_polygon_data = $obs_polygon_data." ".$_;
                      }
                      #my $obs_data = "$obsLayer $_";
                      #$PLDB{$macroName}->dbMdbAddObsPolygon($obs_data);
                   }#elsif obs
#-----------------------------------------------------------------------------------------------------------------------------------------#
                                         }#if between the OBS statements
                                            } # between macro limits
}# while
my $no_macro = 0; 
foreach $macro (keys%MACROS_ATTRIBUTE_ALREADY){
$no_macro++;}
print "INFO-PAR-LEF : 013 : TOTAL NO. OF MACROS --> $no_macro\n";
print "INFO-PAR-LEF : 014 : finshed reading macro section\n";
} # read MACRO also

#if($READ_TECHNOLOGY eq "only" || $READ_TECHNOLOGY eq "also"){
#print "INFO-PAR-LEF : 015 : Summary of technology section...\n";
##format STDOUT_TOP =
##LayerName   LayerNo   Direction       Type           Pitch     Width    Spacing
##--------    --------  --------       --------       --------  --------  --------
##.
##format STDOUT =
##@<<<<<<<<   @##       @<<<<<<<<<<    @<<<<<<<<<<   @##.###   @##.###   @##.###
##$layerName,  $Ln1,        $LD,         $LT,       $LP,       $LW,     $LS
##.
##write;
##&print_pldb_summary;}
##-------------------------------------------------------------------------#
##open(TEST,">eqator.log") or die "Can't open up myfile: $!\n";
#format TEST_TOP =
#LayerName   LayerNo   Direction       Type           Pitch     Width    Spacing
#--------    --------  --------       --------       --------  --------  --------
#.
#
#format TEST =
#@<<<<<<<<   @##       @<<<<<<<<<<    @<<<<<<<<<<   @##.###   @##.###   @##.###
#$layerName,  $Ln1,        $LD,         $LT,       $LP,       $LW,     $LS
#.
#&print_pldb_summary;}
#-------------------------------------------------------------------------#
return(%MACRO_DATA);
}
else { 
print "WARN-PAR-LEF : 016 : $INPUT_LEF FILE DOES NOT EXISTS OR IS NOT READABLE.\n";
return;
}

             }# if 2 arguments or more

my $t1 = new Benchmark;
my $td = timediff($t1, $t0);
print "Command read_lef took:",timestr($td),"\n";
}#sub read_lef_file
#-----------------------------------------------------------------------------------------------------------------------------------#
sub create_conn {
my %MACRO_DATA = &read_lef_file("-lef" ,$INPUT_LEF_FILE, "-tech", $READ_TECHNOLOGY_SECTION); 
foreach my $macroName (keys %MACRO_DATA){
  foreach my $pinName (keys %{$MACRO_DATA{$macroName}}){
    my @new_data = @{$MACRO_DATA{$macroName}{$pinName}};
    my $new = join ",",@new_data;
      print "NEW DATA $macroName $pinName $new\n"; 
    }
}
}#sub create_conn
