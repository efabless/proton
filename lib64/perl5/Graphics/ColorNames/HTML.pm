package Graphics::ColorNames::HTML;

=head1 NAME

Graphics::ColorNames::HTML - HTML color names and equivalent RGB values

=head1 SYNOPSIS

  require Graphics::ColorNames::HTML;

  $NameTable = Graphics::ColorNames::HTML->NamesRgbTable();
  $RgbBlack  = $NameTable->{black};

=head1 DESCRIPTION

This module defines color names and their associated RGB values from the
HTML 4.0 Specification.

=head2 Note

In versions prior to 1.1, "fuchsia" was misspelled "fuscia". This
mispelling came from un unidentified HTML specification.  It also
appears to be a common misspelling, so rather than change it, the
proper spelling was added.

=head1 SEE ALSO

L<Graphics::ColorNames>,  HTML 4.0 Specificiation <http://www.w3.org>

L<Graphics::ColorNames::SVG>, which uses color names based on the SVG
specification (which is more recent).

=head1 AUTHOR

Robert Rothenberg <rrwo at cpan.org>

=head1 LICENSE

Copyright (c) 2001-2008 Robert Rothenberg. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

use strict;
use warnings;

our $VERSION = '2.11';
#$VERSION = eval $VERSION;

sub NamesRgbTable() {
  use integer;
  return {
    'black'	         => 0x000000,
    'blue'	         => 0x0000ff,
    'aqua'	         => 0x00ffff,
    'lime'	         => 0x00ff00,
    'fuchsia'	         => 0xff00ff, # "fuscia" is incorrect but common
    'fuscia'             => 0xff00ff, # mis-spelling...
    'red'	         => 0xff0000,
    'yellow'	         => 0xffff00,
    'white'	         => 0xffffff,
    'navy'	         => 0x000080,
    'teal'	         => 0x008080,
    'green'	         => 0x008000,
    'purple'	         => 0x800080,
    'maroon'	         => 0x800000,
    'olive' 	         => 0x808000,
    'gray'	         => 0x808080,
    'silver'	         => 0xc0c0c0,
    };
}

1;

__END__
