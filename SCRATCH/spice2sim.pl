#!/usr/bin/perl 

################################ Reading spi file ##################################
my $fileName = "";
my $dir = "";
my @file_list = ();
my $new_file = "";
my @spifiles = ();
my $rpt_summary_footprint_file = 0;
my $rpt_fileName = "";
my $file_given = 0;
my $unit_in_micron = 0;
my $dir_given = 0;
for(my $i =0 ;$i<= $#ARGV;$i++){
if($ARGV[$i] eq "-dir"){$dir = $ARGV[$i+1];$dir_given = 1;}
if($ARGV[$i] eq "-file"){$fileName = $ARGV[$i+1];$file_given = 1;}
if($ARGV[$i] eq "--rpt_summary_footprint_file"){$rpt_fileName = $ARGV[$i+1];$rpt_summary_footprint_file = 1;}
if($ARGV[$i] eq "--micron"){$unit_in_micron = 1;}
}
if($rpt_summary_footprint_file == 1){
open(WRITE_RPT,">$rpt_fileName");
}
if($dir_given == 1){
  opendir(DIR, "$dir");
  @file_list = readdir(DIR);
  foreach my $filename (@file_list){
    if($filename eq "."|| $filename eq ".."){next;}
    $new_file = $dir."/".$filename; 
    @spifiles = `find  -L $new_file -name \\*\\.spi -o -name \\*\\.sp`;
    foreach my $file (@spifiles){
      chomp($file);
      #$file =~ s/.*\///;
      #my @new_file = (split(/\s+/,$file));
      &read_spi_and_get_function($file);
    }
  }
}
#-----------------------------------------------------------------------------------------------------------------------------------#
if($file_given == 1){
  @spifiles = `find  -L $fileName -name \\*\\.spi -o -name \\*\\.sp`; 
  foreach my $file (@spifiles){
    chomp($file);
    #$file =~ s/.*\///;
    #my @new_file = (split(/\s+/,$file));
    &read_spi_and_get_function($file);
  }
}
#-------------------------------------------------------------------------------------------------------------------------------------#
sub dec2bin { 
  my $num = $_[0];
  my $width = $_[1];
  my $str = unpack("B32", pack("N", shift)); 
  $str =~ s/^0+(?=\d)//;
  my @digits = split(//,$str);
  my $len_str = @digits;
  my $len_diff = $width - $len_str;
  for(my $i=0; $i<$len_diff; $i++){
     $str = "0".$str;
  }
  return $str;
}#sub dec2bin
#-------------------------------------------------------------------------------------------------------------------------------------#
sub bin2dec {
  return unpack("N", pack("B32", substr("0" x 32 . shift, -32)));
}
#-------------------------------------------------------------------------------------------------------------------------------------#
sub read_spi_and_get_function{
my $file_name = $_[0];
if((-e $file_name) && (-r $file_name)){
my $cellName = "";
my $read_data_of_subckt = 0;
my $end_data_of_subckt = 0;
my @get_data = ();
my %SPICE_DATA = ();
my $data_start = 0;
my $data_end =0;
my $data = "";
my @new_data = ();
my $mdata = "";
my @cell_data = ();
my @input = ();
my %INPUT = ();
my %OUTPUT = ();
my @input_list = ();
my @output_list = ();
open(READ,"$file_name");
while(<READ>){
chomp();
if($_ =~ /\*/){
next;
}
if($_ =~ /^\s*\.subckt/i){
$read_data_of_subckt = 1;
$end_data_of_subckt = 0;
s/^\s*\.(subckt|SUBCKT)\s*//;
@cell_data = (split(/\s+/,$_));
$cellName = shift(@cell_data);
}
if($_ =~ /^\s*\.end/i){
$end_data_of_subckt = 1;
$read_data_of_subckt = 0;
}
  if($read_data_of_subckt == 1 && $end_data_of_subckt == 0){
    if($_=~ /^\s*m\s*/i){
    $data = "";
    @new_data = ();
    $mdata = "";
    $data_start =1;
    $data_end =0;
    }if($_ =~ /^\s*c/i){
    $data_end =1;
    $data_start =0;
    }
    if($data_start == 1 && $data_end ==0){
      if($_=~ /^\s*m\s*/i){
      $data = $data." ".$_;
      }else {
      $data = $data." ".$_;
      }
      $data =~ s/^\s*//;
      @new_data = (split(/\s+/,$data));
      $mdata = shift (@new_data);
      @{$SPICE_DATA{$mdata}} = @new_data;
    }
  }
}# while read 
if($cellName eq ""){print "ERR:We are not getting cellName from .spi file\n";}
open(WRITE_SIM,">$cellName.sim");
foreach my $mdata (sort {$a cmp $b}keys %SPICE_DATA){
  my $width = "";
  my $length = "";
  my $new_width = "";
  my $new_height = "";
  my @data_new = @{$SPICE_DATA{$mdata}};
  foreach my $var(@data_new){
    my $one_meter = 1000000;
    if($var =~ /w/i){$width = (split(/=/,$var))[1];$width =~ s/u//i;
      if($unit_in_micron == 0){
        if($width =~/e/){my ($digit,$exp) = (split(/e/,$width))[0,1];
          if($exp =~/-/){my $num = (split(/-/,$exp))[1];
          my $new_num = 10**$num;
          $new_width = ($digit*$one_meter)/$new_num;
          }elsif($exp =~ /\+/){my $num = (split(/\+/,$exp))[1];
          my $new_num = 10**$num;
          $new_width = ($digit*$one_meter*$new_num);
          }
        }
      }else{$new_width = $width;}
    }
    if($var =~ /l/i){$length = (split(/=/,$var))[1];$length =~ s/u//i;
      if($unit_in_micron == 0){
        if($length =~/e/){my ($digit,$exp) = (split(/e/,$length))[0,1];
          if($exp =~ /-/){my $num = (split(/-/,$exp))[1];
          my $new_num = 10**$num;
          $new_length = ($digit*$one_meter)/$new_num;
          }elsif($exp =~ /\+/){my $num = (split(/\+/,$exp))[1];
          my $new_num = 10**$num;
          $new_length = ($digit*$one_meter*$new_num);
          }
        }
      }else{$new_length = $length;}
    }
  }
  my $data_new_var = join" ",@data_new;
  my ($drain,$gate,$source,$type) = (split(/\s+/,$data_new_var))[0,1,2,4];
  my $new_type = "";
  if($type =~ /n/i){$new_type = "n";}
  elsif($type =~ /p/i){$new_type = "p";}
  #else {$new_type = $type;}
  print WRITE_SIM "$new_type $gate $source $drain $new_length $new_width\n";
  foreach my $port (@cell_data){
  if(($port =~ /vdd/) || ($port =~ /VDD/) || ($port =~ /vss/) || ($port =~ /VSS/) || ($port =~ /gnd/) || ($port =~ /GND/)){}
  else {
    if($port eq $gate){
      push(@input,$port);
      foreach my $in (@input){
      $INPUT{$in} = 1;
      }
    }
    if((($port eq $drain) || ($port eq $source)) && ($port ne $gate)){
         push(@output,$port);
         foreach my $out (@output){
           $OUTPUT{$out} = 1;
         }
      }
    }
  }
}# foreach line 
foreach my $in (keys %INPUT){
  push (@input_list,$in);
}
foreach my $out (keys %OUTPUT){
  push (@output_list,$out);
}

################################ creating cmd file ##################################
open(WRITE_CMD,">$cellName.cmd");
print WRITE_CMD"stepsize 50\n";
foreach my $port (@cell_data){
  if(($port =~ /vdd/) || ($port =~ /VDD/)){
    print WRITE_CMD"h $port\n";
  }elsif(($port =~ /vss/)||($port =~ /VSS/) || ($port =~ /gnd/) || ($port =~ /GND/)){
    print WRITE_CMD"l $port\n";
  }
}
print WRITE_CMD"w @input_list @output_list\n";
print WRITE_CMD"logfile $cellName.log\n";
print WRITE_CMD"vector in @input_list\n";
my $total_input = @input_list;
my $num_input = $total_input ;
my $dec_num = 2**$num_input;
for(my $i=0; $i<$dec_num; $i++){
  my $bin_num = &dec2bin($i,$num_input);
  print WRITE_CMD"set in $bin_num\n";
  print WRITE_CMD"s\n"; 
}
print WRITE_CMD"exit\n";
#-----------------------------------------------------------------------------------------------------------------#
system("irsim scmos100.prm $cellName.sim -$cellName.cmd");
#-----------------------------------------------------------------------------------------------------------------#
my %char_hash = ("0"=>"A", "1"=>"B", "2"=>"C","3"=>"D","4"=>"E","5"=>"F","6"=>"G","7"=>"H","8"=>"I","9"=>"J","10"=>"K","11"=>"L","12"=>"M","13"=>"N","14"=>"O","15"=>"P","16"=>"Q","17"=>"R","18"=>"S","19"=>"T","20"=>"U","21"=>"V","22"=>"W","23"=>"X","24"=>"Y","25"=>"Z");
#-----------------------------------------------------------------------------------------------------------------#
 my %out_hash = ();
 open(READ,"$cellName.log");
 while(<READ>) {
 chomp();
 $_ =~ s/\|\s+//;
 if($_ =~ /time/ ) {next ;}
 foreach my $out (@output_list){
   my @binary = ();
   if($_ =~ /$out\=1/ ){
      my @line = split(/\s+/,$_);
      foreach my $input (@input_list){
        foreach my $value (@line){
          my ($in, $val) = (split(/\=/,$value))[0,1];
          if($input eq $in){
             push(@binary,$val);
             last;
          }#if input matching
        }#foreach line element
      }#foreach input
      my $bin = join "", @binary;
      my $dec = &bin2dec($bin);
      my @old_value = @{$out_hash{$out}};
      push(@old_value,$dec);
      @{$out_hash{$out}} = @old_value;
   }#if output matched
 }#foreach output
 }
 close READ;
#-----------------------------------------------------------------------------------------------------------------------------#
 open(WRITE,">$cellName.genlib");
 use Algorithm::QuineMcCluskey;
 my $width = @input_list;
 foreach my $key (keys %out_hash){
   my @value  = @{$out_hash{$key}};
   my $q = new Algorithm::QuineMcCluskey(
         width => $width,
         minterms => [@value],
         dontcares => [ ]
 );
   my @func = $q->solve;
   my $cnt = 0;
   foreach (@input_list){
     $func[0] =~ s/$char_hash{$cnt}/$_/g;
     $cnt++;
   }
    print WRITE "$key = @func\n";
    if($rpt_summary_footprint_file == 1){
    print WRITE_RPT "$cellName   $key = @func\n";
    }
 }
 close WRITE;
#---------------------------------------------------------------------------------------------------------------------------------#
}else {
  print "WARN FILE DOES NOT EXISTS $file_name OR IS NOT READABLE\n";
}
}#sub read_spi_and_get_function
#-------------------------------------------------------------------------------------------------------------------------------#
