#!/usr/bin/perl
my $word = "";
my $fileName = "";
for(my $i =0; $i <= $#ARGV; $i++){
  if($ARGV[$i] eq "-w"){$word = $ARGV[$i+1];}
  if($ARGV[$i] eq "-file"){$fileName = $ARGV[$i+1];}
}
use XML::Writer;
my $xml = new XML::Writer(OUTPUT => \$xml_output);
$xml->startTag("root");
$xml_output .= "\n";
open (READ,"$fileName");
my $match_found =0;
my $prev_line = "";
my $word_cnt = 0;
my %DATA_WORD = ();
while(<READ>){
chomp();
s/\s+$//g;
  if($match_found == 1){
    if($prev_line ne ""){
      $xml->startTag("before",
                    "line" => $prev_line);
      $xml->endTag();
    }
    $xml_output .= "\n";
    if($_ ne ""){
      $xml->startTag("after",
                   "line" => $_);
      $xml->endTag();
    }
    $xml_output .= "\n";
    $match_found =0;
    $prev_line = "";
  }
  if($_ =~ /$word/){
     $match_found = 1;
     $DATA_WORD{$word_cnt} = $_;
     $xml->startTag("matched",
                    "line" => $_);
     $xml->endTag();
     $xml_output .= "\n";
     $word_cnt++;
     }
  if($match_found == 0){
     $prev_line = $_;
  }
  elsif($match_found == 1){
     if($prev_line eq ""){
        my $before_word_cnt = $word_cnt-2;
        if(exists $DATA_WORD{$before_word_cnt}){
          $prev_line = $DATA_WORD{$before_word_cnt};
        }
     }
  }
}
$xml->endTag(); 
open($xml_new,">data.xml");
print $xml_new "$xml_output\n";
#-------------------------------------------------------------------------------#
