#! /usr/bin/perl

my @AGRV = @_;
if( $ARGV[0] eq '-h' || $ARGV[0] eq '-help' ) { 
  print "Usage : ./genEnc_conf\n";
  print "                  -fname <file name to read [default name is \"config_file\"]> \n";
  print "                  -outname <output file name [default name is \"Default.conf\"]> \n";
} else { # if correct no. of inputs
  my $config_file = "config_file";
  my $scriptfile = "Default.conf";
  my $techleffiles = ""; my $techlef = 0;
  my @leffiles = ();     my $lef = 0;
  my $deffiles = "";     my $def = 0;
  my @netlistfiles = (); my $netlist = 0;
  my @libfiles = ();     my $lib = 0;
  my @sdcfiles = ();     my $sdc = 0;
  my @rtlfiles = ();     my $rtl = 0;
  my $modulename = "";   my $top = 0;
  for(my $i = 0; $i <= $#ARGV; $i++) {
    if($ARGV[$i] eq "-fname")         { $config_file = $ARGV[$i+1]; }
    if($ARGV[$i] eq "-outname")       { $scriptfile = $ARGV[$i+1]; }
  }
   if(-r $config_file){
    open (READ, $config_file);
    while (<READ>) {
      chomp;
      if($_ =~ /^\s*#/ ){next;}
      if($_ =~ /^\#/ ){next;}
      my ($filetype,$filename)=(split(/\:\s*/,$_))[0,1];
      if($filetype eq "TECHLEF"){
        $techlef = 1;
        $techleffiles = $filename;
      }elsif($filetype eq "LEF"){
        $lef = 1;
        push(@leffiles, $filename);
      }elsif($filetype eq "LIB"){
        $lib = 1;
        push(@libfiles, $filename);
      }elsif($filetype eq "DEF"){
        $def = 1;
        $deffiles = $filename;
      }elsif($filetype eq "NETLIST"){
        $netlist = 1;
        push(@netlistfiles, $filename);
      }elsif($filetype eq "SDC"){
        $sdc = 1;
        push(@sdcfiles, $filename);
      }elsif($filetype eq "RTL"){
        $rtl = 1;
        push(@rtlfiles, $filename);
      }elsif($filetype eq "TOP"){
        $top = 1;
        $modulename = $filename;
      }
    }#while read
    close(READ);
    open (READ_CONF, "/vol5/testcase/rajeevs/Default.conf");	
    open (WRITE, ">$scriptfile");
    while (<READ_CONF>) {
    print "I am in \n";
        if($_ =~ / cwd /){
	  my $path  = `pwd`;
	  chomp ($path);
          print WRITE "set cwd $path\n"; 
        }elsif($_ =~ /\(ui_netlist\)/){
          print WRITE "set rda_Input(ui_netlist) \"@netlistfiles\"\n"; 
        }elsif($_ =~ /ui_topcell/){
		if ($top == 1) {
			print WRITE "set rda_Input(ui_topcell) {$modulename}";
		} else {print WRITE $_ ;}
        }elsif($_ =~ /ui_timelib,min/){
          print WRITE "set rda_Input(ui_timelib,min) \"@libfiles\"\n"; 
        }elsif($_ =~ /ui_timelib,max/){
          print WRITE "set rda_Input(ui_timelib,max) \"@libfiles\"\n"; 
        }elsif($_ =~ /\(ui_timingcon_file\)/){
          print WRITE "set rda_Input(ui_timingcon_file) \"@sdcfiles\"\n"; 
        }elsif($_ =~ /\(ui_leffile\)/){
          print WRITE "set rda_Input(ui_leffile) \"$techleffiles @leffiles\"\n"; 
        }else {
      	  print WRITE $_;
	}  
    } #end while
    close(WRITE);
    close (READ);


  } else {
    print"file not readable\n";
  }

} #end else
