

use Tk;
use Tk::Tree;
my $mw = MainWindow->new(-title => 'tree');
my $tree = $mw->Tree->pack(-fill => both, -expand => 1);

foreach (qw/orange orange.red/) {
   $tree->add($_, -text => $_);
}

$tree->autosetmode();
MainLoop;

