#!/usr/bin/perl -w
my %format_keywords = ("TYPE CUT" => "TECHLEF",
                       "TYPE ROUTING" => "TECHLEF",
                       "TYPE MASTERSLICE" => "TECHLEF",
                       "TYPE OVERLAP" => "TECHLEF",
                       "PITCH" => "TECHLEF",
                       "WIDTH" => "TECHLEF",
                       "SPACING" => "TECHLEF",
                       "DIRECTION HORIZONTAL" => "TECHLEF",
                       "DIRECTION VERTICAL" => "TECHLEF",
                       "SAMENET" => "TECHLEF",

                       "MACRO" => "MACROLEF",
                       "CLASS" => "MACROLEF",
                       "FOREIGN" => "MACROLEF",
                       "ORIGIN" => "MACROLEF",
                       "SYMMETRY" => "MACROLEF",
                       "PIN" => "MACROLEF",
                       "USE POWER" => "MACROLEF",
                       "USE GROUND" => "MACROLEF",
                       "USE SIGNAL" => "MACROLEF",
                       "DIRECTION INPUT" => "MACROLEF",
                       "DIRECTION OUTPUT" => "MACROLEF",
                       "DIRECTION INOUT" => "MACROLEF",
                       "SHAPE ABUTMENT" => "MACROLEF",
                       "PORT" => "MACROLEF",
                       "SIZE" => "MACROLEF",

                       "DESIGN" => "DEF",
                       "DIEAREA" => "DEF",
                       "COMPONENTS" => "DEF",
                       "PINS" => "DEF",
                       "VIAS" => "DEF",
                       "SPECIALNETS" => "DEF",
                       "NETS" => "DEF",
                       "BLOCKAGES" => "DEF",
                       "GROUPS" => "DEF",

                       "module" => "VERILOG",
                       "endmodule" => "VERILOG",
                       "inputs" => "VERILOG",
                       "outputs" => "VERILOG",
                       "wire" => "VERILOG",

                       "always" => "RTL",
                      );


my $fileList = $ARGV[0];
my @files = split(/\,/,$fileList);
my $isFileTagged = 0;
foreach my $file (@files){
  if($isFileTagged == 1){
  }else{
    if($file =~ /\.tar\.gz/){
    }elsif($file =~ /\.tgz/){
    }elsif($file =~ /\.tar\.bz2/){ 
    }elsif($file =~ /\.tbz/){ 
    }elsif($file =~ /\.tb2/){ 
    }elsif($file =~ /\.taz/){ 
    }elsif($file =~ /\.tar\.Z/){ 
    }elsif($file =~ /\.tlz/){ 
    }elsif($file =~ /\.tar\.lz/){ 
    }elsif($file =~ /\.txz/){ 
    }elsif($file =~ /\.tar\.xz/){ 
    }elsif($file =~ /\.zip/){ 
    }elsif($file =~ /\.ZIP/){ 
    }else{
    }
    #if($file =~ /\.lef/){
    #   print "File: $file Type: LEF\n";
    #}elsif($file =~ /\.lib/){
    #   print "File: $file Type: LIB\n";
    #}elsif($file =~ /\.DEF/){
    #   print "File: $file Type: DEF\n";
    #}elsif($file =~ /\.v$/ || $file =~ /\.gv$/ || $file =~ /\.vg$/){
    #   print "File: $file Type: VERILOG\n";
    #}elsif($file =~ /\.rtl/){
    #   print "File: $file Type: RTL\n";
    #}elsif($file =~ /\.sdc/){
    #   print "File: $file Type: SDC\n";
    #}elsif($file =~ /\.gds/){
    #   print "File: $file Type: GDS\n";
    #}else{
    #   print "File: $file Type:UNKNOWN\n"; 
    #}
    my $type = &getFileType($file);
    print"File: $file Type: $type\n";
  }
}

sub getFileType {
my $file = $_[0];
my $type = "UNKNOWN";
if((-e $file) && (-r $file)){
  foreach my $keyword (keys %format_keywords){
    my $result = `grep -w "$keyword" $file`;
    print "result $result\n";
  }
  # open(READ_FILE, "$file");
  # while(<READ_FILE>){
  # my $match_found = 0;
  # chomp();  
  #   foreach my $keyword (keys %format_keywords){
  #     if($_ =~ /$keyword/){
  #        #print "aditya $_ | $keyword\n";
  #        $type = $format_keywords{$keyword};
  #        #$match_found = 1;
  #        #last;
  #        next;last;
  #     }
  #   }#foreach keyword
  #   #if($match_found == 0){next;}
  # }#while reading
}#if file exists & readable

#my @keys = keys %format_keywords;
print "type $type\n";

return $type
}#sub getFileType
