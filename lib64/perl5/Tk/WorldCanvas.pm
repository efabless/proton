package Tk::WorldCanvas;
require Tk::Canvas;
require Tk::Derived;
use strict;
use Tk;

use vars qw($VERSION);
$VERSION = '1.2.7';

#Version
#1.0.0 -- Sept 20, 2001 -- Initial release.
#1.1.0 -- Oct  29, 2001 -- Added '-changeView' callback option
#1.2.0 -- Jan  29, 2002 -- Added 'getView' method,
#                          better error handleing in 'bbox',
#                          cleaned up syntax
#1.2.1 -- May  17, 2002 -- changed package name to Tk::WorldCanvas
#1.2.2 -- June 28, 2002 -- Fixed bug in 'coords'
#1.2.3 -- July 31, 2002 -- Fixed another bug in 'coords', and an agrument passing bug.
#1.2.4 -- Sept  5, 2002 -- Added to POD
#1.2.5 -- Sept  6, 2002 -- Enhanced view window scaleing on canvas resize
#1.2.6 -- Nov   1, 2002 -- Fixed _view_area_canvas bug.
#1.2.7 -- Nov  19, 2002 -- handle fractional arguments to canvas(x|y)

@Tk::WorldCanvas::ISA = qw(Tk::Derived Tk::Canvas);

Construct Tk::Widget 'WorldCanvas';

sub ClassInit {
    my ($worldcanvas, $mw) = @_;

    $worldcanvas->SUPER::ClassInit($mw);
}

sub InitObject {
    my ($worldcanvas, $args) = @_;

    my $pData = $worldcanvas->privateData;
    $pData->{'bbox'} = [0, 0, -1, -1];
    $pData->{'scale'} = 1;
    $pData->{'movex'} = 0;
    $pData->{'movey'} = 0;
    $pData->{'bboxvalid'} = 1;
    $pData->{'width'} = $worldcanvas->width;
    $pData->{'height'} = $worldcanvas->height;

    $worldcanvas->configure(-confine => 0);

    $worldcanvas->ConfigSpecs('-bandColor' => ['PASSIVE', 'bandColor', 'BandColor', 'red'],
                              '-bandcolor' => '-bandColor',
                              '-changeView' => ['CALLBACK', 'changeView', 'ChangeView', undef],
                              '-changeview'  => '-changeView');

    $worldcanvas->CanvasBind('<Configure>' =>
        sub {
            my $w = $worldcanvas->width;
            my $h = $worldcanvas->height;
            my $ow = $pData->{'width'};
            my $oh = $pData->{'height'};
            if ($w != $ow or $h != $oh) {
                my $b = $worldcanvas->cget('-borderwidth');
                _view_area_canvas($worldcanvas, $b, $b, $ow - $b, $oh - $b);
                $pData->{'width'} = $w;
                $pData->{'height'} = $h;

                my $bbox = $pData->{'bbox'};
                my $le = $worldcanvas->canvasx($b);
                my $re = $worldcanvas->canvasx($w - $b);
                my $te = $worldcanvas->canvasy($b);
                my $be = $worldcanvas->canvasy($h - $b);
                if (_inside(@$bbox, $le, $te, $re, $be)) {
                    $worldcanvas->viewAll;
                }
            }
        }
    );

    $worldcanvas->SUPER::InitObject($args);
}

sub getView {
    my ($canvas) = @_;

    my $borderwidth = $canvas->cget('-borderwidth');
    my $right_edge = $canvas->width - $borderwidth;
    my $left_edge = $borderwidth;
    my $bot_edge = $canvas->height - $borderwidth;
    my $top_edge = $borderwidth;

    return (worldxy($canvas, $left_edge, $bot_edge), worldxy($canvas, $right_edge, $top_edge));
}

sub xview {
    my $canvas = shift;
    _new_bbox($canvas) unless $canvas->privateData->{'bboxvalid'};
    $canvas->SUPER::xview(@_);
    $canvas->Callback(-changeView, getView($canvas)) if defined($canvas->cget('-changeView'));
}

sub yview {
    my $canvas = shift;
    _new_bbox($canvas) unless $canvas->privateData->{'bboxvalid'};
    $canvas->SUPER::yview(@_);
    $canvas->Callback(-changeView, getView($canvas)) if defined($canvas->cget('-changeView'));
}

sub delete {
    my ($canvas, @tags) = @_;

    my $recreate = _killBand($canvas);

    my $found = 0;
    foreach my $tag (@tags) {
        if ($canvas->type($tag)) {
            $found = 1;
            last;
        }
    }
    if (!$found) { # can't find anything!
        _makeBand($canvas) if $recreate;
        return;
    }

    my $pData = $canvas->privateData;
    my ($cx1, $cy1, $cx2, $cy2) = @{$pData->{'bbox'}};
    my ($x1, $y1, $x2, $y2) = _superBbox($canvas, @tags);
    $canvas->SUPER::delete(@tags);

    if (!$canvas->type('all')) {  # deleted last object
        $pData->{'bbox'} = [0, 0, -1, -1];
        $pData->{'scale'} = 1;
        $pData->{'movex'} = 0;
        $pData->{'movey'} = 0;
    } elsif (!_inside($x1, $y1, $x2, $y2, $cx1, $cy1, $cx2, $cy2)) {
        $pData->{'bboxvalid'} = 0;
    }
    _makeBand($canvas) if $recreate;
}

sub _inside {
    my ($ix1, $iy1, $ix2, $iy2, $ox1, $oy1, $ox2, $oy2) = @_;

    my $wmargin = 0.01 * ($ox2 - $ox1);
    my $hmargin = 0.01 * ($oy2 - $oy1);

    $wmargin = 3 if $wmargin < 3;
    $hmargin = 3 if $hmargin < 3;

    return ($ix1 - $wmargin > $ox1 and $iy1 - $hmargin > $oy1 and
            $ix2 + $wmargin < $ox2 and $iy2 + $hmargin < $oy2);
}

