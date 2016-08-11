#!/usr/bin/perl
use Benchmark;
my $t0 = new Benchmark;

my $fileName = "";
my $output_file = "";
my $over_write = 0;
my %PORT_DATA = ();
my %TRANS_DATA = ();
my %INST_DATA = ();
my $max_number_of_pattern = 1000;
for(my $i =0; $i<=$#ARGV;$i++){
  if($ARGV[$i] eq "-spice_file"){$fileName = $ARGV[$i+1];}
  elsif($ARGV[$i] eq "-output"){$output_file = $ARGV[$i+1];}
  elsif($ARGV[$i] eq "-max_number_of_pattern"){$max_number_of_pattern = $_[$i+1];}
  elsif($ARGV[$i] eq "--overwrite"){$over_write = 1;}
  elsif($ARGV[$i] eq "-help"){ print "Usage : -spice_file <spice fileName>\n";
                               print "      : -output <fileName>\n";
                               print "      : -max_number_of_pattern <digit>\n";
                               print "      : --overwrite\n";
                             }
}#for
if($max_number_of_pattern > 1000){
  $max_number_of_pattern = 1000;
}
#-----------------------------------------------------------------------------------#
%PORT_DATA = ();
%TRANS_DATA = ();
%INST_DATA = ();
my $include_flat = &include_spi_files($fileName);
my ($file_get,$curr_cell_name) = &get_flat_spi($include_flat);
&create_cmd_file($file_get,$output_file,$over_write);
#-----------------------------------------------------------------------------------#
sub create_cmd_file {
my $file = $_[0];
my $output = $_[1];
my $overwrite = $_[2];
my $cellName = "";
my @cell_data = ();
my %INPUT = ();
my %OUTPUT = ();
my @input_list = ();
my @output_list = ();
if((-e $file) && (-r $file)){
  open(READ_SP,"$file");
  my $previous_line = "";
  my $next_line = "";
  while(<READ_SP>){
    chomp();
    if($_ =~ /^\*/){next;}
    if($_ =~ /^$/){next;}
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
  $previous_line = $next_line;
  }#while
  close(READ_SP);
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
}#if
################################ creating cmd file ##########################
my $out_file = "";
if($output eq ""){
  $out_file = "$cellName.cmd";
}else {
  if($output =~ /\.cmd$/){
    $out_file = $output;
  }else {
    $out_file = "$output.cmd";
  }
}
if ( -e $out_file ) {
  if ( $overwrite == 1 ) { 
    print "WARN : 001 : $out_file exists, overwriting existing file as instructed\n";
  } else {
    print "ERROR : 002 : $out_file exists, Please change the output name or remove the existing file\n";
    return;
  }
}#if output file exists
open(WRITE_CMD,">$out_file");
print WRITE_CMD"stepsize 50\n";
foreach my $port (@cell_data){
  if(($port =~ /vdd/i) || ($port =~ /vdar_t/i) || ($port =~ /vdio_t/i)){
    print WRITE_CMD"h $port\n";
  }elsif(($port =~ /vss/i) || ($port =~ /gnd/i)){
    print WRITE_CMD"l $port\n";
  }
}#foreach
print WRITE_CMD"w @input_list @output_list\n";
$out_file =~ s/.cmd//;
print WRITE_CMD"blio open $out_file.blio.gz\n";
print WRITE_CMD"logfile $cellName.log\n";
print WRITE_CMD"vector input @input_list\n";
my $total_input = @input_list;
my $num_input = $total_input;
my $dec_num = 2**$num_input;
for(my $i=0; $i<$dec_num && $i<$max_number_of_pattern; $i++){
  my $bin_num = &dec2bin($i,$num_input);
  print WRITE_CMD"set input $bin_num\n";
  print WRITE_CMD"s\n"; 
}
print WRITE_CMD"exit\n";
close(WRITE_CMD);
}#sub create_cmd_file
#---------------------------------------------------------------------------------#
sub reduce_cap_and_reg {
  my $include_sp_file = $_[0];
  my $read_data_of_subckt = 0;
  my $end_data_of_subckt = 0;
  my $cellName_new= "";
  my %TRANS_DATA_HASH = ();
  my %CAP_DATA_HASH = ();
  my %REG_DATA_HASH = ();
  my %PORT_HASH_OF_SUBCKT = ();
  my $flat_reduce_cap_sp_file = "$include_sp_file-reduce-res.sp";
  open(READ,"$include_sp_file");
  open(WRITE,">$flat_reduce_cap_sp_file");
  while(<READ>){
    chomp();
    if($_ =~ /^\s*\*/){next;}
    if($_ =~ /^$/){next;}
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
      $cellName_new = shift(@cell_data);
      foreach my $port (@cell_data){
        $PORT_HASH_OF_SUBCKT{$port} = 1;
      }
    }elsif($previous_line=~ /^\s*m\s*/i){
      my (@tr_data) = split(/\s+/,$previous_line);
      my $trans_name = shift @tr_data;
      $TRANS_DATA_HASH{$trans_name} = [@tr_data]; 
    }elsif($previous_line =~ /^\s*c\s*/i){
      my ($cap_name, $net1, $net2, $cap_val) = (split(/\s+/,$previous_line))[0,1,2,3];
      $CAP_DATA_HASH{$cap_name} =  [$net1, $net2, $cap_val];
    }elsif($previous_line =~ /^\s*r\s*/i){
      my ($reg_name,$net_1,$net_2) = (split(/\s+/,$previous_line))[0,1,2];
      $REG_DATA_HASH{$reg_name} = [$net_1,$net_2];
    }
  }#if reading subckt   
  $previous_line = $next_line;
  }#while
  close(READ);

  foreach my $res1 (keys %REG_DATA_HASH){
    my ($net1, $net2) = @{$REG_DATA_HASH{$res1}};
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
        if($TRANS_DATA_HASH{$tr}[$i] eq $replace_net){
          $TRANS_DATA_HASH{$tr}[$i] = $replace_val;
        }
      }
    }
    foreach my $cap (keys %CAP_DATA_HASH){
      for(my $i=0; $i<2; $i++){
        if($CAP_DATA_HASH{$cap}[$i] eq $replace_net){
          $CAP_DATA_HASH{$cap}[$i] = $replace_val;
        }
      }
    }
    foreach my $res2 (keys %REG_DATA_HASH){
      for(my $i=0; $i<2; $i++){
        if($REG_DATA_HASH{$res2}[$i] eq $replace_net){
          $REG_DATA_HASH{$res2}[$i] = $replace_val;
        }
      }
      if((exists $PORT_HASH_OF_SUBCKT{$REG_DATA_HASH{$res2}[0]} && exists $PORT_HASH_OF_SUBCKT{$REG_DATA_HASH{$res2}[1]}) || ($REG_DATA_HASH{$res2}[0] eq $REG_DATA_HASH{$res2}[1])){
        delete $REG_DATA_HASH{$res2}; 
      }
    }
  }
  
  foreach my $k (keys %TRANS_DATA_HASH){
     my @val = @{$TRANS_DATA_HASH{$k}};
     print WRITE "$k @val\n";
  }
  foreach my $cap (keys %CAP_DATA_HASH){
    my @cap_data = @{$CAP_DATA_HASH{$cap}};
    print WRITE "$cap @cap_data\n";
  }
  print WRITE ".ends $cellName_new\n";
