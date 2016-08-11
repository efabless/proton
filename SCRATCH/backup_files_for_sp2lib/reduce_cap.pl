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
  my %TRANS_DATA_HASH_NEW = ();
  open(READ,"$include_sp_file");
  open(WRITE,">$file-reduce-cap-res.sp");
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
  foreach my $cap1 (keys %CAP_DATA_HASH){
     my ($net1, $net2) = @{$CAP_DATA_HASH{$cap1}};
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
     foreach my $cap2 (keys %CAP_DATA_HASH){
       for(my $i=0; $i<2; $i++){
           if($CAP_DATA_HASH{$cap2}[$i] eq $replace_net){
              $CAP_DATA_HASH{$cap2}[$i] = $replace_val;
           }
       }
     }
     foreach my $res (keys %REG_DATA_HASH){
       for(my $i=0; $i<2; $i++){
           if($REG_DATA_HASH{$res}[$i] eq $replace_net){
              $REG_DATA_HASH{$res}[$i] = $replace_val;
           }
       }
     }
  }

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
  
print "TRA\n";
  foreach my $k (keys %TRANS_DATA_HASH){
     my @val = @{$TRANS_DATA_HASH{$k}};
     if(exists $TRANS_DATA_HASH_NEW{$k}){
       my @new_val = @{$TRANS_DATA_HASH_NEW{$k}};
       print WRITE "$k => @val @new_val\n";
       print "$k => @val @new_val\n";
     }
  }
  print WRITE ".ends\n";
print "CAP\n";
  foreach my $k (keys %CAP_DATA_HASH){
     my @val = @{$CAP_DATA_HASH{$k}};
     #print "$k => @val\n";
  }
print "RG\n";
  foreach my $k (keys %REG_DATA_HASH){
     my @val = @{$REG_DATA_HASH{$k}};
     #print "$k => @val\n";
  }
close (WRITE);
}#sub reduce_cap_and_reg
