    use Inline C;
    greet('Ingy');
    greet(42);
    __END__
    __C__
    void greet(SV* sv_name) {
      printf("Hello %s!\n", SvPV(sv_name, PL_na));
    }
