#!/usr/bin/perl
use Benchmark;
my $t0 = new Benchmark;
my $input_file ; 

for(my $i=0;$i <=$#ARGV;$i++){
  if($ARGV[$i] eq "-file"){
    $input_file = $ARGV[$i+1];
  }
}#for
open(READ,"$input_file");
my $out_file = "output.json";
open(WRITE,">$out_file");
$json_out_str = $json_out_str."[\n";
my $cnt = 0;
my $count = 0;
while(<READ>){
chomp();
  s/\{\s*//;
  s/\"//;
  s/\"://;
  if($_ =~ /name/i){
    my $name = (split(/\s+/,$_))[1];
    $name =~ s/,//;
    if($cnt <= 30){
      my $y_cnt = 10*$count;
      $json_out_str = $json_out_str."{\"name\":\"$name\",\"id\":$cnt,\"x_loc\":\"0\",\"y_loc\":$y_cnt,\"side\":\"W\"},\n",
    }elsif($cnt <= 60){
      my $x_cnt = 10*$count;
      $json_out_str = $json_out_str."{\"name\":\"$name\",\"id\":$cnt,\"x_loc\":\"$x_cnt\",\"y_loc\":0,\"side\":\"N\"},\n",
    }elsif($cnt <= 90){
      my $y_cnt = 10*$count;
      $json_out_str = $json_out_str."{\"name\":\"$name\",\"id\":$cnt,\"x_loc\":\"580\",\"y_loc\":$y_cnt,\"side\":\"E\"},\n",
    }else {
      my $x_cnt = 10*$count;
      $json_out_str = $json_out_str."{\"name\":\"$name\",\"id\":$cnt,\"x_loc\":\"$x_cnt\",\"y_loc\":580,\"side\":\"S\"},\n",
    }
  } 
$cnt++;
if($count == 30 ){
  $count = 0;
}else {
  $count++;
}
}#while
$json_out_str =~ s/},$/}/;
$json_out_str = $json_out_str."]\n";
print WRITE "$json_out_str\n";
my $t1 = new Benchmark;
my $td = timediff($t1, $t0);
print "create_json took: ",timestr($td),"\n";
