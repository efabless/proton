#!/usr/bin/perl
#my $file = $ARGV[0];
my $file = "k_map_input.txt";
open(READ, "$file");
my $count = 0;
my @in_out = ();
my @final_data = ();
my $str = "";

############# Read Input file ##############
while(<READ>){
  chomp();
  $_ =~ s/^\s+//;
  if($count == 0){
     @in_out = split(/\s+/,$_);
  }else{
     my @data = split(/\s+/,$_);
     push (@final_data, [@data]);
  }
  $count++;
}#while reading 
close READ;

############# process data ################
foreach my $data (@final_data){
   my @binary_data = @$data;
   my $out_bit = pop @binary_data;
   if($out_bit == 1){
      for(my $i=0; $i<=$#binary_data; $i++){
          if($binary_data[$i] == 1){
             $str = $str.$in_out[$i];
          }else{
             $str = $str."!".$in_out[$i];
          }
      }
      $str = $str." + "; 
   }
}
$str =~ s/\+\s+$//;
$str = $in_out[-1]." = ".$str;

###########################################
print "$str\n";