close (WRITE);
return($flat_reduce_cap_sp_file);
}#sub reduce_cap_and_reg
#---------------------------------------------------------------------------------------#
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
  my %source_port_hash = ();
  my %gate_port_hash = ();
  my %drain_port_hash = ();

  open(READ_CAP_FLAT_SP,"$flat_reduce_cap_sp_file");
  my $previous_line1 = "";
  my $next_line1 = "";
  while(<READ_CAP_FLAT_SP>){
    chomp();
    if($_ =~ /^\s*\*/){next;}
    if($_ =~ /^$/){next;}
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
        if($mdata1 !~ /$cellName1/){
          @{$TEMP_SPICE_DATA{$mdata1}} = @new_data1;
        }
      }
    }
    $previous_line1 = $next_line1;
  }#while
  close(READ_CAP_FLAT_SP);
  foreach my $tr(keys %TEMP_SPICE_DATA){
     my @tr_data = @{$TEMP_SPICE_DATA{$tr}};
     my ($temp_drain,$temp_gate,$temp_source,$temp_type) = @tr_data[0,1,2,4];
     $source_port_hash{$temp_source} = 1 if(!exists $source_port_hash{$temp_source});
     $gate_port_hash{$temp_gate} = 1 if(!exists $gate_port_hash{$temp_gate});
     $drain_port_hash{$temp_drain} = 1 if(!exists $drain_port_hash{$temp_drain});
  }
  foreach my $tr_port (@cell_data1){
    if(($tr_port =~ /vdd/i) || ($tr_port =~ /vss/i) || ($tr_port =~ /gnd/i) || ($tr_port =~ /vdar_t/i)||($tr_port =~ /vdio_t/i)){
    }else {
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
         if((!exists $gate_port_hash{$tr_port}) && (exists $drain_port_hash{$tr_port}) || (exists $source_port_hash{$tr_port})){
           #$in_port_hash{$tr_port} = 1 if(!exists $in_port_hash{$tr_port});
           $out_port_hash{$tr_port} = 1 if(!exists $out_port_hash{$tr_port});
         }else {
           #$out_port_hash{$tr_port} = 1 if(!exists $out_port_hash{$tr_port});
           $in_port_hash{$tr_port} = 1 if(!exists $in_port_hash{$tr_port});
         }
      }#if not mux
    }
  }
  return(\%in_port_hash, \%out_port_hash);
}#sub get_input_output_list
#---------------------------------------------------------------------------------------#
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
#---------------------------------------------------------------------------------------#
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
      if($dir_path ne ""){
        if($include_file !~ /^\//){
          $include_file = $dir_path."/".$include_file;
        }
      }
      if(-e $include_file){
        my $next_has_include = &write_data_in_file($write_fh, $include_file);
        if($next_has_include == 1){
           $hier = 1;
        }
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

sub write_data_in_file {
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
#---------------------------------------------------------------------------------------#
sub get_flat_spi {
my $file_name = $_[0];
my $end_data_of_subckt = 0;
my $read_data_of_subckt = 0;
my $cellName = "";
my @cell_data = ();
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
  if($_ =~ /^\s*\*/){next;}
  if($_ =~ /^$/){next;}
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

############################if file is already flat ############################
  my @cells  = keys %TOTAL_CELL_HASH;
  if(@cells ==1){
     if(-e $sp_file_name."-flat.sp"){
       return ($file_name,$cells[0]);
     }else{
       my $flat_sp_file = $sp_file_name."-flat.sp";

       #system("cp $file_name $flat_sp_file");
       open(WRITE, ">$flat_sp_file");
       open(READ, $file_name);
       while(<READ>){
         chomp();
         print WRITE "$_\n";
       }
       close READ;
       close WRITE;
       return ($flat_sp_file,$cells[0]);
     } 
  }elsif(@cells <= 0){return ($file_name,"");} 

########################## making flat data ###################################
  &get_flat_data;
  sub get_flat_data {
    foreach my $cell (keys %INST_DATA){
      my @instance_data = @{$INST_DATA{$cell}}; 
      if(@instance_data <= 0){delete $INST_DATA{$cell};}
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
    #if((keys %INST_DATA) > 0){&get_flat_data;}
  }#sub get_flat_data
  ############################# End of get_flat_data #############################
  my $curr_cell_name = "";
  my $flat_sp_file = "";
  foreach my $mdata (keys %TRANS_DATA){
    my @port_list  = @{$PORT_DATA{$mdata}};
    #$flat_sp_file = "$mdata-flat.sp"; 
    $flat_sp_file = "$sp_file_name-flat.sp"; 
    open(WRITE,">$flat_sp_file");
      $curr_cell_name = $mdata;
      print WRITE".subckt $mdata @port_list\n";
      my @value = @{$TRANS_DATA{$mdata}};
      foreach my $val (@value){
         print WRITE "$val\n";
      }
      print WRITE".ends $mdata\n";
    close WRITE;
  } 
  return ($flat_sp_file,$curr_cell_name);
}#sub get_flat_spi
my $t1 = new Benchmark;
my $td = timediff($t1,$t0);
print "script sp2cmd took:",timestr($td),"\n";
