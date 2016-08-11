    use Term::TransKeys;

    my $listener = Term::TransKeys->new(
        actions => {
            '<F1>' => sub {
                print "... Do something when the F1 key is pressed \n";
            }
        }
    );

    # Term::Screen is not a requirement, just used in example.
    use Term::Screen;
    my $scr = new Term::Screen;

    $scr->clrscr;
    while ( 1 ) {
        # Place to hold the line of input
        my $line;

        # print the buffer until we have a complete line of input, non-blocking IO, loop at 0.01 interval.
        while ( not defined ($line = $listener->ActionRead( mode => 0.01 ))) {

            # Lets provide a prompt
            my $prompt = "input: ";

            # Print our current position (from right) in the buffer.
            $scr->at( 15, 0 )->clreol->puts( $listener->BufferPosition );
            # Show the prompt as well as the text entered so far.
            $scr->at(10,0)->clreol->puts( "input: " . $listener->BufferString );
            # Move the cursor to the currect position in the text
            $scr->at( 10, $listener->BufferPosition + length( $prompt ));
        }

        # When we have a new completed line:
        #  * Delete the line at the top of the screen, moving other lines up.
        #  * Output the new line at row 9.
        chomp( $line );
        $scr->at(0,0)->dl;
        $scr->at(9,0)->clreol->puts( $line );
        exit(0) if $line eq 'exit';
    }
