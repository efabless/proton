#!/usr/bin/perl
use XML::Writer;
use IO::File;

################################## Color Hash #######################################
%HashCol=(0=>"Alice Blue", 1=>"aquamarine", 2=>"blue", 3=>"BlueViolet", 4=>"CadetBlue", 5=>"chartreuse", 6=>"chocolate", 7=>"CornflowerBlue", 8=>"cyan", 9=>"DarkGoldenrod", 10=>"dark khaki", 11=>"dark magenta", 12=>"dark olive green", 13=>"dark orange", 14=>"dark salmon", 15=>"DeepPink", 16=>"DodgerBlue", 17=>"ForestGreen", 18=>"gold", 19=>"GreenYellow", 20=>"HotPink", 21=>"IndianRed", 22=>"LawnGreen", 23=>"light blue", 24=>"light steel blue", 25=>"magenta", 26=>"maroon", 27=>"MediumBlue", 28=>"medium purple", 29=>"medium spring green", 30=>"OliveDrab", 31=>"orange", 32=>"PaleVioletRed", 33=>"peru", 34=>"pink", 35=>"PowderBlue", 36=>"purple", 37=>"red", 38=>"RosyBrown", 39=>"RoyalBlue", 40=>"SaddleBrown", 41=>"SeaGreen", 42=>"tan", 43=>"thistle", 44=>"turquoise", 45=>"violet", 46=>"wheat", 47=>"WhiteSmoke", 48=>"yellow", 49=>"YellowGreen" );

my %COLOR_HEX_MAP = (
	"Alice Blue" => '0xF0F8FF',
	"aquamarine" => '0x7FFFD4',
	"blue" => '0x0000FF',
	"BlueViolet" => '0x8A2BE2',
	"CadetBlue" => '0x5F9EA0',
	"chartreuse" => '0x7FFF00',
	"chocolate" => '0xD2691E',
	"CornflowerBlue"=> '0x6E95ED',
	"cyan"=> '0x00FFFF',
	"DarkGoldenrod" => '0xB8860B',
	"dark khaki" => '0xBDB76B',
	"dark magenta" => '0x8B008B',
	"dark olive green" => '0x556B2F',
	"dark orange" => '0xFF8C00',
	"dark salmon" => '0xE9967A',
	"DeepPink" => '0xFF1493',
	"DodgerBlue" => '0x1E90FF',
	"ForestGreen" => '0x228B22',
	"gold" => '0xFFD700',
	"GreenYellow" => '0xADFF2F',
	"HotPink" => '0xFF69B4',
	"IndianRed" => '0xCD5C5C',
	"LawnGreen" => '0x7CFC00',
	"light blue" => '0xADD8E6',
	"light steel blue" => '0xB0C4DE',
	"magenta" => '0xFF00FF',
	"maroon" => '0x800000',
	"MediumBlue" => '0x0000CD',
	"medium purple" => '0x9370D8',
	"medium spring green" => '0x00FA9A',
	"OliveDrab" => '0x6B8E23',
	"orange" => '0xFFA500',
	"PaleVioletRed" => '0xD87093',
	"peru" => '0xCD853F',
	"pink" => '0xFFC0CB',
	"PowderBlue" => '0xB0E0E6',
	"purple" => '0x800080',
	"red" => '0xFF0000',
	"RosyBrown" => '0xBC8F8F',
	"RoyalBlue" => '0x4169E1',
	"SaddleBrown" => '0x8B4513',
	"SeaGreen" => '0x2E8B57',
	"tan" => '0xD2B48C',
	"thistle" => '0xD8BFD8',
	"turquoise" => '0x40E0D0',
	"violet" => '0xEE82E',
	"wheat" => '0xF5DEB3',
	"WhiteSmoke" => '0xF5F5F5',
	"yellow" => '0xFFFF00',
	"YellowGreen" => '0x9ACD32',
);
#####################################################################################

my $file = $ARGV[0];
my $usrdir = $ARGV[1];

open(READ_TECH, "$file");
my $layerName = "";
my $macroName = "";
my $start_reading_tech_layers = 0; #
my $stop_reading_tech_lef = 0; #
my $start_reading_via_section = 0; #
my $start_reading_viarule_section = 0; #
my $start_reading_macro_lef = 0; #
my $start_reading_site = 0; #
my %LAYER_HASH = ();
my %LAYER_TYPE = ();
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
        $VDB{$viaName}->dbSetViaLayer($newViaLayerInstance);
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
      $VRDB{$viaruleName}->dbSetViaRuleLayer($newLayerInstance);
    }
    $newLayerInstance = "" ;
  }          
  if($_ =~ /^\s*LAYER/){
     if($start_reading_via_section == 0) {
       ($layerName)=(split(/\s+/,$_))[1]; 
       $start_reading_tech_layers = 1 ;
    } 
                       
    if($_ =~ /^\s*END $layerName / ) {
       $start_reading_via_section = 0; 
       $start_reading_tech_layers = 0;
    }
  }
  if($stop_reading_tech_lef == 0 && $start_reading_tech_layers == 1){
     if(/LAYER $layerName/ ... /END $layerName/){
         if($_ =~ /^\s*LAYER/){ 
            ($layerName)=(split(/\s+/,$_))[1];
            if(!exists $LAYER_HASH{$layerName}) {
               my $layerNum = keys %LAYER_HASH;
               $LAYER_HASH{$layerName} = $layerNum;
            }
         }elsif(($_ =~ /TYPE/)||($_ =~ /type/)){ 
            ($layerType)=(split(/\s+/,$_))[2];
            $LAYER_TYPE{$layerName} = $layerType;
         }else{next;}
     }# if between the same layer
  }# if reading only the technology portion
}#while reading 

my $xml_out = new IO::File(">$usrdir/lefLayers.xml");
my $xml = new XML::Writer(OUTPUT => $xml_out);
$xml->startTag("root");
$xml->startTag("lefdata");
foreach my $layer (keys %LAYER_HASH){
   my $num = $LAYER_HASH{$layer};
   my $type = $LAYER_TYPE{$layer};
   my $color = $HashCol{$num};
   my $hex_val = $COLOR_HEX_MAP{$color};
   if($type eq "CUT"){$type = "VIA";}
   $xml->startTag("layer");
   $xml->dataElement("num" => $num);
   $xml->dataElement("name" => $layer);
   $xml->dataElement("type" => $type);
   $xml->dataElement("color" => $hex_val);
   $xml->endTag();  	
}
$xml->endTag();  	
$xml->endTag();  	
$xml_out->close();




