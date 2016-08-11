#!/usr/bin/perl 
my $fileName = "";
my $parameter_file = "";
my $file_given = 0;
my $unit_in_micron = 0;
my $dir = "";
my $dir_given = 0;
my %PORT_DATA = ();
my %TRANS_DATA = ();
my %INST_DATA = ();

for(my $i =0; $i<=$#ARGV;$i++){
if($ARGV[$i] eq "-f"){$fileName = $ARGV[$i+1];$file_given =1;}
if($ARGV[$i] eq "-d"){$dir = $ARGV[$i+1];$dir_given =1;}
if($ARGV[$i] eq "-p"){$parameter_file = $ARGV[$i+1];}
if($ARGV[$i] eq "-micron"){$unit_in_micron = 1;}
}
#----------------------------------------------------------------#
if($dir_given == 1){
  my @spifiles = `find  -L $dir -name \\*\\.spi -o -name \\*\\.sp`;
  foreach my $filename (@spifiles){
    if($filename eq "."|| $filename eq ".."){next;}
      chomp($filename);
      %PORT_DATA = ();
      %TRANS_DATA = ();
      %INST_DATA = ();
      my $file_get = &read_subckt($filename);
      &read_file($file_get);
  }
}
#-----------------------------------------------------------------------#
if($file_given == 1){
   %PORT_DATA = ();
   %TRANS_DATA = ();
   %INST_DATA = ();
   my $file_get = &read_subckt($fileName);
   &read_file($file_get);
}
sub read_file {
my $file = $_[0];
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
my @input = ();
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
my $new_file = "";
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
    s/ \$X.*=.*\$Y.*=.*\$D.*=.*$//;
    print WRITE_NG "$_\n";
  }
}
close(WRITE_NG);
close(READ);
#-------------------------------------------------------------------------#
$new_file = $new_file_spice;
$new_file =~ s/\.ngspice//;
open(READ_SP,"$new_file_spice");
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
  if(($port =~ /vdd/) || ($port =~ /VDD/) || ($port =~ /vss/) || ($port =~ /VSS/) || ($port =~ /gnd/) || ($port =~ /GND/) || ($port =~ /vdar_t/)){}
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
#--------------------------------------------------------------------------------------------------------#
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
  if(($port =~ /vdd/) || ($port =~ /VDD/) || ($port =~ /vdar_t/)){
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
             if(@bits > 1){
                my ($cond, $sdf_cond) = get_cond_and_sdf_cond($rel_pin,\@bits,\@input_list);
                print WRITE_LIB "   condition : $cond\n";
                print WRITE_LIB "   sdf_cond : $sdf_cond\n";
             }
             my @get_new_port_list = ();
             my $pwr_cnt = 0;
             my $dRise = "";
             my $dFall = "";
             my $type = "";
             my $p_join = "";
             my @drise_list = ();
             my @dfall_list = ();
             my @slewr_list = ();
             my @slewf_list = ();

             foreach my $port (@cell_data){
               if($port eq $out){
                  push(@get_new_port_list,"n3");
               }elsif($port =~ /vd/i){
                  $pwr_cnt++;
                  if($pwr_cnt == 1){
                    push(@get_new_port_list,$vdd_pri);
                  }elsif($pwr_cnt == 2){
                    push(@get_new_port_list,$vdd_sec);
                  }
               }elsif($port =~ /vss/i){
                 push(@get_new_port_list,$vss_name);
               }elsif($port =~ /$rel_pin/){
                  push(@get_new_port_list,"n2");
                  my $related_pin_val = $bits[$input_index{$rel_pin}]; 
                  if($related_pin_val == 1){
                    $dRise = "rise=1"; $dFall="fall=1";
                    $type = $out."_noninv";
                  }else{
                    $dRise = "fall=1"; $dFall="rise=1";
                    $type = $out."_inv";
                  }
               }else{
                  if(exists $INPUT{$port}){
                     my $pin_val = $bits[$input_index{$port}]; 
                     if   ($pin_val == 0){push(@get_new_port_list,"vss"); $p_join = $p_join."-".$port."_vss";}
                     elsif($pin_val == 1){push(@get_new_port_list,"vdd"); $p_join = $p_join."-".$port."_vdd";}
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
                     open(WRITE,">$new_file-$rel_pin-$input_slew_value-$op_cap-$p_join-$type");
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
                     print WRITE "\n";
                     print WRITE "vdd vdd 0 vdd\n";
                     print WRITE "vddsec vddsec 0 vddsec\n";
                     print WRITE "vss vss 0   vss\n";
                     print WRITE "\n";
                     print WRITE "vin n2 vss pwl( \n";
                     print WRITE "+               t0   v0 \n";
                     print WRITE "+               t1   v1\n";
                     print WRITE "+               t2   v2\n";
                     print WRITE "+               t3   v3\n";
                     print WRITE "+               t4   v4\n";
                     print WRITE "+               t5   v5\n";
                     print WRITE "+               t6   v6\n";
                     print WRITE "+               t7   v7\n";
                     print WRITE "+               t8   v8\n";
                     print WRITE "+               t9   v9\n";
                     print WRITE "+             )\n";
                     print WRITE ".MODEL nd NMOS\n";
                     print WRITE ".MODEL pd PMOS\n";
                     print WRITE "\n";
                     print WRITE "\n";
                     #----------------------------------------------------------------#
                     print WRITE ".include $new_file_spice\n";
                     print WRITE "x$cellName @get_new_port_list $cellName\n";
                     print WRITE "C1 n3 0 opcap\n"; 
                     print WRITE "\n";
                     print WRITE ".temp 85\n";
                     print WRITE ".tran 10p 500n\n";
                     print WRITE "\n";
                     print WRITE ".meas tran n2_first_fall when v(n2)=vmid fall=1\n";
                     print WRITE "\n";
                     print WRITE ".meas tran n3_first_rise when v(n3)=vmid rise=1\n";
                     print WRITE "\n";
                     print WRITE ".meas tran drise trig v(n2) val=vmid $dRise\n";
                     print WRITE "+                targ v(n3) val=vmid rise=1\n";
                     print WRITE "\n";
                     print WRITE ".meas tran dfall trig v(n2) val=vmid $dFall\n";
                     print WRITE "+                targ v(n3) val=vmid fall=1\n";
                     print WRITE "\n";
                     print WRITE ".meas tran slewr trig v(n3) val=vlo rise=1\n";
                     print WRITE "+                targ v(n3) val=vhi rise=1\n";
                     print WRITE "\n";
                     print WRITE ".meas tran slewf trig v(n3) val=vhi fall=1\n";
                     print WRITE "+                targ v(n3) val=vlo fall=1\n";
                     print WRITE "\n";
                     print WRITE ".end\n";
                     ############################################################## run ngspice###########################################################
                     system ("ngspice -b -o $new_file-$rel_pin-$input_slew_value-$op_cap-$p_join-$type.log $new_file-$rel_pin-$input_slew_value-$op_cap-$p_join-$type");
                     #####################################################################################################################################
                     #----------------------------------------------------------read log file of ngspice--------------------------------------------------#
                     open(READ_NG_LOG,"$new_file-$rel_pin-$input_slew_value-$op_cap-$p_join-$type.log");
                     while(<READ_NG_LOG>){
                     chomp();
                       if($_ =~ /^drise/){s/\s*drise\s*//;my $drise = (split(/=\s+/,$_))[1];
                         $drise =~ s/\s*targ//;
                         my ($n,$m) = (split(/e/,$drise))[0,1];
                         my $m = $m+9;
                         my $drise_new = $n*(10**$m);
                         push(@drise_list,$drise_new);
                       }
                       if($_ =~ /^dfall/){s/\s*dfall\s*//;my $dfall = (split(/=\s+/,$_))[1];
                         $dfall =~ s/\s*targ//;
                         my ($n,$m) = (split(/e/,$dfall))[0,1];
                         my $m = $m+9;
                         my $dfall_new = $n*(10**$m);
                         push(@dfall_list,$dfall_new);
                       }
                       if($_ =~ /^slewr/){s/\s*slewr\s*//;my $slewr = (split(/=\s+/,$_))[1];
                         $slewr =~ s/\s*targ//;
                         my ($n,$m) = (split(/e/,$slewr))[0,1];
                         my $m = $m+9;
                         my $slewr_new = $n*(10**$m);
                         push(@slewr_list,$slewr_new);
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
                 }#foreach output cap
             }#foreach input slew
             print WRITE_LIB "       cell_rise @drise_list\n";
             print WRITE_LIB "       rise_transition @slewr_list\n";
             print WRITE_LIB "       cell_fall @dfall_list\n";
             print WRITE_LIB "       fall_transition @slewf_list\n";
         }#foreach condition
      }#foreach related pin
  }#foreach output
close(WRITE_LIB);
#&write_lib("-genlib","$cellName.genlib","-lib","$fileName.lib");
&write_lib("-genlib","$cellName.genlib","-lib","$new_file.lib");
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

#----------------------------------------------------------------------------------------------------------------------------------#
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
   my $rel_pin = "";
   my $cond = "";
   my $sdf_cond = "";

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

        my $attr3 = liberty::si2drGroupCreateAttr($group1, "date", $liberty::SI2DR_SIMPLE, \$x);
        liberty::si2drSimpleAttrSetStringValue($attr3, "Friday April 01 14:54:29 2011", \$x);

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

        ##my $d = liberty::si2drCreateExpr($liberty::SI2DR_EXPR_VAL,\$x);
        #my $d = liberty::si2drCreateStringValExpr($dir,\$x);
        #print "$pin | dir : $dir , $d , $attr \n";
        #liberty::si2drSimpleAttrSetExprValue($attr, $d, \$x);

     }elsif($_ =~ /^function\s+/){
        my $function = (split(/\:/,$_))[1];
        $function =~ s/^\s+//;

        my $attr = liberty::si2drGroupCreateAttr($group1_1_1, "function", $liberty::SI2DR_SIMPLE, \$x);
        liberty::si2drSimpleAttrSetStringValue($attr, $function, \$x);

     }elsif($_ =~ /^related_pin\s+/){
        $rel_pin = (split(/\s+/,$_))[1];

     }elsif($_ =~ /^condition\s+/){
        $cond = (split(/\:/,$_))[1];
        $cond =~ s/^\s+//;

     }elsif($_ =~ /^sdf_cond\s+/){
        $sdf_cond = (split(/\:/,$_))[1];
        $sdf_cond =~ s/^\s+//;

     }elsif($_ =~ /^cell_rise\s+/){
        my @rise_delay = split(/\s+/,$_);

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

        $group1_1_1_1_1 = liberty::si2drGroupCreateGroup($group1_1_1_1, "delay_template" , "cell_rise", \$x);

        my $attr1 = liberty::si2drGroupCreateAttr($group1_1_1_1_1, "index_1 ", $liberty::SI2DR_COMPLEX, \$x);
        my $index_1 = join ", " ,@index_1;
        liberty::si2drComplexAttrAddStringValue($attr1, $index_1, \$x);

        my $attr2 = liberty::si2drGroupCreateAttr($group1_1_1_1_1, "index_2 ", $liberty::SI2DR_COMPLEX, \$x);
        my $index_2 = join ", " ,@index_2;
        liberty::si2drComplexAttrAddStringValue($attr2, $index_2, \$x);

        my $attr3 = liberty::si2drGroupCreateAttr($group1_1_1_1_1, "values ", $liberty::SI2DR_COMPLEX, \$x);
        shift @rise_delay;
        for(my $i=0; $i<$#rise_delay; $i=($i+$#index_1+1)){
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
        for(my $i=0; $i<$#rise_trans; $i=($i+$#index_1+1)){
           my @new_rise_trans = ();
           for(my $j=$i; $j<($i+$#index_2+1); $j++){
              push(@new_rise_trans, $rise_trans[$j])
           }
           my $rise_tra = join ", ",@new_rise_trans;
           liberty::si2drComplexAttrAddStringValue($attr3, $rise_tra, \$x);
        }

     }elsif($_ =~ /^cell_fall\s+/){
        my @fall_delay = split(/\s+/,$_);

        $group1_1_1_1_3 = liberty::si2drGroupCreateGroup($group1_1_1_1, "delay_template", "cell_fall", \$x);
 
        my $attr1 = liberty::si2drGroupCreateAttr($group1_1_1_1_3, "index_1", $liberty::SI2DR_COMPLEX, \$x);
        my $index_1 = join ", " ,@index_1;
        liberty::si2drComplexAttrAddStringValue($attr1, $index_1, \$x);

        my $attr2 = liberty::si2drGroupCreateAttr($group1_1_1_1_3, "index_2", $liberty::SI2DR_COMPLEX, \$x);
        my $index_2 = join ", " ,@index_2;
        liberty::si2drComplexAttrAddStringValue($attr2, $index_2, \$x);

        my $attr3 = liberty::si2drGroupCreateAttr($group1_1_1_1_3, "values", $liberty::SI2DR_COMPLEX, \$x);
        shift @fall_delay;
        for(my $i=0; $i<$#fall_delay; $i=($i+$#index_1+1)){
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
        for(my $i=0; $i<$#fall_trans; $i=($i+$#index_1+1)){
           my @new_fall_trans = ();
           for(my $j=$i; $j<($i+$#index_2+1); $j++){
              push(@new_fall_trans, $fall_trans[$j])
           }
           my $rise_tra = join ", ",@new_fall_trans;
           liberty::si2drComplexAttrAddStringValue($attr3, $rise_tra, \$x);
        }

     }else{next;}
   }#while reading 
   close READ;
   liberty::si2drWriteLibertyFile($output_file, $group1, \$x);
   liberty::si2drPIQuit(\$x);
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
sub read_subckt {
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
open(READ,"$file_name");
my $previous_line = "";
my $next_line = "";
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
      $previous_line =~ s/^\s*\.(subckt|SUBCKT)\s*//;
      @cell_data = (split(/\s+/,$previous_line));
      $cellName = shift(@cell_data);
      $TOTAL_CELL_HASH{$cellName} = 1; 
      @{$PORT_DATA{$cellName}} = @cell_data;
    }elsif($previous_line=~ /^\s*m\s*/i || $previous_line=~ /^\s*c\s*/i){
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
  }#if read_subckt
  $previous_line = $next_line;
}#while

#----------------------- if file is already flat --------------------------#
my @cells  = keys %TOTAL_CELL_HASH;
if(@cells ==1){
   if(-e $cells[0]."-flat.sp"){
     return $file_name;
   }else{
     my $flat_sp_file = $cells[0]."-flat.sp";
     system("cp $file_name $flat_sp_file");
     return $flat_sp_file;
   } 
}elsif(@cells <= 0){return $file_name}; 
#--------------------------------------------------------------------------#
  #while((keys %INST_DATA) > 1){
    foreach my $cell (keys %INST_DATA){
      my @instance_data = @{$INST_DATA{$cell}}; 
      foreach my $data ( @instance_data){
        my $type = "";
        my @data_list = split(/\s+/,$data);
        for(my $i=0; $i<@data_list; $i++){
           if($data_list[$i] =~ m/wn/){
              $type = $data_list[$i-1];
              last;
           }
        }
        #my @key  = keys %TRANS_DATA;
        #print "keys of trans hash @key\n";
        &replace_data($cell, $type, $data);
      }
    }
  #}

sub replace_data {
my $cell = $_[0];
my $type = $_[1];
my $data_line = $_[2];
#my @key  = keys %TRANS_DATA;
#print "2nd time keys of trans hash @key\n";
   if(exists $INST_DATA{$type}){
      my @instance_data = @{$INST_DATA{$type}};
      foreach my $data (@instance_data){ 
        my $type1 = "";
        my @data_list = split(/\s+/,$data);
        for(my $i=0; $i<@data_list; $i++){
           if($data_list[$i] =~ m/wn/){
              $type1 = $data_list[$i-1];
              last;
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
           my ($drain,$gate,$source) = (split(/\s+/,$trans_name))[1,2,3];
           if(!exists $cell_port_list{$drain}){$trans_name =~ s/\b$drain\b/$drain$xname/g;} 
           if(!exists $cell_port_list{$gate}){$trans_name =~ s/\b$gate\b/$gate$xname/g;}
           if(!exists $cell_port_list{$source}){$trans_name =~ s/\b$source\b/$source$xname/g;}
           foreach my $map (keys %map_hash){
             my $val = $map_hash{$map};
             $trans_name =~ s/\b$map\b/$val/g;
           }
           push (@{$TRANS_DATA{$cell}}, $trans_name);
           my $cell_not_exist = &check_cell_not_exists($cell,$type,$data_line);
           if($cell_not_exist == 1){
              delete $TRANS_DATA{$type};
              my @key =  keys %TRANS_DATA;
              delete $PORT_DATA{$type};
              my @inst_hash_val = @{$INST_DATA{$cell}};
              if(@inst_hash_val <= 1){
                 delete $INST_DATA{$cell};
              }
           }
         }
       }
   }
}#sub replace_data

sub check_cell_not_exists{
my $cell = $_[0];
my $ckt_name = $_[1];
my $data_line_arg = $_[2];
  foreach my $type (keys %INST_DATA){
     my @data  = @{$INST_DATA{$type}};
     my $count = 0;
     foreach my $data_line(@data){
       if($cell eq $type && $data_line_arg eq $data_line){
         delete $data[$count];  
         @{$INST_DATA{$type}} = @data;
       }
       my @data_list = split(/\s+/,$data_line);
       for(my $i=0; $i<@data_list; $i++){
           if($data_list[$i] =~ m/wn/){
              
              if($ckt_name eq $data_list[$i-1]){return 0;};
           }
        }
        $count++;
     }
  }
  return 1;
}#sub check_cell_not_exists
my $flat_sp_file = "";
foreach my $mdata (keys %TRANS_DATA){
  my @port_list  = @{$PORT_DATA{$mdata}};
  $flat_sp_file = "$mdata-flat.sp"; 
  open(WRITE,">$flat_sp_file");
    print WRITE".subckt $mdata @port_list\n";
    my @value = @{$TRANS_DATA{$mdata}};
    foreach my $val (@value){
       print WRITE "$val\n";
    }
    print WRITE".end $mdata\n";
  close WRITE;
} 
return ($flat_sp_file);
}#sub read_subckt
#----------------------------------------------------------------------------------------------------------------#

