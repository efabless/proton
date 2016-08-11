#!/usr/bin/perl 
my $fileName = "";
my $parameter_file = "";
my $file_given = 0;
my $unit_in_micron = 0;
my $combinational = 0;
my $sequential = 0;
my $block = 0;
my $set_case = 0;
my $dir = "";
my $dir_given = 0;
my %PORT_DATA = ();
my %TRANS_DATA = ();
my %INST_DATA = ();
my $pathName = ".";
my $output_dir = "";
my $overwrite = 0;
my $log_file = "error";
my $libfile = "";
my $clear_temp_files = 0;

for(my $i =0; $i<=$#ARGV;$i++){
  if($ARGV[$i] eq "-f"){$fileName = $ARGV[$i+1];$file_given =1;}
  if($ARGV[$i] eq "-d"){$dir = $ARGV[$i+1];$dir_given =1;}
  if($ARGV[$i] eq "-parameter_file"){$parameter_file = $ARGV[$i+1];}
  if($ARGV[$i] eq "-micron"){$unit_in_micron = 1;}
  if($ARGV[$i] eq "--block"){$block = 1;}
  if($ARGV[$i] eq "--set_case"){$set_case = 1;}
  if($ARGV[$i] eq "--sequential"){$sequential = 1;}
  if($ARGV[$i] eq "--combinational"){$combinational = 1;}
  if($ARGV[$i] eq "--output"){$output_dir = $ARGV[$i+1];}
  if($ARGV[$i] eq "--overwrite"){$overwrite = 1;}
  if($ARGV[$i] eq "--log"){$log_file = $ARGV[$i+1];}
  if($ARGV[$i] eq "-lib"){$libfile = $ARGV[$i+1];}
  if($ARGV[$i] eq "--clear_temp_files"){$clear_temp_files = 1;}
  if($ARGV[$i] eq "-help"){ print "Usage : -f <fileName>\n";
                            print "      : -d <dirName>\n"; 
                            print "      : -parameter_file <fileName>\n";
                            print "      : -micron\n";
                            print "      : --block\n";
                            print "      : --set_case\n";
                            print "      : --sequential\n";
                            print "      : --combinational\n";
                            print "      : --output <dirName\>\n";
                            print "      : --overwrite\n";
                            print "      : --log <fileName> or by default fileName is error.log\n"; 
                            print "      : -help\n";
                          }
}
#----------------------------------------------------------------#
if($dir_given == 1){
#----------------------------------------------------------------#
  if (-d $output_dir){
    if($overwrite == 1){
      print "WARN : 001 : $output_dir exists,overwriting existing file as instructed\n";
      system ("rm -rf *");
    }else {print "ERROR : 002 : $output_dir exists, Please change the output name or remove the existing file\n";
     exit;
    } 
  }#if dir exists
  open (WRITELOG,">$log_file.log");
  system ("mkdir $output_dir") if($output_dir ne "");
#----------------------------------------------------------------#
  #my @spifiles = `/usr/bin/find  -L $dir -name \\*\\.spi -o -name \\*\\.sp -o -name \\*\\.spx -o -name \\*\\.spx\\* ! -name \\*\\.pxi`;
  my @spifiles = `find  -L $dir -name \\*\\.spi -o -name \\*\\.sp -o -name \\*\\.spx -o -name \\*\\.spx\\* ! -name \\*\\.pxi ! -name \\*\\.pex`;
  foreach my $filename (@spifiles){
    #if($clear_temp_files == 1){system("ls * | grep -v .lib | xargs rm -rf");}
    if($clear_temp_files == 1){system("rm -rf *");}
    if($filename eq "."|| $filename eq ".."){next;}
      chomp($filename);
      my @dir_path = split(/\//,$filename);
      pop @dir_path;
      my $out_file_dir = join "/", @dir_path; 
      #print "file $filename | $out_file_dir\n";
      %PORT_DATA = ();
      %TRANS_DATA = ();
      %INST_DATA = ();
      if($block == 1){
        &write_block_lib($filename);
      }else{
        my $include_flat = &include_spi_files($filename);
        my $file_get = &get_flat_spi($include_flat);
        if($combinational == 1){
           &read_file($file_get);
        }else{
           my ($val1,$val2,$val3,$val4) = &get_sequential($file_get);
           if($file_get =~ /[1-9]v[1-9]v/){
             my $cell = &check_cellName($file_get);
             if($cell =~ /[1-9]v[1-9]v/){
               &read_file($file_get);
             }else{print "WARN : Please check cell name or file name\n";}
           }elsif($val1 eq "combi" && $val2 eq "" && $val3 eq "" && $val4 eq ""){
              &read_file($file_get, $out_file_dir);
           }elsif($val1 ne "" && $val2 ne "" && $val3 ne "" && $val4 eq "latch"){
               &read_file_for_latch($file_get,$val1,$val2,$val3);
           }elsif($val1 ne "" && $val2 ne "" && $val3 ne "" && $val4 eq "flop"){
               &read_file_for_flop($file_get,$val1,$val2,$val3);
           }else{print WRITELOG "$file_get\n";}
        }#else
      }#else
    }#foreach
    if($output_dir ne "" ){
      my @spilibfiles = `find  -L $pathName -name \\*\\.spi.lib -o -name \\*\\.sp.lib`;
      foreach my $file_Name (@spilibfiles){
        chomp($file_Name);
        my $cell = "";
        my $func_tion = "";
        open(READ,"$file_Name");
        while(<READ>){
          chomp($file_Name);
          if($_ =~ /^\s+\bcell\b\s+/){$cell = (split(/\s+/,$_))[2];
             $cell =~ s/\("//;
             $cell =~ s/"\)//;
          }#if
          if($_ =~ /^\s+\bfunction\b\s+/){}
        }#while reading file
        close (READ);
        if($cell == 3.2){
                         print WRITELOG "$file_Name\n";
                        }
        else {system("cp $file_Name $output_dir");}
      }#foreach 
    }#if output ne ""
}
#------------------------------------------------------------------------------------#
if($file_given == 1){
   %PORT_DATA = ();
   %TRANS_DATA = ();
   %INST_DATA = ();
   if($block == 1){
     &write_block_lib($fileName);
   }else{
      my $include_flat = &include_spi_files($fileName);
      my $file_get = &get_flat_spi($include_flat);
      if($combinational == 1){
         &read_file($file_get);
      }else{
         my ($val1,$val2,$val3,$val4) = &get_sequential($file_get);
         if($file_get =~ /[1-9]v[1-9]v/){
            my $cell = &check_cellName($file_get);
            if($cell =~ /[1-9]v[1-9]v/){
              &read_file($file_get);
            }else{print "WARN : Please check cell name or file name\n";}
         }elsif($val1 eq "combi" && $val2 eq "" && $val3 eq "" && $val4 eq ""){
            &read_file($file_get);
         }elsif($val1 ne "" && $val2 ne "" && $val3 ne "" && $val4 eq "latch"){
            &read_file_for_latch($file_get,$val1,$val2,$val3);
         }elsif($val1 ne "" && $val2 ne "" && $val3 ne "" && $val4 eq "flop"){
            &read_file_for_flop($file_get,$val1,$val2,$val3);
         }
      }
       if($libfile ne ""){ 
         my $spilibfile = `find  -L $pathName -name \\*\\.spi.lib -o -name \\*\\.sp.lib`;
         chomp($spilibfile);
         system ("mv $spilibfile $libfile.lib");
       }else {print "WARN : Please give output libfile name\n";
       }
     }#else
}#if file_given
#-----------------------------------------------------------------------------------#
sub read_file {
my $file = $_[0];
my $out_dir_path = $_[1];
my $out_file;
if($out_dir_path eq ""){$out_file = $file;}
else{$out_file = $out_dir_path."/".$file;}
my $cellName = "";
my $vdd_pri = "";
my $vdd_pri_val = "";
my $vdd_sec = "";
my $vdd_sec_val = "";
my $vss_name = "";
my $vss_val = "";
my $wp = "";
my $wn = "";
my $new_vdd_1 = "";
my $new_vdd_2 = "";
my $new_vss = "";
my @input_slew = ();
my @opcap = ();
my $end_data_of_subckt = 0;
my $read_data_of_subckt = 0;
my @get_data = ();
my @cell_data = ();
my %SPICE_DATA = ();
my $data_start = 0;
my $data_end =0;
my $cap_res_data = 0;
my @CAP_RES_DATA = ();
my $data = "";
my @new_data = ();
my $mdata = "";
my %INPUT = ();
my %OUTPUT = ();
my @input_list = ();
my @output_list = ();
my %RELATED_PIN_COND_HASH = ();
my $read_data_of_subckt_sp = 0;
my $index = 0;
my %input_index = ();
my %high_out_hash = ();
my %low_out_hash = ();
my $new_file_spice = "";
if((-e $file) && (-r $file)){
open(READ,"$file");
$file =~ s/.*\///;
$new_file_spice = $file."\.ngspice";
open(WRITE_NG,">$new_file_spice");
while(<READ>){
  chomp();
  s/\*.*$//;
  if($_ =~ /^\s+$/){next;}
  if($_ =~ /^\s*\.subckt/i){
    print WRITE_NG "$_\n";
    $read_data_of_subckt_sp = 1;
  }elsif($_ =~ /^\s*\.end/i){
    $read_data_of_subckt_sp = 0;
    print WRITE_NG "$_\n";
  }elsif($read_data_of_subckt_sp == 1){
    s/\$[A-Z]=(\d+.\d+)//g;
    #s/ \$X.*=.*\$Y.*=.*\$D.*=.*$//;
    print WRITE_NG "$_\n";
  }
}
close(WRITE_NG);
close(READ);
#-------------------------------------------------------------------------#
open(READ_SP,"$file");
my $previous_line = "";
my $next_line = "";
while(<READ_SP>){
chomp();
if($_ =~ /\*/){next;}
if($_ =~ /^\+/){
  s/\s+$//;
  s/^\+//;
  $previous_line = $previous_line." ".$_;
  next;
}
$next_line = $_;
if($previous_line =~ /^\s*\.subckt/i){
  $read_data_of_subckt = 1;
  $end_data_of_subckt = 0;
  $previous_line =~ s/^\s*\.(subckt|SUBCKT)\s*//;
  @cell_data = (split(/\s+/,$previous_line));
  $cellName = shift(@cell_data);
}
if($previous_line =~ /^\s*\.end/i){
  $end_data_of_subckt = 1;
  $read_data_of_subckt = 0;
}
if($read_data_of_subckt == 1 && $end_data_of_subckt == 0){
  if($previous_line=~ /^\s*m\s*/i){
    $data = "";
    @new_data = ();
    $mdata = "";
    $data_start =1;
    $data_end =0;
    $read_cell_data = 0;
    $cap_res_data = 0;
  }
  if($previous_line =~ /^\s*c/i){
    $data_end =1;
    $data_start =0;
    $cap_res_data = 1;
  }
  if($previous_line =~ /^\s*r/i){
    $data_end =1;
    $data_start =0;
    $cap_res_data = 1;
  }
  if($data_start == 1 && $data_end ==0){
    if($previous_line=~ /^\s*m\s*/i){
    $data = $data." ".$previous_line;
    }else {
    $data = $data." ".$previous_line;
    }
    $data =~ s/^\s*//;
    $data =~ s/=\s+/=/;
    @new_data = (split(/\s+/,$data));
    $mdata = shift (@new_data);
    @{$SPICE_DATA{$mdata}} = @new_data;
  }
  if($cap_res_data == 1){
     push(@CAP_RES_DATA, $previous_line);
  }
}
$previous_line = $next_line;
}#while
close(READ_SP);
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
  #foreach my $port (@cell_data){
  #  if(($port =~ /vdd/) || ($port =~ /VDD/) || ($port =~ /vss/) || ($port =~ /VSS/) || ($port =~ /gnd/) || ($port =~ /GND/) || ($port =~ /vdar_t/)){}
  #  else {
  #    if($cellName =~ m/mux/i){
  #       $INPUT{"a"} = 1 if(!exists $INPUT{"a"});
  #       $INPUT{"b"} = 1 if(!exists $INPUT{"b"});
  #       $INPUT{"sel_a"} = 1 if(!exists $INPUT{"sel_a"});
  #       $OUTPUT{"qp"} = 1 if(!exists $OUTPUT{"qp"});
  #       #if($port eq $gate || $port eq $source){
  #       #  $INPUT{$port} = 1 if(!exists $INPUT{$port});
  #       #}elsif($port eq $drain){
  #       #   $OUTPUT{$port} = 1 if(!exists $OUTPUT{$port});
  #       #}
  #    }else{
  #       if($port eq $gate){
  #         $INPUT{$port} = 1 if(!exists $INPUT{$port});
  #       }elsif((($port eq $drain) || ($port eq $source)) && ($port ne $gate)){
  #          $OUTPUT{$port} = 1 if(!exists $OUTPUT{$port});
  #       }
  #    }#if not mux
  #  }
  #}
}# foreach line 
foreach my $cap_res_line (@CAP_RES_DATA){
   print WRITE_SIM "$cap_res_line\n";
}
close(WRITE_SIM);

#--------------------------------------------------------------------------------------------------------#
my ($ref_in_port, $ref_out_port) = &get_input_output_list(&reduce_cap_and_reg($file));
%INPUT = %$ref_in_port;
%OUTPUT = %$ref_out_port;

foreach my $in (keys %INPUT){
  push (@input_list,$in);
  $input_index{$in} = $index;
  $index++;
}
foreach my $out (keys %OUTPUT){
  push (@output_list,$out);
}
#-----------------------------------------------------------------------------------------------------------------#
################################ creating cmd file ##################################
open(WRITE_CMD,">$cellName.cmd");
print WRITE_CMD"stepsize 50\n";
foreach my $port (@cell_data){
  if(($port =~ /vdd/) || ($port =~ /VDD/) || ($port =~ /vdar_t/i) || ($port =~ /vdio_t/i)){
    print WRITE_CMD"h $port\n";
  }elsif(($port =~ /vss/)||($port =~ /VSS/) || ($port =~ /gnd/) || ($port =~ /GND/)){
    print WRITE_CMD"l $port\n";
  }
}
print WRITE_CMD"w @input_list @output_list\n";
print WRITE_CMD"logfile $cellName.log\n";
print WRITE_CMD"vector input @input_list\n";
my $total_input = @input_list;
my $num_input = $total_input ;
my $dec_num = 2**$num_input;
for(my $i=0; $i<$dec_num; $i++){
  my $bin_num = &dec2bin($i,$num_input);
  print WRITE_CMD"set input $bin_num\n";
  print WRITE_CMD"s\n"; 
}
print WRITE_CMD"exit\n";
close(WRITE_CMD);
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
   #------------Added by Aditya -------------#
      my @values = @{$high_out_hash{$out}};
      push(@values,[@binary]);
      @{$high_out_hash{$out}} = @values;
      last;
   }else{
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
      my @values = @{$low_out_hash{$out}};
      push(@values,[@binary]);
      @{$low_out_hash{$out}} = @values;
      last;
   #-----------------------------------------#
   }
 }#foreach output
 }
 close (READ);
 #------------Added by Aditya -------------#
 foreach my $out (keys %high_out_hash){
   my @high_value = @{$high_out_hash{$out}};
   my @low_value = @{$low_out_hash{$out}};
   my %rel_pin_cond = ();
   for(my $i=0; $i<=$#high_value; $i++){
      my @high_in_val = @{$high_value[$i]};
      for(my $j=0; $j<=$#low_value; $j++){
          my @low_in_val = @{$low_value[$j]};
          my $count = 0; 
          my $related_pin_index;
          for(my $k=0; $k<=$#low_in_val; $k++){
             if($low_in_val[$k] != $high_in_val[$k]){
                $count++;
                $related_pin_index = $k;
             }
          }
          if($count == 1){
             #print "$out related_pin $input_list[$related_pin_index] @high_in_val\n";
             ###### storing the related pin value when output is high ###########
             
             if(exists $rel_pin_cond{$input_list[$related_pin_index]}){
                my @old_value = @{$rel_pin_cond{$input_list[$related_pin_index]}};
                push(@old_value, [@high_in_val]);
               @{$rel_pin_cond{$input_list[$related_pin_index]}} = @old_value;  
             }else{
               my @temp = ();
               push(@temp, [@high_in_val]);
               @{$rel_pin_cond{$input_list[$related_pin_index]}} = @temp;  
             } 

          }#if one input matching
      }#foreach low output value
   }#foreach high output value
   $RELATED_PIN_COND_HASH{$out} = \%rel_pin_cond;
 }#foreach output

#------------------------------------------------------------------------------------------------#
 open(WRITE,">$cellName.funcgenlib");
 use Algorithm::QuineMcCluskey;
 my $width = @input_list;
 foreach my $key (keys %out_hash){
   my @value  = @{$out_hash{$key}};
   my $q = new Algorithm::QuineMcCluskey(
         width => $width,
         minterms => [@value],
         dontcares => [ ]
 );
   my @func = ();
   @func = $q->solve;
   my $cnt = 0;
   foreach (@input_list){
     $func[0] =~ s/$char_hash{$cnt}\'/ ( ! $_ ) /g;
     $cnt++;
   }
   $cnt = 0;
   foreach (@input_list){
     $func[0] =~ s/$char_hash{$cnt}/ $_ /g;
     $cnt++;
   }
    if($func[0] eq ""){
      if($cellName =~/mux/i){
        if(@input_list == 3){
          for(my $i=0;$i<=$#input_list;$i++){
            my $in = $input_list[$i];
            if($in =~ /sel/i){
               my $in1 = $input_list[$i+1];
               my $in2 = $input_list[$i+2];
               my $mux1 = "( ".$in1." "." ( ! ".$in." ) )";
               my $mux2 = "( ".$in2." ".$in." )";    
               push (@func,$mux1,"+",$mux2);
               print WRITE "$key = @func\n";
            }#if $in eq sel                        
          }#for                                    
        }#if no of input == 3                      
      }#if cellname mux                            
    }else {                                       
     print WRITE "$key = @func\n";
    }
 }
 close (WRITE);
}else {
print "WARN : file does not exists\n";
}
#####################################################parameter file#############################################################
open(READ_PARA,"$parameter_file");
while(<READ_PARA>){
  chomp();
  if($_ =~ /vss/i){($vss_name,$vss_val) = (split(/=\s*/,$_))[0,1];}
  if($_ =~ /width\s*pmos/i){$wp = (split(/=\s*/,$_))[1];}
  if($_ =~ /width\s*nmos/i){$wn = (split(/=\s*/,$_))[1];}
  if($_ =~ /input\s*slew/i){s/\s*input\s*slew\s*=\s*//;@input_slew = (split(/\s+/,$_));}
  if($_ =~ /output\s*capacitance/i){s/\s*output\s*capacitance\s*=\s*//;@opcap = (split(/\s+/,$_));}
  if($_ =~ /vdd\s*sec/i){($vdd_sec,$vdd_sec_val) = (split(/=\s*/,$_))[0,1];}
  elsif($_ =~ /vdd/i){($vdd_pri,$vdd_pri_val) = (split(/=\s*/,$_))[0,1];}
}#while reading parameter file
close (READ_PARA);
##################################################write test bench##############################################################
my $ns = @input_slew;
my $nopcap = @opcap;
my $no_of_input = @input_list;
my $no_of_output = @output_list;
open(WRITE_LIB,">$cellName.genlib");
  print WRITE_LIB "LIBNAME typical\n"; 
  print WRITE_LIB "GATE $cellName 3.2\n";
  print WRITE_LIB "  index_1 @input_slew\n";
  print WRITE_LIB "  index_2 @opcap\n";
  foreach my $input_pin (@input_list){
    print WRITE_LIB "  PIN $input_pin NONINV input \n";
  }
  for(my $o =0;$o<$no_of_output;$o++){
      my $out = $output_list[$o];
      print WRITE_LIB "  PIN $out NONINV output \n";

      my $get_function = "";
      open(READ_FUNC,"$cellName.funcgenlib");
      while(<READ_FUNC>){
        chomp();
        if($_ =~ /$out\s+=/){
          $get_function = (split(/=\s*/,$_))[1];
        }
      }
      close(READ_FUNC);

      print WRITE_LIB "   function : $get_function\n"; 

      my %related_pin_hash = %{$RELATED_PIN_COND_HASH{$out}};
      foreach my $rel_pin (keys %related_pin_hash){
         print WRITE_LIB "   related_pin $rel_pin\n";
         my @conditions = @{$related_pin_hash{$rel_pin}};

         for(my $c=0; $c<=$#conditions; $c++){
             my @bits = @{$conditions[$c]}; 
             #if(@bits > 1){
             #   my ($cond, $sdf_cond) = get_cond_and_sdf_cond($rel_pin,\@bits,\@input_list);
             #   print WRITE_LIB "   condition : $cond\n";
             #   print WRITE_LIB "   sdf_cond : $sdf_cond\n";
             #}
             my @get_new_port_list = ();
             my @get_new_port_list1 = ();
             my $output_port = "";
             my $pwr_cnt = 0;
             my $dRise = "";
             my $dFall = "";
             my $dfall_in_volt = "";
             my $drise_in_volt = "";
             my $in_follow_out = "";
             my $type = "";
             my $p_join = "";
             my @drise_list = ();
             my @dfall_list = ();
             my @slewr_list = ();
             my @slewf_list = ();
             foreach my $port (@cell_data){
               if($port eq $out){
                  push(@get_new_port_list,"n3");
                  push(@get_new_port_list1, "n4");
                  $output_port = "n3";
               }elsif($port =~ /vd/i){
                  $pwr_cnt++;
                  if($pwr_cnt == 1){
                    push(@get_new_port_list,$vdd_pri);
                    push(@get_new_port_list1, $vdd_pri);
                  }elsif($pwr_cnt == 2){
                    push(@get_new_port_list,$vdd_sec);
                    push(@get_new_port_list1, $vdd_sec);
                  }
               }elsif($port =~ /vss/i){
                 push(@get_new_port_list,$vss_name);
                 push(@get_new_port_list1, $vss_name);
               }elsif($port =~ /\b$rel_pin\b/){
                  push(@get_new_port_list,"n2");
                  push(@get_new_port_list1,"n3");
                  my $related_pin_val = $bits[$input_index{$rel_pin}]; 
                  if($related_pin_val == 1){
                    $dRise = "rise=1"; $dFall="fall=1";
                    $type = $out."_noninv";
                    $dfall_in_volt = "vdd";
                    $drise_in_volt = "vss";
                    $in_follow_out = 1;
                  }else{
                    $dRise = "fall=1"; $dFall="rise=1";
                    $type = $out."_inv";
                    $dfall_in_volt = "vss";
                    $drise_in_volt = "vdd";
                    $in_follow_out = 0;
                  }
               }else{
                  if(exists $INPUT{$port}){
                     my $pin_val = $bits[$input_index{$port}]; 
                     if   ($pin_val == 0){push(@get_new_port_list,"vss"); push(@get_new_port_list1,"vss"); $p_join = $p_join."-".$port."_vss";}
                     elsif($pin_val == 1){push(@get_new_port_list,"vdd"); push(@get_new_port_list1,"vdd"); $p_join = $p_join."-".$port."_vdd";}
                  }
               }#if other than rel_pin & out
             }#foreach port of cell_data
             $p_join =~ s/^-//;
             #------------------------------------------------------------------------------------#
             for(my $i =0; $i<$ns;$i++){
                 for(my $j =0;$j<$nopcap;$j++){
                     my $input_slew_value = $input_slew[$i];
                     my $input_slew_value_with_unit = $input_slew[$i].""."e-9";
                     my $op_cap = $opcap[$j];
                     my $op_cap_with_unit = $opcap[$j].""."e-12";

                     #--------------- Writing testbench for dfall & slewf --------------------------#
                     open(WRITE,">$file-dfall-$rel_pin-$input_slew_value-$op_cap-$p_join-$type");
                     print WRITE ".title Fanout Versus Delay (TSMC)\n";
                     print WRITE "\n";
                     print WRITE ".param vdd=$vdd_pri_val\n";
                     if($vdd_sec_val eq ""){
                     print WRITE ".param vddsec=$vdd_pri_val\n";
                     }else{
                     print WRITE ".param vddsec=$vdd_sec_val\n";
                     }
                     print WRITE ".param vss=$vss_val\n";
                     print WRITE ".param wp=$wp\n";
                     print WRITE ".param wn=$wn\n";
                     print WRITE ".param vlo='0.2*vdd'\n";
                     print WRITE ".param vmid='0.5*vdd'\n";
                     print WRITE ".param vhi='0.8*vdd'\n";
                     print WRITE ".param opcap=$op_cap_with_unit\n";
                     print WRITE ".param inputslew=$input_slew_value_with_unit\n";
                     print WRITE ".param v0=vss\n";
                     print WRITE ".param v1=vss\n";
                     print WRITE ".param v2=vlo\n";
                     print WRITE ".param v3=vhi\n";
                     print WRITE ".param v4=vdd\n";
                     print WRITE ".param v5=vdd\n";
                     print WRITE ".param v6=vhi\n";
                     print WRITE ".param v7=vlo\n";
                     print WRITE ".param v8=vss\n";
                     print WRITE ".param v9=vss\n";
                     print WRITE ".param t0='inputslew*10/6*0.0'\n";
                     print WRITE ".param t1='inputslew*10/6*1.0'\n";
                     print WRITE ".param t2='inputslew*10/6*1.2'\n";
                     print WRITE ".param t3='inputslew*10/6*1.8'\n";
                     print WRITE ".param t4='inputslew*10/6*2.0'\n";
                     print WRITE ".param t5='inputslew*10/6*3.0'\n";
                     print WRITE ".param t6='inputslew*10/6*3.2'\n";
                     print WRITE ".param t7='inputslew*10/6*3.8'\n";
                     print WRITE ".param t8='inputslew*10/6*4.0'\n";
                     print WRITE ".param t9='inputslew*10/6*5.0'\n";
                     print WRITE ".nodeset v(n3)=vdd\n";
                     print WRITE ".nodeset v(n2)=$dfall_in_volt\n";
                     print WRITE "\n";
                     print WRITE "vdd vdd 0 vdd\n";
                     print WRITE "vddsec vddsec 0 vddsec\n";
                     print WRITE "vss vss 0   vss\n";
                     print WRITE "\n";
                     print WRITE "vin n2 vss pwl( \n";
                     print WRITE "+               t0   v0\n" if($in_follow_out == 0);
                     print WRITE "+               t1   v1\n" if($in_follow_out == 0);
                     print WRITE "+               t2   v2\n" if($in_follow_out == 0);
                     print WRITE "+               t3   v3\n" if($in_follow_out == 0);
                     print WRITE "+               t4   v4\n";
                     print WRITE "+               t5   v5\n";
                     print WRITE "+               t6   v6\n" if($in_follow_out == 1);
                     print WRITE "+               t7   v7\n" if($in_follow_out == 1);
                     print WRITE "+               t8   v8\n" if($in_follow_out == 1);
                     print WRITE "+               t9   v9\n" if($in_follow_out == 1);
                     print WRITE "+             )\n";
                     print WRITE "*.MODEL n NMOS\n";
                     print WRITE "*.MODEL p PMOS\n";
                     print WRITE "*.MODEL nd NMOS\n";
                     print WRITE "*.MODEL pd PMOS\n";
                     print WRITE "\n";
                     print WRITE "\n";
                     #----------------------------------------------------------------#
                     print WRITE ".include  /home/pathak/Testcase/unitTestCases/ngspice/imager.models.small\n";
                     print WRITE ".include $new_file_spice\n";
                     print WRITE "x$cellName @get_new_port_list $cellName\n";
                     print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
                     print WRITE "C1 $output_port 0 opcap\n";
                     print WRITE "\n";
                     print WRITE ".temp 85\n";
                     print WRITE ".tran 10p 500n\n";
                     print WRITE "\n";
                     print WRITE ".meas tran n2_first_fall when v(n2)=vmid fall=1\n" if($in_follow_out == 1);
                     print WRITE ".meas tran n2_first_rise when v(n2)=vmid rise=1\n" if($in_follow_out == 0);
                     print WRITE "\n";
                     print WRITE ".meas tran n3_first_fall when v(n3)=vmid fall=1\n";
                     print WRITE "\n";
                     print WRITE ".meas tran dfall trig v(n2) val=vmid $dFall\n";
                     print WRITE "+                targ v(n3) val=vmid fall=1\n";
                     print WRITE "\n";
                     print WRITE ".meas tran slewf trig v(n3) val=vhi fall=1\n";
                     print WRITE "+                targ v(n3) val=vlo fall=1\n";
                     print WRITE "\n";
                     print WRITE ".end\n";
                     close(WRITE);

                     #--------------- Writing testbench for drise & slewr --------------------------#
                     open(WRITE,">$file-drise-$rel_pin-$input_slew_value-$op_cap-$p_join-$type");
                     print WRITE ".title Fanout Versus Delay (TSMC)\n";
                     print WRITE "\n";
                     print WRITE ".param vdd=$vdd_pri_val\n";
                     if($vdd_sec_val eq ""){
                     print WRITE ".param vddsec=$vdd_pri_val\n";
                     }else{
                     print WRITE ".param vddsec=$vdd_sec_val\n";
                     }
                     print WRITE ".param vss=$vss_val\n";
                     print WRITE ".param wp=$wp\n";
                     print WRITE ".param wn=$wn\n";
                     print WRITE ".param vlo='0.2*vdd'\n";
                     print WRITE ".param vmid='0.5*vdd'\n";
                     print WRITE ".param vhi='0.8*vdd'\n";
                     print WRITE ".param opcap=$op_cap_with_unit\n";
                     print WRITE ".param inputslew=$input_slew_value_with_unit\n";
                     print WRITE ".param v0=vss\n";
                     print WRITE ".param v1=vss\n";
                     print WRITE ".param v2=vlo\n";
                     print WRITE ".param v3=vhi\n";
                     print WRITE ".param v4=vdd\n";
                     print WRITE ".param v5=vdd\n";
                     print WRITE ".param v6=vhi\n";
                     print WRITE ".param v7=vlo\n";
                     print WRITE ".param v8=vss\n";
                     print WRITE ".param v9=vss\n";
                     print WRITE ".param t0='inputslew*10/6*0.0'\n";
                     print WRITE ".param t1='inputslew*10/6*1.0'\n";
                     print WRITE ".param t2='inputslew*10/6*1.2'\n";
                     print WRITE ".param t3='inputslew*10/6*1.8'\n";
                     print WRITE ".param t4='inputslew*10/6*2.0'\n";
                     print WRITE ".param t5='inputslew*10/6*3.0'\n";
                     print WRITE ".param t6='inputslew*10/6*3.2'\n";
                     print WRITE ".param t7='inputslew*10/6*3.8'\n";
                     print WRITE ".param t8='inputslew*10/6*4.0'\n";
                     print WRITE ".param t9='inputslew*10/6*5.0'\n";
                     print WRITE ".nodeset v(n3)=vss\n";
                     print WRITE ".nodeset v(n2)=$drise_in_volt\n";
                     print WRITE "\n";
                     print WRITE "vdd vdd 0 vdd\n";
                     print WRITE "vddsec vddsec 0 vddsec\n";
                     print WRITE "vss vss 0   vss\n";
                     print WRITE "\n";
                     print WRITE "vin n2 vss pwl( \n";
                     print WRITE "+               t0   v0\n" if($in_follow_out == 1);
                     print WRITE "+               t1   v1\n" if($in_follow_out == 1);
                     print WRITE "+               t2   v2\n" if($in_follow_out == 1);
                     print WRITE "+               t3   v3\n" if($in_follow_out == 1);
                     print WRITE "+               t4   v4\n";
                     print WRITE "+               t5   v5\n";
                     print WRITE "+               t6   v6\n" if($in_follow_out == 0);
                     print WRITE "+               t7   v7\n" if($in_follow_out == 0);
                     print WRITE "+               t8   v8\n" if($in_follow_out == 0);
                     print WRITE "+               t9   v9\n" if($in_follow_out == 0);
                     print WRITE "+             )\n";
                     print WRITE "*.MODEL n NMOS\n";
                     print WRITE "*.MODEL p PMOS\n";
                     print WRITE "*.MODEL nd NMOS\n";
                     print WRITE "*.MODEL pd PMOS\n";
                     print WRITE "\n";
                     print WRITE "\n";
                     #----------------------------------------------------------------#
                     print WRITE ".include  /home/pathak/Testcase/unitTestCases/ngspice/imager.models.small\n";
                     print WRITE ".include $new_file_spice\n";
                     print WRITE "x$cellName @get_new_port_list $cellName\n";
                     print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
                     print WRITE "C1 $output_port 0 opcap\n";
                     print WRITE "\n";
                     print WRITE ".temp 85\n";
                     print WRITE ".tran 10p 500n\n";
                     print WRITE "\n";
                     print WRITE ".meas tran n2_first_rise when v(n2)=vmid rise=1\n" if($in_follow_out == 1);
                     print WRITE ".meas tran n2_first_fall when v(n2)=vmid fall=1\n" if($in_follow_out == 0);
                     print WRITE "\n";
                     print WRITE ".meas tran n3_first_rise when v(n3)=vmid rise=1\n";
                     print WRITE "\n";
                     print WRITE ".meas tran drise trig v(n2) val=vmid $dRise\n";
                     print WRITE "+                targ v(n3) val=vmid rise=1\n";
                     print WRITE "\n";
                     print WRITE ".meas tran slewr trig v(n3) val=vlo rise=1\n";
                     print WRITE "+                targ v(n3) val=vhi rise=1\n";
                     print WRITE "\n";
                     print WRITE ".end\n";
                     close(WRITE);

                     ############################################################## run ngspice###########################################################
                     system ("ngspice -b -o $file-dfall-$rel_pin-$input_slew_value-$op_cap-$p_join-$type.log $file-dfall-$rel_pin-$input_slew_value-$op_cap-$p_join-$type");
                     system ("ngspice -b -o $file-drise-$rel_pin-$input_slew_value-$op_cap-$p_join-$type.log $file-drise-$rel_pin-$input_slew_value-$op_cap-$p_join-$type");
                     #####################################################################################################################################
                     #---------------------read log file of ngspice for dfall & slewf -------------------------#
                     open(READ_NG_LOG,"$file-dfall-$rel_pin-$input_slew_value-$op_cap-$p_join-$type.log");
                     while(<READ_NG_LOG>){
                     chomp();
                       if($_ =~ /^dfall/){s/\s*dfall\s*//;my $dfall = (split(/=\s+/,$_))[1];
                         $dfall =~ s/\s*targ//;
                         my ($n,$m) = (split(/e/,$dfall))[0,1];
                         my $m = $m+9;
                         my $dfall_new = $n*(10**$m);
                         push(@dfall_list,$dfall_new);
                       }
                       if($_ =~ /^slewf/){s/\s*slewf\s*//;my $slewf = (split(/=\s+/,$_))[1];
                         $slewf =~ s/\s*targ//;
                         my ($n,$m) = (split(/e/,$slewf))[0,1];
                         my $m = $m+9;
                         my $slewf_new = $n*(10**$m);
                         push(@slewf_list,$slewf_new);
                       }
                     }#while reading
                     close(READ_NG_LOG);

                     #---------------------read log file of ngspice for drise & slewr -------------------------#
                     open(READ_NG_LOG,"$file-drise-$rel_pin-$input_slew_value-$op_cap-$p_join-$type.log");
                     while(<READ_NG_LOG>){
                     chomp();
                       if($_ =~ /^drise/){s/\s*drise\s*//;my $drise = (split(/=\s+/,$_))[1];
                         $drise =~ s/\s*targ//;
                         my ($n,$m) = (split(/e/,$drise))[0,1];
                         my $m = $m+9;
                         my $drise_new = $n*(10**$m);
                         push(@drise_list,$drise_new);
                       }
                       if($_ =~ /^slewr/){s/\s*slewr\s*//;my $slewr = (split(/=\s+/,$_))[1];
                         $slewr =~ s/\s*targ//;
                         my ($n,$m) = (split(/e/,$slewr))[0,1];
                         my $m = $m+9;
                         my $slewr_new = $n*(10**$m);
                         push(@slewr_list,$slewr_new);
                       }
                     }#while reading
                     close(READ_NG_LOG);

                 }#foreach output cap
             }#foreach input slew
             if(@drise_list == ($ns*$nopcap) && @slewr_list == ($ns*$nopcap) && @dfall_list == ($ns*$nopcap) && @slewf_list == ($ns*$nopcap)){
                if(@bits > 1){
                   my ($cond, $sdf_cond) = get_cond_and_sdf_cond($rel_pin,\@bits,\@input_list);
                   print WRITE_LIB "   condition : $cond\n";
                   print WRITE_LIB "   sdf_cond : $sdf_cond\n";
                }
                print WRITE_LIB "       cell_rise @drise_list\n";
                print WRITE_LIB "       rise_transition @slewr_list\n";
                print WRITE_LIB "       cell_fall @dfall_list\n";
                print WRITE_LIB "       fall_transition @slewf_list\n";
             }#if all values found
         }#foreach condition
      }#foreach related pin
  }#foreach output
close(WRITE_LIB);
#&write_lib("-genlib","$cellName.genlib","-lib","$fileName.lib");
&write_lib("-genlib","$cellName.genlib","-lib","$out_file.lib");
}#sub read_file
#----------------------------------------------------------------------------------------------------------#
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
sub check_cellName {
my $file = $_[0];
my $cell = "";
open(READ_SP,"$file");
while(<READ_SP>){
  chomp();
  if($_ =~ /\*/){next;}
  if($_ =~  /^\s*\.subckt/i){
     $cell = (split(/\s+/,$_))[1];
  }
}
close (READ_SP);
return($cell);
}#sub check_cellName
#-------------------------------------------------------------------------------------------------------------------------------------#
sub write_lib {
use liberty;

my $noOfArguments = @_;
my $input_file = "";
my $output_file = "";
my $x = 11;

if($noOfArguments < 2 || $_[0] eq '-h'|| $_[0] eq '-help'){
   print "Usage : ./write_lib.pl -genlib <input file>\n";
   print "                       -lib <output file (default file name will be library name)>\n";
}else{
   for(my $x = 0; $x < $noOfArguments; $x++){
       if($_[$x] eq "-genlib"){ $input_file = $_[$x+1];}
       if($_[$x] eq "-lib"){ $output_file = $_[$x+1];}
   }#foreach arg
   #$pi = liberty::si2drPIInit(\$x)
   liberty::si2drPIInit(\$x);

   my @index_1 = ();  
   my @index_2 = ();  
   my @in_index_1 = ();
   my @in_index_2 = ();
   my $rel_pin = "";
   my $cond = "";
   my $sdf_cond = "";
   my $timing_type = "";
   my $timing_sense = "";
   my $cell_rise_found = 0;

   open (READ, "$input_file");
   while(<READ>){
     chomp();
     $_ =~ s/^\s+//;
     if($_ =~ /^LIBNAME\s+/) { 
        my $lib_name = (split(/\s+/,$_))[1];
        if($output_file eq ""){ $output_file = $lib_name.".lib"}

        $group1 = liberty::si2drPICreateGroup($lib_name, "library", \$x);
        #liberty::si2drGroupSetComment($group1, "Copyright 2011 by Silverline Design Inc.", \$x);
        my $attr = liberty::si2drGroupCreateAttr($group1, "delay_model", $liberty::SI2DR_SIMPLE, \$x);
        liberty::si2drSimpleAttrSetStringValue($attr, "table_lookup", \$x);

        my $attr1 = liberty::si2drGroupCreateAttr($group1, "in_place_swap_mode", $liberty::SI2DR_SIMPLE, \$x);
        liberty::si2drSimpleAttrSetStringValue($attr1, "match_footprint", \$x);

        my $attr2 = liberty::si2drGroupCreateAttr($group1, "revision", $liberty::SI2DR_SIMPLE, \$x);
        liberty::si2drSimpleAttrSetStringValue($attr2, "1.12", \$x);

        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time); 
        my @months = ("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
        my $date = sprintf("%02d-%s-%04d",$mday,$months[$mon],$year+1900);
        my $time = sprintf("%02d:%02d:%02d",$hour,$min,$sec);
        my $localtime = "$date, $time";

        my $attr3 = liberty::si2drGroupCreateAttr($group1, "date", $liberty::SI2DR_SIMPLE, \$x);
        #liberty::si2drSimpleAttrSetStringValue($attr3, "Friday April 01 14:54:29 2011", \$x);
        liberty::si2drSimpleAttrSetStringValue($attr3, "$localtime", \$x);

        my $attr4 = liberty::si2drGroupCreateAttr($group1, "comment", $liberty::SI2DR_SIMPLE, \$x);
        liberty::si2drSimpleAttrSetStringValue($attr4, "Copyright 2011 by Silverline Design Inc.", \$x);

        my $attr5 = liberty::si2drGroupCreateAttr($group1, "time_unit", $liberty::SI2DR_SIMPLE, \$x);
        liberty::si2drSimpleAttrSetStringValue($attr5, "1ns", \$x);

        my $attr6 = liberty::si2drGroupCreateAttr($group1, "voltage_unit", $liberty::SI2DR_SIMPLE, \$x);
        liberty::si2drSimpleAttrSetStringValue($attr6, "1V", \$x);

        my $attr7 = liberty::si2drGroupCreateAttr($group1, "current_unit", $liberty::SI2DR_SIMPLE, \$x);
        liberty::si2drSimpleAttrSetStringValue($attr7, "1uA", \$x);

        my $attr8 = liberty::si2drGroupCreateAttr($group1, "pulling_resistance_unit", $liberty::SI2DR_SIMPLE, \$x);
        liberty::si2drSimpleAttrSetStringValue($attr8, "1kohm", \$x);

        my $attr9 = liberty::si2drGroupCreateAttr($group1, "leakage_power_unit", $liberty::SI2DR_SIMPLE, \$x);
        liberty::si2drSimpleAttrSetStringValue($attr9, "1nW", \$x);

        $group1_2 = liberty::si2drGroupCreateGroup($group1,"delay_template", "lu_table_template", \$x);

        my $attr10 = liberty::si2drGroupCreateAttr($group1_2, "variable_1", $liberty::SI2DR_SIMPLE, \$x);
        liberty::si2drSimpleAttrSetStringValue($attr10, "input_net_transition", \$x);

        my $attr11 = liberty::si2drGroupCreateAttr($group1_2, "variable_2", $liberty::SI2DR_SIMPLE, \$x);
        liberty::si2drSimpleAttrSetStringValue($attr11, "total_output_net_capacitance", \$x);

     }elsif($_ =~ /^GATE\s+/) { 
        my $cell_name = (split(/\s+/,$_))[1];
        $group1_1 = liberty::si2drGroupCreateGroup($group1,$cell_name, "cell", \$x);

     }elsif($_ =~ /^index_1\s+/){
        @index_1 = split(/\s+/,$_);
        shift @index_1;
        my $attr = liberty::si2drGroupCreateAttr($group1_2, "index_1 ", $liberty::SI2DR_COMPLEX, \$x);
        my $ind_1 = join ", " ,@index_1;
        liberty::si2drComplexAttrAddStringValue($attr, $ind_1, \$x);

     }elsif($_ =~ /^index_2\s+/){
        @index_2 = split(/\s+/,$_);
        shift @index_2;
        my $attr = liberty::si2drGroupCreateAttr($group1_2, "index_2 ", $liberty::SI2DR_COMPLEX, \$x);
        my $ind_2 = join ", " ,@index_2;
        liberty::si2drComplexAttrAddStringValue($attr, $ind_2, \$x);

     }elsif($_ =~ /^PIN\s+/){
        my ($pin, $dir) = (split(/\s+/,$_))[1,3];

        $group1_1_1 = liberty::si2drGroupCreateGroup($group1_1,$pin, "pin", \$x);  
        my $attr = liberty::si2drGroupCreateAttr($group1_1_1, "direction", $liberty::SI2DR_SIMPLE, \$x);
        liberty::si2drSimpleAttrSetStringValue($attr, $dir, \$x);
        if($dir =~ /input/i){
           my $attr1 = liberty::si2drGroupCreateAttr($group1_1_1, "max_transition", $liberty::SI2DR_SIMPLE, \$x);
           liberty::si2drSimpleAttrSetFloat64Value($attr1, 2.0, \$x);
        }
        $cell_rise_found = 0;
        $rise_cons_found = 0;

        ##my $d = liberty::si2drCreateExpr($liberty::SI2DR_EXPR_VAL,\$x);
        #my $d = liberty::si2drCreateStringValExpr($dir,\$x);
        #print "$pin | dir : $dir , $d , $attr \n";
        #liberty::si2drSimpleAttrSetExprValue($attr, $d, \$x);

     }elsif($_ =~ /^output\s+/){
        my @out = split(/\s+/,$_);
        shift @out;
        $_ = "I".$_ foreach @out;
        my $out_str = join ",",@out;
        $group1_1_1 = liberty::si2drGroupCreateGroup($group1_1,$out_str, "ff", \$x);

     }elsif($_ =~ /^in_index_1\s+/){
        @in_index_1 = split(/\s+/,$_);
        shift @in_index_1;

     }elsif($_ =~ /^in_index_2\s+/){
        @in_index_2 = split(/\s+/,$_);
        shift @in_index_2;

     }elsif($_ =~ /^function\s+/){
        my $function = (split(/\:/,$_))[1];
        $function =~ s/^\s+//;

        my $attr = liberty::si2drGroupCreateAttr($group1_1_1, "function", $liberty::SI2DR_SIMPLE, \$x);
        liberty::si2drSimpleAttrSetStringValue($attr, $function, \$x);

     }elsif($_ =~ /^clocked_on\s+/){
        my $clocked_on = (split(/\s+/,$_))[1];

        my $attr = liberty::si2drGroupCreateAttr($group1_1_1, "clocked_on", $liberty::SI2DR_SIMPLE, \$x);
        liberty::si2drSimpleAttrSetStringValue($attr, $clocked_on, \$x);

     }elsif($_ =~ /^input\s+/){
        my $next_state = (split(/\s+/,$_))[1];

        my $attr = liberty::si2drGroupCreateAttr($group1_1_1, "next_state", $liberty::SI2DR_SIMPLE, \$x);
        liberty::si2drSimpleAttrSetStringValue($attr, $next_state, \$x);

     }elsif($_ =~ /^reset\s+/){
        my $clear = (split(/\s+/,$_))[1];

        my $attr = liberty::si2drGroupCreateAttr($group1_1_1, "clear", $liberty::SI2DR_SIMPLE, \$x);
        liberty::si2drSimpleAttrSetStringValue($attr, $clear, \$x);

     }elsif($_ =~ /^clock\s+/){
        my $clk_val = (split(/\s+/,$_))[1];

        my $attr = liberty::si2drGroupCreateAttr($group1_1_1, "clock", $liberty::SI2DR_SIMPLE, \$x);
        liberty::si2drSimpleAttrSetStringValue($attr, $clk_val, \$x);

     }elsif($_ =~ /^related_pin\s+/){
        $rel_pin = (split(/\s+/,$_))[1];
        $cell_rise_found = 0;
        $rise_cons_found = 0;

     }elsif($_ =~ /^condition\s+/){
        $cond = (split(/\:/,$_))[1];
        $cond =~ s/^\s+//;

     }elsif($_ =~ /^sdf_cond\s+/){
        $sdf_cond = (split(/\:/,$_))[1];
        $sdf_cond =~ s/^\s+//;

     }elsif($_ =~ /^timing_type\s+/){
        $timing_type = (split(/\:/,$_))[1];
        $timing_type =~ s/^\s+//;

     }elsif($_ =~ /^timing_sense\s+/){
        $timing_sense = (split(/\:/,$_))[1];
        $timing_sense =~ s/^\s+//;

     }elsif($_ =~ /^cell_rise\s+/){
        my @rise_delay = split(/\s+/,$_);
        $cell_rise_found = 1;
        $group1_1_1_1 = liberty::si2drGroupCreateGroup($group1_1_1, "", "timing", \$x);
        if($rel_pin ne ""){
           my $attr = liberty::si2drGroupCreateAttr($group1_1_1_1, "related_pin", $liberty::SI2DR_SIMPLE, \$x);
           liberty::si2drSimpleAttrSetStringValue($attr, $rel_pin, \$x);
        }
        if($cond ne ""){
           my $attr = liberty::si2drGroupCreateAttr($group1_1_1_1, "when", $liberty::SI2DR_SIMPLE, \$x);
           liberty::si2drSimpleAttrSetStringValue($attr, $cond, \$x);
           $cond = "";
        }
        if($sdf_cond ne ""){
           my $attr = liberty::si2drGroupCreateAttr($group1_1_1_1, "sdf_cond", $liberty::SI2DR_SIMPLE, \$x);
           liberty::si2drSimpleAttrSetStringValue($attr, $sdf_cond, \$x);
           $sdf_cond = "";
        }
        if($timing_type ne ""){
           my $attr = liberty::si2drGroupCreateAttr($group1_1_1_1, "timing_type", $liberty::SI2DR_SIMPLE, \$x);
           liberty::si2drSimpleAttrSetStringValue($attr, $timing_type, \$x);
           $timing_type = "";
        }
        if($timing_sense ne ""){
           my $attr = liberty::si2drGroupCreateAttr($group1_1_1_1, "timing_sense", $liberty::SI2DR_SIMPLE, \$x);
           liberty::si2drSimpleAttrSetStringValue($attr, $timing_sense, \$x);
           $timing_sense = "";
        }
        $group1_1_1_1_1 = liberty::si2drGroupCreateGroup($group1_1_1_1, "delay_template" , "cell_rise", \$x);

        my $attr1 = liberty::si2drGroupCreateAttr($group1_1_1_1_1, "index_1 ", $liberty::SI2DR_COMPLEX, \$x);
        my $index_1 = join ", " ,@index_1;
        liberty::si2drComplexAttrAddStringValue($attr1, $index_1, \$x);

        my $attr2 = liberty::si2drGroupCreateAttr($group1_1_1_1_1, "index_2 ", $liberty::SI2DR_COMPLEX, \$x);
        my $index_2 = join ", " ,@index_2;
        liberty::si2drComplexAttrAddStringValue($attr2, $index_2, \$x);

        my $attr3 = liberty::si2drGroupCreateAttr($group1_1_1_1_1, "values ", $liberty::SI2DR_COMPLEX, \$x);
        shift @rise_delay;
        for(my $i=0; $i<$#rise_delay; $i=($i+$#index_2+1)){
           my @new_rise_delay = ();
           for(my $j=$i; $j<($i+$#index_2+1); $j++){
              push(@new_rise_delay, $rise_delay[$j])
           }
           my $rise_del = join ", ",@new_rise_delay;
           liberty::si2drComplexAttrAddStringValue($attr3, $rise_del, \$x);
        }

     }elsif($_ =~ /^rise_transition\s+/){
        my @rise_trans = split(/\s+/,$_);

        $group1_1_1_1_2 = liberty::si2drGroupCreateGroup($group1_1_1_1, "delay_template" , "rise_transition", \$x);

        my $attr1 = liberty::si2drGroupCreateAttr($group1_1_1_1_2, "index_1", $liberty::SI2DR_COMPLEX, \$x);
        my $index_1 = join ", " ,@index_1;
        liberty::si2drComplexAttrAddStringValue($attr1, $index_1, \$x);

        my $attr2 = liberty::si2drGroupCreateAttr($group1_1_1_1_2, "index_2", $liberty::SI2DR_COMPLEX, \$x);
        my $index_2 = join ", " ,@index_2;
        liberty::si2drComplexAttrAddStringValue($attr2, $index_2, \$x);

        my $attr3 = liberty::si2drGroupCreateAttr($group1_1_1_1_2, "values", $liberty::SI2DR_COMPLEX, \$x);
        shift @rise_trans;
        for(my $i=0; $i<$#rise_trans; $i=($i+$#index_2+1)){
           my @new_rise_trans = ();
           for(my $j=$i; $j<($i+$#index_2+1); $j++){
              push(@new_rise_trans, $rise_trans[$j])
           }
           my $rise_tra = join ", ",@new_rise_trans;
           liberty::si2drComplexAttrAddStringValue($attr3, $rise_tra, \$x);
        }

     }elsif($_ =~ /^cell_fall\s+/){
        my @fall_delay = split(/\s+/,$_);
        if($cell_rise_found == 0){
           $group1_1_1_1 = liberty::si2drGroupCreateGroup($group1_1_1, "", "timing", \$x);
           if($rel_pin ne ""){
              my $attr = liberty::si2drGroupCreateAttr($group1_1_1_1, "related_pin", $liberty::SI2DR_SIMPLE, \$x);
              liberty::si2drSimpleAttrSetStringValue($attr, $rel_pin, \$x);
           }
           if($cond ne ""){
              my $attr = liberty::si2drGroupCreateAttr($group1_1_1_1, "when", $liberty::SI2DR_SIMPLE, \$x);
              liberty::si2drSimpleAttrSetStringValue($attr, $cond, \$x);
              $cond = "";
           }
           if($sdf_cond ne ""){
              my $attr = liberty::si2drGroupCreateAttr($group1_1_1_1, "sdf_cond", $liberty::SI2DR_SIMPLE, \$x);
              liberty::si2drSimpleAttrSetStringValue($attr, $sdf_cond, \$x);
              $sdf_cond = "";
           }
           if($timing_type ne ""){
              my $attr = liberty::si2drGroupCreateAttr($group1_1_1_1, "timing_type", $liberty::SI2DR_SIMPLE, \$x);
              liberty::si2drSimpleAttrSetStringValue($attr, $timing_type, \$x);
              $timing_type = "";
           }
           if($timing_sense ne ""){
              my $attr = liberty::si2drGroupCreateAttr($group1_1_1_1, "timing_sense", $liberty::SI2DR_SIMPLE, \$x);
              liberty::si2drSimpleAttrSetStringValue($attr, $timing_sense, \$x);
              $timing_sense = "";
           }
        } 
        $group1_1_1_1_3 = liberty::si2drGroupCreateGroup($group1_1_1_1, "delay_template", "cell_fall", \$x);
 
        my $attr1 = liberty::si2drGroupCreateAttr($group1_1_1_1_3, "index_1", $liberty::SI2DR_COMPLEX, \$x);
        my $index_1 = join ", " ,@index_1;
        liberty::si2drComplexAttrAddStringValue($attr1, $index_1, \$x);

        my $attr2 = liberty::si2drGroupCreateAttr($group1_1_1_1_3, "index_2", $liberty::SI2DR_COMPLEX, \$x);
        my $index_2 = join ", " ,@index_2;
        liberty::si2drComplexAttrAddStringValue($attr2, $index_2, \$x);

        my $attr3 = liberty::si2drGroupCreateAttr($group1_1_1_1_3, "values", $liberty::SI2DR_COMPLEX, \$x);
        shift @fall_delay;
        for(my $i=0; $i<$#fall_delay; $i=($i+$#index_2+1)){
           my @new_fall_delay = ();
           for(my $j=$i; $j<($i+$#index_2+1); $j++){
              push(@new_fall_delay, $fall_delay[$j])
           }
           my $fall_del = join ", ",@new_fall_delay;
           liberty::si2drComplexAttrAddStringValue($attr3, $fall_del, \$x);
        }

     }elsif($_ =~ /^fall_transition\s+/){
        my @fall_trans = split(/\s+/,$_);

        $group1_1_1_1_4 = liberty::si2drGroupCreateGroup($group1_1_1_1, "delay_template", "fall_transition", \$x);

        my $attr1 = liberty::si2drGroupCreateAttr($group1_1_1_1_4, "index_1", $liberty::SI2DR_COMPLEX, \$x);
        my $index_1 = join ", " ,@index_1;
        liberty::si2drComplexAttrAddStringValue($attr1, $index_1, \$x);

        my $attr2 = liberty::si2drGroupCreateAttr($group1_1_1_1_4, "index_2", $liberty::SI2DR_COMPLEX, \$x);
        my $index_2 = join ", " ,@index_2;
        liberty::si2drComplexAttrAddStringValue($attr2, $index_2, \$x);

        my $attr3 = liberty::si2drGroupCreateAttr($group1_1_1_1_4, "values", $liberty::SI2DR_COMPLEX, \$x);
        shift @fall_trans;
        for(my $i=0; $i<$#fall_trans; $i=($i+$#index_2+1)){
           my @new_fall_trans = ();
           for(my $j=$i; $j<($i+$#index_2+1); $j++){
              push(@new_fall_trans, $fall_trans[$j])
           }
           my $rise_tra = join ", ",@new_fall_trans;
           liberty::si2drComplexAttrAddStringValue($attr3, $rise_tra, \$x);
        }

     }elsif($_ =~ /^rise_constraint\s+/){
        my @rise_constraint = split(/\s+/,$_);
        $rise_cons_found = 1;
        $group1_1_1_1 = liberty::si2drGroupCreateGroup($group1_1_1, "", "timing", \$x);
        if($rel_pin ne ""){
           my $attr = liberty::si2drGroupCreateAttr($group1_1_1_1, "related_pin", $liberty::SI2DR_SIMPLE, \$x);
           liberty::si2drSimpleAttrSetStringValue($attr, $rel_pin, \$x);
        }
        if($timing_type ne ""){
           my $attr = liberty::si2drGroupCreateAttr($group1_1_1_1, "timing_type", $liberty::SI2DR_SIMPLE, \$x);
           liberty::si2drSimpleAttrSetStringValue($attr, $timing_type, \$x);
        }
        my $template = "";
        if($timing_type eq "setup_rising"){$template = "setup_template"}
        if($timing_type eq "hold_rising"){$template = "hold_template"}
        if($timing_type eq "recovery_rising"){$template = "recovery_template"}
        $group1_1_1_1_1 = liberty::si2drGroupCreateGroup($group1_1_1_1, $template , "rise_constraint", \$x);

        my $attr1 = liberty::si2drGroupCreateAttr($group1_1_1_1_1, "index_1 ", $liberty::SI2DR_COMPLEX, \$x);
        my $index_1 = join ", " ,@in_index_1;
        liberty::si2drComplexAttrAddStringValue($attr1, $index_1, \$x);

        my $attr2 = liberty::si2drGroupCreateAttr($group1_1_1_1_1, "index_2 ", $liberty::SI2DR_COMPLEX, \$x);
        my $index_2 = join ", " ,@in_index_2;
        liberty::si2drComplexAttrAddStringValue($attr2, $index_2, \$x);

        my $attr3 = liberty::si2drGroupCreateAttr($group1_1_1_1_1, "values ", $liberty::SI2DR_COMPLEX, \$x);
        shift @rise_constraint;
        for(my $i=0; $i<$#rise_constraint; $i=($i+$#in_index_2+1)){
           my @new_rise_cons = ();
           for(my $j=$i; $j<($i+$#in_index_2+1); $j++){
              push(@new_rise_cons, $rise_constraint[$j])
           }
           my $rise_cons = join ", ",@new_rise_cons;
           liberty::si2drComplexAttrAddStringValue($attr3, $rise_cons, \$x);
        }

     }elsif($_ =~ /^fall_constraint\s+/){
        my @fall_constraint = split(/\s+/,$_);
        if($rise_cons_found == 0){
           $group1_1_1_1 = liberty::si2drGroupCreateGroup($group1_1_1, "", "timing", \$x);
           if($rel_pin ne ""){
              my $attr = liberty::si2drGroupCreateAttr($group1_1_1_1, "related_pin", $liberty::SI2DR_SIMPLE, \$x);
              liberty::si2drSimpleAttrSetStringValue($attr, $rel_pin, \$x);
           }
           if($timing_type ne ""){
              my $attr = liberty::si2drGroupCreateAttr($group1_1_1_1, "timing_type", $liberty::SI2DR_SIMPLE, \$x);
              liberty::si2drSimpleAttrSetStringValue($attr, $timing_type, \$x);
           }
        }
        my $template = "";
        if($timing_type eq "setup_rising"){$template = "setup_template"}
        if($timing_type eq "hold_rising"){$template = "hold_template"}
        if($timing_type eq "recovery_rising"){$template = "recovery_template"}
        $group1_1_1_1_1 = liberty::si2drGroupCreateGroup($group1_1_1_1, $template , "fall_constraint", \$x);

        my $attr1 = liberty::si2drGroupCreateAttr($group1_1_1_1_1, "index_1 ", $liberty::SI2DR_COMPLEX, \$x);
        my $index_1 = join ", " ,@in_index_1;
        liberty::si2drComplexAttrAddStringValue($attr1, $index_1, \$x);

        my $attr2 = liberty::si2drGroupCreateAttr($group1_1_1_1_1, "index_2 ", $liberty::SI2DR_COMPLEX, \$x);
        my $index_2 = join ", " ,@in_index_2;
        liberty::si2drComplexAttrAddStringValue($attr2, $index_2, \$x);

        my $attr3 = liberty::si2drGroupCreateAttr($group1_1_1_1_1, "values ", $liberty::SI2DR_COMPLEX, \$x);
        shift @fall_constraint;
        for(my $i=0; $i<$#fall_constraint; $i=($i+$#in_index_2+1)){
           my @new_fall_cons = ();
           for(my $j=$i; $j<($i+$#in_index_2+1); $j++){
              push(@new_fall_cons, $fall_constraint[$j])
           }
           my $fall_cons = join ", ",@new_fall_cons;
           liberty::si2drComplexAttrAddStringValue($attr3, $fall_cons, \$x);
        }

     }else{next;}
   }#while reading 
   close READ;
   liberty::si2drWriteLibertyFile($output_file, $group1, \$x);
   liberty::si2drPIQuit(\$x);
  #------------- Reporting Error --------------#
  liberty::si2drPIInit(\$x);
  liberty::si2drReadLibertyFile($output_file, \$x);
  liberty::si2drPIQuit(\$x); 
  #--------------------------------------------#
}#if correct num of arg
}#sub write_lib
#------------------------------------------------------------------------------------------------------------------3
sub get_cond_and_sdf_cond {
 my $rel_pin = $_[0];
 my @bits = @{$_[1]};
 my @input = @{$_[2]};
 my @cond_val = ();
 my @sdf_cond_val = ();
 for(my $i=0; $i<=$#input; $i++){
    if($input[$i] eq $rel_pin){next;}
    my $bit = $bits[$i];
    if($bit == 0){ push(@cond_val,"!".$input[$i]);}
    if($bit == 1){ push(@cond_val,$input[$i]);}

    push(@sdf_cond_val, $input[$i]." == 1'b".$bit);
 }
 my $cond = join " & ",@cond_val;
 my $sdf_cond = join " && ",@sdf_cond_val;
 return ($cond, $sdf_cond);
}#sub get_cond_and_sdf_cond
#---------------------------------------------------------------------------------------------------------------------#

sub include_spi_files{
  my $spFile = $_[0];
  my @dir_path = split(/\//,$spFile);
  my $sp_file_name = pop @dir_path;
  my $in_file_dir = join "/", @dir_path if(@dir_path > 0); 
  my $out_file = &call_include_spi_files($spFile, $in_file_dir, $sp_file_name, 0);
  return($out_file); 
}#sub include_spi_files

sub call_include_spi_files{
 my $in_file = $_[0];
 my $dir_path = $_[1];
 my $out_file = $_[2];
 my $count = $_[3];
 my $hier = 0;
 my $read_fh;
 my $write_fh;

 open($read_fh,"$in_file");
 open($write_fh,">$out_file$count");
 while(<$read_fh>){
   chomp();
   if($_ =~ /^\s*\.include\s+/){
      my $include_file = (split(/\s+/,$_))[1];
      $include_file =~ s/\"//g;
      $include_file = $dir_path."/".$include_file if($dir_path ne "");
      if(-e $include_file){
         #my $status = &check_include_found($include_file);
         #if($status == 1){
            my $next_has_include = &write_data_in_file($write_fh, $include_file);
            if($next_has_include == 1){
               $hier = 1;
            }
         #}else{
         #   print $write_fh ".include \"$include_file\"\n";
         #}
      }else{
         print "WARN: file  $include_file does not exists\n";
      }
   }else{
      print $write_fh "$_\n";
   }
 }#while
 close $write_fh;
 close $read_fh;
 if($hier > 0){
    &call_include_spi_files($out_file.$count, $dir_path, $out_file, $count+1);
 }else{
    system("cp $out_file$count $out_file-include.sp");
    return( $out_file."-include.sp");
 }
}#sub call_include_spi_files


sub check_include_found{
 my $file = $_[0];
 my $read_fh;
 open($read_fh, $file);
 while(<$read_fh>){
   chomp();
   if($_ =~ (/^\s*\.subckt/i) || (/^\s*x\s*/i)){
      return 1;
   }
 }
 close $read_fh;
 return 0;
}#sub check_include_found

sub write_data_in_file{
 my $file_handle = $_[0];
 my $data_file = $_[1];
 my $has_include = 0;
 my $read_fh;
 open($read_fh, $data_file);
 while(<$read_fh>){
   chomp();
   if($_ =~ /^\s*\.include\s+/){
      $has_include = 1;
   }
   print $file_handle "$_\n";
 }
 close $read_fh;
 return $has_include;
}#sub write_data_in_file

#####################################################################
sub get_flat_spi {
my $file_name = $_[0];
my $end_data_of_subckt = 0;
my $read_data_of_subckt = 0;
my $cellName = "";
my @cell_data = ();
#my %PORT_DATA = ();
#my %TRANS_DATA = ();
#my %INST_DATA = ();
my %TOTAL_CELL_HASH = ();
my @temp = ();

my @dir_path = split(/\//,$file_name);
my $sp_file_name = pop @dir_path;
my $in_file_dir = join "/", @dir_path; 

open(READ,"$file_name");
my $previous_line = "";
my $next_line = "";
while(<READ>){
  chomp();
  if($_ =~ /\*/){next;}
  if($_ =~ /^\s*\.include\s+/){
     my $include_file = (split(/\"/,$_))[1];
     $include_file = $in_file_dir."/".$include_file;
     $_ = ".include \"$include_file\"";
  }
  if($_ =~ /^\+/){
    s/\s+$//;
    s/^\+//;
    $previous_line = $previous_line." ".$_;
    next;
  }
  $next_line = $_;
  if($previous_line =~ /^\s*\.subckt/i){
    $read_data_of_subckt = 1;
    $end_data_of_subckt = 0;
  }
  if($previous_line =~ /^\s*\.end/i){
    $end_data_of_subckt = 1;
    $read_data_of_subckt = 0;
  }
  if($read_data_of_subckt == 1 && $end_data_of_subckt == 0){
    if($previous_line =~ /^\s*\.subckt/i){
      $previous_line =~ s/^\s*\.(subckt|SUBCKT)\s*//;
      @cell_data = (split(/\s+/,$previous_line));
      $cellName = shift(@cell_data);
      $TOTAL_CELL_HASH{$cellName} = 1; 
      @{$PORT_DATA{$cellName}} = @cell_data;
    }elsif($previous_line=~ /^\s*m\s*/i || $previous_line=~ /^\s*c\s*/i || $previous_line=~ /^\s*r\s*/i){
      $previous_line =~ s/=\s+/=/; 
      if(!exists $TRANS_DATA{$cellName}){ 
         @{$TRANS_DATA{$cellName}} = @temp;
      }
      push (@{$TRANS_DATA{$cellName}} ,$previous_line);
    }elsif($previous_line =~ /^\s*x\s*/i){
       $previous_line =~ s/=\s+/=/;
       if(!exists $INST_DATA{$cellName}){
          @{$INST_DATA{$cellName}} = @temp;
       }
       push (@{$INST_DATA{$cellName}},$previous_line);
    }
  }#if reading ckt
  $previous_line = $next_line;
}#while
close READ;

#  foreach my $k (keys %TRANS_DATA){
#    print "tr $k => @{$TRANS_DATA{$k}}\n";
#  }
#  foreach my $k (keys %PORT_DATA){
#    print "port $k => @{$PORT_DATA{$k}}\n";
#  }
#  foreach my $k (keys %INST_DATA){
#    print "inst $k => @{$INST_DATA{$k}}\n";
#  }
#return;
############################if file is already flat ############################
  my @cells  = keys %TOTAL_CELL_HASH;
  if(@cells ==1){
     if(-e $sp_file_name."-flat.sp"){
       return $file_name;
     }else{
       my $flat_sp_file = $sp_file_name."-flat.sp";

       #system("cp $file_name $flat_sp_file");
       open(WRITE, ">$flat_sp_file");
       open(READ, $file_name);
       while(<READ>){
         #if($_ =~ /^\s*\.include\s+/){
         #   my $include_file = (split(/\"/,$_))[1];
         #   $include_file = $in_file_dir."/".$include_file;
         #   $_ = ".include \"$include_file\"";
         #}
         print WRITE "$_\n";
       }
       close READ;
       close WRITE;
       return $flat_sp_file;
     } 
  }elsif(@cells <= 0){return $file_name}; 

########################## making flat data ###################################
  &get_flat_data;
  sub get_flat_data {
    foreach my $cell (keys %INST_DATA){
      my @instance_data = @{$INST_DATA{$cell}}; 
      my $count = 0; 
      foreach my $data ( @instance_data){
        delete $INST_DATA{$cell}[$count];
        my $type = "";
        my @data_list = split(/\s+/,$data);
        for(my $i=0; $i<@data_list; $i++){
           if($data_list[$i] =~ m/=/){
              $type = $data_list[$i-1];
              last;
           }
           if($i == $#data_list){
              $type = $data_list[$i];
           }
        }
        &replace_data($cell, $type, $data);
        $count++;
      }
    }#foreach cell in INST_DATA hash

    ############################ recursive function ##########################  
    sub replace_data {
      my $cell = $_[0];
      my $type = $_[1];
      my $data_line = $_[2];
      my @val = @{$INST_DATA{$type}};
      if(@val <= 0){delete $INST_DATA{$type};}
      if(exists $INST_DATA{$type}){
         my @instance_data = @{$INST_DATA{$type}};
         foreach my $data (@instance_data){ 
           my $type1 = "";
           my @data_list = split(/\s+/,$data);
           for(my $i=0; $i<@data_list; $i++){
              if($data_list[$i] =~ m/=/){
                 $type1 = $data_list[$i-1];
                 last;
              }
              if($i == $#data_list){
                 $type1 = $data_list[$i];
              }
           }
           &replace_data($type, $type1, $data);
         }
      }else{
         my %map_hash = ();
         my %cell_port_list = ();
         my @next_type_port_list = @{$PORT_DATA{$type}};
         my @xx_port_list = split(/\s+/, $data_line); 
         foreach(@next_type_port_list){
           $cell_port_list{$_} = 1;
         }
         my $xname = shift @xx_port_list;
         for(my $i=0; $i<@xx_port_list; $i++){
             if($i < @next_type_port_list){
                $map_hash{$next_type_port_list[$i]} = $xx_port_list[$i];
             }else{
                my ($field,$val) = (split(/\=/,$xx_port_list[$i]))[0,1];
                $map_hash{$field} = $val if($field ne "m");
             }
         }
         if(exists $TRANS_DATA{$type}){
            my @transdata = @{$TRANS_DATA{$type}};
            foreach my $trans_name (@transdata){
              my ($m1) = (split(/\s+/,$trans_name))[0];
              $trans_name =~ s/$m1/$m1$xname/;
              my @trans_data = (split(/\s+/,$trans_name));
              my $temp_trans_name = $trans_data[0];;
              for(my $i =1;$i<=$#trans_data;$i++){
                if(exists $map_hash{$trans_data[$i]}){
                  $temp_trans_name = $temp_trans_name." ".$map_hash{$trans_data[$i]};
                }elsif($trans_data[$i] =~ /=/) {
                  my ($field_val0,$field_val1) = (split(/=/,$trans_data[$i]))[0,1];
                  if(exists $map_hash{$field_val1}){
                    $temp_trans_name = $temp_trans_name." ".$field_val0."=".$map_hash{$field_val1};
                  }else{
                    $temp_trans_name = $temp_trans_name." ".$field_val0."=".$field_val1;
                  }
                }elsif((!exists $cell_port_list{$trans_data[$i]}) && ($i <=3) && ($m1 =~ /^\s*m/i)){
                  if($trans_data[$i] =~ /vss/i || $trans_data[$i] =~ /vdd/i){
                     $temp_trans_name = $temp_trans_name." ".$trans_data[$i];
                  }else{
                     $temp_trans_name = $temp_trans_name." ".$trans_data[$i]."".$xname;
                  }
                }elsif((!exists $cell_port_list{$trans_data[$i]}) && ($i <=2) && ($m1 =~ /^\s*(c|r)/i)){
                  if($trans_data[$i] =~ /vss/i || $trans_data[$i] =~ /vdd/i){
                     $temp_trans_name = $temp_trans_name." ".$trans_data[$i];
                  }else{
                     $temp_trans_name = $temp_trans_name." ".$trans_data[$i]."".$xname;
                  }
                }else{
                  $temp_trans_name = $temp_trans_name." ".$trans_data[$i];
                }
              }
              $trans_name = $temp_trans_name;
              #my ($drain,$gate,$source) = (split(/\s+/,$trans_name))[1,2,3];
              #if(!exists $cell_port_list{$drain}){$trans_name =~ s/\b$drain\b/$drain$xname/g;} 
              #if(!exists $cell_port_list{$gate}){$trans_name =~ s/\b$gate\b/$gate$xname/g;}
              #if(!exists $cell_port_list{$source}){$trans_name =~ s/\b$source\b/$source$xname/g;}
              #foreach my $map (keys %map_hash){
              #  my $val = $map_hash{$map};
              #  $trans_name =~ s/\b$map\b/$val/g;
              #}
              push (@{$TRANS_DATA{$cell}}, $trans_name);
              my $cell_not_exist = &check_cell_not_exists($cell,$type,$data_line);
              if($cell_not_exist == 1){
                 delete $TRANS_DATA{$type};
                 my @key =  keys %TRANS_DATA;
                 delete $PORT_DATA{$type};
                 my @inst_hash_val = @{$INST_DATA{$cell}};
                 if(@inst_hash_val <= 0){
                    delete $INST_DATA{$cell};
                 }
              }#if cell not exists 
            }#foreach data line 
          }#if exists in TRANS_DATA
      }#if cell type not found in INST_DATA hash
    }#sub replace_data
  
    ############################ recursive function ##########################  
    sub check_cell_not_exists{
    my $cell = $_[0];
    my $ckt_name = $_[1];
    my $data_line_arg = $_[2];
    my $cell_not_exist = 1;
      foreach my $type (keys %INST_DATA){
         my @data  = @{$INST_DATA{$type}};
         my $count = 0;
         foreach my $data_line(@data){
           if($cell eq $type && $data_line_arg eq $data_line){
             delete $data[$count];
             my @new_data = ();  
             foreach (@data){
              push(@new_data, $_) if($_ ne "");
             }
             @{$INST_DATA{$type}} = @new_data;
           }
           my @data_list = split(/\s+/,$data_line);
           for(my $i=0; $i<@data_list; $i++){
               if($data_list[$i] =~ m/=/){
                  
                  if($ckt_name eq $data_list[$i-1]){$cell_not_exist = 0;};
                  last;
               }
               if($i == $#data_list){
                  if($ckt_name eq $data_list[$i]){$cell_not_exist = 0;};
               }
            }
            $count++;
         }
      }
      return $cell_not_exist;
    }#sub check_cell_not_exists
    if((keys %INST_DATA) > 0){&get_flat_data;}
  }#sub get_flat_data
  ############################# End of get_flat_data #############################

  my $flat_sp_file = "";
  foreach my $mdata (keys %TRANS_DATA){
    my @port_list  = @{$PORT_DATA{$mdata}};
    #$flat_sp_file = "$mdata-flat.sp"; 
    $flat_sp_file = "$sp_file_name-flat.sp"; 
    open(WRITE,">$flat_sp_file");
      print WRITE".subckt $mdata @port_list\n";
      my @value = @{$TRANS_DATA{$mdata}};
      foreach my $val (@value){
         print WRITE "$val\n";
      }
      print WRITE".ends $mdata\n";
    close WRITE;
  } 
  return ($flat_sp_file);
}#sub get_flat_spi
####################################################reduce cap and reg###########################################
sub reduce_cap_and_reg {
  my $include_sp_file = $_[0];
  my $read_data_of_subckt = 0;
  my $end_data_of_subckt = 0;
  my %TRANS_DATA_HASH = ();
  my %CAP_DATA_HASH = ();
  my %REG_DATA_HASH = ();
  my %PORT_HASH_OF_SUBCKT = ();
  my %TRANS_DATA_HASH_NEW = ();
  my $flat_reduce_cap_sp_file = "$include_sp_file-reduce-cap-res.sp";
  open(READ,"$include_sp_file");
  open(WRITE,">$flat_reduce_cap_sp_file");
  while(<READ>){
    chomp();
    if($_ =~ /\*/){next;}
    if($_ =~ /^\+/){
      s/\s+$//;
      s/^\+//;
      $previous_line = $previous_line." ".$_;
      next;
    }
   $next_line = $_;
   if($previous_line =~ /^\s*\.subckt/i){
     $read_data_of_subckt = 1;
     $end_data_of_subckt = 0;
   }
   if($previous_line =~ /^\s*\.end/i){
    $end_data_of_subckt = 1;
    $read_data_of_subckt = 0;
   }
  if($read_data_of_subckt == 1 && $end_data_of_subckt == 0){
    if($previous_line =~ /^\s*\.subckt/i){
      print WRITE "$previous_line\n";
      $previous_line =~ s/^\s*\.(subckt|SUBCKT)\s*//;
      my @cell_data = (split(/\s+/,$previous_line));
      my $cellName = shift(@cell_data);
      foreach my $port (@cell_data){
        $PORT_HASH_OF_SUBCKT{$port} = 1;
      }
    }elsif($previous_line=~ /^\s*m\s*/i){
      my ($trans_name,$drain,$gate,$source) = (split(/\s+/,$previous_line))[0,1,2,3];
      push(@{$TRANS_DATA_HASH{$trans_name}},$drain,$gate,$source); 
      $previous_line =~ s/$trans_name//;
      $previous_line =~ s/$drain//;
      $previous_line =~ s/$gate//;
      $previous_line =~ s/$source//;
      $previous_line =~ s/\s+//;
      push(@{$TRANS_DATA_HASH_NEW{$trans_name}},$previous_line); 
    }elsif($previous_line =~ /^\s*c\s*/i){
      my ($cap_name,$net_1,$net_2) = (split(/\s+/,$previous_line))[0,1,2];
      push(@{$CAP_DATA_HASH{$cap_name}},$net_1,$net_2);
    }elsif($previous_line =~ /^\s*r\s*/i){
      my ($reg_name,$net_1,$net_2) = (split(/\s+/,$previous_line))[0,1,2];
      push(@{$REG_DATA_HASH{$reg_name}},$net_1,$net_2);
    }
  }#if reading subckt   
  $previous_line = $next_line;
  }#while
  close(READ);
#------------------------------------------------------------------------------------------------------------------#
  #foreach my $cap1 (keys %CAP_DATA_HASH){
  #   my ($net1, $net2) = @{$CAP_DATA_HASH{$cap1}};
  #   my ($replace_net, $replace_val);
  #   if(exists $PORT_HASH_OF_SUBCKT{$net2}){
  #      $replace_net = $net1;
  #      $replace_val = $net2;
  #   }else{
  #      $replace_net = $net2;
  #      $replace_val = $net1;
  #   }
  #   foreach my $tr (keys %TRANS_DATA_HASH){
  #     for(my $i=0; $i<3; $i++){
  #         #if($replace_val =~ /(vss|vdd)/i){next;}
  #         if($TRANS_DATA_HASH{$tr}[$i] eq $replace_net){
  #            $TRANS_DATA_HASH{$tr}[$i] = $replace_val;
  #         }
  #     }
  #   }
  #   foreach my $cap2 (keys %CAP_DATA_HASH){
  #     for(my $i=0; $i<2; $i++){
  #         if($CAP_DATA_HASH{$cap2}[$i] eq $replace_net){
  #            $CAP_DATA_HASH{$cap2}[$i] = $replace_val;
  #         }
  #     }
  #   }
  #   foreach my $res (keys %REG_DATA_HASH){
  #     for(my $i=0; $i<2; $i++){
  #         if($REG_DATA_HASH{$res}[$i] eq $replace_net){
  #            $REG_DATA_HASH{$res}[$i] = $replace_val;
  #         }
  #     }
  #   }
  #}

  foreach my $reg1 (keys %REG_DATA_HASH){
     my ($net1, $net2) = @{$REG_DATA_HASH{$reg1}};
     my ($replace_net, $replace_val);
     if(exists $PORT_HASH_OF_SUBCKT{$net2}){
        $replace_net = $net1;
        $replace_val = $net2;
     }else{
        $replace_net = $net2;
        $replace_val = $net1;
     }
     foreach my $tr (keys %TRANS_DATA_HASH){
       for(my $i=0; $i<3; $i++){
           #if($replace_val =~ /(vss|vdd)/i){next;}
           if($TRANS_DATA_HASH{$tr}[$i] eq $replace_net){
              $TRANS_DATA_HASH{$tr}[$i] = $replace_val;
           }
       }
     }
     foreach my $res2 (keys %REG_DATA_HASH){
       for(my $i=0; $i<2; $i++){
           if($REG_DATA_HASH{$res2}[$i] eq $replace_net){
              $REG_DATA_HASH{$res2}[$i] = $replace_val;
           }
       }
     }
  }
  
  foreach my $k (keys %TRANS_DATA_HASH){
     my @val = @{$TRANS_DATA_HASH{$k}};
     if(exists $TRANS_DATA_HASH_NEW{$k}){
       my @new_val = @{$TRANS_DATA_HASH_NEW{$k}};
       print WRITE "$k @val @new_val\n";
       #print "$k @val @new_val\n";
     }
  }
  print WRITE ".ends\n";
  foreach my $k (keys %CAP_DATA_HASH){
     my @val = @{$CAP_DATA_HASH{$k}};
     #print "$k => @val\n";
  }
  foreach my $k (keys %REG_DATA_HASH){
     my @val = @{$REG_DATA_HASH{$k}};
     #print "$k => @val\n";
  }
close (WRITE);
return($flat_reduce_cap_sp_file);
}#sub reduce_cap_and_reg
#---------------------------------------------------------------------------------------------------------------#
sub get_input_output_list {
  my $flat_reduce_cap_sp_file = $_[0];
  my @cell_data1 = ();
  my $read_data_of_subckt1 = 0;
  my $end_data_of_subckt1 = 0;
  my $cellName1 = "";
  my $data1 = "";
  my $data_start1 = 0;
  my $data_end1 = 0;
  my $mdata1 = "";
  my @new_data1 = ();
  my %TEMP_SPICE_DATA = ();
  my %in_port_hash = ();
  my %out_port_hash = ();

  open(READ_CAP_FLAT_SP,"$flat_reduce_cap_sp_file");
  my $previous_line1 = "";
  my $next_line1 = "";
  while(<READ_CAP_FLAT_SP>){
  chomp();
  if($_ =~ /\*/){next;}
  if($_ =~ /^\+/){
    s/\s+$//;
    s/^\+//;
    $previous_line1 = $previous_line1." ".$_;
    next;
  }
  $next_line1 = $_;
  if($previous_line1 =~ /^\s*\.subckt/i){
    $read_data_of_subckt1 = 1;
    $end_data_of_subckt1 = 0;
    $previous_line1 =~ s/^\s*\.(subckt|SUBCKT)\s*//;
    @cell_data1 = (split(/\s+/,$previous_line1));
    $cellName1 = shift(@cell_data1);
  }
  if($previous_line1 =~ /^\s*\.end/i){
    $end_data_of_subckt1 = 1;
    $read_data_of_subckt1 = 0;
  }
  if($read_data_of_subckt1 == 1 && $end_data_of_subckt1 == 0){
    if($previous_line1=~ /^\s*m\s*/i){
      $data1 = "";
      @new_data1 = ();
      $mdata1 = "";
      $data_start1 =1;
      $data_end1 =0;
    }
    if($previous_line1 =~ /^\s*c/i){
      $data_end1 =1;
      $data_start1 =0;
    }
    if($data_start1 == 1 && $data_end1 ==0){
      if($previous_line1=~ /^\s*m\s*/i){
      $data1 = $data1." ".$previous_line1;
      }else {
      $data1 = $data1." ".$previous_line1;
      }
      $data1 =~ s/^\s*//;
      $data1 =~ s/=\s+/=/;
      @new_data1 = (split(/\s+/,$data1));
      $mdata1 = shift (@new_data1);
      @{$TEMP_SPICE_DATA{$mdata1}} = @new_data1;
    }
  }
  $previous_line1 = $next_line1;
  }#while
  close(READ_CAP_FLAT_SP);
  foreach my $tr(keys %TEMP_SPICE_DATA){
     my @tr_data = @{$TEMP_SPICE_DATA{$tr}};
     my ($temp_drain,$temp_gate,$temp_source,$temp_type) = @tr_data[0,1,2,4];
     foreach my $tr_port (@cell_data1){
       if(($tr_port =~ /vdd/) || ($tr_port =~ /VDD/) || ($tr_port =~ /vss/) || ($tr_port =~ /VSS/) || ($tr_port =~ /gnd/) || ($tr_port =~ /GND/) || ($tr_port =~ /vdar_t/i)||($tr_port =~ /vdio_t/i)){}
       else {
         if($cellName1 =~ m/mux/i){
            #$in_port_hash{"a"} = 1 if(!exists $in_port_hash{"a"});
            $in_port_hash{"A"} = 1 if(!exists $in_port_hash{"A"});
            #$in_port_hash{"b"} = 1 if(!exists $in_port_hash{"b"});
            $in_port_hash{"B"} = 1 if(!exists $in_port_hash{"B"});
            #$in_port_hash{"sel_a"} = 1 if(!exists $in_port_hash{"sel_a"});
            $in_port_hash{"SEL_A"} = 1 if(!exists $in_port_hash{"SEL_A"});
            #$out_port_hash{"qp"} = 1 if(!exists $out_port_hash{"qp"});
            $out_port_hash{"QP"} = 1 if(!exists $out_port_hash{"QP"});
         }else{
            if($tr_port eq $temp_gate){
              $in_port_hash{$tr_port} = 1 if(!exists $in_port_hash{$tr_port});
            }elsif((($tr_port eq $temp_drain) || ($tr_port eq $temp_source)) && ($tr_port ne $temp_gate)){
               $out_port_hash{$tr_port} = 1 if(!exists $out_port_hash{$tr_port});
            }
         }#if not mux
       }
     }
  }
  return(\%in_port_hash, \%out_port_hash);
}#sub get_input_output_list

sub get_reduce_cap_sp_data{
  my $flat_reduce_cap_sp_file = $_[0];
  my @cell_data1 = ();
  my $read_data_of_subckt1 = 0;
  my $end_data_of_subckt1 = 0;
  my $cellName1 = "";
  my $data1 = "";
  my $data_start1 = 0;
  my $data_end1 = 0;
  my $mdata1 = "";
  my @new_data1 = ();
  my %TEMP_SPICE_DATA = ();
  my %in_port_hash = ();
  my %out_port_hash = ();

  open(READ_CAP_FLAT_SP,"$flat_reduce_cap_sp_file");
  my $previous_line1 = "";
  my $next_line1 = "";
  while(<READ_CAP_FLAT_SP>){
  chomp();
  if($_ =~ /\*/){next;}
  if($_ =~ /^\+/){
    s/\s+$//;
    s/^\+//;
    $previous_line1 = $previous_line1." ".$_;
    next;
  }
  $next_line1 = $_;
  if($previous_line1 =~ /^\s*\.subckt/i){
    $read_data_of_subckt1 = 1;
    $end_data_of_subckt1 = 0;
    $previous_line1 =~ s/^\s*\.(subckt|SUBCKT)\s*//;
    @cell_data1 = (split(/\s+/,$previous_line1));
    $cellName1 = shift(@cell_data1);
  }
  if($previous_line1 =~ /^\s*\.end/i){
    $end_data_of_subckt1 = 1;
    $read_data_of_subckt1 = 0;
  }
  if($read_data_of_subckt1 == 1 && $end_data_of_subckt1 == 0){
    if($previous_line1=~ /^\s*m\s*/i){
      $data1 = "";
      @new_data1 = ();
      $mdata1 = "";
      $data_start1 =1;
      $data_end1 =0;
    }
    if($previous_line1 =~ /^\s*c/i){
      $data_end1 =1;
      $data_start1 =0;
    }
    if($data_start1 == 1 && $data_end1 ==0){
      if($previous_line1=~ /^\s*m\s*/i){
      $data1 = $data1." ".$previous_line1;
      }else {
      $data1 = $data1." ".$previous_line1;
      }
      $data1 =~ s/^\s*//;
      $data1 =~ s/=\s+/=/;
      @new_data1 = (split(/\s+/,$data1));
      $mdata1 = shift (@new_data1);
      @{$TEMP_SPICE_DATA{$mdata1}} = @new_data1;
    }
  }
  $previous_line1 = $next_line1;
  }#while
  close(READ_CAP_FLAT_SP);
}#sub get_reduce_cap_sp_data

#---------------------------------------------------------------------------------------------------------------#
#################################################################################################################
############################### function to get sequential/combinational ckt #####################################
sub get_sequential {
  my $file = $_[0];
  if(-e $file){}else{print "WARN: file does not exist\n";return}
  #---------------------------------------variable initilaized-----------------------------------------#
  my $cellName = "";
  my @cell_data = ();
  my $read_data_of_subckt = 0;
  my $end_data_of_subckt = 0;
  my $data = "";
  my @new_data = ();
  my $mdata = "";
  my $data_start = 0;
  my $data_end = 0;
  my %SPICE_DATA = ();
  my %PORT_HASH = ();
  my %GATE_HASH = ();
  my %DRAIN_HASH = ();
  my %SOURCE_HASH = ();
  my %PTYPE_DRAIN_HASH = ();
  my %COMMON_DRAIN_HASH = ();
  #----------------------------------------------read .spi file-----------------------------------------#
  open(READ,$file);
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
    foreach my $port(@cell_data){
      $PORT_HASH{$port} = 1;
    }
  }
  if($_ =~ /^\s*\.end/i){
    $end_data_of_subckt = 1;
    $read_data_of_subckt = 0;
  }
    if($read_data_of_subckt == 1 && $end_data_of_subckt == 0){
      if($_ =~ /^\s*m\s*/i){
        $data = "";
        @new_data = ();
        $mdata = "";
        $data_start = 1;
        $data_end = 0;
      }if($_ =~ /^\s*c/i){
        $data_end = 1;
        $data_start = 0;
      }
      if($data_start == 1 && $data_end == 0){
        if($_ =~ /^\s*m\s*/i){
          $data = $data." ".$_;
        }else{
          $data = $data." ".$_;
        }
          $data =~ s/^\s*//;
          @new_data = (split(/\s+/,$data));
          $mdata = shift (@new_data);
          my ($drain,$gate,$source,$type) = (split(/\s+/,$data))[1,2,3,5];
          my $newdata = $drain." ".$gate." ".$source." ".$type;
          $SPICE_DATA{$mdata} = $newdata;
      }# data start
    }#read data of subckt
  }#while
  
  ########################### Making Drain, Source & Gate hases ############################
  foreach my $mdata (keys %SPICE_DATA){
    my $value = $SPICE_DATA{$mdata}; 
    my ($drain,$gate,$source,$type) = (split(/\s+/,$value));
    my @drain_val = ();
    my @gate_val = ();
    my @src_val = ();
    if(exists $DRAIN_HASH{$drain}){
      @drain_val = @{$DRAIN_HASH{$drain}};
      push (@drain_val,$mdata);
    }else{
      push(@drain_val,$mdata);
    }
    @{$DRAIN_HASH{$drain}} = @drain_val;
  
    if(exists $GATE_HASH{$gate}){
      @gate_val = @{$GATE_HASH{$gate}};
      push (@gate_val,$mdata);
    }else{
      push(@gate_val,$mdata);
    }
    @{$GATE_HASH{$gate}} = @gate_val;
  
    if(exists $SOURCE_HASH{$source}){
      @src_val = @{$SOURCE_HASH{$source}};
      push (@src_val,$mdata);
    }else{
      push(@src_val,$mdata);
    }
    @{$SOURCE_HASH{$source}} = @src_val;
    
  }
  ############################ populating common drain/src hash ##############################
  foreach my $mdata (keys %SPICE_DATA){
    my $value = $SPICE_DATA{$mdata}; 
    my ($drain,$gate,$source,$type) = (split(/\s+/,$value));
    if($type =~ /p/i){
       if($source  =~ /vdd/i ){
         $PTYPE_DRAIN_HASH{$drain} = $gate;
       }elsif($drain =~ /vdd/i){
         $PTYPE_SRC_HASH{$source} = $gate;
       }
    }
  }
  foreach my $mdata (keys %SPICE_DATA){
    my $value = $SPICE_DATA{$mdata}; 
    my ($drain,$gate,$source,$type) = (split(/\s+/,$value));
    if($type =~ /n/i){
       if($source =~ /vss/i){
         if(exists $PTYPE_DRAIN_HASH{$drain} && $gate eq $PTYPE_DRAIN_HASH{$drain}){
           if(!exists $PORT_HASH{$drain}){
              $COMMON_DRAIN_HASH{$drain} = $gate;
           }else{
              $COMMON_DRAIN_HASH{$gate} = $drain;
           }
         }
       }elsif($drain =~ /vss/i){
         if(exists $PTYPE_SRC_HASH{$source} && $gate eq $PTYPE_SRC_HASH{$source}){
           if(!exists $PORT_HASH{$source}){
              $COMMON_DRAIN_HASH{$source} = $gate;
           }else{
              $COMMON_DRAIN_HASH{$gate} = $source;
           }
         }
       }
    }
  }
  
  
  ################################# deleting n/p trans ###################################
  
  foreach my $mdata (keys %SPICE_DATA){
    my $value = $SPICE_DATA{$mdata}; 
    my ($drain,$gate,$source,$type) = (split(/\s+/,$value));
    if((exists $COMMON_DRAIN_HASH{$drain} && $gate eq $COMMON_DRAIN_HASH{$drain} && (($source =~ /vss/i) || ($source =~ /vdd/i)))){
      delete $SPICE_DATA{$mdata};
    }elsif(exists $COMMON_DRAIN_HASH{$source} && $gate eq $COMMON_DRAIN_HASH{$source} && (($drain =~ /vss/i) || ($drain =~ /vdd/i))){
      delete $SPICE_DATA{$mdata};
    }elsif(exists $COMMON_DRAIN_HASH{$gate} && $drain eq $COMMON_DRAIN_HASH{$gate} && (($source =~ /vss/i) || ($source =~ /vdd/i))){
      delete $SPICE_DATA{$mdata};
    }elsif(exists $COMMON_DRAIN_HASH{$gate} && $source eq $COMMON_DRAIN_HASH{$gate} && (($drain =~ /vss/i) || ($drain =~ /vdd/i))){
      delete $SPICE_DATA{$mdata};
    }
  }
  
  ########################## Making one 2 one mapping ###########################
  my %NEW_MAP_HASH = ();
  foreach my $key (keys %COMMON_DRAIN_HASH){
    my $value = $COMMON_DRAIN_HASH{$key};
    if(exists $COMMON_DRAIN_HASH{$value} && !exists $PORT_HASH{$value}){
       $NEW_MAP_HASH{$key} = $COMMON_DRAIN_HASH{$value};
    }else{
       $NEW_MAP_HASH{$key} = $value;
    }
  }
  
  ########################## Replacing the values in transistor hash #################
  foreach my $tran(keys %SPICE_DATA){
    my $data = $SPICE_DATA{$tran};
    my ($drain,$gate,$source,$type) = split(/\s+/,$data);
    if(exists $NEW_MAP_HASH{$drain}){
       $drain = $NEW_MAP_HASH{$drain};
    }
    if(exists $NEW_MAP_HASH{$gate}){
       $gate = $NEW_MAP_HASH{$gate};
    }
    if(exists $NEW_MAP_HASH{$source}){
       $source = $NEW_MAP_HASH{$source};
    }
    my $newdata = $drain." ".$gate." ".$source." ".$type;
    $SPICE_DATA{$tran} = $newdata;
  }#foreach trans
  
  ####### Deleting the transistor from DRAIN_HASH, SOURCE_HASH & GATE_HASH which does not exist in Transistor hash ######
  foreach my $drain(keys %DRAIN_HASH){
    my @drain_val = @{$DRAIN_HASH{$drain}};
    my @new_value = ();
    foreach my $trans_name (@drain_val){
      if(exists $SPICE_DATA{$trans_name}){
        push(@new_value,$trans_name);
      }
    }
    @{$DRAIN_HASH{$drain}} = @new_value;
  }
  
  foreach my $gate(keys %GATE_HASH){
    my @gate_val = @{$GATE_HASH{$gate}};
    my @new_value = ();
    foreach my $trans_name (@gate_val){
      if(exists $SPICE_DATA{$trans_name}){
        push(@new_value,$trans_name);
      }
    }
    @{$GATE_HASH{$gate}} = @new_value;
  }
  
  foreach my $src(keys %SOURCE_HASH){
    my @src_val = @{$SOURCE_HASH{$src}};
    my @new_value = ();
    foreach my $trans_name (@src_val){
      if(exists $SPICE_DATA{$trans_name}){
        push(@new_value,$trans_name);
      }
    }
    @{$SOURCE_HASH{$src}} = @new_value;
  }
  
  
  
  ########################## Replacing the values in of src/drain/gate using MAPPING hash #################
  foreach my $drain (keys %NEW_MAP_HASH){
    #------------------------------if key exists in drain hash------------------------------------#
    if(exists $DRAIN_HASH{$drain}){
      my $gate_value = $NEW_MAP_HASH{$drain};
      if(exists $DRAIN_HASH{$gate_value}){
        my @drain_value_1 = @{$DRAIN_HASH{$gate_value}};
        my @drain_value_2 = @{$DRAIN_HASH{$drain}};
  
        my @new_value = @drain_value_1;
        foreach my $trans_name (@drain_value_2){
          my $found = 0;
          foreach my $stored_val (@drain_value_1){
            if($trans_name eq $stored_val){$found = 1;last;}
          }
          if($found == 0){
             push(@new_value,$trans_name);
          }
        }
        delete $DRAIN_HASH{$drain};
        delete $DRAIN_HASH{$gate_value};
        @{$DRAIN_HASH{$gate_value}} = @new_value if(@new_value > 0);
      }else{
        my @drain_value = @{$DRAIN_HASH{$drain}};
        delete $DRAIN_HASH{$drain};
        @{$DRAIN_HASH{$gate_value}} = @drain_value if(@drain_value > 0);
      }
    }
    #-----------------------------------if key exists in gate hash------------------------------#
    if(exists $GATE_HASH{$drain}){
       my $gate_value = $NEW_MAP_HASH{$drain};
       if(exists $GATE_HASH{$gate_value}){
         my @gate_value_1 = @{$GATE_HASH{$gate_value}};
         my @gate_value_2 = @{$GATE_HASH{$drain}};
  
         my @new_value = @gate_value_1;
         foreach my $trans_name(@gate_value_2){
           my $found = 0;
           foreach my $stored_val (@gate_value_1){
             if($trans_name eq $stored_val){$found =1;last;}
           }
           if($found == 0){
             push(@new_value,$trans_name);
           }
         }
         delete $GATE_HASH{$drain};
         delete $GATE_HASH{$gate_value};
         @{$GATE_HASH{$gate_value}} = @new_value if(@new_value > 0);
       }else {
         my @gatevalue = @{$GATE_HASH{$drain}};
         delete $GATE_HASH{$drain};
         @{$GATE_HASH{$gate_value}} = @gatevalue if(@gatevalue > 0);
       }
    }
    #----------------------------if drian exists in source hash--------------------------#
    if(exists $SOURCE_HASH{$drain}){
       my $gate_value = $NEW_MAP_HASH{$drain};
       if(exists $SOURCE_HASH{$gate_value}){
         my @source_value_1 = @{$SOURCE_HASH{$gate_value}};
         my @source_value_2 = @{$SOURCE_HASH{$drain}}; 
  
         my @new_value = @source_value_1;
         foreach my $trans_name(@source_value_2){
           my $found = 0;
           foreach my $stored_val (@source_value_1){
             if($trans_name eq $stored_val){$found = 1;last;}
           }
           if($found == 0){
             push (@new_value,$trans_name);
           }
         }
         delete $SOURCE_HASH{$drain};
         delete $SOURCE_HASH{$gate_value};
         @{$SOURCE_HASH{$gate_value}} = @new_value if(@new_value > 0);
       }else {
         my @source_value = @{$SOURCE_HASH{$drain}};
         delete $SOURCE_HASH{$drain};
         @{$SOURCE_HASH{$gate_value}} = @source_value if(@source_value > 0); 
       }
    }
  }#foreach common drain hash
  
  
  &delete_map_trans;
  ############################# Deleting the n&p transistor without vss/vdd connection #####################
  sub delete_map_trans{
   my %second_map_hash = ();
   foreach my $mdata (keys %SPICE_DATA){
     my $value = $SPICE_DATA{$mdata}; 
     my ($drain,$gate,$source,$type) = (split(/\s+/,$value));
     foreach my $mdata1 (keys %SPICE_DATA){
       my $value1 = $SPICE_DATA{$mdata1}; 
       my ($drain1,$gate1,$source1,$type1) = (split(/\s+/,$value1));
       if($type ne $type1 && $drain eq $drain1 && $gate eq $gate1 && $source eq $source1){
          delete $SPICE_DATA{$mdata};
          delete $SPICE_DATA{$mdata1};
          if(exists $PORT_HASH{$drain}){ $second_map_hash{$source} = $drain;}
          else{ $second_map_hash{$drain} = $source;}
       }
     }
   }
    
   foreach my $tran(keys %SPICE_DATA){
     my $data = $SPICE_DATA{$tran};
     my ($drain,$gate,$source,$type) = split(/\s+/,$data);
     if(exists $second_map_hash{$drain}){
        $drain = $second_map_hash{$drain};
     }
     if(exists $second_map_hash{$gate}){
        $gate = $second_map_hash{$gate};
     }
     if(exists $second_map_hash{$source}){
        $source = $second_map_hash{$source};
     }
     my $newdata = $drain." ".$gate." ".$source." ".$type;
     $SPICE_DATA{$tran} = $newdata;
   }#foreach trans
   
   ####### Deleting the transistor from DRAIN_HASH, SOURCE_HASH & GATE_HASH which does not exists in Transistor hash ######
   foreach my $drain(keys %DRAIN_HASH){
     my @drain_val = @{$DRAIN_HASH{$drain}};
     my @new_value = ();
     foreach my $trans_name (@drain_val){
       if(exists $SPICE_DATA{$trans_name}){
         push(@new_value,$trans_name);
       }
     }
     @{$DRAIN_HASH{$drain}} = @new_value;
   }
   
   foreach my $gate(keys %GATE_HASH){
     my @gate_val = @{$GATE_HASH{$gate}};
     my @new_value = ();
     foreach my $trans_name (@gate_val){
       if(exists $SPICE_DATA{$trans_name}){
         push(@new_value,$trans_name);
       }
     }
     @{$GATE_HASH{$gate}} = @new_value;
   }
   
   foreach my $src(keys %SOURCE_HASH){
     my @src_val = @{$SOURCE_HASH{$src}};
     my @new_value = ();
     foreach my $trans_name (@src_val){
       if(exists $SPICE_DATA{$trans_name}){
         push(@new_value,$trans_name);
       }
     }
     @{$SOURCE_HASH{$src}} = @new_value;
   }
   
   
   
   ########################## Replacing the values in of src/drain/gate using MAPPING hash #################
   my @map_keys = keys %second_map_hash;
   if(@map_keys <= 0){return;}
   foreach my $drain (keys %second_map_hash){
     #------------------------------if key exists in drain hash------------------------------------#
     if(exists $DRAIN_HASH{$drain}){
       my $gate_value = $second_map_hash{$drain};
       if(exists $DRAIN_HASH{$gate_value}){
         my @drain_value_1 = @{$DRAIN_HASH{$gate_value}};
         my @drain_value_2 = @{$DRAIN_HASH{$drain}};
   
         my @new_value = @drain_value_1;
         foreach my $trans_name (@drain_value_2){
           my $found = 0;
           foreach my $stored_val (@drain_value_1){
             if($trans_name eq $stored_val){$found = 1;last;}
           }
           if($found == 0){
              push(@new_value,$trans_name);
           }
         }
         delete $DRAIN_HASH{$drain};
         delete $DRAIN_HASH{$gate_value};
         @{$DRAIN_HASH{$gate_value}} = @new_value if(@new_value > 0);
       }else{
         my @drain_value = @{$DRAIN_HASH{$drain}};
         delete $DRAIN_HASH{$drain};
         @{$DRAIN_HASH{$gate_value}} = @drain_value if(@drain_value > 0);
       }
     }
     #-----------------------------------if key exists in gate hash------------------------------#
     if(exists $GATE_HASH{$drain}){
        my $gate_value = $second_map_hash{$drain};
        if(exists $GATE_HASH{$gate_value}){
          my @gate_value_1 = @{$GATE_HASH{$gate_value}};
          my @gate_value_2 = @{$GATE_HASH{$drain}};
   
          my @new_value = @gate_value_1;
          foreach my $trans_name(@gate_value_2){
            my $found = 0;
            foreach my $stored_val (@gate_value_1){
              if($trans_name eq $stored_val){$found =1;last;}
            }
            if($found == 0){
              push(@new_value,$trans_name);
            }
          }
          delete $GATE_HASH{$drain};
          delete $GATE_HASH{$gate_value};
          @{$GATE_HASH{$gate_value}} = @new_value if(@new_value > 0);
        }else {
          my @gatevalue = @{$GATE_HASH{$drain}};
          delete $GATE_HASH{$drain};
          @{$GATE_HASH{$gate_value}} = @gatevalue if(@gatevalue > 0);
        }
     }
     #----------------------------if drian exists in source hash--------------------------#
     if(exists $SOURCE_HASH{$drain}){
        my $gate_value = $second_map_hash{$drain};
        if(exists $SOURCE_HASH{$gate_value}){
          my @source_value_1 = @{$SOURCE_HASH{$gate_value}};
          my @source_value_2 = @{$SOURCE_HASH{$drain}}; 
   
          my @new_value = @source_value_1;
          foreach my $trans_name(@source_value_2){
            my $found = 0;
            foreach my $stored_val (@source_value_1){
              if($trans_name eq $stored_val){$found = 1;last;}
            }
            if($found == 0){
              push (@new_value,$trans_name);
            }
          }
          delete $SOURCE_HASH{$drain};
          delete $SOURCE_HASH{$gate_value};
          @{$SOURCE_HASH{$gate_value}} = @new_value if(@new_value > 0);
        }else {
          my @source_value = @{$SOURCE_HASH{$drain}};
          delete $SOURCE_HASH{$drain};
          @{$SOURCE_HASH{$gate_value}} = @source_value if(@source_value > 0); 
        }
     }
   }#foreach common drain hash
   &delete_map_trans;
  }#sub delete_map_trans
  
  ############################ Writing new spice file ########################### 
  open (WRITE, ">sorted.spi");
  foreach (keys %SPICE_DATA){
    my $data = $SPICE_DATA{$_};
    print WRITE "$_ $data\n";
  }
  close WRITE;
  ################################ check seq #################################
  my @out_port = ();
  foreach my $port (keys %PORT_HASH){
    if(($port =~ /vdd/) || ($port =~ /vss/)){}
    else{
       if((exists $GATE_HASH{$port}) && ((exists $DRAIN_HASH{$port}) || (exists $SOURCE_HASH{$port}))){
          push(@out_port, $port);
       }
    }
  }
  if(@out_port < 1){
  #print "This cell \"$cellName\" is Combinational Cell\n";
  return ("combi");
  }else {
  #print "This cell \"$cellName\" is Sequential Cell\n";
  }
  
  ################################## for latch #######################################
  my %IN_HASH = ();
  my %OUT_HASH = ();
  foreach my $tr (keys %SPICE_DATA){
    my $data = $SPICE_DATA{$tr};
    my ($drain,$gate,$source,$type) = split(/\s+/,$data);
    if(exists $PORT_HASH{$gate} && (($source eq "vdd" || $drain eq "vdd") || ($source eq "vss" || $drain eq "vss"))){
      if(exists $PORT_HASH{$source} && ($drain eq "vdd" || $drain eq "vss")){
         $IN_HASH{$gate} = 1 if(!exists $IN_HASH{$gate} && !exists $OUT_HASH{$gate});
         $OUT_HASH{$source} = 1 if(!exists $OUT_HASH{$source} && !exists $IN_HASH{$source});
      }elsif(exists $PORT_HASH{$drain} && ($source eq "vdd" || $source eq "vss")){
         $IN_HASH{$gate} = 1 if(!exists $IN_HASH{$gate} && !exists $OUT_HASH{$gate});
         $OUT_HASH{$drain} = 1 if(!exists $OUT_HASH{$drain} && !exists $IN_HASH{$drain});
      }
    }
  }
  
  my @in_port = ();
  my $reset_sig = "";
  my $clk_enable = "";
  foreach my $in (keys %IN_HASH){
    if(exists $GATE_HASH{$in} && !exists $SOURCE_HASH{$in} && !exists $DRAIN_HASH{$in}){
       #print "reset signal is : $in\n";
       $reset_sig = $in;
    }else{
       push(@in_port, $in);
    } 
  }
  
  foreach my $port (keys %PORT_HASH){
    if($port eq "vss" || $port eq "vdd"){}
    else{
       if(!exists $IN_HASH{$port} && !exists $OUT_HASH{$port}){
         #print  "clock enable signal is: $port \n"; 
          $clk_enable = $port;
       }
    }
  }
  
  #print "input @in_port\n";
  my @out = keys %OUT_HASH;
  #print "out @out\n";
  #if($clk_enable ne ""){return $clk_enable;}
  #print "Latch : reset = $reset_sig,clock = $clk_enable , output = @out , input = @in_port\n";
  if($clk_enable ne "" && @in_port != 0 && @out != 0){return ($clk_enable, $out[0],$in_port[0]),"latch";}
  
  ################################## Making the group of connected transistors ######################################
  my @trans_vdd = @{$DRAIN_HASH{"vdd"}};
  push (@trans_vdd, @{$SOURCE_HASH{"vdd"}});
  my @vdd_tr_grp = ();
  for(my $i=0; $i<@trans_vdd; $i++){
      my @conn_tr = ($trans_vdd[$i]);
      my $data = $SPICE_DATA{$trans_vdd[$i]};
      my ($drain,$gate,$source,$type) = split(/\s+/,$data);
      if($source eq "vdd"){
         my @trans = @{$SOURCE_HASH{$drain}};
         foreach my $tr (@trans){
           push (@conn_tr, $tr);
         }
      }else{
         my @trans = @{$DRAIN_HASH{$source}};
         foreach my $tr (@trans){
           push (@conn_tr, $tr);
         }
      }
      push (@vdd_tr_grp,[@conn_tr]);
  }#foreach my pwr tr
  
  my @trans_vss = @{$DRAIN_HASH{"vss"}};
  push (@trans_vss, @{$SOURCE_HASH{"vss"}});
  my @vss_tr_grp = ();
  for(my $i=0; $i<@trans_vss; $i++){
      my @conn_tr = ($trans_vss[$i]);
      my $data = $SPICE_DATA{$trans_vss[$i]};
      my ($drain,$gate,$source,$type) = split(/\s+/,$data);
      if($source eq "vss"){
         my @trans = @{$SOURCE_HASH{$drain}};
         foreach my $tr (@trans){
           push (@conn_tr, $tr);
         }
      }else{
         my @trans = @{$DRAIN_HASH{$source}};
         foreach my $tr (@trans){
           push (@conn_tr, $tr);
         }
      }
      push (@vss_tr_grp,[@conn_tr]);
  }#foreach my ground tr
  
  my @final_tr_grp = ();
  for(my $i=0; $i<@vdd_tr_grp; $i++){
      my @vdd_tr = @{$vdd_tr_grp[$i]};
      for(my $j=0; $j<@vss_tr_grp; $j++){
          if($vss_tr_grp[$j] eq ""){next;}
          my @vss_tr = @{$vss_tr_grp[$j]};
          my $count = 0;
          for(my $k=0; $k<@vdd_tr; $k++){
              my $data = $SPICE_DATA{$vdd_tr[$k]};
              my ($drain,$gate,$source,$type) = split(/\s+/,$data);
              for(my $l=0; $l<@vss_tr; $l++){
                  my $data1 = $SPICE_DATA{$vss_tr[$l]};
                  my ($drain1,$gate1,$source1,$type1) = split(/\s+/,$data1);
                  if(($type ne $type1) && ($gate eq $gate1)){
                      $count++;
                  }
              }
          }
          if($count == 2){
            push(@final_tr_grp,[@vdd_tr , @vss_tr]);
            delete $vss_tr_grp[$j];
            last;
          }
      }
  }
  
  #foreach my $grp (@final_tr_grp){
  #  print "vd @$grp\n";
  #}
  
  #################################### Verifying Signals #####################################
  my @input_list = ();
  my $clock_signal = "";
  foreach my $port (keys %PORT_HASH){
    if(($port =~ /vdd/) || ($port =~ /vss/)){
    }elsif((exists $GATE_HASH{$port}) && ((exists $DRAIN_HASH{$port}) || (exists $SOURCE_HASH{$port}))){
        push(@output_list,$port);
    }else{
       my $count = 0;
       foreach my $group (@final_tr_grp){
         my @tr = @$group;
         my $conn_found = 0;
         foreach my $t (@tr){
           my $data = $SPICE_DATA{$t};
           my ($drain,$gate,$source,$type) = split(/\s+/,$data);
           if($port eq $gate){$conn_found = 1;}
         }
         if($conn_found == 1){$count++;}
       }
       if($count == @final_tr_grp){$clock_signal = $port;}
       elsif($count == 1){ push(@input_list, $port);}
    }
  }
  #print "Flop : input: @input_list | clock: $clock_signal | output: @output_list\n";
  #return $clock_signal;
  return ($clock_signal,$output_list[0], $input_list[0],"flop");
}#sub get_sequential

#----------------------------------------------------------------------------------------------------------------#
######################################## lib generation for Macro #######################################

sub write_block_lib {
use liberty;
my $file = $_[0];
my %spice_data = ();
my %pin_capacitance = ();
my %port_list = ();
my %gate_port = ();
my %source_port = ();
my %drain_port = ();
my %gate_hash = ();
my %source_hash = ();
my %drain_hash = ();
my %port_vs_width = ();
my %in_port = ();
my %out_port = ();
my @cell_data = ();
my $cellName = "";
my $x = 11;

#-----------Reading file -------------------#
open(READ_SP,"$file");
  my $previous_line = "";
  my $next_line = "";
  while(<READ_SP>){
  chomp();
  if($_ =~ /\*/){next;}
  if($_ =~ /^\+/){
    s/\s+$//;
    s/^\+//;
    $previous_line = $previous_line." ".$_;
    next;
  }
  $next_line = $_;
  if($previous_line =~ /^\s*\.subckt/i){
    $read_data_of_subckt = 1;
    $end_data_of_subckt = 0;
    $previous_line =~ s/^\s*\.(subckt|SUBCKT)\s*//;
    @cell_data = (split(/\s+/,$previous_line));
    $cellName = shift(@cell_data);
  }elsif($previous_line =~ /^\s*\.end/i){
    $end_data_of_subckt = 1;
    $read_data_of_subckt = 0;
  }
  if($read_data_of_subckt == 1 && $end_data_of_subckt == 0){
    if($previous_line=~ /^\s*m\s*/i){
      $data_start =1;
      $data_end =0;
    }elsif($previous_line =~ /^\s*c/i){
      my ($pin, $cap) = (split(/\s+/,$previous_line))[1,3];
      if($cap =~ m/f/){
        $cap =~ s/f//;
        $cap = $cap/1000;
      }elsif($cap =~ m/n/){
        $cap =~ s/n//;
        $cap = $cap*1000;
      }else{
        $cap =~ s/p//;
      }

      $pin_capacitance{$pin} = $cap;
      $data_end =1;
      $data_start =0;
    }
    if($data_start == 1 && $data_end ==0){
      #print "mdata $previous_line\n";
      my @new_data = (split(/\s+/,$previous_line));
      my $mdata = shift (@new_data);
      @{$spice_data{$mdata}} = @new_data;
    }
  }
  $previous_line = $next_line;
  }#while
  close(READ_SP);

  foreach my $port(@cell_data){
    if(($port =~ /vdd/i) || ($port =~ /vss/i) || ($port =~ /gnd/i) || ($port =~ /vdar_t/i)|| ($port =~ /vdio_t/i)){}
    else{ $port_list{$port} = 1;}
  }#foreach port 

  foreach my $tr ( keys %spice_data){
    my @data = @{$spice_data{$tr}};
    my $drain = $data[0];
    my $gate = $data[1];
    my $source = $data[2];
    #my $data_line = join " ",@data;

    if(exists $port_list{$gate}){
      $gate_port{$gate} = 1 if(!exists $gate_port{$gate}); 
    } 
    if(exists $port_list{$source}){
      $source_port{$source} = 1 if(!exists $source_port{$source}); 
    } 
    if(exists $port_list{$drain}){
      $drain_port{$drain} = 1 if(!exists $drain_port{$drain}); 
    } 

    #------------Making src/gate/drain hashes ----------#
    if(exists $drain_hash{$drain}){
       push(@{$drain_hash{$drain}},$tr);
    }else{
       $drain_hash{$drain} = [$tr];   
    }
    if(exists $gate_hash{$gate}){
       push(@{$gate_hash{$gate}},$tr);
    }else{
       $gate_hash{$gate} = [$tr];   
    }
    if(exists $source_hash{$source}){
       push(@{$source_hash{$source}},$tr);
    }else{
       $source_hash{$source} = [$tr];   
    }

    #--- Making hash of port vs width of p-type only ---#
    if($data[4] =~ m/\bPD\b/i){
       my $width_str = $data[6];
       my $width = (split(/\=/,$width_str))[1];
       #-------------- check is unit in micron -------------#
       if($unit_in_micron == 0){
         my $one_meter = 1000000; 
         if($width =~/e/){
            my ($digit,$exp) = (split(/e/,$width))[0,1];
            if($exp =~/-/){
               my $num = (split(/-/,$exp))[1];
               my $new_num = 10**$num;
               $width = ($digit*$one_meter)/$new_num;
            }elsif($exp =~ /\+/){
               my $num = (split(/\+/,$exp))[1];
               my $new_num = 10**$num;
               $width = ($digit*$one_meter*$new_num);
            }
         }
       }else{$width = $width;}
       #--------------- Making port vs width hash -------------------#
       #if(exists $port_list{$drain}){
         if(exists $port_vs_width{$drain}){
            push(@{$port_vs_width{$drain}}, $width);
         }else{
            $port_vs_width{$drain} = [$width];
         }
       #}
       #if(exists $port_list{$source}){
         if(exists $port_vs_width{$source}){
            push(@{$port_vs_width{$source}}, $width);
         }else{
            $port_vs_width{$source} = [$width];
         }
       #}
    }  
  }#foreach transistor 

  foreach my $port(keys %port_list){
    if(exists $gate_port{$port} && !exists $source_port{$port} && !exists $drain_port{$port}){
       $in_port{$port} = 1;
    }else{
       $out_port{$port} = 1;
    }
  }
  

  #-----------writing lib file -------------------#   
  liberty::si2drPIInit(\$x);
  my $group1 = liberty::si2drPICreateGroup($cellName, "library", \$x);
  my $att = liberty::si2drGroupCreateAttr($group1, "capacitive_load_unit", $liberty::SI2DR_COMPLEX, \$x);
  liberty::si2drComplexAttrAddStringValue($att, "1, pf", \$x);
  #liberty::si2drComplexAttrAddInt32Value($att, 1, \$x);
  #liberty::si2drComplexAttrAddStringValue($att, "pf", \$x);

  my $att1 = liberty::si2drGroupCreateAttr($group1, "time_unit", $liberty::SI2DR_SIMPLE, \$x);
  liberty::si2drSimpleAttrSetStringValue($att1, "1ns", \$x);

  my $att2 = liberty::si2drGroupCreateAttr($group1, "voltage_unit", $liberty::SI2DR_SIMPLE, \$x);
  liberty::si2drSimpleAttrSetStringValue($att2, "1V", \$x);

  my $att3 = liberty::si2drGroupCreateAttr($group1, "current_unit", $liberty::SI2DR_SIMPLE, \$x);
  liberty::si2drSimpleAttrSetStringValue($att3, "1mA", \$x);

  my $att4 = liberty::si2drGroupCreateAttr($group1, "leakage_power_unit", $liberty::SI2DR_SIMPLE, \$x);
  liberty::si2drSimpleAttrSetStringValue($att4, "1mW", \$x);

  my $att5 = liberty::si2drGroupCreateAttr($group1, "pulling_resistance_unit", $liberty::SI2DR_SIMPLE, \$x);
  liberty::si2drSimpleAttrSetStringValue($att5, "1kohm", \$x);

  my $group2 = liberty::si2drGroupCreateGroup($group1,$cellName, "cell", \$x);

  foreach my $out (keys %out_port){
    my $max_cap = 0;
    if(exists $port_vs_width{$out}){
       my $cap = $pin_capacitance{$out};
       my @pmos_width = @{$port_vs_width{$out}};
       my $width = 0;
       foreach (@pmos_width){
         $width = $width + $_;
       }
       #### 1um = 10fF #####
       #### so, 1um = 10/1000pF => 1um = 10^-2pF#####
       $max_cap = $width/100 - $cap;
     }else{
       if(exists $source_hash{$out}){
         my @tran = @{$source_hash{$out}};
         foreach my $tr (@tran){
           my @data = @{$spice_data{$tr}};
           if(exists $port_vs_width{$data[0]}){
              my $cap = $pin_capacitance{$data[0]};
              my @pmos_width = @{$port_vs_width{$data[0]}};
              my $width = 0;
              foreach (@pmos_width){
                $width = $width + $_;
              }
              #### 1um = 10fF #####
              #### so, 1um = 10/1000pF => 1um = 10^-2pF#####
              $max_cap = $max_cap + $width/100 - $cap;
           }#if exists in port_vs_width
         }#foreach trans in source hash
       }#if out pin connected to source
       if(exists $drain_hash{$out}){
         my @tran = @{$drain_hash{$out}};
         foreach my $tr (@tran){
           my @data = @{$spice_data{$tr}};
           if(exists $port_vs_width{$data[2]}){
              my $cap = $pin_capacitance{$data[2]};
              my @pmos_width = @{$port_vs_width{$data[2]}};
              my $width = 0;
              foreach (@pmos_width){
                $width = $width + $_;
              }
              #### 1um = 10fF #####
              #### so, 1um = 10/1000pF => 1um = 10^-2pF#####
              $max_cap = $max_cap + $width/100 - $cap;
           }#if exists in port_vs_width
         }#foreach trans in drain hash
       }#if out pin connected to drain 
     }
    
    #print "out $out | @pmos_width | $width | $cap\n";
    if($set_case == 1){$out =~ tr/A-Z/a-z/;} 

    my $group2_1 = liberty::si2drGroupCreateGroup($group2,$out, "pin", \$x);
    my $attr = liberty::si2drGroupCreateAttr($group2_1, "direction", $liberty::SI2DR_SIMPLE, \$x);
    liberty::si2drSimpleAttrSetStringValue($attr, "output", \$x);
    my $attr1 = liberty::si2drGroupCreateAttr($group2_1, "max_fanout", $liberty::SI2DR_SIMPLE, \$x);
    liberty::si2drSimpleAttrSetFloat64Value($attr1, 10, \$x);
    my $attr2 = liberty::si2drGroupCreateAttr($group2_1, "max_capacitance", $liberty::SI2DR_SIMPLE, \$x);
    liberty::si2drSimpleAttrSetFloat64Value($attr2, $max_cap, \$x);
  }
  foreach my $in (keys %in_port){
    my $cap = $pin_capacitance{$in};

    if($set_case == 1){$in =~ tr/A-Z/a-z/;} 

    my $group2_1 = liberty::si2drGroupCreateGroup($group2, $in, "pin", \$x);
    my $attr1 = liberty::si2drGroupCreateAttr($group2_1, "direction", $liberty::SI2DR_SIMPLE, \$x);
    liberty::si2drSimpleAttrSetStringValue($attr1, "input", \$x);
    my $attr2 = liberty::si2drGroupCreateAttr($group2_1, "rise_capacitance", $liberty::SI2DR_SIMPLE, \$x);
    liberty::si2drSimpleAttrSetFloat64Value($attr2, $cap, \$x);
    my $attr3 = liberty::si2drGroupCreateAttr($group2_1, "fall_capacitance", $liberty::SI2DR_SIMPLE, \$x);
    liberty::si2drSimpleAttrSetFloat64Value($attr3, $cap, \$x);
    my $attr4 = liberty::si2drGroupCreateAttr($group2_1, "rise_capacitance_range", $liberty::SI2DR_COMPLEX, \$x);
    liberty::si2drComplexAttrAddFloat64Value($attr4, $cap, \$x);
    liberty::si2drComplexAttrAddFloat64Value($attr4, $cap, \$x);
    my $attr5 = liberty::si2drGroupCreateAttr($group2_1, "fall_capacitance_range", $liberty::SI2DR_COMPLEX, \$x);
    liberty::si2drComplexAttrAddFloat64Value($attr5, $cap, \$x);
    liberty::si2drComplexAttrAddFloat64Value($attr5, $cap, \$x);
    my $attr6 = liberty::si2drGroupCreateAttr($group2_1, "capacitance", $liberty::SI2DR_SIMPLE, \$x);
    liberty::si2drSimpleAttrSetFloat64Value($attr6, $cap, \$x);
    my $attr7 = liberty::si2drGroupCreateAttr($group2_1, "max_transition", $liberty::SI2DR_SIMPLE, \$x);
    liberty::si2drSimpleAttrSetFloat64Value($attr7, 0.120, \$x);

  }
  #liberty::si2drWriteLibertyFile("$cellName.lib", $group1, \$x);
  liberty::si2drWriteLibertyFile("$file.lib", $group1, \$x);
  liberty::si2drPIQuit(\$x);

  #------------- Reporting Error --------------#
  liberty::si2drPIInit(\$x);
  #liberty::si2drReadLibertyFile($cellName.".lib", \$x);
  liberty::si2drReadLibertyFile($file.".lib", \$x);
  liberty::si2drPIQuit(\$x); 

  #------------ remove "" from capacitive_load_unit -----------------#
  #my $old = $cellName.".lib";
  my $old = $file.".lib";
  my $new = "$old.tmp.$$";

  open(OLD, "< $old")         or die "can't open $old: $!";
  open(NEW, "> $new")         or die "can't open $new: $!";

  while (<OLD>) {
    if($_ =~ m/capacitive_load_unit/){
      s/\"//g;
    }
    (print NEW $_)          or die "can't write to $new: $!";
  }

  close(OLD)                  or die "can't close $old: $!";
  close(NEW)                  or die "can't close $new: $!";

  rename($new, $old)          or die "can't rename $new to $old: $!";

  #--------------------------------------------#

}#sub write_block_lib
#------------------------------------------------------------------------------------------------------------------------#
####################################################read seq spi file (latch)#############################################
sub read_file_for_latch_old {
  my $file = $_[0];
  my $clk = $_[1];
  my $out = $_[2];
  my $in = $_[3];
  my $cellName = "";
  my $vdd_pri = "";
  my $vdd_pri_val = "";
  my $vdd_sec = "";
  my $vdd_sec_val = "";
  my $vss_name = "";
  my $vss_val = "";
  my $wp = "";
  my $wn = "";
  my $new_vdd_1 = "";
  my $new_vdd_2 = "";
  my $new_vss = "";
  my @input_slew = ();
  my @opcap = ();
  my $end_data_of_subckt = 0;
  my $read_data_of_subckt = 0;
  my @get_data = ();
  my @cell_data = ();
  my %SPICE_DATA = ();
  my $data_start = 0;
  my $data_end =0;
  my $data = "";
  my @new_data = ();
  my $mdata = "";
  my %INPUT = ();
  my %OUTPUT = ();
  my @input_list = ();
  my @output_list = ();
  my $read_data_of_subckt_sp = 0;
  my $index = 0;
  my $new_file_spice = "";
#------------------------------------------------------------------------------#  
  open(READ,"$file");
  $file =~ s/.*\///;
  $new_file_spice = $file."\.ngspice";
  open(WRITE_NG,">$new_file_spice");
  while(<READ>){
    chomp();
    s/\*.*$//;
    if($_ =~ /^\s+$/){next;}
    if($_ =~ /^\s*\.subckt/i){
      print WRITE_NG "$_\n";
      $read_data_of_subckt_sp = 1;
    }elsif($_ =~ /^\s*\.end/i){
      $read_data_of_subckt_sp = 0;
      print WRITE_NG "$_\n";
    }elsif($read_data_of_subckt_sp == 1){
      s/ \$X.*=.*\$Y.*=.*\$D.*=.*$//;
      print WRITE_NG "$_\n";
    }
  }
  close(WRITE_NG);
  close(READ);
#-----------------------------------------------------------------------------------#
open(READ_SP,"$file");
my $previous_line = "";
my $next_line = "";
while(<READ_SP>){
chomp();
if($_ =~ /\*/){next;}
if($_ =~ /^\+/){
  s/\s+$//;
  s/^\+//;
  $previous_line = $previous_line." ".$_;
  next;
}
$next_line = $_;
if($previous_line =~ /^\s*\.subckt/i){
  $read_data_of_subckt = 1;
  $end_data_of_subckt = 0;
  $previous_line =~ s/^\s*\.(subckt|SUBCKT)\s*//;
  @cell_data = (split(/\s+/,$previous_line));
  $cellName = shift(@cell_data);
}
if($previous_line =~ /^\s*\.end/i){
  $end_data_of_subckt = 1;
  $read_data_of_subckt = 0;
}
if($read_data_of_subckt == 1 && $end_data_of_subckt == 0){
  if($previous_line=~ /^\s*m\s*/i){
    $data = "";
    @new_data = ();
    $mdata = "";
    $data_start =1;
    $data_end =0;
    $read_cell_data = 0;
  }
  if($previous_line =~ /^\s*c/i){
    $data_end =1;
    $data_start =0;
  }
  if($data_start == 1 && $data_end ==0){
    if($previous_line=~ /^\s*m\s*/i){
    $data = $data." ".$previous_line;
    }else {
    $data = $data." ".$previous_line;
    }
    $data =~ s/^\s*//;
    $data =~ s/=\s+/=/;
    @new_data = (split(/\s+/,$data));
    $mdata = shift (@new_data);
    @{$SPICE_DATA{$mdata}} = @new_data;
  }
}
$previous_line = $next_line;
}#while
close(READ_SP);
#-----------------------------------------------created input and output list------------------------------------------#
if($cellName eq ""){print "ERR:We are not getting cellName from .spi file\n";}
foreach my $mdata (sort {$a cmp $b}keys %SPICE_DATA){
  my @data_new = @{$SPICE_DATA{$mdata}};
  my $data_new_var = join" ",@data_new;
  my ($drain,$gate,$source,$type) = (split(/\s+/,$data_new_var))[0,1,2,4];
  foreach my $port (@cell_data){
    if(($port =~ /vdd/) || ($port =~ /VDD/) || ($port =~ /vss/) || ($port =~ /VSS/) || ($port =~ /gnd/) || ($port =~ /GND/) || ($port =~ /vdar_t/i)|| ($port =~ /vdio_t/i)){}
    else {
      if($cellName =~ m/mux/i){
         #$INPUT{"a"} = 1 if(!exists $INPUT{"a"});
         $INPUT{"A"} = 1 if(!exists $INPUT{"A"});
         #$INPUT{"b"} = 1 if(!exists $INPUT{"b"});
         $INPUT{"B"} = 1 if(!exists $INPUT{"B"});
         #$INPUT{"sel_a"} = 1 if(!exists $INPUT{"sel_a"}); 
         $INPUT{"SEL_A"} = 1 if(!exists $INPUT{"SEL_A"}); 
         #$OUTPUT{"qp"} = 1 if(!exists $OUTPUT{"qp"});
         $OUTPUT{"QP"} = 1 if(!exists $OUTPUT{"QP"});
         #if($port eq $gate || $port eq $source){
         #  $INPUT{$port} = 1 if(!exists $INPUT{$port});
         #}elsif($port eq $drain){
         #   $OUTPUT{$port} = 1 if(!exists $OUTPUT{$port});
         #}
      }else{
         if($port eq $gate){
           $INPUT{$port} = 1 if(!exists $INPUT{$port});
         }elsif((($port eq $drain) || ($port eq $source)) && ($port ne $gate)){
            $OUTPUT{$port} = 1 if(!exists $OUTPUT{$port});
         }
      }#if not mux
    }
  }
}# foreach line 

foreach my $in (keys %INPUT){
  push (@input_list,$in);
  $input_index{$in} = $index;
  $index++;
}
foreach my $out (keys %OUTPUT){
  push (@output_list,$out);
}
#--------------------------------------------------------------------------------------------------------#
###########################################parameter file#################################################
open(READ_PARA,"$parameter_file");
while(<READ_PARA>){
  chomp();
  if($_ =~ /vss/i){($vss_name,$vss_val) = (split(/=\s*/,$_))[0,1];}
  if($_ =~ /width\s*pmos/i){$wp = (split(/=\s*/,$_))[1];}
  if($_ =~ /width\s*nmos/i){$wn = (split(/=\s*/,$_))[1];}
  if($_ =~ /input\s*slew/i){s/\s*input\s*slew\s*=\s*//;@input_slew = (split(/\s+/,$_));}
  if($_ =~ /output\s*capacitance/i){s/\s*output\s*capacitance\s*=\s*//;@opcap = (split(/\s+/,$_));}
  if($_ =~ /vdd\s*sec/i){($vdd_sec,$vdd_sec_val) = (split(/=\s*/,$_))[0,1];}
  elsif($_ =~ /vdd/i){($vdd_pri,$vdd_pri_val) = (split(/=\s*/,$_))[0,1];}
}#while reading parameter file
close (READ_PARA);
#--------------------------------------------------------------------------------------------------------#
my @get_new_port_list = ();
my @get_new_port_list1 = ();
my @clock_val = ();
my @rsn_val = ();
my $get_n2_val = "";
my $get_rsn_val = "";
my $port_reset = "";
my $output_port = "";
foreach my $port (@cell_data){
  if($port =~ /vd/i){
    push(@get_new_port_list,$port);
    push(@get_new_port_list1,$port);
  }elsif($port =~ /vss/i){
    push(@get_new_port_list,$port);
    push(@get_new_port_list1,$port);
  }elsif($port =~/$clk/){
    push(@get_new_port_list,"n2");
    push(@get_new_port_list1,"n2");
    push(@clock_val ,0,1);
  }elsif($port =~ /$out/){
    push(@get_new_port_list,"n3");
    push(@get_new_port_list1,"n4");
    $output_port = "n3";
  }elsif($port =~ /$in/){
    push(@get_new_port_list,"n1");
    push(@get_new_port_list1,"n3");
  }elsif($port =~ /sn/){ 
    $port_reset = $port;
    push(@get_new_port_list,"vrs");
    push(@get_new_port_list1,"vrs");
    push(@rsn_val ,0,1);
  }
}#foreach port 
########################################write test bench for latch#####################################################
#---------------------------------------check value of clock-1/rsn-1--------------------------------------------------#
  for(my $l=0;$l<=$#clock_val;$l++){
    for(my $r=0;$r<=$#rsn_val;$r++){
      my $clkval = $clock_val[$l];
      my $rsnval = $rsn_val[$r];
      my $input_slew_val_1_with_unit = $input_slew[0].""."e-9";
      my $op_cap_val_1_with_unit = $opcap[0].""."e-12";
      if($clkval == 1 && $rsnval == 1){
        open(WRITE,">$file-dfall-$clk-$clkval-$port_reset-$rsnval");
        print WRITE ".title Fanout Versus Delay (TSMC)\n";
        print WRITE "\n"; 
        print WRITE ".param vdd=$vdd_pri_val\n";
        print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
        print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
        print WRITE ".param vss=$vss_val\n";
        print WRITE ".param wp=$wp\n";
        print WRITE ".param wn=$wn\n";
        print WRITE ".param vlo='0.2*vdd'\n";
        print WRITE ".param vmid='0.5*vdd'\n";
        print WRITE ".param vhi='0.8*vdd'\n";
        print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
        print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
        print WRITE "\n"; 
        print WRITE ".param v0=vss\n";
        print WRITE ".param v1=vss\n";
        print WRITE ".param v2=vlo\n";
        print WRITE ".param v3=vhi\n";
        print WRITE ".param v4=vdd\n";
        print WRITE ".param v5=vdd\n";
        print WRITE ".param v6=vhi\n";
        print WRITE ".param v7=vlo\n";
        print WRITE ".param v8=vss\n";
        print WRITE ".param v9=vss\n";
        print WRITE "\n"; 
        print WRITE ".param v0_neg_pulse=vdd\n";
        print WRITE ".param v1_neg_pulse=vdd\n";
        print WRITE ".param v2_neg_pulse=vhi\n";
        print WRITE ".param v3_neg_pulse=vlo\n";
        print WRITE ".param v4_neg_pulse=vss\n";
        print WRITE ".param v5_neg_pulse=vss\n";
        print WRITE ".param v6_neg_pulse=vlo\n";
        print WRITE ".param v7_neg_pulse=vhi\n";
        print WRITE ".param v8_neg_pulse=vdd\n";
        print WRITE ".param v9_neg_pulse=vdd\n";
        print WRITE "\n"; 
        print WRITE ".param t0='inputslew*10/6*0.0'\n";
        print WRITE ".param t1='inputslew*10/6*1.0'\n";
        print WRITE ".param t2='inputslew*10/6*1.2'\n";
        print WRITE ".param t3='inputslew*10/6*1.8'\n";
        print WRITE ".param t4='inputslew*10/6*2.0'\n";
        print WRITE ".param t5='inputslew*10/6*3.0'\n";
        print WRITE ".param t6='inputslew*10/6*3.2'\n";
        print WRITE ".param t7='inputslew*10/6*3.8'\n";
        print WRITE ".param t8='inputslew*10/6*4.0'\n";
        print WRITE ".param t9='inputslew*10/6*5.0'\n";
        print WRITE "\n"; 
        print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n";
        print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
        print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
        print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
        print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
        print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n"; 
        print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
        print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
        print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
        print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
        print WRITE "\n"; 
        print WRITE ".nodeset v(n3)=vdd\n";
        print WRITE "*.nodeset v(n3)=vss\n";
        print WRITE "\n"; 
        print WRITE "vdd vdd 0 vdd\n";
        print WRITE "vddsec vddsec 0 vddsec\n";
        print WRITE "vss vss 0   vss\n";
        print WRITE "\n"; 
        print WRITE "vrs vrs 0   vdd\n";
        print WRITE "\n"; 
        print WRITE "vin n2 vss pwl(\n";
        print WRITE "+               t_sec0   v4\n";
        print WRITE "+               t_sec1   v4\n"; 
        print WRITE "+               t_sec2   v4\n";
        print WRITE "+               t_sec3   v4\n";
        print WRITE "+               t_sec4   v4\n";
        print WRITE "+               t_sec5   v4\n";
        print WRITE "+               t_sec6   v4\n";
        print WRITE "+               t_sec7   v4\n";
        print WRITE "+               t_sec8   v4\n";
        print WRITE "+               t_sec9   v4\n";
        print WRITE "+             )\n";
        print WRITE "\n"; 
        print WRITE "vin0 n1 vss pwl(\n";
        print WRITE "+               t4   v4\n"; 
        print WRITE "+               t5   v5\n";
        print WRITE "+               t6   v6\n";
        print WRITE "+               t7   v7\n";
        print WRITE "+               t8   v8\n";
        print WRITE "+               t9   v9\n";
        print WRITE "+             )\n";
        print WRITE "\n"; 
        print WRITE "*vin0 n1 vss pwl(\n";
        print WRITE "*+               t4   v0\n"; 
        print WRITE "*+               t5   v1\n";
        print WRITE "*+               t6   v2\n";
        print WRITE "*+               t7   v3\n";
        print WRITE "*+               t8   v4\n";
        print WRITE "*+               t9   v5\n";
        print WRITE "*+             )\n";
        print WRITE ".MODEL n NMOS\n";
        print WRITE ".MODEL p PMOS\n";
        print WRITE ".MODEL nd NMOS\n";
        print WRITE ".MODEL pd PMOS\n";
        print WRITE "\n"; 
        print WRITE "\n"; 
        print WRITE ".include $new_file_spice\n";
        print WRITE "x$cellName @get_new_port_list $cellName\n";
        print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
        print WRITE "C1 $output_port 0 opcap\n";
        print WRITE "\n"; 
        print WRITE ".temp 85\n";
        print WRITE ".tran 10p 500n\n";
        print WRITE "\n"; 
        print WRITE ".meas tran n1_first_fall when v(n1)=vmid fall=1\n";
        print WRITE "\n"; 
        print WRITE ".meas tran n3_first_fall when v(n3)=vmid fall=1\n";
        print WRITE "\n"; 
        print WRITE ".end\n";
        close(WRITE); 
        #######################################################################################################################
        system ("ngspice -b -o $file-dfall-$clk-$clkval-$port_reset-$rsnval.log $file-dfall-$clk-$clkval-$port_reset-$rsnval");
        #---------------------------------------------read log file for getting value of n2-----------------------------------#
        open(READ_LOG,"$file-dfall-$clk-$clkval-$port_reset-$rsnval.log"); 
        while(<READ_LOG>){
        chomp();
          if($_ =~ /^n3_first_fall/){my $n3_first_fall = (split(/=\s+/,$_))[1];
            if($n3_first_fall ne ""){$get_n2_val = $clkval;$get_rsn_val = $rsnval;}
          } 
        }
        close(READ_LOG);
      }elsif($clkval == 1 && $rsnval == 0){
         #---------------------------------------check value of clock-1/rsn-0-------------------------------------------------#
         open(WRITE,">$file-dfall-$clk-$clkval-$port_reset-$rsnval");
         print WRITE ".title Fanout Versus Delay (TSMC)\n";
         print WRITE "\n"; 
         print WRITE ".param vdd=$vdd_pri_val\n";
         print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
         print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
         print WRITE ".param vss=$vss_val\n";
         print WRITE ".param wp=$wp\n";
         print WRITE ".param wn=$wn\n";
         print WRITE ".param vlo='0.2*vdd'\n";
         print WRITE ".param vmid='0.5*vdd'\n";
         print WRITE ".param vhi='0.8*vdd'\n";
         print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
         print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
         print WRITE "\n"; 
         print WRITE ".param v0=vss\n";
         print WRITE ".param v1=vss\n";
         print WRITE ".param v2=vlo\n";
         print WRITE ".param v3=vhi\n";
         print WRITE ".param v4=vdd\n";
         print WRITE ".param v5=vdd\n";
         print WRITE ".param v6=vhi\n";
         print WRITE ".param v7=vlo\n";
         print WRITE ".param v8=vss\n";
         print WRITE ".param v9=vss\n";
         print WRITE "\n"; 
         print WRITE ".param v0_neg_pulse=vdd\n";
         print WRITE ".param v1_neg_pulse=vdd\n";
         print WRITE ".param v2_neg_pulse=vhi\n";
         print WRITE ".param v3_neg_pulse=vlo\n";
         print WRITE ".param v4_neg_pulse=vss\n";
         print WRITE ".param v5_neg_pulse=vss\n";
         print WRITE ".param v6_neg_pulse=vlo\n";
         print WRITE ".param v7_neg_pulse=vhi\n";
         print WRITE ".param v8_neg_pulse=vdd\n";
         print WRITE ".param v9_neg_pulse=vdd\n";
         print WRITE "\n"; 
         print WRITE ".param t0='inputslew*10/6*0.0'\n";
         print WRITE ".param t1='inputslew*10/6*1.0'\n";
         print WRITE ".param t2='inputslew*10/6*1.2'\n";
         print WRITE ".param t3='inputslew*10/6*1.8'\n";
         print WRITE ".param t4='inputslew*10/6*2.0'\n";
         print WRITE ".param t5='inputslew*10/6*3.0'\n";
         print WRITE ".param t6='inputslew*10/6*3.2'\n";
         print WRITE ".param t7='inputslew*10/6*3.8'\n";
         print WRITE ".param t8='inputslew*10/6*4.0'\n";
         print WRITE ".param t9='inputslew*10/6*5.0'\n";
         print WRITE "\n"; 
         print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n";
         print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
         print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
         print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
         print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
         print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n"; 
         print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
         print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
         print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
         print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
         print WRITE "\n"; 
         print WRITE ".nodeset v(n3)=vdd\n";
         print WRITE "*.nodeset v(n3)=vss\n";
         print WRITE "\n"; 
         print WRITE "vdd vdd 0 vdd\n";
         print WRITE "vddsec vddsec 0 vddsec\n";
         print WRITE "vss vss 0   vss\n";
         print WRITE "\n"; 
         print WRITE "vrs vrs 0   vss\n";
         print WRITE "\n"; 
         print WRITE "vin n2 vss pwl(\n";
         print WRITE "+               t_sec0   v4\n";
         print WRITE "+               t_sec1   v4\n"; 
         print WRITE "+               t_sec2   v4\n";
         print WRITE "+               t_sec3   v4\n";
         print WRITE "+               t_sec4   v4\n";
         print WRITE "+               t_sec5   v4\n";
         print WRITE "+               t_sec6   v4\n";
         print WRITE "+               t_sec7   v4\n";
         print WRITE "+               t_sec8   v4\n";
         print WRITE "+               t_sec9   v4\n";
         print WRITE "+             )\n";
         print WRITE "\n"; 
         print WRITE "vin0 n1 vss pwl(\n";
         print WRITE "+               t4   v4\n"; 
         print WRITE "+               t5   v5\n";
         print WRITE "+               t6   v6\n";
         print WRITE "+               t7   v7\n";
         print WRITE "+               t8   v8\n";
         print WRITE "+               t9   v9\n";
         print WRITE "+             )\n";
         print WRITE "\n"; 
         print WRITE "*vin0 n1 vss pwl(\n";
         print WRITE "*+               t4   v0\n"; 
         print WRITE "*+               t5   v1\n";
         print WRITE "*+               t6   v2\n";
         print WRITE "*+               t7   v3\n";
         print WRITE "*+               t8   v4\n";
         print WRITE "*+               t9   v5\n";
         print WRITE "*+             )\n";
         print WRITE ".MODEL n NMOS\n";
         print WRITE ".MODEL p PMOS\n";
         print WRITE ".MODEL nd NMOS\n";
         print WRITE ".MODEL pd PMOS\n";
         print WRITE "\n"; 
         print WRITE "\n"; 
         print WRITE ".include $new_file_spice\n";
         print WRITE "x$cellName @get_new_port_list $cellName\n";
         print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
         print WRITE "C1 $output_port 0 opcap\n";
         print WRITE "\n"; 
         print WRITE ".temp 85\n";
         print WRITE ".tran 10p 500n\n";
         print WRITE "\n"; 
         print WRITE ".meas tran n1_first_fall when v(n1)=vmid fall=1\n";
         print WRITE "\n"; 
         print WRITE ".meas tran n3_first_fall when v(n3)=vmid fall=1\n";
         print WRITE "\n"; 
         print WRITE ".end\n";
         close(WRITE); 
         #######################################################################################################################
         system ("ngspice -b -o $file-dfall-$clk-$clkval-$port_reset-$rsnval.log $file-dfall-$clk-$clkval-$port_reset-$rsnval");
         #---------------------------------------read log file for getting value of n2-----------------------------------------#
         open(READ_LOG,"$file-dfall-$clk-$clkval-$port_reset-$rsnval.log"); 
         while(<READ_LOG>){
         chomp();
           if($_ =~ /^n3_first_fall/){my $n3_first_fall = (split(/=\s+/,$_))[1];
             if($n3_first_fall ne ""){$get_n2_val = $clkval;$get_rsn_val = $rsnval;}
           }
         }
         close(READ_LOG);
       }elsif($clkval == 0 && $rsnval == 1){
         #---------------------------------------check value of clock-0/rsn-1--------------------------------------------------#
         open(WRITE,">$file-dfall-$clk-$clkval-$port_reset-$rsnval");
         print WRITE ".title Fanout Versus Delay (TSMC)\n";
         print WRITE "\n"; 
         print WRITE ".param vdd=$vdd_pri_val\n";
         print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
         print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
         print WRITE ".param vss=$vss_val\n";
         print WRITE ".param wp=$wp\n";
         print WRITE ".param wn=$wn\n";
         print WRITE ".param vlo='0.2*vdd'\n";
         print WRITE ".param vmid='0.5*vdd'\n";
         print WRITE ".param vhi='0.8*vdd'\n";
         print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
         print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
         print WRITE "\n"; 
         print WRITE ".param v0=vss\n";
         print WRITE ".param v1=vss\n";
         print WRITE ".param v2=vlo\n";
         print WRITE ".param v3=vhi\n";
         print WRITE ".param v4=vdd\n";
         print WRITE ".param v5=vdd\n";
         print WRITE ".param v6=vhi\n";
         print WRITE ".param v7=vlo\n";
         print WRITE ".param v8=vss\n";
         print WRITE ".param v9=vss\n";
         print WRITE "\n"; 
         print WRITE ".param v0_neg_pulse=vdd\n";
         print WRITE ".param v1_neg_pulse=vdd\n";
         print WRITE ".param v2_neg_pulse=vhi\n";
         print WRITE ".param v3_neg_pulse=vlo\n";
         print WRITE ".param v4_neg_pulse=vss\n";
         print WRITE ".param v5_neg_pulse=vss\n";
         print WRITE ".param v6_neg_pulse=vlo\n";
         print WRITE ".param v7_neg_pulse=vhi\n";
         print WRITE ".param v8_neg_pulse=vdd\n";
         print WRITE ".param v9_neg_pulse=vdd\n";
         print WRITE "\n"; 
         print WRITE ".param t0='inputslew*10/6*0.0'\n";
         print WRITE ".param t1='inputslew*10/6*1.0'\n";
         print WRITE ".param t2='inputslew*10/6*1.2'\n";
         print WRITE ".param t3='inputslew*10/6*1.8'\n";
         print WRITE ".param t4='inputslew*10/6*2.0'\n";
         print WRITE ".param t5='inputslew*10/6*3.0'\n";
         print WRITE ".param t6='inputslew*10/6*3.2'\n";
         print WRITE ".param t7='inputslew*10/6*3.8'\n";
         print WRITE ".param t8='inputslew*10/6*4.0'\n";
         print WRITE ".param t9='inputslew*10/6*5.0'\n";
         print WRITE "\n"; 
         print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n";
         print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
         print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
         print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
         print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
         print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n"; 
         print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
         print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
         print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
         print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
         print WRITE "\n"; 
         print WRITE ".nodeset v(n3)=vdd\n";
         print WRITE "*.nodeset v(n3)=vss\n";
         print WRITE "\n"; 
         print WRITE "vdd vdd 0 vdd\n";
         print WRITE "vddsec vddsec 0 vddsec\n";
         print WRITE " vss vss 0   vss\n";
         print WRITE "\n"; 
         print WRITE "vrs vrs 0   vdd\n";
         print WRITE "\n"; 
         print WRITE "vin n2 vss pwl(\n";
         print WRITE "+               t_sec0   v0\n";
         print WRITE "+               t_sec1   v0\n"; 
         print WRITE "+               t_sec2   v0\n";
         print WRITE "+               t_sec3   v0\n";
         print WRITE "+               t_sec4   v0\n";
         print WRITE "+               t_sec5   v0\n";
         print WRITE "+               t_sec6   v0\n";
         print WRITE "+               t_sec7   v0\n";
         print WRITE "+               t_sec8   v0\n";
         print WRITE "+               t_sec9   v0\n";
         print WRITE "+             )\n";
         print WRITE "\n"; 
         print WRITE "vin0 n1 vss pwl(\n";
         print WRITE "+               t4   v4\n"; 
         print WRITE "+               t5   v5\n";
         print WRITE "+               t6   v6\n";
         print WRITE "+               t7   v7\n";
         print WRITE "+               t8   v8\n";
         print WRITE "+               t9   v9\n";
         print WRITE "+             )\n";
         print WRITE "\n"; 
         print WRITE "*vin0 n1 vss pwl(\n";
         print WRITE "*+               t4   v0\n"; 
         print WRITE "*+               t5   v1\n";
         print WRITE "*+               t6   v2\n";
         print WRITE "*+               t7   v3\n";
         print WRITE "*+               t8   v4\n";
         print WRITE "*+               t9   v5\n";
         print WRITE "*+             )\n";
         print WRITE ".MODEL n NMOS\n";
         print WRITE ".MODEL p PMOS\n";
         print WRITE ".MODEL nd NMOS\n";
         print WRITE ".MODEL pd PMOS\n";
         print WRITE "\n"; 
         print WRITE "\n"; 
         print WRITE ".include $new_file_spice\n";
         print WRITE "x$cellName @get_new_port_list $cellName\n";
         print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";            
         print WRITE "C1 $output_port 0 opcap\n";
         print WRITE "\n"; 
         print WRITE ".temp 85\n";
         print WRITE ".tran 10p 500n\n";
         print WRITE "\n"; 
         print WRITE ".meas tran n1_first_fall when v(n1)=vmid fall=1\n";
         print WRITE "\n"; 
         print WRITE ".meas tran n3_first_fall when v(n3)=vmid fall=1\n";
         print WRITE "\n"; 
         print WRITE ".end\n";
         close(WRITE); 
         #######################################################################################################################
         system ("ngspice -b -o $file-dfall-$clk-$clkval-$port_reset-$rsnval.log $file-dfall-$clk-$clkval-$port_reset-$rsnval");
         #----------------------------------------read log file for getting value of n2----------------------------------------#
         open(READ_LOG,"$file-dfall-$clk-$clkval-$port_reset-$rsnval.log"); 
         while(<READ_LOG>){
         chomp();
           if($_ =~ /^n3_first_fall/){my $n3_first_fall = (split(/=\s+/,$_))[1];
             if($n3_first_fall ne ""){$get_n2_val = $clkval;$get_rsn_val = $rsnval;}
           }
         }
         close(READ_LOG);
       }elsif($clkval == 0 && $rsnval == 0){
          #---------------------------------------check value of clock-0/rsn-0-------------------------------------------#
          open(WRITE,">$file-dfall-$clk-$clkval-$port_reset-$rsnval");
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n"; 
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE "\n"; 
          print WRITE ".param v0=vss\n";
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n"; 
          print WRITE ".param v0_neg_pulse=vdd\n";
          print WRITE ".param v1_neg_pulse=vdd\n";
          print WRITE ".param v2_neg_pulse=vhi\n";
          print WRITE ".param v3_neg_pulse=vlo\n";
          print WRITE ".param v4_neg_pulse=vss\n";
          print WRITE ".param v5_neg_pulse=vss\n";
          print WRITE ".param v6_neg_pulse=vlo\n";
          print WRITE ".param v7_neg_pulse=vhi\n";
          print WRITE ".param v8_neg_pulse=vdd\n";
          print WRITE ".param v9_neg_pulse=vdd\n";
          print WRITE "\n"; 
          print WRITE ".param t0='inputslew*10/6*0.0'\n";
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*1.8'\n";
          print WRITE ".param t4='inputslew*10/6*2.0'\n";
          print WRITE ".param t5='inputslew*10/6*3.0'\n";
          print WRITE ".param t6='inputslew*10/6*3.2'\n";
          print WRITE ".param t7='inputslew*10/6*3.8'\n";
          print WRITE ".param t8='inputslew*10/6*4.0'\n";
          print WRITE ".param t9='inputslew*10/6*5.0'\n";
          print WRITE "\n"; 
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n";
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n"; 
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n"; 
          print WRITE ".nodeset v(n3)=vdd\n";
          print WRITE "*.nodeset v(n3)=vss\n";
          print WRITE "\n"; 
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0   vss\n";
          print WRITE "\n"; 
          print WRITE "vrs vrs 0   vss\n";
          print WRITE "\n"; 
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t_sec0   v0\n";
          print WRITE "+               t_sec1   v0\n"; 
          print WRITE "+               t_sec2   v0\n";
          print WRITE "+               t_sec3   v0\n";
          print WRITE "+               t_sec4   v0\n";
          print WRITE "+               t_sec5   v0\n";
          print WRITE "+               t_sec6   v0\n";
          print WRITE "+               t_sec7   v0\n";
          print WRITE "+               t_sec8   v0\n";
          print WRITE "+               t_sec9   v0\n";
          print WRITE "+             )\n";
          print WRITE "\n"; 
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t4   v4\n"; 
          print WRITE "+               t5   v5\n";
          print WRITE "+               t6   v6\n";
          print WRITE "+               t7   v7\n";
          print WRITE "+               t8   v8\n";
          print WRITE "+               t9   v9\n";
          print WRITE "+             )\n";
          print WRITE "\n"; 
          print WRITE "*vin0 n1 vss pwl(\n";
          print WRITE "*+               t4   v0\n"; 
          print WRITE "*+               t5   v1\n";
          print WRITE "*+               t6   v2\n";
          print WRITE "*+               t7   v3\n";
          print WRITE "*+               t8   v4\n";
          print WRITE "*+               t9   v5\n";
          print WRITE "*+             )\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n"; 
          print WRITE "\n"; 
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n"; 
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n"; 
          print WRITE ".meas tran n1_first_fall when v(n1)=vmid fall=1\n";
          print WRITE "\n"; 
          print WRITE ".meas tran n3_first_fall when v(n3)=vmid fall=1\n";
          print WRITE "\n"; 
          print WRITE ".end\n";
          close(WRITE); 
          #######################################################################################################################
          system ("ngspice -b -o $file-dfall-$clk-$clkval-$port_reset-$rsnval.log $file-dfall-$clk-$clkval-$port_reset-$rsnval");
          #-----------------------------------------------read log file for getting value of n2---------------------------------#
          open(READ_LOG,"$file-dfall-$clk-$clkval-$port_reset-$rsnval.log"); 
          while(<READ_LOG>){
          chomp();
            if($_ =~ /^n3_first_fall/){my $n3_first_fall = (split(/=\s+/,$_))[1];
              if($n3_first_fall ne ""){$get_n2_val = $clkval;$get_rsn_val = $rsnval;}
            }
          }
          close(READ_LOG);
        }#elsif 
      }#for rsn val
    }#for clock val
#---------------------------------------------------------------------------------------------------------------#
  my $ns = @input_slew;
  my $nopcap = @opcap;
  my @dclkrise_list = ();
  my @dclkfall_list = ();
  open(WRITE_GENLIB,">$cellName.genlib");
    print WRITE_GENLIB "LIBNAME typical\n";
    print WRITE_GENLIB "GATE $cellName 3.2\n";
    print WRITE_GENLIB "  index_1 @input_slew\n";
    print WRITE_GENLIB "  index_2 @opcap\n";
    print WRITE_GENLIB "  PIN $in NONINV input\n";
    print WRITE_GENLIB "   in_index_1 0.0300 0.9000 3.0000\n";
    print WRITE_GENLIB "   in_index_2 0.0300 3.0000\n";
    print WRITE_GENLIB "   related_pin $clk \n";
    print WRITE_GENLIB "      timing_type : setup_rising\n";
    print WRITE_GENLIB "        rise_constraint 0.0859 0.2031 0.0938 0.2031 -0.0312 0.0859\n";
    print WRITE_GENLIB "        fall_constraint 0.1953 0.5469 0.3594 0.7031 0.7188 1.0700\n";
    print WRITE_GENLIB "      timing_type : hold_rising\n";
    print WRITE_GENLIB "        rise_constraint -0.0391 -0.1875 -0.0547 -0.1797 0.0859 -0.0547\n";
    print WRITE_GENLIB "        fall_constraint -0.0469 -0.0938 -0.2187 -0.2422 -0.5547 -0.5547\n";
    print WRITE_GENLIB "  PIN $clk NONINV input\n";
    print WRITE_GENLIB "    clock  true\n";
    print WRITE_GENLIB "  PIN RN NONINV input\n";
    print WRITE_GENLIB "   in_index_1 0.0300 0.9000 3.0000\n";
    print WRITE_GENLIB "   in_index_2 0.0300 3.0000\n";
    print WRITE_GENLIB "   related_pin  CK\n";
    print WRITE_GENLIB "      timing_type : recovery_rising\n";
    print WRITE_GENLIB "        rise_constraint 0.1172 0.1875 0.1563 0.2187 0.0625 0.1328\n";
    print WRITE_GENLIB "  output $out\n";
    print WRITE_GENLIB "  clocked_on $clk\n";
    print WRITE_GENLIB "  input $in\n";
    print WRITE_GENLIB "  reset RN'\n"; 
    print WRITE_GENLIB "  PIN $out NONINV output\n";
    print WRITE_GENLIB "    function : IQ\n";
    print WRITE_GENLIB "      related_pin $clk\n";
    print WRITE_GENLIB "      timing_type : rising_edge\n";
    print WRITE_GENLIB "      timing_sense : non_unate\n";
    for (my $i =0; $i<$ns;$i++){
      for(my $j=0; $j<$nopcap;$j++){
        my $input_slew_value = $input_slew[$i];
        my $input_slew_value_with_unit = $input_slew[$i].""."e-9";
        my $op_cap = $opcap[$j];
        my $op_cap_with_unit = $opcap[$j].""."e-12";
        #--------------------------------------------------------------------------------------------------------------#
        if($get_n2_val == 0){
        #-------------------------------writing test bench for dclkfall------------------------------------------------#
          open(WRITE,">$file-dclkfall-$input_slew_value-$op_cap");
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_with_unit\n";
          print WRITE ".param inputslew=$input_slew_value_with_unit\n";
          print WRITE "\n";
          print WRITE ".param v0=vss\n";
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param v0_neg_pulse=vdd\n";
          print WRITE ".param v1_neg_pulse=vdd\n";
          print WRITE ".param v2_neg_pulse=vhi\n";
          print WRITE ".param v3_neg_pulse=vlo\n";
          print WRITE ".param v4_neg_pulse=vss\n";
          print WRITE ".param v5_neg_pulse=vss\n";
          print WRITE ".param v6_neg_pulse=vlo\n";
          print WRITE ".param v7_neg_pulse=vhi\n";
          print WRITE ".param v8_neg_pulse=vdd\n";
          print WRITE ".param v9_neg_pulse=vdd\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n";
          print WRITE ".param t1='inputslew*10/6*1.0'\n"; 
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*1.8'\n";
          print WRITE ".param t4='inputslew*10/6*2.0'\n";
          print WRITE ".param t5='inputslew*10/6*3.0'\n";
          print WRITE ".param t6='inputslew*10/6*3.2'\n";
          print WRITE ".param t7='inputslew*10/6*3.8'\n";
          print WRITE ".param t8='inputslew*10/6*4.0'\n";
          print WRITE ".param t9='inputslew*10/6*5.0'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + inputslew*10/6*5.0'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + inputslew*10/6*5.0'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + inputslew*10/6*5.0'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + inputslew*10/6*5.0'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + inputslew*10/6*5.0'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + inputslew*10/6*5.0'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + inputslew*10/6*5.0'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + inputslew*10/6*5.0'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + inputslew*10/6*5.0'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + inputslew*10/6*5.0'\n";
          print WRITE "\n";
          print WRITE "*.nodeset v(n3)=vdd\n";
          print WRITE "*.nodeset v(n3)=vss\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0   vss\n";
          print WRITE "\n";
          print WRITE "vrs vrs 0   vdd\n" if($get_rsn_val == 1);
          print WRITE "*vrs vrs 0  vss\n" if($get_rsn_val == 1);
          print WRITE "*vrs vrs 0  vdd\n" if($get_rsn_val == 0);
          print WRITE "vrs vrs 0   vss\n" if($get_rsn_val == 0);
          print WRITE "\n";
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+              t0       v0\n";  
          print WRITE "+              t6       v5\n";  
          print WRITE "+              t_sec0   v5\n";  
          print WRITE "+              t_sec1   v5\n";  
          print WRITE "+              t_sec2   v4\n";  
          print WRITE "+              t_sec3   v3\n"; 
          print WRITE "+              t_sec4   v2\n";  
          print WRITE "+              t_sec5   v1\n"; 
          print WRITE "+              t_sec6   v0\n"; 
          print WRITE "+              t_sec7   v0\n"; 
          print WRITE "+              t_sec8   v0\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v4\n";     
          print WRITE "+               t1   v4\n";     
          print WRITE "+               t2   v4\n";    
          print WRITE "+               t3   v4\n";     
          print WRITE "+               t4   v4\n";     
          print WRITE "+               t5   v5\n";    
          print WRITE "+               t6   v6\n";    
          print WRITE "+               t7   v7\n";    
          print WRITE "+               t8   v8\n";    
          print WRITE "+               t9   v9\n";    
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE ".meas tran n1_first_fall when v(n1)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n2_first_fall when v(n2)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n3_first_fall when v(n3)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".meas tran dclkfall trig v(n2) val=vmid fall=1\n";
          print WRITE "+                targ v(n3) val=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close(WRITE);
          #-------------------------------writing test bench for dclkrise----------------------------------------#
          open(WRITE,">$file-dclkrise-$input_slew_value-$op_cap");
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_with_unit\n";
          print WRITE ".param inputslew=$input_slew_value_with_unit\n";
          print WRITE "\n";
          print WRITE ".param v0=vss\n";
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param v0_neg_pulse=vdd\n";
          print WRITE ".param v1_neg_pulse=vdd\n";
          print WRITE ".param v2_neg_pulse=vhi\n";
          print WRITE ".param v3_neg_pulse=vlo\n";
          print WRITE ".param v4_neg_pulse=vss\n"; 
          print WRITE ".param v5_neg_pulse=vss\n";
          print WRITE ".param v6_neg_pulse=vlo\n";
          print WRITE ".param v7_neg_pulse=vhi\n";
          print WRITE ".param v8_neg_pulse=vdd\n";
          print WRITE ".param v9_neg_pulse=vdd\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n";
          print WRITE ".param t1='inputslew*10/6*1.0'\n"; 
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*1.8'\n";
          print WRITE ".param t4='inputslew*10/6*2.0'\n";
          print WRITE ".param t5='inputslew*10/6*3.0'\n";
          print WRITE ".param t6='inputslew*10/6*3.2'\n";
          print WRITE ".param t7='inputslew*10/6*3.8'\n";
          print WRITE ".param t8='inputslew*10/6*4.0'\n";
          print WRITE ".param t9='inputslew*10/6*5.0'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + inputslew*10/6*5'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + inputslew*10/6*5'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + inputslew*10/6*5'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + inputslew*10/6*5'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + inputslew*10/6*5'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + inputslew*10/6*5'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + inputslew*10/6*5'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + inputslew*10/6*5'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + inputslew*10/6*5'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + inputslew*10/6*5'\n";
          print WRITE "\n";
          print WRITE "*.nodeset v(n3)=vdd\n";
          print WRITE "*.nodeset v(n3)=vss\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0   vss\n";
          print WRITE "\n";
          print WRITE "vrs vrs 0  vdd\n" if($get_rsn_val == 1);
          print WRITE "*vrs vrs 0 vss\n" if($get_rsn_val == 1);
          print WRITE "*vrs vrs 0 vdd\n" if($get_rsn_val == 0);
          print WRITE "vrs vrs 0  vss\n" if($get_rsn_val == 0);
          print WRITE "\n";
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t_sec0   v5\n"; 
          print WRITE "+               t_sec1   v5\n";
          print WRITE "+               t_sec2   v4\n";
          print WRITE "+               t_sec3   v3\n";
          print WRITE "+               t_sec4   v2\n";
          print WRITE "+               t_sec5   v1\n";
          print WRITE "+               t_sec6   v0\n";
          print WRITE "+               t_sec7   v0\n";
          print WRITE "+               t_sec8   v0\n";
          print WRITE "+               t_sec9   v0\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t4   v0\n"; 
          print WRITE "+               t5   v1\n";
          print WRITE "+               t6   v2\n";
          print WRITE "+               t7   v3\n";
          print WRITE "+               t8   v4\n";
          print WRITE "+               t9   v5\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE ".meas tran n1_first_rise  when v(n1)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n2_first_fall when v(n2)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n3_first_rise  when v(n3)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".meas tran dclkrise trig v(n2) val=vmid fall=1\n";
          print WRITE "+                targ v(n3) val=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close(WRITE);
          ################################################################################################################
          system ("ngspice -b -o $file-dclkfall-$input_slew_value-$op_cap.log $file-dclkfall-$input_slew_value-$op_cap");
          system ("ngspice -b -o $file-dclkrise-$input_slew_value-$op_cap.log $file-dclkrise-$input_slew_value-$op_cap");
          ################################################################################################################
          #-------------------------------------read log file of ngspice for dclkfall------------------------------------#
          open(READ_NG_LOG,"$file-dclkfall-$input_slew_value-$op_cap.log");
          while(<READ_NG_LOG>){
          chomp();
            if($_ =~ /^dclkfall/){s/\s*dclkfall\s*//;my $dclkfall = (split(/=\s+/,$_))[1];
              $dclkfall =~ s/\s*targ//;
              my ($n,$m) = (split(/e/,$dclkfall))[0,1];
              my $m = $m+9;
              my $dclkfall_new = $n*(10**$m);
              push(@dclkfall_list,$dclkfall_new);
            } 
          }#while reading
          close(READ_NG_LOG);
          #---------------------------------read log file of ngspice for dclkrise--------------------------------------#
          open(READ_NG_LOG,"$file-dclkrise-$input_slew_value-$op_cap.log");
          while(<READ_NG_LOG>){
          chomp();
            if($_ =~/^dclkrise /){s/\s*dclkrise\s*//;my $dclkrise = (split(/=\s+/,$_))[1];
              $dclkrise =~ s/\s*targ//;
              my ($n,$m) = (split(/e/,$dclkrise))[0,1];
              my $m = $m+9;
              my $dclkrise_new = $n*(10**$m);
              push(@dclkrise_list,$dclkrise_new);
            }
          }#while reading
        #--------------------------------------------------------------------------------------------------------------#
        }elsif($get_n2_val == 1){
        #------------------------------writing test bench for dclkfall (if clk == 1)-----------------------------------# 
          open(WRITE,">$file-dclkfall-$input_slew_value-$op_cap");
          print WRITE".title Fanout Versus Delay (TSMC)\n";
          print WRITE"\n";
          print WRITE".param vdd=$vdd_pri_val\n";
          print WRITE".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
          print WRITE".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
          print WRITE".param vss=$vss_val\n";
          print WRITE".param wp=$wp\n";
          print WRITE".param wn=$wn\n";
          print WRITE".param vlo='0.2*vdd'\n";
          print WRITE".param vmid='0.5*vdd'\n";
          print WRITE".param vhi='0.8*vdd'\n";
          print WRITE".param opcap=$op_cap_with_unit\n";
          print WRITE".param inputslew=$input_slew_value_with_unit\n";
          print WRITE"\n";
          print WRITE".param v0=vss\n";
          print WRITE".param v1=vss\n";
          print WRITE".param v2=vlo\n";
          print WRITE".param v3=vhi\n";
          print WRITE".param v4=vdd\n";
          print WRITE".param v5=vdd\n";
          print WRITE".param v6=vhi\n";
          print WRITE".param v7=vlo\n";
          print WRITE".param v8=vss\n";
          print WRITE".param v9=vss\n";
          print WRITE"\n";
          print WRITE".param v0_neg_pulse=vdd\n";
          print WRITE".param v1_neg_pulse=vdd\n";
          print WRITE".param v2_neg_pulse=vhi\n";
          print WRITE".param v3_neg_pulse=vlo\n";
          print WRITE".param v4_neg_pulse=vss\n";
          print WRITE".param v5_neg_pulse=vss\n";
          print WRITE".param v6_neg_pulse=vlo\n";
          print WRITE".param v7_neg_pulse=vhi\n";
          print WRITE".param v8_neg_pulse=vdd\n";
          print WRITE".param v9_neg_pulse=vdd\n";
          print WRITE"\n";
          print WRITE".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE".param t1='inputslew*10/6*1.0'\n";
          print WRITE".param t2='inputslew*10/6*1.2'\n";
          print WRITE".param t3='inputslew*10/6*1.8'\n";
          print WRITE".param t4='inputslew*10/6*2.0'\n";
          print WRITE".param t5='inputslew*10/6*3.0'\n";
          print WRITE".param t6='inputslew*10/6*3.2'\n";
          print WRITE".param t7='inputslew*10/6*3.8'\n";
          print WRITE".param t8='inputslew*10/6*4.0'\n";
          print WRITE".param t9='inputslew*10/6*5.0'\n";
          print WRITE"\n";
          print WRITE".param t_sec0='inputslew*10/6*0.0 + inputslew*10/6*5.0'\n"; 
          print WRITE".param t_sec1='inputslew*10/6*1.0 + inputslew*10/6*5.0'\n";
          print WRITE".param t_sec2='inputslew*10/6*1.2 + inputslew*10/6*5.0'\n";
          print WRITE".param t_sec3='inputslew*10/6*1.8 + inputslew*10/6*5.0'\n";
          print WRITE".param t_sec4='inputslew*10/6*2.0 + inputslew*10/6*5.0'\n";
          print WRITE".param t_sec5='inputslew*10/6*3.0 + inputslew*10/6*5.0'\n";
          print WRITE".param t_sec6='inputslew*10/6*3.2 + inputslew*10/6*5.0'\n";
          print WRITE".param t_sec7='inputslew*10/6*3.8 + inputslew*10/6*5.0'\n";
          print WRITE".param t_sec8='inputslew*10/6*4.0 + inputslew*10/6*5.0'\n";
          print WRITE".param t_sec9='inputslew*10/6*5.0 + inputslew*10/6*5.0'\n";
          print WRITE"\n";
          print WRITE"*.nodeset v(n3)=vdd\n";
          print WRITE"*.nodeset v(n3)=vss\n";
          print WRITE"\n";
          print WRITE"vdd vdd 0 vdd\n";
          print WRITE"vddsec vddsec 0 vddsec\n";
          print WRITE"vss vss 0   vss\n";
          print WRITE"\n";
          print WRITE"vrs vrs 0  vdd\n" if($get_rsn_val == 1);
          print WRITE"*vrs vrs 0 vss\n" if($get_rsn_val == 1);
          print WRITE"vrs vrs 0  vss\n" if($get_rsn_val == 0);
          print WRITE"*vrs vrs 0 vdd\n" if($get_rsn_val == 0);
          print WRITE"\n";
          print WRITE"vin n2 vss pwl(\n";
          print WRITE"+               t0       v0_neg_pulse\n";
          print WRITE"+               t6       v5_neg_pulse\n";   
          print WRITE"+               t_sec0   v5_neg_pulse\n";
          print WRITE"+               t_sec1   v5_neg_pulse\n";
          print WRITE"+               t_sec2   v4_neg_pulse\n";
          print WRITE"+               t_sec3   v3_neg_pulse\n";
          print WRITE"+               t_sec4   v2_neg_pulse\n";
          print WRITE"+               t_sec5   v1_neg_pulse\n";
          print WRITE"+               t_sec6   v0_neg_pulse\n";
          print WRITE"+               t_sec7   v0_neg_pulse\n";
          print WRITE"+               t_sec8   v0_neg_pulse\n";
          print WRITE"+               t_sec9   v0_neg_pulse\n"; 
          print WRITE"+             )\n";
          print WRITE"\n";
          print WRITE"vin0 n1 vss pwl(\n";
          print WRITE"+               t0   v4\n"; 
          print WRITE"+               t1   v4\n";
          print WRITE"+               t2   v4\n";
          print WRITE"+               t3   v4\n";
          print WRITE"+               t4   v4\n";
          print WRITE"+               t5   v5\n";
          print WRITE"+               t6   v6\n";
          print WRITE"+               t7   v7\n";
          print WRITE"+               t8   v8\n";
          print WRITE"+               t9   v9\n";
          print WRITE"+             )\n";
          print WRITE"\n";
          print WRITE".MODEL n NMOS\n";
          print WRITE".MODEL p PMOS\n";
          print WRITE".MODEL nd NMOS\n";
          print WRITE".MODEL pd PMOS\n";
          print WRITE"\n";
          print WRITE".include $new_file_spice\n";
          print WRITE"x$cellName @get_new_port_list $cellName\n";
          print WRITE"*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE"\n";
          print WRITE".temp 85\n";
          print WRITE".tran 10p 500n\n";
          print WRITE"\n";
          print WRITE".meas tran n1_first_fall when v(n1)=vmid fall=1\n";
          print WRITE"\n";
          print WRITE".meas tran n2_first_fall when v(n2)=vmid fall=1\n";
          print WRITE"\n";
          print WRITE".meas tran n3_first_fall when v(n3)=vmid fall=1\n";
          print WRITE"\n";
          print WRITE".meas tran dclkfall trig v(n2) val=vmid fall=1\n";
          print WRITE"+                targ v(n3) val=vmid fall=1\n";
          print WRITE"\n";
          print WRITE".end\n";
          close(WRITE);
          #-----------------------------writing test bench for dclkrise------------------------------------------------#
          open(WRITE,">$file-dclkrise-$input_slew_value-$op_cap");
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_with_unit\n";
          print WRITE ".param inputslew=$input_slew_value_with_unit\n";
          print WRITE "\n";
          print WRITE ".param v0=vss\n";
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n"; 
          print WRITE "\n";
          print WRITE ".param v0_neg_pulse=vdd\n"; 
          print WRITE ".param v1_neg_pulse=vdd\n";
          print WRITE ".param v2_neg_pulse=vhi\n";
          print WRITE ".param v3_neg_pulse=vlo\n";
          print WRITE ".param v4_neg_pulse=vss\n";
          print WRITE ".param v5_neg_pulse=vss\n";
          print WRITE ".param v6_neg_pulse=vlo\n";
          print WRITE ".param v7_neg_pulse=vhi\n";
          print WRITE ".param v8_neg_pulse=vdd\n";
          print WRITE ".param v9_neg_pulse=vdd\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*1.8'\n";
          print WRITE ".param t4='inputslew*10/6*2.0'\n";
          print WRITE ".param t5='inputslew*10/6*3.0'\n";
          print WRITE ".param t6='inputslew*10/6*3.2'\n";
          print WRITE ".param t7='inputslew*10/6*3.8'\n";
          print WRITE ".param t8='inputslew*10/6*4.0'\n";
          print WRITE ".param t9='inputslew*10/6*5.0'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + inputslew*10/6*5'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + inputslew*10/6*5'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + inputslew*10/6*5'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + inputslew*10/6*5'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + inputslew*10/6*5'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + inputslew*10/6*5'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + inputslew*10/6*5'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + inputslew*10/6*5'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + inputslew*10/6*5'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + inputslew*10/6*5'\n";
          print WRITE "\n";
          print WRITE "*.nodeset v(n3)=vdd\n";
          print WRITE "*.nodeset v(n3)=vss\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0   vss\n";
          print WRITE "\n";
          print WRITE "vrs vrs 0  vdd\n" if($get_rsn_val == 1);
          print WRITE "*vrs vrs 0 vss\n" if($get_rsn_val == 1);
          print WRITE "*vrs vrs 0 vdd\n" if($get_rsn_val == 0);
          print WRITE "vrs vrs 0  vss\n" if($get_rsn_val == 0);
          print WRITE "\n";
          print WRITE "*vin n2 vss pwl(\n";
          print WRITE "*+               t_sec0   v5\n";
          print WRITE "*+               t_sec1   v5\n"; 
          print WRITE "*+               t_sec2   v4\n";
          print WRITE "*+               t_sec3   v3\n";
          print WRITE "*+               t_sec4   v2\n";
          print WRITE "*+               t_sec5   v1\n";
          print WRITE "*+               t_sec6   v0\n";
          print WRITE "*+               t_sec7   v0\n";
          print WRITE "*+               t_sec8   v0\n";
          print WRITE "*+               t_sec9   v0\n";
          print WRITE "*+             )\n";
          print WRITE "\n";
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t_sec0   v0\n"; 
          print WRITE "+               t_sec1   v0\n";
          print WRITE "+               t_sec2   v1\n";
          print WRITE "+               t_sec3   v2\n";
          print WRITE "+               t_sec4   v3\n";
          print WRITE "+               t_sec5   v4\n";
          print WRITE "+               t_sec6   v5\n";
          print WRITE "+               t_sec7   v5\n";
          print WRITE "+               t_sec8   v5\n";
          print WRITE "+               t_sec9   v5\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "*vin0 n1 vss pwl(\n";
          print WRITE "*+               t4   v4\n"; 
          print WRITE "*+               t5   v5\n";
          print WRITE "*+               t6   v6\n";
          print WRITE "*+               t7   v7\n";
          print WRITE "*+               t8   v8\n";
          print WRITE "*+               t9   v9\n";
          print WRITE "*+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t4   v0\n"; 
          print WRITE "+               t5   v1\n";
          print WRITE "+               t6   v2\n";
          print WRITE "+               t7   v3\n";
          print WRITE "+               t8   v4\n";
          print WRITE "+               t9   v5\n";
          print WRITE "+             )\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE ".meas tran n1_first_rise when v(n1)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n2_first_rise when v(n2)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n3_first_rise when v(n3)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".meas tran dclkrise trig v(n2) val=vmid rise=1\n";
          print WRITE "+                targ v(n3) val=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close(WRITE);
          ##############################################################################################################
          system ("ngspice -b -o $file-dclkfall-$input_slew_value-$op_cap.log $file-dclkfall-$input_slew_value-$op_cap");
          system ("ngspice -b -o $file-dclkrise-$input_slew_value-$op_cap.log $file-dclkrise-$input_slew_value-$op_cap");
          ##############################################################################################################
          #-------------------------------------read log file of ngspice for dclkfall----------------------------------#
          open(READ_NG_LOG,"$file-dclkfall-$input_slew_value-$op_cap.log");
          while(<READ_NG_LOG>){
          chomp();
            if($_ =~ /^dclkfall/){s/\s*dclkfall\s*//;my $dclkfall = (split(/=\s+/,$_))[1];
              $dclkfall =~ s/\s*targ//;
              my ($n,$m) = (split(/e/,$dclkfall))[0,1];
              my $m = $m+9;
              my $dclkfall_new = $n*(10**$m);
              push(@dclkfall_list,$dclkfall_new);
            } 
          }#while reading
          close(READ_NG_LOG);
          #---------------------------------read log file of ngspice for dclkrise--------------------------------------#
          open(READ_NG_LOG,"$file-dclkrise-$input_slew_value-$op_cap.log");
          while(<READ_NG_LOG>){
          chomp();
            if($_ =~/^dclkrise /){s/\s*dclkrise\s*//;my $dclkrise = (split(/=\s+/,$_))[1];
              $dclkrise =~ s/\s*targ//;
              my ($n,$m) = (split(/e/,$dclkrise))[0,1];
              my $m = $m+9;
              my $dclkrise_new = $n*(10**$m);
              push(@dclkrise_list,$dclkrise_new);
            }
          }#while reading
          close(READ_NG_LOG);
        #--------------------------------------------------------------------------------------------------------------#
        }#elsif clk eq 1 
      }#for output cap
    }#for input slew
  print WRITE_GENLIB "       cell_rise @dclkrise_list\n";
  print WRITE_GENLIB "       cell_fall @dclkfall_list\n";
  close (WRITE_GENLIB);
&write_lib("-genlib","$cellName.genlib","-lib","$file.lib");
}#sub read_file_for_latch_old

#-----------------------------------------------------------read file for flop----------------------------------------#
sub read_file_for_flop_old {
  my $file = $_[0];
  my $clk = $_[1];
  my $out = $_[2];
  my $in = $_[3];
  my $cellName = "";
  my $vdd_pri = "";
  my $vdd_pri_val = "";
  my $vdd_sec = "";
  my $vdd_sec_val = "";
  my $vss_name = "";
  my $vss_val = "";
  my $wp = "";
  my $wn = "";
  my $new_vdd_1 = "";
  my $new_vdd_2 = "";
  my $new_vss = "";
  my @input_slew = ();
  my @opcap = ();
  my $end_data_of_subckt = 0;
  my $read_data_of_subckt = 0;
  my @get_data = ();
  my @cell_data = ();
  my %SPICE_DATA = ();
  my $data_start = 0;
  my $data_end =0;
  my $data = "";
  my @new_data = ();
  my $mdata = "";
  my %INPUT = ();
  my %OUTPUT = ();
  my @input_list = ();
  my @output_list = ();
  my $read_data_of_subckt_sp = 0;
  my $index = 0;
  my $new_file_spice = "";
#------------------------------------------------------------------------------#  
  open(READ,"$file");
  $file =~ s/.*\///;
  $new_file_spice = $file."\.ngspice";
  open(WRITE_NG,">$new_file_spice");
  while(<READ>){
    chomp();
    s/\*.*$//;
    if($_ =~ /^\s+$/){next;}
    if($_ =~ /^\s*\.subckt/i){
      print WRITE_NG "$_\n";
      $read_data_of_subckt_sp = 1;
    }elsif($_ =~ /^\s*\.end/i){
      $read_data_of_subckt_sp = 0;
      print WRITE_NG "$_\n";
    }elsif($read_data_of_subckt_sp == 1){
      s/ \$X.*=.*\$Y.*=.*\$D.*=.*$//;
      print WRITE_NG "$_\n";
    }
  }
  close(WRITE_NG);
  close(READ);
#------------------------------------------------------------------------------------------------------------#
open(READ_SP,"$file");
my $previous_line = "";
my $next_line = "";
while(<READ_SP>){
chomp();
if($_ =~ /\*/){next;}
if($_ =~ /^\+/){
  s/\s+$//;
  s/^\+//;
  $previous_line = $previous_line." ".$_;
  next;
}
$next_line = $_;
if($previous_line =~ /^\s*\.subckt/i){
  $read_data_of_subckt = 1;
  $end_data_of_subckt = 0;
  $previous_line =~ s/^\s*\.(subckt|SUBCKT)\s*//;
  @cell_data = (split(/\s+/,$previous_line));
  $cellName = shift(@cell_data);
}
if($previous_line =~ /^\s*\.end/i){
  $end_data_of_subckt = 1;
  $read_data_of_subckt = 0;
}
if($read_data_of_subckt == 1 && $end_data_of_subckt == 0){
  if($previous_line=~ /^\s*m\s*/i){
    $data = "";
    @new_data = ();
    $mdata = "";
    $data_start =1;
    $data_end =0;
    $read_cell_data = 0;
  }
  if($previous_line =~ /^\s*c/i){
    $data_end =1;
    $data_start =0;
  }
  if($data_start == 1 && $data_end ==0){
    if($previous_line=~ /^\s*m\s*/i){
    $data = $data." ".$previous_line;
    }else {
    $data = $data." ".$previous_line;
    }
    $data =~ s/^\s*//;
    $data =~ s/=\s+/=/;
    @new_data = (split(/\s+/,$data));
    $mdata = shift (@new_data);
    @{$SPICE_DATA{$mdata}} = @new_data;
  }
}
$previous_line = $next_line;
}#while
close(READ_SP);
#-----------------------------------------------created input and output list------------------------------------------#
if($cellName eq ""){print "ERR:We are not getting cellName from .spi file\n";}
foreach my $mdata (sort {$a cmp $b}keys %SPICE_DATA){
  my @data_new = @{$SPICE_DATA{$mdata}};
  my $data_new_var = join" ",@data_new;
  my ($drain,$gate,$source,$type) = (split(/\s+/,$data_new_var))[0,1,2,4];
  foreach my $port (@cell_data){
    if(($port =~ /vdd/) || ($port =~ /VDD/) || ($port =~ /vss/) || ($port =~ /VSS/) || ($port =~ /gnd/) || ($port =~ /GND/) || ($port =~ /vdar_t/i)|| ($port =~ /vdio_t/i)){}
    else {
      if($cellName =~ m/mux/i){
         #$INPUT{"a"} = 1 if(!exists $INPUT{"a"});
         $INPUT{"A"} = 1 if(!exists $INPUT{"A"});
         #$INPUT{"b"} = 1 if(!exists $INPUT{"b"}); 
         $INPUT{"B"} = 1 if(!exists $INPUT{"B"}); 
         #$INPUT{"sel_a"} = 1 if(!exists $INPUT{"sel_a"});
         $INPUT{"SEL_A"} = 1 if(!exists $INPUT{"SEL_A"});
         #$OUTPUT{"qp"} = 1 if(!exists $OUTPUT{"qp"});
         $OUTPUT{"QP"} = 1 if(!exists $OUTPUT{"QP"});
         #if($port eq $gate || $port eq $source){
         #  $INPUT{$port} = 1 if(!exists $INPUT{$port});
         #}elsif($port eq $drain){
         #   $OUTPUT{$port} = 1 if(!exists $OUTPUT{$port});
         #}
      }else{
         if($port eq $gate){
           $INPUT{$port} = 1 if(!exists $INPUT{$port});
         }elsif((($port eq $drain) || ($port eq $source)) && ($port ne $gate)){
            $OUTPUT{$port} = 1 if(!exists $OUTPUT{$port});
         }
      }#if not mux
    }
  }
}# foreach line 

foreach my $in (keys %INPUT){
  push (@input_list,$in);
  $input_index{$in} = $index;
  $index++;
}
foreach my $out (keys %OUTPUT){
  push (@output_list,$out);
}
#--------------------------------------------------------------------------------------------------------#
###########################################parameter file#################################################
open(READ_PARA,"$parameter_file");
while(<READ_PARA>){
  chomp();
  if($_ =~ /vss/i){($vss_name,$vss_val) = (split(/=\s*/,$_))[0,1];}
  if($_ =~ /width\s*pmos/i){$wp = (split(/=\s*/,$_))[1];}
  if($_ =~ /width\s*nmos/i){$wn = (split(/=\s*/,$_))[1];}
  if($_ =~ /input\s*slew/i){s/\s*input\s*slew\s*=\s*//;@input_slew = (split(/\s+/,$_));}
  if($_ =~ /output\s*capacitance/i){s/\s*output\s*capacitance\s*=\s*//;@opcap = (split(/\s+/,$_));}
  if($_ =~ /vdd\s*sec/i){($vdd_sec,$vdd_sec_val) = (split(/=\s*/,$_))[0,1];}
  elsif($_ =~ /vdd/i){($vdd_pri,$vdd_pri_val) = (split(/=\s*/,$_))[0,1];}
}#while reading parameter file
close (READ_PARA);
#--------------------------------------------------------------------------------------------------------#
my $input_slew_val_1_with_unit = $input_slew[0].""."e-9";
my $op_cap_val_1_with_unit = $opcap[0].""."e-12";
my @get_new_port_list = ();
my @get_new_port_list1 = ();
my $low_to_high = 0; 
my $high_to_low = 0; 
my $output_port = "";
foreach my $port (@cell_data){
  if($port =~ /vd/i){
    push(@get_new_port_list,$port);
    push(@get_new_port_list1,$port);
  }elsif($port =~ /vss/i){
    push(@get_new_port_list,$port);
    push(@get_new_port_list1,$port);
  }elsif($port =~/$clk/){
    push(@get_new_port_list,"n2");
    push(@get_new_port_list1,"n2");
  }elsif($port =~ /$out/){
    push(@get_new_port_list,"n3");
    push(@get_new_port_list1,"n4");
    $output_port = "n3";
  }elsif($port =~ /$in/){
    push(@get_new_port_list,"n1");
    push(@get_new_port_list1,"n3");
  }elsif($port =~ /rs/){ 
    push(@get_new_port_list,"vrs");
    push(@get_new_port_list1,"vrs");
  }
}#foreach port 
####################################write test bench for flop (low to high)######################################
open(WRITE,">$file-low_to_high"); 
  print WRITE ".title Fanout Versus Delay (TSMC)\n";
  print WRITE "\n";
  print WRITE ".param vdd=$vdd_pri_val\n";
  print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
  print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
  print WRITE ".param vss=$vss_val\n";
  print WRITE ".param wp=$wp\n";
  print WRITE ".param wn=$wn\n";
  print WRITE ".param vlo='0.2*vdd'\n";
  print WRITE ".param vmid='0.5*vdd'\n";
  print WRITE ".param vhi='0.8*vdd'\n";
  print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
  print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
  print WRITE ".param v0=vss\n";
  print WRITE ".param v1=vss\n";
  print WRITE ".param v2=vlo\n";
  print WRITE ".param v3=vhi\n";
  print WRITE ".param v4=vdd\n";
  print WRITE ".param v5=vdd\n";
  print WRITE ".param v6=vhi\n";
  print WRITE ".param v7=vlo\n";
  print WRITE ".param v8=vss\n";
  print WRITE ".param v9=vss\n";
  print WRITE "\n";
  print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
  print WRITE ".param t1='inputslew*10/6*1.0'\n";
  print WRITE ".param t2='inputslew*10/6*1.2'\n";
  print WRITE ".param t3='inputslew*10/6*1.8'\n";
  print WRITE ".param t4='inputslew*10/6*2.0'\n";
  print WRITE ".param t5='inputslew*10/6*3.0'\n";
  print WRITE ".param t6='inputslew*10/6*3.2'\n";
  print WRITE ".param t7='inputslew*10/6*3.8'\n";
  print WRITE ".param t8='inputslew*10/6*4.0'\n";
  print WRITE ".param t9='inputslew*10/6*5.0'\n";
  print WRITE "\n";
  print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
  print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
  print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
  print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
  print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
  print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
  print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
  print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
  print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
  print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
  print WRITE "\n";
  print WRITE ".nodeset v(n3)=vss\n";
  print WRITE "\n";
  print WRITE "vdd vdd 0 vdd\n";
  print WRITE "vddsec vddsec 0 vddsec\n";
  print WRITE "vss vss 0   vss\n";
  print WRITE "\n";
  print WRITE "vin n2 vss pwl(\n";
  print WRITE "+               t0   v0\n";
  print WRITE "+               t1   v1\n"; 
  print WRITE "+               t2   v2\n";
  print WRITE "+               t3   v3\n";
  print WRITE "+               t4   v4\n";
  print WRITE "+               t5   v5\n";
  print WRITE "+             )\n";
  print WRITE "\n";
  print WRITE "vin0 n1 vss pwl(\n";
  print WRITE "+               t0   v5\n"; 
  print WRITE "+               t1   v5\n";
  print WRITE "+               t2   v5\n";
  print WRITE "+               t3   v5\n";
  print WRITE "+               t4   v5\n";
  print WRITE "+               t5   v5\n";
  print WRITE "+             )\n";
  print WRITE ".MODEL n NMOS\n";
  print WRITE ".MODEL p PMOS\n";
  print WRITE ".MODEL nd NMOS\n";
  print WRITE ".MODEL pd PMOS\n";
  print WRITE "\n";
  print WRITE "\n";
  print WRITE ".include $new_file_spice\n";
  print WRITE "x$cellName @get_new_port_list $cellName\n";
  print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
  print WRITE "C1 $output_port 0 opcap\n";
  print WRITE "\n";
  print WRITE ".temp 85\n";
  print WRITE ".tran 10p 500n\n";
  print WRITE "\n";
  print WRITE ".meas tran n1_first_rise when v(n1)=vmid rise=1\n";
  print WRITE "\n";
  print WRITE ".meas tran n3_first_rise when v(n3)=vmid rise=1\n";
  print WRITE "\n";
  print WRITE ".end\n";
close(WRITE);
##########################################################################################################
system ("ngspice -b -o $file-low_to_high.log $file-low_to_high");
#----------------------------read log file for n3 first rise---------------------------------------------#
open(READ_LOG,"$file-low_to_high.log"); 
while(<READ_LOG>){
chomp();
  if($_ =~ /^n3_first_rise/){my $n3_first_rise = (split(/=\s+/,$_))[1];
    if($n3_first_rise ne ""){$low_to_high = 1; $high_to_low = 0;}
  } 
}
close(READ_LOG);
#---------------------------write test bench for flop (high to low)--------------------------------------# 
open(WRITE,">$file-high_to_low"); 
  print WRITE ".title Fanout Versus Delay (TSMC)\n";
  print WRITE "\n";
  print WRITE ".param vdd=$vdd_pri_val\n";
  print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
  print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
  print WRITE ".param vss=$vss_val\n";
  print WRITE ".param wp=$wp\n";
  print WRITE ".param wn=$wn\n";
  print WRITE ".param vlo='0.2*vdd'\n";
  print WRITE ".param vmid='0.5*vdd'\n";
  print WRITE ".param vhi='0.8*vdd'\n";
  print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
  print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
  print WRITE ".param v0=vss\n";
  print WRITE ".param v1=vss\n";
  print WRITE ".param v2=vlo\n";
  print WRITE ".param v3=vhi\n";
  print WRITE ".param v4=vdd\n";
  print WRITE ".param v5=vdd\n";
  print WRITE ".param v6=vhi\n";
  print WRITE ".param v7=vlo\n";
  print WRITE ".param v8=vss\n";
  print WRITE ".param v9=vss\n";
  print WRITE "\n";
  print WRITE ".param t0='inputslew*10/6*0.0'\n";
  print WRITE ".param t1='inputslew*10/6*1.0'\n";
  print WRITE ".param t2='inputslew*10/6*1.2'\n"; 
  print WRITE ".param t3='inputslew*10/6*1.8'\n";
  print WRITE ".param t4='inputslew*10/6*2.0'\n";
  print WRITE ".param t5='inputslew*10/6*3.0'\n";
  print WRITE ".param t6='inputslew*10/6*3.2'\n";
  print WRITE ".param t7='inputslew*10/6*3.8'\n";
  print WRITE ".param t8='inputslew*10/6*4.0'\n";
  print WRITE ".param t9='inputslew*10/6*5.0'\n";
  print WRITE "\n";
  print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n";
  print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n"; 
  print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
  print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
  print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
  print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
  print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
  print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
  print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
  print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
  print WRITE "\n";
  print WRITE ".nodeset v(n3)=vss\n";
  print WRITE "\n";
  print WRITE "vdd vdd 0 vdd\n";
  print WRITE "vddsec vddsec 0 vddsec\n";
  print WRITE "vss vss 0   vss\n";
  print WRITE "\n";
  print WRITE "vin n2 vss pwl(\n";
  print WRITE "+               t0   v5\n"; 
  print WRITE "+               t1   v4\n";
  print WRITE "+               t2   v3\n";
  print WRITE "+               t3   v2\n";
  print WRITE "+               t4   v1\n";
  print WRITE "+               t5   v0\n";
  print WRITE "+             )\n";
  print WRITE "\n";
  print WRITE "vin0 n1 vss pwl(\n";
  print WRITE "+               t0   v5\n"; 
  print WRITE "+               t1   v5\n";
  print WRITE "+               t2   v5\n";
  print WRITE "+               t3   v5\n";
  print WRITE "+               t4   v5\n";
  print WRITE "+               t5   v5\n";
  print WRITE "+             )\n";
  print WRITE ".MODEL n NMOS\n";
  print WRITE ".MODEL p PMOS\n";
  print WRITE ".MODEL nd NMOS\n";
  print WRITE ".MODEL pd PMOS\n";
  print WRITE "\n";
  print WRITE "\n";
  print WRITE ".include $new_file_spice\n";
  print WRITE "x$cellName @get_new_port_list $cellName\n";
  print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";  
  print WRITE "C1 $output_port 0 opcap\n";
  print WRITE "\n";
  print WRITE ".temp 85\n";
  print WRITE ".tran 10p 500n\n";
  print WRITE "\n";
  print WRITE ".meas tran n1_first_rise when v(n1)=vmid rise=1\n";
  print WRITE "\n";
  print WRITE ".meas tran n3_first_rise when v(n3)=vmid rise=1\n";
  print WRITE "\n";
  print WRITE ".end\n";
close(WRITE);
##########################################################################################
system ("ngspice -b -o $file-high_to_low.log $file-high_to_low");
#----------------------------------read log file for n3 first rise-----------------------#
open(READ_LOG,"$file-high_to_low.log"); 
while(<READ_LOG>){
chomp();
  if($_ =~ /^n3_first_rise/){my $n3_first_rise = (split(/=\s+/,$_))[1];
    if($n3_first_rise ne ""){$high_to_low = 1; $low_to_high = 0;}
  } 
}
close(READ_LOG);
#----------------------------------------------------------------------------------------#
my $ns = @input_slew;
my $nopcap = @opcap;
my @dclkrise_list = ();
my @dclkfall_list = ();
#----------------------------------------------------------------------------------------#   
open(WRITE_GENLIB,">$cellName.genlib");
  print WRITE_GENLIB "LIBNAME typical\n";
  print WRITE_GENLIB "GATE $cellName 3.2\n";
  print WRITE_GENLIB "  index_1 @input_slew\n";
  print WRITE_GENLIB "  index_2 @opcap\n";
  print WRITE_GENLIB "  PIN $in NONINV input\n";
  print WRITE_GENLIB "   in_index_1 0.0300 0.9000 3.0000\n";
  print WRITE_GENLIB "   in_index_2 0.0300 3.0000\n";
  print WRITE_GENLIB "   related_pin $clk \n";
  print WRITE_GENLIB "      timing_type : setup_rising\n";
  print WRITE_GENLIB "        rise_constraint 0.0859 0.2031 0.0938 0.2031 -0.0312 0.0859\n";
  print WRITE_GENLIB "        fall_constraint 0.1953 0.5469 0.3594 0.7031 0.7188 1.0700\n";
  print WRITE_GENLIB "      timing_type : hold_rising\n";
  print WRITE_GENLIB "        rise_constraint -0.0391 -0.1875 -0.0547 -0.1797 0.0859 -0.0547\n";
  print WRITE_GENLIB "        fall_constraint -0.0469 -0.0938 -0.2187 -0.2422 -0.5547 -0.5547\n";
  print WRITE_GENLIB "  PIN $clk NONINV input\n";
  print WRITE_GENLIB "    clock  true\n";
  print WRITE_GENLIB "  PIN RN NONINV input\n";
  print WRITE_GENLIB "   in_index_1 0.0300 0.9000 3.0000\n";
  print WRITE_GENLIB "   in_index_2 0.0300 3.0000\n";
  print WRITE_GENLIB "   related_pin  CK\n";
  print WRITE_GENLIB "      timing_type : recovery_rising\n";
  print WRITE_GENLIB "        rise_constraint 0.1172 0.1875 0.1563 0.2187 0.0625 0.1328\n";
  print WRITE_GENLIB "  output $out\n";
  print WRITE_GENLIB "  clocked_on $clk\n";
  print WRITE_GENLIB "  input $in\n";
  print WRITE_GENLIB "  reset RN'\n"; 
  print WRITE_GENLIB "  PIN $out NONINV output\n";
  print WRITE_GENLIB "    function : IQ\n";
  print WRITE_GENLIB "      related_pin $clk\n";
  print WRITE_GENLIB "      timing_type : rising_edge\n";
  print WRITE_GENLIB "      timing_sense : non_unate\n";
  for (my $i =0; $i<$ns;$i++){
    for(my $j=0; $j<$nopcap;$j++){
      my $input_slew_value = $input_slew[$i];
      my $input_slew_value_with_unit = $input_slew[$i].""."e-9";
      my $op_cap = $opcap[$j];
      my $op_cap_with_unit = $opcap[$j].""."e-12";
      #--------------------------------------write test bench for dclkfall---------------------------#
      if($low_to_high == 1){
        open(WRITE,">$file-dclkfall-$input_slew_value-$op_cap-low_to_high"); 
        print WRITE ".title Fanout Versus Delay (TSMC)\n";
        print WRITE "\n";
        print WRITE ".param vdd=$vdd_pri_val\n";
        print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
        print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
        print WRITE ".param vss=$vss_val\n";
        print WRITE ".param wp=$wp\n";
        print WRITE ".param wn=$wn\n";
        print WRITE ".param vlo='0.2*vdd'\n";
        print WRITE ".param vmid='0.5*vdd'\n";
        print WRITE ".param vhi='0.8*vdd'\n";
        print WRITE ".param opcap=$op_cap_with_unit\n";
        print WRITE ".param inputslew=$input_slew_value_with_unit\n";
        print WRITE ".param v0=vss\n";
        print WRITE ".param v1=vss\n";
        print WRITE ".param v2=vlo\n";
        print WRITE ".param v3=vhi\n"; 
        print WRITE ".param v4=vdd\n";
        print WRITE ".param v5=vdd\n";
        print WRITE ".param v6=vhi\n";
        print WRITE ".param v7=vlo\n";
        print WRITE ".param v8=vss\n";
        print WRITE ".param v9=vss\n";
        print WRITE "\n";
        print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
        print WRITE ".param t1='inputslew*10/6*1.0'\n";
        print WRITE ".param t2='inputslew*10/6*1.2'\n";
        print WRITE ".param t3='inputslew*10/6*1.8'\n";
        print WRITE ".param t4='inputslew*10/6*2.0'\n";
        print WRITE ".param t5='inputslew*10/6*3.0'\n";
        print WRITE ".param t6='inputslew*10/6*3.2'\n";
        print WRITE ".param t7='inputslew*10/6*3.8'\n";
        print WRITE ".param t8='inputslew*10/6*4.0'\n";
        print WRITE ".param t9='inputslew*10/6*5.0'\n";
        print WRITE "\n";
        print WRITE ".param t_sec0='inputslew*10/6*0.0 + inputslew*10/6*5'\n"; 
        print WRITE ".param t_sec1='inputslew*10/6*1.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec2='inputslew*10/6*1.2 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec3='inputslew*10/6*1.8 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec4='inputslew*10/6*2.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec5='inputslew*10/6*3.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec6='inputslew*10/6*3.2 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec7='inputslew*10/6*3.8 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec8='inputslew*10/6*4.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec9='inputslew*10/6*5.0 + inputslew*10/6*5'\n";
        print WRITE "\n";
        print WRITE ".nodeset v(n3)=vdd\n";
        print WRITE "\n";
        print WRITE "vdd vdd 0 vdd\n";
        print WRITE "vddsec vddsec 0 vddsec\n";
        print WRITE "vss vss 0   vss\n";
        print WRITE "\n";
        print WRITE "vin n2 vss pwl(\n";
        print WRITE "+               t0   v0\n"; 
        print WRITE "+               t1   v1\n";
        print WRITE "+               t2   v2\n";
        print WRITE "+               t3   v3\n";
        print WRITE "+               t4   v4\n";
        print WRITE "+               t5   v5\n";
        print WRITE "+             )\n";
        print WRITE "\n";
        print WRITE "vin0 n1 vss pwl(\n";
        print WRITE "+               t0   v0\n"; 
        print WRITE "+               t1   v0\n";
        print WRITE "+               t2   v0\n";
        print WRITE "+               t3   v0\n";
        print WRITE "+               t4   v0\n";
        print WRITE "+               t5   v0\n";
        print WRITE "+             )\n";
        print WRITE ".MODEL n NMOS\n";
        print WRITE ".MODEL p PMOS\n";
        print WRITE ".MODEL nd NMOS\n";
        print WRITE ".MODEL pd PMOS\n";
        print WRITE "\n";
        print WRITE "\n";
        print WRITE ".include $new_file_spice\n";
        print WRITE "x$cellName @get_new_port_list $cellName\n";
        print WRITE "*xx$cellName @get_new_port_list1 $cellName\n"; 
        print WRITE "C1 $output_port 0 opcap\n";
        print WRITE "\n";
        print WRITE ".temp 85\n";
        print WRITE ".tran 10p 500n\n";
        print WRITE "\n";
        print WRITE ".meas tran n3_first_fall when v(n3)=vmid fall=1\n";
        print WRITE "\n";
        print WRITE ".meas tran dclkfall trig v(n2) val=vmid rise=1\n";
        print WRITE "+                targ v(n3) val=vmid fall=1\n";
        print WRITE "\n";
        print WRITE ".end\n";
        close(WRITE);
        #------------------------------------------------------write test bench for dclkrise-----------------------------------------------#
        open(WRITE,">$file-dclkrise-$input_slew_value-$op_cap-low_to_high"); 
        print WRITE ".title Fanout Versus Delay (TSMC)\n";
        print WRITE "\n";
        print WRITE ".param vdd=$vdd_pri_val\n";
        print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
        print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
        print WRITE ".param vss=$vss_val\n";
        print WRITE ".param wp=$wp\n";
        print WRITE ".param wn=$wn\n";
        print WRITE ".param vlo='0.2*vdd'\n";
        print WRITE ".param vmid='0.5*vdd'\n";
        print WRITE ".param vhi='0.8*vdd'\n";
        print WRITE ".param opcap=$op_cap_with_unit\n";
        print WRITE ".param inputslew=$input_slew_value_with_unit\n";
        print WRITE ".param v0=vss\n";
        print WRITE ".param v1=vss\n";
        print WRITE ".param v2=vlo\n";
        print WRITE ".param v3=vhi\n";
        print WRITE ".param v4=vdd\n";
        print WRITE ".param v5=vdd\n";
        print WRITE ".param v6=vhi\n";
        print WRITE ".param v7=vlo\n";
        print WRITE ".param v8=vss\n";
        print WRITE ".param v9=vss\n";
        print WRITE "\n";
        print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
        print WRITE ".param t1='inputslew*10/6*1.0'\n";
        print WRITE ".param t2='inputslew*10/6*1.2'\n";
        print WRITE ".param t3='inputslew*10/6*1.8'\n";
        print WRITE ".param t4='inputslew*10/6*2.0'\n";
        print WRITE ".param t5='inputslew*10/6*3.0'\n";
        print WRITE ".param t6='inputslew*10/6*3.2'\n";
        print WRITE ".param t7='inputslew*10/6*3.8'\n";
        print WRITE ".param t8='inputslew*10/6*4.0'\n";
        print WRITE ".param t9='inputslew*10/6*5.0'\n";
        print WRITE "\n";
        print WRITE ".param t_sec0='inputslew*10/6*0.0 + inputslew*10/6*5'\n"; 
        print WRITE ".param t_sec1='inputslew*10/6*1.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec2='inputslew*10/6*1.2 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec3='inputslew*10/6*1.8 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec4='inputslew*10/6*2.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec5='inputslew*10/6*3.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec6='inputslew*10/6*3.2 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec7='inputslew*10/6*3.8 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec8='inputslew*10/6*4.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec9='inputslew*10/6*5.0 + inputslew*10/6*5'\n";
        print WRITE "\n";
        print WRITE ".nodeset v(n3)=vss\n";
        print WRITE "\n";
        print WRITE "vdd vdd 0 vdd\n";
        print WRITE "vddsec vddsec 0 vddsec\n";
        print WRITE "vss vss 0   vss\n";
        print WRITE "\n";
        print WRITE "vin n2 vss pwl(\n";
        print WRITE "+               t0   v0\n"; 
        print WRITE "+               t1   v1\n";
        print WRITE "+               t2   v2\n";
        print WRITE "+               t3   v3\n";
        print WRITE "+               t4   v4\n";
        print WRITE "+               t5   v5\n";
        print WRITE "+             )\n";
        print WRITE "\n";
        print WRITE "vin0 n1 vss pwl(\n";
        print WRITE "+               t0   v5\n"; 
        print WRITE "+               t1   v5\n";
        print WRITE "+               t2   v5\n";
        print WRITE "+               t3   v5\n";
        print WRITE "+               t4   v5\n";
        print WRITE "+               t5   v5\n";
        print WRITE "+             )\n";
        print WRITE ".MODEL n NMOS\n";
        print WRITE ".MODEL p PMOS\n";
        print WRITE ".MODEL nd NMOS\n";
        print WRITE ".MODEL pd PMOS\n";
        print WRITE "\n";
        print WRITE "\n";
        print WRITE ".include $new_file_spice\n";
        print WRITE "x$cellName @get_new_port_list $cellName\n";
        print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
        print WRITE "C1 $output_port 0 opcap\n";
        print WRITE "\n";
        print WRITE ".temp 85\n";
        print WRITE ".tran 10p 500n\n";
        print WRITE "\n";
        print WRITE ".meas tran n3_first_rise when v(n3)=vmid rise=1\n";
        print WRITE "\n";
        print WRITE ".meas tran dclkrise trig v(n2) val=vmid rise=1\n";
        print WRITE "+                targ v(n3) val=vmid rise=1\n";
        print WRITE "\n";
        print WRITE ".end\n";
        close(WRITE);
        ######################################################################################################################################
        system ("ngspice -b -o $file-dclkfall-$input_slew_value-$op_cap-low_to_high.log $file-dclkfall-$input_slew_value-$op_cap-low_to_high");
        system ("ngspice -b -o $file-dclkrise-$input_slew_value-$op_cap-low_to_high.log $file-dclkrise-$input_slew_value-$op_cap-low_to_high");
        ######################################################################################################################################
        #-------------------------------------read log file of ngspice for dclkfall----------------------------------------------------------#
        open(READ_NG_LOG,"$file-dclkfall-$input_slew_value-$op_cap-low_to_high.log");
        while(<READ_NG_LOG>){
        chomp();
          if($_ =~ /^dclkfall/){s/\s*dclkfall\s*//;my $dclkfall = (split(/=\s+/,$_))[1];
            $dclkfall =~ s/\s*targ//;
            my ($n,$m) = (split(/e/,$dclkfall))[0,1];
            my $m = $m+9;
            my $dclkfall_new = $n*(10**$m);
            push(@dclkfall_list,$dclkfall_new);
          } 
        }#while reading
        close(READ_NG_LOG);
        #---------------------------------read log file of ngspice for dclkrise----------------------------------------#
        open(READ_NG_LOG,"$file-dclkrise-$input_slew_value-$op_cap-low_to_high.log");
        while(<READ_NG_LOG>){
        chomp();
          if($_ =~/^dclkrise /){s/\s*dclkrise\s*//;my $dclkrise = (split(/=\s+/,$_))[1];
            $dclkrise =~ s/\s*targ//;
            my ($n,$m) = (split(/e/,$dclkrise))[0,1];
            my $m = $m+9;
            my $dclkrise_new = $n*(10**$m);
            push(@dclkrise_list,$dclkrise_new);
          }
        }#while reading
        close(READ_NG_LOG);
      }#if low_to_high eq 1
      #--------------------------------------------write test bench for high to low-------------------------------------#
      if($high_to_low == 1){
        open(WRITE,">$file-dclkfall-$input_slew_value-$op_cap-high_to_low"); 
        print WRITE ".title Fanout Versus Delay (TSMC)\n";
        print WRITE "\n";
        print WRITE ".param vdd=$vdd_pri_val\n";
        print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
        print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
        print WRITE ".param vss=$vss_val\n";
        print WRITE ".param wp=$wp\n";
        print WRITE ".param wn=$wn\n";
        print WRITE ".param vlo='0.2*vdd'\n";
        print WRITE ".param vmid='0.5*vdd'\n";
        print WRITE ".param vhi='0.8*vdd'\n";
        print WRITE ".param opcap=$op_cap_with_unit\n";
        print WRITE ".param inputslew=$input_slew_value_with_unit\n";
        print WRITE ".param v0=vss\n";
        print WRITE ".param v1=vss\n";
        print WRITE ".param v2=vlo\n";
        print WRITE ".param v3=vhi\n";
        print WRITE ".param v4=vdd\n";
        print WRITE ".param v5=vdd\n"; 
        print WRITE ".param v6=vhi\n";
        print WRITE ".param v7=vlo\n";
        print WRITE ".param v8=vss\n";
        print WRITE ".param v9=vss\n";
        print WRITE "\n";
        print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
        print WRITE ".param t1='inputslew*10/6*1.0'\n";
        print WRITE ".param t2='inputslew*10/6*1.2'\n";
        print WRITE ".param t3='inputslew*10/6*1.8'\n";
        print WRITE ".param t4='inputslew*10/6*2.0'\n";
        print WRITE ".param t5='inputslew*10/6*3.0'\n";
        print WRITE ".param t6='inputslew*10/6*3.2'\n";
        print WRITE ".param t7='inputslew*10/6*3.8'\n";
        print WRITE ".param t8='inputslew*10/6*4.0'\n";
        print WRITE ".param t9='inputslew*10/6*5.0'\n";
        print WRITE "\n";
        print WRITE ".param t_sec0='inputslew*10/6*0.0 + inputslew*10/6*5'\n"; 
        print WRITE ".param t_sec1='inputslew*10/6*1.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec2='inputslew*10/6*1.2 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec3='inputslew*10/6*1.8 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec4='inputslew*10/6*2.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec5='inputslew*10/6*3.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec6='inputslew*10/6*3.2 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec7='inputslew*10/6*3.8 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec8='inputslew*10/6*4.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec9='inputslew*10/6*5.0 + inputslew*10/6*5'\n";
        print WRITE "\n";
        print WRITE ".nodeset v(n3)=vdd\n";
        print WRITE "\n";
        print WRITE "vdd vdd 0 vdd\n";
        print WRITE "vddsec vddsec 0 vddsec\n";
        print WRITE "vss vss 0   vss\n";
        print WRITE "\n";
        print WRITE "vin n2 vss pwl(\n";
        print WRITE "+               t0   v5\n"; 
        print WRITE "+               t1   v4\n";
        print WRITE "+               t2   v3\n";
        print WRITE "+               t3   v2\n";
        print WRITE "+               t4   v1\n";
        print WRITE "+               t5   v0\n";
        print WRITE "+             )\n";
        print WRITE "\n";
        print WRITE "vin0 n1 vss pwl(\n";
        print WRITE "+               t0   v0\n"; 
        print WRITE "+               t1   v0\n";
        print WRITE "+               t2   v0\n";
        print WRITE "+               t3   v0\n";
        print WRITE "+               t4   v0\n";
        print WRITE "+               t5   v0\n";
        print WRITE "+             )\n";
        print WRITE ".MODEL n NMOS\n";
        print WRITE ".MODEL p PMOS\n";
        print WRITE ".MODEL nd NMOS\n";
        print WRITE ".MODEL pd PMOS\n";
        print WRITE "\n";
        print WRITE "\n";
        print WRITE ".include $new_file_spice\n";
        print WRITE "x$cellName @get_new_port_list $cellName\n";
        print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
        print WRITE "C1 $output_port 0 opcap\n";
        print WRITE "\n";
        print WRITE ".temp 85\n";
        print WRITE ".tran 10p 500n\n";
        print WRITE "\n";
        print WRITE ".meas tran n3_first_fall when v(n3)=vmid fall=1\n";
        print WRITE "\n";
        print WRITE ".meas tran dclkfall trig v(n2) val=vmid fall=1\n";
        print WRITE "+                targ v(n3) val=vmid fall=1\n";
        print WRITE "\n";
        print WRITE ".end\n";
        close(WRITE);
        #-----------------------------------write test bench for dclkrise-----------------------------------------------#
        open(WRITE,">$file-dclkrise-$input_slew_value-$op_cap-high_to_low"); 
        print WRITE ".title Fanout Versus Delay (TSMC)\n";
        print WRITE "\n";
        print WRITE ".param vdd=$vdd_pri_val\n";
        print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
        print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
        print WRITE ".param vss=$vss_val\n";
        print WRITE ".param wp=$wp\n";
        print WRITE ".param wn=$wn\n";
        print WRITE ".param vlo='0.2*vdd'\n";
        print WRITE ".param vmid='0.5*vdd'\n";
        print WRITE ".param vhi='0.8*vdd'\n";
        print WRITE ".param opcap=$op_cap_with_unit\n";
        print WRITE ".param inputslew=$input_slew_value_with_unit\n";
        print WRITE ".param v0=vss\n";
        print WRITE ".param v1=vss\n";
        print WRITE ".param v2=vlo\n";
        print WRITE ".param v3=vhi\n";
        print WRITE ".param v4=vdd\n"; 
        print WRITE ".param v5=vdd\n";
        print WRITE ".param v6=vhi\n";
        print WRITE ".param v7=vlo\n";
        print WRITE ".param v8=vss\n";
        print WRITE ".param v9=vss\n";
        print WRITE "\n";
        print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
        print WRITE ".param t1='inputslew*10/6*1.0'\n";
        print WRITE ".param t2='inputslew*10/6*1.2'\n";
        print WRITE ".param t3='inputslew*10/6*1.8'\n";
        print WRITE ".param t4='inputslew*10/6*2.0'\n";
        print WRITE ".param t5='inputslew*10/6*3.0'\n";
        print WRITE ".param t6='inputslew*10/6*3.2'\n";
        print WRITE ".param t7='inputslew*10/6*3.8'\n";
        print WRITE ".param t8='inputslew*10/6*4.0'\n";
        print WRITE ".param t9='inputslew*10/6*5.0'\n";
        print WRITE "\n";
        print WRITE ".param t_sec0='inputslew*10/6*0.0 + inputslew*10/6*5'\n"; 
        print WRITE ".param t_sec1='inputslew*10/6*1.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec2='inputslew*10/6*1.2 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec3='inputslew*10/6*1.8 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec4='inputslew*10/6*2.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec5='inputslew*10/6*3.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec6='inputslew*10/6*3.2 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec7='inputslew*10/6*3.8 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec8='inputslew*10/6*4.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec9='inputslew*10/6*5.0 + inputslew*10/6*5'\n";
        print WRITE "\n";
        print WRITE ".nodeset v(n3)=vss\n";
        print WRITE "\n";
        print WRITE "vdd vdd 0 vdd\n";
        print WRITE "vddsec vddsec 0 vddsec\n";
        print WRITE "vss vss 0   vss\n";
        print WRITE "\n";
        print WRITE "vin n2 vss pwl(\n";
        print WRITE "+               t0   v5\n"; 
        print WRITE "+               t1   v4\n";
        print WRITE "+               t2   v3\n";
        print WRITE "+               t3   v2\n";
        print WRITE "+               t4   v1\n";
        print WRITE "+               t5   v0\n";
        print WRITE "+             )\n";
        print WRITE "\n";
        print WRITE "vin0 n1 vss pwl(\n";
        print WRITE "+               t0   v5\n"; 
        print WRITE "+               t1   v5\n";
        print WRITE "+               t2   v5\n";
        print WRITE "+               t3   v5\n";
        print WRITE "+               t4   v5\n";
        print WRITE "+               t5   v5\n";
        print WRITE "+             )\n";
        print WRITE ".MODEL n NMOS\n";
        print WRITE ".MODEL p PMOS\n";
        print WRITE ".MODEL nd NMOS\n";
        print WRITE ".MODEL pd PMOS\n";
        print WRITE "\n";
        print WRITE "\n";
        print WRITE ".include $new_file_spice\n";
        print WRITE "x$cellName @get_new_port_list $cellName\n";
        print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
        print WRITE "C1 $output_port 0 opcap\n";
        print WRITE "\n";
        print WRITE ".temp 85\n";
        print WRITE ".tran 10p 500n\n";
        print WRITE "\n";
        print WRITE ".meas tran n3_first_rise when v(n3)=vmid rise=1\n";
        print WRITE "\n";
        print WRITE ".meas tran dclkrise trig v(n2) val=vmid fall=1\n";
        print WRITE "+                targ v(n3) val=vmid rise=1\n";
        print WRITE "\n";
        print WRITE ".end\n";
        close(WRITE);
        ################################################################################################################
        system ("ngspice -b -o $file-dclkfall-$input_slew_value-$op_cap-high_to_low.log $file-dclkfall-$input_slew_value-$op_cap-high_to_low");
        system ("ngspice -b -o $file-dclkrise-$input_slew_value-$op_cap-high_to_low.log $file-dclkrise-$input_slew_value-$op_cap-high_to_low");
        ################################################################################################################
        #-------------------------------------read log file of ngspice for dclkfall------------------------------------#
        open(READ_NG_LOG,"$file-dclkfall-$input_slew_value-$op_cap-high_to_low.log");
        while(<READ_NG_LOG>){
        chomp();
          if($_ =~ /^dclkfall/){s/\s*dclkfall\s*//;my $dclkfall = (split(/=\s+/,$_))[1];
            $dclkfall =~ s/\s*targ//;
            my ($n,$m) = (split(/e/,$dclkfall))[0,1];
            my $m = $m+9;
            my $dclkfall_new = $n*(10**$m);
            push(@dclkfall_list,$dclkfall_new);
          } 
        }#while reading
        close(READ_NG_LOG);
        #---------------------------------read log file of ngspice for dclkrise----------------------------------------#
        open(READ_NG_LOG,"$file-dclkrise-$input_slew_value-$op_cap-hight_to_low.log");
        while(<READ_NG_LOG>){
        chomp();
          if($_ =~/^dclkrise /){s/\s*dclkrise\s*//;my $dclkrise = (split(/=\s+/,$_))[1];
            $dclkrise =~ s/\s*targ//;
            my ($n,$m) = (split(/e/,$dclkrise))[0,1];
            my $m = $m+9;
            my $dclkrise_new = $n*(10**$m);
            push(@dclkrise_list,$dclkrise_new);
          }
        }#while reading
        close(READ_NG_LOG);
      }#if high_to_low eq 1
    }#for
  }#for
  print WRITE_GENLIB "       cell_rise @dclkrise_list\n";
  print WRITE_GENLIB "       cell_fall @dclkfall_list\n";
  close (WRITE_GENLIB);
&write_lib("-genlib","$cellName.genlib","-lib","$file.lib");
}#sub read_file_for_flop_old

#-------------------------------------------------------------------------------------------------------------------------#
sub read_file_for_flop {
  my $file = $_[0];
  my $clk = $_[1];
  my $out = $_[2];
  my $in = $_[3];
  my $cellName = "";
  my $vdd_pri = "";
  my $vdd_pri_val = "";
  my $vdd_sec = "";
  my $vdd_sec_val = "";
  my $vss_name = "";
  my $vss_val = "";
  my $wp = "";
  my $wn = "";
  my $new_vdd_1 = "";
  my $new_vdd_2 = "";
  my $new_vss = "";
  my @input_slew = ();
  my @input_slew_clock = ();
  my @opcap = ();
  my $end_data_of_subckt = 0;
  my $read_data_of_subckt = 0;
  my @get_data = ();
  my @cell_data = ();
  my %SPICE_DATA = ();
  my $data_start = 0;
  my $data_end =0;
  my $data = "";
  my @new_data = ();
  my $mdata = "";
  my %INPUT = ();
  my %OUTPUT = ();
  my @input_list = ();
  my @output_list = ();
  my $read_data_of_subckt_sp = 0;
  my $index = 0;
  my $new_file_spice = "";
#------------------------------------------------------------------------------#  
  open(READ,"$file");
  $file =~ s/.*\///;
  $new_file_spice = $file."\.ngspice";
  open(WRITE_NG,">$new_file_spice");
  while(<READ>){
    chomp();
    s/\*.*$//;
    if($_ =~ /^\s+$/){next;}
    if($_ =~ /^\s*\.subckt/i){
      print WRITE_NG "$_\n";
      $read_data_of_subckt_sp = 1;
    }elsif($_ =~ /^\s*\.end/i){
      $read_data_of_subckt_sp = 0;
      print WRITE_NG "$_\n";
    }elsif($read_data_of_subckt_sp == 1){
      s/ \$X.*=.*\$Y.*=.*\$D.*=.*$//;
      print WRITE_NG "$_\n";
    }
  }
  close(WRITE_NG);
  close(READ);
#------------------------------------------------------------------------------------------------------------#
open(READ_SP,"$file");
my $previous_line = "";
my $next_line = "";
while(<READ_SP>){
chomp();
if($_ =~ /\*/){next;}
if($_ =~ /^\+/){
  s/\s+$//;
  s/^\+//;
  $previous_line = $previous_line." ".$_;
  next;
}
$next_line = $_;
if($previous_line =~ /^\s*\.subckt/i){
  $read_data_of_subckt = 1;
  $end_data_of_subckt = 0;
  $previous_line =~ s/^\s*\.(subckt|SUBCKT)\s*//;
  @cell_data = (split(/\s+/,$previous_line));
  $cellName = shift(@cell_data);
}
if($previous_line =~ /^\s*\.end/i){
  $end_data_of_subckt = 1;
  $read_data_of_subckt = 0;
}
if($read_data_of_subckt == 1 && $end_data_of_subckt == 0){
  if($previous_line=~ /^\s*m\s*/i){
    $data = "";
    @new_data = ();
    $mdata = "";
    $data_start =1;
    $data_end =0;
    $read_cell_data = 0;
  }
  if($previous_line =~ /^\s*c/i){
    $data_end =1;
    $data_start =0;
  }
  if($data_start == 1 && $data_end ==0){
    if($previous_line=~ /^\s*m\s*/i){
    $data = $data." ".$previous_line;
    }else {
    $data = $data." ".$previous_line;
    }
    $data =~ s/^\s*//;
    $data =~ s/=\s+/=/;
    @new_data = (split(/\s+/,$data));
    $mdata = shift (@new_data);
    @{$SPICE_DATA{$mdata}} = @new_data;
  }
}
$previous_line = $next_line;
}#while
close(READ_SP);
#-----------------------------------------------created input and output list------------------------------------------#
if($cellName eq ""){print "ERR:We are not getting cellName from .spi file\n";}
foreach my $mdata (sort {$a cmp $b}keys %SPICE_DATA){
  my @data_new = @{$SPICE_DATA{$mdata}};
  my $data_new_var = join" ",@data_new;
  my ($drain,$gate,$source,$type) = (split(/\s+/,$data_new_var))[0,1,2,4];
  foreach my $port (@cell_data){
    if(($port =~ /vdd/) || ($port =~ /VDD/) || ($port =~ /vss/) || ($port =~ /VSS/) || ($port =~ /gnd/) || ($port =~ /GND/) || ($port =~ /vdar_t/i)|| ($port =~ /vdio_t/i)){}
    else {
      if($cellName =~ m/mux/i){
         #$INPUT{"a"} = 1 if(!exists $INPUT{"a"});
         $INPUT{"A"} = 1 if(!exists $INPUT{"A"});
         #$INPUT{"b"} = 1 if(!exists $INPUT{"b"}); 
         $INPUT{"B"} = 1 if(!exists $INPUT{"B"}); 
         #$INPUT{"sel_a"} = 1 if(!exists $INPUT{"sel_a"});
         $INPUT{"SEL_A"} = 1 if(!exists $INPUT{"SEL_A"});
         #$OUTPUT{"qp"} = 1 if(!exists $OUTPUT{"qp"});
         $OUTPUT{"QP"} = 1 if(!exists $OUTPUT{"QP"});
         #if($port eq $gate || $port eq $source){
         #  $INPUT{$port} = 1 if(!exists $INPUT{$port});
         #}elsif($port eq $drain){
         #   $OUTPUT{$port} = 1 if(!exists $OUTPUT{$port});
         #}
      }else{
         if($port eq $gate){
           $INPUT{$port} = 1 if(!exists $INPUT{$port});
         }elsif((($port eq $drain) || ($port eq $source)) && ($port ne $gate)){
            $OUTPUT{$port} = 1 if(!exists $OUTPUT{$port});
         }
      }#if not mux
    }
  }
}# foreach line 

foreach my $in (keys %INPUT){
  push (@input_list,$in);
  $input_index{$in} = $index;
  $index++;
}
foreach my $out (keys %OUTPUT){
  push (@output_list,$out);
}
#--------------------------------------------------------------------------------------------------------#
###########################################parameter file#################################################
open(READ_PARA,"$parameter_file");
while(<READ_PARA>){
  chomp();
  if($_ =~ /vss/i){($vss_name,$vss_val) = (split(/=\s*/,$_))[0,1];}
  if($_ =~ /width\s*pmos/i){$wp = (split(/=\s*/,$_))[1];}
  if($_ =~ /width\s*nmos/i){$wn = (split(/=\s*/,$_))[1];}
  if($_ =~ /input\s*slew\s*clock/i){s/\s*input\s*slew\s*clock\s*=\s*//;@input_slew_clock = (split(/\s+/,$_));}
  if($_ =~ /input\s*slew/i){s/\s*input\s*slew\s*=\s*//;@input_slew = (split(/\s+/,$_));}
  if($_ =~ /output\s*capacitance/i){s/\s*output\s*capacitance\s*=\s*//;@opcap = (split(/\s+/,$_));}
  if($_ =~ /vdd\s*sec/i){($vdd_sec,$vdd_sec_val) = (split(/=\s*/,$_))[0,1];}
  elsif($_ =~ /vdd/i){($vdd_pri,$vdd_pri_val) = (split(/=\s*/,$_))[0,1];}
}#while reading parameter file
close (READ_PARA);
#--------------------------------------------------------------------------------------------------------#
my $input_slew_val_1_with_unit = $input_slew[0].""."e-9";
my $op_cap_val_1_with_unit = $opcap[0].""."e-12";
my @get_new_port_list = ();
my @get_new_port_list1 = ();
my $get_n2_val = "";
my $output_port = "";
my $reset_port = "";
my @clk_value = ();
my @n1_value = ();
my @n3_value = ();
my $reset_exists = 0;
my @reset_value = ();
foreach my $port (@cell_data){
  if($port =~ /vd/i){
    push(@get_new_port_list,$port);
    push(@get_new_port_list1,$port);
  }elsif($port =~ /vss/i){
    push(@get_new_port_list,$port);
    push(@get_new_port_list1,$port);
  }elsif($port =~/$clk/){
    push(@get_new_port_list,"n2");
    push(@get_new_port_list1,"n2");
    push(@clk_value,0,1);
  }elsif($port =~ /$out/){
    push(@get_new_port_list,"n3");
    push(@get_new_port_list1,"n4");
    push (@n3_value,"vdd","vss");
    $output_port = "n3";
  }elsif($port =~ /$in/){
    push(@get_new_port_list,"n1");
    push(@get_new_port_list1,"n3");
    push(@n1_value,0,1);
  }elsif($port =~ /rs/){ 
    push(@get_new_port_list,"vrs");
    push(@get_new_port_list1,"vrs");
    push (@reset_value,0,1);
    $reset_exists = 1;
    $reset_port = $port;
  }
}#foreach port 
####################################write test bench for flop to find value of clock and reset#######################################
if ($reset_exists == 1){
  my $get_clock_val = "";  
  my $get_n1_value = "";
  my $get_n3_value = "";
  my $get_reset_value = "";
  for (my $vl=0;$vl<=$#reset_value;$vl++){
    for (my $vol=0;$vol<=$#n3_value;$vol++){
      for(my $ck_val=0;$ck_val<=$#clk_value;$ck_val++){
        for(my $n1val=0;$n1val<=$#n1_value;$n1val++){ 
        my $ck_value = $clk_value[$ck_val];
        my $reset_val = $reset_value[$vl];
        my $n3_vl = $n3_value[$vol];
        my $n1_vl = $n1_value[$n1val];
        if($ck_value == 0 && $reset_val == 0 && $n1_vl == 0 && $n3_vl eq "vdd"){
        open(WRITE,">$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
        print WRITE ".title Fanout Versus Delay (TSMC)\n";
        print WRITE "\n";
        print WRITE ".param vdd=$vdd_pri_val\n";
        print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
        print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
        print WRITE ".param vss=$vss_val\n";
        print WRITE ".param wp=$wp\n";
        print WRITE ".param wn=$wn\n";
        print WRITE ".param vlo='0.2*vdd'\n";
        print WRITE ".param vmid='0.5*vdd'\n";
        print WRITE ".param vhi='0.8*vdd'\n";
        print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
        print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
        print WRITE ".param v0=vss\n"; 
        print WRITE ".param v1=vss\n";
        print WRITE ".param v2=vlo\n";
        print WRITE ".param v3=vhi\n";
        print WRITE ".param v4=vdd\n";
        print WRITE ".param v5=vdd\n";
        print WRITE ".param v6=vhi\n";
        print WRITE ".param v7=vlo\n";
        print WRITE ".param v8=vss\n";
        print WRITE ".param v9=vss\n";
        print WRITE "\n";
        print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
        print WRITE ".param t1='inputslew*10/6*1.0'\n";
        print WRITE ".param t2='inputslew*10/6*1.2'\n";
        print WRITE ".param t3='inputslew*10/6*1.8'\n";
        print WRITE ".param t4='inputslew*10/6*2.0'\n";
        print WRITE ".param t5='inputslew*10/6*3.0'\n";
        print WRITE ".param t6='inputslew*10/6*3.2'\n";
        print WRITE ".param t7='inputslew*10/6*3.8'\n";
        print WRITE ".param t8='inputslew*10/6*4.0'\n";
        print WRITE ".param t9='inputslew*10/6*5.0'\n";
        print WRITE "\n";
        print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
        print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
        print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
        print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
        print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
        print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
        print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
        print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
        print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
        print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
        print WRITE "\n";
        print WRITE ".nodeset v(n3)=vdd\n";
        print WRITE "\n";
        print WRITE "vdd vdd 0 vdd\n";
        print WRITE "vddsec vddsec 0 vddsec\n";
        print WRITE "vss vss 0   vss\n";
        print WRITE "\n";
        print WRITE "vrs vrs 0   vss\n";
        print WRITE "\n"; 
        print WRITE "vin n2 vss pwl(\n";
        print WRITE "+               t0   v5\n"; 
        print WRITE "+               t1   v4\n";
        print WRITE "+               t2   v3\n";
        print WRITE "+               t3   v2\n";
        print WRITE "+               t4   v1\n";
        print WRITE "+               t5   v0\n";
        print WRITE "+             )\n";
        print WRITE "\n";
        print WRITE "vin0 n1 vss pwl(\n";
        print WRITE "+               t0   v0\n"; 
        print WRITE "+               t1   v0\n";
        print WRITE "+               t2   v0\n";
        print WRITE "+               t3   v0\n";
        print WRITE "+               t4   v0\n";
        print WRITE "+               t5   v0\n";
        print WRITE "+             )\n";
        print WRITE ".MODEL n NMOS\n";
        print WRITE ".MODEL p PMOS\n";
        print WRITE ".MODEL nd NMOS\n";
        print WRITE ".MODEL pd PMOS\n";
        print WRITE "\n";
        print WRITE "\n";
        print WRITE ".include $new_file_spice\n";
        print WRITE "x$cellName @get_new_port_list $cellName\n";
        print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
        print WRITE "C1 $output_port 0 opcap\n";
        print WRITE "\n";
        print WRITE ".temp 85\n";
        print WRITE ".tran 10p 500n\n";
        print WRITE "\n";
        print WRITE "*.meas tran n1_first_fall when v(n1)=vmid fall=1\n";
        print WRITE "\n";
        print WRITE ".meas tran n3_first_fall when v(n3)=vmid fall=1\n";
        print WRITE "\n";
        print WRITE ".end\n";
        close (WRITE);
        ###############################################################################################################################
        system ("ngspice -b -o $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl"); 
        #-------------------------------------------------------read log file---------------------------------------------------------#
        open(READ_LOG,"$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log");
        while(<READ_LOG>){
        chomp();
          if($_ =~ /^n3_first_fall/){my $n3_first_fall = (split(/=\s+/,$_))[1];
            if($n3_first_fall ne ""){$get_clock_val = $ck_value;
                                     $get_n1_value = $n1_vl;
                                     $get_n3_value = $n3_vl;
                                     $get_reset_value = $reset_val;}
          }
        }#while reading log file
        close(READ_LOG);
        #-----------------------------------------------------------------------------------------------------------------------------------------------------------------------#
        }elsif($ck_value == 1 && $reset_val == 0 && $n1_vl == 0 && $n3_vl eq "vdd"){
          open(WRITE,">$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq ""); 
          print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne ""); 
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE ".param v0=vss\n";
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*1.8'\n";
          print WRITE ".param t4='inputslew*10/6*2.0'\n";
          print WRITE ".param t5='inputslew*10/6*3.0'\n";
          print WRITE ".param t6='inputslew*10/6*3.2'\n";
          print WRITE ".param t7='inputslew*10/6*3.8'\n";
          print WRITE ".param t8='inputslew*10/6*4.0'\n";
          print WRITE ".param t9='inputslew*10/6*5.0'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n";
          print WRITE ".nodeset v(n3)=vdd\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0   vss\n";
          print WRITE "\n";
          print WRITE "vrs vrs 0   vss\n";
          print WRITE "\n";
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t0   v0\n"; 
          print WRITE "+               t1   v1\n";
          print WRITE "+               t2   v2\n";
          print WRITE "+               t3   v3\n";
          print WRITE "+               t4   v4\n";
          print WRITE "+               t5   v5\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v0\n"; 
          print WRITE "+               t1   v0\n";
          print WRITE "+               t2   v0\n";
          print WRITE "+               t3   v0\n";
          print WRITE "+               t4   v0\n";
          print WRITE "+               t5   v0\n";
          print WRITE "+             )\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE "*.meas tran n1_first_fall when v(n1)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n3_first_fall when v(n3)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close (WRITE);
          ####################################################################################################################################
          system ("ngspice -b -o $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          #--------------------------------------read log file-------------------------------------------------------------------------------#
          open(READ_LOG,"$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log");
          while(<READ_LOG>){
          chomp();
            if($_ =~ /^n3_first_fall/){my $n3_first_fall = (split(/=\s+/,$_))[1];
              if($n3_first_fall ne ""){$get_clock_val = $ck_value;
                                     $get_n1_value = $n1_vl;
                                     $get_n3_value = $n3_vl;
                                     $get_reset_value = $reset_val;}
            }
          }#while reading log file
          close(READ_LOG);
          #-----------------------------------------------------------------------------------------------------------------------------------#
        }elsif ($ck_value == 0 && $reset_val == 1 && $n1_vl == 0 && $n3_vl eq "vdd"){
          open(WRITE,">$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if ($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if ($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE ".param v0=vss\n"; 
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*1.8'\n";
          print WRITE ".param t4='inputslew*10/6*2.0'\n";
          print WRITE ".param t5='inputslew*10/6*3.0'\n";
          print WRITE ".param t6='inputslew*10/6*3.2'\n";
          print WRITE ".param t7='inputslew*10/6*3.8'\n";
          print WRITE ".param t8='inputslew*10/6*4.0'\n";
          print WRITE ".param t9='inputslew*10/6*5.0'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n";
          print WRITE ".nodeset v(n3)=vdd\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0   vss\n"; 
          print WRITE "\n";
          print WRITE "vrs vrs 0   vdd\n";
          print WRITE "\n"; 
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t0   v5\n"; 
          print WRITE "+               t1   v4\n";
          print WRITE "+               t2   v3\n";
          print WRITE "+               t3   v2\n";
          print WRITE "+               t4   v1\n";
          print WRITE "+               t5   v0\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v0\n"; 
          print WRITE "+               t1   v0\n";
          print WRITE "+               t2   v0\n";
          print WRITE "+               t3   v0\n";
          print WRITE "+               t4   v0\n";
          print WRITE "+               t5   v0\n";
          print WRITE "+             )\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE "*.meas tran n1_first_fall when v(n1)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n3_first_fall when v(n3)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close (WRITE);
          ####################################################################################################################################
          system("ngspice -b -o $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          #-------------------------------------read log file--------------------------------------------------------------------------------#
          open(READ_LOG,"$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log");
          while(<READ_LOG>){
          chomp();
            if($_ =~ /^n3_first_fall/){my $n3_first_fall = (split(/=\s+/,$_))[1];
              if($n3_first_fall ne ""){$get_clock_val = $ck_value;
                                       $get_n1_value = $n1_vl;
                                       $get_n3_value = $n3_vl;
                                       $get_reset_value = $reset_val;}
            }
          }#while reading log file
          close(READ_LOG);
          #------------------------------------------------------------------------------------------------------------------------------------#
        }elsif ($ck_value == 1 && $reset_val == 1 && $n1_vl == 0 && $n3_vl eq "vdd"){
          open(WRITE,">$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE ".param v0=vss\n"; 
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*1.8'\n";
          print WRITE ".param t4='inputslew*10/6*2.0'\n";
          print WRITE ".param t5='inputslew*10/6*3.0'\n";
          print WRITE ".param t6='inputslew*10/6*3.2'\n";
          print WRITE ".param t7='inputslew*10/6*3.8'\n";
          print WRITE ".param t8='inputslew*10/6*4.0'\n";
          print WRITE ".param t9='inputslew*10/6*5.0'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n";
          print WRITE ".nodeset v(n3)=vdd\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0   vss\n";
          print WRITE "\n";
          print WRITE "vrs vrs 0   vdd\n";
          print WRITE "\n";
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t0   v0\n"; 
          print WRITE "+               t1   v1\n";
          print WRITE "+               t2   v2\n";
          print WRITE "+               t3   v3\n";
          print WRITE "+               t4   v4\n";
          print WRITE "+               t5   v5\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v0\n"; 
          print WRITE "+               t1   v0\n";
          print WRITE "+               t2   v0\n";
          print WRITE "+               t3   v0\n";
          print WRITE "+               t4   v0\n";
          print WRITE "+               t5   v0\n";
          print WRITE "+             )\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE "*.meas tran n1_first_fall when v(n1)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n3_first_fall when v(n3)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close (WRITE);
          #############################################################################################################################
          system("ngspice -b -o $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl"); 
          #-------------------------------------read log file-------------------------------------------------------------------------#
          open(READ_LOG,"$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log");
          while(<READ_LOG>){
          chomp();
            if($_ =~ /^n3_first_fall/){my $n3_first_fall = (split(/=\s+/,$_))[1];
              if($n3_first_fall ne ""){$get_clock_val = $ck_value;
                                     $get_n1_value = $n1_vl;
                                     $get_n3_value = $n3_vl;
                                     $get_reset_value = $reset_val;}
            }
          }#while reading log file
          close(READ_LOG);
          #---------------------------------------------------------------------------------------------------------------------------#
        }elsif($ck_value == 0 && $reset_val == 0 && $n1_vl == 0 && $n3_vl eq "vss"){
          open(WRITE,">$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE ".param v0=vss\n"; 
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*1.8'\n";
          print WRITE ".param t4='inputslew*10/6*2.0'\n";
          print WRITE ".param t5='inputslew*10/6*3.0'\n";
          print WRITE ".param t6='inputslew*10/6*3.2'\n";
          print WRITE ".param t7='inputslew*10/6*3.8'\n";
          print WRITE ".param t8='inputslew*10/6*4.0'\n";
          print WRITE ".param t9='inputslew*10/6*5.0'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n";
          print WRITE ".nodeset v(n3)=vss\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0   vss\n";
          print WRITE "\n";
          print WRITE "vrs vrs 0   vss\n";
          print WRITE "\n"; 
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t0   v5\n"; 
          print WRITE "+               t1   v4\n";
          print WRITE "+               t2   v3\n";
          print WRITE "+               t3   v2\n";
          print WRITE "+               t4   v1\n";
          print WRITE "+               t5   v0\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v0\n"; 
          print WRITE "+               t1   v0\n";
          print WRITE "+               t2   v0\n";
          print WRITE "+               t3   v0\n";
          print WRITE "+               t4   v0\n";
          print WRITE "+               t5   v0\n";
          print WRITE "+             )\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE "*.meas tran n1_first_rise when v(n1)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n3_first_rise when v(n3)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close (WRITE);
          ########################################################################################################################################
          system("ngspice -b -o $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          #-------------------------------------read log file------------------------------------------------------------------------------------# 
          open(READ_LOG,"$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log");
          while(<READ_LOG>){
          chomp();
            if($_ =~ /^n3_first_rise/){my $n3_first_rise = (split(/=\s+/,$_))[1];
              if($n3_first_rise ne ""){$get_clock_val = $ck_value;
                                       $get_n1_value = $n1_vl;
                                       $get_n3_value = $n3_vl;
                                       $get_reset_value = $reset_val;}
            }
          }#while reading log file
          close(READ_LOG);
          #--------------------------------------------------------------------------------------------------------------------------------------#
        }elsif($ck_value == 1 && $reset_val == 0 && $n1_vl == 0 && $n3_vl eq "vss"){
          open(WRITE,">$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE ".param v0=vss\n"; 
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*1.8'\n";
          print WRITE ".param t4='inputslew*10/6*2.0'\n";
          print WRITE ".param t5='inputslew*10/6*3.0'\n";
          print WRITE ".param t6='inputslew*10/6*3.2'\n";
          print WRITE ".param t7='inputslew*10/6*3.8'\n";
          print WRITE ".param t8='inputslew*10/6*4.0'\n";
          print WRITE ".param t9='inputslew*10/6*5.0'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n";
          print WRITE ".nodeset v(n3)=vss\n"; 
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0   vss\n";
          print WRITE "\n";
          print WRITE "vrs vrs 0   vss\n";
          print WRITE "\n"; 
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t0   v0\n"; 
          print WRITE "+               t1   v1\n";
          print WRITE "+               t2   v2\n";
          print WRITE "+               t3   v3\n";
          print WRITE "+               t4   v4\n";
          print WRITE "+               t5   v5\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v0\n"; 
          print WRITE "+               t1   v0\n";
          print WRITE "+               t2   v0\n";
          print WRITE "+               t3   v0\n";
          print WRITE "+               t4   v0\n";
          print WRITE "+               t5   v0\n";
          print WRITE "+             )\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE "*.meas tran n1_first_rise when v(n1)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n3_first_rise when v(n3)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close (WRITE);
          ####################################################################################################################################
          system("ngspice -b -o $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl"); 
          #-------------------------------------read log file--------------------------------------------------------------------------------#
          open(READ_LOG,"$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log");
          while(<READ_LOG>){
          chomp();
            if($_ =~ /^n3_first_rise/){my $n3_first_rise = (split(/=\s+/,$_))[1];
              if($n3_first_rise ne ""){$get_clock_val = $ck_value;
                                       $get_n1_value = $n1_vl;
                                       $get_n3_value = $n3_vl;
                                       $get_reset_value = $reset_val;}
            }
          }#while reading log file
          close(READ_LOG);
          #-----------------------------------------------------------------------------------------------------------------------------------#
        }elsif($ck_value == 0 && $reset_val == 1 && $n1_vl == 0 && $n3_vl eq "vss"){
          open(WRITE,">$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE ".param v0=vss\n"; 
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*1.8'\n";
          print WRITE ".param t4='inputslew*10/6*2.0'\n";
          print WRITE ".param t5='inputslew*10/6*3.0'\n";
          print WRITE ".param t6='inputslew*10/6*3.2'\n";
          print WRITE ".param t7='inputslew*10/6*3.8'\n";
          print WRITE ".param t8='inputslew*10/6*4.0'\n";
          print WRITE ".param t9='inputslew*10/6*5.0'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n";
          print WRITE ".nodeset v(n3)=vss\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0   vss\n";
          print WRITE "\n";
          print WRITE "vrs vrs 0   vdd\n";
          print WRITE "\n"; 
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t0   v5\n"; 
          print WRITE "+               t1   v4\n";
          print WRITE "+               t2   v3\n";
          print WRITE "+               t3   v2\n";
          print WRITE "+               t4   v1\n";
          print WRITE "+               t5   v0\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v0\n"; 
          print WRITE "+               t1   v0\n";
          print WRITE "+               t2   v0\n";
          print WRITE "+               t3   v0\n";
          print WRITE "+               t4   v0\n";
          print WRITE "+               t5   v0\n";
          print WRITE "+             )\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE "*.meas tran n1_first_rise when v(n1)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n3_first_rise when v(n3)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close (WRITE);
          ####################################################################################################################################
          system("ngspice -b -o $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl"); 
          #-------------------------------------read log file--------------------------------------------------------------------------------#
          open(READ_LOG,"$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log");
          while(<READ_LOG>){
          chomp();
            if($_ =~ /^n3_first_rise/){my $n3_first_rise = (split(/=\s+/,$_))[1];
              if($n3_first_rise ne ""){$get_clock_val = $ck_value;
                                       $get_n1_value = $n1_vl;
                                       $get_n3_value = $n3_vl;
                                       $get_reset_value = $reset_val;}
            }
          }#while reading log file
          close(READ_LOG);
          #-----------------------------------------------------------------------------------------------------------------------------------#
        }elsif($ck_value == 1 && $reset_val == 1 && $n1_vl == 0 && $n3_vl eq "vss"){
          open(WRITE,">$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE ".param v0=vss\n"; 
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*1.8'\n";
          print WRITE ".param t4='inputslew*10/6*2.0'\n";
          print WRITE ".param t5='inputslew*10/6*3.0'\n";
          print WRITE ".param t6='inputslew*10/6*3.2'\n";
          print WRITE ".param t7='inputslew*10/6*3.8'\n";
          print WRITE ".param t8='inputslew*10/6*4.0'\n";
          print WRITE ".param t9='inputslew*10/6*5.0'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n";
          print WRITE ".nodeset v(n3)=vss\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0   vss\n";
          print WRITE "\n";
          print WRITE "vrs vrs 0   vdd\n";
          print WRITE "\n"; 
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t0   v0\n"; 
          print WRITE "+               t1   v1\n";
          print WRITE "+               t2   v2\n";
          print WRITE "+               t3   v3\n";
          print WRITE "+               t4   v4\n";
          print WRITE "+               t5   v5\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v0\n"; 
          print WRITE "+               t1   v0\n";
          print WRITE "+               t2   v0\n";
          print WRITE "+               t3   v0\n";
          print WRITE "+               t4   v0\n";
          print WRITE "+               t5   v0\n";
          print WRITE "+             )\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE "*.meas tran n1_first_rise when v(n1)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n3_first_rise when v(n3)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close (WRITE);
          ######################################################################################################################################
          system ("ngspice -b -o $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          #--------------------------------------read log file---------------------------------------------------------------------------------# 
          open(READ_LOG,"$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log");
          while(<READ_LOG>){
          chomp();
            if($_ =~ /^n3_first_rise/){my $n3_first_rise = (split(/=\s+/,$_))[1];
              if($n3_first_rise ne ""){$get_clock_val = $ck_value;
                                       $get_n1_value = $n1_vl;
                                       $get_n3_value = $n3_vl;
                                       $get_reset_value = $reset_val;}
            }
          }#while reading log file
          close(READ_LOG);
          #-------------------------------------------------------------------------------------------------------------------------------------#
        }elsif($ck_value == 0 && $reset_val == 0 && $n1_vl == 1 && $n3_vl eq "vdd"){
          open(WRITE,">$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE ".param v0=vss\n"; 
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*1.8'\n";
          print WRITE ".param t4='inputslew*10/6*2.0'\n";
          print WRITE ".param t5='inputslew*10/6*3.0'\n";
          print WRITE ".param t6='inputslew*10/6*3.2'\n";
          print WRITE ".param t7='inputslew*10/6*3.8'\n";
          print WRITE ".param t8='inputslew*10/6*4.0'\n";
          print WRITE ".param t9='inputslew*10/6*5.0'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n";
          print WRITE ".nodeset v(n3)=vdd\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0   vss\n";
          print WRITE "\n";
          print WRITE "vrs vrs 0   vss\n";
          print WRITE "\n";
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t0   v5\n"; 
          print WRITE "+               t1   v4\n";
          print WRITE "+               t2   v3\n";
          print WRITE "+               t3   v2\n";
          print WRITE "+               t4   v1\n";
          print WRITE "+               t5   v0\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v5\n"; 
          print WRITE "+               t1   v5\n";
          print WRITE "+               t2   v5\n";
          print WRITE "+               t3   v5\n";
          print WRITE "+               t4   v5\n";
          print WRITE "+               t5   v5\n";
          print WRITE "+             )\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE "*.meas tran n1_first_fall when v(n1)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n3_first_fall when v(n3)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close(WRITE);
          ############################################################################################################################################################
          system("ngspice -b -o $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          #-------------------------------------------------------read log file--------------------------------------------------------------------------------------# 
          open(READ_LOG,"$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log");
          while(<READ_LOG>){
          chomp(); 
            if($_ =~ /^n3_first_fall/){my $n3_first_fall = (split(/=\s+/,$_))[1];
              if($n3_first_fall ne ""){$get_clock_val = $ck_value;
                                       $get_n1_value = $n1_vl;
                                       $get_n3_value = $n3_vl;
                                       $get_reset_value = $reset_val;}
              } 
          }#while reading log file
          close(READ_LOG);
          #-----------------------------------------------------------------------------------------------------------------------------------------------------------#
        }elsif($ck_value == 1 && $reset_val == 0 && $n1_vl == 1 && $n3_vl eq "vdd"){
          open(WRITE,">$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if ($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if ($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE ".param v0=vss\n"; 
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*1.8'\n";
          print WRITE ".param t4='inputslew*10/6*2.0'\n";
          print WRITE ".param t5='inputslew*10/6*3.0'\n";
          print WRITE ".param t6='inputslew*10/6*3.2'\n";
          print WRITE ".param t7='inputslew*10/6*3.8'\n";
          print WRITE ".param t8='inputslew*10/6*4.0'\n";
          print WRITE ".param t9='inputslew*10/6*5.0'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n";
          print WRITE ".nodeset v(n3)=vdd\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0   vss\n";
          print WRITE "\n";
          print WRITE "vrs vrs 0   vss\n";
          print WRITE "\n";
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t0   v0\n"; 
          print WRITE "+               t1   v1\n";
          print WRITE "+               t2   v2\n";
          print WRITE "+               t3   v3\n";
          print WRITE "+               t4   v4\n";
          print WRITE "+               t5   v5\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v5\n"; 
          print WRITE "+               t1   v5\n";
          print WRITE "+               t2   v5\n";
          print WRITE "+               t3   v5\n";
          print WRITE "+               t4   v5\n";
          print WRITE "+               t5   v5\n";
          print WRITE "+             )\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE "*.meas tran n1_first_fall when v(n1)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n3_first_fall when v(n3)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close(WRITE);
          ###################################################################################################################################################
          system("ngspice -b -o $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          #--------------------------------------------------------------read log file----------------------------------------------------------------------# 
          open(READ_LOG,"$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log");
          while(<READ_LOG>){
          chomp();
            if($_ =~ /^n3_first_fall/){my $n3_first_fall = (split(/=\s+/,$_))[1];
              if($n3_first_fall ne ""){$get_clock_val = $ck_value;
                                       $get_n1_value = $n1_vl;
                                       $get_n3_value = $n3_vl;
                                       $get_reset_value = $reset_val;}
               }
          }#while reading log file
          close(READ_LOG);
          #-------------------------------------------------------------------------------------------------------------------------------------------------#
        }elsif($ck_value == 0 && $reset_val == 1 && $n1_vl == 1 && $n3_vl eq "vdd"){
          open(WRITE,">$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE ".param v0=vss\n"; 
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*1.8'\n";
          print WRITE ".param t4='inputslew*10/6*2.0'\n";
          print WRITE ".param t5='inputslew*10/6*3.0'\n";
          print WRITE ".param t6='inputslew*10/6*3.2'\n";
          print WRITE ".param t7='inputslew*10/6*3.8'\n";
          print WRITE ".param t8='inputslew*10/6*4.0'\n";
          print WRITE ".param t9='inputslew*10/6*5.0'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n";
          print WRITE ".nodeset v(n3)=vdd\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0   vss\n";
          print WRITE "\n";
          print WRITE "vrs vrs 0   vdd\n";
          print WRITE "\n";
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t0   v5\n"; 
          print WRITE "+               t1   v4\n";
          print WRITE "+               t2   v3\n";
          print WRITE "+               t3   v2\n";
          print WRITE "+               t4   v1\n";
          print WRITE "+               t5   v0\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v5\n"; 
          print WRITE "+               t1   v5\n";
          print WRITE "+               t2   v5\n";
          print WRITE "+               t3   v5\n";
          print WRITE "+               t4   v5\n";
          print WRITE "+               t5   v5\n";
          print WRITE "+             )\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE "*.meas tran n1_first_fall when v(n1)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n3_first_fall when v(n3)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close(WRITE);
          ########################################################################################################################################
          system("ngspice -b -o $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          #---------------------------------------------------------read log file----------------------------------------------------------------# 
          open(READ_LOG,"$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log");
          while(<READ_LOG>){
          chomp();
            if($_ =~ /^n3_first_fall/){my $n3_first_fall = (split(/=\s+/,$_))[1];
              if($n3_first_fall ne ""){$get_clock_val = $ck_value;
                                       $get_n1_value = $n1_vl;
                                       $get_n3_value = $n3_vl;
                                       $get_reset_value = $reset_val;}
              } 
          }#while reading log file
          close(READ_LOG);
          #---------------------------------------------------------------------------------------------------------------------------------------#
        }elsif($ck_value == 1 && $reset_val == 1 && $n1_vl == 1 && $n3_vl eq "vdd"){
          open(WRITE,">$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE ".param v0=vss\n"; 
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*1.8'\n";
          print WRITE ".param t4='inputslew*10/6*2.0'\n";
          print WRITE ".param t5='inputslew*10/6*3.0'\n";
          print WRITE ".param t6='inputslew*10/6*3.2'\n";
          print WRITE ".param t7='inputslew*10/6*3.8'\n";
          print WRITE ".param t8='inputslew*10/6*4.0'\n";
          print WRITE ".param t9='inputslew*10/6*5.0'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n";
          print WRITE ".nodeset v(n3)=vdd\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0   vss\n";
          print WRITE "\n";
          print WRITE "vrs vrs 0   vdd\n";
          print WRITE "\n";
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t0   v0\n"; 
          print WRITE "+               t1   v1\n";
          print WRITE "+               t2   v2\n";
          print WRITE "+               t3   v3\n";
          print WRITE "+               t4   v4\n";
          print WRITE "+               t5   v5\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v5\n"; 
          print WRITE "+               t1   v5\n";
          print WRITE "+               t2   v5\n";
          print WRITE "+               t3   v5\n";
          print WRITE "+               t4   v5\n";
          print WRITE "+               t5   v5\n";
          print WRITE "+             )\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE "*.meas tran n1_first_fall when v(n1)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n3_first_fall when v(n3)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close(WRITE);
          ##########################################################################################################################################
          system("ngspice -b -o $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          #---------------------------------------------------------read log file------------------------------------------------------------------# 
          open(READ_LOG,"$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log");
          while(<READ_LOG>){
          chomp();
            if($_ =~ /^n3_first_fall/){my $n3_first_fall = (split(/=\s+/,$_))[1];
              if($n3_first_fall ne ""){$get_clock_val = $ck_value;
                                       $get_n1_value = $n1_vl;
                                       $get_n3_value = $n3_vl;
                                       $get_reset_value = $reset_val;}
              }
          }#while reading log file
          close(READ_LOG);
          #---------------------------------------------------------------------------------------------------------------------------------------#
        }elsif($ck_value == 0 && $reset_val == 0 && $n1_vl == 1 && $n3_vl eq "vss"){
          open(WRITE,">$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if ($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if ($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE ".param v0=vss\n"; 
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*1.8'\n";
          print WRITE ".param t4='inputslew*10/6*2.0'\n";
          print WRITE ".param t5='inputslew*10/6*3.0'\n";
          print WRITE ".param t6='inputslew*10/6*3.2'\n";
          print WRITE ".param t7='inputslew*10/6*3.8'\n";
          print WRITE ".param t8='inputslew*10/6*4.0'\n";
          print WRITE ".param t9='inputslew*10/6*5.0'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n";
          print WRITE ".nodeset v(n3)=vss\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0   vss\n";
          print WRITE "\n";
          print WRITE "vrs vrs 0   vss\n";
          print WRITE "\n";
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t0   v5\n"; 
          print WRITE "+               t1   v4\n";
          print WRITE "+               t2   v3\n";
          print WRITE "+               t3   v2\n";
          print WRITE "+               t4   v1\n";
          print WRITE "+               t5   v0\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v5\n"; 
          print WRITE "+               t1   v5\n";
          print WRITE "+               t2   v5\n";
          print WRITE "+               t3   v5\n";
          print WRITE "+               t4   v5\n";
          print WRITE "+               t5   v5\n";
          print WRITE "+             )\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE "*.meas tran n1_first_rise when v(n1)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n3_first_rise when v(n3)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close(WRITE);
          ####################################################################################################################################
          system("ngspice -b -o $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl"); 
          #---------------------------------------------------------read log file------------------------------------------------------------#
          open(READ_LOG,"$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log");
          while(<READ_LOG>){
          chomp();
            if($_ =~ /^n3_first_rise/){my $n3_first_rise = (split(/=\s+/,$_))[1];
              if($n3_first_rise ne ""){$get_clock_val = $ck_value;
                                       $get_n1_value = $n1_vl;
                                       $get_n3_value = $n3_vl;
                                       $get_reset_value = $reset_val;}
              } 
          }#while reading log file 
          close(READ_LOG);
          #----------------------------------------------------------------------------------------------------------------------------------#
        }elsif($ck_value == 1 && $reset_val == 0 && $n1_vl == 1 && $n3_vl eq "vss"){
          open(WRITE,">$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if ($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if ($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE ".param v0=vss\n"; 
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*1.8'\n";
          print WRITE ".param t4='inputslew*10/6*2.0'\n";
          print WRITE ".param t5='inputslew*10/6*3.0'\n";
          print WRITE ".param t6='inputslew*10/6*3.2'\n";
          print WRITE ".param t7='inputslew*10/6*3.8'\n";
          print WRITE ".param t8='inputslew*10/6*4.0'\n";
          print WRITE ".param t9='inputslew*10/6*5.0'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n";
          print WRITE ".nodeset v(n3)=vss\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0   vss\n";
          print WRITE "\n";
          print WRITE "vrs vrs 0   vss\n";
          print WRITE "\n";
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t0   v0\n"; 
          print WRITE "+               t1   v1\n";
          print WRITE "+               t2   v2\n";
          print WRITE "+               t3   v3\n";
          print WRITE "+               t4   v4\n";
          print WRITE "+               t5   v5\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v5\n"; 
          print WRITE "+               t1   v5\n";
          print WRITE "+               t2   v5\n";
          print WRITE "+               t3   v5\n";
          print WRITE "+               t4   v5\n";
          print WRITE "+               t5   v5\n";
          print WRITE "+             )\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE "*.meas tran n1_first_rise when v(n1)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n3_first_rise when v(n3)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close(WRITE);
          #############################################################################################################################
          system("ngspice -b -o $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          #---------------------------------------------------------read log file-----------------------------------------------------# 
          open(READ_LOG,"$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          while(<READ_LOG>){
          chomp();
            if($_ =~ /^n3_first_rise/){my $n3_first_rise = (split(/=\s+/,$_))[1];
              if($n3_first_rise ne ""){$get_clock_val = $ck_value;
                                       $get_n1_value = $n1_vl;
                                       $get_n3_value = $n3_vl;
                                       $get_reset_value = $reset_val;}
              } 
          }#while reading log file
          close(READ_LOG);
          #---------------------------------------------------------------------------------------------------------------------------#
        }elsif($ck_value == 0 && $reset_val == 1 && $n1_vl == 1 && $n3_vl eq "vss"){
          open(WRITE,">$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if ($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if ($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE ".param v0=vss\n"; 
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*1.8'\n";
          print WRITE ".param t4='inputslew*10/6*2.0'\n";
          print WRITE ".param t5='inputslew*10/6*3.0'\n";
          print WRITE ".param t6='inputslew*10/6*3.2'\n";
          print WRITE ".param t7='inputslew*10/6*3.8'\n";
          print WRITE ".param t8='inputslew*10/6*4.0'\n";
          print WRITE ".param t9='inputslew*10/6*5.0'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n";
          print WRITE ".nodeset v(n3)=vss\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0   vss\n";
          print WRITE "\n";
          print WRITE "vrs vrs 0   vdd\n";
          print WRITE "\n";
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t0   v5\n"; 
          print WRITE "+               t1   v4\n";
          print WRITE "+               t2   v3\n";
          print WRITE "+               t3   v2\n";
          print WRITE "+               t4   v1\n";
          print WRITE "+               t5   v0\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v5\n"; 
          print WRITE "+               t1   v5\n";
          print WRITE "+               t2   v5\n";
          print WRITE "+               t3   v5\n";
          print WRITE "+               t4   v5\n";
          print WRITE "+               t5   v5\n";
          print WRITE "+             )\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE "*.meas tran n1_first_rise when v(n1)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n3_first_rise when v(n3)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close(WRITE);
          #######################################################################################################################################
          system("ngspice -b -o $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          #--------------------------------------------------------------read log file----------------------------------------------------------# 
          open(READ_LOG,"$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log");
          while(<READ_LOG>){
          chomp();
            if($_ =~ /^n3_first_rise/){my $n3_first_rise = (split(/=\s+/,$_))[1];
              if($n3_first_rise ne ""){$get_clock_val = $ck_value;
                                       $get_n1_value = $n1_vl;
                                       $get_n3_value = $n3_vl;
                                       $get_reset_value = $reset_val;}
              } 
          }#while reading log file
          close(READ_LOG);
          #-------------------------------------------------------------------------------------------------------------------------------------#
        }elsif($ck_value == 1 && $reset_val == 1 && $n1_vl == 1 && $n3_vl eq "vss"){
          open(WRITE,">$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if ($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if ($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE ".param v0=vss\n"; 
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*1.8'\n";
          print WRITE ".param t4='inputslew*10/6*2.0'\n";
          print WRITE ".param t5='inputslew*10/6*3.0'\n";
          print WRITE ".param t6='inputslew*10/6*3.2'\n";
          print WRITE ".param t7='inputslew*10/6*3.8'\n";
          print WRITE ".param t8='inputslew*10/6*4.0'\n";
          print WRITE ".param t9='inputslew*10/6*5.0'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n";
          print WRITE ".nodeset v(n3)=vss\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0   vss\n";
          print WRITE "\n";
          print WRITE "vrs vrs 0   vdd\n";
          print WRITE "\n";
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t0   v0\n"; 
          print WRITE "+               t1   v1\n";
          print WRITE "+               t2   v2\n";
          print WRITE "+               t3   v3\n";
          print WRITE "+               t4   v4\n";
          print WRITE "+               t5   v5\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v5\n"; 
          print WRITE "+               t1   v5\n";
          print WRITE "+               t2   v5\n";
          print WRITE "+               t3   v5\n";
          print WRITE "+               t4   v5\n";
          print WRITE "+               t5   v5\n";
          print WRITE "+             )\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE "*.meas tran n1_first_rise when v(n1)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n3_first_rise when v(n3)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close(WRITE);
          #############################################################################################################################
          system("ngspice -b -o $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          #--------------------------------------------------------------read log file------------------------------------------------#
          open(READ_LOG,"$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log");
          while(<READ_LOG>){
          chomp();
            if($_ =~ /^n3_first_rise/){my $n3_first_rise = (split(/=\s+/,$_))[1];
              if($n3_first_rise ne ""){$get_clock_val = $ck_value;
                                       $get_n1_value = $n1_vl;
                                       $get_n3_value = $n3_vl;
                                       $get_reset_value = $reset_val;}
            }
          }#while reading log file
          close(READ_LOG);
          #----------------------------------------------------------------------------------------------------------------------------#
        }
      }#for
    }#for clock_val when reset exists
  }#for n3 value when reset exists
}#for vol when reset exists
}else{
  my $get_clk_val = "";
  my $get_n1_val = ""; 
  my $get_n2_val = ""; 
  my $get_n3_val = "";
  for(my $n=0;$n<=$#n1_value;$n++){
    for (my $v=0;$v<=$#n3_value;$v++){
      for(my $l=0;$l<=$#clk_value;$l++){
        my $clkval = $clk_value[$l];
        my $n3_val = $n3_value[$v];
        my $n1_val = $n1_value[$n];
        if($clkval == 0 && $n1_val == 0 && $n3_val eq "vdd"){
          open(WRITE,">$file-$clk-$clkval-n1_$n1_val-n3_$n3_val");
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE ".param v0=vss\n"; 
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*1.8'\n";
          print WRITE ".param t4='inputslew*10/6*2.0'\n";
          print WRITE ".param t5='inputslew*10/6*3.0'\n";
          print WRITE ".param t6='inputslew*10/6*3.2'\n";
          print WRITE ".param t7='inputslew*10/6*3.8'\n";
          print WRITE ".param t8='inputslew*10/6*4.0'\n";
          print WRITE ".param t9='inputslew*10/6*5.0'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n";
          print WRITE ".nodeset v(n3)=vdd\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0   vss\n";
          print WRITE "\n";
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t0   v5\n"; 
          print WRITE "+               t1   v4\n";
          print WRITE "+               t2   v3\n";
          print WRITE "+               t3   v2\n";
          print WRITE "+               t4   v1\n";
          print WRITE "+               t5   v0\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v0\n"; 
          print WRITE "+               t1   v0\n";
          print WRITE "+               t2   v0\n";
          print WRITE "+               t3   v0\n";
          print WRITE "+               t4   v0\n";
          print WRITE "+               t5   v0\n";
          print WRITE "+             )\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE "*.meas tran n1_first_fall when v(n1)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n3_first_fall when v(n3)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close(WRITE);
          ##########################################################################################
          system("ngspice -b -o $file-$clk-$clkval-n1_$n1_val-n3_$n3_val.log $file-$clk-$clkval-n1_$n1_val-n3_$n3_val"); 
          #-------------------------------------------- read log file------------------------------#
          open (READ_LOG,"$file-$clk-$clkval-n1_$n1_val-n3_$n3_val.log");
          while(<READ_LOG>){
          chomp();
            if($_ =~ /^n3_first_fall/){my $n3_first_fall = (split(/=\s+/,$_))[1];
              if($n3_first_fall ne ""){$get_clk_val = $clkval;
                                       $get_n1_val = $n1_val;
                                       $get_n3_val = $n3_val;}
            }
          }
          close(READ_LOG);
          #---------------------------------------------------------------------------------------#
        }elsif($clkval == 1 && $n1_val == 0 && $n3_val eq "vdd"){
          open(WRITE,">$file-$clk-$clkval-n1_$n1_val-n3_$n3_val"); 
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE ".param v0=vss\n";
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n"; 
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*1.8'\n";
          print WRITE ".param t4='inputslew*10/6*2.0'\n";
          print WRITE ".param t5='inputslew*10/6*3.0'\n";
          print WRITE ".param t6='inputslew*10/6*3.2'\n";
          print WRITE ".param t7='inputslew*10/6*3.8'\n";
          print WRITE ".param t8='inputslew*10/6*4.0'\n";
          print WRITE ".param t9='inputslew*10/6*5.0'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n";
          print WRITE ".nodeset v(n3)=vdd\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0   vss\n";
          print WRITE "\n";
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t0   v0\n"; 
          print WRITE "+               t1   v1\n";
          print WRITE "+               t2   v2\n";
          print WRITE "+               t3   v3\n";
          print WRITE "+               t4   v4\n";
          print WRITE "+               t5   v5\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v0\n"; 
          print WRITE "+               t1   v0\n";
          print WRITE "+               t2   v0\n";
          print WRITE "+               t3   v0\n";
          print WRITE "+               t4   v0\n";
          print WRITE "+               t5   v0\n";
          print WRITE "+             )\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE "*.meas tran n1_first_fall when v(n1)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n3_first_fall when v(n3)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close(WRITE);
          ############################################################################################
          system("ngspice -b -o $file-$clk-$clkval-n1_$n1_val-n3_$n3_val.log $file-$clk-$clkval-n1_$n1_val-n3_$n3_val");
          #---------------------------------------------------read log file--------------------------#
          open (READ_LOG,"$file-$clk-$clkval-n1_$n1_val-n3_$n3_val.log"); 
          while(<READ_LOG>){
          chomp();
            if($_ =~ /^n3_first_fall/){my $n3_first_fall = (split(/=\s+/,$_))[1];
              if($n3_first_fall ne ""){$get_clk_val = $clkval;
                                       $get_n1_val = $n1_val;
                                       $get_n3_val = $n3_val;}
            }
          }
          close(READ_LOG);
          #------------------------------------------------------------------------------------------#      
        }elsif($clkval == 0 && $n1_val == 0 && $n3_val eq "vss"){
          open(WRITE,">$file-$clk-$clkval-n1_$n1_val-n3_$n3_val");
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE ".param v0=vss\n"; 
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*1.8'\n";
          print WRITE ".param t4='inputslew*10/6*2.0'\n";
          print WRITE ".param t5='inputslew*10/6*3.0'\n";
          print WRITE ".param t6='inputslew*10/6*3.2'\n";
          print WRITE ".param t7='inputslew*10/6*3.8'\n";
          print WRITE ".param t8='inputslew*10/6*4.0'\n";
          print WRITE ".param t9='inputslew*10/6*5.0'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n";
          print WRITE ".nodeset v(n3)=vss\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0   vss\n";
          print WRITE "\n";
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t0   v5\n"; 
          print WRITE "+               t1   v4\n";
          print WRITE "+               t2   v3\n";
          print WRITE "+               t3   v2\n";
          print WRITE "+               t4   v1\n";
          print WRITE "+               t5   v0\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v0\n"; 
          print WRITE "+               t1   v0\n";
          print WRITE "+               t2   v0\n";
          print WRITE "+               t3   v0\n";
          print WRITE "+               t4   v0\n";
          print WRITE "+               t5   v0\n";
          print WRITE "+             )\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE "*.meas tran n1_first_rise when v(n1)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n3_first_rise when v(n3)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close(WRITE);
          ##############################################################################################
          system("ngspice -b -o $file-$clk-$clkval-n1_$n1_val-n3_$n3_val.log $file-$clk-$clkval-n1_$n1_val-n3_$n3_val");
          #-----------------------------------------------read log file--------------------------------# 
          open (READ_LOG,"$file-$clk-$clkval-n1_$n1_val-n3_$n3_val.log");
          while(<READ_LOG>){
          chomp();
            if($_ =~ /^n3_first_rise/){my $n3_first_rise = (split(/=\s+/,$_))[1];
              if($n3_first_rise ne ""){$get_clk_val = $clkval;
                                       $get_n1_val = $n1_val;
                                       $get_n3_val = $n3_val;}
            }
          }
          close(READ_LOG);
          #--------------------------------------------------------------------------------------------# 
        }elsif($clkval == 1 && $n1_val == 0 && $n3_val eq "vss"){
          open(WRITE,">$file-$clk-$clkval-n1_$n1_val-n3_$n3_val");
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE ".param v0=vss\n"; 
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n";  
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*1.8'\n";
          print WRITE ".param t4='inputslew*10/6*2.0'\n";
          print WRITE ".param t5='inputslew*10/6*3.0'\n";
          print WRITE ".param t6='inputslew*10/6*3.2'\n";
          print WRITE ".param t7='inputslew*10/6*3.8'\n";
          print WRITE ".param t8='inputslew*10/6*4.0'\n";
          print WRITE ".param t9='inputslew*10/6*5.0'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n";
          print WRITE ".nodeset v(n3)=vss\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0   vss\n";
          print WRITE "\n";
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t0   v0\n"; 
          print WRITE "+               t1   v1\n";
          print WRITE "+               t2   v2\n";
          print WRITE "+               t3   v3\n";
          print WRITE "+               t4   v4\n";
          print WRITE "+               t5   v5\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v0\n"; 
          print WRITE "+               t1   v0\n";
          print WRITE "+               t2   v0\n";
          print WRITE "+               t3   v0\n";
          print WRITE "+               t4   v0\n";
          print WRITE "+               t5   v0\n";
          print WRITE "+             )\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE "*.meas tran n1_first_rise when v(n1)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n3_first_rise when v(n3)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close(WRITE);
          ########################################################################################################
          system("ngspice -b -o $file-$clk-$clkval-n1_$n1_val-n3_$n3_val.log $file-$clk-$clkval-n1_$n1_val-n3_$n3_val");
          #-----------------------------------------------------read log file------------------------------------# 
          open (READ_LOG,"$file-$clk-$clkval-n1_$n1_val-n3_$n3_val.log");
          while(<READ_LOG>){
          chomp();
            if($_ =~ /^n3_first_rise/){my $n3_first_rise = (split(/=\s+/,$_))[1];
              if($n3_first_rise ne ""){$get_clk_val = $clkval;
                                       $get_n1_val = $n1_val;
                                       $get_n3_val = $n3_val;}
            }
          }
          close(READ_LOG);
          #---------------------------check the value of clock ---------------------------------------------#
        }elsif($clkval == 0 && $n1_val == 1 && $n3_val eq "vdd"){
          open(WRITE,">$file-$clk-$clkval-n1_$n1_val-n3_$n3_val");
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE ".param v0=vss\n";
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n"; 
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*1.8'\n";
          print WRITE ".param t4='inputslew*10/6*2.0'\n";
          print WRITE ".param t5='inputslew*10/6*3.0'\n";
          print WRITE ".param t6='inputslew*10/6*3.2'\n";
          print WRITE ".param t7='inputslew*10/6*3.8'\n";
          print WRITE ".param t8='inputslew*10/6*4.0'\n";
          print WRITE ".param t9='inputslew*10/6*5.0'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n";
          print WRITE ".nodeset v(n3)=vdd\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0   vss\n";
          print WRITE "\n";
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t0   v5\n"; 
          print WRITE "+               t1   v4\n";
          print WRITE "+               t2   v3\n";
          print WRITE "+               t3   v2\n";
          print WRITE "+               t4   v1\n";
          print WRITE "+               t5   v0\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v5\n"; 
          print WRITE "+               t1   v5\n";
          print WRITE "+               t2   v5\n";
          print WRITE "+               t3   v5\n";
          print WRITE "+               t4   v5\n";
          print WRITE "+               t5   v5\n";
          print WRITE "+             )\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE "*.meas tran n1_first_fall when v(n1)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n3_first_fall when v(n3)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close(WRITE);
          ##############################################################################################
          system("ngspice -b -o $file-$clk-$clkval-n1_$n1_val-n3_$n3_val.log $file-$clk-$clkval-n1_$n1_val-n3_$n3_val");
          #----------------------------------------------read log file---------------------------------# 
          open (READ_LOG,"$file-$clk-$clkval-n1_$n1_val-n3_$n3_val.log");
          while(<READ_LOG>){
          chomp();
            if($_ =~ /^n3_first_fall/){my $n3_first_fall = (split(/=\s+/,$_))[1];
              if($n3_first_fall ne ""){$get_n2_val = $clkval;}
            }
          }
          close(READ_LOG);
         #---------------------------------------------------------------------------------------------#
        }elsif($clkval == 1 && $n1_val == 1 && $n3_val eq "vdd"){
         open(WRITE,">$file-$clk-$clkval-n1_$n1_val-n3_$n3_val");
         print WRITE ".title Fanout Versus Delay (TSMC)\n";
         print WRITE "\n";
         print WRITE ".param vdd=$vdd_pri_val\n";
         print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
         print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
         print WRITE ".param vss=$vss_val\n";
         print WRITE ".param wp=$wp\n";
         print WRITE ".param wn=$wn\n";
         print WRITE ".param vlo='0.2*vdd'\n";
         print WRITE ".param vmid='0.5*vdd'\n";
         print WRITE ".param vhi='0.8*vdd'\n";
         print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
         print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
         print WRITE ".param v0=vss\n"; 
         print WRITE ".param v1=vss\n";
         print WRITE ".param v2=vlo\n";
         print WRITE ".param v3=vhi\n";
         print WRITE ".param v4=vdd\n";
         print WRITE ".param v5=vdd\n";
         print WRITE ".param v6=vhi\n";
         print WRITE ".param v7=vlo\n";
         print WRITE ".param v8=vss\n";
         print WRITE ".param v9=vss\n";
         print WRITE "\n";
         print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
         print WRITE ".param t1='inputslew*10/6*1.0'\n";
         print WRITE ".param t2='inputslew*10/6*1.2'\n";
         print WRITE ".param t3='inputslew*10/6*1.8'\n";
         print WRITE ".param t4='inputslew*10/6*2.0'\n";
         print WRITE ".param t5='inputslew*10/6*3.0'\n";
         print WRITE ".param t6='inputslew*10/6*3.2'\n";
         print WRITE ".param t7='inputslew*10/6*3.8'\n";
         print WRITE ".param t8='inputslew*10/6*4.0'\n";
         print WRITE ".param t9='inputslew*10/6*5.0'\n";
         print WRITE "\n";
         print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n";
         print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
         print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
         print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
         print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
         print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
         print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
         print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
         print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
         print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n"; 
         print WRITE "\n";
         print WRITE ".nodeset v(n3)=vdd\n";
         print WRITE "\n";
         print WRITE "vdd vdd 0 vdd\n";
         print WRITE "vddsec vddsec 0 vddsec\n";
         print WRITE "vss vss 0   vss\n";
         print WRITE "\n";
         print WRITE "vin n2 vss pwl(\n";
         print WRITE "+               t0   v0\n"; 
         print WRITE "+               t1   v1\n";
         print WRITE "+               t2   v2\n";
         print WRITE "+               t3   v3\n";
         print WRITE "+               t4   v4\n";
         print WRITE "+               t5   v5\n";
         print WRITE "+             )\n";
         print WRITE "\n";
         print WRITE "vin0 n1 vss pwl(\n";
         print WRITE "+               t0   v5\n"; 
         print WRITE "+               t1   v5\n";
         print WRITE "+               t2   v5\n";
         print WRITE "+               t3   v5\n";
         print WRITE "+               t4   v5\n";
         print WRITE "+               t5   v5\n";
         print WRITE "+             )\n";
         print WRITE ".MODEL n NMOS\n";
         print WRITE ".MODEL p PMOS\n";
         print WRITE ".MODEL nd NMOS\n";
         print WRITE ".MODEL pd PMOS\n";
         print WRITE "\n";
         print WRITE "\n";
         print WRITE ".include $new_file_spice\n";
         print WRITE "x$cellName @get_new_port_list $cellName\n";
         print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
         print WRITE "C1 $output_port 0 opcap\n";
         print WRITE "\n";
         print WRITE ".temp 85\n";
         print WRITE ".tran 10p 500n\n";
         print WRITE "\n";
         print WRITE "*.meas tran n1_first_fall when v(n1)=vmid fall=1\n";
         print WRITE "\n";
         print WRITE ".meas tran n3_first_fall when v(n3)=vmid fall=1\n";
         print WRITE "\n";
         print WRITE ".end\n";
         close(WRITE);
         ###################################################################################################
         system("ngspice -b -o $file-$clk-$clkval-n1_$n1_val-n3_$n3_val.log $file-$clk-$clkval-n1_$n1_val-n3_$n3_val"); 
         #---------------------------------------------------------read log file---------------------------#
          open (READ_LOG,"$file-$clk-$clkval-n1_$n1_val-n3_$n3_val.log");
          while(<READ_LOG>){
          chomp();
            if($_ =~ /^n3_first_fall/){my $n3_first_fall = (split(/=\s+/,$_))[1];
              if($n3_first_fall ne ""){$get_n2_val = $clkval;}
            }
          }
          close(READ_LOG);
        #-------------------------------------------------------------------------------------------------#      
        }elsif($clkval == 0 && $n1_val == 1 && $n3_val eq "vss"){
          open(WRITE,">$file-$clk-$clkval-n1_$n1_val-n3_$n3_val");
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE ".param v0=vss\n"; 
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*1.8'\n";
          print WRITE ".param t4='inputslew*10/6*2.0'\n";
          print WRITE ".param t5='inputslew*10/6*3.0'\n";
          print WRITE ".param t6='inputslew*10/6*3.2'\n";
          print WRITE ".param t7='inputslew*10/6*3.8'\n";
          print WRITE ".param t8='inputslew*10/6*4.0'\n";
          print WRITE ".param t9='inputslew*10/6*5.0'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n";
          print WRITE ".nodeset v(n3)=vss\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0   vss\n";
          print WRITE "\n";
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t0   v5\n"; 
          print WRITE "+               t1   v4\n";
          print WRITE "+               t2   v3\n";
          print WRITE "+               t3   v2\n";
          print WRITE "+               t4   v1\n";
          print WRITE "+               t5   v0\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v5\n"; 
          print WRITE "+               t1   v5\n";
          print WRITE "+               t2   v5\n";
          print WRITE "+               t3   v5\n";
          print WRITE "+               t4   v5\n";
          print WRITE "+               t5   v5\n";
          print WRITE "+             )\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE "*.meas tran n1_first_rise when v(n1)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n3_first_rise when v(n3)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close(WRITE);
          #########################################################################################################
          system("ngspice -b -o $file-$clk-$clkval-n1_$n1_val-n3_$n3_val.log $file-$clk-$clkval-n1_$n1_val-n3_$n3_val");
          #-------------------------------------------------read log file-----------------------------------------# 
          open (READ_LOG,"$file-$clk-$clkval-n1_$n1_val-n3_$n3_val.log");
          while(<READ_LOG>){
          chomp();
            if($_ =~ /^n3_first_rise/){my $n3_first_rise = (split(/=\s+/,$_))[1];
              if($n3_first_rise ne ""){$get_n2_val = $clkval;}
            }
          }
          close(READ_LOG);
          #-------------------------------------------------------------------------------------------------------# 
        }elsif($clkval == 1 && $n1_val == 1 && $n3_val eq "vss"){
          open(WRITE,">$file-$clk-$clkval-n1_$n1_val-n3_$n3_val");
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE ".param v0=vss\n"; 
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*1.8'\n";
          print WRITE ".param t4='inputslew*10/6*2.0'\n";
          print WRITE ".param t5='inputslew*10/6*3.0'\n";
          print WRITE ".param t6='inputslew*10/6*3.2'\n";
          print WRITE ".param t7='inputslew*10/6*3.8'\n";
          print WRITE ".param t8='inputslew*10/6*4.0'\n";
          print WRITE ".param t9='inputslew*10/6*5.0'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n";
          print WRITE ".nodeset v(n3)=vss\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0   vss\n";
          print WRITE "\n";
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t0   v0\n"; 
          print WRITE "+               t1   v1\n";
          print WRITE "+               t2   v2\n";
          print WRITE "+               t3   v3\n";
          print WRITE "+               t4   v4\n";
          print WRITE "+               t5   v5\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v5\n"; 
          print WRITE "+               t1   v5\n";
          print WRITE "+               t2   v5\n";
          print WRITE "+               t3   v5\n";
          print WRITE "+               t4   v5\n";
          print WRITE "+               t5   v5\n";
          print WRITE "+             )\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE "*.meas tran n1_first_rise when v(n1)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n3_first_rise when v(n3)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close(WRITE);
          ####################################################################################################################################
          system("ngspice -b -o $file-$clk-$clkval-n1_$n1_val-n3_$n3_val.log $file-$clk-$clkval-n1_$n1_val-n3_$n3_val");
          #------------------------------------------------------read log file---------------------------------------------------------------# 
          open (READ_LOG,"$file-$clk-$clkval-n1_0-n3_vdd.log");
          while(<READ_LOG>){
          chomp();
            if($_ =~ /^n3_first_rise/){my $n3_first_rise = (split(/=\s+/,$_))[1];
              if($n3_first_rise ne ""){$get_n2_val = $clkval;}
            }
          }
          close(READ_LOG);
          #----------------------------------------------------------------------------------------------------------------------------------#
        }
      }#for clk value
    }#for n3 value
  }#for n1 value
  if($get_n2_val == $get_clk_val){print "INFO : clock value is correct and the clock value is $get_clk_val\n";}
  else{print "WARN : Please check the value of clock\n";} 
#-------------------------------------------------------create test bench for setup and hold time--------------------------------------------#
my @setup_time_list_for_rise = ();
my @hold_time_list_for_rise = ();
my @setup_time_list_for_fall = ();
my @hold_time_list_for_fall = ();
#-------------------------------------------------test bench for setup time for n3_first_rise------------------------------------------------#
for(my $in_slew_clk=0;$in_slew_clk<=$#input_slew_clock;$in_slew_clk++){
  for (my $in_slew_data=0;$in_slew_data<=$#input_slew;$in_slew_data++){
    my $input_slew_data = $input_slew[$in_slew_data]; 
    my $input_slew_data_value_with_unit = $input_slew[$in_slew_data].""."e-9";
    my $input_slew_clk = $input_slew_clock[$in_slew_clk];
    my $input_slew_clk_value_with_unit = $input_slew_clock[$in_slew_clk].""."e-9";
    my $get_n3_first_rise_from_n1_n2_delay_0 = "";
    my $get_n3_first_fall_from_n1_n2_delay_0 = "";
    my $setup_time_negative_for_fall = 0;
    my $setup_time_positive_for_fall = 0;
    my $setup_time_negative_for_rise = 0;
    my $setup_time_positive_for_rise = 0;
    my $set_up_time_for_rise_nanosecond = "";
    my $set_up_time_for_fall_nanosecond = "";
    open(WRITE,">$file-setup_for_rise-n1_n2_delay_0-$input_slew_data-$input_slew_clk");
    print WRITE ".title Fanout Versus Delay (TSMC)\n";
    print WRITE "\n";
    print WRITE ".param vdd=$vdd_pri_val\n";
    print WRITE ".param vddsec=$vdd_pri_val\n"if($vdd_sec_val eq "");
    print WRITE ".param vddsec=$vdd_sec_val\n"if($vdd_sec_val ne "");
    print WRITE ".param vss=$vss_val\n";
    print WRITE ".param wp=$wp\n";
    print WRITE ".param wn=$wn\n";
    print WRITE ".param vlo='0.2*vdd'\n";
    print WRITE ".param vmid='0.5*vdd'\n";
    print WRITE ".param vhi='0.8*vdd'\n";
    print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
    print WRITE ".param inputslew=$input_slew_data_value_with_unit\n";
    print WRITE ".param inputslew_clock=$input_slew_clk_value_with_unit\n";
    print WRITE ".param v0=vss\n"; 
    print WRITE ".param v1=vss\n";
    print WRITE ".param v2=vlo\n";
    print WRITE ".param v3=vhi\n";
    print WRITE ".param v4=vdd\n";
    print WRITE ".param v5=vdd\n";
    print WRITE ".param v6=vhi\n";
    print WRITE ".param v7=vlo\n";
    print WRITE ".param v8=vss\n";
    print WRITE ".param v9=vss\n";
    print WRITE "\n";
    print WRITE ".param powerparam=0\n";
    print WRITE ".param divisor='2**powerparam'\n";
    print WRITE "*.param n1_n2_delay='10e-09/divisor'\n";
    print WRITE ".param n1_n2_delay=0\n";
    print WRITE "\n";
    print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
    print WRITE ".param t1='inputslew*10/6*1.0'\n";
    print WRITE ".param t2='inputslew*10/6*1.2'\n";
    print WRITE ".param t3='inputslew*10/6*1.8'\n";
    print WRITE ".param t4='inputslew*10/6*2.0'\n";
    print WRITE ".param t5='inputslew*10/6*3.0'\n";
    print WRITE ".param t6='inputslew*10/6*3.2'\n";
    print WRITE ".param t7='inputslew*10/6*3.8'\n";
    print WRITE ".param t8='inputslew*10/6*4.0'\n";
    print WRITE ".param t9='inputslew*10/6*5.0'\n";
    print WRITE "\n";
    print WRITE ".param t_0='t0 - n1_n2_delay'\n"; 
    print WRITE ".param t_1='t_0 + inputslew_clock*10/6*1.0'\n";
    print WRITE ".param t_2='t_0 + inputslew_clock*10/6*1.2'\n";
    print WRITE ".param t_3='t_0 + inputslew_clock*10/6*1.8'\n";
    print WRITE ".param t_4='t_0 + inputslew_clock*10/6*2.0'\n";
    print WRITE ".param t_5='t_0 + inputslew_clock*10/6*3.0'\n";
    print WRITE ".param t_6='t_0 + inputslew_clock*10/6*3.2'\n";
    print WRITE ".param t_7='t_0 + inputslew_clock*10/6*3.8'\n";
    print WRITE ".param t_8='t_0 + inputslew_clock*10/6*4.0'\n";
    print WRITE ".param t_9='t_0 + inputslew_clock*10/6*5.0'\n";
    print WRITE "\n";
    print WRITE ".nodeset v(n3)=vss\n";
    print WRITE "\n";
    print WRITE "vdd vdd 0 vdd\n";
    print WRITE "vddsec vddsec 0 vddsec\n";
    print WRITE "vss vss 0   vss\n";
    print WRITE "\n";
    print WRITE "vin n2 vss pwl(\n";
    print WRITE "+               t_0   v0\n"; 
    print WRITE "+               t_1   v1\n";
    print WRITE "+               t_2   v2\n";
    print WRITE "+               t_3   v3\n";
    print WRITE "+               t_4   v4\n";
    print WRITE "+               t_5   v5\n";
    print WRITE "+             )\n";
    print WRITE "\n";
    print WRITE "vin0 n1 vss pwl(\n";
    print WRITE "+               t0   v0\n"; 
    print WRITE "+               t1   v1\n";
    print WRITE "+               t2   v2\n";
    print WRITE "+               t3   v3\n";
    print WRITE "+               t4   v4\n";
    print WRITE "+               t5   v5\n";
    print WRITE "+             )\n";
    print WRITE ".MODEL n NMOS\n";
    print WRITE ".MODEL p PMOS\n";
    print WRITE ".MODEL nd NMOS\n";
    print WRITE ".MODEL pd PMOS\n";
    print WRITE "\n";
    print WRITE "\n";
    print WRITE ".include $new_file_spice\n";
    print WRITE "x$cellName @get_new_port_list $cellName\n";
    print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
    print WRITE "C1 $output_port 0 opcap\n";
    print WRITE "\n";
    print WRITE ".temp 85\n";
    print WRITE ".tran 10p 500n\n";
    print WRITE "\n";
    print WRITE ".meas tran n3_first_rise when v(n3)=vhi rise=1\n";
    print WRITE "\n";
    print WRITE ".end\n";
    close(WRITE);
    ###################################################################################################################################################
    system ("ngspice -b -o $file-setup_for_rise-n1_n2_delay_0-$input_slew_data-$input_slew_clk.log $file-setup_for_rise-n1_n2_delay_0-$input_slew_data-$input_slew_clk"); 
    #--------------------------------------------read log file of first test bench n3_first_rise------------------------------------------------------#
    open(READ_LOG,"$file-setup_for_rise-n1_n2_delay_0-$input_slew_data-$input_slew_clk.log");
    while(<READ_LOG>){
    chomp();
      if($_ =~ /^n3_first_rise/){$get_n3_first_rise_from_n1_n2_delay_0 = (split(/=\s+/,$_))[1];
      } 
    }#while reading
    close(READ_LOG);
    #-----------------------------------------------------------------------------------------------------------------------------------------------#
    if($get_n3_first_rise_from_n1_n2_delay_0 ne ""){
      my $n3_transistion_found = 0;
      my $power_param = 0;
      while ($n3_transistion_found == 0){
        my $n3_firstrise = "";
        open(WRITE,">$file-setup_for_rise-$input_slew_data-$input_slew_clk-$power_param");
        print WRITE ".title Fanout Versus Delay (TSMC)\n";
        print WRITE "\n";
        print WRITE ".param vdd=$vdd_pri_val\n";
        print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
        print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
        print WRITE ".param vss=$vss_val\n";
        print WRITE ".param wp=$wp\n";
        print WRITE ".param wn=$wn\n";
        print WRITE ".param vlo='0.2*vdd'\n";
        print WRITE ".param vmid='0.5*vdd'\n";
        print WRITE ".param vhi='0.8*vdd'\n";
        print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
        print WRITE ".param inputslew=$input_slew_data_value_with_unit\n";
        print WRITE ".param inputslew_clock=$input_slew_clk_value_with_unit\n";
        print WRITE ".param v0=vss\n"; 
        print WRITE ".param v1=vss\n";
        print WRITE ".param v2=vlo\n";
        print WRITE ".param v3=vhi\n";
        print WRITE ".param v4=vdd\n";
        print WRITE ".param v5=vdd\n";
        print WRITE ".param v6=vhi\n";
        print WRITE ".param v7=vlo\n";
        print WRITE ".param v8=vss\n";
        print WRITE ".param v9=vss\n";
        print WRITE ".param powerparam=$power_param\n";
        print WRITE ".param divisor='2**powerparam'\n";
        print WRITE ".param n1_n2_delay='10e-09/divisor'\n";
        print WRITE "\n";
        print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
        print WRITE ".param t1='inputslew*10/6*1.0'\n";
        print WRITE ".param t2='inputslew*10/6*1.2'\n";
        print WRITE ".param t3='inputslew*10/6*1.8'\n";
        print WRITE ".param t4='inputslew*10/6*2.0'\n";
        print WRITE ".param t5='inputslew*10/6*3.0'\n";
        print WRITE ".param t6='inputslew*10/6*3.2'\n";
        print WRITE ".param t7='inputslew*10/6*3.8'\n";
        print WRITE ".param t8='inputslew*10/6*4.0'\n";
        print WRITE ".param t9='inputslew*10/6*5.0'\n";
        print WRITE "\n";
        print WRITE ".param t_0='t0 - n1_n2_delay'\n"; 
        print WRITE ".param t_1='t_0 + inputslew_clock*10/6*1.0'\n";
        print WRITE ".param t_2='t_0 + inputslew_clock*10/6*1.2'\n";
        print WRITE ".param t_3='t_0 + inputslew_clock*10/6*1.8'\n";
        print WRITE ".param t_4='t_0 + inputslew_clock*10/6*2.0'\n";
        print WRITE ".param t_5='t_0 + inputslew_clock*10/6*3.0'\n";
        print WRITE ".param t_6='t_0 + inputslew_clock*10/6*3.2'\n";
        print WRITE ".param t_7='t_0 + inputslew_clock*10/6*3.8'\n";
        print WRITE ".param t_8='t_0 + inputslew_clock*10/6*4.0'\n";
        print WRITE ".param t_9='t_0 + inputslew_clock*10/6*5.0'\n";
        print WRITE "\n";
        print WRITE ".nodeset v(n3)=vss\n";
        print WRITE "\n";
        print WRITE "vdd vdd 0 vdd\n";
        print WRITE "vddsec vddsec 0 vddsec\n";
        print WRITE "vss vss 0   vss\n";
        print WRITE "\n";
        print WRITE "vin n2 vss pwl(\n";
        print WRITE "+               t_0   v0\n"; 
        print WRITE "+               t_1   v1\n";
        print WRITE "+               t_2   v2\n";
        print WRITE "+               t_3   v3\n";
        print WRITE "+               t_4   v4\n";
        print WRITE "+               t_5   v5\n";
        print WRITE "+             )\n";
        print WRITE "\n";
        print WRITE "vin0 n1 vss pwl(\n";
        print WRITE "+               t0   v0\n"; 
        print WRITE "+               t1   v1\n";
        print WRITE "+               t2   v2\n";
        print WRITE "+               t3   v3\n";
        print WRITE "+               t4   v4\n";
        print WRITE "+               t5   v5\n";
        print WRITE "+             )\n";
        print WRITE ".MODEL n NMOS\n";
        print WRITE ".MODEL p PMOS\n";
        print WRITE ".MODEL nd NMOS\n";
        print WRITE ".MODEL pd PMOS\n";
        print WRITE "\n";
        print WRITE "\n";
        print WRITE ".include $new_file_spice\n";
        print WRITE "x$cellName @get_new_port_list $cellName\n";
        print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
        print WRITE "C1 $output_port 0 opcap\n";
        print WRITE "\n";
        print WRITE ".temp 85\n";
        print WRITE ".tran 10p 500n\n";
        print WRITE "\n";
        print WRITE ".meas tran n3_first_rise when v(n3)=vhi rise=1\n";
        print WRITE "\n";
        print WRITE ".end\n";
        close (WRITE);
        ###########################################################################################################################################################
        system ("ngspice -b -o $file-setup_for_rise-$input_slew_data-$input_slew_clk-$power_param.log $file-setup_for_rise-$input_slew_data-$input_slew_clk-$power_param"); 
        #---------------------------------------------------------------read log file-----------------------------------------------------------------------------#
        open(READ_LOG,"$file-setup_for_rise-$input_slew_data-$input_slew_clk-$power_param.log");
        while(<READ_LOG>){
        chomp();
          if($_ =~ /^n3_first_rise/){$n3_firstrise = (split(/=\s+/,$_))[1];}
        }#while reading log file
        close(READ_LOG);
        if($n3_firstrise eq ""){
          $n3_transistion_found = 0;
          $power_param++;
        }else{$n3_transistion_found = 1;
           my $divisor=2**$power_param;
           my $n1_n2_delay = -(10e-09/$divisor);
           $set_up_time_for_rise_nanosecond = $n1_n2_delay*(10**9);
           $setup_time_negative_for_rise = 1;
           push(@setup_time_list_for_rise,$set_up_time_for_rise_nanosecond);
        } 
      }#while n3_transistion_found for rise 
    }else {
        my $n3_transistion_found_for_rise = 1;
        my $power_param = 0;
        while($n3_transistion_found_for_rise == 1){
        my $n3_first_rise = "";
        open(WRITE,">$file-setup_for_rise-$input_slew_data-$input_slew_clk-$power_param");
        print WRITE ".title Fanout Versus Delay (TSMC)\n";
        print WRITE "\n";
        print WRITE ".param vdd=$vdd_pri_val\n";
        print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
        print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
        print WRITE ".param vss=$vss_val\n";
        print WRITE ".param wp=$wp\n";
        print WRITE ".param wn=$wn\n";
        print WRITE ".param vlo='0.2*vdd'\n";
        print WRITE ".param vmid='0.5*vdd'\n";
        print WRITE ".param vhi='0.8*vdd'\n";
        print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
        print WRITE ".param inputslew=$input_slew_data_value_with_unit\n";
        print WRITE ".param inputslew_clock=$input_slew_clk_value_with_unit\n";
        print WRITE ".param v0=vss\n"; 
        print WRITE ".param v1=vss\n";
        print WRITE ".param v2=vlo\n";
        print WRITE ".param v3=vhi\n";
        print WRITE ".param v4=vdd\n";
        print WRITE ".param v5=vdd\n";
        print WRITE ".param v6=vhi\n";
        print WRITE ".param v7=vlo\n";
        print WRITE ".param v8=vss\n";
        print WRITE ".param v9=vss\n";
        print WRITE ".param powerparam=$power_param\n";
        print WRITE ".param divisor='2**powerparam'\n";
        print WRITE ".param n1_n2_delay='10e-09/divisor'\n";
        print WRITE "\n";
        print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
        print WRITE ".param t1='inputslew*10/6*1.0'\n";
        print WRITE ".param t2='inputslew*10/6*1.2'\n";
        print WRITE ".param t3='inputslew*10/6*1.8'\n";
        print WRITE ".param t4='inputslew*10/6*2.0'\n";
        print WRITE ".param t5='inputslew*10/6*3.0'\n";
        print WRITE ".param t6='inputslew*10/6*3.2'\n";
        print WRITE ".param t7='inputslew*10/6*3.8'\n";
        print WRITE ".param t8='inputslew*10/6*4.0'\n";
        print WRITE ".param t9='inputslew*10/6*5.0'\n";
        print WRITE "\n";
        print WRITE ".param t_0='t0 + n1_n2_delay'\n"; 
        print WRITE ".param t_1='t_0 + inputslew_clock*10/6*1.0'\n";
        print WRITE ".param t_2='t_0 + inputslew_clock*10/6*1.2'\n";
        print WRITE ".param t_3='t_0 + inputslew_clock*10/6*1.8'\n";
        print WRITE ".param t_4='t_0 + inputslew_clock*10/6*2.0'\n";
        print WRITE ".param t_5='t_0 + inputslew_clock*10/6*3.0'\n";
        print WRITE ".param t_6='t_0 + inputslew_clock*10/6*3.2'\n";
        print WRITE ".param t_7='t_0 + inputslew_clock*10/6*3.8'\n";
        print WRITE ".param t_8='t_0 + inputslew_clock*10/6*4.0'\n";
        print WRITE ".param t_9='t_0 + inputslew_clock*10/6*5.0'\n";
        print WRITE "\n";
        print WRITE ".nodeset v(n3)=vss\n";
        print WRITE "\n";
        print WRITE "vdd vdd 0 vdd\n";
        print WRITE "vddsec vddsec 0 vddsec\n";
        print WRITE "vss vss 0   vss\n";
        print WRITE "\n";
        print WRITE "vin n2 vss pwl(\n";
        print WRITE "+               t_0   v0\n"; 
        print WRITE "+               t_1   v1\n";
        print WRITE "+               t_2   v2\n";
        print WRITE "+               t_3   v3\n";
        print WRITE "+               t_4   v4\n";
        print WRITE "+               t_5   v5\n";
        print WRITE "+             )\n";
        print WRITE "\n";
        print WRITE "vin0 n1 vss pwl(\n";
        print WRITE "+               t0   v0\n"; 
        print WRITE "+               t1   v1\n";
        print WRITE "+               t2   v2\n";
        print WRITE "+               t3   v3\n";
        print WRITE "+               t4   v4\n";
        print WRITE "+               t5   v5\n";
        print WRITE "+             )\n";
        print WRITE ".MODEL n NMOS\n";
        print WRITE ".MODEL p PMOS\n";
        print WRITE ".MODEL nd NMOS\n";
        print WRITE ".MODEL pd PMOS\n";
        print WRITE "\n";
        print WRITE "\n";
        print WRITE ".include $new_file_spice\n";
        print WRITE "x$cellName @get_new_port_list $cellName\n";
        print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
        print WRITE "C1 $output_port 0 opcap\n";
        print WRITE "\n";
        print WRITE ".temp 85\n";
        print WRITE ".tran 10p 500n\n";
        print WRITE "\n";
        print WRITE ".meas tran n3_first_rise when v(n3)=vhi rise=1\n";
        print WRITE "\n";
        print WRITE ".end\n";
        close (WRITE);
        ############################################################################################################################################################
        system ("ngspice -b -o $file-setup_for_rise-$input_slew_data-$input_slew_clk-$power_param.log $file-setup_for_rise-$input_slew_data-$input_slew_clk-$power_param");
        #---------------------------------------------------read log file------------------------------------------------------------------------------------------# 
        open(READ_LOG,"$file-setup_for_rise-$input_slew_data-$input_slew_clk-$power_param.log");
        while(<READ_LOG>){
        chomp();
          if($_ =~ /^n3_first_rise/){$n3_first_rise = (split(/=\s+/,$_))[1];}
        }#while reading log file
        close(READ_LOG);
        if($n3_first_rise ne ""){
          $n3_transistion_found_for_rise = 1;
          $power_param++;
        }else{
              $n3_transistion_found_for_rise = 0;
              my $before_power_param = ($power_param -1);
              my $divisor = 2**$before_power_param;
              my $n1_n2_delay = (10e-09/$divisor);
              $set_up_time_for_rise_nanosecond = $n1_n2_delay*(10**9);
              $setup_time_positive_for_rise = 1;
              push(@setup_time_list_for_rise,$set_up_time_for_rise_nanosecond);
        }
      }#while n3_transistion_found for rise
    }#else
    #-------------------------------------------------test bench for setup time for n3_first_fall------------------------------# 
    open(WRITE,">$file-setup_for_fall-n1_n2_delay_0-$input_slew_data-$input_slew_clk");
    print WRITE ".title Fanout Versus Delay (TSMC)\n";
    print WRITE "\n";
    print WRITE ".param vdd=$vdd_pri_val\n";
    print WRITE ".param vddsec=$vdd_pri_val\n"if($vdd_sec_val eq "");
    print WRITE ".param vddsec=$vdd_sec_val\n"if($vdd_sec_val ne "");
    print WRITE ".param vss=$vss_val\n";
    print WRITE ".param wp=$wp\n";
    print WRITE ".param wn=$wn\n";
    print WRITE ".param vlo='0.2*vdd'\n";
    print WRITE ".param vmid='0.5*vdd'\n";
    print WRITE ".param vhi='0.8*vdd'\n";
    print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
    print WRITE ".param inputslew=$input_slew_data_value_with_unit\n";
    print WRITE ".param inputslew_clock=$input_slew_clk_value_with_unit\n";
    print WRITE ".param v0=vss\n"; 
    print WRITE ".param v1=vss\n";
    print WRITE ".param v2=vlo\n";
    print WRITE ".param v3=vhi\n";
    print WRITE ".param v4=vdd\n";
    print WRITE ".param v5=vdd\n";
    print WRITE ".param v6=vhi\n";
    print WRITE ".param v7=vlo\n";
    print WRITE ".param v8=vss\n";
    print WRITE ".param v9=vss\n";
    print WRITE ".param powerparam=0\n";
    print WRITE ".param divisor='2**powerparam'\n";
    print WRITE "*.param n1_n2_delay='10e-09/divisor'\n";
    print WRITE ".param n1_n2_delay=0\n";
    print WRITE "\n";
    print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
    print WRITE ".param t1='inputslew*10/6*1.0'\n";
    print WRITE ".param t2='inputslew*10/6*1.2'\n";
    print WRITE ".param t3='inputslew*10/6*1.8'\n";
    print WRITE ".param t4='inputslew*10/6*2.0'\n";
    print WRITE ".param t5='inputslew*10/6*3.0'\n";
    print WRITE ".param t6='inputslew*10/6*3.2'\n";
    print WRITE ".param t7='inputslew*10/6*3.8'\n";
    print WRITE ".param t8='inputslew*10/6*4.0'\n";
    print WRITE ".param t9='inputslew*10/6*5.0'\n";
    print WRITE "\n";
    print WRITE ".param t_0='t0 - n1_n2_delay'\n"; 
    print WRITE ".param t_1='t_0 + inputslew_clock*10/6*1.0'\n";
    print WRITE ".param t_2='t_0 + inputslew_clock*10/6*1.2'\n";
    print WRITE ".param t_3='t_0 + inputslew_clock*10/6*1.8'\n";
    print WRITE ".param t_4='t_0 + inputslew_clock*10/6*2.0'\n";
    print WRITE ".param t_5='t_0 + inputslew_clock*10/6*3.0'\n";
    print WRITE ".param t_6='t_0 + inputslew_clock*10/6*3.2'\n";
    print WRITE ".param t_7='t_0 + inputslew_clock*10/6*3.8'\n";
    print WRITE ".param t_8='t_0 + inputslew_clock*10/6*4.0'\n";
    print WRITE ".param t_9='t_0 + inputslew_clock*10/6*5.0'\n";
    print WRITE "\n";
    print WRITE ".nodeset v(n3)=vdd\n";
    print WRITE "\n";
    print WRITE "vdd vdd 0 vdd\n";
    print WRITE "vddsec vddsec 0 vddsec\n";
    print WRITE "vss vss 0   vss\n";
    print WRITE "\n";
    print WRITE "vin n2 vss pwl(\n";
    print WRITE "+               t_0   v0\n"; 
    print WRITE "+               t_1   v1\n";
    print WRITE "+               t_2   v2\n";
    print WRITE "+               t_3   v3\n";
    print WRITE "+               t_4   v4\n";
    print WRITE "+               t_5   v5\n";
    print WRITE "+             )\n";
    print WRITE "\n";
    print WRITE "vin0 n1 vss pwl(\n";
    print WRITE "+               t0   v5\n"; 
    print WRITE "+               t1   v4\n";
    print WRITE "+               t2   v3\n";
    print WRITE "+               t3   v2\n";
    print WRITE "+               t4   v1\n";
    print WRITE "+               t5   v0\n";
    print WRITE "+             )\n";
    print WRITE ".MODEL n NMOS\n";
    print WRITE ".MODEL p PMOS\n";
    print WRITE ".MODEL nd NMOS\n";
    print WRITE ".MODEL pd PMOS\n";
    print WRITE "\n";
    print WRITE "\n";
    print WRITE ".include $new_file_spice\n";
    print WRITE "x$cellName @get_new_port_list $cellName\n";
    print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
    print WRITE "C1 $output_port 0 opcap\n";
    print WRITE "\n";
    print WRITE ".temp 85\n";
    print WRITE ".tran 10p 500n\n";
    print WRITE "\n";
    print WRITE ".meas tran n3_first_fall when v(n3)=vlo fall=1\n";
    print WRITE "\n";
    print WRITE ".end\n";
    close (WRITE);
    ############################################################################################################################
    system ("ngspice -b -o $file-setup_for_fall-n1_n2_delay_0-$input_slew_data-$input_slew_clk.log $file-setup_for_fall-n1_n2_delay_0-$input_slew_data-$input_slew_clk"); 
    #------------------------------------------------read log file for n3_first_fall-------------------------------------------#
    open(READ_LOG,"$file-setup_for_fall-n1_n2_delay_0-$input_slew_data-$input_slew_clk.log");
    while(<READ_LOG>){
    chomp();
      if($_ =~ /^n3_first_fall/){$get_n3_first_fall_from_n1_n2_delay_0 = (split(/=\s+/,$_))[1];
      }
    }#while reading
    close(READ_LOG);
    #--------------------------------------------------------------------------------------------------------------------------#
    if($get_n3_first_fall_from_n1_n2_delay_0 ne ""){
      my $n3_transistion_found = 0;
      my $power_param = 0;
      while ($n3_transistion_found == 0){
        my $n3_firstfall = "";
        open(WRITE,">$file-setup_for_fall-$input_slew_data-$input_slew_clk-$power_param");
        print WRITE ".title Fanout Versus Delay (TSMC)\n";
        print WRITE "\n";
        print WRITE ".param vdd=$vdd_pri_val\n";
        print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
        print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
        print WRITE ".param vss=$vss_val\n";
        print WRITE ".param wp=$wp\n";
        print WRITE ".param wn=$wn\n";
        print WRITE ".param vlo='0.2*vdd'\n";
        print WRITE ".param vmid='0.5*vdd'\n";
        print WRITE ".param vhi='0.8*vdd'\n";
        print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
        print WRITE ".param inputslew=$input_slew_data_value_with_unit\n";
        print WRITE ".param inputslew_clock=$input_slew_clk_value_with_unit\n";
        print WRITE ".param v0=vss\n"; 
        print WRITE ".param v1=vss\n";
        print WRITE ".param v2=vlo\n";
        print WRITE ".param v3=vhi\n";
        print WRITE ".param v4=vdd\n";
        print WRITE ".param v5=vdd\n";
        print WRITE ".param v6=vhi\n";
        print WRITE ".param v7=vlo\n";
        print WRITE ".param v8=vss\n";
        print WRITE ".param v9=vss\n";
        print WRITE ".param powerparam=$power_param\n";
        print WRITE ".param divisor='2**powerparam'\n";
        print WRITE ".param n1_n2_delay='10e-09/divisor'\n";
        print WRITE "\n";
        print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
        print WRITE ".param t1='inputslew*10/6*1.0'\n";
        print WRITE ".param t2='inputslew*10/6*1.2'\n";
        print WRITE ".param t3='inputslew*10/6*1.8'\n";
        print WRITE ".param t4='inputslew*10/6*2.0'\n";
        print WRITE ".param t5='inputslew*10/6*3.0'\n";
        print WRITE ".param t6='inputslew*10/6*3.2'\n";
        print WRITE ".param t7='inputslew*10/6*3.8'\n";
        print WRITE ".param t8='inputslew*10/6*4.0'\n";
        print WRITE ".param t9='inputslew*10/6*5.0'\n";
        print WRITE "\n";
        print WRITE ".param t_0='t0 - n1_n2_delay'\n"; 
        print WRITE ".param t_1='t_0 + inputslew_clock*10/6*1.0'\n";
        print WRITE ".param t_2='t_0 + inputslew_clock*10/6*1.2'\n";
        print WRITE ".param t_3='t_0 + inputslew_clock*10/6*1.8'\n";
        print WRITE ".param t_4='t_0 + inputslew_clock*10/6*2.0'\n";
        print WRITE ".param t_5='t_0 + inputslew_clock*10/6*3.0'\n";
        print WRITE ".param t_6='t_0 + inputslew_clock*10/6*3.2'\n";
        print WRITE ".param t_7='t_0 + inputslew_clock*10/6*3.8'\n";
        print WRITE ".param t_8='t_0 + inputslew_clock*10/6*4.0'\n";
        print WRITE ".param t_9='t_0 + inputslew_clock*10/6*5.0'\n";
        print WRITE "\n";
        print WRITE ".nodeset v(n3)=vdd\n";
        print WRITE "\n";
        print WRITE "vdd vdd 0 vdd\n";
        print WRITE "vddsec vddsec 0 vddsec\n";
        print WRITE "vss vss 0   vss\n";
        print WRITE "\n";
        print WRITE "vin n2 vss pwl(\n";
        print WRITE "+               t_0   v0\n"; 
        print WRITE "+               t_1   v1\n";
        print WRITE "+               t_2   v2\n";
        print WRITE "+               t_3   v3\n";
        print WRITE "+               t_4   v4\n";
        print WRITE "+               t_5   v5\n";
        print WRITE "+             )\n";
        print WRITE "\n";
        print WRITE "vin0 n1 vss pwl(\n";
        print WRITE "+               t0   v5\n"; 
        print WRITE "+               t1   v4\n";
        print WRITE "+               t2   v3\n";
        print WRITE "+               t3   v2\n";
        print WRITE "+               t4   v1\n";
        print WRITE "+               t5   v0\n";
        print WRITE "+             )\n";
        print WRITE ".MODEL n NMOS\n";
        print WRITE ".MODEL p PMOS\n";
        print WRITE ".MODEL nd NMOS\n";
        print WRITE ".MODEL pd PMOS\n";
        print WRITE "\n";
        print WRITE "\n";
        print WRITE ".include $new_file_spice\n";
        print WRITE "x$cellName @get_new_port_list $cellName\n";
        print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
        print WRITE "C1 $output_port 0 opcap\n";
        print WRITE "\n";
        print WRITE ".temp 85\n";
        print WRITE ".tran 10p 500n\n";
        print WRITE "\n";
        print WRITE ".meas tran n3_first_fall when v(n3)=vlo fall=1\n";
        print WRITE "\n";
        print WRITE ".end\n";
        close (WRITE);
        ########################################################################################################################
        system ("ngspice -b -o $file-setup_for_fall-$input_slew_data-$input_slew_clk-$power_param.log $file-setup_for_fall-$input_slew_data-$input_slew_clk-$power_param"); 
        #---------------------------------------------------read log file for setup fall---------------------------------------#
        open(READ_LOG,"$file-setup_for_fall-$input_slew_data-$input_slew_clk-$power_param.log");
        while(<READ_LOG>){
        chomp();
          if($_ =~ /^n3_first_fall/){$n3_firstfall = (split(/=\s+/,$_))[1];}
        }#while reading log file
        close(READ_LOG);
        if($n3_firstfall eq ""){
          $n3_transistion_found = 0;
          $power_param++;
        }else{$n3_transistion_found = 1;
           my $divisor = 2**$power_param;
           my $n1_n2_delay = -(10e-09/$divisor);
           $set_up_time_for_fall_nanosecond = $n1_n2_delay*(10**9);
           $setup_time_negative_for_fall = 1;
           push(@setup_time_list_for_fall,$set_up_time_for_fall_nanosecond);
        }
      }#while n3_transistion_found for fall
    }else {
       my $n3_transistion_found = 1;
       my $power_param = 0;
       while($n3_transistion_found == 1){
       my $n3_firstfall = "";
       open(WRITE,">$file-setup_for_fall-$input_slew_data-$input_slew_clk-$power_param");
       print WRITE ".title Fanout Versus Delay (TSMC)\n";
       print WRITE "\n";
       print WRITE ".param vdd=$vdd_pri_val\n";
       print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
       print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
       print WRITE ".param vss=$vss_val\n";
       print WRITE ".param wp=$wp\n";
       print WRITE ".param wn=$wn\n";
       print WRITE ".param vlo='0.2*vdd'\n";
       print WRITE ".param vmid='0.5*vdd'\n";
       print WRITE ".param vhi='0.8*vdd'\n";
       print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
       print WRITE ".param inputslew=$input_slew_data_value_with_unit\n";
       print WRITE ".param inputslew_clock=$input_slew_clk_value_with_unit\n";
       print WRITE ".param v0=vss\n"; 
       print WRITE ".param v1=vss\n";
       print WRITE ".param v2=vlo\n";
       print WRITE ".param v3=vhi\n";
       print WRITE ".param v4=vdd\n";
       print WRITE ".param v5=vdd\n";
       print WRITE ".param v6=vhi\n";
       print WRITE ".param v7=vlo\n";
       print WRITE ".param v8=vss\n";
       print WRITE ".param v9=vss\n";
       print WRITE ".param powerparam=$power_param\n";
       print WRITE ".param divisor='2**powerparam'\n";
       print WRITE ".param n1_n2_delay='10e-09/divisor'\n";
       print WRITE "\n";
       print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
       print WRITE ".param t1='inputslew*10/6*1.0'\n";
       print WRITE ".param t2='inputslew*10/6*1.2'\n";
       print WRITE ".param t3='inputslew*10/6*1.8'\n";
       print WRITE ".param t4='inputslew*10/6*2.0'\n";
       print WRITE ".param t5='inputslew*10/6*3.0'\n";
       print WRITE ".param t6='inputslew*10/6*3.2'\n";
       print WRITE ".param t7='inputslew*10/6*3.8'\n";
       print WRITE ".param t8='inputslew*10/6*4.0'\n";
       print WRITE ".param t9='inputslew*10/6*5.0'\n";
       print WRITE "\n";
       print WRITE ".param t_0='t0 + n1_n2_delay'\n"; 
       print WRITE ".param t_1='t_0 + inputslew_clock*10/6*1.0'\n";
       print WRITE ".param t_2='t_0 + inputslew_clock*10/6*1.2'\n";
       print WRITE ".param t_3='t_0 + inputslew_clock*10/6*1.8'\n";
       print WRITE ".param t_4='t_0 + inputslew_clock*10/6*2.0'\n";
       print WRITE ".param t_5='t_0 + inputslew_clock*10/6*3.0'\n";
       print WRITE ".param t_6='t_0 + inputslew_clock*10/6*3.2'\n";
       print WRITE ".param t_7='t_0 + inputslew_clock*10/6*3.8'\n";
       print WRITE ".param t_8='t_0 + inputslew_clock*10/6*4.0'\n";
       print WRITE ".param t_9='t_0 + inputslew_clock*10/6*5.0'\n";
       print WRITE "\n";
       print WRITE ".nodeset v(n3)=vdd\n";
       print WRITE "\n";
       print WRITE "vdd vdd 0 vdd\n";
       print WRITE "vddsec vddsec 0 vddsec\n";
       print WRITE "vss vss 0   vss\n";
       print WRITE "\n";
       print WRITE "vin n2 vss pwl(\n";
       print WRITE "+               t_0   v0\n"; 
       print WRITE "+               t_1   v1\n";
       print WRITE "+               t_2   v2\n";
       print WRITE "+               t_3   v3\n";
       print WRITE "+               t_4   v4\n";
       print WRITE "+               t_5   v5\n";
       print WRITE "+             )\n";
       print WRITE "\n";
       print WRITE "vin0 n1 vss pwl(\n";
       print WRITE "+               t0   v5\n"; 
       print WRITE "+               t1   v4\n";
       print WRITE "+               t2   v3\n";
       print WRITE "+               t3   v2\n";
       print WRITE "+               t4   v1\n";
       print WRITE "+               t5   v0\n";
       print WRITE "+             )\n";
       print WRITE ".MODEL n NMOS\n";
       print WRITE ".MODEL p PMOS\n";
       print WRITE ".MODEL nd NMOS\n";
       print WRITE ".MODEL pd PMOS\n";
       print WRITE "\n";
       print WRITE "\n";
       print WRITE ".include $new_file_spice\n";
       print WRITE "x$cellName @get_new_port_list $cellName\n";
       print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
       print WRITE "C1 $output_port 0 opcap\n";
       print WRITE "\n";
       print WRITE ".temp 85\n";
       print WRITE ".tran 10p 500n\n";
       print WRITE "\n";
       print WRITE ".meas tran n3_first_fall when v(n3)=vlo fall=1\n";
       print WRITE "\n";
       print WRITE ".end\n";
       close (WRITE);
       #########################################################################################################################
       system ("ngspice -b -o $file-setup_for_fall-$input_slew_data-$input_slew_clk-$power_param.log $file-setup_for_fall-$input_slew_data-$input_slew_clk-$power_param"); 
       #---------------------------------------------------read log file-------------------------------------------------------#
       open(READ_NG_LOG,"$file-setup_for_fall-$input_slew_data-$input_slew_clk-$power_param.log");
       while(<READ_NG_LOG>){
       chomp();
         if($_ =~ /^n3_first_fall/){$n3_firstfall = (split(/=\s+/,$_))[1];}
       }#while reading log file
       close(READ_NG_LOG);
       if($n3_firstfall ne ""){
         $n3_transistion_found = 1;
         $power_param++;
       }else{$n3_transistion_found = 0;
             my $before_power_param = ($power_param -1);
             my $divisor = 2**$before_power_param;
             my $n1_n2_delay = (10e-09/$divisor);
             $set_up_time_for_fall_nanosecond = $n1_n2_delay*(10**9);
             $setup_time_positive_for_fall = 1;
             push(@setup_time_list_for_fall,$set_up_time_for_fall_nanosecond);
       }
     }#while n3_transistion_found for fall
    }#else
    #-----------------------------------------test bench for hold time for n3_first rise---------------------------------------#
    if ($set_up_time_for_rise_nanosecond ne "" && $setup_time_negative_for_rise == 1){
      my $n3firstrise = "";
      my $set_up_time_for_rise_second = $set_up_time_for_rise_nanosecond.""."e-9"; 
      open(WRITE,">$file-hold_for_rise-n1_n1_delay_0-$input_slew_data-$input_slew_clk");
      print WRITE ".title Fanout Versus Delay (TSMC)\n";
      print WRITE "\n";
      print WRITE ".param vdd=$vdd_pri_val\n";
      print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
      print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
      print WRITE ".param vss=$vss_val\n";
      print WRITE ".param wp=$wp\n";
      print WRITE ".param wn=$wn\n";
      print WRITE ".param vlo='0.2*vdd'\n";
      print WRITE ".param vmid='0.5*vdd'\n";
      print WRITE ".param vhi='0.8*vdd'\n";
      print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
      print WRITE ".param inputslew=$input_slew_data_value_with_unit\n";
      print WRITE ".param inputslew_clock=$input_slew_clk_value_with_unit\n";
      print WRITE ".param v0=vss\n"; 
      print WRITE ".param v1=vss\n";
      print WRITE ".param v2=vlo\n";
      print WRITE ".param v3=vhi\n";
      print WRITE ".param v4=vdd\n";
      print WRITE ".param v5=vdd\n";
      print WRITE ".param v6=vhi\n";
      print WRITE ".param v7=vlo\n";
      print WRITE ".param v8=vss\n";
      print WRITE ".param v9=vss\n";
      print WRITE ".param setup_time=$set_up_time_for_rise_second\n";
      print WRITE ".param powerparam=0\n";
      print WRITE ".param divisor='2**powerparam'\n";
      print WRITE "*.param n1_n1_delay='10e-09/divisor'\n";
      print WRITE ".param n1_n1_delay=0\n";
      print WRITE "\n";
      print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
      print WRITE ".param t1='inputslew*10/6*1.0'\n";
      print WRITE ".param t2='inputslew*10/6*1.2'\n";
      print WRITE ".param t3='inputslew*10/6*1.8'\n";
      print WRITE ".param t4='inputslew*10/6*2.0'\n";
      print WRITE ".param t5='t4 + 0'\n";
      print WRITE "\n";
      print WRITE ".param t_0='t0 - n1_n1_delay + setup_time'\n"; 
      print WRITE ".param t_1='t_0 + inputslew_clock*10/6*1.0'\n";
      print WRITE ".param t_2='t_0 + inputslew_clock*10/6*1.2'\n";
      print WRITE ".param t_3='t_0 + inputslew_clock*10/6*1.8'\n";
      print WRITE ".param t_4='t_0 + inputslew_clock*10/6*2.0'\n";
      print WRITE ".param t_5='t_0 + inputslew_clock*10/6*3.0'\n";
      print WRITE "\n";
      print WRITE ".param t_sec0='t5 + n1_n1_delay'\n";
      print WRITE ".param t_sec1='t_sec0 + inputslew*10/6*0.2'\n"; 
      print WRITE ".param t_sec2='t_sec0 + inputslew*10/6*0.8'\n";
      print WRITE ".param t_sec3='t_sec0 + inputslew*10/6*1.0'\n";
      print WRITE ".param t_sec4='t_sec0 + inputslew*10/6*2.0'\n";
      print WRITE "\n";
      print WRITE ".nodeset v(n3)=vss\n";
      print WRITE "\n";
      print WRITE "vdd vdd 0 vdd\n";
      print WRITE "vddsec vddsec 0 vddsec\n";
      print WRITE "vss vss 0   vss\n";
      print WRITE "\n";
      print WRITE "vin n2 vss pwl(\n";
      print WRITE "+               t_0   v0\n"; 
      print WRITE "+               t_1   v1\n";
      print WRITE "+               t_2   v2\n";
      print WRITE "+               t_3   v3\n";
      print WRITE "+               t_4   v4\n";
      print WRITE "+               t_5   v5\n";
      print WRITE "+             )\n";
      print WRITE "\n";
      print WRITE "vin0 n1 vss pwl(\n";
      print WRITE "+               t0       v0\n"; 
      print WRITE "+               t1       v1\n";
      print WRITE "+               t2       v2\n";
      print WRITE "+               t3       v3\n";
      print WRITE "+               t4       v4\n";
      print WRITE "+               t5       v5\n";
      print WRITE "+               t_sec0   v4\n";
      print WRITE "+               t_sec1   v3\n";
      print WRITE "+               t_sec2   v2\n";
      print WRITE "+               t_sec3   v1\n";
      print WRITE "+               t_sec4   v0\n";
      print WRITE "+             )\n";
      print WRITE ".MODEL n NMOS\n";
      print WRITE ".MODEL p PMOS\n";
      print WRITE ".MODEL nd NMOS\n";
      print WRITE ".MODEL pd PMOS\n";
      print WRITE "\n";
      print WRITE "\n";
      print WRITE ".include $new_file_spice\n";
      print WRITE "x$cellName @get_new_port_list $cellName\n";
      print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
      print WRITE "C1 $output_port 0 opcap\n";
      print WRITE "\n";
      print WRITE ".temp 85\n";
      print WRITE ".tran 10p 500n\n";
      print WRITE "\n";
      print WRITE ".meas tran n3_first_rise when v(n3)=vhi rise=1\n";
      print WRITE "\n";
      print WRITE ".end\n";
      close (WRITE);
      ############################################################################################################################
      system ("ngspice -b -o $file-hold_for_rise-n1_n1_delay_0-$input_slew_data-$input_slew_clk.log $file-hold_for_rise-n1_n1_delay_0-$input_slew_data-$input_slew_clk"); 
      #------------------------------------------------------------read log file-------------------------------------------------#
      open(READ_LOG,"$file-hold_for_rise-n1_n1_delay_0-$input_slew_data-$input_slew_clk.log");
      while(<READ_LOG>){
      chomp();
        if($_ =~ /^n3_first_rise/){$n3firstrise = (split(/=\s+/,$_))[1];}
      }#while reading log file
      close(READ_LOG);
      if($n3firstrise ne ""){
         my $hold_time_for_rise_nanosecond = -1*$set_up_time_for_rise_nanosecond;
         push (@hold_time_list_for_rise,$hold_time_for_rise_nanosecond);
      }else {
           my $n3_transistion_found_for_hold = 1;
           my $power_param_for_hold = 0;
         while ($n3_transistion_found_for_hold == 1){
         my $n3_first_rise = "";
         open(WRITE,">$file-hold_for_rise-$input_slew_data-$input_slew_clk-$power_param_for_hold");
         print WRITE ".title Fanout Versus Delay (TSMC)\n";
         print WRITE "\n";
         print WRITE ".param vdd=$vdd_pri_val\n";
         print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
         print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
         print WRITE ".param vss=$vss_val\n";
         print WRITE ".param wp=$wp\n";
         print WRITE ".param wn=$wn\n";
         print WRITE ".param vlo='0.2*vdd'\n";
         print WRITE ".param vmid='0.5*vdd'\n";
         print WRITE ".param vhi='0.8*vdd'\n";
         print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
         print WRITE ".param inputslew=$input_slew_data_value_with_unit\n";
         print WRITE ".param inputslew_clock=$input_slew_clk_value_with_unit\n";
         print WRITE ".param v0=vss\n"; 
         print WRITE ".param v1=vss\n";
         print WRITE ".param v2=vlo\n";
         print WRITE ".param v3=vhi\n";
         print WRITE ".param v4=vdd\n";
         print WRITE ".param v5=vdd\n";
         print WRITE ".param v6=vhi\n";
         print WRITE ".param v7=vlo\n";
         print WRITE ".param v8=vss\n";
         print WRITE ".param v9=vss\n";
         print WRITE ".param setup_time=$set_up_time_for_rise_second\n";
         print WRITE ".param powerparam=$power_param_for_hold\n";
         print WRITE ".param divisor='2**powerparam'\n";
         print WRITE ".param n1_n1_delay='10e-09/divisor'\n";
         print WRITE "*.param n1_n1_delay=0\n";
         print WRITE "\n";
         print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
         print WRITE ".param t1='inputslew*10/6*1.0'\n";
         print WRITE ".param t2='inputslew*10/6*1.2'\n";
         print WRITE ".param t3='inputslew*10/6*1.8'\n";
         print WRITE ".param t4='inputslew*10/6*2.0'\n";
         print WRITE ".param t5='t4 + 0'\n";
         print WRITE "\n";
         print WRITE "*.param t_0='t0 - n1_n1_delay + setup_time'\n"; 
         print WRITE ".param t_0='t0  + setup_time'\n"; 
         print WRITE ".param t_1='t_0 + inputslew_clock*10/6*1.0'\n";
         print WRITE ".param t_2='t_0 + inputslew_clock*10/6*1.2'\n";
         print WRITE ".param t_3='t_0 + inputslew_clock*10/6*1.8'\n";
         print WRITE ".param t_4='t_0 + inputslew_clock*10/6*2.0'\n";
         print WRITE ".param t_5='t_0 + inputslew_clock*10/6*3.0'\n";
         print WRITE "\n";
         print WRITE ".param t_sec0='t5 + n1_n1_delay'\n";
         print WRITE ".param t_sec1='t_sec0 + inputslew*10/6*0.2'\n"; 
         print WRITE ".param t_sec2='t_sec0 + inputslew*10/6*0.8'\n";
         print WRITE ".param t_sec3='t_sec0 + inputslew*10/6*1.0'\n";
         print WRITE ".param t_sec4='t_sec0 + inputslew*10/6*2.0'\n";
         print WRITE "\n";
         print WRITE ".nodeset v(n3)=vss\n";
         print WRITE "\n";
         print WRITE "vdd vdd 0 vdd\n";
         print WRITE "vddsec vddsec 0 vddsec\n";
         print WRITE "vss vss 0   vss\n";
         print WRITE "\n";
         print WRITE "vin n2 vss pwl(\n";
         print WRITE "+               t_0   v0\n"; 
         print WRITE "+               t_1   v1\n";
         print WRITE "+               t_2   v2\n";
         print WRITE "+               t_3   v3\n";
         print WRITE "+               t_4   v4\n";
         print WRITE "+               t_5   v5\n";
         print WRITE "+             )\n";
         print WRITE "\n";
         print WRITE "vin0 n1 vss pwl(\n";
         print WRITE "+               t0       v0\n"; 
         print WRITE "+               t1       v1\n";
         print WRITE "+               t2       v2\n";
         print WRITE "+               t3       v3\n";
         print WRITE "+               t4       v4\n";
         print WRITE "+               t5       v5\n";
         print WRITE "+               t_sec0   v4\n";
         print WRITE "+               t_sec1   v3\n";
         print WRITE "+               t_sec2   v2\n";
         print WRITE "+               t_sec3   v1\n";
         print WRITE "+               t_sec4   v0\n";
         print WRITE "+             )\n";
         print WRITE ".MODEL n NMOS\n";
         print WRITE ".MODEL p PMOS\n";
         print WRITE ".MODEL nd NMOS\n";
         print WRITE ".MODEL pd PMOS\n";
         print WRITE "\n";
         print WRITE "\n";
         print WRITE ".include $new_file_spice\n";
         print WRITE "x$cellName @get_new_port_list $cellName\n";
         print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
         print WRITE "C1 $output_port 0 opcap\n";
         print WRITE "\n";
         print WRITE ".temp 85\n";
         print WRITE ".tran 10p 500n\n";
         print WRITE "\n";
         print WRITE ".meas tran n3_first_rise when v(n3)=vhi rise=1\n";
         print WRITE "\n";
         print WRITE ".end\n";
         close (WRITE);
         ####################################################################################################################
         system ("ngspice -b -o $file-hold_for_rise-$input_slew_data-$input_slew_clk-$power_param_for_hold.log $file-hold_for_rise-$input_slew_data-$input_slew_clk-$power_param_for_hold"); 
         #----------------------------------------------------read log file-------------------------------------------------#
         open(READ_LOG,"$file-hold_for_rise-$input_slew_data-$input_slew_clk-$power_param_for_hold.log");
         while(<READ_LOG>){
         chomp();
           if($_ =~ /^n3_first_rise/){$n3_first_rise = (split(/=\s+/,$_))[1];}
         }#while reading log file
         close(READ_LOG);
         if($n3_first_rise ne ""){
           $n3_transistion_found_for_hold = 1;
           $power_param_for_hold++;
         }else {
           $n3_transistion_found_for_hold = 0;
           my $before_power_param = ($power_param_for_hold -1);
           my $divisor = 2**$before_power_param;
           my $n1_n1_delay = (10e-09/$divisor);
           my $hold_time_for_rise = $n1_n1_delay - $set_up_time_for_rise_second;
           my $hold_time_for_rise_nanosecond = $hold_time_for_rise*(10**9);
           push (@hold_time_list_for_rise,$hold_time_for_rise_nanosecond);
         }#else
         }#while n3_transistion_found_for_hold
       }#else
    }elsif($set_up_time_for_rise_nanosecond ne "" && $setup_time_positive_for_rise == 1){
       my $n3firstrise = "";
       my $set_up_time_for_rise_second = $set_up_time_for_rise_nanosecond.""."e-9"; 
       open(WRITE,">$file-hold_for_rise-n1_n1_delay_0-$input_slew_data-$input_slew_clk");
       print WRITE ".title Fanout Versus Delay (TSMC)\n";
       print WRITE "\n";
       print WRITE ".param vdd=$vdd_pri_val\n";
       print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
       print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
       print WRITE ".param vss=$vss_val\n";
       print WRITE ".param wp=$wp\n";
       print WRITE ".param wn=$wn\n";
       print WRITE ".param vlo='0.2*vdd'\n";
       print WRITE ".param vmid='0.5*vdd'\n";
       print WRITE ".param vhi='0.8*vdd'\n";
       print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
       print WRITE ".param inputslew=$input_slew_data_value_with_unit\n";
       print WRITE ".param inputslew_clock=$input_slew_clk_value_with_unit\n";
       print WRITE ".param v0=vss\n"; 
       print WRITE ".param v1=vss\n";
       print WRITE ".param v2=vlo\n";
       print WRITE ".param v3=vhi\n";
       print WRITE ".param v4=vdd\n";
       print WRITE ".param v5=vdd\n";
       print WRITE ".param v6=vhi\n";
       print WRITE ".param v7=vlo\n";
       print WRITE ".param v8=vss\n";
       print WRITE ".param v9=vss\n";
       print WRITE ".param setup_time=$set_up_time_for_rise_second\n";
       print WRITE ".param powerparam=0\n";
       print WRITE ".param divisor='2**powerparam'\n";
       print WRITE "*.param n1_n1_delay='10e-09/divisor'\n";
       print WRITE ".param n1_n1_delay=0\n";
       print WRITE "\n";
       print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
       print WRITE ".param t1='inputslew*10/6*1.0'\n";
       print WRITE ".param t2='inputslew*10/6*1.2'\n";
       print WRITE ".param t3='inputslew*10/6*1.8'\n";
       print WRITE ".param t4='inputslew*10/6*2.0'\n";
       print WRITE ".param t5='t4 + setup_time'\n";
       print WRITE "\n";
       print WRITE ".param t_0='t0 - n1_n1_delay + setup_time'\n"; 
       print WRITE ".param t_1='t_0 + inputslew_clock*10/6*1.0'\n";
       print WRITE ".param t_2='t_0 + inputslew_clock*10/6*1.2'\n";
       print WRITE ".param t_3='t_0 + inputslew_clock*10/6*1.8'\n";
       print WRITE ".param t_4='t_0 + inputslew_clock*10/6*2.0'\n";
       print WRITE ".param t_5='t_0 + inputslew_clock*10/6*3.0'\n";
       print WRITE "\n";
       print WRITE ".param t_sec0='t5 + n1_n1_delay'\n";
       print WRITE ".param t_sec1='t_sec0 + inputslew*10/6*0.2'\n"; 
       print WRITE ".param t_sec2='t_sec0 + inputslew*10/6*0.8'\n";
       print WRITE ".param t_sec3='t_sec0 + inputslew*10/6*1.0'\n";
       print WRITE ".param t_sec4='t_sec0 + inputslew*10/6*2.0'\n";
       print WRITE "\n";
       print WRITE ".nodeset v(n3)=vss\n";
       print WRITE "\n";
       print WRITE "vdd vdd 0 vdd\n";
       print WRITE "vddsec vddsec 0 vddsec\n";
       print WRITE "vss vss 0   vss\n";
       print WRITE "\n";
       print WRITE "vin n2 vss pwl(\n";
       print WRITE "+               t_0   v0\n"; 
       print WRITE "+               t_1   v1\n";
       print WRITE "+               t_2   v2\n";
       print WRITE "+               t_3   v3\n";
       print WRITE "+               t_4   v4\n";
       print WRITE "+               t_5   v5\n";
       print WRITE "+             )\n";
       print WRITE "\n";
       print WRITE "vin0 n1 vss pwl(\n";
       print WRITE "+               t0       v0\n"; 
       print WRITE "+               t1       v1\n";
       print WRITE "+               t2       v2\n";
       print WRITE "+               t3       v3\n";
       print WRITE "+               t4       v4\n";
       print WRITE "+               t5       v5\n";
       print WRITE "+               t_sec0   v4\n";
       print WRITE "+               t_sec1   v3\n";
       print WRITE "+               t_sec2   v2\n";
       print WRITE "+               t_sec3   v1\n";
       print WRITE "+               t_sec4   v0\n";
       print WRITE "+             )\n";
       print WRITE ".MODEL n NMOS\n";
       print WRITE ".MODEL p PMOS\n";
       print WRITE ".MODEL nd NMOS\n";
       print WRITE ".MODEL pd PMOS\n";
       print WRITE "\n";
       print WRITE "\n";
       print WRITE ".include $new_file_spice\n";
       print WRITE "x$cellName @get_new_port_list $cellName\n";
       print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
       print WRITE "C1 $output_port 0 opcap\n";
       print WRITE "\n";
       print WRITE ".temp 85\n";
       print WRITE ".tran 10p 500n\n";
       print WRITE "\n";
       print WRITE ".meas tran n3_first_rise when v(n3)=vhi rise=1\n";
       print WRITE "\n";
       print WRITE ".end\n";
       close (WRITE);
       ##############################################################################################################################
       system("ngspice -b -o $file-hold_for_rise-n1_n1_delay_0-$input_slew_data-$input_slew_clk.log $file-hold_for_rise-n1_n1_delay_0-$input_slew_data-$input_slew_clk"); 
       #------------------------------------------------------------read log file---------------------------------------------------#
       open(READ_LOG,"$file-hold_for_rise-n1_n1_delay_0-$input_slew_data-$input_slew_clk.log");
       while(<READ_LOG>){
       chomp();
         if($_ =~ /^n3_first_rise/){$n3firstrise = (split(/=\s+/,$_))[1];}
       }#while reading log file
       close(READ_LOG);
       if($n3firstrise  ne ""){
         my $hold_time_for_rise = 0;
         my $hold_time_for_rise_nanosecond = $hold_time_for_rise*(10**9);
         push (@hold_time_list_for_rise,$hold_time_for_rise_nanosecond);
       }else {
           my $n3_transistion_found_for_hold = 1;
           my $power_param_for_hold = 0;
         while ($n3_transistion_found_for_hold == 1){
           my $n3_first_rise = "";
         open(WRITE,">$file-hold_for_rise-$input_slew_data-$input_slew_clk-$power_param_for_hold");
         print WRITE ".title Fanout Versus Delay (TSMC)\n";
         print WRITE "\n";
         print WRITE ".param vdd=$vdd_pri_val\n";
         print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
         print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
         print WRITE ".param vss=$vss_val\n";
         print WRITE ".param wp=$wp\n";
         print WRITE ".param wn=$wn\n";
         print WRITE ".param vlo='0.2*vdd'\n";
         print WRITE ".param vmid='0.5*vdd'\n";
         print WRITE ".param vhi='0.8*vdd'\n";
         print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
         print WRITE ".param inputslew=$input_slew_data_value_with_unit\n";
         print WRITE ".param inputslew_clock=$input_slew_clk_value_with_unit\n";
         print WRITE ".param v0=vss\n"; 
         print WRITE ".param v1=vss\n";
         print WRITE ".param v2=vlo\n";
         print WRITE ".param v3=vhi\n";
         print WRITE ".param v4=vdd\n";
         print WRITE ".param v5=vdd\n";
         print WRITE ".param v6=vhi\n";
         print WRITE ".param v7=vlo\n";
         print WRITE ".param v8=vss\n";
         print WRITE ".param v9=vss\n";
         print WRITE ".param setup_time=$set_up_time_for_rise_second\n";
         print WRITE ".param powerparam=$power_param_for_hold\n";
         print WRITE ".param divisor='2**powerparam'\n";
         print WRITE ".param n1_n1_delay='10e-09/divisor'\n";
         print WRITE "*.param n1_n1_delay=0\n";
         print WRITE "\n";
         print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
         print WRITE ".param t1='inputslew*10/6*1.0'\n";
         print WRITE ".param t2='inputslew*10/6*1.2'\n";
         print WRITE ".param t3='inputslew*10/6*1.8'\n";
         print WRITE ".param t4='inputslew*10/6*2.0'\n";
         print WRITE ".param t5='t4 + setup_time'\n";
         print WRITE "\n";
         print WRITE "*.param t_0='t0 - n1_n1_delay + setup_time'\n"; 
         print WRITE ".param t_0='t0  + setup_time'\n"; 
         print WRITE ".param t_1='t_0 + inputslew_clock*10/6*1.0'\n";
         print WRITE ".param t_2='t_0 + inputslew_clock*10/6*1.2'\n";
         print WRITE ".param t_3='t_0 + inputslew_clock*10/6*1.8'\n";
         print WRITE ".param t_4='t_0 + inputslew_clock*10/6*2.0'\n";
         print WRITE ".param t_5='t_0 + inputslew_clock*10/6*3.0'\n";
         print WRITE "\n";
         print WRITE ".param t_sec0='t5 + n1_n1_delay'\n";
         print WRITE ".param t_sec1='t_sec0 + inputslew*10/6*0.2'\n"; 
         print WRITE ".param t_sec2='t_sec0 + inputslew*10/6*0.8'\n";
         print WRITE ".param t_sec3='t_sec0 + inputslew*10/6*1.0'\n";
         print WRITE ".param t_sec4='t_sec0 + inputslew*10/6*2.0'\n";
         print WRITE "\n";
         print WRITE ".nodeset v(n3)=vss\n";
         print WRITE "\n";
         print WRITE "vdd vdd 0 vdd\n";
         print WRITE "vddsec vddsec 0 vddsec\n";
         print WRITE "vss vss 0   vss\n";
         print WRITE "\n";
         print WRITE "vin n2 vss pwl(\n";
         print WRITE "+               t_0   v0\n"; 
         print WRITE "+               t_1   v1\n";
         print WRITE "+               t_2   v2\n";
         print WRITE "+               t_3   v3\n";
         print WRITE "+               t_4   v4\n";
         print WRITE "+               t_5   v5\n";
         print WRITE "+             )\n";
         print WRITE "\n";
         print WRITE "vin0 n1 vss pwl(\n";
         print WRITE "+               t0       v0\n"; 
         print WRITE "+               t1       v1\n";
         print WRITE "+               t2       v2\n";
         print WRITE "+               t3       v3\n";
         print WRITE "+               t4       v4\n";
         print WRITE "+               t5       v5\n";
         print WRITE "+               t_sec0   v4\n";
         print WRITE "+               t_sec1   v3\n";
         print WRITE "+               t_sec2   v2\n";
         print WRITE "+               t_sec3   v1\n";
         print WRITE "+               t_sec4   v0\n";
         print WRITE "+             )\n";
         print WRITE ".MODEL n NMOS\n";
         print WRITE ".MODEL p PMOS\n";
         print WRITE ".MODEL nd NMOS\n";
         print WRITE ".MODEL pd PMOS\n";
         print WRITE "\n";
         print WRITE "\n";
         print WRITE ".include $new_file_spice\n";
         print WRITE "x$cellName @get_new_port_list $cellName\n";
         print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
         print WRITE "C1 $output_port 0 opcap\n";
         print WRITE "\n";
         print WRITE ".temp 85\n";
         print WRITE ".tran 10p 500n\n";
         print WRITE "\n";
         print WRITE ".meas tran n3_first_rise when v(n3)=vhi rise=1\n";
         print WRITE "\n";
         print WRITE ".end\n";
         close (WRITE);
         ############################################################################################################################
         system ("ngspice -b -o $file-hold_for_rise-$input_slew_data-$input_slew_clk-$power_param_for_hold.log $file-hold_for_rise-$input_slew_data-$input_slew_clk-$power_param_for_hold");
         #-------------------------------------------------read log file------------------------------------------------------------# 
         open(READ_LOG,"$file-hold_for_rise-$input_slew_data-$input_slew_clk-$power_param_for_hold.log");
         while(<READ_LOG>){
         chomp();
           if($_ =~ /^n3_first_rise/){$n3_first_rise = (split(/=\s+/,$_))[1];}
         }#while reading log file
         close(READ_LOG);
         if($n3_first_rise ne ""){
           $n3_transistion_found_for_hold = 1;
           $power_param_for_hold++;
         }else {
           $n3_transistion_found_for_hold = 0;
           my $before_power_param = ($power_param_for_hold -1);
           my $divisor = 2**$before_power_param;
           my $n1_n1_delay = (10e-09/$divisor); 
           my $hold_time_for_rise = $n1_n1_delay;
           my $hold_time_for_rise_nanosecond = $hold_time_for_rise*(10**9);
           push (@hold_time_list_for_rise,$hold_time_for_rise_nanosecond);
         }#else
         }#while n3_transistion_found_for_hold
       }#else
    }#elsif
    #----------------------------------------------write test bench for hold time for fall case-------------------------------------#
    if($set_up_time_for_fall_nanosecond ne "" && $setup_time_negative_for_fall == 1){
      my $n3firstfall = "";
      my $set_up_time_for_fall_second = $set_up_time_for_fall_nanosecond.""."e-9"; 
      open(WRITE,">$file-hold_for_fall-n1_n1_delay_0-$input_slew_data-$input_slew_clk");
      print WRITE ".title Fanout Versus Delay (TSMC)\n";
      print WRITE "\n";
      print WRITE ".param vdd=$vdd_pri_val\n";
      print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
      print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
      print WRITE ".param vss=$vss_val\n";
      print WRITE ".param wp=$wp\n";
      print WRITE ".param wn=$wn\n";
      print WRITE ".param vlo='0.2*vdd'\n";
      print WRITE ".param vmid='0.5*vdd'\n";
      print WRITE ".param vhi='0.8*vdd'\n";
      print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
      print WRITE ".param inputslew=$input_slew_data_value_with_unit\n";
      print WRITE ".param inputslew_clock=$input_slew_clk_value_with_unit\n";
      print WRITE ".param v0=vss\n"; 
      print WRITE ".param v1=vss\n";
      print WRITE ".param v2=vlo\n";
      print WRITE ".param v3=vhi\n";
      print WRITE ".param v4=vdd\n";
      print WRITE ".param v5=vdd\n";
      print WRITE ".param v6=vhi\n";
      print WRITE ".param v7=vlo\n";
      print WRITE ".param v8=vss\n";
      print WRITE ".param v9=vss\n";
      print WRITE ".param setup_time=$set_up_time_for_fall_second\n";
      print WRITE ".param powerparam=0\n";
      print WRITE ".param divisor='2**powerparam'\n";
      print WRITE "*.param n1_n1_delay='10e-09/divisor'\n";
      print WRITE ".param n1_n1_delay=0\n";
      print WRITE "\n";
      print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
      print WRITE ".param t1='inputslew*10/6*1.0'\n";
      print WRITE ".param t2='inputslew*10/6*1.2'\n";
      print WRITE ".param t3='inputslew*10/6*1.8'\n";
      print WRITE ".param t4='inputslew*10/6*2.0'\n";
      print WRITE ".param t5='t4 + 0'\n";
      print WRITE "\n";
      print WRITE ".param t_0='t0 - n1_n1_delay + setup_time'\n"; 
      print WRITE ".param t_1='t_0 + inputslew_clock*10/6*1.0'\n";
      print WRITE ".param t_2='t_0 + inputslew_clock*10/6*1.2'\n";
      print WRITE ".param t_3='t_0 + inputslew_clock*10/6*1.8'\n";
      print WRITE ".param t_4='t_0 + inputslew_clock*10/6*2.0'\n";
      print WRITE ".param t_5='t_0 + inputslew_clock*10/6*3.0'\n";
      print WRITE "\n";
      print WRITE ".param t_sec0='t5 + n1_n1_delay'\n";
      print WRITE ".param t_sec1='t_sec0 + inputslew*10/6*0.2'\n"; 
      print WRITE ".param t_sec2='t_sec0 + inputslew*10/6*0.8'\n";
      print WRITE ".param t_sec3='t_sec0 + inputslew*10/6*1.0'\n";
      print WRITE ".param t_sec4='t_sec0 + inputslew*10/6*2.0'\n";
      print WRITE "\n";
      print WRITE ".nodeset v(n3)=vdd\n";
      print WRITE "\n";
      print WRITE "vdd vdd 0 vdd\n";
      print WRITE "vddsec vddsec 0 vddsec\n";
      print WRITE "vss vss 0   vss\n";
      print WRITE "\n";
      print WRITE "vin n2 vss pwl(\n";
      print WRITE "+               t_0   v0\n"; 
      print WRITE "+               t_1   v1\n";
      print WRITE "+               t_2   v2\n";
      print WRITE "+               t_3   v3\n";
      print WRITE "+               t_4   v4\n";
      print WRITE "+               t_5   v5\n";
      print WRITE "+             )\n";
      print WRITE "\n";
      print WRITE "vin0 n1 vss pwl(\n";
      print WRITE "+               t0       v5\n"; 
      print WRITE "+               t1       v4\n";
      print WRITE "+               t2       v3\n";
      print WRITE "+               t3       v2\n";
      print WRITE "+               t4       v1\n";
      print WRITE "+               t5       v0\n";
      print WRITE "+               t_sec0   v1\n";
      print WRITE "+               t_sec1   v2\n";
      print WRITE "+               t_sec2   v3\n";
      print WRITE "+               t_sec3   v4\n";
      print WRITE "+               t_sec4   v5\n";
      print WRITE "+             )\n";
      print WRITE ".MODEL n NMOS\n";
      print WRITE ".MODEL p PMOS\n";
      print WRITE ".MODEL nd NMOS\n";
      print WRITE ".MODEL pd PMOS\n";
      print WRITE "\n";
      print WRITE "\n";
      print WRITE ".include $new_file_spice\n";
      print WRITE "x$cellName @get_new_port_list $cellName\n";
      print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
      print WRITE "C1 $output_port 0 opcap\n";
      print WRITE "\n";
      print WRITE ".temp 85\n";
      print WRITE ".tran 10p 500n\n";
      print WRITE "\n";
      print WRITE ".meas tran n3_first_fall when v(n3)=vlo fall=1\n";
      print WRITE "\n";
      print WRITE ".end\n";
      close (WRITE);
      #############################################################################################################################
      system ("ngspice -b -o $file-hold_for_fall-n1_n1_delay_0-$input_slew_data-$input_slew_clk.log $file-hold_for_fall-n1_n1_delay_0-$input_slew_data-$input_slew_clk"); 
      #-------------------------------------------------------read log file-------------------------------------------------------#
      open(READ_LOG,"$file-hold_for_fall-n1_n1_delay_0-$input_slew_data-$input_slew_clk.log");
      while(<READ_LOG>){
      chomp();
        if($_ =~ /^n3_first_fall/){$n3firstfall = (split(/=\s+/,$_))[1];}
      }#while reading log file
      close(READ_LOG);
      if($n3firstfall ne ""){
         my $hold_time_for_fall_nanosecond = -1*$set_up_time_for_fall_nanosecond;
         push (@hold_time_list_for_fall,$hold_time_for_fall_nanosecond);
      }else{
        my $n3_transistion_found_for_hold = 1;
        my $power_param_for_hold = 0;
        while ($n3_transistion_found_for_hold == 1){
          my $n3_first_fall = "";
          open(WRITE,">$file-hold_for_fall-$input_slew_data-$input_slew_clk-$power_param_for_hold");
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_data_value_with_unit\n";
          print WRITE ".param inputslew_clock=$input_slew_clk_value_with_unit\n";
          print WRITE ".param v0=vss\n"; 
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE ".param setup_time=$set_up_time_for_fall_second\n";
          print WRITE ".param powerparam=$power_param_for_hold\n";
          print WRITE ".param divisor='2**powerparam'\n";
          print WRITE ".param n1_n1_delay='10e-09/divisor'\n";
          print WRITE "*.param n1_n1_delay=0\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*1.8'\n";
          print WRITE ".param t4='inputslew*10/6*2.0'\n";
          print WRITE ".param t5='t4 + 0'\n";
          print WRITE "\n";
          print WRITE "*.param t_0='t0 - n1_n1_delay + setup_time'\n"; 
          print WRITE ".param t_0='t0  + setup_time'\n"; 
          print WRITE ".param t_1='t_0 + inputslew_clock*10/6*1.0'\n";
          print WRITE ".param t_2='t_0 + inputslew_clock*10/6*1.2'\n";
          print WRITE ".param t_3='t_0 + inputslew_clock*10/6*1.8'\n";
          print WRITE ".param t_4='t_0 + inputslew_clock*10/6*2.0'\n";
          print WRITE ".param t_5='t_0 + inputslew_clock*10/6*3.0'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='t5 + n1_n1_delay'\n";
          print WRITE ".param t_sec1='t_sec0 + inputslew*10/6*0.2'\n"; 
          print WRITE ".param t_sec2='t_sec0 + inputslew*10/6*0.8'\n";
          print WRITE ".param t_sec3='t_sec0 + inputslew*10/6*1.0'\n";
          print WRITE ".param t_sec4='t_sec0 + inputslew*10/6*2.0'\n";
          print WRITE "\n";
          print WRITE ".nodeset v(n3)=vdd\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0   vss\n";
          print WRITE "\n";
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t_0   v0\n"; 
          print WRITE "+               t_1   v1\n";
          print WRITE "+               t_2   v2\n";
          print WRITE "+               t_3   v3\n";
          print WRITE "+               t_4   v4\n";
          print WRITE "+               t_5   v5\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0       v5\n"; 
          print WRITE "+               t1       v4\n";
          print WRITE "+               t2       v3\n";
          print WRITE "+               t3       v2\n";
          print WRITE "+               t4       v1\n";
          print WRITE "+               t5       v0\n";
          print WRITE "+               t_sec0   v1\n";
          print WRITE "+               t_sec1   v2\n";
          print WRITE "+               t_sec2   v3\n";
          print WRITE "+               t_sec3   v4\n";
          print WRITE "+               t_sec4   v5\n";
          print WRITE "+             )\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE ".meas tran n3_first_fall when v(n3)=vlo fall=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close(WRITE);
          ##########################################################################################################################
          system ("ngspice -b -o $file-hold_for_fall-$input_slew_data-$input_slew_clk-$power_param_for_hold.log $file-hold_for_fall-$input_slew_data-$input_slew_clk-$power_param_for_hold"); 
          #----------------------------------------------------------------read log file-------------------------------------------#
          open(READ_LOG,"$file-hold_for_fall-$input_slew_data-$input_slew_clk-$power_param_for_hold.log");
          while(<READ_LOG>){
          chomp();
            if($_ =~ /^n3_first_fall/){$n3_first_fall = (split(/=\s+/,$_))[1];}
          }#while reading log file
          close(READ_LOG);
          if($n3_first_fall ne ""){
             $n3_transistion_found_for_hold = 1; 
             $power_param_for_hold++;
          }else{
            $n3_transistion_found_for_hold = 0;
            my $before_power_param = ($power_param_for_hold -1);
            my $divisor  = 2**$before_power_param;
            my $n1_n1_delay = (10e-09/$divisor);
            my $hold_time_for_fall = $n1_n1_delay - $set_up_time_for_fall_second;
            my $hold_time_for_fall_nanosecond = $hold_time_for_fall*(10**9);
            push (@hold_time_list_for_fall,$hold_time_for_fall_nanosecond);
          }#else
        }#while n3_transistion_found_for_hold
      }#else
    }elsif($set_up_time_for_fall_nanosecond ne "" && $setup_time_positive_for_fall == 1){
       my $n3firstfall = "";
       my $set_up_time_for_fall_second = $set_up_time_for_fall_nanosecond.""."e-9";
       open(WRITE,">$file-hold_for_fall-n1_n1_delay_0-$input_slew_data-$input_slew_clk");
       print WRITE ".title Fanout Versus Delay (TSMC)\n";
       print WRITE "\n";
       print WRITE ".param vdd=$vdd_pri_val\n";
       print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
       print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
       print WRITE ".param vss=$vss_val\n";
       print WRITE ".param wp=$wp\n";
       print WRITE ".param wn=$wn\n";
       print WRITE ".param vlo='0.2*vdd'\n";
       print WRITE ".param vmid='0.5*vdd'\n";
       print WRITE ".param vhi='0.8*vdd'\n";
       print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
       print WRITE ".param inputslew=$input_slew_data_value_with_unit\n";
       print WRITE ".param inputslew_clock=$input_slew_clk_value_with_unit\n";
       print WRITE ".param v0=vss\n"; 
       print WRITE ".param v1=vss\n";
       print WRITE ".param v2=vlo\n";
       print WRITE ".param v3=vhi\n";
       print WRITE ".param v4=vdd\n";
       print WRITE ".param v5=vdd\n";
       print WRITE ".param v6=vhi\n";
       print WRITE ".param v7=vlo\n";
       print WRITE ".param v8=vss\n";
       print WRITE ".param v9=vss\n";
       print WRITE ".param setup_time=$set_up_time_for_fall_second\n";
       print WRITE ".param powerparam=0\n";
       print WRITE ".param divisor='2**powerparam'\n";
       print WRITE "*.param n1_n1_delay='10e-09/divisor'\n";
       print WRITE ".param n1_n1_delay=0\n";
       print WRITE "\n";
       print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
       print WRITE ".param t1='inputslew*10/6*1.0'\n";
       print WRITE ".param t2='inputslew*10/6*1.2'\n";
       print WRITE ".param t3='inputslew*10/6*1.8'\n";
       print WRITE ".param t4='inputslew*10/6*2.0'\n";
       print WRITE ".param t5='t4 + setup_time'\n";
       print WRITE "\n";
       print WRITE ".param t_0='t0 - n1_n1_delay + setup_time'\n"; 
       print WRITE ".param t_1='t_0 + inputslew_clock*10/6*1.0'\n";
       print WRITE ".param t_2='t_0 + inputslew_clock*10/6*1.2'\n";
       print WRITE ".param t_3='t_0 + inputslew_clock*10/6*1.8'\n";
       print WRITE ".param t_4='t_0 + inputslew_clock*10/6*2.0'\n";
       print WRITE ".param t_5='t_0 + inputslew_clock*10/6*3.0'\n";
       print WRITE "\n";
       print WRITE ".param t_sec0='t5 + n1_n1_delay'\n";
       print WRITE ".param t_sec1='t_sec0 + inputslew*10/6*0.2'\n"; 
       print WRITE ".param t_sec2='t_sec0 + inputslew*10/6*0.8'\n";
       print WRITE ".param t_sec3='t_sec0 + inputslew*10/6*1.0'\n";
       print WRITE ".param t_sec4='t_sec0 + inputslew*10/6*2.0'\n";
       print WRITE "\n";
       print WRITE ".nodeset v(n3)=vdd\n";
       print WRITE "\n";
       print WRITE "vdd vdd 0 vdd\n";
       print WRITE "vddsec vddsec 0 vddsec\n";
       print WRITE "vss vss 0   vss\n";
       print WRITE "\n";
       print WRITE "vin n2 vss pwl(\n";
       print WRITE "+               t_0   v0\n"; 
       print WRITE "+               t_1   v1\n";
       print WRITE "+               t_2   v2\n";
       print WRITE "+               t_3   v3\n";
       print WRITE "+               t_4   v4\n";
       print WRITE "+               t_5   v5\n";
       print WRITE "+             )\n";
       print WRITE "\n";
       print WRITE "vin0 n1 vss pwl(\n";
       print WRITE "+               t0       v5\n"; 
       print WRITE "+               t1       v4\n";
       print WRITE "+               t2       v3\n";
       print WRITE "+               t3       v2\n";
       print WRITE "+               t4       v1\n";
       print WRITE "+               t5       v0\n";
       print WRITE "+               t_sec0   v1\n";
       print WRITE "+               t_sec1   v2\n";
       print WRITE "+               t_sec2   v3\n";
       print WRITE "+               t_sec3   v4\n";
       print WRITE "+               t_sec4   v5\n";
       print WRITE "+             )\n";
       print WRITE ".MODEL n NMOS\n";
       print WRITE ".MODEL p PMOS\n";
       print WRITE ".MODEL nd NMOS\n";
       print WRITE ".MODEL pd PMOS\n";
       print WRITE "\n";
       print WRITE "\n";
       print WRITE ".include $new_file_spice\n";
       print WRITE "x$cellName @get_new_port_list $cellName\n";
       print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
       print WRITE "C1 $output_port 0 opcap\n";
       print WRITE "\n";
       print WRITE ".temp 85\n";
       print WRITE ".tran 10p 500n\n";
       print WRITE "\n";
       print WRITE ".meas tran n3_first_fall when v(n3)=vlo fall=1\n";
       print WRITE "\n";
       print WRITE ".end\n";
       close (WRITE);
       ###########################################################################################################################
       system("ngspice -b -o $file-hold_for_fall-n1_n1_delay_0-$input_slew_data-$input_slew_clk.log $file-hold_for_fall-n1_n1_delay_0-$input_slew_data-$input_slew_clk");
       #--------------------------------------------------read log file----------------------------------------------------------#
       open(READ_LOG,"$file-hold_for_fall-n1_n1_delay_0-$input_slew_data-$input_slew_clk.log");
       while(<READ_LOG>){
       chomp();
         if($_ =~ /^n3_first_fall/){$n3firstfall = (split(/=\s+/,$_))[1];}
       }#while reading log file
       close(READ_LOG);
       if($n3firstfall ne ""){
         my $hold_time_for_fall_nanosecond = 0;
#         my $hold_time_for_fall_nanosecond = $hold_time_for_fall*(10**9);
         push (@hold_time_list_for_fall,$hold_time_for_fall_nanosecond);
       }else{
         my $n3_transistion_found_for_hold = 1;
         my $power_param_for_hold = 0;
         while ($n3_transistion_found_for_hold == 1){
           my $n3_first_fall = "";
           open(WRITE,">$file-hold_for_fall-$input_slew_data-$input_slew_clk-$power_param_for_hold");
           print WRITE ".title Fanout Versus Delay (TSMC)\n";
           print WRITE "\n";
           print WRITE ".param vdd=$vdd_pri_val\n";
           print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
           print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
           print WRITE ".param vss=$vss_val\n";
           print WRITE ".param wp=$wp\n";
           print WRITE ".param wn=$wn\n";
           print WRITE ".param vlo='0.2*vdd'\n";
           print WRITE ".param vmid='0.5*vdd'\n";
           print WRITE ".param vhi='0.8*vdd'\n";
           print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
           print WRITE ".param inputslew=$input_slew_data_value_with_unit\n";
           print WRITE ".param inputslew_clock=$input_slew_clk_value_with_unit\n";
           print WRITE ".param v0=vss\n"; 
           print WRITE ".param v1=vss\n";
           print WRITE ".param v2=vlo\n";
           print WRITE ".param v3=vhi\n";
           print WRITE ".param v4=vdd\n";
           print WRITE ".param v5=vdd\n";
           print WRITE ".param v6=vhi\n";
           print WRITE ".param v7=vlo\n";
           print WRITE ".param v8=vss\n";
           print WRITE ".param v9=vss\n";
           print WRITE ".param setup_time=$set_up_time_for_fall_second\n";
           print WRITE ".param powerparam=$power_param_for_hold\n";
           print WRITE ".param divisor='2**powerparam'\n";
           print WRITE ".param n1_n1_delay='10e-09/divisor'\n";
           print WRITE "*.param n1_n1_delay=0\n";
           print WRITE "\n";
           print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
           print WRITE ".param t1='inputslew*10/6*1.0'\n";
           print WRITE ".param t2='inputslew*10/6*1.2'\n";
           print WRITE ".param t3='inputslew*10/6*1.8'\n";
           print WRITE ".param t4='inputslew*10/6*2.0'\n";
           print WRITE ".param t5='t4 + setup_time'\n";
           print WRITE "\n";
           print WRITE "*.param t_0='t0 - n1_n1_delay + setup_time'\n"; 
           print WRITE ".param t_0='t0  + setup_time'\n"; 
           print WRITE ".param t_1='t_0 + inputslew_clock*10/6*1.0'\n";
           print WRITE ".param t_2='t_0 + inputslew_clock*10/6*1.2'\n";
           print WRITE ".param t_3='t_0 + inputslew_clock*10/6*1.8'\n";
           print WRITE ".param t_4='t_0 + inputslew_clock*10/6*2.0'\n";
           print WRITE ".param t_5='t_0 + inputslew_clock*10/6*3.0'\n";
           print WRITE "\n";
           print WRITE ".param t_sec0='t5 + n1_n1_delay'\n";
           print WRITE ".param t_sec1='t_sec0 + inputslew*10/6*0.2'\n"; 
           print WRITE ".param t_sec2='t_sec0 + inputslew*10/6*0.8'\n";
           print WRITE ".param t_sec3='t_sec0 + inputslew*10/6*1.0'\n";
           print WRITE ".param t_sec4='t_sec0 + inputslew*10/6*2.0'\n";
           print WRITE "\n";
           print WRITE ".nodeset v(n3)=vdd\n";
           print WRITE "\n";
           print WRITE "vdd vdd 0 vdd\n";
           print WRITE "vddsec vddsec 0 vddsec\n";
           print WRITE "vss vss 0   vss\n";
           print WRITE "\n";
           print WRITE "vin n2 vss pwl(\n";
           print WRITE "+               t_0   v0\n"; 
           print WRITE "+               t_1   v1\n";
           print WRITE "+               t_2   v2\n";
           print WRITE "+               t_3   v3\n";
           print WRITE "+               t_4   v4\n";
           print WRITE "+               t_5   v5\n";
           print WRITE "+             )\n";
           print WRITE "\n";
           print WRITE "vin0 n1 vss pwl(\n";
           print WRITE "+               t0       v5\n"; 
           print WRITE "+               t1       v4\n";
           print WRITE "+               t2       v3\n";
           print WRITE "+               t3       v2\n";
           print WRITE "+               t4       v1\n";
           print WRITE "+               t5       v0\n";
           print WRITE "+               t_sec0   v1\n";
           print WRITE "+               t_sec1   v2\n";
           print WRITE "+               t_sec2   v3\n";
           print WRITE "+               t_sec3   v4\n";
           print WRITE "+               t_sec4   v5\n";
           print WRITE "+             )\n";
           print WRITE ".MODEL n NMOS\n";
           print WRITE ".MODEL p PMOS\n";
           print WRITE ".MODEL nd NMOS\n";
           print WRITE ".MODEL pd PMOS\n";
           print WRITE "\n";
           print WRITE "\n";
           print WRITE ".include $new_file_spice\n";
           print WRITE "x$cellName @get_new_port_list $cellName\n";
           print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
           print WRITE "C1 $output_port 0 opcap\n";
           print WRITE "\n";
           print WRITE ".temp 85\n";
           print WRITE ".tran 10p 500n\n";
           print WRITE "\n";
           print WRITE ".meas tran n3_first_fall when v(n3)=vlo fall=1\n";
           print WRITE "\n";
           print WRITE ".end\n";
           close (WRITE);
           #######################################################################################################################
           system ("ngspice -b -o $file-hold_for_fall-$input_slew_data-$input_slew_clk-$power_param_for_hold.log $file-hold_for_fall-$input_slew_data-$input_slew_clk-$power_param_for_hold");
           #--------------------------------------------------read log file------------------------------------------------------#
           open(READ_LOG,"$file-hold_for_fall-$input_slew_data-$input_slew_clk-$power_param_for_hold.log");
           while(<READ_LOG>){
           chomp();
             if($_ =~ /^n3_first_fall/){$n3_first_fall = (split(/=\s+/,$_))[1];}
           }#while reading log file
           close(READ_LOG);
           if($n3_first_fall ne ""){
             $n3_transistion_found_for_hold = 1; 
             $power_param_for_hold++;
           }else{
             $n3_transistion_found_for_hold = 0;
             my $before_power_param = ($power_param_for_hold -1);
             my $divisor = 2**$before_power_param;
             my $n1_n1_delay = (10e-09/$divisor);
             my $hold_time_for_fall = $n1_n1_delay;
             my $hold_time_for_fall_nanosecond = $hold_time_for_fall*(10**9);
             push (@hold_time_list_for_fall,$hold_time_for_fall_nanosecond);
           }#else 
         }#while n3_transistion_found_for_hold
       }#else
    }#elsif
  }#for input_slew_data
}#for input_slew_clk
#--------------------------------------------------end test bench for setup and hold time------------------------------------#
#-------------------------------------------------create genlib and calculate dclkrise and dclkfall--------------------------#
open(WRITE_GENLIB,">$cellName.genlib");
  print WRITE_GENLIB "LIBNAME typical\n";
  print WRITE_GENLIB "GATE $cellName 3.2\n";
  print WRITE_GENLIB "  index_1 @input_slew\n";
  print WRITE_GENLIB "  index_2 @opcap\n";
  print WRITE_GENLIB "  PIN $in NONINV input\n";
  print WRITE_GENLIB "   in_index_1 @input_slew\n";
  print WRITE_GENLIB "   in_index_2 @input_slew_clock\n";
  print WRITE_GENLIB "   related_pin $clk \n";
  print WRITE_GENLIB "      timing_type : setup_rising\n";
  print WRITE_GENLIB "        rise_constraint @setup_time_list_for_rise\n";
  print WRITE_GENLIB "        fall_constraint @setup_time_list_for_fall\n";
  print WRITE_GENLIB "      timing_type : hold_rising\n";
  print WRITE_GENLIB "        rise_constraint @hold_time_list_for_rise\n";
  print WRITE_GENLIB "        fall_constraint @hold_time_list_for_fall\n";
  print WRITE_GENLIB "  PIN $clk NONINV input\n";
  print WRITE_GENLIB "    clock  true\n";
  print WRITE_GENLIB "  PIN RN NONINV input\n" if($reset_exists == 1);
  print WRITE_GENLIB "   in_index_1 0.0300 0.9000 3.0000\n" if($reset_exists == 1);
  print WRITE_GENLIB "   in_index_2 0.0300 3.0000\n" if($reset_exists == 1);
  print WRITE_GENLIB "   related_pin  CK\n" if($reset_exists == 1);
  print WRITE_GENLIB "      timing_type : recovery_rising\n" if($reset_exists == 1);
  print WRITE_GENLIB "        rise_constraint 0.1172 0.1875 0.1563 0.2187 0.0625 0.1328\n" if($reset_exists == 1);
  print WRITE_GENLIB "  output $out\n";
  print WRITE_GENLIB "  clocked_on $clk\n";
  print WRITE_GENLIB "  input $in\n";
  print WRITE_GENLIB "  reset RN'\n" if($reset_exists == 1); 
  print WRITE_GENLIB "  PIN $out NONINV output\n";
  print WRITE_GENLIB "    function : IQ\n";
  print WRITE_GENLIB "      related_pin $clk\n";
  print WRITE_GENLIB "      timing_type : rising_edge\n";
  print WRITE_GENLIB "      timing_sense : non_unate\n";
#----------------------------------------------------------------------------------------------------#
my $ns = @input_slew;
my $nopcap = @opcap; 
my @dclkrise_list = ();
my @dclkfall_list = ();
  for (my $i =0; $i<$ns;$i++){
    for(my $j=0; $j<$nopcap;$j++){
      my $input_slew_value = $input_slew[$i];
      my $input_slew_value_with_unit = $input_slew[$i].""."e-9";
      my $op_cap = $opcap[$j];
      my $op_cap_with_unit = $opcap[$j].""."e-12";
      if($get_clk_val == 0 && $get_n1_val == 0 && $get_n3_val eq "vdd"){
      #--------------------------------------write test bench for dclkfall---------------------------#
        open(WRITE,">$file-dclkfall-$input_slew_value-$op_cap-clk_$get_clk_val-n1_$get_n1_val-n3_$get_n3_val");
        print WRITE ".title Fanout Versus Delay (TSMC)\n";
        print WRITE "\n";
        print WRITE ".param vdd=$vdd_pri_val\n";
        print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
        print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
        print WRITE ".param vss=$vss_val\n";
        print WRITE ".param wp=$wp\n";
        print WRITE ".param wn=$wn\n";
        print WRITE ".param vlo='0.2*vdd'\n";
        print WRITE ".param vmid='0.5*vdd'\n";
        print WRITE ".param vhi='0.8*vdd'\n";
        print WRITE ".param opcap=$op_cap_with_unit\n";
        print WRITE ".param inputslew=$input_slew_value_with_unit\n";
        print WRITE ".param v0=vss\n"; 
        print WRITE ".param v1=vss\n";
        print WRITE ".param v2=vlo\n";
        print WRITE ".param v3=vhi\n";
        print WRITE ".param v4=vdd\n";
        print WRITE ".param v5=vdd\n";
        print WRITE ".param v6=vhi\n";
        print WRITE ".param v7=vlo\n";
        print WRITE ".param v8=vss\n";
        print WRITE ".param v9=vss\n";
        print WRITE "\n";
        print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
        print WRITE ".param t1='inputslew*10/6*1.0'\n";
        print WRITE ".param t2='inputslew*10/6*1.2'\n";
        print WRITE ".param t3='inputslew*10/6*1.8'\n";
        print WRITE ".param t4='inputslew*10/6*2.0'\n";
        print WRITE ".param t5='inputslew*10/6*3.0'\n";
        print WRITE ".param t6='inputslew*10/6*3.2'\n";
        print WRITE ".param t7='inputslew*10/6*3.8'\n";
        print WRITE ".param t8='inputslew*10/6*4.0'\n";
        print WRITE ".param t9='inputslew*10/6*5.0'\n";
        print WRITE "\n";
        print WRITE ".param t_sec0='inputslew*10/6*0.0 + inputslew*10/6*5'\n"; 
        print WRITE ".param t_sec1='inputslew*10/6*1.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec2='inputslew*10/6*1.2 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec3='inputslew*10/6*1.8 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec4='inputslew*10/6*2.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec5='inputslew*10/6*3.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec6='inputslew*10/6*3.2 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec7='inputslew*10/6*3.8 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec8='inputslew*10/6*4.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec9='inputslew*10/6*5.0 + inputslew*10/6*5'\n";
        print WRITE "\n";
        print WRITE ".nodeset v(n3)=vdd\n";
        print WRITE "\n";
        print WRITE "vdd vdd 0 vdd\n";
        print WRITE "vddsec vddsec 0 vddsec\n";
        print WRITE "vss vss 0   vss\n";
        print WRITE "\n";
        print WRITE "vin n2 vss pwl(\n";
        print WRITE "+               t0   v5\n"; 
        print WRITE "+               t1   v4\n";
        print WRITE "+               t2   v3\n";
        print WRITE "+               t3   v2\n";
        print WRITE "+               t4   v1\n";
        print WRITE "+               t5   v0\n";
        print WRITE "+             )\n";
        print WRITE "\n";
        print WRITE "vin0 n1 vss pwl(\n";
        print WRITE "+               t0   v0\n";
        print WRITE "+               t1   v0\n";
        print WRITE "+               t2   v0\n";
        print WRITE "+               t3   v0\n";
        print WRITE "+               t4   v0\n";
        print WRITE "+               t5   v0\n";
        print WRITE "+             )\n";
        print WRITE ".MODEL n NMOS\n";
        print WRITE ".MODEL p PMOS\n";
        print WRITE ".MODEL nd NMOS\n";
        print WRITE ".MODEL pd PMOS\n";
        print WRITE "\n";
        print WRITE "\n";
        print WRITE ".include $new_file_spice\n";
        print WRITE "x$cellName @get_new_port_list $cellName\n";
        print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
        print WRITE "C1 $output_port 0 opcap\n";
        print WRITE "\n";
        print WRITE ".temp 85\n";
        print WRITE ".tran 10p 500n\n";
        print WRITE "\n";
        print WRITE ".meas tran n3_first_fall when v(n3)=vmid fall=1\n";
        print WRITE "\n";
        print WRITE ".meas tran dclkfall trig v(n2) val=vmid fall=1\n";
        print WRITE "+                targ v(n3) val=vmid fall=1\n";
        print WRITE "\n";
        print WRITE ".end\n";
        close (WRITE);
        #-----------------------------------------------write test bench for dlclkrise----------------------------------------------------------------------------------------------------------------------------------#
        open(WRITE,">$file-dclkrise-$input_slew_value-$op_cap-clk_$get_clk_val-n1_$get_n1_val-n3_$get_n3_val");
        print WRITE ".title Fanout Versus Delay (TSMC)\n";
        print WRITE "\n";
        print WRITE ".param vdd=$vdd_pri_val\n";
        print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
        print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
        print WRITE ".param vss=$vss_val\n";
        print WRITE ".param wp=$wp\n";
        print WRITE ".param wn=$wn\n";
        print WRITE ".param vlo='0.2*vdd'\n";
        print WRITE ".param vmid='0.5*vdd'\n";
        print WRITE ".param vhi='0.8*vdd'\n";
        print WRITE ".param opcap=$op_cap_with_unit\n";
        print WRITE ".param inputslew=$input_slew_value_with_unit\n";
        print WRITE ".param v0=vss\n"; 
        print WRITE ".param v1=vss\n";
        print WRITE ".param v2=vlo\n";
        print WRITE ".param v3=vhi\n";
        print WRITE ".param v4=vdd\n";
        print WRITE ".param v5=vdd\n";
        print WRITE ".param v6=vhi\n";
        print WRITE ".param v7=vlo\n";
        print WRITE ".param v8=vss\n";
        print WRITE ".param v9=vss\n";
        print WRITE "\n";
        print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
        print WRITE ".param t1='inputslew*10/6*1.0'\n";
        print WRITE ".param t2='inputslew*10/6*1.2'\n";
        print WRITE ".param t3='inputslew*10/6*1.8'\n";
        print WRITE ".param t4='inputslew*10/6*2.0'\n";
        print WRITE ".param t5='inputslew*10/6*3.0'\n";
        print WRITE ".param t6='inputslew*10/6*3.2'\n";
        print WRITE ".param t7='inputslew*10/6*3.8'\n";
        print WRITE ".param t8='inputslew*10/6*4.0'\n";
        print WRITE ".param t9='inputslew*10/6*5.0'\n";
        print WRITE "\n";
        print WRITE ".param t_sec0='inputslew*10/6*0.0 + inputslew*10/6*5'\n"; 
        print WRITE ".param t_sec1='inputslew*10/6*1.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec2='inputslew*10/6*1.2 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec3='inputslew*10/6*1.8 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec4='inputslew*10/6*2.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec5='inputslew*10/6*3.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec6='inputslew*10/6*3.2 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec7='inputslew*10/6*3.8 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec8='inputslew*10/6*4.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec9='inputslew*10/6*5.0 + inputslew*10/6*5'\n";
        print WRITE "\n";
        print WRITE ".nodeset v(n3)=vss\n";
        print WRITE "\n";
        print WRITE "vdd vdd 0 vdd\n";
        print WRITE "vddsec vddsec 0 vddsec\n";
        print WRITE "vss vss 0   vss\n";
        print WRITE "\n";
        print WRITE "vin n2 vss pwl(\n";
        print WRITE "+               t0   v5\n"; 
        print WRITE "+               t1   v4\n";
        print WRITE "+               t2   v3\n";
        print WRITE "+               t3   v2\n";
        print WRITE "+               t4   v1\n";
        print WRITE "+               t5   v0\n";
        print WRITE "+             )\n";
        print WRITE "\n";
        print WRITE "vin0 n1 vss pwl(\n";
        print WRITE "+               t0   v5\n"; 
        print WRITE "+               t1   v5\n";
        print WRITE "+               t2   v5\n";
        print WRITE "+               t3   v5\n";
        print WRITE "+               t4   v5\n";
        print WRITE "+               t5   v5\n";
        print WRITE "+             )\n";
        print WRITE ".MODEL n NMOS\n";
        print WRITE ".MODEL p PMOS\n";
        print WRITE ".MODEL nd NMOS\n";
        print WRITE ".MODEL pd PMOS\n";
        print WRITE "\n";
        print WRITE "\n";
        print WRITE ".include $new_file_spice\n";
        print WRITE "x$cellName @get_new_port_list $cellName\n";
        print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
        print WRITE "C1 $output_port 0 opcap\n";
        print WRITE "\n";
        print WRITE ".temp 85\n";
        print WRITE ".tran 10p 500n\n";
        print WRITE "\n";
        print WRITE ".meas tran n3_first_rise when v(n3)=vmid rise=1\n";
        print WRITE "\n";
        print WRITE ".meas tran dclkrise trig v(n2) val=vmid fall=1\n";
        print WRITE "+                targ v(n3) val=vmid rise=1\n";
        print WRITE "\n";
        print WRITE ".end\n";
        close (WRITE);
        #################################################################################################################################################################################################################
        system ("ngspice -b -o $file-dclkfall-$input_slew_value-$op_cap-clk_$get_clk_val-n1_$get_n1_val-n3_$get_n3_val.log $file-dclkfall-$input_slew_value-$op_cap-clk_$get_clk_val-n1_$get_n1_val-n3_$get_n3_val"); 
        system ("ngspice -b -o $file-dclkrise-$input_slew_value-$op_cap-clk_$get_clk_val-n1_$get_n1_val-n3_$get_n3_val.log $file-dclkrise-$input_slew_value-$op_cap-clk_$get_clk_val-n1_$get_n1_val-n3_$get_n3_val"); 
        #-------------------------------------------------------------------------read log file for dclkfall------------------------------------------------------------------------------------------------------------------------#
        open (READ_NG_LOG,"$file-dclkfall-$input_slew_value-$op_cap-clk_$get_clk_val-n1_$get_n1_val-n3_$get_n3_val.log");
        while(<READ_NG_LOG>){
        chomp();
          if($_ =~ /^dclkfall/){s/\s*dclkfall\s*//;my $dclkfall = (split(/=\s+/,$_))[1];
            $dclkfall =~ s/\s*targ//;
            my ($n,$m) = (split(/e/,$dclkfall))[0,1];
            my $m = $m+9;
            my $dclkfall_new = $n*(10**$m);
            push(@dclkfall_list,$dclkfall_new);
          }
        }#while reading
       close(READ_NG_LOG);
       #------------------------------------------------------------------------read log file for dclkrise---------------------------------------------------------------------------------------------# 
       open(READ_NG_LOG,"$file-dclkrise-$input_slew_value-$op_cap-clk_$get_clk_val-n1_$get_n1_val-n3_$get_n3_val.log");
       while(<READ_NG_LOG>){
       chomp();
         if($_ =~ /^dclkrise/){s/\s*dclkrise\s*//;my $dclkrise = (split(/=\s+/,$_))[1];
           $dclkrise =~ s/\s*targ//;
           my ($n,$m) = (split(/e/,$dclkrise))[0,1];
           my $m = $m+9;
           my $dclkrise_new = $n*(10**$m);
           push(@dclkrise_list,$dclkrise_new);
         }
       }#while reading
       close(READ_NG_LOG);
      #-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
      }elsif($get_clk_val == 1 && $get_n1_val == 0 && $get_n3_val eq "vdd"){
        open(WRITE,">$file-dclkfall-$input_slew_value-$op_cap-clk_$get_clk_val-n1_$get_n1_val-n3_$get_n3_val");
        print WRITE ".title Fanout Versus Delay (TSMC)\n";
        print WRITE "\n";
        print WRITE ".param vdd=$vdd_pri_val\n";
        print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
        print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
        print WRITE ".param vss=$vss_val\n";
        print WRITE ".param wp=$wp\n";
        print WRITE ".param wn=$wn\n";
        print WRITE ".param vlo='0.2*vdd'\n";
        print WRITE ".param vmid='0.5*vdd'\n";
        print WRITE ".param vhi='0.8*vdd'\n";
        print WRITE ".param opcap=$op_cap_with_unit\n";
        print WRITE ".param inputslew=$input_slew_value_with_unit\n";
        print WRITE ".param v0=vss\n";
        print WRITE ".param v1=vss\n";
        print WRITE ".param v2=vlo\n";
        print WRITE ".param v3=vhi\n";
        print WRITE ".param v4=vdd\n";
        print WRITE ".param v5=vdd\n";
        print WRITE ".param v6=vhi\n";
        print WRITE ".param v7=vlo\n";
        print WRITE ".param v8=vss\n";
        print WRITE ".param v9=vss\n";
        print WRITE "\n";
        print WRITE ".param t0='inputslew*10/6*0.0'\n";
        print WRITE ".param t1='inputslew*10/6*1.0'\n";
        print WRITE ".param t2='inputslew*10/6*1.2'\n";
        print WRITE ".param t3='inputslew*10/6*1.8'\n";
        print WRITE ".param t4='inputslew*10/6*2.0'\n";
        print WRITE ".param t5='inputslew*10/6*3.0'\n";
        print WRITE ".param t6='inputslew*10/6*3.2'\n";
        print WRITE ".param t7='inputslew*10/6*3.8'\n";
        print WRITE ".param t8='inputslew*10/6*4.0'\n";
        print WRITE ".param t9='inputslew*10/6*5.0'\n";
        print WRITE "\n";
        print WRITE ".param t_sec0='inputslew*10/6*0.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec1='inputslew*10/6*1.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec2='inputslew*10/6*1.2 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec3='inputslew*10/6*1.8 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec4='inputslew*10/6*2.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec5='inputslew*10/6*3.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec6='inputslew*10/6*3.2 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec7='inputslew*10/6*3.8 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec8='inputslew*10/6*4.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec9='inputslew*10/6*5.0 + inputslew*10/6*5'\n";
        print WRITE "\n";
        print WRITE ".nodeset v(n3)=vdd\n";
        print WRITE "\n";
        print WRITE "vdd vdd 0 vdd\n";
        print WRITE "vddsec vddsec 0 vddsec\n";
        print WRITE "vss vss 0   vss\n";
        print WRITE "\n";
        print WRITE "vin n2 vss pwl(\n";
        print WRITE "+               t0   v0\n";
        print WRITE "+               t1   v1\n";
        print WRITE "+               t2   v2\n";
        print WRITE "+               t3   v3\n";
        print WRITE "+               t4   v4\n";
        print WRITE "+               t5   v5\n";
        print WRITE "+             )\n";
        print WRITE "\n";
        print WRITE "vin0 n1 vss pwl(\n";
        print WRITE "+               t0   v0\n";
        print WRITE "+               t1   v0\n";
        print WRITE "+               t2   v0\n";
        print WRITE "+               t3   v0\n";
        print WRITE "+               t4   v0\n";
        print WRITE "+               t5   v0\n";
        print WRITE "+             )\n";
        print WRITE ".MODEL n NMOS\n";
        print WRITE ".MODEL p PMOS\n";
        print WRITE ".MODEL nd NMOS\n";
        print WRITE ".MODEL pd PMOS\n";
        print WRITE "\n";
        print WRITE "\n";
        print WRITE ".include $new_file_spice\n";
        print WRITE "x$cellName @get_new_port_list $cellName\n";
        print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
        print WRITE "C1 $output_port 0 opcap\n";
        print WRITE "\n";
        print WRITE ".temp 85\n";
        print WRITE ".tran 10p 500n\n";
        print WRITE "\n";
        print WRITE ".meas tran n3_first_fall when v(n3)=vmid fall=1\n";
        print WRITE "\n";
        print WRITE ".meas tran dclkfall trig v(n2) val=vmid rise=1\n";
        print WRITE "+                targ v(n3) val=vmid fall=1\n";
        print WRITE "\n";
        print WRITE ".end\n";
        close(WRITE);
  #------------------------------------------------------------write test bench for dclkrise-----------------------------------------------------#
        open(WRITE,">$file-dclkrise-$input_slew_value-$op_cap-clk_$get_clk_val-n1_$get_n1_val-n3_$get_n3_val");
        print WRITE ".title Fanout Versus Delay (TSMC)\n";
        print WRITE "\n";
        print WRITE ".param vdd=$vdd_pri_val\n";
        print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
        print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
        print WRITE ".param vss=$vss_val\n";
        print WRITE ".param wp=$wp\n";
        print WRITE ".param wn=$wn\n";
        print WRITE ".param vlo='0.2*vdd'\n";
        print WRITE ".param vmid='0.5*vdd'\n";
        print WRITE ".param vhi='0.8*vdd'\n";
        print WRITE ".param opcap=$op_cap_with_unit\n";
        print WRITE ".param inputslew=$input_slew_value_with_unit\n";
        print WRITE ".param v0=vss\n"; 
        print WRITE ".param v1=vss\n";
        print WRITE ".param v2=vlo\n";
        print WRITE ".param v3=vhi\n";
        print WRITE ".param v4=vdd\n";
        print WRITE ".param v5=vdd\n";
        print WRITE ".param v6=vhi\n";
        print WRITE ".param v7=vlo\n";
        print WRITE ".param v8=vss\n";
        print WRITE ".param v9=vss\n";
        print WRITE "\n";
        print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
        print WRITE ".param t1='inputslew*10/6*1.0'\n";
        print WRITE ".param t2='inputslew*10/6*1.2'\n";
        print WRITE ".param t3='inputslew*10/6*1.8'\n";
        print WRITE ".param t4='inputslew*10/6*2.0'\n";
        print WRITE ".param t5='inputslew*10/6*3.0'\n";
        print WRITE ".param t6='inputslew*10/6*3.2'\n";
        print WRITE ".param t7='inputslew*10/6*3.8'\n";
        print WRITE ".param t8='inputslew*10/6*4.0'\n";
        print WRITE ".param t9='inputslew*10/6*5.0'\n";
        print WRITE "\n";
        print WRITE ".param t_sec0='inputslew*10/6*0.0 + inputslew*10/6*5'\n"; 
        print WRITE ".param t_sec1='inputslew*10/6*1.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec2='inputslew*10/6*1.2 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec3='inputslew*10/6*1.8 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec4='inputslew*10/6*2.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec5='inputslew*10/6*3.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec6='inputslew*10/6*3.2 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec7='inputslew*10/6*3.8 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec8='inputslew*10/6*4.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec9='inputslew*10/6*5.0 + inputslew*10/6*5'\n";
        print WRITE "\n";
        print WRITE ".nodeset v(n3)=vss\n";
        print WRITE "\n";
        print WRITE "vdd vdd 0 vdd\n";
        print WRITE "vddsec vddsec 0 vddsec\n";
        print WRITE "vss vss 0   vss\n";
        print WRITE "\n";
        print WRITE "vin n2 vss pwl(\n";
        print WRITE "+               t0   v0\n"; 
        print WRITE "+               t1   v1\n";
        print WRITE "+               t2   v2\n";
        print WRITE "+               t3   v3\n";
        print WRITE "+               t4   v4\n";
        print WRITE "+               t5   v5\n";
        print WRITE "+             )\n";
        print WRITE "\n";
        print WRITE "vin0 n1 vss pwl(\n";
        print WRITE "+               t0   v5\n"; 
        print WRITE "+               t1   v5\n";
        print WRITE "+               t2   v5\n";
        print WRITE "+               t3   v5\n";
        print WRITE "+               t4   v5\n";
        print WRITE "+               t5   v5\n";
        print WRITE "+             )\n";
        print WRITE ".MODEL n NMOS\n";
        print WRITE ".MODEL p PMOS\n";
        print WRITE ".MODEL nd NMOS\n";
        print WRITE ".MODEL pd PMOS\n";
        print WRITE "\n";
        print WRITE "\n";
        print WRITE ".include $new_file_spice\n";
        print WRITE "x$cellName @get_new_port_list $cellName\n";
        print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
        print WRITE "C1 $output_port 0 opcap\n";
        print WRITE "\n";
        print WRITE ".temp 85\n";
        print WRITE ".tran 10p 500n\n";
        print WRITE "\n";
        print WRITE ".meas tran n3_first_rise when v(n3)=vmid rise=1\n";
        print WRITE "\n";
        print WRITE ".meas tran dclkrise trig v(n2) val=vmid rise=1\n";
        print WRITE "+                targ v(n3) val=vmid rise=1\n";
        print WRITE "\n";
        print WRITE ".end\n";
        close (WRITE);
        #################################################################################################################################################################################################################
        system ("ngspice -b -o $file-dclkfall-$input_slew_value-$op_cap-clk_$get_clk_val-n1_$get_n1_val-n3_$get_n3_val.log $file-dclkfall-$input_slew_value-$op_cap-clk_$get_clk_val-n1_$get_n1_val-n3_$get_n3_val"); 
        system ("ngspice -b -o $file-dclkrise-$input_slew_value-$op_cap-clk_$get_clk_val-n1_$get_n1_val-n3_$get_n3_val.log $file-dclkrise-$input_slew_value-$op_cap-clk_$get_clk_val-n1_$get_n1_val-n3_$get_n3_val"); 
        #------------------------------------------------------------------------read log file for dclkfall-------------------------------------------------------------------------------------------------------------#
        open(READ_NG_LOG,"$file-dclkfall-$input_slew_value-$op_cap-clk_$get_clk_val-n1_$get_n1_val-n3_$get_n3_val.log");
        while(<READ_NG_LOG>){
        chomp();
          if($_ =~ /^dclkfall/){s/\s*dclkfall\s*//;my $dclkfall = (split(/=\s+/,$_))[1];
            $dclkfall =~ s/\s*targ//;
            my ($n,$m) = (split(/e/,$dclkfall))[0,1];
            my $m =$m+9;
            my $dclkfall_new = $n*(10**$m);
            push(@dclkfall_list,$dclkfall_new);
          }
        }#while reading
        close(READ_NG_LOG); 
        #----------------------------------read log file for dclkrise----------------------------------------------------------------------------------------------------------#
        open(READ_NG_LOG,"$file-dclkrise-$input_slew_value-$op_cap-clk_$get_clk_val-n1_$get_n1_val-n3_$get_n3_val.log");
        while(<READ_NG_LOG>){
        chomp();
          if($_ =~ /^dclkrise/){s/\s*dclkrise\s*//;my $dclkrise = (split(/=\s+/,$_))[1];
            $dclkrise =~ s/\s*targ//;
            my ($n,$m) = (split(/e/,$dclkrise))[0,1];
            my $m = $m+9;
            my $dclkrise_new = $n*(10**$m);
            push(@dclkrise_list,$dclkrise_new);
          }
        }#while reading 
        close(READ_NG_LOG);
      }elsif($get_clk_val == 0 && $get_n1_val == 0 && $get_n3_val eq "vss"){
        #----------------------------------------write test bench for dclkfall-----------------------------------------------#
         open(WRITE,">$file-dclkfall-$input_slew_value-$op_cap-clk_$get_clk_val-n1_$get_n1_val-n3_$get_n3_val");
         print WRITE ".title Fanout Versus Delay (TSMC)\n";
         print WRITE "\n";
         print WRITE ".param vdd=$vdd_pri_val\n";
         print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
         print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
         print WRITE ".param vss=$vss_val\n";
         print WRITE ".param wp=$wp\n";
         print WRITE ".param wn=$wn\n";
         print WRITE ".param vlo='0.2*vdd'\n";
         print WRITE ".param vmid='0.5*vdd'\n";
         print WRITE ".param vhi='0.8*vdd'\n";
         print WRITE ".param opcap=$op_cap_with_unit\n";
         print WRITE ".param inputslew=$input_slew_value_with_unit\n";
         print WRITE ".param v0=vss\n"; 
         print WRITE ".param v1=vss\n";
         print WRITE ".param v2=vlo\n";
         print WRITE ".param v3=vhi\n";
         print WRITE ".param v4=vdd\n";
         print WRITE ".param v5=vdd\n";
         print WRITE ".param v6=vhi\n";
         print WRITE ".param v7=vlo\n";
         print WRITE ".param v8=vss\n";
         print WRITE ".param v9=vss\n";
         print WRITE "\n";
         print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
         print WRITE ".param t1='inputslew*10/6*1.0'\n";
         print WRITE ".param t2='inputslew*10/6*1.2'\n";
         print WRITE ".param t3='inputslew*10/6*1.8'\n";
         print WRITE ".param t4='inputslew*10/6*2.0'\n";
         print WRITE ".param t5='inputslew*10/6*3.0'\n";
         print WRITE ".param t6='inputslew*10/6*3.2'\n";
         print WRITE ".param t7='inputslew*10/6*3.8'\n";
         print WRITE ".param t8='inputslew*10/6*4.0'\n";
         print WRITE ".param t9='inputslew*10/6*5.0'\n";
         print WRITE "\n";
         print WRITE ".param t_sec0='inputslew*10/6*0.0 + inputslew*10/6*5'\n"; 
         print WRITE ".param t_sec1='inputslew*10/6*1.0 + inputslew*10/6*5'\n";
         print WRITE ".param t_sec2='inputslew*10/6*1.2 + inputslew*10/6*5'\n";
         print WRITE ".param t_sec3='inputslew*10/6*1.8 + inputslew*10/6*5'\n";
         print WRITE ".param t_sec4='inputslew*10/6*2.0 + inputslew*10/6*5'\n";
         print WRITE ".param t_sec5='inputslew*10/6*3.0 + inputslew*10/6*5'\n";
         print WRITE ".param t_sec6='inputslew*10/6*3.2 + inputslew*10/6*5'\n";
         print WRITE ".param t_sec7='inputslew*10/6*3.8 + inputslew*10/6*5'\n";
         print WRITE ".param t_sec8='inputslew*10/6*4.0 + inputslew*10/6*5'\n";
         print WRITE ".param t_sec9='inputslew*10/6*5.0 + inputslew*10/6*5'\n";
         print WRITE "\n";
         print WRITE ".nodeset v(n3)=vdd\n";
         print WRITE "\n";
         print WRITE "vdd vdd 0 vdd\n";
         print WRITE "vddsec vddsec 0 vddsec\n";
         print WRITE "vss vss 0   vss\n";
         print WRITE "\n";
         print WRITE "vin n2 vss pwl(\n";
         print WRITE "+               t0   v5\n"; 
         print WRITE "+               t1   v4\n";
         print WRITE "+               t2   v3\n";
         print WRITE "+               t3   v2\n";
         print WRITE "+               t4   v1\n";
         print WRITE "+               t5   v0\n";
         print WRITE "+             )\n";
         print WRITE "\n";
         print WRITE "vin0 n1 vss pwl(\n";
         print WRITE "+               t0   v5\n"; 
         print WRITE "+               t1   v5\n";
         print WRITE "+               t2   v5\n";
         print WRITE "+               t3   v5\n";
         print WRITE "+               t4   v5\n";
         print WRITE "+               t5   v5\n";
         print WRITE "+             )\n";
         print WRITE ".MODEL n NMOS\n";
         print WRITE ".MODEL p PMOS\n";
         print WRITE ".MODEL nd NMOS\n";
         print WRITE ".MODEL pd PMOS\n";
         print WRITE "\n";
         print WRITE "\n";
         print WRITE ".include $new_file_spice\n";
         print WRITE "x$cellName @get_new_port_list $cellName\n";
         print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
         print WRITE "C1 $output_port 0 opcap\n";
         print WRITE "\n";
         print WRITE ".temp 85\n";
         print WRITE ".tran 10p 500n\n";
         print WRITE "\n";
         print WRITE ".meas tran n3_first_fall when v(n3)=vmid fall=1\n";
         print WRITE "\n";
         print WRITE ".meas tran dclkfall trig v(n2) val=vmid fall=1\n";
         print WRITE "+                targ v(n3) val=vmid fall=1\n";
         print WRITE "\n";
         print WRITE ".end\n";
         close(WRITE);
  #----------------------------------------------------write test bench for dclkrise------------------------------------------------#
         open(WRITE,">$file-dclkrise-$input_slew_value-$op_cap-clk_$get_clk_val-n1_$get_n1_val-n3_$get_n3_val");
         print WRITE ".title Fanout Versus Delay (TSMC)\n";
         print WRITE "\n";
         print WRITE ".param vdd=$vdd_pri_val\n";
         print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
         print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
         print WRITE ".param vss=$vss_val\n";
         print WRITE ".param wp=$wp\n";
         print WRITE ".param wn=$wn\n";
         print WRITE ".param vlo='0.2*vdd'\n";
         print WRITE ".param vmid='0.5*vdd'\n";
         print WRITE ".param vhi='0.8*vdd'\n";
         print WRITE ".param opcap=$op_cap_with_unit\n";
         print WRITE ".param inputslew=$input_slew_value_with_unit\n";
         print WRITE ".param v0=vss\n"; 
         print WRITE ".param v1=vss\n";
         print WRITE ".param v2=vlo\n";
         print WRITE ".param v3=vhi\n";
         print WRITE ".param v4=vdd\n";
         print WRITE ".param v5=vdd\n";
         print WRITE ".param v6=vhi\n";
         print WRITE ".param v7=vlo\n";
         print WRITE ".param v8=vss\n";
         print WRITE ".param v9=vss\n";
         print WRITE "\n";
         print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
         print WRITE ".param t1='inputslew*10/6*1.0'\n";
         print WRITE ".param t2='inputslew*10/6*1.2'\n";
         print WRITE ".param t3='inputslew*10/6*1.8'\n";
         print WRITE ".param t4='inputslew*10/6*2.0'\n";
         print WRITE ".param t5='inputslew*10/6*3.0'\n";
         print WRITE ".param t6='inputslew*10/6*3.2'\n";
         print WRITE ".param t7='inputslew*10/6*3.8'\n";
         print WRITE ".param t8='inputslew*10/6*4.0'\n";
         print WRITE ".param t9='inputslew*10/6*5.0'\n";
         print WRITE "\n";
         print WRITE ".param t_sec0='inputslew*10/6*0.0 + inputslew*10/6*5'\n"; 
         print WRITE ".param t_sec1='inputslew*10/6*1.0 + inputslew*10/6*5'\n";
         print WRITE ".param t_sec2='inputslew*10/6*1.2 + inputslew*10/6*5'\n";
         print WRITE ".param t_sec3='inputslew*10/6*1.8 + inputslew*10/6*5'\n";
         print WRITE ".param t_sec4='inputslew*10/6*2.0 + inputslew*10/6*5'\n";
         print WRITE ".param t_sec5='inputslew*10/6*3.0 + inputslew*10/6*5'\n";
         print WRITE ".param t_sec6='inputslew*10/6*3.2 + inputslew*10/6*5'\n";
         print WRITE ".param t_sec7='inputslew*10/6*3.8 + inputslew*10/6*5'\n";
         print WRITE ".param t_sec8='inputslew*10/6*4.0 + inputslew*10/6*5'\n";
         print WRITE ".param t_sec9='inputslew*10/6*5.0 + inputslew*10/6*5'\n";
         print WRITE "\n";
         print WRITE ".nodeset v(n3)=vss\n";
         print WRITE "\n";
         print WRITE "vdd vdd 0 vdd\n";
         print WRITE "vddsec vddsec 0 vddsec\n";
         print WRITE "vss vss 0   vss\n";
         print WRITE "\n";
         print WRITE "vin n2 vss pwl(\n";
         print WRITE "+               t0   v5\n"; 
         print WRITE "+               t1   v4\n";
         print WRITE "+               t2   v3\n";
         print WRITE "+               t3   v2\n";
         print WRITE "+               t4   v1\n";
         print WRITE "+               t5   v0\n";
         print WRITE "+             )\n";
         print WRITE "\n";
         print WRITE "vin0 n1 vss pwl(\n";
         print WRITE "+               t0   v0\n"; 
         print WRITE "+               t1   v0\n";
         print WRITE "+               t2   v0\n";
         print WRITE "+               t3   v0\n";
         print WRITE "+               t4   v0\n";
         print WRITE "+               t5   v0\n";
         print WRITE "+             )\n";
         print WRITE ".MODEL n NMOS\n";
         print WRITE ".MODEL p PMOS\n";
         print WRITE ".MODEL nd NMOS\n";
         print WRITE ".MODEL pd PMOS\n";
         print WRITE "\n";
         print WRITE "\n";
         print WRITE ".include $new_file_spice\n";
         print WRITE "x$cellName @get_new_port_list $cellName\n";
         print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
         print WRITE "C1 $output_port 0 opcap\n";
         print WRITE "\n";
         print WRITE ".temp 85\n";
         print WRITE ".tran 10p 500n\n";
         print WRITE "\n";
         print WRITE ".meas tran n3_first_rise when v(n3)=vmid rise=1\n";
         print WRITE "\n";
         print WRITE ".meas tran dclkrise trig v(n2) val=vmid fall=1\n";
         print WRITE "+                targ v(n3) val=vmid rise=1\n";
         print WRITE "\n";
         print WRITE ".end\n";
         close(WRITE);
         ################################################################################################################################################################################################################
         system("ngspice -b -o $file-dclkfall-$input_slew_value-$op_cap-clk_$get_clk_val-n1_$get_n1_val-n3_$get_n3_val.log $file-dclkfall-$input_slew_value-$op_cap-clk_$get_clk_val-n1_$get_n1_val-n3_$get_n3_val"); 
         system("ngspice -b -o $file-dclkrise-$input_slew_value-$op_cap-clk_$get_clk_val-n1_$get_n1_val-n3_$get_n3_val.log $file-dclkrise-$input_slew_value-$op_cap-clk_$get_clk_val-n1_$get_n1_val-n3_$get_n3_val"); 
         #-------------------------------------------------------------------read log file for dclkfall----------------------------------------------------------------------------------------------------#
         open(READ_NG_LOG,"$file-dclkfall-$input_slew_value-$op_cap-clk_$get_clk_val-n1_$get_n1_val-n3_$get_n3_val.log");
         while(<READ_NG_LOG>){
         chomp();
           if($_ =~ /^dclkfall/){s/\s*dclkfall\s*//;my $dclkfall = (split(/=\s+/,$_))[1];
             $dclkfall =~ s/\s*targ//;
             my ($n,$m) = (split(/e/,$dclkfall))[0,1];
             my $m =$m+9;
             my $dclkfall_new = $n*(10**$m);
             push(@dclkfall_list,$dclkfall_new);
           } 
         }#while reading
         close(READ_NG_LOG);
         #------------------------------------------------------------------read log file for dclkrise-------------------------------------------------------------------------------------------------------------------#
         open(READ_NG_LOG,"$file-dclkrise-$input_slew_value-$op_cap-clk_$get_clk_val-n1_$get_n1_val-n3_$get_n3_val.log");
         while(<READ_NG_LOG>){
         chomp();
           if($_ =~ /^dclkrise/){s/\s*dclkrise\s*//;my $dclkrise = (split(/=\s+/,$_))[1];
             $dclkrise =~ s/\s*targ//;
             my ($n,$m) = (split(/e/,$dclkrise))[0,1];
             my $m =$m+9;
             my $dclkrise_new = $n*(10**$m);
             push(@dclkrise_list,$dclkrise_new);
           }
         }#while reading
        close(READ_NG_LOG);
      }elsif($get_clk_val == 1 && $get_n1_val == 0 && $get_n3_val eq "vss"){
  #----------------------------------------write test bench for dclkfall----------------------------------------------------#
        open(WRITE,">$file-dclkfall-$input_slew_value-$op_cap-clk_$get_clk_val-n1_$get_n1_val-n3_$get_n3_val");
        print WRITE ".title Fanout Versus Delay (TSMC)\n";
        print WRITE "\n";
        print WRITE ".param vdd=$vdd_pri_val\n";
        print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
        print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
        print WRITE ".param vss=$vss_val\n";
        print WRITE ".param wp=$wp\n";
        print WRITE ".param wn=$wn\n";
        print WRITE ".param vlo='0.2*vdd'\n";
        print WRITE ".param vmid='0.5*vdd'\n";
        print WRITE ".param vhi='0.8*vdd'\n";
        print WRITE ".param opcap=$op_cap_with_unit\n";
        print WRITE ".param inputslew=$input_slew_value_with_unit\n";
        print WRITE ".param v0=vss\n"; 
        print WRITE ".param v1=vss\n";
        print WRITE ".param v2=vlo\n";
        print WRITE ".param v3=vhi\n";
        print WRITE ".param v4=vdd\n";
        print WRITE ".param v5=vdd\n";
        print WRITE ".param v6=vhi\n";
        print WRITE ".param v7=vlo\n";
        print WRITE ".param v8=vss\n";
        print WRITE ".param v9=vss\n";
        print WRITE "\n";
        print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
        print WRITE ".param t1='inputslew*10/6*1.0'\n";
        print WRITE ".param t2='inputslew*10/6*1.2'\n";
        print WRITE ".param t3='inputslew*10/6*1.8'\n";
        print WRITE ".param t4='inputslew*10/6*2.0'\n";
        print WRITE ".param t5='inputslew*10/6*3.0'\n";
        print WRITE ".param t6='inputslew*10/6*3.2'\n";
        print WRITE ".param t7='inputslew*10/6*3.8'\n";
        print WRITE ".param t8='inputslew*10/6*4.0'\n";
        print WRITE ".param t9='inputslew*10/6*5.0'\n";
        print WRITE "\n";
        print WRITE ".param t_sec0='inputslew*10/6*0.0 + inputslew*10/6*5'\n"; 
        print WRITE ".param t_sec1='inputslew*10/6*1.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec2='inputslew*10/6*1.2 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec3='inputslew*10/6*1.8 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec4='inputslew*10/6*2.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec5='inputslew*10/6*3.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec6='inputslew*10/6*3.2 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec7='inputslew*10/6*3.8 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec8='inputslew*10/6*4.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec9='inputslew*10/6*5.0 + inputslew*10/6*5'\n";
        print WRITE "\n";
        print WRITE ".nodeset v(n3)=vdd\n";
        print WRITE "\n";
        print WRITE "vdd vdd 0 vdd\n";
        print WRITE "vddsec vddsec 0 vddsec\n";
        print WRITE "vss vss 0   vss\n";
        print WRITE "\n";
        print WRITE "vin n2 vss pwl(\n";
        print WRITE "+               t0   v0\n"; 
        print WRITE "+               t1   v1\n";
        print WRITE "+               t2   v2\n";
        print WRITE "+               t3   v3\n";
        print WRITE "+               t4   v4\n";
        print WRITE "+               t5   v5\n";
        print WRITE "+             )\n";
        print WRITE "\n";
        print WRITE "vin0 n1 vss pwl(\n";
        print WRITE "+               t0   v0\n"; 
        print WRITE "+               t1   v0\n";
        print WRITE "+               t2   v0\n";
        print WRITE "+               t3   v0\n";
        print WRITE "+               t4   v0\n";
        print WRITE "+               t5   v0\n";
        print WRITE "+             )\n";
        print WRITE ".MODEL n NMOS\n";
        print WRITE ".MODEL p PMOS\n";
        print WRITE ".MODEL nd NMOS\n";
        print WRITE ".MODEL pd PMOS\n";
        print WRITE "\n";
        print WRITE "\n";
        print WRITE ".include $new_file_spice\n";
        print WRITE "x$cellName @get_new_port_list $cellName\n";
        print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
        print WRITE "C1 $output_port 0 opcap\n";
        print WRITE "\n";
        print WRITE ".temp 85\n";
        print WRITE ".tran 10p 500n\n";
        print WRITE "\n";
        print WRITE ".meas tran n3_first_fall when v(n3)=vmid fall=1\n";
        print WRITE "\n";
        print WRITE ".meas tran dclkfall trig v(n2) val=vmid rise=1\n";
        print WRITE "+                targ v(n3) val=vmid fall=1\n";
        print WRITE "\n";
        print WRITE ".end\n";
        close (WRITE);
   #------------------------------------------write test bench for dclkrise-----------------------------------------------#
        open(WRITE,">$file-dclkrise-$input_slew_value-$op_cap-clk_$get_clk_val-n1_$get_n1_val-n3_$get_n3_val");
        print WRITE ".title Fanout Versus Delay (TSMC)\n";
        print WRITE "\n";
        print WRITE ".param vdd=5\n";
        print WRITE ".param vddsec=5\n";
        print WRITE ".param vss=0.0\n";
        print WRITE ".param wp=3.00e-06\n";
        print WRITE ".param wn=1.20e-06\n";
        print WRITE ".param vlo='0.2*vdd'\n";
        print WRITE ".param vmid='0.5*vdd'\n";
        print WRITE ".param vhi='0.8*vdd'\n";
        print WRITE ".param opcap=0.060e-12\n";
        print WRITE ".param inputslew=0.800e-9\n";
        print WRITE ".param v0=vss\n"; 
        print WRITE ".param v1=vss\n";
        print WRITE ".param v2=vlo\n";
        print WRITE ".param v3=vhi\n";
        print WRITE ".param v4=vdd\n";
        print WRITE ".param v5=vdd\n";
        print WRITE ".param v6=vhi\n";
        print WRITE ".param v7=vlo\n";
        print WRITE ".param v8=vss\n";
        print WRITE ".param v9=vss\n";
        print WRITE "\n";
        print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
        print WRITE ".param t1='inputslew*10/6*1.0'\n";
        print WRITE ".param t2='inputslew*10/6*1.2'\n";
        print WRITE ".param t3='inputslew*10/6*1.8'\n";
        print WRITE ".param t4='inputslew*10/6*2.0'\n";
        print WRITE ".param t5='inputslew*10/6*3.0'\n";
        print WRITE ".param t6='inputslew*10/6*3.2'\n";
        print WRITE ".param t7='inputslew*10/6*3.8'\n";
        print WRITE ".param t8='inputslew*10/6*4.0'\n";
        print WRITE ".param t9='inputslew*10/6*5.0'\n";
        print WRITE "\n";
        print WRITE ".param t_sec0='inputslew*10/6*0.0 + inputslew*10/6*5'\n"; 
        print WRITE ".param t_sec1='inputslew*10/6*1.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec2='inputslew*10/6*1.2 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec3='inputslew*10/6*1.8 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec4='inputslew*10/6*2.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec5='inputslew*10/6*3.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec6='inputslew*10/6*3.2 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec7='inputslew*10/6*3.8 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec8='inputslew*10/6*4.0 + inputslew*10/6*5'\n";
        print WRITE ".param t_sec9='inputslew*10/6*5.0 + inputslew*10/6*5'\n";
        print WRITE "\n";
        print WRITE ".nodeset v(n3)=vss\n";
        print WRITE "\n";
        print WRITE "vdd vdd 0 vdd\n";
        print WRITE "vddsec vddsec 0 vddsec\n";
        print WRITE "vss vss 0   vss\n";
        print WRITE "\n";
        print WRITE "vin n2 vss pwl(\n";
        print WRITE "+               t0   v0\n"; 
        print WRITE "+               t1   v1\n";
        print WRITE "+               t2   v2\n";
        print WRITE "+               t3   v3\n";
        print WRITE "+               t4   v4\n";
        print WRITE "+               t5   v5\n";
        print WRITE "+             )\n";
        print WRITE "\n";
        print WRITE "vin0 n1 vss pwl(\n";
        print WRITE "+               t0   v0\n"; 
        print WRITE "+               t1   v0\n";
        print WRITE "+               t2   v0\n";
        print WRITE "+               t3   v0\n";
        print WRITE "+               t4   v0\n";
        print WRITE "+               t5   v0\n";
        print WRITE "+             )\n";
        print WRITE ".MODEL n NMOS\n";
        print WRITE ".MODEL p PMOS\n";
        print WRITE ".MODEL nd NMOS\n";
        print WRITE ".MODEL pd PMOS\n";
        print WRITE "\n";
        print WRITE "\n";
        print WRITE ".include sff1_x4-flat.sp.ngspice\n";
        print WRITE "xsff1_x4 n2 n1 n3 vdd vss sff1_x4\n";
        print WRITE "*xxsff1_x4 n2 n3 n4 vdd vss sff1_x4\n";
        print WRITE "C1 n3 0 opcap\n";
        print WRITE "\n";
        print WRITE ".temp 85\n";
        print WRITE ".tran 10p 500n\n";
        print WRITE "\n";
        print WRITE ".meas tran n3_first_rise when v(n3)=vmid rise=1\n";
        print WRITE "\n";
        print WRITE ".meas tran dclkrise trig v(n2) val=vmid rise=1\n";
        print WRITE "+                targ v(n3) val=vmid rise=1\n";
        print WRITE "\n";
        print WRITE ".end\n";
        close (WRITE);
        ################################################################################################################################################################################################################
        system("ngspice -b -o $file-dclkfall-$input_slew_value-$op_cap-clk_$get_clk_val-n1_$get_n1_val-n3_$get_n3_val.log $file-dclkfall-$input_slew_value-$op_cap-clk_$get_clk_val-n1_$get_n1_val-n3_$get_n3_val"); 
        system("ngspice -b -o $file-dclkrise-$input_slew_value-$op_cap-clk_$get_clk_val-n1_$get_n1_val-n3_$get_n3_val.log $file-dclkrise-$input_slew_value-$op_cap-clk_$get_clk_val-n1_$get_n1_val-n3_$get_n3_val"); 
        #-------------------------------------------------------------------read log file for dclkfall----------------------------------------------------------------------------------------------------#
        open(READ_NG_LOG,"$file-dclkfall-$input_slew_value-$op_cap-clk_$get_clk_val-n1_$get_n1_val-n3_$get_n3_val.log");
        while(<READ_NG_LOG>){
        chomp();
          if($_ =~ /^dclkfall/){s/\s*dclkfall\s*//;my $dclkfall = (split(/=\s+/,$_))[1];
            $dclkfall =~ s/\s*targ//;
            my ($n,$m) = (split(/e/,$dclkfall))[0,1];
            my $m =$m+9;
            my $dclkfall_new = $n*(10**$m);
            push(@dclkfall_list,$dclkfall_new);
          } 
        }#while reading
        close(READ_NG_LOG);
        #------------------------------------------------------------------read log file for dclkrise-------------------------------------------------------------------------------------------------------------------#
        open(READ_NG_LOG,"$file-dclkrise-$input_slew_value-$op_cap-clk_$get_clk_val-n1_$get_n1_val-n3_$get_n3_val.log");
        while(<READ_NG_LOG>){
        chomp();
          if($_ =~ /^dclkrise/){s/\s*dclkrise\s*//;my $dclkrise = (split(/=\s+/,$_))[1];
            $dclkrise =~ s/\s*targ//;
            my ($n,$m) = (split(/e/,$dclkrise))[0,1];
            my $m =$m+9;
            my $dclkrise_new = $n*(10**$m);
            push(@dclkrise_list,$dclkrise_new);
          }
        }#while reading
       close(READ_NG_LOG);
      } 
    }#for
  }#for
print WRITE_GENLIB "       cell_rise @dclkrise_list\n";
print WRITE_GENLIB "       cell_fall @dclkfall_list\n";
close (WRITE_GENLIB);
&write_lib("-genlib","$cellName.genlib","-lib","$file.lib");
}#else
}#sub read_file_for_flop
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
sub read_file_for_latch {
  my $file = $_[0];
  my $clk = $_[1];
  my $out = $_[2];
  my $in = $_[3];
  my $cellName = "";
  my $vdd_pri = "";
  my $vdd_pri_val = "";
  my $vdd_sec = "";
  my $vdd_sec_val = "";
  my $vss_name = "";
  my $vss_val = "";
  my $wp = "";
  my $wn = "";
  my $new_vdd_1 = "";
  my $new_vdd_2 = "";
  my $new_vss = "";
  my @input_slew = ();
  my @opcap = ();
  my $end_data_of_subckt = 0;
  my $read_data_of_subckt = 0;
  my @get_data = ();
  my @cell_data = ();
  my %SPICE_DATA = ();
  my $data_start = 0;
  my $data_end =0;
  my $data = "";
  my @new_data = ();
  my $mdata = "";
  my %INPUT = ();
  my %OUTPUT = ();
  my @input_list = ();
  my @output_list = ();
  my $read_data_of_subckt_sp = 0;
  my $index = 0;
  my $new_file_spice = "";
#------------------------------------------------------------------------------#  
  open(READ,"$file");
  $file =~ s/.*\///;
  $new_file_spice = $file."\.ngspice";
  open(WRITE_NG,">$new_file_spice");
  while(<READ>){
    chomp();
    s/\*.*$//;
    if($_ =~ /^\s+$/){next;}
    if($_ =~ /^\s*\.subckt/i){
      print WRITE_NG "$_\n";
      $read_data_of_subckt_sp = 1;
    }elsif($_ =~ /^\s*\.end/i){
      $read_data_of_subckt_sp = 0;
      print WRITE_NG "$_\n";
    }elsif($read_data_of_subckt_sp == 1){
      s/ \$X.*=.*\$Y.*=.*\$D.*=.*$//;
      print WRITE_NG "$_\n";
    }
  }
  close(WRITE_NG);
  close(READ);
#-----------------------------------------------------------------------------------#
open(READ_SP,"$file");
my $previous_line = "";
my $next_line = "";
while(<READ_SP>){
chomp();
if($_ =~ /\*/){next;}
if($_ =~ /^\+/){
  s/\s+$//;
  s/^\+//;
  $previous_line = $previous_line." ".$_;
  next;
}
$next_line = $_;
if($previous_line =~ /^\s*\.subckt/i){
  $read_data_of_subckt = 1;
  $end_data_of_subckt = 0;
  $previous_line =~ s/^\s*\.(subckt|SUBCKT)\s*//;
  @cell_data = (split(/\s+/,$previous_line));
  $cellName = shift(@cell_data);
}
if($previous_line =~ /^\s*\.end/i){
  $end_data_of_subckt = 1;
  $read_data_of_subckt = 0;
}
if($read_data_of_subckt == 1 && $end_data_of_subckt == 0){
  if($previous_line=~ /^\s*m\s*/i){
    $data = "";
    @new_data = ();
    $mdata = "";
    $data_start =1;
    $data_end =0;
    $read_cell_data = 0;
  }
  if($previous_line =~ /^\s*c/i){
    $data_end =1;
    $data_start =0;
  }
  if($data_start == 1 && $data_end ==0){
    if($previous_line=~ /^\s*m\s*/i){
    $data = $data." ".$previous_line;
    }else {
    $data = $data." ".$previous_line;
    }
    $data =~ s/^\s*//;
    $data =~ s/=\s+/=/;
    @new_data = (split(/\s+/,$data));
    $mdata = shift (@new_data);
    @{$SPICE_DATA{$mdata}} = @new_data;
  }
}
$previous_line = $next_line;
}#while
close(READ_SP);
#-----------------------------------------------created input and output list------------------------------------------#
if($cellName eq ""){print "ERR:We are not getting cellName from .spi file\n";}
foreach my $mdata (sort {$a cmp $b}keys %SPICE_DATA){
  my @data_new = @{$SPICE_DATA{$mdata}};
  my $data_new_var = join" ",@data_new;
  my ($drain,$gate,$source,$type) = (split(/\s+/,$data_new_var))[0,1,2,4];
  foreach my $port (@cell_data){
    if(($port =~ /vdd/) || ($port =~ /VDD/) || ($port =~ /vss/) || ($port =~ /VSS/) || ($port =~ /gnd/) || ($port =~ /GND/) || ($port =~ /vdar_t/i)|| ($port =~ /vdio_t/i)){}
    else {
      if($cellName =~ m/mux/i){
         #$INPUT{"a"} = 1 if(!exists $INPUT{"a"});
         $INPUT{"A"} = 1 if(!exists $INPUT{"A"});
        # $INPUT{"b"} = 1 if(!exists $INPUT{"b"});
         $INPUT{"B"} = 1 if(!exists $INPUT{"B"});
         #$INPUT{"sel_a"} = 1 if(!exists $INPUT{"sel_a"}); 
         $INPUT{"SEL_A"} = 1 if(!exists $INPUT{"SEL_A"}); 
         #$OUTPUT{"qp"} = 1 if(!exists $OUTPUT{"qp"});
         $OUTPUT{"QP"} = 1 if(!exists $OUTPUT{"QP"});
         #if($port eq $gate || $port eq $source){
         #  $INPUT{$port} = 1 if(!exists $INPUT{$port});
         #}elsif($port eq $drain){
         #   $OUTPUT{$port} = 1 if(!exists $OUTPUT{$port});
         #}
      }else{
         if($port eq $gate){
           $INPUT{$port} = 1 if(!exists $INPUT{$port});
         }elsif((($port eq $drain) || ($port eq $source)) && ($port ne $gate)){
            $OUTPUT{$port} = 1 if(!exists $OUTPUT{$port});
         }
      }#if not mux
    }
  }
}# foreach line 

foreach my $in (keys %INPUT){
  push (@input_list,$in);
  $input_index{$in} = $index;
  $index++;
}
foreach my $out (keys %OUTPUT){
  push (@output_list,$out);
}
#--------------------------------------------------------------------------------------------------------#
###########################################parameter file#################################################
open(READ_PARA,"$parameter_file");
while(<READ_PARA>){
  chomp();
  if($_ =~ /vss/i){($vss_name,$vss_val) = (split(/=\s*/,$_))[0,1];}
  if($_ =~ /width\s*pmos/i){$wp = (split(/=\s*/,$_))[1];}
  if($_ =~ /width\s*nmos/i){$wn = (split(/=\s*/,$_))[1];}
  if($_ =~ /input\s*slew/i){s/\s*input\s*slew\s*=\s*//;@input_slew = (split(/\s+/,$_));}
  if($_ =~ /output\s*capacitance/i){s/\s*output\s*capacitance\s*=\s*//;@opcap = (split(/\s+/,$_));}
  if($_ =~ /vdd\s*sec/i){($vdd_sec,$vdd_sec_val) = (split(/=\s*/,$_))[0,1];}
  elsif($_ =~ /vdd/i){($vdd_pri,$vdd_pri_val) = (split(/=\s*/,$_))[0,1];}
}#while reading parameter file
close (READ_PARA);
#--------------------------------------------------------------------------------------------------------#
my $input_slew_val_1_with_unit = $input_slew[0].""."e-9";
my $op_cap_val_1_with_unit = $opcap[0].""."e-12";
my @get_new_port_list = ();
my @get_new_port_list1 = ();
my $output_port = "";
my $reset_port = "";
my @clk_value = ();
my @n1_value = ();
my @n3_value = ();
my @reset_value = ();
foreach my $port (@cell_data){
  if($port =~ /vd/i){
    push(@get_new_port_list,$port);
    push(@get_new_port_list1,$port);
  }elsif($port =~ /vss/i){
    push(@get_new_port_list,$port);
    push(@get_new_port_list1,$port);
  }elsif($port =~/$clk/){
    push(@get_new_port_list,"n2");
    push(@get_new_port_list1,"n2");
    push(@clk_value ,0,1);
  }elsif($port =~ /$out/){
    push(@get_new_port_list,"n3");
    push(@get_new_port_list1,"n4");
    push (@n3_value,"vdd","vss");
    $output_port = "n3";
  }elsif($port =~ /$in/){
    push(@get_new_port_list,"n1");
    push(@get_new_port_list1,"n3");
    push(@n1_value,0,1);
  }elsif($port =~ /rs/){ 
    push(@get_new_port_list,"vrs");
    push(@get_new_port_list1,"vrs");
    push(@reset_value ,0,1);
    $reset_port = $port;
  }
}#foreach port 
####################################write test bench to find the value of clock and reset################################
my $get_clock_val = "";  
my $get_n1_value = "";
my $get_n3_value = "";
my $get_reset_value = "";
my $get_reset_val = "";
my $get_n2_value = "";

for (my $vl=0;$vl<=$#reset_value;$vl++){
  for (my $vol=0;$vol<=$#n3_value;$vol++){
    for(my $ck_val=0;$ck_val<=$#clk_value;$ck_val++){
      for(my $n1val=0;$n1val<=$#n1_value;$n1val++){ 
        my $ck_value = $clk_value[$ck_val];
        my $reset_val = $reset_value[$vl];
        my $n3_vl = $n3_value[$vol];
        my $n1_vl = $n1_value[$n1val];
        if($ck_value == 0 && $reset_val == 0 && $n1_vl == 0 && $n3_vl eq "vdd"){
          open(WRITE,">$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE "\n";
          print WRITE ".param v0=vss\n"; 
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*7.0'\n";
          print WRITE ".param t4='inputslew*10/6*8.0'\n";
          print WRITE ".param t5='inputslew*10/6*8.8'\n";
          print WRITE ".param t6='inputslew*10/6*9.0'\n";
          print WRITE ".param t7='inputslew*10/6*10.0'\n";
          print WRITE ".param t8='inputslew*10/6*10.2'\n";
          print WRITE ".param t9='inputslew*10/6*10.8'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n";
          print WRITE "*.nodeset v(n3)=vdd\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0 vss\n";
          print WRITE "\n";
          print WRITE "vrs vrs 0 vss\n";
          print WRITE "\n";
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t0   v0\n"; 
          print WRITE "+               t1   v0\n";
          print WRITE "+               t2   v0\n";
          print WRITE "+               t3   v0\n";
          print WRITE "+               t4   v0\n";
          print WRITE "+               t5   v0\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v5\n"; 
          print WRITE "+               t1   v5\n";
          print WRITE "+               t2   v5\n";
          print WRITE "+               t3   v4\n";
          print WRITE "+               t4   v3\n";
          print WRITE "+               t5   v2\n";
          print WRITE "+               t6   v1\n";
          print WRITE "+               t7   v0\n";
          print WRITE "+               t8   v0\n";
          print WRITE "+               t9   v0\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE "*.meas tran n1_first_fall when v(n1)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n3_first_fall when v(n3)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close (WRITE);
          ###############################################################################################################
          system("ngspice -b -o $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          #------------------------------------------------read log file------------------------------------------------# 
          open(READ_LOG,"$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log");
          while(<READ_LOG>){
          chomp();
            if($_ =~ /^n3_first_fall/){my $n3_first_fall = (split(/=\s+/,$_))[1];
              if($n3_first_fall ne ""){$get_clk_val = $clkval;
                                       $get_n1_val = $n1_val;
                                       $get_n3_val = $n3_val;}
            }
          }#while
          close(READ_LOG);
          #-------------------------------------------------------------------------------------------------------------#
        }elsif($ck_value == 1 && $reset_val == 0 && $n1_vl == 0 && $n3_vl eq "vdd"){
          open(WRITE,">$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE "\n";
          print WRITE ".param v0=vss\n"; 
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*7.0'\n";
          print WRITE ".param t4='inputslew*10/6*8.0'\n";
          print WRITE ".param t5='inputslew*10/6*8.8'\n";
          print WRITE ".param t6='inputslew*10/6*9.0'\n";
          print WRITE ".param t7='inputslew*10/6*10.0'\n";
          print WRITE ".param t8='inputslew*10/6*10.2'\n";
          print WRITE ".param t9='inputslew*10/6*10.8'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n";
          print WRITE "*.nodeset v(n3)=vdd\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0 vss\n";
          print WRITE "\n";
          print WRITE "vrs vrs 0 vss\n";
          print WRITE "\n";
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t0   v5\n"; 
          print WRITE "+               t1   v5\n";
          print WRITE "+               t2   v5\n";
          print WRITE "+               t3   v5\n";
          print WRITE "+               t4   v5\n";
          print WRITE "+               t5   v5\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v5\n"; 
          print WRITE "+               t1   v5\n";
          print WRITE "+               t2   v5\n";
          print WRITE "+               t3   v4\n";
          print WRITE "+               t4   v3\n";
          print WRITE "+               t5   v2\n";
          print WRITE "+               t6   v1\n";
          print WRITE "+               t7   v0\n";
          print WRITE "+               t8   v0\n";
          print WRITE "+               t9   v0\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE "*.meas tran n1_first_fall when v(n1)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n3_first_fall when v(n3)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close (WRITE);
          ###############################################################################################################
          system("ngspice -b -o $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          #------------------------------------------------read log file------------------------------------------------#
          open(READ_LOG,"$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log");
          while(<READ_LOG>){
            chomp();
              if($_ =~ /^n3_first_fall/){my $n3_first_fall = (split(/=\s+/,$_))[1];
                if($n3_first_fall ne ""){$get_clk_val = $clkval;
                                         $get_n1_val = $n1_val;
                                         $get_n3_val = $n3_val;}
              }
          }#while
          close(READ_LOG);
          #-------------------------------------------------------------------------------------------------------------#
        }elsif($ck_value == 0 && $reset_val == 1 && $n1_vl == 0 && $n3_vl eq "vdd"){
          open(WRITE,">$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE "\n";
          print WRITE ".param v0=vss\n"; 
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*7.0'\n";
          print WRITE ".param t4='inputslew*10/6*8.0'\n";
          print WRITE ".param t5='inputslew*10/6*8.8'\n";
          print WRITE ".param t6='inputslew*10/6*9.0'\n";
          print WRITE ".param t7='inputslew*10/6*10.0'\n";
          print WRITE ".param t8='inputslew*10/6*10.2'\n";
          print WRITE ".param t9='inputslew*10/6*10.8'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n";
          print WRITE "*.nodeset v(n3)=vdd\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0 vss\n";
          print WRITE "\n";
          print WRITE "vrs vrs 0 vdd\n";
          print WRITE "\n";
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t0   v0\n"; 
          print WRITE "+               t1   v0\n";
          print WRITE "+               t2   v0\n";
          print WRITE "+               t3   v0\n";
          print WRITE "+               t4   v0\n";
          print WRITE "+               t5   v0\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v5\n"; 
          print WRITE "+               t1   v5\n";
          print WRITE "+               t2   v5\n";
          print WRITE "+               t3   v4\n";
          print WRITE "+               t4   v3\n";
          print WRITE "+               t5   v2\n";
          print WRITE "+               t6   v1\n";
          print WRITE "+               t7   v0\n";
          print WRITE "+               t8   v0\n";
          print WRITE "+               t9   v0\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE ".MODEL n NMOS\n"; 
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE "*.meas tran n1_first_fall when v(n1)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n3_first_fall when v(n3)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close (WRITE);
          ###############################################################################################################
          system("ngspice -b -o $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl"); 
          #-------------------------------------------------read log file-----------------------------------------------#
          open(READ_LOG,"$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log"); 
          while(<READ_LOG>){
          chomp();
            if($_ =~ /^n3_first_fall/){my $n3_first_fall = (split(/=\s+/,$_))[1];
              if($n3_first_fall ne ""){$get_clock_val = $ck_value;
                                       $get_n1_value = $n1_vl;
                                       $get_n3_value = $n3_vl;
                                       $get_reset_value = $reset_val;}
            }
          }#while reading log file
          close(READ_LOG);
          #------------------------------------------------------------------------------------------------------------------------------------#
        }elsif($ck_value == 1 && $reset_val == 1 && $n1_vl == 0 && $n3_vl eq "vdd"){
          open(WRITE,">$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE "\n";
          print WRITE ".param v0=vss\n"; 
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*7.0'\n";
          print WRITE ".param t4='inputslew*10/6*8.0'\n";
          print WRITE ".param t5='inputslew*10/6*8.8'\n";
          print WRITE ".param t6='inputslew*10/6*9.0'\n";
          print WRITE ".param t7='inputslew*10/6*10.0'\n";
          print WRITE ".param t8='inputslew*10/6*10.2'\n";
          print WRITE ".param t9='inputslew*10/6*10.8'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n";
          print WRITE "*.nodeset v(n3)=vdd\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0 vss\n";
          print WRITE "\n";
          print WRITE "vrs vrs 0 vdd\n";
          print WRITE "\n";
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t0   v5\n"; 
          print WRITE "+               t1   v5\n";
          print WRITE "+               t2   v5\n";
          print WRITE "+               t3   v5\n";
          print WRITE "+               t4   v5\n";
          print WRITE "+               t5   v5\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v5\n"; 
          print WRITE "+               t1   v5\n";
          print WRITE "+               t2   v5\n";
          print WRITE "+               t3   v4\n";
          print WRITE "+               t4   v3\n";
          print WRITE "+               t5   v2\n";
          print WRITE "+               t6   v1\n";
          print WRITE "+               t7   v0\n";
          print WRITE "+               t8   v0\n";
          print WRITE "+               t9   v0\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE "*.meas tran n1_first_fall when v(n1)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n3_first_fall when v(n3)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close (WRITE);
          #############################################################################################################################
          system("ngspice -b -o $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl"); 
          #-------------------------------------read log file-------------------------------------------------------------------------#
          open(READ_LOG,"$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log");
          while(<READ_LOG>){
          chomp();
            if($_ =~ /^n3_first_fall/){my $n3_first_fall = (split(/=\s+/,$_))[1];
              if($n3_first_fall ne ""){$get_clock_val = $ck_value;
                                     $get_n1_value = $n1_vl;
                                     $get_n3_value = $n3_vl;
                                     $get_reset_value = $reset_val;}
            }
          }#while reading log file
          close(READ_LOG);
          #---------------------------------------------------------------------------------------------------------------------------#
        }elsif($ck_value == 0 && $reset_val == 0 && $n1_vl == 0 && $n3_vl eq "vss"){
          open(WRITE,">$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE "\n";
          print WRITE ".param v0=vss\n"; 
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*7.0'\n";
          print WRITE ".param t4='inputslew*10/6*8.0'\n";
          print WRITE ".param t5='inputslew*10/6*8.8'\n";
          print WRITE ".param t6='inputslew*10/6*9.0'\n";
          print WRITE ".param t7='inputslew*10/6*10.0'\n";
          print WRITE ".param t8='inputslew*10/6*10.2'\n";
          print WRITE ".param t9='inputslew*10/6*10.8'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n";
          print WRITE "*.nodeset v(n3)=vss\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0 vss\n";
          print WRITE "\n";
          print WRITE "vrs vrs 0 vss\n";
          print WRITE "\n";
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t0   v0\n"; 
          print WRITE "+               t1   v0\n";
          print WRITE "+               t2   v0\n";
          print WRITE "+               t3   v0\n";
          print WRITE "+               t4   v0\n";
          print WRITE "+               t5   v0\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v5\n"; 
          print WRITE "+               t1   v5\n";
          print WRITE "+               t2   v5\n";
          print WRITE "+               t3   v4\n";
          print WRITE "+               t4   v3\n";
          print WRITE "+               t5   v2\n";
          print WRITE "+               t6   v1\n";
          print WRITE "+               t7   v0\n";
          print WRITE "+               t8   v0\n";
          print WRITE "+               t9   v0\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE "*.meas tran n1_first_fall when v(n1)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n3_first_rise when v(n3)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close (WRITE);
          ########################################################################################################################################
          system("ngspice -b -o $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          #-------------------------------------read log file------------------------------------------------------------------------------------# 
          open(READ_LOG,"$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log");
          while(<READ_LOG>){
          chomp();
            if($_ =~ /^n3_first_rise/){my $n3_first_rise = (split(/=\s+/,$_))[1];
              if($n3_first_rise ne ""){$get_clock_val = $ck_value;
                                       $get_n1_value = $n1_vl;
                                       $get_n3_value = $n3_vl;
                                       $get_reset_value = $reset_val;}
            }
          }#while reading log file
          close(READ_LOG);
          #--------------------------------------------------------------------------------------------------------------------------------------#
        }elsif($ck_value == 1 && $reset_val == 0 && $n1_vl == 0 && $n3_vl eq "vss"){
          open(WRITE,">$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl"); 
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE "\n";
          print WRITE ".param v0=vss\n"; 
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*7.0'\n";
          print WRITE ".param t4='inputslew*10/6*8.0'\n";
          print WRITE ".param t5='inputslew*10/6*8.8'\n";
          print WRITE ".param t6='inputslew*10/6*9.0'\n";
          print WRITE ".param t7='inputslew*10/6*10.0'\n";
          print WRITE ".param t8='inputslew*10/6*10.2'\n";
          print WRITE ".param t9='inputslew*10/6*10.8'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n";
          print WRITE "*.nodeset v(n3)=vss\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0 vss\n";
          print WRITE "\n";
          print WRITE "vrs vrs 0 vss\n";
          print WRITE "\n";
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t0   v5\n"; 
          print WRITE "+               t1   v5\n";
          print WRITE "+               t2   v5\n";
          print WRITE "+               t3   v5\n";
          print WRITE "+               t4   v5\n";
          print WRITE "+               t5   v5\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v5\n"; 
          print WRITE "+               t1   v5\n";
          print WRITE "+               t2   v5\n";
          print WRITE "+               t3   v4\n";
          print WRITE "+               t4   v3\n";
          print WRITE "+               t5   v2\n";
          print WRITE "+               t6   v1\n";
          print WRITE "+               t7   v0\n";
          print WRITE "+               t8   v0\n";
          print WRITE "+               t9   v0\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE "*.meas tran n1_first_fall when v(n1)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n3_first_rise when v(n3)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close (WRITE);
          ####################################################################################################################################
          system("ngspice -b -o $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl"); 
          #-------------------------------------read log file--------------------------------------------------------------------------------#
          open(READ_LOG,"$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log");
          while(<READ_LOG>){
          chomp();
            if($_ =~ /^n3_first_rise/){my $n3_first_rise = (split(/=\s+/,$_))[1];
              if($n3_first_rise ne ""){$get_clock_val = $ck_value;
                                       $get_n1_value = $n1_vl;
                                       $get_n3_value = $n3_vl;
                                       $get_reset_value = $reset_val;}
            }
          }#while reading log file
          close(READ_LOG);
          #-----------------------------------------------------------------------------------------------------------------------------------#
        }elsif($ck_value == 0 && $reset_val == 1 && $n1_vl == 0 && $n3_vl eq "vss"){
          open(WRITE,">$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl"); 
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE "\n";
          print WRITE ".param v0=vss\n"; 
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*7.0'\n";
          print WRITE ".param t4='inputslew*10/6*8.0'\n";
          print WRITE ".param t5='inputslew*10/6*8.8'\n";
          print WRITE ".param t6='inputslew*10/6*9.0'\n";
          print WRITE ".param t7='inputslew*10/6*10.0'\n";
          print WRITE ".param t8='inputslew*10/6*10.2'\n";
          print WRITE ".param t9='inputslew*10/6*10.8'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n";
          print WRITE "*.nodeset v(n3)=vss\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0 vss\n";
          print WRITE "\n";
          print WRITE "vrs vrs 0 vdd\n";
          print WRITE "\n";
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t0   v0\n"; 
          print WRITE "+               t1   v0\n";
          print WRITE "+               t2   v0\n";
          print WRITE "+               t3   v0\n";
          print WRITE "+               t4   v0\n";
          print WRITE "+               t5   v0\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v5\n"; 
          print WRITE "+               t1   v5\n";
          print WRITE "+               t2   v5\n";
          print WRITE "+               t3   v4\n";
          print WRITE "+               t4   v3\n";
          print WRITE "+               t5   v2\n";
          print WRITE "+               t6   v1\n";
          print WRITE "+               t7   v0\n";
          print WRITE "+               t8   v0\n";
          print WRITE "+               t9   v0\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE "*.meas tran n1_first_fall when v(n1)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n3_first_rise when v(n3)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close (WRITE);
          ####################################################################################################################################
          system("ngspice -b -o $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl"); 
          #-------------------------------------read log file--------------------------------------------------------------------------------#
          open(READ_LOG,"$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log");
          while(<READ_LOG>){
          chomp();
            if($_ =~ /^n3_first_rise/){my $n3_first_rise = (split(/=\s+/,$_))[1];
              if($n3_first_rise ne ""){$get_clock_val = $ck_value;
                                       $get_n1_value = $n1_vl;
                                       $get_n3_value = $n3_vl;
                                       $get_reset_value = $reset_val;}
            }
          }#while reading log file
          close(READ_LOG);
          #-----------------------------------------------------------------------------------------------------------------------------------#
        }elsif($ck_value == 1 && $reset_val == 1 && $n1_vl == 0 && $n3_vl eq "vss"){
          open(WRITE,">$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE "\n";
          print WRITE ".param v0=vss\n"; 
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*7.0'\n";
          print WRITE ".param t4='inputslew*10/6*8.0'\n";
          print WRITE ".param t5='inputslew*10/6*8.8'\n";
          print WRITE ".param t6='inputslew*10/6*9.0'\n";
          print WRITE ".param t7='inputslew*10/6*10.0'\n";
          print WRITE ".param t8='inputslew*10/6*10.2'\n";
          print WRITE ".param t9='inputslew*10/6*10.8'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n";
          print WRITE "*.nodeset v(n3)=vss\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0 vss\n";
          print WRITE "\n";
          print WRITE "vrs vrs 0 vdd\n";
          print WRITE "\n";
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t0   v5\n"; 
          print WRITE "+               t1   v5\n";
          print WRITE "+               t2   v5\n";
          print WRITE "+               t3   v5\n";
          print WRITE "+               t4   v5\n";
          print WRITE "+               t5   v5\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v5\n"; 
          print WRITE "+               t1   v5\n";
          print WRITE "+               t2   v5\n";
          print WRITE "+               t3   v4\n";
          print WRITE "+               t4   v3\n";
          print WRITE "+               t5   v2\n";
          print WRITE "+               t6   v1\n";
          print WRITE "+               t7   v0\n";
          print WRITE "+               t8   v0\n";
          print WRITE "+               t9   v0\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE "*.meas tran n1_first_fall when v(n1)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n3_first_rise when v(n3)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close (WRITE);
          ######################################################################################################################################
          system ("ngspice -b -o $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          #--------------------------------------read log file---------------------------------------------------------------------------------# 
          open(READ_LOG,"$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log");
          while(<READ_LOG>){
          chomp();
            if($_ =~ /^n3_first_rise/){my $n3_first_rise = (split(/=\s+/,$_))[1];
              if($n3_first_rise ne ""){$get_clock_val = $ck_value;
                                       $get_n1_value = $n1_vl;
                                       $get_n3_value = $n3_vl;
                                       $get_reset_value = $reset_val;}
            }
          }#while reading log file
          close(READ_LOG);
          #-------------------------------------------------------------------------------------------------------------------------------------#
        }elsif($ck_value == 0 && $reset_val == 0 && $n1_vl == 1 && $n3_vl eq "vdd"){
          open(WRITE,">$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE "\n";
          print WRITE ".param v0=vss\n"; 
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*7.0'\n";
          print WRITE ".param t4='inputslew*10/6*8.0'\n";
          print WRITE ".param t5='inputslew*10/6*8.8'\n";
          print WRITE ".param t6='inputslew*10/6*9.0'\n";
          print WRITE ".param t7='inputslew*10/6*10.0'\n";
          print WRITE ".param t8='inputslew*10/6*10.2'\n";
          print WRITE ".param t9='inputslew*10/6*10.8'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n";
          print WRITE "*.nodeset v(n3)=vdd\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0 vss\n";
          print WRITE "\n";
          print WRITE "vrs vrs 0 vss\n";
          print WRITE "\n";
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t0   v0\n"; 
          print WRITE "+               t1   v0\n";
          print WRITE "+               t2   v0\n";
          print WRITE "+               t3   v0\n";
          print WRITE "+               t4   v0\n";
          print WRITE "+               t5   v0\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v0\n"; 
          print WRITE "+               t1   v0\n";
          print WRITE "+               t2   v0\n";
          print WRITE "+               t3   v1\n";
          print WRITE "+               t4   v2\n";
          print WRITE "+               t5   v3\n";
          print WRITE "+               t6   v4\n";
          print WRITE "+               t7   v5\n";
          print WRITE "+               t8   v5\n";
          print WRITE "+               t9   v5\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE ".meas tran n1_first_fall when v(n1)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE "*.meas tran n3_first_rise when v(n3)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close (WRITE);
          ############################################################################################################################################################
          system("ngspice -b -o $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          #-------------------------------------------------------read log file--------------------------------------------------------------------------------------# 
          open(READ_LOG,"$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log");
          while(<READ_LOG>){
          chomp(); 
            if($_ =~ /^n3_first_fall/){my $n3_first_fall = (split(/=\s+/,$_))[1];
              if($n3_first_fall ne ""){$get_n2_value = $ck_value;
                                       $get_reset_val = $reset_val;}
              } 
          }#while reading log file
          close(READ_LOG);
          #-----------------------------------------------------------------------------------------------------------------------------------------------------------#
        }elsif($ck_value == 1 && $reset_val == 0 && $n1_vl == 1 && $n3_vl eq "vdd"){
          open(WRITE,">$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE "\n";
          print WRITE ".param v0=vss\n"; 
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*7.0'\n";
          print WRITE ".param t4='inputslew*10/6*8.0'\n";
          print WRITE ".param t5='inputslew*10/6*8.8'\n";
          print WRITE ".param t6='inputslew*10/6*9.0'\n";
          print WRITE ".param t7='inputslew*10/6*10.0'\n";
          print WRITE ".param t8='inputslew*10/6*10.2'\n";
          print WRITE ".param t9='inputslew*10/6*10.8'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n";
          print WRITE "*.nodeset v(n3)=vdd\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0 vss\n";
          print WRITE "\n";
          print WRITE "vrs vrs 0 vss\n";
          print WRITE "\n";
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t0   v5\n"; 
          print WRITE "+               t1   v5\n";
          print WRITE "+               t2   v5\n";
          print WRITE "+               t3   v5\n";
          print WRITE "+               t4   v5\n";
          print WRITE "+               t5   v5\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v0\n"; 
          print WRITE "+               t1   v0\n";
          print WRITE "+               t2   v0\n";
          print WRITE "+               t3   v1\n";
          print WRITE "+               t4   v2\n";
          print WRITE "+               t5   v3\n";
          print WRITE "+               t6   v4\n";
          print WRITE "+               t7   v5\n";
          print WRITE "+               t8   v5\n";
          print WRITE "+               t9   v5\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE ".meas tran n1_first_fall when v(n1)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE "*.meas tran n3_first_rise when v(n3)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close (WRITE);
          ###################################################################################################################################################
          system("ngspice -b -o $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          #--------------------------------------------------------------read log file----------------------------------------------------------------------# 
          open(READ_LOG,"$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log");
          while(<READ_LOG>){
          chomp();
            if($_ =~ /^n3_first_fall/){my $n3_first_fall = (split(/=\s+/,$_))[1];
              if($n3_first_fall ne ""){$get_n2_value = $ck_value;
                                       $get_reset_val = $reset_val;}
               }
          }#while reading log file
          close(READ_LOG);
          #-------------------------------------------------------------------------------------------------------------------------------------------------#
        }elsif($ck_value == 0 && $reset_val == 1 && $n1_vl == 1 && $n3_vl eq "vdd"){
          open(WRITE,">$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl"); 
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE "\n";
          print WRITE ".param v0=vss\n"; 
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*7.0'\n";
          print WRITE ".param t4='inputslew*10/6*8.0'\n";
          print WRITE ".param t5='inputslew*10/6*8.8'\n";
          print WRITE ".param t6='inputslew*10/6*9.0'\n";
          print WRITE ".param t7='inputslew*10/6*10.0'\n";
          print WRITE ".param t8='inputslew*10/6*10.2'\n";
          print WRITE ".param t9='inputslew*10/6*10.8'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n";
          print WRITE "*.nodeset v(n3)=vdd\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0 vss\n";
          print WRITE "\n";
          print WRITE "vrs vrs 0 vdd\n";
          print WRITE "\n";
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t0   v0\n"; 
          print WRITE "+               t1   v0\n";
          print WRITE "+               t2   v0\n";
          print WRITE "+               t3   v0\n";
          print WRITE "+               t4   v0\n";
          print WRITE "+               t5   v0\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v0\n"; 
          print WRITE "+               t1   v0\n";
          print WRITE "+               t2   v0\n";
          print WRITE "+               t3   v1\n";
          print WRITE "+               t4   v2\n";
          print WRITE "+               t5   v3\n";
          print WRITE "+               t6   v4\n";
          print WRITE "+               t7   v5\n";
          print WRITE "+               t8   v5\n";
          print WRITE "+               t9   v5\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE ".meas tran n1_first_fall when v(n1)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE "*.meas tran n3_first_rise when v(n3)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close (WRITE);
          ########################################################################################################################################
          system("ngspice -b -o $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          #---------------------------------------------------------read log file----------------------------------------------------------------# 
          open(READ_LOG,"$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log");
          while(<READ_LOG>){
          chomp();
            if($_ =~ /^n3_first_fall/){my $n3_first_fall = (split(/=\s+/,$_))[1];
              if($n3_first_fall ne ""){$get_n2_value = $ck_value;
                                       $get_reset_val = $reset_val;}
              } 
          }#while reading log file
          close(READ_LOG);
          #---------------------------------------------------------------------------------------------------------------------------------------#
        }elsif($ck_value == 1 && $reset_val == 1 && $n1_vl == 1 && $n3_vl eq "vdd"){
          open(WRITE,">$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if ($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if ($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE "\n";
          print WRITE ".param v0=vss\n"; 
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*7.0'\n";
          print WRITE ".param t4='inputslew*10/6*8.0'\n";
          print WRITE ".param t5='inputslew*10/6*8.8'\n";
          print WRITE ".param t6='inputslew*10/6*9.0'\n";
          print WRITE ".param t7='inputslew*10/6*10.0'\n";
          print WRITE ".param t8='inputslew*10/6*10.2'\n";
          print WRITE ".param t9='inputslew*10/6*10.8'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n";
          print WRITE "*.nodeset v(n3)=vdd\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0 vss\n";
          print WRITE "\n";
          print WRITE "vrs vrs 0 vdd\n";
          print WRITE "\n";
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t0   v5\n"; 
          print WRITE "+               t1   v5\n";
          print WRITE "+               t2   v5\n";
          print WRITE "+               t3   v5\n";
          print WRITE "+               t4   v5\n";
          print WRITE "+               t5   v5\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v0\n"; 
          print WRITE "+               t1   v0\n";
          print WRITE "+               t2   v0\n";
          print WRITE "+               t3   v1\n";
          print WRITE "+               t4   v2\n";
          print WRITE "+               t5   v3\n";
          print WRITE "+               t6   v4\n";
          print WRITE "+               t7   v5\n";
          print WRITE "+               t8   v5\n";
          print WRITE "+               t9   v5\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE ".meas tran n1_first_fall when v(n1)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE "*.meas tran n3_first_rise when v(n3)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close (WRITE);
          ##########################################################################################################################################
          system("ngspice -b -o $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          #---------------------------------------------------------read log file------------------------------------------------------------------# 
          open(READ_LOG,"$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log");
          while(<READ_LOG>){
          chomp();
            if($_ =~ /^n3_first_fall/){my $n3_first_fall = (split(/=\s+/,$_))[1];
              if($n3_first_fall ne ""){$get_n2_value = $ck_value;
                                       $get_reset_val = $reset_val;}
              }
          }#while reading log file
          close(READ_LOG);
          #---------------------------------------------------------------------------------------------------------------------------------------#
        }elsif($ck_value == 0 && $reset_val == 0 && $n1_vl == 1 && $n3_vl eq "vss"){
          open(WRITE,">$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if ($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if ($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE "\n";
          print WRITE ".param v0=vss\n"; 
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*7.0'\n";
          print WRITE ".param t4='inputslew*10/6*8.0'\n";
          print WRITE ".param t5='inputslew*10/6*8.8'\n";
          print WRITE ".param t6='inputslew*10/6*9.0'\n";
          print WRITE ".param t7='inputslew*10/6*10.0'\n";
          print WRITE ".param t8='inputslew*10/6*10.2'\n";
          print WRITE ".param t9='inputslew*10/6*10.8'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n";
          print WRITE "*.nodeset v(n3)=vss\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0 vss\n";
          print WRITE "\n";
          print WRITE "vrs vrs 0 vss\n";
          print WRITE "\n";
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t0   v0\n"; 
          print WRITE "+               t1   v0\n";
          print WRITE "+               t2   v0\n";
          print WRITE "+               t3   v0\n";
          print WRITE "+               t4   v0\n";
          print WRITE "+               t5   v0\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v0\n"; 
          print WRITE "+               t1   v0\n";
          print WRITE "+               t2   v0\n";
          print WRITE "+               t3   v1\n";
          print WRITE "+               t4   v2\n";
          print WRITE "+               t5   v3\n";
          print WRITE "+               t6   v4\n";
          print WRITE "+               t7   v5\n";
          print WRITE "+               t8   v5\n";
          print WRITE "+               t9   v5\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE "*.meas tran n1_first_fall when v(n1)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n3_first_rise when v(n3)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close (WRITE);
          ####################################################################################################################################
          system("ngspice -b -o $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl"); 
          #---------------------------------------------------------read log file------------------------------------------------------------#
          open(READ_LOG,"$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log");
          while(<READ_LOG>){
          chomp();
            if($_ =~ /^n3_first_rise/){my $n3_first_rise = (split(/=\s+/,$_))[1];
              if($n3_first_rise ne ""){$get_n2_value = $ck_value;
                                       $get_reset_val = $reset_val;}
              } 
          }#while reading log file 
          close(READ_LOG);
          #----------------------------------------------------------------------------------------------------------------------------------#
        }elsif($ck_value == 1 && $reset_val == 0 && $n1_vl == 1 && $n3_vl eq "vss"){
          open(WRITE,">$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if ($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if ($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE "\n";
          print WRITE ".param v0=vss\n"; 
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*7.0'\n";
          print WRITE ".param t4='inputslew*10/6*8.0'\n";
          print WRITE ".param t5='inputslew*10/6*8.8'\n";
          print WRITE ".param t6='inputslew*10/6*9.0'\n";
          print WRITE ".param t7='inputslew*10/6*10.0'\n";
          print WRITE ".param t8='inputslew*10/6*10.2'\n";
          print WRITE ".param t9='inputslew*10/6*10.8'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n";
          print WRITE "*.nodeset v(n3)=vss\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0 vss\n";
          print WRITE "\n";
          print WRITE "vrs vrs 0 vss\n";
          print WRITE "\n";
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t0   v5\n"; 
          print WRITE "+               t1   v5\n";
          print WRITE "+               t2   v5\n";
          print WRITE "+               t3   v5\n";
          print WRITE "+               t4   v5\n";
          print WRITE "+               t5   v5\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v0\n"; 
          print WRITE "+               t1   v0\n";
          print WRITE "+               t2   v0\n";
          print WRITE "+               t3   v1\n";
          print WRITE "+               t4   v2\n";
          print WRITE "+               t5   v3\n";
          print WRITE "+               t6   v4\n";
          print WRITE "+               t7   v5\n";
          print WRITE "+               t8   v5\n";
          print WRITE "+               t9   v5\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE "*.meas tran n1_first_fall when v(n1)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n3_first_rise when v(n3)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close (WRITE);
          #############################################################################################################################
          system("ngspice -b -o $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          #---------------------------------------------------------read log file-----------------------------------------------------# 
          open(READ_LOG,"$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          while(<READ_LOG>){
          chomp();
            if($_ =~ /^n3_first_rise/){my $n3_first_rise = (split(/=\s+/,$_))[1];
              if($n3_first_rise ne ""){$get_n2_value = $ck_value;
                                       $get_reset_val = $reset_val;}
              } 
          }#while reading log file
          close(READ_LOG);
          #--------------------------------------------------------------------------------------------------------------------------#
        }elsif($ck_value == 0 && $reset_val == 1 && $n1_vl == 1 && $n3_vl eq "vss"){
          open(WRITE,">$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl"); 
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if ($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if ($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE "\n";
          print WRITE ".param v0=vss\n"; 
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*7.0'\n";
          print WRITE ".param t4='inputslew*10/6*8.0'\n";
          print WRITE ".param t5='inputslew*10/6*8.8'\n";
          print WRITE ".param t6='inputslew*10/6*9.0'\n";
          print WRITE ".param t7='inputslew*10/6*10.0'\n";
          print WRITE ".param t8='inputslew*10/6*10.2'\n";
          print WRITE ".param t9='inputslew*10/6*10.8'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n";
          print WRITE "*.nodeset v(n3)=vss\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0 vss\n";
          print WRITE "\n";
          print WRITE "vrs vrs 0 vdd\n";
          print WRITE "\n";
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t0   v0\n"; 
          print WRITE "+               t1   v0\n";
          print WRITE "+               t2   v0\n";
          print WRITE "+               t3   v0\n";
          print WRITE "+               t4   v0\n";
          print WRITE "+               t5   v0\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v0\n"; 
          print WRITE "+               t1   v0\n";
          print WRITE "+               t2   v0\n";
          print WRITE "+               t3   v1\n";
          print WRITE "+               t4   v2\n";
          print WRITE "+               t5   v3\n";
          print WRITE "+               t6   v4\n";
          print WRITE "+               t7   v5\n";
          print WRITE "+               t8   v5\n";
          print WRITE "+               t9   v5\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE "*.meas tran n1_first_fall when v(n1)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n3_first_rise when v(n3)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close (WRITE);
          #############################################################################################################################
          system("ngspice -b -o $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          #---------------------------------------------------------read log file-----------------------------------------------------# 
          open(READ_LOG,"$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          while(<READ_LOG>){
          chomp();
            if($_ =~ /^n3_first_rise/){my $n3_first_rise = (split(/=\s+/,$_))[1];
              if($n3_first_rise ne ""){$get_n2_value = $ck_value;
                                       $get_reset_val = $reset_val;}
              } 
          }#while reading log file
          close(READ_LOG);
          #---------------------------------------------------------------------------------------------------------------------------#
        }elsif($ck_value == 1 && $reset_val == 1 && $n1_vl == 1 && $n3_vl eq "vss"){
          open(WRITE,">$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          print WRITE ".title Fanout Versus Delay (TSMC)\n";
          print WRITE "\n";
          print WRITE ".param vdd=$vdd_pri_val\n";
          print WRITE ".param vddsec=$vdd_pri_val\n" if ($vdd_sec_val eq "");
          print WRITE ".param vddsec=$vdd_sec_val\n" if ($vdd_sec_val ne "");
          print WRITE ".param vss=$vss_val\n";
          print WRITE ".param wp=$wp\n";
          print WRITE ".param wn=$wn\n";
          print WRITE ".param vlo='0.2*vdd'\n";
          print WRITE ".param vmid='0.5*vdd'\n";
          print WRITE ".param vhi='0.8*vdd'\n";
          print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
          print WRITE ".param inputslew=$input_slew_val_1_with_unit\n";
          print WRITE "\n";
          print WRITE ".param v0=vss\n"; 
          print WRITE ".param v1=vss\n";
          print WRITE ".param v2=vlo\n";
          print WRITE ".param v3=vhi\n";
          print WRITE ".param v4=vdd\n";
          print WRITE ".param v5=vdd\n";
          print WRITE ".param v6=vhi\n";
          print WRITE ".param v7=vlo\n";
          print WRITE ".param v8=vss\n";
          print WRITE ".param v9=vss\n";
          print WRITE "\n";
          print WRITE ".param t0='inputslew*10/6*0.0'\n"; 
          print WRITE ".param t1='inputslew*10/6*1.0'\n";
          print WRITE ".param t2='inputslew*10/6*1.2'\n";
          print WRITE ".param t3='inputslew*10/6*7.0'\n";
          print WRITE ".param t4='inputslew*10/6*8.0'\n";
          print WRITE ".param t5='inputslew*10/6*8.8'\n";
          print WRITE ".param t6='inputslew*10/6*9.0'\n";
          print WRITE ".param t7='inputslew*10/6*10.0'\n";
          print WRITE ".param t8='inputslew*10/6*10.2'\n";
          print WRITE ".param t9='inputslew*10/6*10.8'\n";
          print WRITE "\n";
          print WRITE ".param t_sec0='inputslew*10/6*0.0 + 5e-9'\n"; 
          print WRITE ".param t_sec1='inputslew*10/6*1.0 + 5e-9'\n";
          print WRITE ".param t_sec2='inputslew*10/6*1.2 + 5e-9'\n";
          print WRITE ".param t_sec3='inputslew*10/6*1.8 + 5e-9'\n";
          print WRITE ".param t_sec4='inputslew*10/6*2.0 + 5e-9'\n";
          print WRITE ".param t_sec5='inputslew*10/6*3.0 + 5e-9'\n";
          print WRITE ".param t_sec6='inputslew*10/6*3.2 + 5e-9'\n";
          print WRITE ".param t_sec7='inputslew*10/6*3.8 + 5e-9'\n";
          print WRITE ".param t_sec8='inputslew*10/6*4.0 + 5e-9'\n";
          print WRITE ".param t_sec9='inputslew*10/6*5.0 + 5e-9'\n";
          print WRITE "\n";
          print WRITE "*.nodeset v(n3)=vss\n";
          print WRITE "\n";
          print WRITE "vdd vdd 0 vdd\n";
          print WRITE "vddsec vddsec 0 vddsec\n";
          print WRITE "vss vss 0 vss\n";
          print WRITE "\n";
          print WRITE "vrs vrs 0 vdd\n";
          print WRITE "\n";
          print WRITE "vin n2 vss pwl(\n";
          print WRITE "+               t0   v5\n"; 
          print WRITE "+               t1   v5\n";
          print WRITE "+               t2   v5\n";
          print WRITE "+               t3   v5\n";
          print WRITE "+               t4   v5\n";
          print WRITE "+               t5   v5\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE "vin0 n1 vss pwl(\n";
          print WRITE "+               t0   v0\n"; 
          print WRITE "+               t1   v0\n";
          print WRITE "+               t2   v0\n";
          print WRITE "+               t3   v1\n";
          print WRITE "+               t4   v2\n";
          print WRITE "+               t5   v3\n";
          print WRITE "+               t6   v4\n";
          print WRITE "+               t7   v5\n";
          print WRITE "+               t8   v5\n";
          print WRITE "+               t9   v5\n";
          print WRITE "+             )\n";
          print WRITE "\n";
          print WRITE ".MODEL n NMOS\n";
          print WRITE ".MODEL p PMOS\n";
          print WRITE ".MODEL nd NMOS\n";
          print WRITE ".MODEL pd PMOS\n";
          print WRITE "\n";
          print WRITE "\n";
          print WRITE ".include $new_file_spice\n";
          print WRITE "x$cellName @get_new_port_list $cellName\n";
          print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
          print WRITE "C1 $output_port 0 opcap\n";
          print WRITE "\n";
          print WRITE ".temp 85\n";
          print WRITE ".tran 10p 500n\n";
          print WRITE "\n";
          print WRITE "*.meas tran n1_first_fall when v(n1)=vmid fall=1\n";
          print WRITE "\n";
          print WRITE ".meas tran n3_first_rise when v(n3)=vmid rise=1\n";
          print WRITE "\n";
          print WRITE ".end\n";
          close (WRITE);
          #############################################################################################################################
          system("ngspice -b -o $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log $file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl");
          #--------------------------------------------------------------read log file------------------------------------------------#
          open(READ_LOG,"$file-$clk-$ck_value-$reset_port-$reset_val-n1_$n1_vl-n3_$n3_vl.log");
          while(<READ_LOG>){
          chomp();
            if($_ =~ /^n3_first_rise/){my $n3_first_rise = (split(/=\s+/,$_))[1];
              if($n3_first_rise ne ""){$get_n2_value = $ck_value;
                                       $get_reset_val = $reset_val;}
            }
          }#while reading log file
          close(READ_LOG);
          #----------------------------------------------------------------------------------------------------------------------------#
        }
      }#for
    }#for clk
  }#for n3
}#for n1 
if($get_n2_value == $get_clock_val && $get_reset_val == $get_reset_value ){print "INFO : clock and reset values are correct and the clock value is $get_clock_val and reset value is $get_reset_value\n";}
else {print "WARN : Please check the value of clock and reset\n";}
#-----------------------------------------------test bench for setup time and hold time------------------------------------------------#
for(my $in_slew_clk=0;$in_slew_clk<=$#input_slew_clock;$in_slew_clk++){
  for(my $in_slew_data=0;$in_slew_data<=$#input_slew;$in_slew_data++){
    my $input_slew_data = $input_slew[$in_slew_data];
    my $input_slew_data_value_with_unit = $input_slew[$in_slew_data].""."e-9";
    my $input_slew_clk = $input_slew_clock[$in_slew_clk];
    my $input_slew_clk_value_with_unit = $input_slew_clock[$in_slew_clk].""."e-9";
    my $get_n3_first_rise_from_n1_n2_delay_0 = "";
    my $get_n3_first_fall_from_n1_n2_delay_0 = "";
    my $setup_time_negative_for_fall = 0;
    my $setup_time_positive_for_fall = 0;
    my $setup_time_negative_for_rise = 0;
    my $setup_time_positive_for_rise = 0;
    my $set_up_time_for_rise_nanosecond = "";
    my $set_up_time_for_fall_nanosecond = "";
    open(WRITE,">$file-setup_for_rise-n1_n2_delay_0-$input_slew_data-$input_slew_clk");
    print WRITE ".title Fanout Versus Delay (TSMC)\n";
    print WRITE "\n";
    print WRITE ".param vdd=$vdd_pri_val\n";
    print WRITE ".param vddsec=$vdd_pri_val\n"if($vdd_sec_val eq "");
    print WRITE ".param vddsec=$vdd_sec_val\n"if($vdd_sec_val ne "");
    print WRITE ".param vss=$vss_val\n";
    print WRITE ".param wp=$wp\n";
    print WRITE ".param wn=$wn\n";
    print WRITE ".param vlo='0.2*vdd'\n";
    print WRITE ".param vmid='0.5*vdd'\n";
    print WRITE ".param vhi='0.8*vdd'\n";
    print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
    print WRITE ".param inputslew=$input_slew_data_value_with_unit\n";
    print WRITE "\n";
    print WRITE ".param v0=vss\n"; 
    print WRITE ".param v1=vss\n";
    print WRITE ".param v2=vlo\n";
    print WRITE ".param v3=vhi\n";
    print WRITE ".param v4=vdd\n";
    print WRITE ".param v5=vdd\n";
    print WRITE ".param v6=vhi\n";
    print WRITE ".param v7=vlo\n";
    print WRITE ".param v8=vss\n";
    print WRITE ".param v9=vss\n";
    print WRITE "\n";
    print WRITE ".param powerparam=0\n";
    print WRITE ".param divisor='2**powerparam'\n";
    print WRITE "*.param n1_n2_delay='10e-09/divisor'\n";
    print WRITE ".param n1_n2_delay=0\n";
    print WRITE "\n";
    print WRITE ".param t0 = 0\n"; 
    print WRITE ".param t1 =30e-09\n";
    print WRITE ".param t2 ='30e-09 + 10/6*inputslew*20/100'\n"; 
    print WRITE ".param t3 ='30e-09 + 10/6*inputslew*80/100'\n";
    print WRITE ".param t4 ='30e-09 + 10/6*inputslew*100/100'\n"; 
    print WRITE ".param t5 =35e-09\n"; 
    print WRITE "\n";
    print WRITE ".param t_0=0\n";
    print WRITE ".param t_1=10e-09\n";
    print WRITE ".param t_2='10e-09 + 10/6*inputslew*20/100'\n";
    print WRITE ".param t_3='10e-09 + 10/6*inputslew*80/100'\n";
    print WRITE ".param t_4='10e-09 + 10/6*inputslew*100/100'\n";
    print WRITE ".param t_5='30e-09 - n1_n2_delay'\n";
    print WRITE ".param t_6='t_5 + 10/6*inputslew*20/100'\n";
    print WRITE ".param t_7='t_5 + 10/6*inputslew*80/100'\n";
    print WRITE ".param t_8='t_5 + 10/6*inputslew*100/100'\n";
    print WRITE ".param t_9=60e-09\n";
    print WRITE "\n";
    print WRITE "\n";
    print WRITE "*.nodeset v(n3)=vdd\n";
    print WRITE "\n";
    print WRITE "vdd vdd 0 vdd\n";
    print WRITE "vddsec vddsec 0 vddsec\n";
    print WRITE "vss vss 0 vss\n";
    print WRITE "\n";
    print WRITE "vrs vrs 0 vss\n";
    print WRITE "\n";
    print WRITE "vin0 n1 vss pwl(\n";
    print WRITE "+               t0   v0\n"; 
    print WRITE "+               t1   v1\n";
    print WRITE "+               t2   v2\n";
    print WRITE "+               t3   v3\n";
    print WRITE "+               t4   v4\n";
    print WRITE "+               t5   v5\n";
    print WRITE "+             )\n";
    print WRITE "\n";
    print WRITE "vin n2 vss pwl(\n";
    print WRITE "+               t_0   v5\n"; 
    print WRITE "+               t_1   v4\n";
    print WRITE "+               t_2   v3\n";
    print WRITE "+               t_3   v2\n";
    print WRITE "+               t_4   v1\n";
    print WRITE "+               t_5   v1\n";
    print WRITE "+               t_6   v2\n";
    print WRITE "+               t_7   v3\n";
    print WRITE "+               t_8   v4\n";
    print WRITE "+               t_9   v5\n";
    print WRITE "+             )\n";
    print WRITE "\n";
    print WRITE ".MODEL n NMOS\n";
    print WRITE ".MODEL p PMOS\n";
    print WRITE ".MODEL nd NMOS\n";
    print WRITE ".MODEL pd PMOS\n";
    print WRITE "\n";
    print WRITE "\n";
    print WRITE ".include $new_file_spice\n";
    print WRITE "x$cellName @get_new_port_list $cellName\n";
    print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
    print WRITE "C1 $output_port 0 opcap\n";
    print WRITE "\n";
    print WRITE ".temp 85\n";
    print WRITE ".tran 10p 500n\n";
    print WRITE "\n";
    print WRITE "*.meas tran n1_first_rise when v(n1)=vmid rise=1\n";
    print WRITE "\n";
    print WRITE ".meas tran n3_first_rise when v(n3)=vmid rise=1\n";
    print WRITE "\n";
    print WRITE ".end\n";
    close (WRITE);
    ########################################################################################################################################################################
    system ("ngspice -b -o $file-setup_for_rise-n1_n2_delay_0-$input_slew_data-$input_slew_clk.log $file-setup_for_rise-n1_n2_delay_0-$input_slew_data-$input_slew_clk"); 
    #--------------------------------------------read log file of first test bench n3_first_rise---------------------------------------------------------------------------#
    open(READ_LOG,"$file-setup_for_rise-n1_n2_delay_0-$input_slew_data-$input_slew_clk.log");
    while(<READ_LOG>){
    chomp();
      if($_ =~ /^n3_first_rise/){$get_n3_first_rise_from_n1_n2_delay_0 = (split(/=\s+/,$_))[1];
      }
    }#while    
    close(READ_LOG); 
    #----------------------------------------------------------------------------------------------------------------------------------------------------------------------#
    if($get_n3_first_rise_from_n1_n2_delay_0 ne ""){
      my $n3_transistion_found = 0;
      my $power_param = 0;
      while ($n3_transistion_found == 0){
        my $n3_firstrise = "";
        open(WRITE,">$file-setup_for_rise-$input_slew_data-$input_slew_clk-$power_param");
        print WRITE ".title Fanout Versus Delay (TSMC)\n";
        print WRITE "\n";
        print WRITE ".param vdd=$vdd_pri_val\n";
        print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
        print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
        print WRITE ".param vss=$vss_val\n";
        print WRITE ".param wp=$wp\n";
        print WRITE ".param wn=$wn\n";
        print WRITE ".param vlo='0.2*vdd'\n";
        print WRITE ".param vmid='0.5*vdd'\n";
        print WRITE ".param vhi='0.8*vdd'\n";
        print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
        print WRITE ".param inputslew=$input_slew_data_value_with_unit\n";
        print WRITE "\n";
        print WRITE ".param v0=vss\n"; 
        print WRITE ".param v1=vss\n";
        print WRITE ".param v2=vlo\n";
        print WRITE ".param v3=vhi\n";
        print WRITE ".param v4=vdd\n";
        print WRITE ".param v5=vdd\n";
        print WRITE ".param v6=vhi\n";
        print WRITE ".param v7=vlo\n";
        print WRITE ".param v8=vss\n";
        print WRITE ".param v9=vss\n";
        print WRITE "\n";
        print WRITE ".param powerparam=$powerparam\n";
        print WRITE ".param divisor='2**powerparam'\n";
        print WRITE ".param n1_n2_delay='10e-09/divisor'\n";
        print WRITE "*.param n1_n2_delay=0\n";
        print WRITE "\n";
        print WRITE ".param t0 = 0\n"; 
        print WRITE ".param t1 =30e-09\n";
        print WRITE ".param t2 ='30e-09 + 10/6*inputslew*20/100'\n"; 
        print WRITE ".param t3 ='30e-09 + 10/6*inputslew*80/100'\n";
        print WRITE ".param t4 ='30e-09 + 10/6*inputslew*100/100'\n"; 
        print WRITE ".param t5 =35e-09\n"; 
        print WRITE "\n";
        print WRITE ".param t_0=0\n";
        print WRITE ".param t_1=10e-09\n";
        print WRITE ".param t_2='10e-09 + 10/6*inputslew*20/100'\n";
        print WRITE ".param t_3='10e-09 + 10/6*inputslew*80/100'\n";
        print WRITE ".param t_4='10e-09 + 10/6*inputslew*100/100'\n";
        print WRITE ".param t_5='30e-09 - n1_n2_delay'\n";
        print WRITE ".param t_6='t_5 + 10/6*inputslew*20/100'\n";
        print WRITE ".param t_7='t_5 + 10/6*inputslew*80/100'\n";
        print WRITE ".param t_8='t_5 + 10/6*inputslew*100/100'\n";
        print WRITE "*.param t_9=60e-09\n";
        print WRITE "\n";
        print WRITE "\n";
        print WRITE "\n";
        print WRITE "*.nodeset v(n3)=vdd\n";
        print WRITE "\n";
        print WRITE "vdd vdd 0 vdd\n";
        print WRITE "vddsec vddsec 0 vddsec\n";
        print WRITE "vss vss 0 vss\n";
        print WRITE "\n";
        print WRITE "vrs vrs 0 vss\n";
        print WRITE "\n";
        print WRITE "vin0 n1 vss pwl(\n";
        print WRITE "+               t0   v0\n"; 
        print WRITE "+               t1   v1\n";
        print WRITE "+               t2   v2\n";
        print WRITE "+               t3   v3\n";
        print WRITE "+               t4   v4\n";
        print WRITE "+               t5   v5\n";
        print WRITE "+             )\n";
        print WRITE "\n";
        print WRITE "vin n2 vss pwl(\n";
        print WRITE "+               t_0   v5\n"; 
        print WRITE "+               t_1   v4\n";
        print WRITE "+               t_2   v3\n";
        print WRITE "+               t_3   v2\n";
        print WRITE "+               t_4   v1\n";
        print WRITE "+               t_5   v1\n";
        print WRITE "+               t_6   v2\n";
        print WRITE "+               t_7   v3\n";
        print WRITE "+               t_8   v4\n";
        print WRITE "*+               t_9   v5\n";
        print WRITE "+             )\n";
        print WRITE "\n";
        print WRITE ".MODEL n NMOS\n";
        print WRITE ".MODEL p PMOS\n";
        print WRITE ".MODEL nd NMOS\n";
        print WRITE ".MODEL pd PMOS\n";
        print WRITE "\n";
        print WRITE "\n";
        print WRITE ".include $new_file_spice\n";
        print WRITE "x$cellName @get_new_port_list $cellName\n";
        print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
        print WRITE "C1 $output_port 0 opcap\n";
        print WRITE "\n";
        print WRITE ".temp 85\n";
        print WRITE ".tran 10p 500n\n";
        print WRITE "\n";
        print WRITE "*.meas tran n1_first_rise when v(n1)=vmid rise=1\n";
        print WRITE "\n";
        print WRITE ".meas tran n3_first_rise when v(n3)=vmid rise=1\n";
        print WRITE "\n";
        print WRITE ".end\n";
        close (WRITE);
        ###########################################################################################################################################################
        system ("ngspice -b -o $file-setup_for_rise-$input_slew_data-$input_slew_clk-$power_param.log $file-setup_for_rise-$input_slew_data-$input_slew_clk-$power_param"); 
        #---------------------------------------------------------------read log file-----------------------------------------------------------------------------#
        open(READ_LOG,"$file-setup_for_rise-$input_slew_data-$input_slew_clk-$power_param.log");
        while(<READ_LOG>){
        chomp();
          if($_ =~ /^n3_first_rise/){$n3_first_rise = (split(/=\s+/,$_))[1];}
        }#while
        close(READ_LOG);
        if($n3_firstrise eq ""){
          $n3_transistion_found = 0;
          $power_param++;
        }else{$n3_transistion_found = 1;
           my $divisor=2**$power_param;
           my $n1_n2_delay = -(10e-09/$divisor);
           $set_up_time_for_rise_nanosecond = $n1_n2_delay*(10**9);
           $setup_time_negative_for_rise = 1;
           push(@setup_time_list_for_rise,$set_up_time_for_rise_nanosecond);
        }
      }#while n3_transistion_found_for_rise
    }else {
        my $n3_transistion_found_for_rise = 1;
        my $power_param = 0;
        while($n3_transistion_found_for_rise == 1){
        my $n3_first_rise = "";
        open(WRITE,">$file-setup_for_rise-$input_slew_data-$input_slew_clk-$power_param");
        print WRITE ".title Fanout Versus Delay (TSMC)\n";
        print WRITE "\n";
        print WRITE ".param vdd=$vdd_pri_val\n";
        print WRITE ".param vddsec=$vdd_pri_val\n" if($vdd_sec_val eq "");
        print WRITE ".param vddsec=$vdd_sec_val\n" if($vdd_sec_val ne "");
        print WRITE ".param vss=$vss_val\n";
        print WRITE ".param wp=$wp\n";
        print WRITE ".param wn=$wn\n";
        print WRITE ".param vlo='0.2*vdd'\n";
        print WRITE ".param vmid='0.5*vdd'\n";
        print WRITE ".param vhi='0.8*vdd'\n";
        print WRITE ".param opcap=$op_cap_val_1_with_unit\n";
        print WRITE ".param inputslew=$input_slew_data_value_with_unit\n";
        print WRITE "\n";
        print WRITE ".param v0=vss\n"; 
        print WRITE ".param v1=vss\n";
        print WRITE ".param v2=vlo\n";
        print WRITE ".param v3=vhi\n";
        print WRITE ".param v4=vdd\n";
        print WRITE ".param v5=vdd\n";
        print WRITE ".param v6=vhi\n";
        print WRITE ".param v7=vlo\n";
        print WRITE ".param v8=vss\n";
        print WRITE ".param v9=vss\n";
        print WRITE "\n";
        print WRITE ".param powerparam=$power_param\n";
        print WRITE ".param divisor='2**powerparam'\n";
        print WRITE ".param n1_n2_delay='10e-09/divisor'\n";
        print WRITE "*.param n1_n2_delay=0\n";
        print WRITE "\n";
        print WRITE ".param t0 = 0\n"; 
        print WRITE ".param t1 =30e-09\n";
        print WRITE ".param t2 ='30e-09 + 10/6*inputslew*20/100'\n"; 
        print WRITE ".param t3 ='30e-09 + 10/6*inputslew*80/100'\n";
        print WRITE ".param t4 ='30e-09 + 10/6*inputslew*100/100'\n"; 
        print WRITE ".param t5 =35e-09\n"; 
        print WRITE "\n";
        print WRITE ".param t_0=0\n";
        print WRITE ".param t_1=10e-09\n";
        print WRITE ".param t_2='10e-09 + 10/6*inputslew*20/100'\n";
        print WRITE ".param t_3='10e-09 + 10/6*inputslew*80/100'\n";
        print WRITE ".param t_4='10e-09 + 10/6*inputslew*100/100'\n";
        print WRITE ".param t_5='30e-09 + n1_n2_delay'\n";
        print WRITE ".param t_6='t_5 + 10/6*inputslew*20/100'\n";
        print WRITE ".param t_7='t_5 + 10/6*inputslew*80/100'\n";
        print WRITE ".param t_8='t_5 + 10/6*inputslew*100/100'\n";
        print WRITE "*.param t_9=60e-09\n";
        print WRITE "\n";
        print WRITE "\n";
        print WRITE "*.nodeset v(n3)=vdd\n";
        print WRITE "\n";
        print WRITE "vdd vdd 0 vdd\n";
        print WRITE "vddsec vddsec 0 vddsec\n";
        print WRITE "vss vss 0 vss\n";
        print WRITE "\n";
        print WRITE "vrs vrs 0 vss\n";
        print WRITE "\n";
        print WRITE "vin0 n1 vss pwl(\n";
        print WRITE "+               t0   v0\n"; 
        print WRITE "+               t1   v1\n";
        print WRITE "+               t2   v2\n";
        print WRITE "+               t3   v3\n";
        print WRITE "+               t4   v4\n";
        print WRITE "+               t5   v5\n";
        print WRITE "+             )\n";
        print WRITE "\n";
        print WRITE "vin n2 vss pwl(\n";
        print WRITE "+               t_0   v5\n"; 
        print WRITE "+               t_1   v4\n";
        print WRITE "+               t_2   v3\n";
        print WRITE "+               t_3   v2\n";
        print WRITE "+               t_4   v1\n";
        print WRITE "+               t_5   v1\n";
        print WRITE "+               t_6   v2\n";
        print WRITE "+               t_7   v3\n";
        print WRITE "+               t_8   v4\n";
        print WRITE "*+               t_9   v5\n";
        print WRITE "+             )\n";
        print WRITE "\n";
        print WRITE ".MODEL n NMOS\n";
        print WRITE ".MODEL p PMOS\n";
        print WRITE ".MODEL nd NMOS\n";
        print WRITE ".MODEL pd PMOS\n";
        print WRITE "\n";
        print WRITE "\n";
        print WRITE ".include $new_file_spice\n";
        print WRITE "x$cellName @get_new_port_list $cellName\n";
        print WRITE "*xx$cellName @get_new_port_list1 $cellName\n";
        print WRITE "C1 $output_port 0 opcap\n";
        print WRITE "\n";
        print WRITE ".temp 85\n";
        print WRITE ".tran 10p 500n\n";
        print WRITE "\n";
        print WRITE "*.meas tran n1_first_rise when v(n1)=vmid rise=1\n";
        print WRITE "\n";
        print WRITE ".meas tran n3_first_rise when v(n3)=vmid rise=1\n";
        print WRITE "\n";
        print WRITE ".end\n";
        close (WRITE);
        ###################################################################################################################################################################
        system ("ngspice -b -o $file-setup_for_rise-$input_slew_data-$input_slew_clk-$power_param.log $file-setup_for_rise-$input_slew_data-$input_slew_clk-$power_param");
        #---------------------------------------------------read log file-------------------------------------------------------------------------------------------------# 
        open(READ_LOG,"$file-setup_for_rise-$input_slew_data-$input_slew_clk-$power_param.log");
        while(<READ_LOG>){
        chomp();
          if($_ =~ /^n3_first_rise/){$n3_first_rise = (split(/=\s+/,$_))[1];}
        }#while reading log file
        close(READ_LOG);
        if($n3_first_rise ne ""){
          $n3_transistion_found_for_rise = 1;
          $power_param++;
        }else{
              $n3_transistion_found_for_rise = 0;
              my $before_power_param = ($power_param -1);
              my $divisor = 2**$before_power_param; 
              my $n1_n2_delay = (10e-09/$divisor);
              $set_up_time_for_rise_nanosecond = $n1_n2_delay*(10**9);
              $setup_time_positive_for_rise = 1; 
              push(@setup_time_list_for_rise,$set_up_time_for_rise_nanosecond); 
        }
      }#while n3_transistion_found_for_rise
    }#else
    #------------------------------------------------test bench for setup time for n3_first_fall--------------------------------------------------------------------------#
  }#for
}#for
}#sub read_file_for_latch
