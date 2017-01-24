#!/usr/local/bin/perl -ws

use strict ;

use Carp ;
use Config ;
use Fcntl qw( :seek ) ;
use File::Temp qw( tempfile );
use Test::More ;

use File::ReadBackwards ;

# NOTE: much of this code was taken from the core perl test script
# ops/lfs.t. it was modified to test File::ReadBackwards and large files

my $test_file = 'bw.data' ;

my @test_lines = (
	"3rd from last line\n",
	"2nd from last\n",
	"last line\n",
) ;

my $test_text = join '', @test_lines ;


sub skip_all_tests {

	my( $skip_text ) = @_ ;

#	unlink $test_file ;
	plan skip_all => $skip_text ;
}

if( $Config{lseeksize} < 8 ) {
	skip_all_tests( "no 64-bit file offsets\n" ) ;
}

unless( $Config{uselargefiles} ) {
	skip_all_tests( "no large file support\n" ) ;
}

unless ( have_sparse_files() ) {
	skip_all_tests( "no sparse file support\n" ) ;
}

# run the long seek code below in a subprocess in case it exits with a
# signal

my $rc = system $^X, '-e', <<"EOF";
open(BIG, ">$test_file");
seek(BIG, 5_000_000_000, 0);
print BIG "$test_text" ;
exit 0;
EOF

if( $rc ) {

	my $error = 'signal ' . ($rc & 0x7f) ;
	skip_all_tests( "seeking past 2GB failed: $error" ) ;
}

open(BIG, ">$test_file");

unless( seek(BIG, 5_000_000_000, 0) ) {
	skip_all_tests( "seeking past 2GB failed: $!" ) ;
}


# Either the print or (more likely, thanks to buffering) the close will
# fail if there are are filesize limitations (process or fs).

my $print = print BIG $test_text ;
my $close = close BIG;

unless ($print && $close) {

	print "# print failed: $!\n" unless $print;
	print "# close failed: $!\n" unless $close;

	if( $! =~/too large/i ) {
		skip_all_tests( 'writing past 2GB failed: process limits?' ) ;
	}

	if( $! =~ /quota/i ) {
		skip_all_tests( 'filesystem quota limits?' ) ;
	}

	skip_all_tests( "large file error: $!" ) ;
}

plan tests => 2 ;

my $bw = File::ReadBackwards->new( $test_file ) or
	die "can't open $test_file: $!" ;

my $line = $bw->readline() ;
is( $line, $test_lines[-1], 'last line' ) ;

$line = $bw->readline() ;
is( $line, $test_lines[-2], 'next to last line' ) ;

unlink $test_file ;

exit ;


######## subroutines

# this is lifted wholesale from t/op/lfs.t in perl.  Also, Uri is the
# wind beneath my wings.
sub have_sparse_files {

     # don't even try for spare files on some OSs
     return 0 if {
         map { $_ => 1 } qw( MSWin32 NetWare VMS unicos )
     }->{ $^O };
     # take that, readability.

     my (undef,$big0) = tempfile();
     my (undef,$big1) = tempfile();
     my (undef,$big2) = tempfile();

     # We'll start off by creating a one megabyte file which has
     # only three "true" bytes.  If we have sparseness, we should
     # consume less blocks than one megabyte (assuming nobody has
     # one megabyte blocks...)

     open(BIG, ">$big1") or
         die "open $big1 failed: $!";
     binmode(BIG) or
         die "binmode $big1 failed: $!";
     seek(BIG, 1_000_000, SEEK_SET) or
         die "seek $big1 failed: $!";
     print BIG "big" or
         die "print $big1 failed: $!";
     close(BIG) or
         die "close $big1 failed: $!";

     my @s1 = stat($big1);

 #    diag "s1 = @s1";

     open(BIG, ">$big2") or
         die "open $big2 failed: $!";
     binmode(BIG) or
         die "binmode $big2 failed: $!";
     seek(BIG, 2_000_000, SEEK_SET) or
         die "seek $big2 failed: $!";
     print BIG "big" or
         die "print $big2 failed: $!";
     close(BIG) or
         die "close $big2 failed: $!";

     my @s2 = stat($big2);

#     diag "s2 = @s2";

     unless (
         $s1[7] == 1_000_003 && $s2[7] == 2_000_003 &&
	$s1[11] == $s2[11] && $s1[12] == $s2[12] &&
         $s1[12] > 0 ) {
#         diag 'no sparse files.  sad face.';
         return 0;
     }

#     diag 'we seem to have sparse files...';

     return 1 ;
}



