#!/usr/bin/perl
use GDS2;
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

if($usrdir eq ""){$usrdir = ".";}
######################### Reading GDS file ###############################
my %LAYERS = ();
my %cell_hash = ();
my %temp_hash = ();

my $string_found = 0;
my $boundary_found = 0;
my $aref_found = 0;
my $sref_found = 0;


my $gds2File = new GDS2(-fileName=>"$file");
my ($string_name, $layer_name);
my ($sname, $sname1);
while ($gds2File->readGds2Record) {
  if($gds2File->isBgnstr){
     $string_found = 1;
     $string_name = "";
     #%temp_hash = ();
  }elsif($gds2File->isEndstr){
     #@{$LAYERS{$string_name}}= (keys %temp_hash)  if(keys %temp_hash > 0);
     $string_found = 0;
  }elsif($gds2File->isBoundary){
     $boundary_found = 1;
     $layer_name = "";
  }elsif($gds2File->isAref){
     $aref_found = 1;
     $sname = "";
  }elsif($gds2File->isSref){
     $sref_found = 1;
     $sname1 = "";
  }elsif($gds2File->isEndel){
     $boundary_found = 0;
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
           if(!exists $temp_hash{$layer_name}){
              $temp_hash{$layer_name} = 1;
           }
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
        }else{next;}
     }else{next;}
  }else{next;}
}#while

####################### Finding TOP Module ########################
my @keys = sort{$cell_hash{$a}<=>$cell_hash{$b}} (keys %cell_hash);
my $top_module = $keys[0];
%cell_hash = (); # making hash empty

my $xml_out = new IO::File(">$usrdir/gdsLayers.xml");
my $xml = new XML::Writer(OUTPUT => $xml_out);
$xml->startTag("root");
$xml->startTag("gdsdata");

#my @gds_layers = @{$LAYERS{$top_module}};
#foreach my $layer (@gds_layers){
my $cnt = 0;
foreach my $layer (keys %temp_hash){
   my $color = $HashCol{$cnt};
   my $hex_val = $COLOR_HEX_MAP{$color};
   $xml->startTag("layer");
   $xml->dataElement("num" => $layer);  
   $xml->dataElement("color" => $hex_val);  
   $xml->endTag();  	
   $cnt++;
}
$xml->endTag();  	
$xml->endTag();  	
$xml_out->close();


