#
# PDF::Image::GIF - GIF image support for PDF::Create
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

package PDF::Image::GIF;
use strict;
use warnings;
use FileHandle;

our $VERSION = '1.10';
our $DEBUG   = 0;

sub new
{
	my $self = {};

	$self->{private}               = {};
	$self->{colorspace}            = 0;
	$self->{width}                 = 0;
	$self->{height}                = 0;
	$self->{colorspace}            = "DeviceRGB";
	$self->{colorspacedata}        = "";
	$self->{colorspacesize}        = 0;
	$self->{filename}              = "";
	$self->{error}                 = "";
	$self->{imagesize}             = 0;
	$self->{transparent}           = 0;
	$self->{filter}                = ["LZWDecode"];
	$self->{decodeparms}           = { 'EarlyChange' => 0 };
	$self->{private}->{interlaced} = 0;

	bless($self);
	return $self;
}

sub LZW
{
	my $self   = shift;
	my $data   = shift;
	my $result = "";
	my $prefix = "";
	my $c;
	my %hash;
	my $num;
	my $codesize = 9;

	#init hash-table
	for ( $num = 0 ; $num < 256 ; $num++ ) {
		$hash{ chr($num) } = $num;
	}

	#start with a clear
	$num = 258;
	my $currentvalue = 256;
	my $bits         = 9;

	my $pos = 0;
	while ( $pos < length($data) ) {
		$c = substr( $data, $pos, 1 );

		if ( exists( $hash{ $prefix . $c } ) ) {
			$prefix .= $c;
		} else {

			#save $hash{$prefix}
			$currentvalue <<= $codesize;
			$currentvalue |= $hash{$prefix};
			$bits += $codesize;
			while ( $bits >= 8 ) {
				$result .= chr( ( $currentvalue >> ( $bits - 8 ) ) & 255 );
				$bits -= 8;
				$currentvalue &= ( 1 << $bits ) - 1;
			}

			$hash{ $prefix . $c } = $num;
			$prefix = $c;
			$num++;

			#increase code size?
			if ( $num == 513 || $num == 1025 || $num == 2049 ) {
				$codesize++;
			}

			#hash table overflow?
			if ( $num == 4097 ) {

				#save clear
				$currentvalue <<= $codesize;
				$currentvalue |= 256;
				$bits += $codesize;
				while ( $bits >= 8 ) {
					$result .= chr( ( $currentvalue >> ( $bits - 8 ) ) & 255 );
					$bits -= 8;
					$currentvalue &= ( 1 << $bits ) - 1;
				}

				#reset hash table
				$codesize = 9;
				%hash     = ();
				for ( $num = 0 ; $num < 256 ; $num++ ) {
					$hash{ chr($num) } = $num;
				}
				$num = 258;
			}
		}
		$pos++;
	}

	#save value for prefix
	$currentvalue <<= $codesize;
	$currentvalue |= $hash{$prefix};
	$bits += $codesize;
	while ( $bits >= 8 ) {
		$result .= chr( ( $currentvalue >> ( $bits - 8 ) ) & 255 );
		$bits -= 8;
		$currentvalue &= ( 1 << $bits ) - 1;
	}

	#save eoi
	$currentvalue <<= $codesize;
	$currentvalue |= 257;
	$bits += $codesize;
	while ( $bits >= 8 ) {
		$result .= chr( ( $currentvalue >> ( $bits - 8 ) ) & 255 );
		$bits -= 8;
		$currentvalue &= ( 1 << $bits ) - 1;
	}

	#save remainder in $currentvalue
	if ( $bits > 0 ) {
		$currentvalue = $currentvalue << ( 8 - $bits );
		$result .= chr( $currentvalue & 255 );
	}

	$result;
}

