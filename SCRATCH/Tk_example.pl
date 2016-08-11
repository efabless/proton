#!/usr/local/bin/perl -w
    use Tk;
    
    ($c = MainWindow->new->Canvas)->
       pack(-fill => 'both', -expand => 1);
    # to survive under Tk-b8. 
    # You don't need paren before pack in b9.
    
    ($pop1 = $c->Menu)->command(-label => "FOO");
    ($pop2 = $c->Menu)->command(-label => "BAR");
    
    $c->create(oval => 0, 0, 100, 100, 
               -fill => 'black', 
               -tags => ['popup']);
    
    $c->Tk::bind($c, '<3>', [\&PopupOnlyThis, $pop1]);
    $c->bind('popup', '<3>', [\&PopupOnlyThis, $pop2]);
    
    sub PopupOnlyThis {
        print "@_\n";
        my($c, $pop) = @_;
    
        # to prevent multiple popup.
        Tk->break if defined $Tk::popup;
    
        my $e = $c->XEvent;
        $pop->Popup($e->X, $e->Y);
        # Tk::Menu::Popup sets $Tk::popup.
    
    }
    MainLoop;
    
    $Tk::popup = undef; # to kill warning.
