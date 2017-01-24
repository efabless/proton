#
# PDF::Image::JPEG - JPEG image support for PDF::Create
#
# Author: Michael Gross <info@mdgrosse.net>
#
# Copyright 1999-2001 Fabien Tassin
# Copyright 2007-     Markus Baertschi <markus@markus.org>
#
# Please see the CHANGES and Changes file for the detailed change log
#
# Please do not use any of the methods here directly. You will be
# punished with your application no longer working after an upgrade !
# 

package PDF::Image::JPEG;
use strict;
use warnings;
use FileHandle;

our $VERSION = '1.10';
our $DEBUG   = 0;

sub new
{
	my $self = {};

	$self->{private}        = {};
	$self->{width}          = 0;
	$self->{height}         = 0;
	$self->{colorspacedata} = "";
	$self->{colorspace}     = "";
	$self->{colorspacesize} = 0;
	$self->{filename}       = "";
	$self->{error}          = "";
	$self->{imagesize}      = 0;
	$self->{transparent}    = 0;
	$self->{filter}         = ["DCTDecode"];
	$self->{decodeparms}    = {};

	bless($self);
	return $self;
}

sub pdf_next_jpeg_marker
{
	my $self = shift;
	my $fh   = shift;
	my $c    = 0;
	my $s;
	my $M_ERROR = 0x100;    #dummy marker, internal use only
	                        #my $dbg = "";

	while ( $c == 0 ) {
		while ( $c != 0xFF ) {
			if ( eof($fh) ) {

				#print "EOF in next_marker ($dbg)\n";
				return $M_ERROR;
			}
			read $fh, $s, 1;
			$c = unpack( "C", $s );

			#$dbg.=" " . sprintf("%x", $c);
		}

		while ( $c == 0xFF ) {
			if ( eof($fh) ) {

				#print "EOF in next_marker ($dbg)\n";
				return $M_ERROR;
			}
			read $fh, $s, 1;
			$c = unpack( "C", $s );

			#$dbg.=" " . sprintf("%x", $c);
		}
	}

	#print "next_marker: $dbg\n";
	return $c;
}

