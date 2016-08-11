#!/usr/bin/perl
my $fileName  = "";
for(my $i =0 ;$i<=$#ARGV;$i++){
  if($ARGV[$i] eq "-f"){$fileName = $ARGV[$i+1];}
}

my $st = &get_sequential($fileName);
print "$st\n";
sub get_sequential {
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
#-------------------testing -------------------#
 # foreach (keys %PTYPE_SRC_HASH){
 #   print "src $_=> $PTYPE_SRC_HASH{$_}\n";
 # }
 # foreach (keys %PTYPE_DRAIN_HASH){
 #   print "drain $_=> $PTYPE_DRAIN_HASH{$_}\n";
 # }
#------------------------------------------#
  foreach my $mdata (keys %SPICE_DATA){
    my $value = $SPICE_DATA{$mdata}; 
    my ($drain,$gate,$source,$type) = (split(/\s+/,$value));
    if($type =~ /n/i){
       if($source =~ /vss/i){
         if(exists $PTYPE_DRAIN_HASH{$drain} && $gate eq $PTYPE_DRAIN_HASH{$drain}){
           if(!exists $PORT_HASH{$drain}){
              $COMMON_DRAIN_HASH{$drain} = $gate;
              #print "aditya 1 $mdata\n";
           }else{
              $COMMON_DRAIN_HASH{$gate} = $drain;
              #print "aditya 2\n";
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
  
  
  #foreach (keys %COMMON_DRAIN_HASH){
  #  print "common $_=> $COMMON_DRAIN_HASH{$_}\n";
  #}
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
  
  #foreach my $spice (keys %SPICE_DATA){
  #  print "spice $spice => $SPICE_DATA{$spice}\n";
  #}

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
  if($clk_enable ne "" && @in_port != 0 && $out != 0){return $clk_enable;}
  
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
  print "input: @input_list | clock $clock_signal | output @output_list\n";
  return $clock_signal;
  
}#sub get_sequential
############################################################################################
