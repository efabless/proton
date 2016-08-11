#!/usr/bin/perl 
my $file_Name = "";
my $parameter_file = "";
my $file_given = 0;
for(my $i=0;$i<=$#ARGV;$i++){
  if($ARGV[$i] eq "-f"){$file_Name = $ARGV[$i+1];$file_given = 1;}
  if($ARGV[$i] eq "-p"){$parameter_file = $ARGV[$i+1];}
}
if($file_given == 1){
  #my ($clk, $out, $in) = &get_sequential($file_Name);
  #print "$clk, $out ,$in\n";
  #if($clk ne "" && $out ne "" && $in ne ""){
    &read_file_for_seq($file_Name);
  #}
}
#---------------------------------------read seq file--------------------------# 
sub read_file_for_seq {
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
#-----------------------------------------------created input output list------------------------------------------#
if($cellName eq ""){print "ERR:We are not getting cellName from .spi file\n";}
foreach my $mdata (sort {$a cmp $b}keys %SPICE_DATA){
  my @data_new = @{$SPICE_DATA{$mdata}};
  my $data_new_var = join" ",@data_new;
  my ($drain,$gate,$source,$type) = (split(/\s+/,$data_new_var))[0,1,2,4];
  foreach my $port (@cell_data){
    if(($port =~ /vdd/) || ($port =~ /VDD/) || ($port =~ /vss/) || ($port =~ /VSS/) || ($port =~ /gnd/) || ($port =~ /GND/) || ($port =~ /vdar_t/)){}
    else {
      if($cellName =~ m/mux/i){
         if($port eq $gate || $port eq $source){
           $INPUT{$port} = 1 if(!exists $INPUT{$port});
         }elsif($port eq $drain){
            $OUTPUT{$port} = 1 if(!exists $OUTPUT{$port});
         }
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
my @get_new_portlist0 = ();
my @get_new_portlist1 = ();
my ($clk, $out, $in) = &get_sequential($file);
foreach my $port (@cell_data){
  if($port =~ /vd/i){
    push(@get_new_portlist0,$port);
    push(@get_new_portlist1,$port);
  }elsif($port =~ /vss/i){
    push(@get_new_portlist0,$port);
    push(@get_new_portlist1,$port);
  }elsif($port =~/$clk/){
    push(@get_new_portlist0,"n2");
    push(@get_new_portlist1,"n2");
  }elsif($port =~ /$out/){
    push(@get_new_portlist0,"n3");
    push(@get_new_portlist1,"n4");
  }elsif($port =~ /$in/){
    push(@get_new_portlist0,"n1");
    push(@get_new_portlist1,"n3");
  }
}#foreach port 
################################################write test bench##########################################
  my $ns = @input_slew;
  my $nopcap = @opcap;
  my @drise_list = ();
  my @slewr_list = ();
  my @dfall_list = ();
  my @slewf_list = ();
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
    print WRITE_GENLIB "  output $out QN\n";
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
        #-------------------------------writing test bench for dfall and slewf-----------------------------------------#
        open(WRITE,">$file-dfall-$input_slew_value-$op_cap");
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
        print WRITE ".nodeset v(n3)=vdd\n";
        print WRITE "vdd vdd 0 vdd\n";
        print WRITE "vddsec vddsec 0 vddsec\n";
        print WRITE "vss vss 0   vss\n";
        print WRITE "\n";
        print WRITE "vin n2 vss pwl(\n"; 
        print WRITE "+               t_sec0   v0\n"; 
        print WRITE "+               t_sec1   v1\n";
        print WRITE "+               t_sec2   v2\n";
        print WRITE "+               t_sec3   v3\n";
        print WRITE "+               t_sec4   v4\n";
        print WRITE "+               t_sec5   v5\n";
        print WRITE "+               t_sec6   v6\n";
        print WRITE "+               t_sec7   v7\n";
        print WRITE "+               t_sec8   v8\n";
        print WRITE "+               t_sec9   v9\n";
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
        print WRITE ".MODEL n NMOS\n";
        print WRITE ".MODEL p PMOS\n";
        print WRITE "\n";
        print WRITE "\n";
        print WRITE ".include $new_file_spice\n";
        #print WRITE "x1sff1_x4 n2 n1 n3 vdd vss sff1_x4\n";
        print WRITE "x$cellName @get_new_portlist0 $cellName\n";
        #print WRITE "x1sff1_x4 n2 n3 n4 vdd vss sff1_x4\n";
        print WRITE "xx$cellName @get_new_portlist1 $cellName\n";
        print WRITE "\n";
        print WRITE ".temp 85\n";
        print WRITE ".tran 10p 500n\n";
        print WRITE "\n";
        print WRITE ".meas tran n1_first_fall when v(n1)=vmid fall=1\n";
        print WRITE "\n";
        print WRITE ".meas tran n2_first_fall when v(n2)=vmid fall=1\n";
        print WRITE "\n";
        print WRITE ".meas tran n2_first_rise when v(n2)=vmid rise=1\n";
        print WRITE "\n";
        print WRITE ".meas tran n3_first_fall when v(n3)=vmid fall=1\n";
        print WRITE "\n";
        print WRITE ".meas tran dfall trig v(n2) val=vmid rise=1\n";
        print WRITE "+                targ v(n3) val=vmid fall=1\n";
        print WRITE "\n";
        print WRITE ".meas tran slewf trig v(n3) val=vhi fall=1\n";
        print WRITE "+                targ v(n3) val=vlo fall=1\n";
        print WRITE "\n";
        print WRITE ".end\n";
        close(WRITE);
        #-----------------------------------------------writing test bench for drise and slewr----------------------------------------------#
        open (WRITE,">$file-drise-$input_slew_value-$op_cap");
        print WRITE ".title Fanout Versus Delay (TSMC)\n";
        print WRITE "\n";
        print WRITE ".param vdd=$vdd_pri_val\n";
        if($vdd_sec_val eq ""){
        print WRITE ".param vddsec=$vdd_pri_val\n";
        }else{
        print WRITE ".param vddsec=$vdd_sec_val\n";
        }
        print WRITE ".param vss=0.0\n";
        print WRITE ".param wp=3.00e-06\n";
        print WRITE ".param wn=1.20e-06\n";
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
        print WRITE ".nodeset v(n3)=vss\n";
        print WRITE "vdd vdd 0 vdd\n";
        print WRITE "vddsec vddsec 0 vddsec\n";
        print WRITE "vss vss 0   vss\n";
        print WRITE "\n";
        print WRITE "vin n2 vss pwl(\n"; 
        print WRITE "+               t_sec0   v0\n"; 
        print WRITE "+               t_sec1   v1\n";
        print WRITE "+               t_sec2   v2\n";
        print WRITE "+               t_sec3   v3\n";
        print WRITE "+               t_sec4   v4\n";
        print WRITE "+               t_sec5   v5\n";
        print WRITE "+               t_sec6   v6\n";
        print WRITE "+               t_sec7   v7\n";
        print WRITE "+               t_sec8   v8\n";
        print WRITE "+               t_sec9   v9\n";
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
        print WRITE "\n";
        print WRITE "\n";
        print WRITE ".include $new_file_spice\n";
        #print WRITE "x1sff1_x4 n2 n1 n3 vdd vss sff1_x4\n";
        print WRITE "x$cellName @get_new_portlist0 $cellName\n";
        #print WRITE "x1sff1_x4 n2 n3 n4 vdd vss sff1_x4\n";
        print WRITE "xx$cellName @get_new_portlist1 $cellName\n";
        #print WRITE ".include ./sff1_x4.spi\n";
        #print WRITE "x1sff1_x4 n2 n1 n3 vdd vss sff1_x4\n";
        #print WRITE "x1sff1_x4 n2 n3 n4 vdd vss sff1_x4\n";
        print WRITE "\n";
        print WRITE ".temp 85\n";
        print WRITE ".tran 10p 500n\n";
        print WRITE "\n";
        print WRITE ".meas tran n1_first_rise when v(n1)=vmid rise=1\n";
        print WRITE "\n";
        print WRITE ".meas tran n2_first_fall when v(n2)=vmid fall=1\n";
        print WRITE "\n";
        print WRITE ".meas tran n2_first_rise when v(n2)=vmid rise=1\n";
        print WRITE "\n";
        print WRITE ".meas tran n3_first_rise when v(n3)=vmid rise=1\n";
        print WRITE "\n";
        print WRITE ".meas tran drise trig v(n2) val=vmid rise=1\n";
        print WRITE "+                targ v(n3) val=vmid rise=1\n";
        print WRITE "\n";
        print WRITE ".meas tran slewr trig v(n3) val=vlo rise=1\n";
        print WRITE "+                targ v(n3) val=vhi rise=1\n";
        print WRITE "\n";
        print WRITE ".end\n";
        close(WRITE);
        ###########################################################run ngspice###########################################################
        system ("ngspice -b -o $file-dfall-$input_slew_value-$op_cap.log $file-dfall-$input_slew_value-$op_cap");
        system ("ngspice -b -o $file-drise-$input_slew_value-$op_cap.log $file-drise-$input_slew_value-$op_cap");
        #################################################################################################################################
        #-----------------------------read log file of ngspice for dfall and slewf---------------------------------------------#
        open(READ_NG_LOG,"$file-dfall-$input_slew_value-$op_cap.log");
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
        open(READ_NG_LOG,"$file-drise-$input_slew_value-$op_cap.log");
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
        #------------------------------------------------------------------------------------------#
      }#for output cap
    }#for input slew
    #if(@drise_list == ($ns+$nopcap) && @slewr_list == ($ns+$nopcap) && @dfall_list == ($ns+$nopcap) && @slewf_list == ($ns+$nopcap)){
       print WRITE_GENLIB "       cell_rise @drise_list\n";
       print WRITE_GENLIB "       rise_transition @slewr_list\n";
       print WRITE_GENLIB "       cell_fall @dfall_list\n";
       print WRITE_GENLIB "       fall_transition @slewf_list\n";
       close (WRITE_GENLIB);
   #}#if all values found 
&write_lib("-genlib","$cellName.genlib","-lib","$file.lib");
}#sub read_file_for_seq
#------------------------------------------------------------------get seuential-------------------------------------------------------#
sub get_sequential{
  my $fileName = $_[0];
  if(-e $fileName){}else{print "WARN: file does not exist\n";return}
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
  open(READ,$fileName);
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
  print "This cell \"$cellName\" is Combinational Cell\n";
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
    if(exists $PORT_HASH{$gate} && ($source eq "vdd" || $drain eq "vdd")){
      if(exists $PORT_HASH{$source} && $drain eq "vdd"){
         $IN_HASH{$gate} = 1 if(!exists $IN_HASH{$gate} && !exists $OUT_HASH{$gate});
         $OUT_HASH{$source} = 1 if(!exists $OUT_HASH{$source} && !exists $IN_HASH{$source});
      }elsif(exists $PORT_HASH{$drain} && $source eq "vdd"){
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
  if($clk_enable ne "" && @in_port != 0 && @out != 0){return ($clk_enable, $out[0],$in_port[0]);}
  
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
  #print "input: @input_list | clock $clock_signal | output @output_list\n";
  return ($clock_signal,$output_list[0], $input_list[0]);
  

}#sub get_sequential
