package Graphics::ColorNames;
use 5.006;

use base "Exporter";

use strict;
use warnings;

# use AutoLoader;
use Carp;
use Module::Load 0.10;
use Module::Loaded;

our $VERSION   = '2.11';
# $VERSION = eval $VERSION;

our %EXPORT_TAGS = (
 'all'     => [ qw( hex2tuple tuple2hex all_schemes ) ],
 'utility' => [ qw( hex2tuple tuple2hex ) ],
);
our @EXPORT_OK    = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT       = ( );

# We store Schemes in a hash as a quick-and-dirty way to filter
# duplicates (which sometimes occur when directories are repeated in
# @INC or via symlinks).  The order does not matter.

# If we use AutoLoader, these should be use vars() ?

my %FoundSchemes = ( );

# Since 2.10_02, we've added autoloading color names to the object-
# oriented interface.

our $AUTOLOAD;

sub AUTOLOAD {
  $AUTOLOAD =~ /^(.*:)*([\w\_]+)$/;
  my $name  = $2;
  my $hex   = (my $self = $_[0])->FETCH($name);
  if (defined $hex) {
    return $hex;
  }
  else {
    croak "No method or color named $name";
    # $AutoLoader::AUTOLOAD = $AUTOLOAD;
    # goto &AutoLoader::AUTOLOAD;
  }
}


sub _load {
  while(my $module = shift) {
    unless (is_loaded($module)) {
      load($module);
      mark_as_loaded($module) unless (is_loaded($module));
    }
  }
}

# TODO - see if using Tie::Hash::Layered gives an improvement

sub _load_scheme_from_module {
  my $self = shift;
  my $base = __PACKAGE__;

  my $module = join('::', $base, (my $scheme = shift));
  eval { _load($module); };
  if ($@) {
    eval { _load($module = $scheme); };
    if ($@) {
      croak "Cannot load color naming scheme \`$module\'";
    }
  }
    
  {
    no strict 'refs';
    if ($module =~ $base) {
	$self->load_scheme($module->NamesRgbTable);
    }
    elsif ($module =~ /Color::Library::Dictionary/) {
	$self->load_scheme($module->_load_color_list);
    }
    else {
	croak "Unknown scheme type: $module";
    }
  }
}

sub TIEHASH {
  my $class = shift || __PACKAGE__;
  my $self  = {
   _schemes  => [ ],
   _iterator => 0,
  };

  bless $self, $class;

  if (@_) {
    foreach my $scheme (@_) {
      if (ref $scheme) {
	$self->load_scheme( $scheme );
      }
      elsif (-r $scheme) {
	$self->_load_scheme_from_file( $scheme );
      }
      else {
	$self->_load_scheme_from_module( $scheme );
      }
    }
  } else {
    $self->_load_scheme_from_module('X');
  }

  return $self;
}

sub FETCH {
  my $self   = shift;
  my $key    = lc(shift||"");

  # If we're passing it an RGB value, return that value

  if ($key =~ m/^\x23?([\da-f]{6})$/) {
    return $1;
  } else {
      
      $key =~ s/[^a-z\d\%]//g; # ignore non-word characters

      my $val = undef;
      my $i   = 0;
      while ((!defined $val) && ($i < @{$self->{_schemes}})) {
	  $val = $self->{_schemes}->[$i++]->{$key};
      }

      if (defined $val) {
 	  return sprintf('%06x', $val ), ;
      } else {
 	  return;
      }
  }
}

sub EXISTS {
  my ($self, $key) = @_;
  defined ($self->FETCH($key));
}

sub FIRSTKEY {
  (my $self = shift)->{_iterator} = 0;
  each %{$self->{_schemes}->[$self->{_iterator}]};
}

sub NEXTKEY {
  my $self = shift;
  my ($key, $val)  = each %{$self->{_schemes}->[$self->{_iterator}]};
  unless (defined $key) {
      ($key, $val)  = each %{$self->{_schemes}->[++$self->{_iterator}]};
  }
  return $key;
}

