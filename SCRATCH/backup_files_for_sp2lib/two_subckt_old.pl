#!/usr/bin/perl
my $fileName = "";
for(my $i =0; $i<=$#ARGV;$i++){
if($ARGV[$i] eq "-f"){$fileName = $ARGV[$i+1];}
}
&read_subckt($fileName);
sub read_subckt {
my $end_data_of_subckt = 0;
my $read_data_of_subckt = 0;
my $cellName = "";
my @cell_data = ();
my %PORT_DATA = ();
my %TRANS_DATA = ();
my %INST_DATA = ();
my @temp = ();
my @trans_data = ();
open(READ,"$fileName");
my $previous_line = "";
my $next_line = "";
while(<READ>){
  chomp();
  if($_ =~ /\*/){next;}
  if($_ =~ /^\+/){
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
      @trans_data = ();
      $previous_line =~ s/^\s*\.(subckt|SUBCKT)\s*//;
      @cell_data = (split(/\s+/,$previous_line));
      $cellName = shift(@cell_data);
      @{$PORT_DATA{$cellName}} = @cell_data;
    }elsif($previous_line=~ /^\s*m\s*/i || $previous_line=~ /^\s*c\s*/i){
      if(!exists $TRANS_DATA{$cellName}){ 
         @{$TRANS_DATA{$cellName}} = @temp;
      }
      push (@{$TRANS_DATA{$cellName}} ,$previous_line);
    }elsif($previous_line =~ /^\s*x\s*/i){
       if(!exists $INST_DATA{$cellName}){
          @{$INST_DATA{$cellName}} = @temp;
       }
       push (@{$INST_DATA{$cellName}},$previous_line);
    }
  }#if read_subckt
  $previous_line = $next_line;
}#while
#--------------------------------------------------------------------------#
#--------------------------------------------------------------------------#
  #while((keys %INST_DATA) > 0){
    foreach my $cell (keys %INST_DATA){
      print "cell $cell\n";
      my @instance_data = @{$INST_DATA{$cell}}; 
      foreach my $data ( @instance_data){
        print "data $data\n";
        my $type = "";
        my @data_list = split(/\s+/,$data);
        for(my $i=0; $i<@data_list; $i++){
           if($data_list[$i] =~ m/wn/){
              $type = $data_list[$i-1];
              last;
           }
        }
        &replace_data($cell, $type, $data);
      }
    }
  #}

sub replace_data {
my $cell = $_[0];
my $type = $_[1];
my $data_line = $_[2];
#print "abb $data_line\n";
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
      my @next_type_port_list = @{$PORT_DATA{$type}};
      my @xx_port_list = split(/\s+/, $data_line); 
      my $xname = shift @xx_port_list;
      for(my $i=0; $i<@next_type_port_list; $i++){
          $map_hash{$next_type_port_list[$i]} = $xx_port_list[$i];
      }
      #foreach my $k (keys %map_hash){
      #   print "$k => $map_hash{$k}\n";
      #}
      if(exists $TRANS_DATA{$type}){
         my @transdata = @{$TRANS_DATA{$type}};
         foreach my $trans_name (@transdata){
           my ($m1) = (split(/\s+/,$trans_name))[0];
           $trans_name =~ s/$m1/$m1$xname/;
           foreach my $map (keys %map_hash){
             my $val = $map_hash{$map};
             $trans_name =~ s/$map/$val/g;
           }
           push (@{$TRANS_DATA{$cell}}, $trans_name);
           my $cell_not_exist = &check_cell_not_exists($cell,$type,$data_line);
           print "cell exists $cell_not_exist\n";
           if($cell_not_exist == 1){
              delete $TRANS_DATA{$type};
              delete $PORT_DATA{$type};
              my @inst_hash_val = @{$INST_DATA{$cell}};
              print "aditya $#inst_hash_val\n";
              if(@inst_hash_val <= 0){
                 print "deleting $cell\n";
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
     #my $count = 0;
     my @new_data = ();
     foreach my $data_line(@data){
       if($cell eq $type && $data_line_arg eq $data_line){
         #delete $data[$count];  
         #@{$INST_DATA{$type}} = @data;
         next;
       }else{
         push(@new_data, @data_line);
       }
       my @data_list = split(/\s+/,$data_line);
       for(my $i=0; $i<@data_list; $i++){
           if($data_list[$i] =~ m/wn/){
              
              if($ckt_name eq $data_list[$i-1]){return 0;};
           }
        }
        #$count++;
     }
     @{$INST_DATA{$type}} = @new_data
  }
  return 1;
}#sub check_cell_not_exists

foreach my $mdata (keys %TRANS_DATA){
  my @value = @{$TRANS_DATA{$mdata}};
  foreach my  $_ (@value){
  print "NEW $mdata => $_\n";
  }
} 
#foreach my $mdata (keys %PORT_DATA){
#  my @value = @{$PORT_DATA{$mdata}};
#  foreach my  $_ (@value){
#  print "port $mdata => $_\n";
#  }
#} 
#foreach my $mdata (keys %INST_DATA){
#  my @value = @{$INST_DATA{$mdata}};
#  foreach my  $_ (@value){
#  print "ins $mdata => $_\n";
#  }
#} 
}#sub read_subckt


