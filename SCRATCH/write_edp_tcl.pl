#!/usr/bin/perl
use XML::Simple;
#use Data::Dumper;

my ($svgFile, $tcl_file);

if(@ARGV < 4 || $ARGV[0] eq "-help" || $ARGV[0] eq "-h" || $ARGV[0] eq "-HELP"){
   print "Usage: ./write_edp_tcl.pl -svg <svg file name>\n";
   print "                          -tcl <tcl file name>\n";
}else{
   for(my $i=0; $i<=$#ARGV; $i++){
       if($ARGV[$i] eq "-svg"){$svgFile = $ARGV[$i+1];}
       if($ARGV[$i] eq "-tcl"){$tcl_file = $ARGV[$i+1];}
   }
   
   my $data = XMLin($svgFile);
   #print Dumper($data);
   
   open (WRITE, ">$tcl_file") || die("Cannot open file for writing");
   
   my $canW = $data->{width};
   my $canH = $data->{height};
   
   print "chip : $canW $canH\n"; 
   print WRITE "createPseudoTopModule -top mychip -H $canH -W $canW\n";
   
   my @polyline = ();
   my @text = ();
   
   if(ref($data->{polyline}) eq 'ARRAY'){
      @polyline = @{$data->{polyline}};
   }else{
      push(@polyline, $data->{polyline});
   }
   if(ref($data->{text}) eq 'ARRAY'){
      @text = @{$data->{text}};
   }else{
      push(@text, $data->{text});
   }
   
   
   my %INST_HASH = ();
   my $inst_cnt = 0;
   my $mod_cnt = 0;
   foreach my $inst (keys %{$data->{figure}}){ 
       my $fig_id = $data->{figure}->{$inst}->{id};
       my $type = $inst;
       my $poly_coords = $data->{figure}->{$inst}->{polygon}->{points};
       my $poly_text = $data->{figure}->{$inst}->{text}->{tspan}->{content};
       if($poly_text eq ""){
          if(exists $INST_HASH{"BD0_u".$inst_cnt}){
             $inst_cnt++;
             $poly_text = "BD0_u".$inst_cnt;
          }else{
             $poly_text = "BD0_u".$inst_cnt;
             $inst_cnt++;
          }
       }elsif(exists $INST_HASH{$poly_text}){
          open(IN, "+<$tcl_file");
          $inst_cnt++;
          my $new_name = "BD0_u".$inst_cnt;
          while (<IN>){
             s/$poly_text/$new_name/;
          }
          close IN;
       }else{ }
      
       $INST_HASH{$poly_text} = $fig_id;
      
       my @coords = split(/\s+|\,/,$poly_coords);
       
       print "POLYGON:$mod_cnt coord=>@coords name=>$poly_text type=>$type\n";
       print WRITE "createPseudoModule -top mychip -bbox {$coords[0],$coords[1],$coords[4],$coords[5]} -module BD0_mod$mod_cnt\n";
       print WRITE "createPseudoHierModuleInst -parent mychip -bbox {$coords[0],$coords[1],$coords[4],$coords[5]} -cellref BD0_mod$mod_cnt -inst $poly_text\n";
       $mod_cnt++; 
       #$INST_COORD{$poly_text} = [$poly_text, @coords];
   }
   
   %INST_HASH = reverse %INST_HASH;
   for(my $i=0; $i<=$#polyline; $i++){
       my $line_coords = $polyline[$i]->{points};
       my $srcInst = $INST_HASH{$polyline[$i]->{src}};
       my $sinkInst = $INST_HASH{$polyline[$i]->{sink}};
       my $line_text = $text[$i]->{tspan}->{content};
       my @coords = split(/\s+|\,/,$line_coords);
       my $coord_str = join (",", @coords);
       
       #xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx Added by Mansi xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx#
       my $poly_style = $polyline[$i]->{style};
       my $temp_poly_style = $poly_style;                           
       $temp_poly_style =~ s/.*-width/width/;
       my $wireWidth = "";
       my $type = "";
       if($temp_poly_style =~m/width/){my $width = (split(/\s*:\s*/,$temp_poly_style))[1];
         $width =~ s/;.*//;
         $wireWidth = $width/0.2; 
         #print "$wireWidth\n";
         if($wireWidth == 1){
           $type = "wire";
         }else{
           $type = "bus";
         }
       }#if

       #xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx#
       print "LINE:$i coord=>@coords connection=> $srcInst, $sinkInst\n";
       if($line_text eq ""){
          print WRITE "createPseudoNet -parentModule mychip -type $type -wireWidth $wireWidth -inst {$srcInst,$sinkInst} -netCoords $coord_str\n";
       }else{
          print WRITE "createPseudoNet -parentModule mychip -type $type -wireWidth $wireWidth -inst {$srcInst,$sinkInst} -netCoords $coord_str -prefix $line_text\n";
       }
   }
   
   close WRITE;
}