sub load_scheme {
  my $self   = shift;
  my $scheme = shift;

  if (ref($scheme) eq "HASH") {
      push @{$self->{_schemes}}, $scheme;
  }
  elsif (ref($scheme) eq "CODE") {
      _load("Tie::Sub");
      push @{$self->{_schemes}}, { };
      tie %{$self->{_schemes}->[-1]}, 'Tie::Sub', $scheme;
  }
  elsif (ref($scheme) eq "ARRAY") {
      # assumes these are Color::Library::Dictionary 0.02 files 
      my $s = { };
      foreach my $rec (@$scheme) {
	  my $key  =  $rec->[0];
	  my $name =  $rec->[1];
	  my $code =  $rec->[5];
	  $name    =~ s/[\W\_]//g; # ignore non-word characters
	  $s->{$name} = $code unless (exists $s->{$name});
	  if ($key =~ /^(.+\:.+)\.(\d+)$/) {
	      $s->{"$name$2"} = $code;
	  }
      }
      push @{$self->{_schemes}}, $s;
  }
  else {
    # TODO - use Exception
    undef $!;
    eval {
      if ((ref($scheme) eq 'GLOB')
         || ref($scheme) eq "IO::File"   || $scheme->isa('IO::File')
         || ref($scheme) eq "FileHandle" || $scheme->isa('FileHandle')) {
	$self->_load_scheme_from_file($scheme);
      }
    };
    if ($@) {
      croak "Error $@ on scheme type ", ref($scheme);
    }
    elsif ($!) {
      croak "$!";
    }
    else {
	# everything is ok?
    }
  }
}

sub _find_schemes {

    my $path = shift;

    # BUG: deep-named schemes such as Graphics::ColorNames::Foo::Bar
    # are not supported.

    if (-d $path) {
      my $dh = DirHandle->new( $path )
	|| croak "Unable to access directory $path";
      while (defined(my $fn = $dh->read)) {
	if ((-r File::Spec->catdir($path, $fn)) && ($fn =~ /(.+)\.pm$/)) {
	  $FoundSchemes{$1}++;
	}
      }
    }
  }

sub _readonly_error {
  croak "Cannot modify a read-only value";
}

sub DESTROY {
  my $self = shift;
  delete $self->{_schemes};
  delete $self->{_iterator};
}

sub UNTIE {             # stub to avoid AUTOLOAD 
}

BEGIN {
  no strict 'refs';
  *STORE  = \ &_readonly_error;
  *DELETE = \ &_readonly_error;
  *CLEAR  = \ &_readonly_error; # causes problems with 'undef'

  *new    = \ &TIEHASH;
}


1;

## __END__

# Convert 6-digit hexidecimal code (used for HTML etc.) to an array of
# RGB values

sub hex2tuple {
  my $rgb = CORE::hex( shift );
  my ($red, $green, $blue);
  $blue  = ($rgb & 0x0000ff);
  $green = ($rgb & 0x00ff00) >> 8;
  $red   = ($rgb & 0xff0000) >> 16;
  return ($red, $green, $blue);
}


# Convert list of RGB values to 6-digit hexidecimal code (used for HTML, etc.)

sub tuple2hex {
  my ($red, $green, $blue) = @_;
  my $rgb = sprintf "%.2x%.2x%.2x", $red, $green, $blue;
  return $rgb;
}

sub all_schemes {
    unless (%FoundSchemes) {
	
      _load("DirHandle", "File::Spec");

      foreach my $dir (@INC) {
	_find_schemes(
	  File::Spec->catdir($dir, split(/::/, __PACKAGE__)));
      }
    }
    return (keys %FoundSchemes);
  }