sub UnLZW
{
	my $self   = shift;
	my $data   = shift;
	my $result = "";

	my $bits         = 0;
	my $currentvalue = 0;
	my $codesize     = 9;
	my $pos          = 0;

	my $prefix = "";
	my $suffix;
	my @table;

	#initialize lookup-table
	my $num;
	for ( $num = 0 ; $num < 256 ; $num++ ) {
		$table[$num] = chr($num);
	}
	$table[256] = "";

	$num = 257;

	my $c1;

	#get first word
	while ( $bits < $codesize ) {
		my $d = ord( substr( $data, $pos, 1 ) );
		$currentvalue = ( $currentvalue << 8 ) + $d;
		$bits += 8;
		$pos++;
	}
	my $c2 = $currentvalue >> ( $bits - $codesize );
	$bits -= $codesize;
	my $mask = ( 1 << $bits ) - 1;
	$currentvalue = $currentvalue & $mask;

  DECOMPRESS: while ( $pos < length($data) ) {
		$c1 = $c2;

		#get next word
		while ( $bits < $codesize ) {
			my $d = ord( substr( $data, $pos, 1 ) );
			$currentvalue = ( $currentvalue << 8 ) + $d;
			$bits += 8;
			$pos++;
		}
		$c2 = $currentvalue >> ( $bits - $codesize );
		$bits -= $codesize;
		$mask         = ( 1 << $bits ) - 1;
		$currentvalue = $currentvalue & $mask;

		#clear code?
		if ( $c2 == 256 ) {
			$result .= $table[$c1];
			$#table   = 256;
			$codesize = 9;
			$num      = 257;
			next DECOMPRESS;
		}

		#End Of Image?
		if ( $c2 == 257 ) {
			last DECOMPRESS;
		}

		#get prefix
		if ( $c1 < $num ) {
			$prefix = $table[$c1];
		} else {
			print "Compression Error ($c1>=$num)\n";
		}

		#write prefix
		$result .= $prefix;

		#get suffix
		if ( $c2 < $num ) {
			$suffix = substr( $table[$c2], 0, 1 );
		} elsif ( $c2 == $num ) {
			$suffix = substr( $prefix, 0, 1 );
		} else {
			print "Compression Error ($c2>$num)\n";
		}

		#new table entry is prefix.suffix
		$table[$num] = $prefix . $suffix;

		#next table entry
		$num++;

		#increase code size?
		if ( $num == 512 || $num == 1024 || $num == 2048 ) {
			$codesize++;
		}
	}
	$result .= $table[$c1];

	$result;
}

sub UnInterlace
{
	my $self = shift;
	my $data = shift;
	my $row;
	my @result;
	my $width  = $self->{width};
	my $height = $self->{height};
	my $idx    = 0;

	#Pass 1 - every 8th row, starting with row 0
	$row = 0;
	while ( $row < $height ) {
		$result[$row] = substr( $data, $idx * $width, $width );
		$row += 8;
		$idx++;
	}

	#Pass 2 - every 8th row, starting with row 4
	$row = 4;
	while ( $row < $height ) {
		$result[$row] = substr( $data, $idx * $width, $width );
		$row += 8;
		$idx++;
	}

	#Pass 3 - every 4th row, starting with row 2
	$row = 2;
	while ( $row < $height ) {
		$result[$row] = substr( $data, $idx * $width, $width );
		$row += 4;
		$idx++;
	}

	#Pass 4 - every 2th row, starting with row 1
	$row = 1;
	while ( $row < $height ) {
		$result[$row] = substr( $data, $idx * $width, $width );
		$row += 2;
		$idx++;
	}

	join( '', @result );
}

sub GetDataBlock
{
	my $self = shift;
	my $fh   = shift;
	my $s;
	my $count;
	my $buf;
	read $fh, $s, 1;
	$count = unpack( "C", $s );

	if ($count) {
		read $fh, $buf, $count;
	}

	( $count, $buf );
}

sub ReadColorMap
{
	my $self = shift;
	my $fh   = shift;
	read $fh, $self->{'colorspacedata'}, 3 * $self->{'colormapsize'};
	1;
}

