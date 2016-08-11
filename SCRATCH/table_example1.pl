#!/usr/bin/perl

use Tk;
use Tk::TableMatrix::Spreadsheet;

$mw = MainWindow->new;
$mw->configure(-title=>'ID3 Tag Genre and Year Fixer');
$mw->minsize(qw(500 200));
$menu = $mw->Frame()->pack(-side=>'top',-fill=>'x');
$menu_file = $menu->Menubutton(-text=>'File',-tearoff=>'false')->pack(-side=>'left');
$menu_file->command(-label=>'Exit',-command=>sub{$mw->destroy});
$frame = $mw->Frame(-height=>'10',-width=>'30',-relief=>'groove',-borderwidth=>'3')->pack(-fill=>'x',-pady=>'0');

@border = (0,0,0,1);

$arrayVar->{"0,0"} = "%";
$arrayVar->{"0,1"} = "Artist";
$arrayVar->{"0,2"} = "Album";
$arrayVar->{"0,3"} = "Year";
$arrayVar->{"0,4"} = "Genre";
$table = $frame->Scrolled('Spreadsheet',
 -cols => 5,
 -width => 5, -height => 6,
 -titlerows => 1,
 -variable => $arrayVar,
 -selectmode => 'multiple',
 -selecttype => 'row',
 -resizeborders => 'col',
 -bg => 'white',
 -rowheight => 2,
 -bd => \@border,
 -justify => 'left',
 -drawmode => 'compatible',
 -wrap => 0,
 -relief => 'solid'
)->pack(-fill=>'both');
$table->rowHeight(0,1);
$table->tagRow('title',0);
$table->tagConfigure('title', -bd=>2, -relief=>'raised');
$table->colWidth(0,5,3,6,4,10);
MainLoop();