sub _load_scheme_from_file {
  my $self = shift;
  my $file = shift;

  unless (ref $file) {
    unless (-r $file) {
      croak "Cannot load scheme from file: \'$file\'";
    }
    _load("IO::File");
  }

  my $fh = ref($file) ? $file : (IO::File->new);
  unless (ref $file) {
    open($fh, $file)
      || croak "Cannot open file: \'$file\'";
  }

  my $scheme = { };

  while (my $line = <$fh>) {
      chomp($line);
      $line =~ s/[\!\#].*$//;
      if ($line ne "") {
	my $name  = lc(substr($line, 12));
	$name     =~ s/[\W]//g; # remove anything that isn't a letter or number

	croak "Missing color name",
	  unless ($name ne "");

	# TODO? Should we add an option to warn if overlapping names
	# are defined? This seems to be too common to be useful.

	# unless (exists $scheme->{$name}) {

 	  $scheme->{$name} = 0;
	  foreach (0, 4, 8) {
	      $scheme->{$name} <<= 8;
	      $scheme->{$name}  |= (eval substr($line,  $_, 3));
	  }

	# }
      }
  }
  $self->load_scheme( $scheme );

  unless (ref $file) {
    close $fh;
  }
}


sub hex {
    my $self = shift;
    my $rgb  = $self->FETCH(my $name = shift);
    my $pre  = shift || "";
    return ($pre.$rgb);
}

sub rgb {
    my $self = shift;
    my @rgb  = hex2tuple($self->FETCH(my $name = shift));
    my $sep  = shift || ','; # (*)
    return wantarray ? @rgb : join($sep,@rgb);
# (*) A possible bug, if one uses "0" as a separator. But this is not likely
}

__END__

=head1 NAME

Graphics::ColorNames - defines RGB values for common color names

=begin readme

=head1 REQUIREMENTS

C<Graphics::ColorNames> should work on Perl 5.6.0.  It requires the
following non-core (depending on your Perl version) modules:

  Module::Load
  Module::Loaded

The following modules are not required for using most features but
are recommended:

  Color::Library
  Tie::Sub

L<Installation|/INSTALLATION> requires the following testing modules:

  Test::Exception
  Test::More

If the C<DEVEL_TESTS> environment variable is set, the tests will also
use the following modules for running developer tests, if they are
installed:

  Test::Pod
  Test::Pod::Coverage
  Test::Portability::Files

The developer tests are for quality-control purposes.

=head1 INSTALLATION

Installation can be done using the traditional Makefile.PL or the newer
Build.PL methods.

Using Makefile.PL:

  perl Makefile.PL
  make test
  make install

(On Windows platforms you should use C<nmake> instead.)

Using Build.PL (if you have L<Module::Build> installed):

  perl Build.PL
  perl Build test
  perl Build install

=end readme

=head1 SYNOPSIS

  use Graphics::ColorNames 2.10;

  $po = new Graphics::ColorNames(qw( X ));

  $rgb = $po->hex('green');          # returns '00ff00'
  $rgb = $po->hex('green', '0x');    # returns '0x00ff00'
  $rgb = $po->hex('green', '#');     # returns '#00ff00'

  $rgb = $po->rgb('green');          # returns '0,255,0'
  @rgb = $po->rgb('green');          # returns (0, 255, 0)  

  $rgb = $po->green;                 # same as $po->hex('green');

  tie %ph, 'Graphics::ColorNames', (qw( X ));

  $rgb = $ph{green};                 # same as $po->hex('green');

=head1 DESCRIPTION

This module provides a common interface for obtaining the RGB values
of colors by standard names.  The intention is to (1) provide a common
module that authors can use with other modules to specify colors by
name; and (2) free module authors from having to "re-invent the wheel"
whenever they decide to give the users the option of specifying a
color by name rather than RGB value.

=begin readme

See the module POD for complete documentation.

=end readme

=for readme stop

For example,

  use Graphics::ColorNames 2.10;

  use GD;

  $pal = new Graphics::ColorNames;

  $img = new GD::Image(100, 100);

  $bgColor = $img->colorAllocate( $pal->rgb('CadetBlue3') );

Although this is a little "bureaucratic", the meaning of this code is clear:
C<$bgColor> (or background color) is 'CadetBlue3' (which is easier to for one
to understand than C<0x7A, 0xC5, 0xCD>). The variable is named for its
function, not form (ie, C<$CadetBlue3>) so that if the author later changes
the background color, the variable name need not be changed.

You can also define L</Custom Color Schemes> for specialised palettes
for websites or institutional publications:

  $color = $pal->hex('MenuBackground');

As an added feature, a hexidecimal RGB value in the form of #RRGGBB,
0xRRGGBB or RRGGBB will return itself:

  $color = $pal->hex('#123abc');         # returns '123abc'

=head2 Tied Interface

The standard interface (prior to version 0.40) is through a tied hash:

  tie %pal, 'Graphics::ColorNames', @schemes;

where C<%pal> is the tied hash and C<@schemes> is a list of
L<color schemes|/Color Schemes>.

A valid color scheme may be the name of a color scheme (such as C<X>
or a full module name such as C<Graphics::ColorNames::X>), a reference
to a color scheme hash or subroutine, or to the path or open
filehandle for a F<rgb.txt> file.

As of version 2.1002, one can also use L<Color::Library> dictionaries:

  tie %pal, 'Graphics::ColorNames', qw(Color::Library::Dictionary::HTML);

This is an experimental feature which may change in later versions (see
L</SEE ALSO> for a discussion of the differences between modules).

Multiple schemes can be used:

  tie %pal, 'Graphics::ColorNames', qw(HTML Netscape);

In this case, if the name is not a valid HTML color, the Netscape name
will be used.

One can load all available schemes in the Graphics::ColorNames namespace
(as of version 2.0):

  use Graphics::ColorNames 2.0, 'all_schemes';
  tie %NameTable, 'Graphics::ColorNames', all_schemes();

When multiple color schemes define the same name, then the earlier one
listed has priority (however, hash-based color schemes always have
priority over code-based color schemes).

When no color scheme is specified, the X-Windows scheme is assumed.

Color names are case insensitive, and spaces or punctuation
are ignored.  So "Alice Blue" returns the same
value as "aliceblue", "ALICE-BLUE" and "a*lICEbl-ue".  (If you are
using color names based on user input, you may want to add additional
validation of the color names.)

The value returned is in the six-digit hexidecimal format used in HTML and
CSS (without the initial '#'). To convert it to separate red, green, and
blue values (between 0 and 255), use the L</hex2tuple> function.

=head2 Object-Oriented Interface

If you prefer, an object-oriented interface is available:

  use Graphics::ColorNames 0.40;

  $obj = Graphics::ColorNames->new('/etc/rgb.txt');

  $hex = $obj->hex('skyblue'); # returns "87ceeb"
  @rgb = $obj->rgb('skyblue'); # returns (0x87, 0xce, 0xeb)

The interface is similar to the L<Color::Rgb> module:

=over

=item new

  $obj = Graphics::ColorNames->new( @SCHEMES );

Creates the object, using the default L<color schemes|/Color Schemes>.
If none are specified, it uses the C<X> scheme.

=item load_scheme

  $obj->load_scheme( $scheme );

Loads a scheme dynamically.  The scheme may be any hash or code reference.

=item hex

  $hex = $obj->hex($name, $prefix);

Returns a 6-digit hexidecimal RGB code for the color.  If an optional
prefix is specified, it will prefix the code with that string.  For
example,

  $hex = $obj->hex('blue', '#'); # returns "#0000ff"

=item rgb

  @rgb = $obj->rgb($name);

  $rgb = $obj->rgb($name, $separator);

If called in a list context, returns a triplet.

If called in a scalar context, returns a string separated by an
optional separator (which defauls to a comma).  For example,

  @rgb = $obj->rgb('blue');      # returns (0, 0, 255)

  $rgb = $obj->rgb('blue', ','); # returns "0,0,255"

=back

Since version 2.10_02, the interface will assume method names
are color names and return the hex value,

  $obj->black eq $obj->hex("black")

Method names are case-insensitive, and underscores are ignored.

=head2 Utility Functions

These functions are not exported by default, so much be specified to
be used:

  use Graphics::ColorNames qw( all_schemes hex2tuple tuple2hex );

=over

=item all_schemes

  @schemes = all_schemes();

Returns a list of all available color schemes installed on the machine
in the F<Graphics::ColorNames> namespace.

The order has no significance.

=item hex2tuple

  ($red, $green, $blue) = hex2tuple( $colors{'AliceBlue'});

=item tuple2hex

  $rgb = tuple2hex( $red, $green, $blue );

=back

=head2 Color Schemes

The following schemes are available by default:

=over

=item X

About 750 color names used in X-Windows (although about 90+ of them are
duplicate names with spaces).

=item HTML

16 common color names defined in the HTML 4.0 specification. These
names are also used with older CSS and SVG specifications. (You may
want to see L<Graphics::ColorNames::SVG> for a complete list.)

=item Netscape

100 color names names associated Netscape 1.1 (I cannot determine whether
they were once usable in Netscape or were arbitrary names for RGB values--
many of these names are not recognized by later versions of Netscape).

This scheme may be deprecated in future versions, but available as a
separate module.

=item Windows

16 commom color names used with Microsoft Windows and related
products.  These are actually the same colors as the L</HTML> scheme,
although with different names.

=back

Rather than a color scheme, the path or open filehandle for a
F<rgb.txt> file may be specified.

Additional color schemes may be available on CPAN.

=head2 Custom Color Schemes

You can add naming scheme files by creating a Perl module is the name
C<Graphics::ColorNames::SCHEMENAME> which has a subroutine named
C<NamesRgbTable> that returns a hash of color names and RGB values.
(Schemes with a different base namespace will require the fill namespace
to be given.)

The color names must be in all lower-case, and the RGB values must be
24-bit numbers containing the red, green, and blue values in most- significant
to least- significant byte order.

An example naming schema is below:

  package Graphics::ColorNames::Metallic;

  sub NamesRgbTable() {
    use integer;
    return {
      copper => 0xb87333,
      gold   => 0xcd7f32,
      silver => 0xe6e8fa,
    };
  }

You would use the above schema as follows:

  tie %colors, 'Graphics::ColorNames', 'Metallic';

The behavior of specifying multiple keys with the same name is undefined
as to which one takes precedence.

As of version 2.10, case, spaces and punctuation are ignored in color
names. So a name like "Willy's Favorite Shade-of-Blue" is treated the
same as "willysfavoroteshadeofblue".  (If your scheme does not include
duplicate entrieswith spaces and punctuation, then the minimum
version of L<Graphics::ColorNames> should be 2.10 in your requirements.)

An example of an additional module is the L<Graphics::ColorNames::Mozilla>
module by Steve Pomeroy.

Since version 1.03, C<NamesRgbTable> may also return a code reference:

  package Graphics::ColorNames::Orange;

  sub NamesRgbTable() {
    return sub {
      my $name = shift;
      return 0xffa500;        
    };
  }

See L<Graphics::ColorNames::GrayScale> for an example.

=head2 Graphics::ColourNames

The alias "Graphics::ColourNames" (British spelling) is no longer available
as of version 2.01.

It seems absurd to maintain it when all the modules does is provide an
alternative spelling for the module I<name> without doing anything about
the component colors of each scheme, and when most other modules
(and non-Perl software) does not bother with such things.

=head1 SEE ALSO

L<Color::Library> provides an extensive library of color schemes. A notable
difference is that it supports more complex schemes which contain additional
information about individual colors and map multiple colors to a single name.

L<Color::Rgb> has a similar function to this module, but parses an
F<rgb.txt> file.

L<Graphics::ColorObject> can convert between RGB and other color space
types.

L<Acme::AutoColor> provides subroutines corresponding to color names.

=begin readme

=head1 REVISION HISTORY

Changes since the last release:

=for readme include file=Changes start=^2.11 stop=^2.04 type=text

More details can be found in the F<Changes> file.

=end readme

=for readme continue

=head1 AUTHOR

Robert Rothenberg <rrwo at cpan.org>

=for readme stop

=head2 Acknowledgements

Alan D. Salewski <alans at cji.com> for feedback and the addition of
C<tuple2hex>.

Steve Pomeroy <xavier at cpan.org>, "chemboy" <chemboy at perlmonk.org>
and "magnus" <magnus at mbox604.swipnet.se> who pointed out issues
with various color schemes.

=head2 Suggestions and Bug Reporting

Feedback is always welcome.  Please use the CPAN Request Tracker at
L<http://rt.cpan.org> to submit bug reports.

There is a Sourceforge project for this package at
L<http://sourceforge.net/projects/colornames/>.

If you create additional color schemes, please make them available
separately in CPAN rather than submit them to me for inclusion into
this module.

=for readme continue

=head1 LICENSE

Copyright (c) 2001-2008 Robert Rothenberg. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
