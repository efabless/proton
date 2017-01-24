my $loaded;
BEGIN { $| = 1; $loaded = 0; print "1..2\n"; }
use GDS2;
sub ok
{
    my ($n, $result, @info) = @_;
    if ($result) {
        print "ok $n\n";
    }
    else {
        print "not ok $n\n";
        print "# @info\n" if @info;
    }
}

$loaded = 1;
ok(1,$loaded,'problem with GDS2 load.');

open(DUMPIN,"TEST.dump") or die "Unable to read TEST.dump because $!";
my $gds2FileOut = new GDS2(-fileName => ">testdump.gds");
my $dataString;
while (<DUMPIN>)
{
    my $line=$_;
    $line=~s|^\s+||; ## make following comparisions easier...
    next if (m|^#|); ## see # as here-to-line-end comment
    chomp $line;
    $line=~s|#.*||;
    $line=~s|$| |g;  ## for match below
    $dataString='';
    if ($line =~ m|^([a-z]+) (.*)|i)
    {
        my $type=$1;
        $dataString=$2 if (defined $2);
        $gds2FileOut -> printGds2Record(-type=>$type,-asciiData=>$dataString)
    }
    else
    {
        print STDERR "\nWARNING: Unable to parse '$line'\n";
    }
}
$gds2FileOut -> close;
close DUMPIN;

my $gds2File = new GDS2(-fileName => 'testdump.gds');
my $G_epsilon = $gds2File -> getG_epsilon;
my $G_fltLen = $gds2File -> getG_fltLen;
open(DUMPOUT,">dump.gdt") or die "Unable to create dump.gdt $!";
my $printLine = "";
while ($gds2File -> readGds2Record)
{
    my $line = $gds2File -> returnRecordAsString(-compact => 1);
    print DUMPOUT "$line";
}
close DUMPOUT;

my $good=1;
open(DUMPNEW,"dump.gdt") or die "Unable to read dump.gdt $!";
open(DUMPOLD,"TEST.gdt") or die "Unable to read TEST.gdt because $!";
READGDT: while (my $line1 = <DUMPOLD>)
{
    next READGDT if ($line1 =~ m/^#/); #comment
    chomp $line1;
    my $line2 = <DUMPNEW>;
    chomp $line2;
    if ($line1 ne $line2)
    {
        $good = 0;
        print STDERR "\nold:$line1 != new:$line2 -> DeveloperNote: G_epsilon==$G_epsilon G_fltLen=$G_fltLen\n";
    }
}
close DUMPOLD;
close DUMPNEW;
if ($good)
{
    unlink"testdump.gds";
    unlink "dump.gdt";
}
ok(2,$good,'problem with ascii dump.');
0;