sub _new_bbox {
    my ($canvas) = @_;

    my $borderwidth = $canvas->cget('-borderwidth');
    my $vwidth = $canvas->width - 2 * $borderwidth;
    my $vheight = $canvas->height - 2 * $borderwidth;

    my $pData = $canvas->privateData;
    my ($cx1, $cy1, $cx2, $cy2) = @{$pData->{'bbox'}};

    $cx2 += 1 if $cx2 == $cx1;
    $cy2 += 1 if $cy2 == $cy1;
    my $zoomx = $vwidth  / abs($cx2 - $cx1);
    my $zoomy = $vheight / abs($cy2 - $cy1);
    my $zoom = ($zoomx > $zoomy) ? $zoomx : $zoomy;

    if ($zoom > 1.01) {
        _scale($canvas, $canvas->width / 2, $canvas->height / 2, $zoom * 100);
    }

    my ($x1, $y1, $x2, $y2) = _superBbox($canvas, 'all');
    $pData->{'bbox'} =                  [$x1, $y1, $x2, $y2];
    $canvas->configure(-scrollregion => [$x1, $y1, $x2, $y2]);

    if ($zoom > 1.01) {
        _scale($canvas, $canvas->width / 2, $canvas->height / 2, 1 / ($zoom * 100));
    }

    $pData->{'bboxvalid'} = 1;
}

sub _find_box {
    die "Error: the number of args to _find_box must be positive and even\n" if @_ % 2 or !@_;
    my $x1 = $_[0];
    my $x2 = $_[0];
    my $y1 = $_[1];
    my $y2 = $_[1];
    for (my $i = 2; $i < @_; $i += 2) {
        if ($_[$i] < $x1) {$x1 = $_[$i];}
        if ($_[$i] > $x2) {$x2 = $_[$i];}
        if ($_[$i + 1] < $y1) {$y1 = $_[$i + 1];}
        if ($_[$i + 1] > $y2) {$y2 = $_[$i + 1];}
    }
    return ($x1, $y1, $x2, $y2);
}

sub zoom {
    my ($canvas, $zoom) = @_;
    _new_bbox($canvas) unless $canvas->privateData->{'bboxvalid'};
    _scale($canvas, $canvas->width / 2, $canvas->height / 2, $zoom);
    $canvas->Callback(-changeView, getView($canvas)) if defined($canvas->cget('-changeView'));
}

sub _scale {
    my ($canvas, $xo, $yo, $scale) = @_;

    $scale = abs($scale);

    my $x = $canvas->canvasx(0) + $xo;
    my $y = $canvas->canvasy(0) + $yo;

    if (!$canvas->type('all')) {return;} # can't find it

    my $pData = $canvas->privateData;
    $pData->{'movex'} = ($pData->{'movex'} - $x) * $scale + $x;
    $pData->{'movey'} = ($pData->{'movey'} - $y) * $scale + $y;
    $pData->{'scale'} *= $scale;

    $canvas->SUPER::scale('all', $x, $y, $scale, $scale);

    my ($x1, $y1, $x2, $y2) = @{$pData->{'bbox'}};
    $x1 = ($x1 - $x) * $scale + $x;
    $x2 = ($x2 - $x) * $scale + $x;
    $y1 = ($y1 - $y) * $scale + $y;
    $y2 = ($y2 - $y) * $scale + $y;
    $pData->{'bbox'} =                  [$x1, $y1, $x2, $y2];
    $canvas->configure(-scrollregion => [$x1, $y1, $x2, $y2]);
}

sub center {
    my ($canvas, $x, $y) = @_;

    if (!$canvas->type('all')) {return;} # can't find anything!

    my $pData = $canvas->privateData;
    _new_bbox($canvas) unless $pData->{'bboxvalid'};

    $x = $x *  $pData->{'scale'} + $pData->{'movex'};
    $y = $y * -$pData->{'scale'} + $pData->{'movey'};

    my $dx = $canvas->canvasx(0) + $canvas->width / 2 - $x;
    my $dy = $canvas->canvasy(0) + $canvas->height / 2 - $y;

    $pData->{'movex'} += $dx;
    $pData->{'movey'} += $dy;
    $canvas->SUPER::move('all', $dx, $dy);

    my ($x1, $y1, $x2, $y2) = @{$pData->{'bbox'}};
    $x1 += $dx;
    $x2 += $dx;
    $y1 += $dy;
    $y2 += $dy;
    $pData->{'bbox'} =                  [$x1, $y1, $x2, $y2];
    $canvas->configure(-scrollregion => [$x1, $y1, $x2, $y2]);
    $canvas->Callback(-changeView, getView($canvas)) if defined($canvas->cget('-changeView'));
}

sub centerTags {
    my ($canvas, @args) = @_;

    my ($x1, $y1, $x2, $y2) = bbox($canvas, @args);
    return unless defined($y2);
    center($canvas, ($x1 + $x2) / 2.0, ($y1 + $y2) / 2.0);
}

sub panWorld {
    my ($canvas, $x, $y) = @_;

    my $cx = worldx($canvas, $canvas->width / 2)  + $x;
    my $cy = worldy($canvas, $canvas->height / 2) + $y;
    center($canvas, $cx, $cy);
}

sub viewAll {
    my $canvas = shift;

    if (!$canvas->type('all')) {return;} # can't find anything!

    my %switches = (-border => 0.02, @_);
    $switches{-border} = 0 if $switches{-border} < 0;

    my $pData = $canvas->privateData;
    _new_bbox($canvas) unless $pData->{'bboxvalid'};

    my ($x1, $y1, $x2, $y2) = @{$pData->{'bbox'}};
    my $scale = $pData->{'scale'};
    my $movex = $pData->{'movex'};
    my $movey = $pData->{'movey'};
    my $wx1 = ($x1 - $movex) / $scale;
    my $wx2 = ($x2 - $movex) / $scale;
    my $wy1 = ($y1 - $movey) / $scale;
    my $wy2 = ($y2 - $movey) / $scale;

    viewArea($canvas, $wx1, -$wy1, $wx2, -$wy2, -border => $switches{-border});
}

