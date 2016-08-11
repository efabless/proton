#!/bin/perl -w 

    use Tk::DynaTabFrame;

    $TabbedFrame = $widget->DynaTabFrame (
        -font => $font,
        -raisecmd => \&raise_callback,
        -raisecolor => 'green',
        -tabclose => sub { 
                my ($dtf, $caption) = @_; 
                $dtf->delete($caption);
                },
        -tabcolor => 'yellow',
        -tabcurve => 2,
        -tablock => undef,
        -tabpadx => 5,
        -tabpady => 5,
        -tabrotate => 1,
        -tabside => 'nw',
        -tabscroll => undef,
        -textalign => 1,
        -tiptime => 600,
        -tipcolor => 'yellow',
       );
