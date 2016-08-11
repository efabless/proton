
use Tk;
use Tk::BarberPole;

    $pole = $parent->Tk::BarberPole(
	-width       => 200,
	-length      => 20,
	-bg          => 'white',
        -orientation => 'vertical',
	-colors      => [qw/red blue/],

	-slant       => 38,
        -stripewidth => 15,
        -separation  => 35,

        -delay       => 50,
        -autostart   => 1,
    );

    $pole->start;
    $pole->stop;