sub viewArea {
    my ($canvas, $vx1, $vy1, $vx2, $vy2) = splice(@_, 0, 5);

    if (!defined($vy2) or !$canvas->type('all')) {return;} # can't find anything!

    my %switches = (-border => 0.02, @_);
    $switches{-border} = 0 if $switches{-border} < 0;

    my $pData = $canvas->privateData;
    _new_bbox($canvas) unless $pData->{'bboxvalid'};

    $vy1 = -$vy1;
    $vy2 = -$vy2;

    ($vx1, $vx2) = ($vx2, $vx1) if $vx1 > $vx2;
    ($vy1, $vy2) = ($vy2, $vy1) if $vy1 > $vy2;
    my $bw = $switches{-border} * ($vx2 - $vx1);
    my $bh = $switches{-border} * ($vy2 - $vy1);
    $vx1 -= $bw;
    $vx2 += $bw;
    $vy1 -= $bh;
    $vy2 += $bh;

    my $scale  = $pData->{'scale'};
    my $movex  = $pData->{'movex'};
    my $movey  = $pData->{'movey'};
    my $canvasx = $canvas->canvasx(0);
    my $canvasy = $canvas->canvasy(0);

    my $cx1 = $vx1 * $scale + $movex - $canvasx;
    my $cx2 = $vx2 * $scale + $movex - $canvasx;
    my $cy1 = $vy1 * $scale + $movey - $canvasy;
    my $cy2 = $vy2 * $scale + $movey - $canvasy;

    _view_area_canvas($canvas, $cx1, $cy1, $cx2, $cy2);
}

sub _view_area_canvas {
    my ($canvas, $vx1, $vy1, $vx2, $vy2) = @_;

    if (!$canvas->type('all')) {return;} # can't find anything!
    my $pData = $canvas->privateData;
    _new_bbox($canvas) unless $pData->{'bboxvalid'};

    my $borderwidth = $canvas->cget('-borderwidth');
    my $cwidth = $canvas->width;
    my $cheight = $canvas->height;

    my $dx = $cwidth / 2 - ($vx1 + $vx2) / 2;
    my $dy = $cheight / 2 - ($vy1 + $vy2) / 2;

    my $midx = $canvas->canvasx(0) + $cwidth / 2;
    my $midy = $canvas->canvasy(0) + $cheight / 2;

    $vx2 += 1 if $vx2 == $vx1;
    $vy2 += 1 if $vy2 == $vy1;
    my $zoomx =  ($cwidth - 2 * $borderwidth) / abs($vx2 - $vx1);
    my $zoomy = ($cheight - 2 * $borderwidth) / abs($vy2 - $vy1);
    my $zoom = ($zoomx < $zoomy) ? $zoomx : $zoomy;
    $zoom = abs($zoom); # This should never be needed.

    if ($zoom > 0.999 and $zoom < 1.001) {
        $canvas->SUPER::move('all', $dx, $dy);
    } else {
        $canvas->SUPER::scale('all', $midx - $dx - $dx / ($zoom - 1), $midy - $dy - $dy / ($zoom - 1), $zoom, $zoom);
    }

    $pData->{'movex'} = ($pData->{'movex'} + $dx - $midx) * $zoom + $midx;
    $pData->{'movey'} = ($pData->{'movey'} + $dy - $midy) * $zoom + $midy;
    $pData->{'scale'} *= $zoom;

    my ($x1, $y1, $x2, $y2) = @{$pData->{'bbox'}};
    $x1 = ($x1 + $dx - $midx) * $zoom + $midx;
    $x2 = ($x2 + $dx - $midx) * $zoom + $midx;
    $y1 = ($y1 + $dy - $midy) * $zoom + $midy;
    $y2 = ($y2 + $dy - $midy) * $zoom + $midy;
    $pData->{'bbox'} =                  [$x1, $y1, $x2, $y2];
    $canvas->configure(-scrollregion => [$x1, $y1, $x2, $y2]);
    $canvas->Callback(-changeView, getView($canvas)) if defined($canvas->cget('-changeView'));
}

sub _map_coords {
    my $canvas = shift;

    my @coords = ();
    my $pData = $canvas->privateData;
    my $change_bbox = 0;
    my ($x1, $y1, $x2, $y2) = @{$pData->{'bbox'}};

    my $scale = $pData->{'scale'};
    my $movex = $pData->{'movex'};
    my $movey = $pData->{'movey'};

    my $x = 1;
    while (defined (my $arg = shift)) {
        if ($arg !~ /^[+-.]*\d/) {
            unshift @_, $arg;
            last;
        } else {
            if ($x) {
               $arg = $arg * $scale + $movex;
               if ($x2 < $x1) {$x2 = $x1 = $arg; $change_bbox = 1;}
               if ($arg < $x1) {$x1 = $arg; $change_bbox = 1;}
               if ($arg > $x2) {$x2 = $arg; $change_bbox = 1;}
               $x = 0;
            } else {
               $arg = -$arg * $scale + $movey;  # invert y-coords
               if ($y2 < $y1) {$y2 = $y1 = $arg; $change_bbox = 1;}
               if ($arg < $y1) {$y1 = $arg; $change_bbox = 1;}
               if ($arg > $y2) {$y2 = $arg; $change_bbox = 1;}
               $x = 1;
            }
            push @coords, $arg;
        }
    }
    if ($change_bbox) {
        $pData->{'bbox'} =                  [$x1, $y1, $x2, $y2];
        $canvas->configure(-scrollregion => [$x1, $y1, $x2, $y2]);
    }

    return (@coords, @_);
}

