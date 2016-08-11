

   use strict;
   use Tk;
   use Tk::Label;
   use Tk::HList;

   my $mw = MainWindow->new();
   my $label = $mw->Label(-width=>15);
   my $hlist = $mw->HList(
                       -itemtype   => 'text',
                       -separator  => '/',
                       -selectmode => 'single',
                       -browsecmd  => sub {
                                 my $file = shift;
                                 $label->configure(-text=>$file);
                              }
                       );

   foreach ( qw(/ /home /home/ioi /home/foo /usr /usr/lib) ) {
       $hlist->add($_, -text=>$_);
   }

   $hlist->pack;
   $label->pack;

   MainLoop;
