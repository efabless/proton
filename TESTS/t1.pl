#!/usr/bin/perl
use Tk;
#my $top = new MainWindow;
#$top->withdraw;
#
#my $dir = $top->chooseDirectory(-initialdir => '~',
#                                   -title => 'Choose a directory');
#    if (!defined $dir) {
#        warn 'No directory selected';
#    } else {
#        warn "Selected $dir";
#    }

  use Tk::DirSelect;
  my $ds  = $mw->DirSelect();
  my $dir = $ds->Show();
