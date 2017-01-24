#
# PDF::Create::Outline - PDF outline support for PDF::Create
#
# Author: Fabien Tassin
#
# Copyright 1999-2001 Fabien Tassin
# Copyright 2007-     Markus Baertschi <markus@markus.org>
# Copyright 2010      Gary Lieberman
#
# Please see the CHANGES and Changes file for the detailed change log
#
# Please do not use any of the methods here directly. You will be
# punished with your application no longer working after an upgrade !
# 

package PDF::Create::Outline;
use strict;
use warnings;

use Carp;
use FileHandle;
use Data::Dumper;
use Scalar::Util qw(weaken);

our $VERSION = '1.10';
our $DEBUG   = 0;

sub new
{
	my $this  = shift;
	my $class = ref($this) || $this;
	my $self  = {};
	bless $self, $class;
	$self->{'Kids'} = [];
	$self;
}

sub add
{
	my $self    = shift;
	my $outline = PDF::Create::Outline->new();
	$outline->{'id'}     = shift;
	$outline->{'name'}   = shift;
	$outline->{'Parent'} = $self;
	weaken $outline->{Parent};
	$outline->{'pdf'}    = $self->{'pdf'};
	weaken $outline->{pdf};
	my %params = @_;
	$outline->{'Title'}  = $params{'Title'}  if defined $params{'Title'};
	$outline->{'Action'} = $params{'Action'} if defined $params{'Action'};
	$outline->{'Status'} = defined $params{'Status'}
	  && ( $params{'Status'} eq 'closed' || !$params{'Status'} ) ? 0 : 1;
	$outline->{'Dest'} = $params{'Destination'}
	  if defined $params{'Destination'};
	push @{ $self->{'Kids'} }, $outline;
	$outline;
}

sub count
{
	my $self = shift;

	my $c = scalar @{ $self->{'Kids'} };
	return $c unless $c;
	for my $outline ( @{ $self->{'Kids'} } ) {
		my $v = $outline->count;
		$c += $v if $outline->{'Status'};
	}
	$c *= -1 unless $self->{'Status'};
	$c;
}

sub kids
{
	my $self = shift;

	my $t = [];
	map { push @$t, $_->{'id'} } @{ $self->{'Kids'} };
	$t;
}

sub list
{
	my $self = shift;
	my @l;
	for my $e ( @{ $self->{'Kids'} } ) {
		my @t = $e->list;
		push @l, $e;
		push @l, @t if scalar @t;
	}
	@l;
}

sub new_outline
{
	my $self = shift;

	$self->{'pdf'}->new_outline( 'Parent' => $self, @_ );
}

1;
