sub read_edif {
my $noOfArguments = @_; 
if($noOfArguments < 1 || $_[0] eq "-h"){
                                        }
else {
my $INPUT_EDIF_FILE = "";
%MODULE_ALREADY = ();
my $bracket_of_library = 0;
my $library_start = 0;
my $bracket_of_cell = 0;
my $cell_start = 0;
my $bracket_of_view = 0;
my $view_start = 0;
my $bracket_of_port = 0;
my $port_start = 0;
my $bracket_of_instance = 0;
my $instance_start = 0;
my $bracket_of_net = 0;
my $net_start = 0;
my $moduleName = "";
my $bracket_cnt = 0;

for (my $i=0;$i<$noOfArguments; $i++){
  if($_[$i] eq "-edif"){ $INPUT_EDIF_FILE = $_[$i+1];}
}#for
if(( -e $INPUT_EDIF_FILE) && (-r $INPUT_EDIF_FILE)){
open (READ_INPUT_EDIF,"$INPUT_EDIF_FILE");
while (<READ_INPUT_EDIF>){
chomp ();
$_ =~ s/\s+//;
$_=~ s/\s+$//;
#my %TEMP_HASH = ();
#my %INST_DATA = ();
#----------------------------------------------------------------------------------------------------------#
#if($_ =~ /\(/){
#  $bracket_cnt++;
#  if($_ =~ /library/){
#    $bracket_of_library++;
#  }
#  #$bracket_of_cell++;
#  print "$_ $bracket_cnt $bracket_of_library $bracket_of_cell\n";
#}
#if($_ =~ /\)/){
#  $bracket_cnt--;
#  $bracket_of_library--;
#  $bracket_of_cell--;
#  print "$_ $bracket_cnt $bracket_of_library $bracket_of_cell\n";
#}

#----------------------------------------------------------------------------------------------------------#
if($_ =~ /^\(\blibrary\b/){
  $bracket_of_library++;
  $library_start = 1;
  my $cell = "";
}
#if($_ =~ /^\(\bcell\b/){
#  $moduleName = (split(/\s+/,$_))[1];
#  $bracket_of_cell++;
#  $cell_start = 1;
#}if($_ =~ /^\(\bview\b/){
#  $bracket_of_view++;
#  $view_start = 1;
#}if($_ =~ /^\(\bport\b/){
#  $bracket_of_port++;
#  $bracket_of_view++;
#  $port_start = 1;
#}if($_ =~ /^\(\binstance\b/){
#  $bracket_of_instance++;
#  $bracket_of_view++;
#  $instance_start = 1;
#  $net_start = 0;
#}if($_ =~ /^\(\bnet\b/){
#  $bracket_of_net++;
#  $bracket_of_view++;
#  $net_start = 1;
#}
if($library_start == 1){
  if($_ =~ /\(\bcell\b/){
    $cell = (split(/\s+/,$_))[1]; 
    $bracket_of_cell++;
    #  print "$_ $bracket_of_cell $bracket_of_view $bracket_of_port\n";
    $TEMP_DATA_OF_MODULE{$cell} = $cell;
  }if($_ =~ /\(\bview\b/){
    my $view = (split(/\s+/,$_))[1];
    $bracket_of_view++;
    # print "$_ $bracket_of_cell $bracket_of_view $bracket_of_port\n";
    $TEMP_VIEW_OF_MODULE{$cell} = $view;
  }
  if($_ =~ /\(\bport\b/){
    my $portName = (split(/\s+/,$_))[1];
    $bracket_of_port++;
    $bracket_of_view++;
    #print "$_ $bracket_of_cell $bracket_of_view $bracket_of_port port\n";
    push (@{$TEMP_PORT_OF_MODULE{$cell}},$portName);
  }if($_ =~ /\(\bdirection\b/){
     my $direction = (split(/\s+/,$_))[1];$direction =~ s/\)//;
     push (@{$TEMP_PORT_OF_MODULE{$cell}},$direction);
  }if($_ =~ /\(\binstance\b/){
    my $inst = (split(/\s+/,$_))[1];
    #print "$inst\n";
    push(@{$TEMP_INST_OF_MODULE{$cell}},$inst);
  }if($_ =~ /\(\bcellRef\b/){
    my $cellref = (split(/\s+/,$_))[1];$cellref =~ s/\)//;
    push(@{$TEMP_INST_OF_MODULE{$cell}},$cellref);
  }if($_ =~ /\(\bnet\b/){
    my $net = (split(/\s+/,$_))[1];
#    print "$net\n";
    push(@{$TEMP_NET_OF_MODULE{$cell}},"net"." ".$net);
  }if($_ =~ /\(\bportRef\b/){
    my $portref = (split(/\s+/,$_))[1];
#    print "$portref\n";
    push(@{$TEMP_NET_OF_MODULE{$cell}},"pin"." ".$portref);
  }if($_ =~ /\(\binstanceRef\b/){
    my $instref = (split(/\s+/,$_))[1];$instref =~ s/\)//;
#    print "$instref\n";
    push(@{$TEMP_NET_OF_MODULE{$cell}},"inst"." ".$instref);
  }
}
}#while
#--------------------------------------------------------------------------------------------------------#
foreach my $module (keys %TEMP_DATA_OF_MODULE){
  my @port = @{$TEMP_PORT_OF_MODULE{$module}};
  $MODULE_ALREADY{$module} = VNOM::new();
  for (my $i =0; $i<=$#port;$i=$i+2){
    my $port_Name = $port[$i];
    my $port_dir = $port[$i+1];
    if($port_dir eq "INPUT"){
      $MODULE_ALREADY{$module}->dbVNOMAddInput($port_Name);
      $MODULE_ALREADY{$module}->dbVNOMSetInputType($port_Name,0);
    }elsif($port_dir eq "OUTPUT"){
      $MODULE_ALREADY{$module}->dbVNOMAddOutput($port_Name);
      $MODULE_ALREADY{$module}->dbVNOMSetOutputType($port_Name,0);
    }elsif($port_dir eq "INOUT"){
      $MODULE_ALREADY{$module}->dbVNOMAddBidi($port_Name);
      $MODULE_ALREADY{$module}->dbVNOMSetBidiType($port_Name,0);
    }
  }#for
  my %INST_CELL_HASH = ();
  my @inst_cell_data = @{$TEMP_INST_OF_MODULE{$cell}};
#print "@inst_cell_data\n";
  for(my $i=0;$i<$#inst_cell_data;$i=$i+2){
    my $instName = $inst_cell_data[$i];
    my $cellName = $inst_cell_data[$i+1];
   # print "$instName  => $cellName\n";
    $MODULE_ALREADY{$module}->dbVNOMAddLeafInst($instName);
    $INST_CELL_HASH{$instName} = $cellName;
  }#for
  my @net_data = @{$TEMP_NET_OF_MODULE{$module}};
  my %NET_DATA = ();
  my $netName = "";
  foreach my $data (@net_data){
    if($data =~ /\bnet\b/){
      $netName = (split(/\s+/,$data))[1];
    }elsif($data =~ /\bpin\b/){
      my $pinName = (split(/\s+/,$data))[1];
      push(@{$NET_DATA{$netName}},$pinName);
    }elsif($data =~ /\binst\b/){
      my $instName = (split(/\s+/,$data))[1];
      push(@{$NET_DATA{$netName}},$instName);
    }
  }
  foreach my $net (keys %NET_DATA){
    my @netdata_list =  @{$NET_DATA{$net}};
#    print "$net\n";
    for(my $i=0;$i<$#netdata_list;$i=$i+2){
      my $portName = $netdata_list[$i];
      my $instName = $netdata_list[$i+1];
#      print "$portName $instName\n";
      my $inst_data_new = ".".$portName."(".$net.")"; 
  #    print "$instName => $inst_data_new\n";
      push(@{$INST_CONN{$instName}},$inst_data_new);
    }#for
  }
  foreach my $inst (keys %INST_CONN){
#    print "$inst => @{$INST_CONN{$inst}}\n";
     my @conn = @{$INST_CONN{$inst}};
     my $temp_conn= join " ",@conn;
    if(exists $INST_CELL_HASH{$inst}){
      my $cell_Name = $INST_CELL_HASH{$inst};
#      print "$INST_CELL_HASH{$inst} => $inst => @{$INST_CONN{$inst}}\n";
      my $connLine = $cell_Name." ".$inst." (".$temp_conn.");"; 
      #my $connLine = "IsoDrv6 IsoDrv6_1 (.OutB(N_9), .In(N_7), .EnblDrv(Vdd), .OutA(N_8), .Clk(N_11));"; 
      print "$connLine\n";
      $MODULE_ALREADY{$module}->dbVNOMAddConn($connLine);
    }
  }
}#foreach
#------------------------------------------------------------------------------------------------------#
#$MODULE_ALREADY{$moduleName_with_view} = VNOM::new();
#if($_ =~ /^\(\bview\b/){$viewName = (split(/\s+/,$_))[1];
#$moduleName_with_view = $moduleName."_".$viewName;
##print "$moduleName_with_view\n";
#$MODULE_ALREADY{$moduleName_with_view} = VNOM::new();
#}
#  if($_ =~ /^\(\bport\b/){
#    $portName = (split(/\s+/,$_))[1];
#  }if($_ =~ /^\(\bdirection\b/){
#    $direction = (split(/\s+/,$_))[1];$direction =~ s/\)//;
#    if($direction eq "INPUT"){
#      $MODULE_ALREADY{$moduleName_with_view}->dbVNOMAddInput($portName); 
#      $MODULE_ALREADY{$moduleName_with_view}->dbVNOMSetInputType($portName,0);
#    }elsif($direction eq "OUTPUT"){                                  
#      $MODULE_ALREADY{$moduleName_with_view}->dbVNOMAddOutput($portName); 
#      $MODULE_ALREADY{$moduleName_with_view}->dbVNOMSetOutputType($portName,0);
#    }elsif($direction eq "INOUT"){                                   
#      $MODULE_ALREADY{$moduleName_with_view}->dbVNOMAddBidi($portName);
#      $MODULE_ALREADY{$moduleName_with_view}->dbVNOMSetBidiType($portName,0);
#    }
#  }if($_ =~ /^\(\binstance\b/){
#     $instName = (split(/\s+/,$_))[1];
#     #print "$instName\n";
#  }if($_ =~ /^\(\bcellRef\b/){
#     $cellref = (split(/\s+/,$_))[1];
#     $cellref =~ s/\)//;
#     #print "$cellref\n";
#     $TEMP_HASH{$instName} = $cellref;
#  }if($_ =~ /^\(\bnet\b/){
#     $netName = (split(/\s+/,$_))[1];
#     #print "Net $netName\n";
#  }if($_ =~ /^\(\bportRef\b/){
#     $portref = (split(/\s+/,$_))[1];
#     $portref =~ s/\)//;
#     #print "Port $portref\n";
#  }if($_ =~ /^\(\binstanceRef\b/){
#     $instanceRef = (split(/\s+/,$_))[1];
#     $instanceRef =~ s/\)//;
#     #print "InstRef $instanceRef\n";
#     my $inst_data = ".".$portref."(".$netName.")".",";
#     my $cell = $TEMP_HASH{$instanceRef};
#     print "Mansi $cell\n";
#     $INST_DATA{$instanceRef} = $inst_data; 
#  }
#  foreach my $inst (keys %INST_DATA){
#    my $value = $INST_DATA{$inst};
#    #push (@{$NEW_TEMP{$inst}},$value); 
#    push (@{$NEW_TEMP{$inst}},$value); 
#  }
#  foreach my $inst (keys %NEW_TEMP){
#    my @net_data = @{$NEW_TEMP{$inst}};
#    if(exists $TEMP_HASH{$inst}){
#      my $cell = $TEMP_HASH{$inst};
#    }
#    #print "Mansi data $inst => @net_data\n"; 
#    $str = join" ",@net_data;
#    #print "$str\n";
#    $MODULE_ALREADY{$moduleName_with_view}->dbVNOMAddConn($str);
#  }
#-----------------------------------------------------------------------------------------------------------#
}else{
  print "WARN : $INPUT_EDIF_FILE FILE DOES NOT EXISTS OR IS NOT READABLE.\n"; 
}

}#else
close(READ_INPUT_EDIF);
my @TOP = ();
foreach my $mod (keys %MODULE_ALREADY) { 
       my @parents =  $MODULE_ALREADY{$mod}->dbVNOMGetParent;
       my $np = @parents;
#       print "number of parents of $mod are $np\n";
       if ( $np == 0 ) { push(@TOP,$mod); }
       elsif ( $np > 1 ) { print "INFO-PAR-VERI : 014 : $mod has $np parents \n"; }
                              }
my $nT = @TOP;
if ( $nT == 1 ) { print "INFO-PAR-VERI : 015 : Setting top module as $TOP[0]\n"; 
                  $CURRENT_MODULE = $TOP[0];
                  $TOP_MODULE = $TOP[0];
		  $GLOBAL->dbfGlobalSetTOP($TOP_MODULE);
                }
elsif ( $nT > 1 ) { print "WARN-PAR-VERI : 016 : there are more than 1 possible top modules, please pick the correct one from the list below\n";
                    #print join ",", @TOP; #print "\n";
                     $TOP_MODULE = "ChTop_Sim_ChTop";
                  }
else { print "ERROR-PAR-VERI : 017 : something is wrong with the verilog file\n"; }
&write_edif;
}#sub read_edif
#-------------------------------------------------------------------------------------------------------------------------------------------------#
sub write_edif {
foreach my $moduleName (keys %MODULE_ALREADY){
  #print "$moduleName\n";
}
}#sub write_edif 
1;
