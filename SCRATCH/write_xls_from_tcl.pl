#!/usr/bin/perl
use Spreadsheet::WriteExcel;

my $numOfArg = @ARGV;

if($numOfArg < 3 || $ARGV[0] eq '-HELP' || $ARGV[0] eq '-help' || $ARGV[0] eq '-h'){
   print "Usage: write_xls.pl -tcl <tcl file>\n";
   print "                    -xls <xls file (defult: proton.xls)>\n";
   print "                    --addStripes/--powerRouting\n";
}else{
   my %xlsColumns = ();
   my ($tclFile, $xlsFile, $xlsSheet) = ("", "proton.xls", "");
   my ($writeStripes, $writePowerRoute) = (0, 0);

   for(my $i=0; $i<$numOfArg; $i++){
       if($ARGV[$i] eq '-tcl'){$tclFile = $ARGV[$i+1];}
       if($ARGV[$i] eq '-xls'){$xlsFile = $ARGV[$i+1];}
       if($ARGV[$i] eq '--addStripes'){$writeStripes = 1;$writePowerRoute = 0; $xlsSheet = 'addStripes';}
       if($ARGV[$i] eq '--powerRouting'){$writePowerRoute = 1;$writeStripes = 0; $xlsSheet = 'powerRoute';}
   }

   ########################## Reading tcl file ###############################
   if($writeStripes == 1){
      %xlsColumns = ("instance"=>1, "offset"=>2, "spacing"=>3, "dir"=>4, "side"=>5, "net"=>6, "layer"=>7, "width"=>8,"repeat"=>9,"extend"=>10);
   }elsif($writePowerRoute == 1){
      %xlsColumns = ("block"=>1, "net"=>2, "routing_side"=>3, "routing_layer"=>4, "layer_dir"=>5, "maxDistFromPinPoly2CellBoundary"=>6, "maxDistFromCellBoundary2Stripe"=>7);
   }

   if(-e $tclFile){
      my $workbook = Spreadsheet::WriteExcel->new($xlsFile);
      my $worksheet = $workbook->add_worksheet($xlsSheet);
      $worksheet->activate($xlsSheet);

      # Increase the column width for clarity
      $worksheet->set_column('A:A', 25);

      #  Add and define a format
      $format = $workbook->add_format(); # Add a format
      # Increase the font size for legibility.
      #$format = $workbook->add_format(size => 72);

      $format->set_bold();
      $format->set_shrink();
      $format->set_color('red');
      $format->set_align('center');
   
      my $rowNum = 1;
      foreach my $colName (keys %xlsColumns){
        my $colNum = $xlsColumns{$colName};
        $worksheet->write(0,$colNum,$colName,$format);
      }

      open(READ_TCL, "$tclFile");
      while(<READ_TCL>){
        if($_ =~ /^\s*#/ ){ next ; }
        if($_ =~ /\#/ ) { $_ =~ s/\s+#.*$//; }
        $_ =~ s/\s+/ /g;
        $_ =~ s/^\s+//g;
        $_=~ s/\s+$//g;
        if($writeStripes == 1 && ($_ =~ m/^\s*addStripes/)){
        }elsif($writePowerRoute == 1 && ($_ =~ m/^\s*add_power_route/)){
        }else{next;}
        my @cmdLine = split(/\s+/,$_);
        my $cmd = shift @cmdLine;
        $worksheet->write($rowNum,0,$cmd);
        for(my $i=0; $i<=$#cmdLine; $i++){
            if($cmdLine[$i] =~ m/^-(\w+)/){
               $cmdLine[$i] =~ s/\-//;
               my $colNum = $xlsColumns{$cmdLine[$i]};
               my $cellValue = $cmdLine[$i+1];
               $worksheet->write($rowNum,$colNum,$cellValue);
               $i = $i + 1;
            }
        }
        $rowNum++;
      }
   }else{
      print"WARN: tcl file does not exists!\n";
   }
}
