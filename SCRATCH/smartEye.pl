#!/usr/bin/perl -w
use Benchmark;
my $t0 = new Benchmark;

use XML::Writer;
use IO::File;

my %format_keywords = ("TYPE CUT" => "TECH_LEF",
                       "TYPE ROUTING" => "TECH_LEF",
                       "TYPE MASTERSLICE" => "TECH_LEF",
                       "TYPE OVERLAP" => "TECH_LEF",
                       "PITCH" => "TECH_LEF",
                       "WIDTH" => "TECH_LEF",
                       "SPACING" => "TECH_LEF",
                       "DIRECTION HORIZONTAL" => "TECH_LEF",
                       "DIRECTION VERTICAL" => "TECH_LEF",
                       "SAMENET" => "TECH_LEF",

                       "MACRO" => "MACRO_LEF",
                       "CLASS" => "MACRO_LEF",
                       "FOREIGN" => "MACRO_LEF",
                       "ORIGIN" => "MACRO_LEF",
                       "SYMMETRY" => "MACRO_LEF",
                       #"PIN" => "MACRO_LEF", #also found in def
                       "USE POWER" => "MACRO_LEF",
                       "USE GROUND" => "MACRO_LEF",
                       #"USE SIGNAL" => "MACRO_LEF", #also found in def
                       #"DIRECTION INPUT" => "MACRO_LEF", #also found in def
                       #"DIRECTION OUTPUT" => "MACRO_LEF", #also found in def
                       #"DIRECTION INOUT" => "MACRO_LEF", #also found in def
                       "SHAPE ABUTMENT" => "MACRO_LEF",
                       "PORT" => "MACRO_LEF",

                       "cell" => "LIB",
                       "direction :" => "LIB",
                       "capacitance :" => "LIB",
                       "function :" => "LIB",
                       "internal_power" => "LIB",
                       "rise_power" => "LIB",
                       "fall_power" => "LIB",
                       "timing" => "LIB",
                       "related_pin" => "LIB",
                       "timing_sense" => "LIB",
                       "timing_type" => "LIB",
                       "when" => "LIB",
                       "sdf_cond" => "LIB",
                       "cell_rise" => "LIB",
                       "rise_transition" => "LIB",
                       "cell_fall" => "LIB",
                       "fall_transition" => "LIB",
                       "rise_constraint" => "LIB",
                       "fall_constraint" => "LIB",

                       "DESIGN" => "DEF",
                       "DIEAREA" => "DEF",
                       "COMPONENTS" => "DEF",
                       "PINS" => "DEF",
                       "VIAS" => "DEF",
                       "SPECIALNETS" => "DEF",
                       "NETS" => "DEF",
                       "BLOCKAGES" => "DEF",
                       "GROUPS" => "DEF",

                       "module" => "VERILOG",
                       "endmodule" => "VERILOG",
                       "inputs" => "VERILOG",
                       "outputs" => "VERILOG",
                       "wire" => "VERILOG",

                       "always" => "RTL",

                       ".subckt" => "SPICE",
                       ".SUBCKT" => "SPICE",
                       ".ends" => "SPICE",
                       ".ENDS" => "SPICE",
                      );


my $fileList = $ARGV[0];
my @files = split(/\,/,$fileList);
my $isFileTagged = 0;

my $xml_output = new IO::File(">file_info.xml");
my $xml = new XML::Writer(OUTPUT => $xml_output);
$xml->startTag("root");

foreach my $file (@files){
  if($isFileTagged == 1){
  }else{
    if($file =~ /\.tar\.gz/){
    }elsif($file =~ /\.tgz/){
    }elsif($file =~ /\.tar\.bz2/){ 
    }elsif($file =~ /\.tbz/){ 
    }elsif($file =~ /\.tb2/){ 
    }elsif($file =~ /\.taz/){ 
    }elsif($file =~ /\.tar\.Z/){ 
    }elsif($file =~ /\.tlz/){ 
    }elsif($file =~ /\.tar\.lz/){ 
    }elsif($file =~ /\.txz/){ 
    }elsif($file =~ /\.tar\.xz/){ 
    }elsif($file =~ /\.zip/){ 
    }elsif($file =~ /\.ZIP/){ 
    }else{
    }
    my $type = &getFileType($file);
    $xml->startTag("file", "name"=>$file, "type"=>$type);
    $xml->endTag();
    #print"File: $file Type: $type\n";
    
  }
}
$xml->endTag();
$xml->end();
$xml_output->close();

my $t1 = new Benchmark;
my $td = timediff($t1, $t0);
print "smartEyeApp took:",timestr($td),"\n";

sub getFileType {
my $file = $_[0];
my $file_type = "UNKNOWN";
my %file_type_hash = ();
my %max_keyword_hash = ();
my %type_match = ();

if(-e $file){
  foreach my $keyword (keys %format_keywords){
    my $type = $format_keywords{$keyword};
    if(exists $max_keyword_hash{$type}){
       $max_keyword_hash{$type} += 1;
    }else{
       $max_keyword_hash{$type} = 1;
    }
    my $word_cnt = `grep -w "$keyword" $file | grep -cv "[//|#]"`;
    if($word_cnt > 0){
       if(exists $file_type_hash{$type}){
          $file_type_hash{$type} += $word_cnt;
          $type_match{$type} += 1;
       }else{ 
          $file_type_hash{$type} = $word_cnt;
          $type_match{$type} += 1;
       }
    }
  }
  if(exists $type_match{"TECH_LEF"} && exists $type_match{"MACRO_LEF"}){
     my $tech_keyword_matched = $type_match{"TECH_LEF"};
     my $max_tech_keyword = $max_keyword_hash{"TECH_LEF"};
     my $macro_keyword_matched = $type_match{"MACRO_LEF"};
     my $max_macro_keyword = $max_keyword_hash{"MACRO_LEF"};

     my $tech_key_per_match = $tech_keyword_matched*100/$max_tech_keyword;
     my $macro_key_per_match = $macro_keyword_matched*100/$max_macro_keyword;

     if($tech_key_per_match > 90 && $macro_key_per_match < 70){
        $file_type = "TECH_LEF";
     }elsif($tech_key_per_match < 70 && $macro_key_per_match > 90){
        $file_type = "MACRO_LEF";
     }elsif($tech_key_per_match > 70 && $macro_key_per_match > 70){
        $file_type = "TECH_MACRO_LEF";
     }
  }else{
     my @types = sort {$file_type_hash{$b} <=> $file_type_hash{$a}} keys %file_type_hash;
     $file_type = $types[0] if(@types > 0);
  }
  print "$file_type\n";
  return $file_type
}else{
  print"File $file does not exist\n";
  return 0;
}
}#sub getFileType
