#!/usr/local/bin/perl -ws

use strict ;
use Test::More ;
use Fcntl qw( :seek ) ;
use File::ReadBackwards ;
use Carp ;

use vars qw( $opt_v ) ;

my $file = 'bw.data' ;

my $is_crlf = ( $^O =~ /win32/i || $^O =~ /vms/i ) ;

print "nl\n" ;
my @nl_data = init_data( "\n" ) ;
plan( tests => 10 * @nl_data + 1 ) ;
test_read_backwards( \@nl_data ) ;

print "crlf\n" ;
my @crlf_data = init_data( "\015\012" ) ;
test_read_backwards( \@crlf_data, "\015\012" ) ;

test_close() ;
unlink $file ;

exit ;

sub init_data {

	my ( $rec_sep ) = @_ ;

	return map { ( my $data = $_ ) =~ s/RS/$rec_sep/g ; $data }
			'',
			'RS',
  			'RSRS',
  			'RSRSRS',
 			"\015",
   			"\015RSRS",
  			'abcd',
  			"abcdefghijRS",
 			"abcdefghijRS" x 512,
  			'a' x (8 * 1024),
  			'a' x (8 * 1024) . '0',
  			'0' x (8 * 1024) . '0',
  			'a' x (32 * 1024),
  			join( 'RS', '00' .. '99', '' ),
  			join( 'RS', '00' .. '99' ),
  			join( 'RS', '0000' .. '9999', '' ),
  			join( 'RS', '0000' .. '9999' ),
	;
}

sub test_read_backwards {

	my( $data_list_ref, $rec_sep ) = @_ ;

	foreach my $data ( @$data_list_ref ) {

# write the test data to a file in text or bin_mode

		if ( defined $rec_sep ) { 

			write_bin_file( $file, $data ) ;

# print "cnt: ${\scalar @rev_file_lines}\n" ;

		}
		else {
			write_file( $file, $data ) ;

		}

		test_data( $rec_sep ) ;

		test_tell_handle( $rec_sep ) ;
	}
}

sub test_data {

	my( $rec_sep ) = @_ ;

# slurp in the file and reverse the list of lines to get golden data

	my @rev_file_lines = reverse read_bin_file( $file ) ;

# convert CR/LF to \n if needed - based on OS or we are testing CR/LF

	if ( $is_crlf || $rec_sep && $rec_sep eq "\015\012" ) {
		s/\015\012\z/\n/ for @rev_file_lines ;
	}

# open the file with backwards and read in the lines

	my $bw = File::ReadBackwards->new( $file, $rec_sep ) or
				die "can't open $file: $!" ;

	my( @bw_file_lines ) ;
	while ( 1 ) {

		my $line = $bw->readline() ;
		last unless defined( $line ) ;
		push( @bw_file_lines, $line ) ;

		$line = $bw->getline() ;
		last unless defined( $line ) ;
		push( @bw_file_lines, $line ) ;
	}

# 	while ( defined( my $line = $bw->readline() ) ) {
# 		push( @bw_file_lines, $line) ;
# 	}

# see if we close cleanly

	ok( $bw->close(), 'close' ) ;

# compare the golden lines to the backwards lines

	if ( eq_array( \@rev_file_lines, \@bw_file_lines ) ) {

		ok( 1, 'read' ) ;
		return ;
	}

# test failed so dump the different lines if verbose

	ok( 0, 'read' ) ;

	return unless $opt_v ;

	print "[$rev_file_lines[0]]\n" ;
	print unpack( 'H*', $rev_file_lines[0] ), "\n" ;
	print unpack( 'H*', $bw_file_lines[0] ), "\n" ;

#print "REV ", unpack( 'H*', join '',@rev_file_lines ), "\n" ;
#print "BW  ", unpack( 'H*', join '',@bw_file_lines ), "\n" ;

}

sub test_tell_handle {

	my( $rec_sep ) = @_ ;

# open the file backwards again to test tell and get_handle methods

	my $bw = File::ReadBackwards->new( $file, $rec_sep ) or
				die "can't open $file: $!" ;

# read the last line in

	my $bw_line = $bw->readline() ;

# get the current seek position

	my $pos = $bw->tell() ;

#print "BW pos = $pos\n" ;

	if ( $bw->eof() ) {

		ok( 1, "skip tell - at eof" ) ;
		ok( 1, "skip get_handle - at eof" ) ;
	}
	else {

# save the current $/ so we can reassign it if it $rec_sep isn't set

		my $old_rec_sep = $/ ; 
		local $/ = $rec_sep || $old_rec_sep ;

# open a new regular file and seek to this spot.

		open FH, $file or die "tell open $!" ;
		seek FH, $pos, SEEK_SET or die "tell seek $!" ;

# read in the next line and clean up the ending CR/LF

		my $fw_line = <FH> ;
		$fw_line =~ s/\015\012\z/\n/ ;

# print "BW [", unpack( 'H*', $bw_line ),
# "] TELL [", unpack( 'H*', $fw_line), "]\n" if $bw_line ne $fw_line ; 

# compare the backwards and forwards lines

		is ( $bw_line, $fw_line, "tell check" ) ;

# get the handle and seek to the current spot

		my $fh = $bw->get_handle() ;

# read in the next line and clean up the ending CR/LF

		my $fh_line = <$fh> ;
		$fh_line =~ s/\015\012\z/\n/ ;

# print "BW [", unpack( 'H*', $bw_line ),
# "] HANDLE [", unpack( 'H*', $fh_line), "]\n" if $bw_line ne $fh_line ; 

# compare the backwards and forwards lines

		is ( $bw_line, $fh_line, "get_handle" ) ;
	}

	ok( $bw->close(), 'close2' ) ;

}

sub test_close {

	write_file( $file, <<BW ) ;
line1
line2
BW

	my $bw = File::ReadBackwards->new( $file ) or
					die "can't open $file: $!" ;

	my $line = $bw->readline() ;

	$bw->close() ;

	if ( $bw->readline() ) {

		ok( 0, 'close' ) ;
		return ;
	}

	ok( 1, 'close' ) ;
}

sub read_file {

	my( $file_name ) = shift ;

	local( *FH ) ;

	open( FH, $file_name ) || carp "can't open $file_name $!" ;

	local( $/ ) unless wantarray ;

	<FH>
}

# utility sub to write a file. takes a file name and a list of strings

sub write_file {

	my( $file_name ) = shift ;

	local( *FH ) ;

	open( FH, ">$file_name" ) || carp "can't create $file_name $!" ;

	print FH @_ ;
}

sub read_bin_file {

	my( $file_name ) = shift ;

	local( *FH ) ;
	open( FH, $file_name ) || carp "can't open $file_name $!" ;
	binmode( FH ) ;

	local( $/ ) = shift if @_ ;

	local( $/ ) unless wantarray ;

	<FH>
}

# utility sub to write a file. takes a file name and a list of strings

sub write_bin_file {

	my( $file_name ) = shift ;

	local( *FH ) ;
	open( FH, ">$file_name" ) || carp "can't create $file_name $!" ;
	binmode( FH ) ;

	print FH @_ ;
}
