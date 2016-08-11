#!/usr/bin/perl
my $fileName  = "";
for(my $i =0 ;$i<=$#ARGV;$i++){
  if($ARGV[$i] eq "-f"){$fileName = $ARGV[$i+1];}
}
#--------------------------------------------------------------------variable initilaized-----------------------------------------#
my $cellName = "";
my @cell_data = ();
my $read_data_of_subckt = 0;
my $end_data_of_subckt = 0;
my $data = "";
my @new_data = ();
my $mdata = "";
my $portName = "";
my $data_start = 0;
my $data_end = 0;
#my @internal_wire_list = ();
#my @temp_internal_wire_list = ();
my %TEMP_IN_WIRE = ();
my %SPICE_DATA = ();
my %PORT_HASH = ();
my %GATE_HASH = ();
my %DRAIN_HASH = ();
my %SOURCE_HASH = ();
my %PTYPE_DRAIN_HASH = ();
my %COMMON_DRAIN_HASH = ();
#-----------------------------------------------------------------read .spi file--------------------------------------------------#
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
        #if(!exists $PORT_HASH{$drain}){
        #  if(!exists $TEMP_IN_WIRE{$drain}){
        #     $TEMP_IN_WIRE{$drain} = 1;
        #  } 
        #  #push (@temp_internal_wire_list,$drain);
        #  #foreach my $in_wire (@temp_internal_wire_list){
        #  #  $TEMP_IN_WIRE{$in_wire} = 1;
        #  #}
        #}
        #if(!exists $PORT_HASH{$gate}){
        #  if(!exists $TEMP_IN_WIRE{$gate}){
        #     $TEMP_IN_WIRE{$gate} = 1;
        #  } 
        #  #push (@temp_internal_wire_list,$gate);
        #  #foreach my $in_wire (@temp_internal_wire_list){
        #  #  $TEMP_IN_WIRE{$in_wire} = 1;
        #  #}
        #}
        #if(!exists $PORT_HASH{$source}){
        #  if(!exists $TEMP_IN_WIRE{$source}){
        #     $TEMP_IN_WIRE{$source} = 1;
        #  } 
        #  #push (@temp_internal_wire_list,$source);
        #  #foreach my $in_wire (@temp_internal_wire_list){
        #  #  $TEMP_IN_WIRE{$in_wire} = 1;
        #  #}
        #}
    }# data start
  }#read data of subckt
}#while
#---------------------------------------------------------get list of internal wire-----------------------------------------------------------------------#
#foreach my $in_wire (keys %TEMP_IN_WIRE){
#  push (@internal_wire_list,$in_wire);
#}
#---------------------------------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------populate gate,drain and source hash from port---------------------------------------------------#
#foreach my $port (@cell_data){
#  foreach my $mdata (keys %SPICE_DATA){
#    my $value = $SPICE_DATA{$mdata}; 
#    my ($drain,$gate,$source,$type) = (split(/\s+/,$value));
#    if($port eq $gate){
#      my @trans_name = ();
#      if(exists $GATE_HASH{$port}){
#        @trans_name = @{$GATE_HASH{$port}};
#        push (@trans_name,$mdata);
#      }else{
#        push(@trans_name,$mdata);
#      }
#        @{$GATE_HASH{$port}} = @trans_name;
#    }elsif($port eq $drain){
#      my @trans_name = ();
#      if(exists $DRAIN_HASH{$port}){
#        @trans_name = @{$DRAIN_HASH{$port}};
#        push (@trans_name,$mdata);
#      }else{
#        push(@trans_name,$mdata);
#      }
#        @{$DRAIN_HASH{$port}} = @trans_name;
#    }elsif($port eq $source){
#      my @trans_name = ();
#      if(exists $SOURCE_HASH{$port}){
#        @trans_name = @{$SOURCE_HASH{$port}};
#        push (@trans_name,$mdata);
#      }else{
#        push(@trans_name,$mdata);
#      }
#        @{$SOURCE_HASH{$port}} = @trans_name;
#    }
#  }
#}
##----------------------------------------------------------------------------------------------------------------------------------------------------#
##-------------------------------------------------------populate gare,drain and source hash from internal wire---------------------------------------#
##foreach my $in_wire (@internal_wire_list){
#foreach my $in_wire (keys %TEMP_IN_WIRE){
#  foreach my $mdata (keys %SPICE_DATA){
#    my $value = $SPICE_DATA{$mdata}; 
#    my ($drain,$gate,$source,$type) = (split(/\s+/,$value));
#    if($in_wire eq $gate){
#      my @trans_name = ();
#      if(exists $GATE_HASH{$in_wire}){
#        @trans_name = @{$GATE_HASH{$in_wire}};
#        push (@trans_name,$mdata);
#      }else{
#        push(@trans_name,$mdata);
#      }
#        @{$GATE_HASH{$in_wire}} = @trans_name;
#    }elsif($in_wire eq $drain){
#      my @trans_name = ();
#      if(exists $DRAIN_HASH{$in_wire}){
#        @trans_name = @{$DRAIN_HASH{$in_wire}};
#        push (@trans_name,$mdata);
#      }else{
#        push(@trans_name,$mdata);
#      }
#        @{$DRAIN_HASH{$in_wire}} = @trans_name;
#    }elsif($in_wire eq $source){
#      my @trans_name = ();
#      if(exists $SOURCE_HASH{$in_wire}){
#        @trans_name = @{$SOURCE_HASH{$in_wire}};
#        push (@trans_name,$mdata);
#      }else{
#        push(@trans_name,$mdata);
#      }
#        @{$SOURCE_HASH{$in_wire}} = @trans_name;
#    }
#  }
#}
#--------------------------------------------------------------------------------------------------------------------------------------------------------#
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
#--------------------------------------------------------------------------check seq---------------------------------------------------------------------#
foreach my $port (keys %PORT_HASH){
  if(($port =~ /vdd/) || ($port =~ /vss/)){}
  else{
     if((exists $GATE_HASH{$port}) && ((exists $DRAIN_HASH{$port}) || (exists $SOURCE_HASH{$port}))){
      $portName = $port;
    }
  }
}
if($portName eq ""){
print "This cell \"$cellName\" is Combinational Cell\n";
}else {
print "This cell \"$cellName\" is Sequential Cell\n";
}
#----------------------------------------------------------------populate common drain hash---------------------------------------------------------------#
foreach my $mdata (keys %SPICE_DATA){
  my $value = $SPICE_DATA{$mdata}; 
  my ($drain,$gate,$source,$type) = (split(/\s+/,$value));
  if($type =~ /p/i){
     if($source  =~ /vdd/i){
       $PTYPE_DRAIN_HASH{$drain} =1;
     }
  }
}
foreach my $mdata (keys %SPICE_DATA){
  my $value = $SPICE_DATA{$mdata}; 
  my ($drain,$gate,$source,$type) = (split(/\s+/,$value));
  if($type =~ /n/i){
     if($source =~ /vss/i){
       if(exists $PTYPE_DRAIN_HASH{$drain}){
         $COMMON_DRAIN_HASH{$drain} = $gate;
       }
     }
  }
}
#---------------------------------------------------------------delete n/p trans-------------------------------------------------------------------------#
foreach my $mdata (keys %SPICE_DATA){
  my $value = $SPICE_DATA{$mdata}; 
  my ($drain,$gate,$source,$type) = (split(/\s+/,$value));
  if(exists $COMMON_DRAIN_HASH{$drain}){
    delete $SPICE_DATA{$mdata};
  }
}
#--------------------------------------------------------------------------------------------------------------------------------------------------------#
#foreach my $drain (keys %COMMON_DRAIN_HASH){
##-----------------------------------if drain exists in drain hash--------------------------------------------#
#  if((exists $DRAIN_HASH{$drain}) && (!exists $PORT_HASH{$drain})){
#    my $gate_value = $COMMON_DRAIN_HASH{$drain};
#    if(exists $DRAIN_HASH{$gate_value}){
#      my @drain_value_1 = @{$DRAIN_HASH{$gate_value}};
#      my @drain_value_2 = @{$DRAIN_HASH{$drain}};
#      my @get_new_value = ();
#      foreach my $trans_name (@drain_value_2){
#        if(!exists $SPICE_DATA{$trans_name}){
#          push(@get_new_value,$trans_name);
#        }
#      }
#      my @new_value = (@drain_value_1,@get_new_value);
#      delete $DRAIN_HASH{$drain};
#      @{$DRAIN_HASH{$gate_value}} = @new_value;
#    }else{
#      my @drain_value = @{$DRAIN_HASH{$drain}};
#      my @get_new_value = ();
#      foreach my $trans_name (@drain_value){
#        if(!exists $SPICE_DATA{$trans_name}){
#          push(@get_new_value,$trans_name);
#        }
#      }
#      my $no_of_value = @get_new_value;
#      delete $DRAIN_HASH{$drain};
#      if($no_of_value != 0){
#        @{$DRAIN_HASH{$gate_value}} = @get_new_value;
#      }
#    }
#  }
##-----------------------------------if drain exists in gate hash-------------------------------------------------#
#  if((exists $GATE_HASH{$drain}) && (!exists $PORT_HASH{$drain})){
#     my $gate_value = $COMMON_DRAIN_HASH{$drain};
#     if(exists $GATE_HASH{$gate_value}){
#       my @gate_value_1 = @{$GATE_HASH{$gate_value}};
#       my @gate_value_2 = @{$GATE_HASH{$drain}};
#       my @get_new_value = ();
#       foreach my $trans_name(@gate_value_2){
#         if(!exists $SPICE_DATA{$trans_name}){
#           push(@get_new_value,$trans_name);
#         }
#       }
#       my @new_value = (@gate_value_1,@get_new_value);
#       delete $GATE_HASH{$drain};
#       @{$GATE_HASH{$gate_value}} = @new_value;
#     }else {
#       my @gatevalue = @{$GATE_HASH{$drain}};
#       my @get_new_value = ();
#       foreach my $trans_name(@gatevalue){
#         if(!exists $SPICE_DATA{$trans_name}){
#           push(@get_new_value,$trans_name);
#         }
#       }
#       my $no_of_value = @get_new_value;
#       delete $GATE_HASH{$drain};
#       if($no_of_value != 0){
#         @{$GATE_HASH{$gate_value}} = @get_new_value;
#       }
#     }
#  }
##----------------------------------------------if drian exists in source hash-----------------------------------#
#  if((exists $SOURCE_HASH{$drain}) && (!exists $PORT_HASH{$drain})){
#     my $gate_value = $COMMON_DRAIN_HASH{$drain};
#     if(exists $SOURCE_HASH{$gate_value}){
#       my @source_value_1 = @{$SOURCE_HASH{$gate_value}};
#       my @source_value_2 = @{$SOURCE_HASH{$drain}}; 
#       my @get_new_value = ();
#       foreach my $trans_name(@source_value_2){
#         if(!exists $SPICE_DATA{$trans_name}){
#           push (@get_new_value,$trans_name);
#         }
#       }
#       my @new_value = (@source_value_1,@get_new_value);
#       delete $SOURCE_HASH{$drain};
#       @{$SOURCE_HASH{$gate_value}} = @new_value;
#     }else {
#       my @source_value = @{$SOURCE_HASH{$drain}};
#       my @get_new_value = ();
#       foreach my $trans_name(@source_value){
#         if(!exists $SPICE_DATA{$trans_name}){
#           push (@get_new_value,$trans_name);
#         }
#       }
#       my $no_of_value = @get_new_value;
#       delete $SOURCE_HASH{$drain};
#       if($no_of_value != 0){
#         @{$SOURCE_HASH{$gate_value}} = @get_new_value; 
#       }
#     }
#  }
##-------------------------------------------if drain is port and  exists in gate hash-----------------------------------------#
#  if(exists $PORT_HASH{$drain}){
#     my $gate_value = $COMMON_DRAIN_HASH{$drain};
#     if(exists $GATE_HASH{$gate_value}){
#       my @gate_value_1 = @{$GATE_HASH{$gate_value}};
#       my @gate_value_2 = @{$GATE_HASH{$drain}};
#       my @get_new_value = ();
#       foreach my $trans_name (@gate_value_1){
#         if(!exists $SPICE_DATA{$trans_name}){
#           push(@get_new_value,$trans_name);
#         }
#       }
#       my @new_value = (@gate_value_2,@get_new_value);
#       delete $GATE_HASH{$gate_value};
#       @{$GATE_HASH{$drain}} = @new_value;
#     }else{
#       my @gate_value = @{$GATE_HASH{$drain}};
#       my @get_new_value =();
#       foreach my $trans_name (@gate_value){
#         if(!exists $SPICE_DATA{$trans_name}){
#           push(@get_new_value,$trans_name);
#         }
#       } 
#       my $no_of_value = @get_new_value;
#       delete $GATE_HASH{$gate_value};
#       if($no_of_value != 0){
#         @{$GATE_HASH{$drain}} = @get_new_value;
#       }
#     }
#  }
##--------------------------------------if drain is port and exists in drain hash-------------#
#  if(exists $PORT_HASH{$drain}){
#    my $gate_value = $COMMON_DRAIN_HASH{$drain};
#    if(exists $DRAIN_HASH{$gate_value}){
#       my @gate_value_1 = @{$DRAIN_HASH{$gate_value}};
#       my @gate_value_2 = @{$DRAIN_HASH{$drain}};
#       my @get_new_value = ();
#       foreach my $trans_name (@gate_value_1){
#         if(!exists $SPICE_DATA{$trans_name}){
#           push(@get_new_value,$trans_name);
#         }
#       }
#       my @new_value = (@gate_value_2,@get_new_value);
#       delete $DRAIN_HASH{$gate_value};
#       @{$DRAIN_HASH{$drain}} = @new_value;
#     }else{
#       my @gate_value = @{$DRAIN_HASH{$drain}};
#       my @get_new_value =();
#       foreach my $trans_name (@gate_value){
#         if(!exists $SPICE_DATA{$trans_name}){
#           push(@get_new_value,$trans_name);
#         }
#       } 
#       my $no_of_value = @get_new_value;
#       delete $DRAIN_HASH{$gate_value};
#       if($no_of_value != 0){
#         @{$DRAIN_HASH{$drain}} = @get_new_value;
#       }
#     }
#   }
##-------------------------------------------if drain is port and exists in source hash---------------------------#
#   if(exists $PORT_HASH{$drain}){
#     my $gate_value = $COMMON_DRAIN_HASH{$drain};
#     if(exists $SOURCE_HASH{$gate_value}){
#       my @gate_value_1 = @{$SOURCE_HASH{$gate_value}};
#       my @gate_value_2 = @{$SOURCE_HASH{$drain}};
#       my @get_new_value = ();
#       foreach my $trans_name(@gate_value_1){
#         if(!exists $SPICE_DATA{$trans_name}){
#           push(@get_new_value,$trans_name);
#         }
#       }
#       my @new_value = (@gate_value_2,@get_new_value);
#       delete $SOURCE_HASH{$gate_value};
#       @{$SOURCE_HASH{$drain}} = @new_value;
#     }else{
#       my @gate_value = @{$SOURCE_HASH{$drain}};
#       my @get_new_value = ();
#       foreach my $trans_name(@gate_value){
#         if(!exists $SPICE_DATA{$trans_name}){
#           push(@get_new_value,$trans_name);
#         }
#       }
#       my $no_of_value = @get_new_value;
#       delete $SOURCE_HASH{$gate_value};
#       if($no_of_value != 0){
#         @{$SOURCE_HASH{$drain}} = @get_new_value;
#       }
#     }
#   }
#}#foreach common drain hash
##------------------------------------------------------------------------------------------------------------------------------#
#foreach my $port (keys %GATE_HASH){
#my @value = @{$GATE_HASH{$port}};
#print "NEW GATE $port => @value\n";
#}
#foreach my $port (keys %DRAIN_HASH){
#my @value = @{$DRAIN_HASH{$port}}; 
#print "NEW DRAIN $port => @value\n";
#}
#foreach my $port (keys %SOURCE_HASH){
#my @value = @{$SOURCE_HASH{$port}};
#print "NEW SOURCE $port => @value\n";
#}
#foreach my $data (keys %SPICE_DATA){
#print "NEW $data => $SPICE_DATA{$data}\n";
#}