sub find {
    my ($canvas, @args) = @_;

    my $pData = $canvas->privateData;
    if ($args[0] =~ m/^(closest|above|below)$/i) {
        if ($args[0] =~ m/^closest$/i) {
            return if @args < 3;
            my $scale = $pData->{'scale'};
            $args[1] =  $args[1] * $scale + $pData->{'movex'};
            $args[2] = -$args[2] * $scale + $pData->{'movey'};
        }
        my $recreate = _killBand($canvas);
        my $found = $canvas->SUPER::find(@args);
        _makeBand($canvas) if $recreate;
        return $found;
    } else {
        if ($args[0] =~ m/^(enclosed|overlapping)$/i) {
            return if @args < 5;
            my $scale = $pData->{'scale'};
            my $movex = $pData->{'movex'};
            my $movey = $pData->{'movey'};
            $args[1] =  $args[1] * $scale + $movex;
            $args[2] = -$args[2] * $scale + $movey;
            $args[3] =  $args[3] * $scale + $movex;
            $args[4] = -$args[4] * $scale + $movey;
        }
        my $recreate = _killBand($canvas);
        my @found = $canvas->SUPER::find(@args);
        _makeBand($canvas) if $recreate;
        return @found;
    }
}

sub coords {
    my ($canvas, $tag, @w_coords) = @_;

    if (!$canvas->type($tag)) {return;} # can't find it

    my $pData = $canvas->privateData;
    my $scale = $pData->{'scale'};
    my $movex = $pData->{'movex'};
    my $movey = $pData->{'movey'};

    if (@w_coords) {
        die "missing y coordinate in call to coords\n" if @w_coords % 2;
        my ($x1, $y1, $x2, $y2) = _find_box($canvas->SUPER::coords($tag));

        my @c_coords = @w_coords;
        for (my $i = 0; $i < @c_coords; $i += 2) {
            $c_coords[$i]     =  $c_coords[$i    ] * $scale + $movex;
            $c_coords[$i + 1] = -$c_coords[$i + 1] * $scale + $movey;
        }
        $canvas->SUPER::coords($tag, @c_coords);

        my ($nx1, $ny1, $nx2, $ny2) = _find_box(@c_coords);
        _adjustBbox($canvas, $x1, $y1, $x2, $y2, $nx1, $ny1, $nx2, $ny2);
    } else {
        @w_coords = $canvas->SUPER::coords($tag);
        die "missing y coordinate in return value from SUPER::coords\n" if @w_coords % 2;
        for (my $i = 0; $i < @w_coords; $i += 2) {
            $w_coords[$i] =         ($w_coords[$i]     - $movex) / $scale;
            $w_coords[$i + 1] = 0 - ($w_coords[$i + 1] - $movey) / $scale;
        }
        if (@w_coords == 4 and ($w_coords[0] > $w_coords[2] or $w_coords[1] > $w_coords[3])) {
            my $type = $canvas->type($tag);
            if ($type =~ /^arc$|^oval$|^rectangle$/) {
                ($w_coords[0], $w_coords[2]) = ($w_coords[2], $w_coords[0]) if $w_coords[0] > $w_coords[2];
                ($w_coords[1], $w_coords[3]) = ($w_coords[3], $w_coords[1]) if $w_coords[1] > $w_coords[3];
            }
        }
        return @w_coords;
    }
    return;
}

sub scale {
    my ($canvas, $tag, $xo, $yo, $xs, $ys) = @_;

    if (!$canvas->type($tag)) {return;} # can't find it

    my $pData = $canvas->privateData;

    my $cxo =  $xo * $pData->{'scale'} + $pData->{'movex'};
    my $cyo = -$yo * $pData->{'scale'} + $pData->{'movey'};

    if ($tag =~ m/^all$/i) {
        $canvas->SUPER::scale($tag, $cxo, $cyo, $xs, $ys);

        my ($x1, $y1, $x2, $y2) = @{$pData->{'bbox'}};
        $x1 = ($x1 - $cxo) * $xs + $cxo;
        $x2 = ($x2 - $cxo) * $xs + $cxo;
        $y1 = ($y1 - $cyo) * $ys + $cyo;
        $y2 = ($y2 - $cyo) * $ys + $cyo;
        $pData->{'bbox'} =                  [$x1, $y1, $x2, $y2];
        $canvas->configure(-scrollregion => [$x1, $y1, $x2, $y2]);
    } else {
        my ($x1, $y1, $x2, $y2) = _find_box($canvas->SUPER::coords($tag));
        $canvas->SUPER::scale($tag, $cxo, $cyo, $xs, $ys);
        my $nx1 = ($x1 - $cxo) * $xs + $cxo;
        my $nx2 = ($x2 - $cxo) * $xs + $cxo;
        my $ny1 = ($y1 - $cyo) * $ys + $cyo;
        my $ny2 = ($y2 - $cyo) * $ys + $cyo;

        _adjustBbox($canvas, $x1, $y1, $x2, $y2, $nx1, $ny1, $nx2, $ny2);
    }
}

sub move {
    my ($canvas, $tag, $x, $y) = @_;

    my ($x1, $y1, $x2, $y2) = _find_box($canvas->SUPER::coords($tag));

    my $scale = $canvas->privateData->{'scale'};
    my $dx =  $x * $scale;
    my $dy = -$y * $scale;
    $canvas->SUPER::move($tag, $dx, $dy);

    my ($nx1, $ny1, $nx2, $ny2) = ($x1 + $dx, $y1 + $dy, $x2 + $dx, $y2 + $dy);
    _adjustBbox($canvas, $x1, $y1, $x2, $y2, $nx1, $ny1, $nx2, $ny2);
}

