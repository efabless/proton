##!/usr/local/bin/perl

use Tk::widgets qw/CollapsableFrame Pane/;

 my $mw = MainWindow->new;

 my $pane = $mw->Scrolled(
      qw/Pane -width 250 -height 50 -scrollbars osow -sticky nw/,
 )->pack;

 my $cf = $pane->CollapsableFrame(-title => 'Frame1 ', -height => 50);
 $cf->pack(qw/-fill x -expand 1/);
 $cf->toggle;

 my $colf = $cf->Subwidget('colf');
 my $but = $colf->Button(-text => 'Close Frame 1!');
 $but->pack;
 $but->bind('<Button-1>' => [sub {$_[1]->close}, $cf]);
