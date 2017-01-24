use ExtUtils::MakeMaker;
my $mmv = $ExtUtils::MakeMaker::VERSION;
require 5.008001;

WriteMakefile(
  'NAME'	     => 'GDS2',
  'DISTNAME'     => 'GDS2',
  'AUTHOR'       => 'SCHUMACK Ken Schumack',
  'VERSION_FROM' => 'lib/GDS2.pm',
  'test'         => { TESTS => 't/*.t' },
  'linkext'      => { LINKTYPE=>'' },
  'dist'         => {'COMPRESS'=>'gzip -9f', 'SUFFIX' => 'gz', 'ZIP'=>'/usr/bin/zip', 'ZIPFLAGS'=>'-rl'},
   (   $mmv < 6.46
        ? ()
        : ( META_MERGE => {
              requires  => {perl => '5.008001'},
              resources => {
                license    => 'http://dev.perl.org/licenses/',
                homepage   => 'https://metacpan.org/module/GDS2',
              },
              no_index => {directory => [qw/t/]},
            },
            META_ADD => {
                build_requires     => {},
                configure_requires => {}
            },
        )
    ),
);