sub DoExtension
{
	my $self  = shift;
	my $label = shift;
	my $fh    = shift;
	my $res;
	my $buf;
	my $c;
	my $c2;
	my $c3;

	if ( $label eq "\001" ) {    #Plain Text Extension
	} elsif ( ord($label) == 0xFF ) {    #Application Extension
	} elsif ( ord($label) == 0xFE ) {    #Comment Extension
	} elsif ( ord($label) == 0xF9 ) {    #Grapgic Control Extension
		( $res, $buf ) = $self->GetDataBlock($fh);    #(p, image, (unsigned char*) buf);
		( $c, $c2, $c2, $c3 ) = unpack( "CCCC", $buf );
		if ( $c && 0x1 != 0 ) {
			$self->{transparent} = 1;
			$self->{mask}        = $c3;
		}
	}

  BLOCK: while (1) {
		( $res, $buf ) = $self->GetDataBlock($fh);
		if ( $res == 0 ) {
			last BLOCK;
		}
	}

	1;
}

sub Open
{
	my $self     = shift;
	my $filename = shift;

	my $PDF_STRING_GIF = "\107\111\106";
	my $PDF_STRING_87a = "\070\067\141";
	my $PDF_STRING_89a = "\070\071\141";
	my $LOCALCOLORMAP  = 0x80;
	my $INTERLACE      = 0x40;

	my $s;
	my $c;
	my $ar;
	my $flags;

	$self->{filename} = $filename;
	my $fh = FileHandle->new("$filename");
	if ( !defined $fh ) { $self->{error} = "PDF::Image::GIF.pm: $filename: $!"; return 0 }
	binmode $fh;
	read $fh, $s, 3;
	if ( $s ne $PDF_STRING_GIF ) {
		close $fh;
		$self->{error} = "PDF::Image::GIF.pm: Not a gif file.";
		return 0;
	}

	read $fh, $s, 3;
	if ( $s ne $PDF_STRING_87a && $s ne $PDF_STRING_89a ) {
		close $fh;
		$self->{error} = "PDF::Image::GIF.pm: GIF version $s not supported.";
		return 0;
	}

	read $fh, $s, 7;
	( $self->{width}, $self->{height}, $flags, $self->{private}->{background}, $ar ) = unpack( "vvCCC", $s );

	$self->{colormapsize} = 2 << ( $flags & 0x07 );
	$self->{colorspacesize} = 3 * $self->{colormapsize};
	if ( $flags & $LOCALCOLORMAP ) {
		if ( !$self->ReadColorMap($fh) ) {
			close $fh;
			$self->{error} = "PDF::Image::GIF.pm: Cant read color map.";
			return 0;
		}
	}

	if ( $ar != 0 ) {
		$self->{private}->{dpi_x} = -( $ar + 15.0 ) / 64.0;
		$self->{private}->{dpi_y} = -1.0;
	}

	my $imageCount = 0;
  IMAGES: while (1) {
		read $fh, $c, 1;
		if ( $c eq ";" ) {    #GIF file terminator
			close $fh;
			$self->{error} = "PDF::Image::GIF.pm: Cant find image in gif file.";
			return 0;
		}

		if ( $c eq "!" ) {    #Extension
			read $fh, $c, 1;
			$self->DoExtension( $c, $fh );
			next;
		}

		if ( $c ne "," ) {    #must be comma
			next;             #ignore
		}

		$imageCount++;

		read $fh, $s, 9;
		my $x;
		( $x, $c, $self->{width}, $self->{height}, $flags ) = unpack( "vvvvC", $s );

		if ( $flags && $INTERLACE ) {
			$self->{private}->{interlaced} = 1;
		}

		if ( $flags & $LOCALCOLORMAP ) {
			if ( !$self->ReadColorMap($fh) ) {
				close $fh;
				$self->{error} = "PDF::Image::GIF.pm: Cant read color map.";
				return 0;
			}
		}

		read $fh, $s, 1;    #read "LZW initial code size"
		$self->{bpc} = unpack( "C", $s );
		if ( $self->{bpc} != 8 ) {
			close $fh;
			$self->{error} = "PDF::Image::GIF.pm: LZW minimum code size is " . $self->{bpc} . ", must be 8 to be supported.";
			return 0;
		}

		if ( $imageCount == 1 ) {
			last IMAGES;
		}

	}

	$self->{private}->{datapos} = tell($fh);
	close $fh;

	1;
}

