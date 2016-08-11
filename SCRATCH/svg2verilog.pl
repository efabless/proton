#!/usr/bin/perl
use XML::Simple;
use Data::Dumper;

my ($svgFile, $cloud_share_path);

if(@ARGV < 2 || $ARGV[0] eq "-help" || $ARGV[0] eq "-h" || $ARGV[0] eq "-HELP"){ 
  print "Usage: ./svg2verilog -svg <svg file name>\n"; 
  return;
}
for(my $i=0;$i <=$#ARGV;$i++){
  if($ARGV[$i] eq "-svg"){$svgFile = $ARGV[$i+1];}
  if($ARGV[$i] eq "-cloud_share_path"){$cloud_share_path = $ARGV[$i+1];}
}
my @path =split(/\//,$svgFile);
$fileName = $path[-1];
$fileName =~ s/\.svg//; 

my $data = XMLin($svgFile);

open (WRITE, ">script") || die("Cannot open file for writing");


my @polyline = ();
my @text = ();
my %CELL_VS_INPUT_PIN = ();
my %CELL_VS_OUTPUT_PIN = ();
my %CELL_VS_INST = ();
my %CELL_VS_INST_LOC = ();
my %ID_VS_INST = ();
my %PIN_VS_DIR =();
my %check_pin = ();
my $inst_cnt = 0;

my $canW = $data->{svg}->{width};
my $canH = $data->{svg}->{height};

if(ref($data->{svg}->{g}->{polyline}) eq 'ARRAY'){
   @polyline = @{$data->{svg}->{g}->{polyline}};
}elsif($data->{svg}->{g}->{polyline}){
   push(@polyline, $data->{svg}->{g}->{polyline});
}
if(ref($data->{svg}->{g}->{text}) eq 'ARRAY'){
   @text = @{$data->{svg}->{g}->{text}};
}elsif($data->{svg}->{g}->{text}){
   push(@text, $data->{svg}->{g}->{text});
}
foreach my $instId (sort {$a <=> $b} keys %{$data->{svg}->{g}->{g}}){
  my $fig_type_data = $data->{svg}->{g}->{g}->{$instId}->{type};
  my $bound_box = $data->{svg}->{g}->{g}->{$instId}->{bounds}; 
  my ($llx,$lly,$urx,$ury) = (split(/,/,$bound_box))[0,1,2,3];
  my $sizeW =sprintf("%.2f",($urx - $llx)/100);
  my $sizeH =sprintf("%.2f",($ury - $lly)/100);
  my @poly_text = @{$data->{svg}->{g}->{g}->{$instId}->{text}};
  my $poly_text_str = $poly_text[0]->{tspan}->{content};
  my @fig_data = (split(/\//,$fig_type_data));
  my $fig_type = $fig_data[0]; 
  my $input_data = $fig_data[1]; 
  my $output_data = $fig_data[2];
  $input_data =~ s/=//; 
  $input_data =~ s/input//;
  $output_data =~ s/=//; 
  $output_data =~ s/output//;

  my @input_pin = (split(/,/,$input_data));
  my @output_pin = (split(/,/,$output_data));
  if(!exists $CELL_VS_INST{$fig_type}){
    push(@{$CELL_VS_INST{$fig_type}},$poly_text, $sizeW, $sizeH);
  }
  if(!exists $CELL_VS_INPUT_PIN{$fig_type}){
    push(@{$CELL_VS_INPUT_PIN{$fig_type}},@input_pin);
  }
  if(!exists $CELL_VS_OUTPUT_PIN{$fig_type}){
    push(@{$CELL_VS_OUTPUT_PIN{$fig_type}},@output_pin);
  }
  if($poly_text_str eq ""){
    $poly_text_str = "slvr_u$inst_cnt";
    $inst_cnt++;
  }
  push(@{$CELL_VS_INST_LOC{$poly_text_str}},$fig_type, $llx,$lly);
  $ID_VS_INST{$instId} = $poly_text_str;
}#foreach

foreach my $cell (keys %CELL_VS_INST){
  my @cellvalue = @{$CELL_VS_INST{$cell}};
  print WRITE "create_lef_cell -cell $cell -size {$cellvalue[1],$cellvalue[2]}";
  if(exists $CELL_VS_INPUT_PIN{$cell}){
    my @input_pin = @{$CELL_VS_INPUT_PIN{$cell}}; 
    foreach my $pin (@input_pin){
      print WRITE " -pinData {$pin,input}";
      $PIN_VS_DIR{$cell}{$pin} = "input";
    }#foreach
  }
  if(exists $CELL_VS_OUTPUT_PIN{$cell}){
    my @output_pin = @{$CELL_VS_OUTPUT_PIN{$cell}}; 
    foreach my $pin (@output_pin){
      print WRITE " -pinData {$pin,output}";
      $PIN_VS_DIR{$cell}{$pin} = "output";
    }#foreach
  }
  print WRITE "\n";
}#foreach

print WRITE "createPseudoTopModule -top mychip -H $canH -W $canW\n";
foreach my $inst (keys %CELL_VS_INST_LOC){
  my @inst_with_loc = @{$CELL_VS_INST_LOC{$inst}};
  print WRITE "createPseudoInstance -parent mychip -cell $inst_with_loc[0] -inst $inst -loc {$inst_with_loc[1],$inst_with_loc[2]} -orient N\n";
}#foreach 
for(my $i=0; $i<=$#polyline; $i++){
  my $line_text = $text[$i]->{tspan}->{content};
  my $srcInst = $ID_VS_INST{$polyline[$i]->{src}};
  my $sinkInst = $ID_VS_INST{$polyline[$i]->{sink}};
  my $src_pin_id = $polyline[$i]->{srcPin};
  my $sink_pin_id = $polyline[$i]->{sinkPin};
}

for(my $i=0; $i<=$#polyline; $i++){
  my $line_text = $text[$i]->{tspan}->{content};
  my $srcInst = $ID_VS_INST{$polyline[$i]->{src}};
  my $sinkInst = $ID_VS_INST{$polyline[$i]->{sink}};
  my $src_pin_name = $polyline[$i]->{srcPinName};
  my $sink_pin_name = $polyline[$i]->{sinkPinName};
  if(exists $CELL_VS_INST_LOC{$srcInst}){
    my @inst_data = @{$CELL_VS_INST_LOC{$srcInst}};
    my $cellref = $inst_data[0];
    if(exists $PIN_VS_DIR{$cellref}{$src_pin_name}){
      my $dir = $PIN_VS_DIR{$cellref}{$src_pin_name};
      if($dir =~ /output/i){
        if(!exists $check_pin{$srcInst." ".$src_pin_name}){
          $check_pin{$srcInst." ".$src_pin_name} = 1;
          my $src_inst_and_pin = "0"." ".$srcInst." ".$src_pin_name;
          push(@{$NET_CONN{$line_text}},$src_inst_and_pin);
        }
      }else {
        my $src_inst_and_pin = $srcInst." ".$src_pin_name;
        push(@{$NET_CONN{$line_text}},$src_inst_and_pin);
      }
    }
  }
  if(exists $CELL_VS_INST_LOC{$sinkInst}){
    my @inst_data = @{$CELL_VS_INST_LOC{$sinkInst}};
    my $cellref = $inst_data[0];
    if(exists $PIN_VS_DIR{$cellref}{$sink_pin_name}){
      my $dir = $PIN_VS_DIR{$cellref}{$sink_pin_name};
      if($dir =~ /output/i){
        if(!exists $check_pin{$sinkInst." ".$sink_pin_name}){
          $check_pin{$sinkInst." ".$sink_pin_name} = 1;
          my $sink_inst_and_pin = "0"." ".$sinkInst." ".$sink_pin_name; 
          push(@{$NET_CONN{$line_text}},$sink_inst_and_pin);
        }
      }else {
        my $sink_inst_and_pin = $sinkInst." ".$sink_pin_name;
        push(@{$NET_CONN{$line_text}},$sink_inst_and_pin);
      }
    }
  }
}#for
foreach my $net (keys %NET_CONN){ 
  my @net_conn_data = sort @{$NET_CONN{$net}};
  my $src_data = shift (@net_conn_data); 
  my ($src_id,$src,$src_pin) = (split(/\s+/,$src_data))[0,1,2];
  print WRITE "createPseudoNet -parentModule mychip -type wire -wireWidth 1 -source $src -pin $src_pin ";
  for(my $i=0;$i<=$#net_conn_data;$i++){
    my $sink_data = $net_conn_data[$i]; 
    my ($sink,$sink_pin) = (split(/\s+/,$sink_data))[0,1];
    print WRITE "-sink $sink -pin $sink_pin ";
  }
  print WRITE "-prefix $net\n";
}#foreach
#----------------------------------------------------------------------------------------------------------------------#
print WRITE "commit_module -module mychip\n";
print WRITE "write_verilog -output $fileName.v --overwrite --hier --notWriteEmptyModule\n";
print WRITE "exit\n";
close WRITE;
system("$cloud_share_path/apps/content/drupal_app/proton -f script --nolog");
#system("/home/mansis/Projects/proton/proton -f script --nolog");
#----------------------------------------------------------------------------------------------------------------------#