sub Open
{
	my $self     = shift;
	my $filename = shift;
	$self->{filename} = $filename;

	my $M_SOF0 = 0xc0;    # baseline DCT
	my $M_SOF1 = 0xc1;    # extended sequential DCT
	my $M_SOF2 = 0xc2;    # progressive DCT
	my $M_SOF3 = 0xc3;    # lossless (sequential)

	my $M_SOF5 = 0xc5;    # differential sequential DCT
	my $M_SOF6 = 0xc6;    # differential progressive DCT
	my $M_SOF7 = 0xc7;    # differential lossless

	my $M_JPG   = 0xc8;   # JPEG extensions
	my $M_SOF9  = 0xc9;   # extended sequential DCT
	my $M_SOF10 = 0xca;   # progressive DCT
	my $M_SOF11 = 0xcb;   # lossless (sequential)

	my $M_SOF13 = 0xcd;   # differential sequential DCT
	my $M_SOF14 = 0xce;   # differential progressive DCT
	my $M_SOF15 = 0xcf;   # differential lossless

	my $M_DHT = 0xc4;     # define Huffman tables

	my $M_DAC = 0xcc;     # define arithmetic conditioning table

	my $M_RST0 = 0xd0;    # restart
	my $M_RST1 = 0xd1;    # restart
	my $M_RST2 = 0xd2;    # restart
	my $M_RST3 = 0xd3;    # restart
	my $M_RST4 = 0xd4;    # restart
	my $M_RST5 = 0xd5;    # restart
	my $M_RST6 = 0xd6;    # restart
	my $M_RST7 = 0xd7;    # restart

	my $M_SOI = 0xd8;     # start of image
	my $M_EOI = 0xd9;     # end of image
	my $M_SOS = 0xda;     # start of scan
	my $M_DQT = 0xdb;     # define quantization tables
	my $M_DNL = 0xdc;     # define number of lines
	my $M_DRI = 0xdd;     # define restart interval
	my $M_DHP = 0xde;     # define hierarchical progression
	my $M_EXP = 0xdf;     # expand reference image(s)

	my $M_APP0  = 0xe0;   # application marker, used for JFIF
	my $M_APP1  = 0xe1;   # application marker
	my $M_APP2  = 0xe2;   # application marker
	my $M_APP3  = 0xe3;   # application marker
	my $M_APP4  = 0xe4;   # application marker
	my $M_APP5  = 0xe5;   # application marker
	my $M_APP6  = 0xe6;   # application marker
	my $M_APP7  = 0xe7;   # application marker
	my $M_APP8  = 0xe8;   # application marker
	my $M_APP9  = 0xe9;   # application marker
	my $M_APP10 = 0xea;   # application marker
	my $M_APP11 = 0xeb;   # application marker
	my $M_APP12 = 0xec;   # application marker
	my $M_APP13 = 0xed;   # application marker
	my $M_APP14 = 0xee;   # application marker, used by Adobe
	my $M_APP15 = 0xef;   # application marker

	my $M_JPG0  = 0xf0;   # reserved for JPEG extensions
	my $M_JPG13 = 0xfd;   # reserved for JPEG extensions
	my $M_COM   = 0xfe;   # comment

	my $M_TEM = 0x01;     # temporary use

	my $M_ERROR = 0x100;  #dummy marker, internal use only

	my $b;
	my $c;
	my $s;
	my $i;
	my $length;
	my $APP_MAX = 255;
	my $appstring;
	my $SOF_done   = 0;
	my $mask       = -1;
	my $adobeflag  = 0;
	my $components = 0;

	my $fh = FileHandle->new($filename);
	if ( !defined $fh ) { $self->{error} = "PDF::Image::JPEG.pm: $filename: $!"; return 0 }
	binmode $fh;

	#Tommy's special trick for Macintosh JPEGs: simply skip some
	# hundred bytes at the beginning of the file!
  MACTrick: while ( !eof($fh) ) {
		$c = 0;
		while ( !eof($fh) && $c != 0xFF ) {    # skip if not FF
			read $fh, $s, 1;
			$c = unpack( "C", $s );
		}

		if ( eof($fh) ) {
			close($fh);
			$self->{error} = "PDF::Image::JPEG.pm: Not a JPEG file.";
			return 0;
		}

		while ( !eof($fh) && $c == 0xFF ) {    # skip repeated FFs
			read $fh, $s, 1;
			$c = unpack( "C", $s );
		}

		$self->{private}->{datapos} = tell($fh) - 2;

		if ( $c == $M_SOI ) {
			seek( $fh, $self->{private}->{datapos}, 0 );
			last MACTrick;
		}
	}

	my $BOGUS_LENGTH = 768;

	#Heuristics: if we are that far from the start chances are
	# it is a TIFF file with embedded JPEG data which we cannot
	# handle - regard as hopeless...
	if ( eof($fh) || $self->{private}->{datapos} > $BOGUS_LENGTH ) {
		close($fh);
		$self->{error} = "PDF::Image::JPEG.pm: Not a JPEG file.";
		return 0;
	}

	#process JPEG markers */
  JPEGMarkers: while ( !$SOF_done && ( $c = $self->pdf_next_jpeg_marker($fh) ) != $M_EOI ) {

		#print "Marker: " . sprintf("%x", $c) . "\n";
		if (    $c == $M_ERROR
			 || $c == $M_SOF3
			 || $c == $M_SOF5
			 || $c == $M_SOF6
			 || $c == $M_SOF7
			 || $c == $M_SOF9
			 || $c == $M_SOF11
			 || $c == $M_SOF13
			 || $c == $M_SOF14
			 || $c == $M_SOF15 ) {
			close($fh);
			$self->{error} = "PDF::Image::JPEG.pm: JPEG compression " . ord($c) . " not supported in PDF 1.3.", return 0;
		}

		if ( $c == $M_SOF2 || $c == $M_SOF10 ) {
			close($fh);
			$self->{error} = "PDF::Image::JPEG.pm: JPEG compression " . ord($c) . " not supported in PDF 1.2.", return 0;
		}

		if ( $c == $M_SOF0 || $c == $M_SOF1 ) {
			read $fh, $s, 12;
			( $c, $self->{bpc}, $self->{height}, $self->{width}, $components ) = unpack( "nCnnC", $s );

			$SOF_done = 1;
			last JPEGMarkers;
		} elsif ( $c == $M_APP0 ) {
			read $fh, $s, 2;
			$length = unpack( "n", $s ) - 2;
			read $fh, $appstring, $length;

			#Check for JFIF application marker and read density values
			# per JFIF spec version 1.02.

			my $ASPECT_RATIO  = 0;    #JFIF unit byte: aspect ratio only
			my $DOTS_PER_INCH = 1;    #JFIF unit byte: dots per inch
			my $DOTS_PER_CM   = 2;    #JFIF unit byte: dots per cm

			if ( $length >= 12 && $appstring =~ /^JFIF/ ) {
				( $c, $c, $c, $c, $c, $c, $c, $self->{private}->{unit}, $self->{dpi_x}, $self->{dpi_y} ) =
				  unpack( "CCCCCCCCnn", $appstring );
				if ( $self->{dpi_x} <= 0 || $self->{dpi_y} <= 0 ) {
					$self->{dpi_x} = 0;
					$self->{dpi_y} = 0;
				} elsif ( $self->{private}->{unit} == $DOTS_PER_INCH ) {
				} elsif ( $self->{private}->{unit} == $DOTS_PER_CM ) {
					$self->{dpi_x} *= 2.54;
					$self->{dpi_y} *= 2.54;
				} elsif ( $self->{private}->{unit} == $ASPECT_RATIO ) {
					$self->{dpi_x} *= -1;
					$self->{dpi_y} *= -1;
				}
			}
		} elsif ( $c == $M_APP14 ) {    #check for Adobe marker
			read $fh, $s, 2;
			$length = unpack( "n", $s ) - 2;

			read $fh, $appstring, $length;

			#Check for Adobe application marker. It is known (per Adobe's TN5116)
			#to contain the string "Adobe" at the start of the APP14 marker.

			if ( $length >= 10 && $appstring =~ /^Adobe/ ) {
				$adobeflag = 1;
			}
		} elsif (    $c == $M_SOI
				  || $c == $M_EOI
				  || $c == $M_TEM
				  || $c == $M_RST0
				  || $c == $M_RST1
				  || $c == $M_RST2
				  || $c == $M_RST3
				  || $c == $M_RST4
				  || $c == $M_RST5
				  || $c == $M_RST6
				  || $c == $M_RST7 ) {

			#no parameters --> ignore
		} else {

			#skip variable length markers
			read $fh, $s, 2;
			$length = unpack( "n", $s ) - 2;
			read $fh, $s, $length;
		}
	}

	if ( $self->{height} <= 0 || $self->{width} <= 0 || $components <= 0 ) {
		close($fh);
		$self->{error} = "PDF::Image::JPEG.pm: Bad image parameters in JPEG file.";
		return 0;
	}

	if ( $self->{bpc} != 8 ) {
		close($fh);
		$self->{error} = "PDF::Image::JPEG.pm: Bad bpc in JPEG file.";
		return 0;
	}

	if ( $components == 1 ) {
		$self->{colorspace} = "DeviceGray";
	} elsif ( $components == 3 ) {
		$self->{colorspace} = "DeviceRGB";
	} elsif ( $components == 4 ) {
		$self->{colorspace} = "DeviceCMYK";

		#special handling of Photoshop-generated CMYK JPEG files
		if ($adobeflag) {
			$self->{invert} = 1;
		}
	} else {
		close($fh);
		$self->{error} = "PDF::Image::JPEG.pm: Unknown number of color components in JPEG file.", return 0;
	}

	close($fh);

	1;
}

sub ReadData
{
	my $self = shift;
	my $s    = "";
	my $result;
	my $JPEG_BUFSIZE = 1024;
	my $fh           = FileHandle->new($self->{filename});
	if ( !defined $fh ) { $self->{error} = "PDF::Image::JPEG.pm: $self->{filename}: $!"; return 0 }
	binmode $fh;
	seek( $fh, $self->{private}->{datapos}, 0 );

	while ( read( $fh, $s, $JPEG_BUFSIZE ) > 0 ) {
		$result .= $s;
	}

	$self->{imagesize} = length($result);

	close $fh;

	$result;
}

1;

