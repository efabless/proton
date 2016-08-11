#!/usr/bin/perl
use XML::Simple;
#use Data::Dumper;

my $svgFile = $ARGV[0];
my $tcl_file = $ARGV[1];

my $data = XMLin($svgFile);
#print Dumper(data);

my %MOD_TYPE = ("#ffffff"=>"Empty Mod", "#008000"=>"Hard Macro", "#00FF00"=>"Memory", "#FF8C00"=>"Soft Macro", "#0000CD"=>"IO pads");


open (WRITE, ">$tcl_file") || die("Cannot open file for writing");

my $canW = $data->{width};
my $canH = $data->{height};

print "chip : $canW $canH\n"; 
print WRITE "createPseudoTopModule -top mychip -H $canH -W $canW\n";

my @polyline = ();
my @polygon = ();
my @text = ();

if(ref($data->{polyline}) eq 'ARRAY'){
   @polyline = @{$data->{polyline}};
}else{
   push(@polyline, $data->{polyline});
}
if(ref($data->{polygon}) eq 'ARRAY'){
   @polygon = @{$data->{polygon}};
}else{
   push(@polygon, $data->{polygon});
}
if(ref($data->{text}) eq 'ARRAY'){
   @text = @{$data->{text}};
}else{
   push(@text, $data->{text});
}

#print "line: @polyline | poly @polygon | text @text\n";

my $total_num_line = @polyline;
my $total_num_poly = @polygon;
my $total_num_text = @text;

my %INST_COORD = ();
my $inst_cnt = 0;

for(my $i=0; $i< $total_num_poly - $total_num_line; $i++){
    my $poly_coords = $polygon[$i]->{points};
    my $poly_style = $polygon[$i]->{style};
    my $poly_text = $text[$i]->{tspan}->{content};
    if($poly_text eq ""){$poly_text = "BD0_u".$inst_cnt; $inst_cnt++;}

    $poly_style =~ m/fill:(.*?);/;
    my $type = $MOD_TYPE{$1};
    my @coords = split(/\s+|\,/,$poly_coords);
  
    print "POLYGON:$i coord=>@coords name=>$poly_text type=>$type\n";
    print WRITE "createPseudoModule -top mychip -bbox {$coords[0],$coords[1],$coords[4],$coords[5]} -module BD0_mod$i\n";
    print WRITE "createPseudoHierModuleInst -parent mychip -bbox {$coords[0],$coords[1],$coords[4],$coords[5]} -cellref BD0_mod$i -inst $poly_text\n";

    $INST_COORD{$poly_text} = [$poly_text, @coords];
}

for(my $i=0; $i< $total_num_line; $i++){
    my $line_coords = $polyline[$i]->{points};
    my $line_text = $text[$total_num_poly - $total_num_line+$i]->{tspan}->{content};
    my @coords = split(/\s+|\,/,$line_coords);
    my $coord_str = join (",", @coords);
    
    my $stX = $coords[0];
    my $stY = $coords[1];
    my $edX = $coords[-2];
    my $edY = $coords[-1];
     
    my $cnt = 0; 
    my @src_sink = ();
    foreach my $inst (keys %INST_COORD){
       if($cnt >= 2){last;}
       my @data = @{$INST_COORD{$inst}};
       my $polyType = shift @data;
       for(my $j=0; $j<=$#data; $j=$j+2){
           my $xx =  sprintf("%.5f", $data[$j]);
           my $yy =  sprintf("%.5f", $data[$j+1]);

           if(($data[$j] == $stX || $data[$j] == $edX || $data[$j+1] == $stY || $data[$j+1] == $edY) || ($xx == $stX || $xx == $edX || $yy == $stY || $yy == $edY)){
              push (@src_sink, $inst);
              $cnt++;
              last;
           }
       }
    }
    print "LINE: coord=>@coords connection=> @src_sink\n";
    if($line_text eq ""){
       print WRITE "createPseudoNet -parentModule mychip -type wire -wireWidth 1 -inst {$src_sink[0],$src_sink[1]} -netCoords $coord_str\n";
    }else{
       print WRITE "createPseudoNet -parentModule mychip -type wire -wireWidth 1 -inst {$src_sink[0],$src_sink[1]} -netCoords $coord_str -prefix $line_text\n";
    }
}

close WRITE;