sub ReadData
{
	my $self = shift;

	# init the LZW transformation vars
	my $c_size = 9;      # initial code size
	my $t_size = 257;    # initial "table" size
	my $i_buff = 0;      # input buffer
	my $i_bits = 0;      # input buffer empty
	my $o_bits = 0;      # output buffer empty
	my $o_buff = 0;
	my $c_mask;
	my $bytes_available = 0;
	my $n_bytes;
	my $s;
	my $c;
	my $flag13;
	my $code;
	my $w_bits;

	my $result = "";

	my $fh = FileHandle->new($self->{filename});
	if ( !defined $fh ) { $self->{error} = "PDF::Image::GIF.pm: $self->{filename}: $!"; return 0 }
	binmode $fh;
	seek( $fh, $self->{private}->{datapos}, 0 );
	my $pos = 0;
	my $data;
	read $fh, $data, ( -s $self->{filename} );

	use integer;

	$self->{imagesize} = 0;
  BLOCKS: while (1) {
		$s = substr( $data, $pos, 1 );
		$pos++;
		$n_bytes = unpack( "C", $s );
		if ( !$n_bytes ) {
			last BLOCKS;
		}

		$c_mask = ( 1 << $c_size ) - 1;
		$flag13 = 0;

	  BLOCK: while (1) {
			$w_bits = $c_size;    # number of bits to write
			$code   = 0;

			#get at least c_size bits into i_buff
			while ( $i_bits < $c_size ) {
				if ( $n_bytes == 0 ) {
					last BLOCK;
				}
				$n_bytes--;
				$s = substr( $data, $pos, 1 );
				$pos++;
				$c = unpack( "C", $s );
				$i_buff |= $c << $i_bits;    #EOF will be caught later
				$i_bits += 8;
			}

			$code = $i_buff & $c_mask;

			$i_bits -= $c_size;
			$i_buff >>= $c_size;

			if ( $flag13 && $code != 256 && $code != 257 ) {
				$self->{error} = "PDF::Image::GIF.pm: LZW code size overflow.";
				return 0;
			}

			if ( $o_bits > 0 ) {
				$o_buff |= $code >> ( $c_size - 8 + $o_bits );
				$w_bits -= 8 - $o_bits;
				$result .= chr( $o_buff & 255 );
			}

			if ( $w_bits >= 8 ) {
				$w_bits -= 8;
				$result .= chr( ( $code >> $w_bits ) & 255 );
			}
			$o_bits = $w_bits;
			if ( $o_bits > 0 ) {
				$o_buff = $code << ( 8 - $o_bits );
			}

			$t_size++;
			if ( $code == 256 ) {    #clear code
				$c_size = 9;
				$c_mask = ( 1 << $c_size ) - 1;
				$t_size = 257;
				$flag13 = 0;
			}

			if ( $code == 257 ) {    #end code
				last BLOCK;
			}

			if ( $t_size == ( 1 << $c_size ) ) {
				if ( ++$c_size > 12 ) {
					$c_size--;
					$flag13 = 1;
				} else {
					$c_mask = ( 1 << $c_size ) - 1;
				}
			}
		}    # while () for block
	}    # while () for all blocks

	#interlaced?
	if ( $self->{private}->{interlaced} ) {

		#when interlaced first uncompress image
		$result = $self->UnLZW($result);

		#remove interlacing
		$result = $self->UnInterlace($result);

		#compress image again
		$result = $self->LZW($result);
	}

	$self->{imagesize} = length($result);
	$result;
}

1;

