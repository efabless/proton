     use Tk;
     use Tk::LineGraph;
     use Tk::LineGraphDataset;

     my $mw = MainWindow->new;

     my $cp = $mw->LineGraph(-width=>500, -height=>500, -background => snow)->grid;

     my @yArray = (1..5,11..18,22..23,99..300,333..555,0,0,0,0,600,600,600,600,599,599,599);
     my $ds = LineGraphDataset->new(-yData=>\@yArray,-name=>"setOne");
     $cp->plot(-dataset=>$ds);

     MainLoop;
