#!/usr/bin/perl -w


my ($LOGFILE1, $LOGFILE2);
my $noOfArguments = @ARGV;
#print "No of arguments: $noOfArguments\n";
if($ARGV[0] eq "-h" )  {
        print "Usage :  editTimeStamp";
        print "                       -log <encounter log file>\n";
        print "                       <-debug>\n";

  }
  else {
  for(my $i = 0; $i < $noOfArguments; $i++){
  if($ARGV[$i] eq "-log"){
    $LOGFILE1 = $ARGV[$i+1];
  }
  elsif ($ARGV[$i] eq "-debug") {
   $debug = 1;
  }
} #end for

#system ("cp /home/rajeevs/soc.txt log_header");
$LOGFILE2 = "encounter.temp.log";
open(READ_LOG, "$LOGFILE1");
open(HEADER, "log_header");
open (WRITE_LOG, ">$LOGFILE2");#|| die("Cannot open file for writing");

while(<HEADER>) {
print WRITE_LOG "$_";
}

for (my $i = 1; $i<=35; $i++){
my $a = <READ_LOG>;
}
while(<READ_LOG>){
print WRITE_LOG "$_";
}

close (READ_LOG);
close(HEADER);
close (WRITE_LOG);

#$date = `date`;
$date = "Fri Jan  29 10:49:32 PST 2010";
print "Today's date is $date\n";
@date = split(/\s+/,$date);
$str = "$date[0]"." "."$date[1]"." "."$date[2]";
print "String is $str\n";
open(LOG_F, "encounter.temp.log");
open(WRITE_F, ">encounter.temp2.log");

while (<LOG_F>){
	if ($_ =~ m/(Sun|Mon|Tue|Wed|Thu|Fri|Sat) \S{3} \d{2}/ ) {
		print "$_ ";
		$_ =~ s/(Sun|Mon|Tue|Wed|Thu|Fri|Sat) \S{3} \d{2} (.*) (2008|2009|2010)/$str $2 2010/	;
		print $_;
	}
print WRITE_F "$_ ";
}

system ("rm encounter.temp.log");
system ("cp encounter.temp2.log encounter.log");
system ("rm encounter.temp2.log");
} #end else