sub _adjustBbox {
    my ($canvas, $x1, $y1, $x2, $y2, $nx1, $ny1, $nx2, $ny2) = @_;

    my $pData = $canvas->privateData;
    my ($cx1, $cy1, $cx2, $cy2) = @{$pData->{'bbox'}};

    my $changeBbox = 0;
    if ($nx1 < $cx1) {$cx1 = $nx1; $changeBbox = 1;}
    if ($ny1 < $cy1) {$cy1 = $ny1; $changeBbox = 1;}
    if ($nx2 > $cx2) {$cx2 = $nx2; $changeBbox = 1;}
    if ($ny2 > $cy2) {$cy2 = $ny2; $changeBbox = 1;}

    #expanding the bounding box is easy.
    if ($changeBbox) {
        $pData->{'bbox'} =                  [$cx1, $cy1, $cx2, $cy2];
        $canvas->configure(-scrollregion => [$cx1, $cy1, $cx2, $cy2]);
    }

    #shrinking the bounding box is not easy.
    my $wmargin = 0.01 * ($cx2 - $cx1);
    my $hmargin = 0.01 * ($cy2 - $cy1);
    $wmargin = 3 if $wmargin < 3;
    $hmargin = 3 if $hmargin < 3;

    if (($x1 - $wmargin < $cx1 and $x1 < $nx1) or
        ($y1 - $hmargin < $cy1 and $y1 < $ny1) or
        ($x2 + $wmargin > $cx2 and $x2 > $nx2) or
        ($y2 + $hmargin > $cy2 and $y2 > $ny2)) {
        $pData->{'bboxvalid'} = 0;
    }
}

sub bbox {
    my $canvas = shift;

    my $exact = 0;
    if ($_[0] =~ m/-exact/i) {
        shift;
        $exact = shift;
    }
    my @tags = @_;

    my $found = 0;
    foreach my $tag (@tags) {
        if ($canvas->type($tag)) {
            $found = 1;
            last;
        }
    }
    return unless $found;

    my $pData = $canvas->privateData;

    if ($tags[0] =~ m/^all$/i) {
        my ($x1, $y1, $x2, $y2) = @{$pData->{'bbox'}};
        my $scale = $pData->{'scale'};
        my $movex = $pData->{'movex'};
        my $movey = $pData->{'movey'};
        my $wx1 = ($x1 - $movex) /  $scale;
        my $wx2 = ($x2 - $movex) /  $scale;
        my $wy1 = ($y1 - $movey) / -$scale;
        my $wy2 = ($y2 - $movey) / -$scale;

        ($wx1, $wx2) = ($wx2, $wx1) if ($wx2 < $wx1);
        ($wy1, $wy2) = ($wy2, $wy1) if ($wy2 < $wy1);
        return ($wx1, $wy1, $wx2, $wy2);
    } else {
        my $onePixel = 1.0 / $pData->{'scale'};
        my $zoom_fix = 0;
        if ($exact and $onePixel > 0.001) {
            zoom($canvas, $onePixel * 1000);
            $zoom_fix = 1;
        }
        my ($x1, $y1, $x2, $y2) = _superBbox($canvas, @tags);
        if (not defined $x1) {
            # @tags exist but their bbox can not be
            # expressed in integers (overflows).
            zoom($canvas, 1 / ($onePixel * 1000)) if $zoom_fix;
            return;
        }

        # If the error looks to be greater than 15%, do exact anyway
        if (!$exact and abs($x2 - $x1) < 27 and abs($y2 - $y1) < 27) {
            zoom($canvas, $onePixel * 1000);
            my ($nx1, $ny1, $nx2, $ny2) = _superBbox($canvas, @tags);
            if (not defined $nx1) {
                # overflows integers.  Retreat to previous box.
                zoom($canvas, 1 / ($onePixel * 1000));
            } else {
                $zoom_fix = 1;
                ($x1, $y1, $x2, $y2) = ($nx1, $ny1, $nx2, $ny2);
            }
        }

        my $scale = $pData->{'scale'};
        my $movex = $pData->{'movex'};
        my $movey = $pData->{'movey'};
        $x1 = ($x1 - $movex) /  $scale;
        $x2 = ($x2 - $movex) /  $scale;
        $y1 = ($y1 - $movey) / -$scale;
        $y2 = ($y2 - $movey) / -$scale;

        if ($zoom_fix) {
            zoom($canvas, 1 / ($onePixel * 1000));
        }
        return ($x1, $y2, $x2, $y1);
    }
}

sub rubberBand {
    die "Error: wrong number of args passed to rubberBand\n" unless @_ == 2;
    my ($canvas, $step) = @_;

    my $pData = $canvas->privateData;
    return if $step >= 1 and not defined $pData->{'RubberBand'};

    my $ev = $canvas->XEvent;
    my $x = worldx($canvas, $ev->x);
    my $y = worldy($canvas, $ev->y);

    if ($step == 0) {
        # create anchor for rubberband
        _killBand($canvas);
        $pData->{'RubberBand'} = [$x, $y, $x, $y];
    } elsif ($step == 1) {
        # update end of rubber band and redraw
        $pData->{'RubberBand'}[2] = $x;
        $pData->{'RubberBand'}[3] = $y;
        _killBand($canvas);
        _makeBand($canvas);
    } elsif ($step == 2) {
        # step == 2: done
        _killBand($canvas) or return;

        my ($x1, $y1, $x2, $y2) = @{$pData->{'RubberBand'}};
        undef($pData->{'RubberBand'});

        ($x1, $x2) = ($x2, $x1) if ($x2 < $x1);
        ($y1, $y2) = ($y2, $y1) if ($y2 < $y1);
        return ($x1, $y1, $x2, $y2);
    }
}

sub _superBbox {
    my ($canvas, @tags) = @_;

    my $recreate = _killBand($canvas);
    my ($x1, $y1, $x2, $y2) = $canvas->SUPER::bbox(@tags);
    _makeBand($canvas) if $recreate;

    return ($x1, $y1, $x2, $y2);
}

sub _killBand {
    my ($canvas) = @_;

    my $id = $canvas->privateData->{'RubberBandID'};
    return 0 if !defined($id);

    $canvas->SUPER::delete($id);
    undef($canvas->privateData->{'RubberBandID'});

    return 1;
}

