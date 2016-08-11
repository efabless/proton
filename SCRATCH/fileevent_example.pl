#!/usr/local/bin/perl -w
    #
    # tktail pathname
    
    use English;
    use Tk;
    
    open(H, "tail -f -n 25 $ARGV[0]|") or die "Nope: $OS_ERROR";
    
    $mw = MainWindow->new;
    $t = $mw->Text(-width => 80, -height => 25, -wrap => 'none');
    $t->pack(-expand => 1);
    $mw->fileevent(H, 'readable', [\&fill_text_widget, $t]);
    MainLoop;
    
    sub fill_text_widget {
    
        my($widget) = @ARG;
    
        $ARG = <H>;
        $widget->insert('end', $ARG);
        $widget->yview('end');
    
    } # end fill_text_widget

