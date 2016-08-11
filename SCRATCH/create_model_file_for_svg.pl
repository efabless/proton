#!/usr/bin/perl
use Benchmark;
my $t0 = new Benchmark;
my $drupal_temp_path; 
my $fileName = "";
my $cloud_share_path; 
my $read_model_file = "read_model_file";
for(my $i =0; $i<=$#ARGV;$i++){
  if($ARGV[$i] eq "-model"){$fileName = $ARGV[$i+1];}
  if($ARGV[$i] eq "-cloud_share_path"){$cloud_share_path = $ARGV[$i+1];} 
  if($ARGV[$i] eq "-drupal_temp_storage_path"){
          $drupal_temp_path = $ARGV[$i+1];
    }

}#for
if( -e $fileName) {
  open(READ_FILE,$fileName);
  open(WRITE_FILE,">$read_model_file");
  while(<READ_FILE>){
    chomp();
    print WRITE_FILE"$_\n";
  }#while
  print WRITE_FILE".end\n";
  close(WRITE_FILE);
  
  &read_model_file($read_model_file);
}else {
  open(WRITE_MODEL,">temp_model_file");
  close(WRITE_MODEL);
  system("cp temp_model_file $drupal_temp_path/");
  system("rm -rf temp_model_file");

}

sub read_model_file {
my $model_file = $_[0];
open(READ,"$model_file");
my $previous_line = "";
my $next_line = "";
my %MODEL_NAME_HASH = ();
my %PARAM_NAME_HASH = ();
my $parameter_val_expr = "([^ ']+=(('[^']+')|([^ ]+)))";
while(<READ>){
  chomp($_);
  if($_ =~ /^\s*\*/){next;}
  if($_ =~ /^\s*$/){next;}
  if($_ =~ /^\s*\+/){
    s/\s+$//;
    s/^\s*\+\s*//;
    $previous_line = $previous_line." ".$_;
    next;
  }
  $next_line = $_;
  $previous_line =~ s/^\s*//;
  $previous_line =~ s/\s*$//;
  if($previous_line =~ /.param/i){
    $previous_line =~ s/^\s*\.param\s*//i;
    $previous_line =~ s/\s+$//g;
    $previous_line =~ s/\s*=\s*/=/g;
    my @param_data = ();
    while($previous_line =~ /^\s*$parameter_val_expr/){
      push(@param_data,$1); 
      $previous_line =~ s/^\s*\Q$1\E//;
    }
    foreach my $param_str (@param_data){
      my ($key,$value) = (split(/=/,$param_str))[0,1];
      #print "$key => $value\n"; 
      $value =~ s/'//g;
      $PARAM_NAME_HASH{$key} = $value;
    }
  }elsif($previous_line =~ /.model/i){
    $previous_line =~ s/^\s*\.model\s*//i;
    $previous_line =~ s/\s+/ /g;
    my $temp_previous_line = $previous_line;
    $temp_previous_line =~ s/\(.*//g;
    $previous_line =~ s/.*\(\s*//g;
    $previous_line =~ s/=//g;
    my @model_data = (split(/\s+/,$previous_line));
    my ($model_name,$type) = (split(/\s+/,$temp_previous_line))[0,1];
    for(my $i=0;$i<=$#model_data;$i=$i+2){
       $MODEL_NAME_HASH{$model_name." ".$type}{$model_data[$i]} = $model_data[$i+1]; 
    }#for 
  }
$previous_line = $next_line;
}#while
close(READ);
my %GET_PARAM_VALUE = &get_value_frm_hash(\%PARAM_NAME_HASH);
open(WRITE_MODEL,">temp_model_file");
foreach my $type (keys %MODEL_NAME_HASH){
  print WRITE_MODEL ".MODEL $type\n";
  my @all_value = ();
  my $cnt =0;
  foreach my $key (keys %{$MODEL_NAME_HASH{$type}}){
    my $value = $MODEL_NAME_HASH{$type}{$key}; 
    $value =~ s/\)//;
    if(exists $GET_PARAM_VALUE{$value}){
       if($cnt == 3){
         push (@all_value,"\n+","$key = $GET_PARAM_VALUE{$value} "); 
         $cnt = 0;
       }else {
         push (@all_value,"$key = $GET_PARAM_VALUE{$value} "); 
       }
       $cnt++;
    }else {
       if($cnt == 3){
         push (@all_value,"\n+","$key = $value "); 
         $cnt = 0;
       }else {
         push (@all_value,"$key = $value "); 
       }
       $cnt++;
    }
  }#foreach 
  my $all_value_1 = shift @all_value;
  my $all_value_2 = shift @all_value;
  my $all_value_3 = shift @all_value;
  print WRITE_MODEL "+ $all_value_1 $all_value_2 $all_value_3";
  print WRITE_MODEL "@all_value\n";
  print WRITE_MODEL "\n";
}#foreach
close (WRITE_MODEL);
system("cp temp_model_file $drupal_temp_path/");
system("rm -rf read_model_file");
system("rm -rf temp_model_file");

}#sub read_model_file
#---------------------------------------------------------#
sub get_value_frm_hash {
my %PARAM_HASH = %{$_[0]}; 
my $plus = "+";
my $minus = "-";
my $multiply = "*";
my $divide = "/";
my $opening_bracket = "(";
my $closing_bracket = ")";
my @value_arr = ();
my $new_value = "";
my $value = "";
my $any_param_value_replaced = 1;
while ($any_param_value_replaced==1) {
  $any_param_value_replaced = 0;
  foreach my $temp_param (keys %PARAM_HASH){
    $value = $PARAM_HASH{$temp_param};
    $value =~ s/([^Ee])\Q$plus\E/$1 $plus /g;
    $value =~ s/([^Ee])\Q$minus\E/$1 $minus /g;
    $value =~ s/\Q$multiply\E/ $multiply /g;
    $value =~ s/\Q$divide\E/ $divide /g;
    $value =~ s/\Q$opening_bracket\E/ $opening_bracket /g;
    $value =~ s/\Q$closing_bracket\E/ $closing_bracket /g;
    @value_arr = (split(/\s+/,$value));
    foreach my $var (@value_arr){
      if(exists $PARAM_HASH{$var}){
        my $key_value = $PARAM_HASH{$var};
        if(!exists $PARAM_HASH{$key_value}){
          if(($key_value !~ /\s*[^Ee]\Q$plus\E\s*/)
            &&($key_value !~ /\s*[^Ee]\Q$minus\E\s*/)
            &&($key_value !~ /\s*\Q$multiply\E\s*/)
            &&($key_value !~ /\s*\Q$divide\E\s*/)
            &&($key_value !~ /\s*\Q$opening_bracket\E\s*/)
            &&($key_value !~ /\s*\Q$closing_bracket\E\s*/)){
            $value =~ s/\Q$var\E/$key_value/g;
            $any_param_value_replaced = 1;
          }
        }
      }
    }
    $PARAM_HASH{$temp_param} = $value;
    $eval_in = $value;
    $eval_in =~ s/\s+//g;
    $eval_in =~ s/\Q$minus$minus\E/$plus/g;
    $eval_in =~ s/\Q$minus$plus\E/$minus/g;
    $eval_in =~ s/\Q$plus$minus\E/$minus/g;
    $eval_in =~ s/\Q$plus$plus\E/$plus/g;
    my $eval_value = eval ($eval_in);
    if($eval_value ne ""){
      $PARAM_HASH{$temp_param} = $eval_value;
    }
  }
}
my %GET_PARAM_VALUE = %PARAM_HASH;
return(%GET_PARAM_VALUE);
}#sub get_value_frm_hash
#---------------------------------------------------------#
my $t1 = new Benchmark;
my $td = timediff($t1,$t0);
print "create_model_file_for_svg :",timestr($td),"\n";