sub _makeBand {
    my ($canvas) = @_;

    my $pData = $canvas->privateData;
    my $rb = $pData->{'RubberBand'};
    die "Error: RubberBand is not defined" if !$rb;
    die "Error: RubberBand does not have 4 values." if @$rb != 4;

    my $scale = $pData->{'scale'};
    my $movex = $pData->{'movex'};
    my $movey = $pData->{'movey'};
    my $crbx1 = $rb->[0] *  $scale + $movex;
    my $crbx2 = $rb->[2] *  $scale + $movex;
    my $crby1 = $rb->[1] * -$scale + $movey;
    my $crby2 = $rb->[3] * -$scale + $movey;

    my $color = $canvas->cget('-bandColor');
    my $id = $canvas->SUPER::create('rectangle', $crbx1, $crby1, $crbx2, $crby2, -outline => $color);
    $pData->{'RubberBandID'} = $id;
}

sub eventLocation {
    my ($canvas) = @_;

    my $ev = $canvas->XEvent;
    return ($canvas->worldx($ev->x), $canvas->worldy($ev->y)) if defined $ev;
    return;
}

sub viewFit {
    my $canvas = shift;
    my $border = 0.02;

    if ($_[0] =~ m/-border/i) {
        shift;
        $border = shift if (@_);
        $border = 0 if $border < 0;
    }
    my @tags = @_;

    my $found = 0;
    foreach my $tag (@tags) {
        if ($canvas->type($tag)) {
            $found = 1;
            last;
        }
    }
    return unless $found;

    viewArea($canvas, bbox($canvas, @tags), -border => $border);
}

sub pixelSize {
    my ($canvas) = @_;

    return (1.0 / $canvas->privateData->{'scale'});
}

sub worldx {
    my ($canvas, $x) = @_;

    my $pData = $canvas->privateData;
    my $scale = $pData->{'scale'};
    return if !$scale;
    return (($canvas->canvasx(0) + $x - $pData->{'movex'}) / $scale);
}

sub worldy {
    my ($canvas, $y) = @_;

    my $pData = $canvas->privateData;
    my $scale = $pData->{'scale'};
    return if !$scale;
    return (0 - ($canvas->canvasy(0) + $y - $pData->{'movey'}) / $scale);
}

sub worldxy {
    my ($canvas, $x, $y) = @_;

    my $pData = $canvas->privateData;
    my $scale = $pData->{'scale'};
    return if !$scale;
    return (    ($canvas->canvasx(0) + $x - $pData->{'movex'}) / $scale,
            0 - ($canvas->canvasy(0) + $y - $pData->{'movey'}) / $scale);
}

sub widgetx {
    my ($canvas, $x) = @_;

    my $pData = $canvas->privateData;
    return ($x * $pData->{'scale'} + $pData->{'movex'} - $canvas->canvasx(0));
}

sub widgety {
    my ($canvas, $y) = @_;

    my $pData = $canvas->privateData;
    return (-$y * $pData->{'scale'} + $pData->{'movey'} - $canvas->canvasy(0));
}

sub widgetxy {
    my ($canvas, $x, $y) = @_;

    my $pData = $canvas->privateData;
    my $scale = $pData->{'scale'};
    return ( $x * $scale + $pData->{'movex'} - $canvas->canvasx(0),
            -$y * $scale + $pData->{'movey'} - $canvas->canvasy(0));
}

# In older versions of Tk, createType calls create('type', ...)
# 'coords_mapped' is used to avoid calling _map_coords twice.
# I could have had the createType methods all call create, but
# that defeats the point of the new Tk optimization to avoid
# the case statement.
my $coords_mapped = 0;

sub create {
    my ($canvas, $type) = splice(@_, 0, 2);
    my @new_args = ($coords_mapped) ? @_ : _map_coords($canvas, @_);
    return ($canvas->SUPER::create($type, @new_args));
}

sub createPolygon {
    my $canvas = shift;
    my @new_args = _map_coords($canvas, @_);
    $coords_mapped = 1;
    my $id = $canvas->SUPER::createPolygon(@new_args);
    $coords_mapped = 0;
    return $id;
}

sub createRectangle {
    my $canvas = shift;
    my @new_args = _map_coords($canvas, @_);
    $coords_mapped = 1;
    my $id = $canvas->SUPER::createRectangle(@new_args);
    $coords_mapped = 0;
    return $id;
}

sub createArc {
    my $canvas = shift;
    my @new_args = _map_coords($canvas, @_);
    $coords_mapped = 1;
    my $id = $canvas->SUPER::createArc(@new_args);
    $coords_mapped = 0;
    return $id;
}

sub createLine {
    my $canvas = shift;
    my @new_args = _map_coords($canvas, @_);
    $coords_mapped = 1;
    my $id = $canvas->SUPER::createLine(@new_args);
    $coords_mapped = 0;
    return $id;
}

sub createOval {
    my $canvas = shift;
    my @new_args = _map_coords($canvas, @_);
    $coords_mapped = 1;
    my $id = $canvas->SUPER::createOval(@new_args);
    $coords_mapped = 0;
    return $id;
}

sub createText {
    my $canvas = shift;
    my @new_args = _map_coords($canvas, @_);
    $coords_mapped = 1;
    my $id = $canvas->SUPER::createText(@new_args);
    $coords_mapped = 0;
    return $id;
}

sub createWindow {
    my $canvas = shift;
    my @new_args = _map_coords($canvas, @_);
    $coords_mapped = 1;
    my $id = $canvas->SUPER::createWindow(@new_args);
    $coords_mapped = 0;
    return $id;
}

sub createBitmap {
    my $canvas = shift;
    my @new_args = _map_coords($canvas, @_);
    $coords_mapped = 1;
    my $id = $canvas->SUPER::createBitmap(@new_args);
    $coords_mapped = 0;
    return $id;
}

sub createImage {
    my $canvas = shift;
    my @new_args = _map_coords($canvas, @_);
    $coords_mapped = 1;
    my $id = $canvas->SUPER::createImage(@new_args);
    $coords_mapped = 0;
    return $id;
}

1;

__END__

=head1 NAME

Tk::WorldCanvas - Autoscaling Canvas widget with zoom, viewAll, viewArea, viewFit, and center.

=for category Tk Widget Classes

=head1 SYNOPSIS

    $worldcanvas = $parent->WorldCanvas(?options?);

