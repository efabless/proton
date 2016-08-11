
use Inline C;
    print JAxH('Perl');
    __END__
    __C__
    SV* JAxH(char* x) {
        return newSVpvf("Just Another %s Hacker\n", x);
    }
