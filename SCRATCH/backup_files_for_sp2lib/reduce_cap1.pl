#!/usr/bin/perl

my $file = $ARGV[0];
&reduce_cap_and_reg($file);

sub reduce_cap_and_reg {
  my $include_sp_file = $_[0];
  my $read_data_of_subckt = 0;
  my $end_data_of_subckt = 0;
  my %TRANS_DATA_HASH = ();
  my %CAP_DATA_HASH = ();
  my %REG_DATA_HASH = ();
  my %PORT_HASH_OF_SUBCKT = ();
  open(READ,"$include_sp_file");
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
      my @cell_data = (split(/\s+/,$previous_line));
      my $cellName = shift(@cell_data);
      foreach my $port (@cell_data){
        $PORT_HASH_OF_SUBCKT{$port} = 1;
      }
    }elsif($previous_line=~ /^\s*m\s*/i){
      my ($trans_name,$drain,$gate,$source) = (split(/\s+/,$previous_line))[0,1,2,3];
      push(@{$TRANS_DATA_HASH{$trans_name}},$drain,$gate,$source); 
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
  foreach my $cap (keys %CAP_DATA_HASH){
    my @port_list_cap = ();
    @port_list_cap = @{$CAP_DATA_HASH{$cap}};
    my $net_1_cap = shift(@port_list_cap);
    my $net_2_cap = shift(@port_list_cap);
      foreach my $reg (keys %REG_DATA_HASH){
        my @port_list_reg = ();
        @port_list_reg = @{$REG_DATA_HASH{$reg}}; 
        my $net_1_reg = shift(@port_list_reg);
        my $net_2_reg = shift(@port_list_reg);
        if(($net_1_cap eq $net_1_reg) || ($net_1_cap eq $net_2_reg)){
          if(exists $PORT_HASH_OF_SUBCKT{$net_1_cap}){
#            print "$net_1_cap\n";
            push(@port_list_reg,$net_1_cap);
          }else {
#            print "$net_1_cap\n";
            push(@port_list_reg,$net_2_cap);
          }
        }if(($net_2_cap eq $net_1_reg) || ($net_2_cap eq $net_2_reg)){
          if(exists $PORT_HASH_OF_SUBCKT{$net_2_cap}){
            push(@port_list_reg,$net_2_cap);
          }else {
            push(@port_list_reg,$net_1_cap);
          }
        }
       @{$REG_DATA_HASH{$reg}} = @port_list_reg;
      }
    @{$CAP_DATA_HASH{$cap}} = @port_list_cap;
  }#foreach
  foreach my $cap (keys %CAP_DATA_HASH){
   my @new = @{$CAP_DATA_HASH{$cap}};
   #print "$cap => @new\n";
  }
  foreach my $reg (keys %REG_DATA_HASH){
    my @new = @{$REG_DATA_HASH{$reg}};
    print "$reg => @new\n";
  }
}#sub reduce_cap_and_reg
