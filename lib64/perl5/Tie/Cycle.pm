package Tie::Cycle;
use strict;

our $VERSION = '1.21';

use Carp qw(carp);

use constant CURSOR_COL => 0;
use constant COUNT_COL  => 1;
use constant ITEM_COL   => 2;

sub TIESCALAR {
	my( $class, $list_ref ) = @_;
	my $self = bless [], $class;

	unless( $self->STORE( $list_ref ) ) {
		carp "The argument to Tie::Cycle must be an array reference";
		return;
		}

	return $self;
	}

sub FETCH {
	my( $self ) = @_;

	my $index = $self->[CURSOR_COL]++;
	$self->[CURSOR_COL] %= $self->_count;

	return $self->_item( $index );
	}

sub STORE {
	my( $self, $list_ref ) = @_;
	return unless ref $list_ref eq ref [];
	my @shallow_copy = map { $_ } @$list_ref;

	$self->[CURSOR_COL] = 0;
	$self->[COUNT_COL]  = scalar @shallow_copy;
	$self->[ITEM_COL]   = \@shallow_copy;
	}

sub reset { $_[0]->[CURSOR_COL] = 0 }

sub previous {
	my( $self ) = @_;

	my $index = $self->_cursor - 1;
	$self->[CURSOR_COL] %= $self->_count;

	return $self->_item( $index );
	}

sub next {
	my( $self ) = @_;

	my $index = $self->_cursor + 1;
	$self->[CURSOR_COL] %= $self->_count;

	return $self->_item( $index );
	}

sub _cursor  { $_[0]->[CURSOR_COL] }
sub _count   { $_[0]->[COUNT_COL] }
sub _item    {
	my( $self, $index ) = @_;
	$index = defined $index ? $index : $self->_cursor;
	$self->[ITEM_COL][ $index ] 
	}

"Tie::Cycle";

__END__

=encoding utf8

=head1 NAME

Tie::Cycle - Cycle through a list of values via a scalar.

=head1 SYNOPSIS

	use v5.10.1;
	use Tie::Cycle;

	tie my $cycle, 'Tie::Cycle', [ qw( FFFFFF 000000 FFFF00 ) ];

	say $cycle; # FFFFFF
	say $cycle; # 000000
	say $cycle; # FFFF00
	say $cycle; # FFFFFF  back to the beginning

	(tied $cycle)->reset;  # back to the beginning

=head1 DESCRIPTION

You use C<Tie::Cycle> to go through a list over and over again.
Once you get to the end of the list, you go back to the beginning.
You don't have to worry about any of this since the magic of
tie does that for you.

The tie takes an array reference as its third argument. The tie
should succeed unless the argument is not an array reference.
Previous versions required you to use an array that had more
than one element (what's the pointing of looping otherwise?),
but I've removed that restriction since the number of elements
you want to use may change depending on the situation.

During the tie, this module makes a shallow copy of the array
reference. If the array reference contains references, and those
references are changed after the tie, the elements of the cycle
will change as well. See the included F<test.pl> script for an
example of this effect.

=head1 OBJECT METHODS

You can call methods on the underlying object (which you access
with C<tied()> ).

=over 4

=item reset

Roll the iterator back to the starting position. The next access
will give the first element in the list.

=item previous

Give the previous element. This does not affect the current position.

=item next

Give the next element. This does not affect the current position.
You can peek at the next element if you like.

=back

=head1 SOURCE AVAILABILITY

This module is on Github:

	https://github.com/briandfoy/tie-cycle

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2000-2013, brian d foy, All rights reserved

This software is available under the same terms as perl.

=cut
