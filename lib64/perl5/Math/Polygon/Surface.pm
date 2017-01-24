# Copyrights 2004,2006-2014 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
use strict;
use warnings;

package Math::Polygon::Surface;
use vars '$VERSION';
$VERSION = '1.03';

use Math::Polygon;


sub new(@)
{   my $thing = shift;
    my $class = ref $thing || $thing;

    my @poly;
    my %options;

    while(@_)
    {   if(!ref $_[0]) { my $k = shift; $options{$k} = shift }
        elsif(ref $_[0] eq 'ARRAY')        {push @poly, shift}
        elsif($_[0]->isa('Math::Polygon')) {push @poly, shift}
        else { die "Illegal argument $_[0]" }
    }

    $options{_poly} = \@poly if @poly;
    (bless {}, $class)->init(\%options);
}

sub init($$)
{   my ($self, $args)  = @_;
    my ($outer, @inner);

    if($args->{_poly})
    {   ($outer, @inner) = @{$args->{_poly}};
    }
    else
    {   $outer = $args->{outer}
            or die "ERROR: surface requires outer polygon\n";

        @inner = @{$args->{inner}} if defined $args->{inner};
    }

    foreach ($outer, @inner)
    {  next unless ref $_ eq 'ARRAY';
       $_ = Math::Polygon->new(points => $_);
    }

    $self->{MS_outer} = $outer;
    $self->{MS_inner} = \@inner;
    $self;
}


sub outer() { shift->{MS_outer} }


sub inner() { @{shift->{MS_inner}} }


sub bbox() { shift->outer->bbox }


sub area()
{   my $self = shift;
    my $area = $self->outer->area;
    $area   -= $_->area for $self->inner;
    $area;
}


sub perimeter()
{   my $self = shift;
    my $per  = $self->outer->perimeter;
    $per    += $_->perimeter for $self->inner;
    $per;
}


sub lineClip($$$$)
{   my ($self, @bbox) = @_;
    map { $_->lineClip(@bbox) } $self->outer, $self->inner;
}


sub fillClip1($$$$)
{   my ($self, @bbox) = @_;
    my $outer = $self->outer->fillClip1(@bbox);
    return () unless defined $outer;

    $self->new
      ( outer => $outer
      , inner => [ map {$_->fillClip1(@bbox)} $self->inner ]
      );
}


sub string()
{   my $self = shift;
      "["
    . join( "]\n-["
          , $self->outer->string
          , map {$_->string } $self->inner)
    . "]";
}

1;