=head1 DESCRIPTION

This module is a wrapper around the Canvas widget that maps the
user's coordinate system to the now mostly hidden coordinate system of
the Canvas widget.  In world coordinates the y-axis increases in
the upward direction.

I<WorldCanvas> is meant to be a replacement for Canvas.  It's not
quite a "drop in" replacement though because the y-axis is inverted
compared to Canvas.  Usually to convert you will have to invert all
y-coordinates used to create objects.  Typically, you should call
$worldcanvas->viewAll (or $worldcanvas->viewArea(@box)) before calling
MainLoop.

Most of the I<WorldCanvas> methods are the same as the I<Canvas>
methods except that they accept and return world coordinates instead
of widget coordinates.

=head1 INSTALLATION

    Standard method:

    perl Makefile.PL
    make
    make test
    make install

    The last step requires proper permissions.

    Or you can copy the WorldCanvas.pm file to a local directory and
    skip the formalities.

=head1 NEW METHODS

=over 4

=item I<$worldcanvas>->B<zoom>(I<zoom factor>)

Zooms the display by the specified amount.  Example:

    $worldcanvas->CanvasBind('<i>' => sub {$worldcanvas->zoom(1.25)});
    $worldcanvas->CanvasBind('<o>' => sub {$worldcanvas->zoom(0.8)});

    # If you are using the 'Scrolled' constructor as in:
    my $worldcanvas = $main->Scrolled('WorldCanvas', -scrollbars => 'nw', ... )
    # you want to bind the key-presses to the 'worldcanvas' Subwidget of Scrolled.
    my $scrolled_canvas = $worldcanvas->Subwidget('worldcanvas'); # note the lower case 'worldcanvas'
    $scrolled_canvas->CanvasBind('<i>' => sub {$scrolled_canvas->zoom(1.25)});
    $scrolled_canvas->CanvasBind('<o>' => sub {$scrolled_canvas->zoom(0.8)});

    # I don't like the scrollbars taking the focus when I
    # <ctrl>-tab through the windows, so I:
    $worldcanvas->Subwidget('xscrollbar')->configure(-takefocus => 0);
    $worldcanvas->Subwidget('yscrollbar')->configure(-takefocus => 0);


=item I<$worldcanvas>->B<center>(I<x, y>)

Centers the display around world coordinates x, y.
Example:

    $worldcanvas->CanvasBind('<2>' =>
        sub {
            $worldcanvas->CanvasFocus;
            $worldcanvas->center($worldcanvas->eventLocation);
        }
    );


=item I<$worldcanvas>->B<centerTags>([-exact => {0 | 1}], I<TagOrID, [TagOrID, ...]>)

Centers the display around the center of the bounding box
containing the specified TagOrID's without changing the current
magnification of the display.

'-exact => 1' will cause the canvas to be scaled twice to get
an accurate bounding box.  This will be expensive if the canvas
contains a large number of objects.


=item I<$worldcanvas>->B<eventLocation>()

Returns the world coordinates (x, y) of the last Xevent.


=item I<$worldcanvas>->B<panWorld>(I<dx, dy>)

Pans the display by the specified world distances.  B<panWorld>
is not meant to replace the xview/yview panning methods.  Most
user interfaces will want the arrow keys tied to the xview/yview
panning methods (the default bindings), which pan in widget
coordinates.

If you do want to change the arrow key-bindings to pan in world
coordinates using B<panWorld> you must disable the default arrow
key-bindings.

    Example:

    $mainwindow->bind('WorldCanvas',    '<Up>' => "");
    $mainwindow->bind('WorldCanvas',  '<Down>' => "");
    $mainwindow->bind('WorldCanvas',  '<Left>' => "");
    $mainwindow->bind('WorldCanvas', '<Right>' => "");

    $worldcanvas->CanvasBind(   '<Up>' => sub {$worldcanvas->panWorld(0,  100);});
    $worldcanvas->CanvasBind( '<Down>' => sub {$worldcanvas->panWorld(0, -100);});
    $worldcanvas->CanvasBind( '<Left>' => sub {$worldcanvas->panWorld(-100, 0);});
    $worldcanvas->CanvasBind('<Right>' => sub {$worldcanvas->panWorld( 100, 0);});

This is not usually desired, as the percentage of the display that
is shifted will be dependent on the current display magnification.


=item I<$worldcanvas>->B<pixelSize>()

Returns the width (in world coordinates) of a pixel (at the current magnification).


=item I<$worldcanvas>->B<rubberBand>(I<{0|1|2}>)

Creates a rubber banding box that allows the user to graphically
select a region.  B<rubberBand> is called with a step parameter
'0', '1', or '2'.  '0' to start a new box, '1' to stretch the box,
and '2' to finish the box.  When called with '2', the specified
box is returned (x1, y1, x2, y2)

The band color is set with the I<WorldCanvas> option '-bandColor'.
The default color is 'red'

Example, specify a region to delete:

    $worldcanvas->configure(-bandColor => 'purple');
    $worldcanvas->CanvasBind('<3>'               => sub {$worldcanvas->CanvasFocus;
                                                         $worldcanvas->rubberBand(0)
                                                        });
    $worldcanvas->CanvasBind('<B3-Motion>'       => sub {$worldcanvas->rubberBand(1)});
    $worldcanvas->CanvasBind('<ButtonRelease-3>' => sub {my @box = $worldcanvas->rubberBand(2);
                                                         my @ids = $worldcanvas->find('enclosed', @box);
                                                         foreach my $id (@ids) {$worldcanvas->delete($id)}
                                                        });
    # Note: '<B3-ButtonRelease>' will be called for any ButtonRelease!
    # You should use '<ButtonRelease-3>' instead.

    # If you want the rubber band to look smooth during panning and
    # zooming, add rubberBand(1) update calls to the appropriate key-bindings:

    $worldcanvas->CanvasBind(   '<Up>' => sub {$worldcanvas->rubberBand(1);});
    $worldcanvas->CanvasBind( '<Down>' => sub {$worldcanvas->rubberBand(1);});
    $worldcanvas->CanvasBind( '<Left>' => sub {$worldcanvas->rubberBand(1);});
    $worldcanvas->CanvasBind('<Right>' => sub {$worldcanvas->rubberBand(1);});
    $worldcanvas->CanvasBind('<i>' => sub {$worldcanvas->zoom(1.25); $worldcanvas->rubberBand(1);});
    $worldcanvas->CanvasBind('<o>' => sub {$worldcanvas->zoom(0.8);  $worldcanvas->rubberBand(1);});

