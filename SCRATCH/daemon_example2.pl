
use DBI;
use POSIX qw(setsid);

chdir '/'                 or die "Can't chdir to /: $!";
umask 0;
open STDIN, '/dev/null'   or die "Can't read /dev/null: $!";
open STDOUT, '>/home/rajeevs/mac.rpt' or die "Can't write to /dev/null: $!";
open STDERR, '>/dev/null' or die "Can't write to /dev/null: $!";
defined(my $pid = fork)   or die "Can't fork: $!";
exit if $pid;
setsid                    or die "Can't start a new session: $!";

while(1) {
   sleep(2);
my $waitTime = 5;
my $estRunTime = 5;
#----------------------------------------------#
# get status of machines                       #
#----------------------------------------------#
system("rschedule status > /tmp/mac.status");
open(READ,"/tmp/mac.status");
my %macHash = ();
while(<READ>){
             chomp();
             my ($macName, $load) = (split(/\s+/,$_))[0,1];
             if ( $load =~ /[0-9]+\.[0-9]+\%/ ) {
             $load =~ s/\%//;
                                                $macHash{$load}=$macName;
                                                }
             }
close(READ);
my @l;
foreach $m ( keys %macHash ) { 
                             print "$m $macHash{$m}\n"; 
                             if ( $m < 60 ) { push(@l,$m); }
                             }
my @key = sort{$a <=> $b} @l;
print "least loaded machine is $key[0] : $macHash{$key[0]} \n";

#----------------------------------------------#
#query SQL data base for testcases             # 
#----------------------------------------------#
#$KB_DATABASE="DB;aditya.lnx4.com";
$dbh = DBI->connect( "dbi:mysql:$KB_DATABASE",qaadmin,qaadmin ) || die "Cannot connect: $DBI::errstr";

my $jobcount = 1;
my $machinesAvailable = @key;
print "INFO : $machinesAvailable machines are available for execution\n";

$sth = $dbh->prepare( "SELECT Status, TestPath, TestName  FROM designStat");
$sth->execute;
my @jobQueue = ();
while (($status, $tp, $t) = $sth->fetchrow_array) {;
last if ( $jobcount > $machinesAvailable ) ;
if ( $status == 0 ) {
                    print "preparing to execute $t on $macHash{$key[$jobcount-1]}\n";
                    push(@jobQueue,$t);
                    print "Launching a job on the machine $macHash{$key[0]} ....\n";
#                    system("perl /home/rajeevs/Projects/proton/SCRATCH/runRegression.pl $macHash{$key[0]} $tp &");
#                    fork("perl /home/rajeevs/Projects/proton/SCRATCH/runRegression.pl $macHash{$key[0]} $tp");
                    sleep($waitTime);
                    print "finished job ....\n";
                    $jobcount ++;
                    }
                                                  }# while
$sth->finish;
foreach my $t ( @jobQueue ) {
                    $sth = $dbh->prepare( "UPDATE designStat SET Status = '2' WHERE TestName='$t'" );
                    $sth->execute;
                    print "Setting the status of test case $t as 2 : processing\n";
                               }

#----------------------------------------------#
#launch jobs on that machine                   # 
#----------------------------------------------#

#----------------------------------------------#
#send email of successful job execution        # 
#----------------------------------------------#
}# while
