# Copyrights 2004,2006-2014 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
use strict;
use warnings;

package Math::Polygon;
use vars '$VERSION';
$VERSION = '1.03';


use Math::Polygon::Calc;
use Math::Polygon::Clip;
use Math::Polygon::Transform;


sub new(@)
{   my $thing = shift;
    my $class = ref $thing || $thing;

    my @points;
    my %options;
    if(ref $thing)
    {   $options{clockwise} = $thing->{MP_clockwise};
    }

    while(@_)
    {   if(ref $_[0] eq 'ARRAY') {push @points, shift}
        else { my $k = shift; $options{$k} = shift }
    }
    $options{_points} = \@points;

    (bless {}, $class)->init(\%options);
}

sub init($$)
{   my ($self, $args) = @_;
    $self->{MP_points}    = $args->{points} || $args->{_points};
    $self->{MP_clockwise} = $args->{clockwise};
    $self->{MP_bbox}      = $args->{bbox};
    $self;
}


sub nrPoints() { scalar @{shift->{MP_points}} }


sub order() { @{shift->{MP_points}} -1 }


sub points() { wantarray ? @{shift->{MP_points}} : shift->{MP_points} }


sub point(@)
{   my $points = shift->{MP_points};
    wantarray ? @{$points}[@_] : $points->[shift];
}


sub bbox()
{   my $self = shift;
    return @{$self->{MP_bbox}} if $self->{MP_bbox};

    my @bbox = polygon_bbox $self->points;
    $self->{MP_bbox} = \@bbox;
    @bbox;
}


sub area()
{   my $self = shift;
    return $self->{MP_area} if defined $self->{MP_area};
    $self->{MP_area} = polygon_area $self->points;
}

sub centroid()
{   my $self = shift;
    return $self->{MP_centroid} if $self->{MP_centroid};
    $self->{MP_centroid} = polygon_centroid $self->points;
}


sub isClockwise()
{   my $self = shift;
    return $self->{MP_clockwise} if defined $self->{MP_clockwise};
    $self->{MP_clockwise} = polygon_is_clockwise $self->points;
}


sub clockwise()
{   my $self = shift;
    return $self if $self->isClockwise;

    $self->{MP_points}    = [ reverse $self->points ];
    $self->{MP_clockwise} = 1;
    $self;
}


sub counterClockwise()
{   my $self = shift;
    return $self unless $self->isClockwise;

    $self->{MP_points}    = [ reverse $self->points ];
    $self->{MP_clockwise} = 0;
    $self;
}


sub perimeter() { polygon_perimeter shift->points }


sub startMinXY()
{   my $self = shift;
    $self->new(polygon_start_minxy $self->points);
}


sub beautify(@)
{   my ($self, %opts) = @_;
    my @beauty = polygon_beautify \%opts, $self->points;
    @beauty>2 ? $self->new(points => \@beauty) : ();
}


sub equal($;@)
{   my $self  = shift;
    my ($other, $tolerance);
    if(@_ > 2 || ref $_[1] eq 'ARRAY') { $other = \@_ }
    else
    {   $other     = ref $_[0] eq 'ARRAY' ? shift : shift->points;
        $tolerance = shift;
    }
    polygon_equal scalar($self->points), $other, $tolerance;
}


sub same($;@)
{   my $self = shift;
    my ($other, $tolerance);
    if(@_ > 2 || ref $_[1] eq 'ARRAY') { $other = \@_ }
    else
    {   $other     = ref $_[0] eq 'ARRAY' ? shift : shift->points;
        $tolerance = shift;
    }
    polygon_same scalar($self->points), $other, $tolerance;
}


sub contains($)
{   my ($self, $point) = @_;
    polygon_contains_point($point, $self->points);
}


sub isClosed() { polygon_is_closed(shift->points) }


sub resize(@)
{   my $self = shift;

    my $clockwise = $self->{MP_clockwise};
    if(defined $clockwise)
    {   my %args   = @_;
        my $xscale = $args{xscale} || $args{scale} || 1;
        my $yscale = $args{yscale} || $args{scale} || 1;
        $clockwise = not $clockwise if $xscale * $yscale < 0;
    }

    (ref $self)->new
       ( points    => [ polygon_resize @_, $self->points ]
       , clockwise => $clockwise
       # we could save the bbox calculation as well
       );
}


sub move(@)
{   my $self = shift;

    (ref $self)->new
       ( points    => [ polygon_move @_, $self->points ]
       , clockwise => $self->{MP_clockwise}
       , bbox      => $self->{MP_bbox}
       );
}


sub rotate(@)
{   my $self = shift;

    (ref $self)->new
       ( points    => [ polygon_rotate @_, $self->points ]
       , clockwise => $self->{MP_clockwise}
       # we could save the bbox calculation as well
       );
}


sub grid(@)
{   my $self = shift;

    (ref $self)->new
       ( points    => [ polygon_grid @_, $self->points ]
       , clockwise => $self->{MP_clockwise}  # probably
       # we could save the bbox calculation as well
       );
}


sub mirror(@)
{   my $self = shift;

    my $clockwise = $self->{MP_clockwise};
    $clockwise    = not $clockwise if defined $clockwise;

    (ref $self)->new
       ( points    => [ polygon_grid @_, $self->points ]
       , clockwise => $clockwise
       # we could save the bbox calculation as well
       );
}


sub simplify(@)
{   my $self = shift;

    (ref $self)->new
       ( points    => [ polygon_simplify @_, $self->points ]
       , clockwise => $self->{MP_clockwise}  # probably
       , bbox      => $self->{MP_bbox}       # protect bounds
       );
}


sub lineClip($$$$)
{   my ($self, @bbox) = @_;
    polygon_line_clip \@bbox, $self->points;
}


sub fillClip1($$$$)
{   my ($self, @bbox) = @_;
    my @clip = polygon_fill_clip1 \@bbox, $self->points;
    @clip or return undef;
    $self->new(points => \@clip);
}

#-------------


sub string() { polygon_string(shift->points) }

1;