This box avoids the overhead of bounding box calculations
that can occur if you create your own rubberBand outside of I<WorldCanvas>.


=item I<$worldcanvas>->B<viewAll>([-border => number])

Displays at maximum possible zoom all objects centered in the
I<WorldCanvas>.  The switch '-border' specifies, as a percentage
of the screen, the minimum amount of white space to be left on
the edges of the display.  Default '-border' is 0.02.


=item I<$worldcanvas>->B<viewArea>(x1, y1, x2, y2, [-border => number]))

Displays at maximum possible zoom the specified region centered
in the I<WorldCanvas>.


=item I<$worldcanvas>->B<viewFit>([-border => number], I<TagOrID>, [I<TagOrID>, ...])

Adjusts the worldcanvas to display all of the specified tags.  The '-border'
switch specifies (as a percentage) how much extra surrounding space should be shown.


=item I<$worldcanvas>->B<getView>()

Returns the rectangle of the current view (x1, y1, x2, y2)


=item I<$worldcanvas>->B<widgetx>(I<x>)

=item I<$worldcanvas>->B<widgety>(I<y>)

=item I<$worldcanvas>->B<widgetxy>(I<x, y>)

Convert world coordinates to widget coordinates.


=item I<$worldcanvas>->B<worldx>(I<x>)

=item I<$worldcanvas>->B<worldy>(I<y>)

=item I<$worldcanvas>->B<worldxy>(I<x, y>)

Convert widget coordinates to world coordinates.

=back

=head1 CHANGED METHODS

=over 4

World coordinates are supplied and returned to B<WorldCanvas> methods
instead of widget coordinates unless otherwise specified.  (ie. These
methods take and return world coordinates: center, panWorld, viewArea,
find, coords, scale, move, bbox, rubberBand, eventLocation, pixelSize,
and create*)


=item I<$worldcanvas>->B<bbox>([-exact => {0 | 1}], I<TagOrID>, [I<TagOrID>, ...])

'-exact => 1' is only needed if the TagOrID is not 'all'.  It
will cause the canvas to be scaled twice to get an accurate
bounding box.  This will be expensive if the canvas contains
a large number of objects.

Neither setting of exact will produce exact results because
the underlying canvas bbox method returns a slightly larger box
to insure that everything is contained.  It appears that a number
close to '2' is added or subtracted.  The '-exact => 1' zooms
in to reduce this error.

If the underlying canvas B<bbox> method returns a bounding box
that is small (high error percentage) then '-exact => 1' is done
automatically.


=item I<$worldcanvas>->B<scale>(I<'all', xOrigin, yOrigin, xScale, yScale>)

B<Scale> should not be used to 'zoom' the display in and out as it will
change the world coordinates of the scaled objects.  Methods B<zoom>,
B<viewArea>, and B<viewAll> should be used to change the
scale of the display without affecting the dimensions of the objects.

=back

=head1 VIEW AREA CHANGE CALLBACK

I<Tk::WorldCanvas> option '-changeView' can be used to specify
a callback for a change of the view area.  This is useful for
updating a second worldcanvas which is displaying the view region
of the first worldcanvas.

The callback subroutine will be passed the coordinates of the
displayed box (x1, y1, x2, y2).  These arguments are added after
any extra arguments specifed by the user calling 'configure'.

    Example:

    $worldcanvas->configure(-changeView => [\&changeView, $worldcanvas2]);
    # viewAll if worldcanvas2 widget is resized.
    $worldcanvas2->CanvasBind('<Configure>' => sub {$worldcanvas2->viewAll});

    {
        my $viewBox;
        sub changeView {
            my ($canvas2, @coords) = @_;

            $canvas2->delete($viewBox) if $viewBox;
            $viewBox = $canvas2->createRectangle(@coords, -outline => 'orange');
        }
    }


=head1 SCROLL REGION NOTES

(1) The underlying I<Tk::Canvas> has a '-confine' option which is set
to '1' by default.  With '-confine => 1' the canvas will not allow
the display to go outside of the scroll region causing some methods
to not work accurately.  For example, the 'center' method will not be
able to center on coordinates near to the edge of the scroll region;
'zoom out' near the edge will zoom out and pan towards the center.

I<Tk::WorldCanvas> sets '-confine => 0' by default to avoid these
problems.  You can change it back with:

    $worldcanvas->configure(-confine => 1);


(2) '-scrollregion' is maintained by I<WorldCanvas> to include all
objects on the canvas.  '-scrollregion' will be adjusted automatically
as objects are added, deleted, scaled, moved, etc.  (You can create a
static scrollregion by adding a border rectangle to the canvas.)


(3) The bounding box of all objects is required to set the scroll region.
Calculating this bounding box is expensive if the canvas has a large
number of objects.  So for performance reasons these operations will
not immediately change the bounding box if they potentially shrink it:

    coords
    delete
    move
    scale

Instead they will mark the bounding box as invalid, and it will be
updated at the next zoom or pan operation.  The only downside to this
is that the scrollbars will be incorrect until the update.

If these operations increase the size of the box, changing the box is
trivial and the update is immediate.

=head1 AUTHOR

Joseph Skrovan (I<joseph@skrovan.com>)

Note: based on an earlier implementation by Rudy Albachten (I<rudy@albachten.com>)

If you use and enjoy I<WorldCanvas> please let me know.

=head1 COPYRIGHTS

    Copyright (c) 2002 Joseph Skrovan. All rights reserved.
    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself. 

=cut
