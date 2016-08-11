#!/usr/bin/perl
my $file = $ARGV[0];
use XML::Writer;
my $xml = new XML::Writer(OUTPUT => \$xml_output);
$xml->startTag("root");
$xml_output .= "\n";
$xml_output .= " ";
#--------------------------------------------------------------------#
$xml->startTag("layermap");
$xml_output .= "\n";
$xml_output .= "  ";
#--------------------------------------------------------------------#
$xml->startTag("pnr");
$xml_output .= "\n";
$xml_output .= "   ";
#--------------------------------------------------------------------#
my ($total_layer,$GET_LAYER_DATA,$GET_LAYER_TYPE) = &read_lef_tech($file);
my ($Hash_Col,$stipple_type) = &create_hashCol_for_layer;
my %HASH_COL = %$Hash_Col;
$xml->startTag("valid",
               "valid" => $total_layer);
$xml->endTag();
$xml_output .= "\n";
$xml_output .= "   ";  
#--------------------------------------------------------------------#
my %LAYER_DATA = %$GET_LAYER_DATA;
$xml->startTag("layer_data");
$xml_output .= "\n";
$xml_output .= "   ";                 
foreach my $layerNum (sort {$a <=> $b}keys %LAYER_DATA){
  $xml->startTag("layer",
                 "name" => $LAYER_DATA{$layerNum},"lefid" => $layerNum,"gdsname" => "","gdsid" => "","gdsdt" => "","oasisname" => "",
                 "oasisid" => "","oasisdt" => "","color" => $HASH_COL{$layerNum},"filltype"=> $stipple_type);
  $xml->endTag();
  $xml_output .= "\n";
  $xml_output .= "   ";                 
}
$xml->endTag();
$xml_output .= "\n";
$xml_output .= "  ";                 
#--------------------------------------------------------------------#
$xml->endTag();
$xml_output .= "\n";
$xml_output .= " ";
#--------------------------------------------------------------------#
$xml->endTag();
$xml_output .= "\n";
$xml_output .= "";  
#--------------------------------------------------------------------#
$xml->endTag();
open($xml_new,">layer.map.xml");
print $xml_new "$xml_output\n";
#-----------------------------------------------------------------------------------------------------------------------------------------------------------#
sub read_lef_tech {
my @arg = @_;
my $INPUT_LEF = $arg[-1];
if((-e $INPUT_LEF) && (-r $INPUT_LEF)){
open(READ_TECH,"$INPUT_LEF");
my $stop_reading_tech_lef = 0;
my $layerName = "";
my $siteName = "";
my $start_reading_tech_layers = 0;
my $start_reading_macro_lef = 0;
my $start_reading_site = 0;
my $start_reading_via_section = 0;
my $start_reading_viarule_section = 0;
my $total_layer = 0;
my %LAYER_DATA = ();
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
                  $stop_reading_tech_lef = 0;
                  $start_reading_via_section = 0;
                  $start_reading_viarule_section = 0;
                  $start_reading_site = 1;
                  $start_reading_macro_lef = 0;
                          }# if site
if (/^\s*SITE $siteName/ ... /END $siteName/ ) {
               next if ( $start_reading_macro_lef == 1 );
               if( $_ =~ /CLASS/ ) { $class = (split(/\s+/,$_))[2]; 
                                     $class =~ s/\;//;
                                   }
               elsif( $_ =~ /SIZE/ ) { ($width,$height) = (split(/\s+/,$_))[2,4];
                                        $height =~ s/\;//;
                                  }
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
       if(!exists $LAYER_DATA{$layerName}){
          my $layerNum = keys %LAYER_DATA;
          $LAYER_DATA{$layerNum} = $layerName;
          $total_layer++;
       }
     }
   }# if between the same layer
 }# if reading only the technology portion
}# while
close(READ_TECH);
return ($total_layer,\%LAYER_DATA);
}else {print "WARN FILE DOES NOT EXISTS OR IS NOT READABLE\n";}
}#sub read_lef_tech
#--------------------------------------------------------------------------------------------------------------------------------------------------#
sub create_hashCol_for_layer {
my %HASH_COL = ();
my $stipple_type = "";
%HASH_COL=(0=>"Alice Blue", 
           1=>"aquamarine",
           2=>"blue",
           3=>"BlueViolet",
           4=>"CadetBlue",
           5=>"chartreuse",
           6=>"chocolate", 
           7=>"CornflowerBlue",
           8=>"cyan", 
           9=>"DarkGoldenrod",
           10=>"dark khaki",
           11=>"dark magenta", 
           12=>"dark olive green",
           13=>"dark orange",
           14=>"dark salmon",
           15=>"DeepPink",
           16=>"DodgerBlue",
           17=>"ForestGreen",
           18=>"gold",
           19=>"GreenYellow", 
           20=>"HotPink", 
           21=>"IndianRed", 
           22=>"LawnGreen", 
           23=>"light blue",
           24=>"light steel blue", 
           25=>"magenta", 
           26=>"maroon",
           27=>"MediumBlue",
           28=>"medium purple", 
           29=>"medium spring green",
           30=>"OliveDrab", 
           31=>"orange",
           32=>"PaleVioletRed", 
           33=>"peru",
           34=>"pink",
           35=>"PowderBlue", 
           36=>"purple",
           37=>"red", 
           38=>"RosyBrown", 
           39=>"RoyalBlue", 
           40=>"SaddleBrown",
           41=>"SeaGreen", 
           42=>"tan",
           43=>"thistle",
           44=>"turquoise",
           45=>"violet",
           46=>"wheat",
           47=>"WhiteSmoke", 
           48=>"yellow", 
           49=>"YellowGreen" );
$stipple_type = "gray12";
return(\%HASH_COL,$stipple_type);
}#sub create_hashCol_for_layer
#--------------------------------------------------------------------------------------------------------------------------------------------------#
