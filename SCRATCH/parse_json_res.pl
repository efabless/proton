#!/usr/bin/perl
use JSON;

my $filename = './library_new.config';
my $data;
if (open (my $json_str, $filename))
{
  local $/ = undef;
  my $json = JSON->new;
  $data = $json->decode(<$json_str>);
  close($json_stream);
}


foreach my $lib (keys %$data){
   print "lib:$lib\n";
   foreach my $node (@{$data->{$lib}{node}}){
      print "  type:".$node->{type}."\n";
      #print "  file:".$node->{files}."\n";
      foreach my $file (@{$node->{files}}){
          print "    layer:".$file->{layer}."\n";
          print "    std-cells:".$file->{'std-cells'}."\n";
          print "    tech:".$file->{tech}."\n";
      }
   }
}
