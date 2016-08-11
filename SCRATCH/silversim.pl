#!/usr/bin/perl
use Benchmark;
my $t0 = new Benchmark;

my $noOfArg = @ARGV; 
my ($prmFile, $spFileStr, $cmdFileStr, $argStr) = ("", "", "", "");

if($ARGV[0] eq "-h" || $ARGV[0] eq "-help" || $ARGV[0] eq "-HELP"){
   print"Usage: silversim  -prmFile <parameter file>\n";
   print"                  -spiceFile <{sp1,sp2,sp3...}>\n";
   print"                  -spiceLib <{dir1,dir2,dir3...}>\n";
   print"                  -cmdFile <cmd file>\n";
   print"                  -in_unit <input unit>\n";
}else{
   for(my $xx=0; $xx<$noOfArg; $xx++){
       if($ARGV[$xx] eq "-prmFile"){$prmFile = $ARGV[$xx+1];}
       if($ARGV[$xx] eq "-spiceFile"){
          $spFileStr = $ARGV[$xx+1];}
          $spFileStr =~ s/\{\s*//; 
          $spFileStr =~ s/\s*\}//;
       if($ARGV[$xx] eq "-spiceLib"){
          $spLibDirStr = $ARGV[$xx+1];
          $spLibDirStr =~ s/\{\s*//; 
          $spLibDirStr =~ s/\s*\}//;
          $argStr .= "-spiceLib $spLibDirStr --complete_spice ";
       } 
       if($ARGV[$xx] eq "-cmdFile"){
          $cmdFileStr = $ARGV[$xx+1]; 
          $cmdFileStr =~ s/\{\s*//; 
          $cmdFileStr =~ s/\s*\}//;
       }
       if($ARGV[$xx] eq "-in_unit"){
          my $inUnit = $ARGV[$xx+1];
          $argStr .= "-in_unit $inUnit -out_unit micron ";
       }
   }
  
   ################ making command file args ##################
   my @cmdFileArr = split(/\,/,$cmdFileStr);
   $cmdFile = join(" -", @cmdFileArr);
 
   ################ script to generate silversim format spice from spice/verilog file ##################
   open(WRITE, ">script");
   my @spFilesArr = split(/\,/,$spFileStr);
   foreach my $spFile(@spFilesArr){
      print WRITE "read_spice_new -sp $spFile\n";
   }
   print WRITE "write_spice_file $argStr -output silversim.sp --hier --vector_bit_blast --add_top_instance --add_spice_missing_port --global_change_pin_vss_to_gnd --add_first_blank_line --notWriteEmptyModule --add_global_vdd_and_gnd\n";
   print WRITE "exit\n";
   close(WRITE);

   close(WRITE);
   system("/apps/proton -f script --nolog");

   ############################ running silversim app ##############################
   open(WRITE, ">silversim_cmdline");
    print WRITE "/apps/imager_irsim $prmFile silversim.sp -$cmdFile -spargs -vcd\n";
   close(WRITE);
   system("/apps/imager_irsim $prmFile silversim.sp -$cmdFile -spargs -vcd");
   system("/apps/processVcd -vcd_in silversim.dmp -vcd_out silversim.vcd --overwrite");
}
my $t1 = new Benchmark;
my $td = timediff($t1, $t0);
print "silversim took:",timestr($td),"\n";
