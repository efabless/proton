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
    }# data start
  }#read data of subckt
}#while

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
#---------------------------------------------------------------delete n/p trans-------------------------------------------------------------------------#
foreach my $mdata (keys %SPICE_DATA){
  my $value = $SPICE_DATA{$mdata}; 
  my ($drain,$gate,$source,$type) = (split(/\s+/,$value));
  if((exists $COMMON_DRAIN_HASH{$drain} && $gate eq $COMMON_DRAIN_HASH{$drain} && ($source eq "vss" || $source eq "vdd"))){
    delete $SPICE_DATA{$mdata};
  }elsif(exists $COMMON_DRAIN_HASH{$source} && $gate eq $COMMON_DRAIN_HASH{$source} && ($drain eq "vss" || $drain eq "vdd")){
    delete $SPICE_DATA{$mdata};
  }elsif((exists $COMMON_DRAIN_HASH{$gate} && $drain eq $COMMON_DRAIN_HASH{$gate} && ($source eq "vss" || $source eq "vdd"))){
    delete $SPICE_DATA{$mdata};
  }elsif(exists $COMMON_DRAIN_HASH{$gate} && $source eq $COMMON_DRAIN_HASH{$gate} && ($drain eq "vss" || $drain eq "vdd")){
    delete $SPICE_DATA{$mdata};
  }
}

#foreach my $port (keys %GATE_HASH){
#my @value = @{$GATE_HASH{$port}};
#print "GATE $port => @value\n";
#}
#foreach my $port (keys %DRAIN_HASH){
#my @value = @{$DRAIN_HASH{$port}}; 
#print "DRAIN $port => @value\n";
#}
#foreach my $port (keys %SOURCE_HASH){
#my @value = @{$SOURCE_HASH{$port}};
#print "SOURCE $port => @value\n";
#}
#--------------------------------------------------------------------------------------------------------------------------------------------------------#
foreach my $drain (keys %COMMON_DRAIN_HASH){
#------------------------------if drain exists in drain hash------------------------------------#
  if(exists $DRAIN_HASH{$drain}){
    my $gate_value = $COMMON_DRAIN_HASH{$drain};
    print "drain $drain\n";
    if(exists $DRAIN_HASH{$gate_value}){
      my @drain_value_1 = @{$DRAIN_HASH{$gate_value}};
      my @drain_value_2 = @{$DRAIN_HASH{$drain}};
      print "$drain  @drain_value_2\n";
      print "$gate_value  @drain_value_1\n";

      my @new_value = ();
      foreach my $trans_name (@drain_value_1){
        if(exists $SPICE_DATA{$trans_name}){
          push(@new_value,$trans_name);
        }
      }
      foreach my $trans_name (@drain_value_2){
        my $found = 0;
        foreach my $stored_val (@drain_value_1){
          if($trans_name eq $stored_val){$found = 1;last;}
        }
        if(exists $SPICE_DATA{$trans_name} && $found == 0){
           push(@new_value,$trans_name);
        }
      }
      delete $DRAIN_HASH{$drain};
      @{$DRAIN_HASH{$gate_value}} = @new_value;
    }else{
      my @drain_value = @{$DRAIN_HASH{$drain}};
      my @get_new_value = ();
      foreach my $trans_name (@drain_value){
        if(exists $SPICE_DATA{$trans_name}){
           push(@get_new_value,$trans_name);
        }
      }
      delete $DRAIN_HASH{$drain};
      if($#get_new_value >= 0){
        @{$DRAIN_HASH{$gate_value}} = @get_new_value;
      }
    }
  }
#-----------------------------------if drain exists in gate hash-------------------------------------------------#
  if(exists $GATE_HASH{$drain}){
     my $gate_value = $COMMON_DRAIN_HASH{$drain};
     if(exists $GATE_HASH{$gate_value}){
       my @gate_value_1 = @{$GATE_HASH{$gate_value}};
       my @gate_value_2 = @{$GATE_HASH{$drain}};

       my @new_value = ();
       foreach my $trans_name (@gate_value_1){
         if(exists $SPICE_DATA{$trans_name}){
           push(@new_value,$trans_name);
         }
       }
       foreach my $trans_name(@gate_value_2){
         my $found = 0;
         foreach my $stored_val (@gate_value_1){
           if($trans_name eq $stored_val){$found =1;last;}
         }
         if(exists $SPICE_DATA{$trans_name} && $found == 0){
           push(@new_value,$trans_name);
         }
       }
       delete $GATE_HASH{$drain};
       @{$GATE_HASH{$gate_value}} = @new_value;
     }else {
       my @gatevalue = @{$GATE_HASH{$drain}};
       my @get_new_value = ();
       foreach my $trans_name(@gatevalue){
         if(exists $SPICE_DATA{$trans_name}){
           push(@get_new_value,$trans_name);
         }
       }
       delete $GATE_HASH{$drain};
       if($#get_new_value >= 0){
         @{$GATE_HASH{$gate_value}} = @get_new_value;
       }
     }
  }
#----------------------------------------------if drian exists in source hash-----------------------------------#
  if(exists $SOURCE_HASH{$drain}){
     my $gate_value = $COMMON_DRAIN_HASH{$drain};
     if(exists $SOURCE_HASH{$gate_value}){
       my @source_value_1 = @{$SOURCE_HASH{$gate_value}};
       my @source_value_2 = @{$SOURCE_HASH{$drain}}; 

       my @new_value = ();
       foreach my $trans_name (@source_value_1){
         if(exists $SPICE_DATA{$trans_name}){
           push(@new_value,$trans_name);
         }
       }
       foreach my $trans_name(@source_value_2){
         my $found = 0;
         foreach my $stored_val (@source_value_1){
           if($trans_name eq $stored_val){$found = 1;last;}
         }
         if(exists $SPICE_DATA{$trans_name} && $found == 0){
           push (@new_value,$trans_name);
         }
       }
       delete $SOURCE_HASH{$drain};
       @{$SOURCE_HASH{$gate_value}} = @new_value;
     }else {
       my @source_value = @{$SOURCE_HASH{$drain}};
       my @get_new_value = ();
       foreach my $trans_name(@source_value){
         if(exists $SPICE_DATA{$trans_name}){
           push (@get_new_value,$trans_name);
         }
       }
       delete $SOURCE_HASH{$drain};
       if($#get_new_value >= 0){
         @{$SOURCE_HASH{$gate_value}} = @get_new_value; 
       }
     }
  }
}#foreach common drain hash
##------------------------------------------------------------------------------------------------------------------------------#
foreach my $port (keys %GATE_HASH){
my @value = @{$GATE_HASH{$port}};
print "NEW GATE $port => @value\n";
}
foreach my $port (keys %DRAIN_HASH){
my @value = @{$DRAIN_HASH{$port}}; 
print "NEW DRAIN $port => @value\n";
}
foreach my $port (keys %SOURCE_HASH){
my @value = @{$SOURCE_HASH{$port}};
print "NEW SOURCE $port => @value\n";
}
foreach my $data (keys %SPICE_DATA){
#print "NEW $data => $SPICE_DATA{$data}\n";
}
