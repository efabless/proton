use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'              => 'File::Data',
    'VERSION_FROM'      => 'lib/File/Data.pm',
    'PREREQ_PM'         => {
        Carp            => 1.3301,
       'Data::Dumper'   => 2.151,
        Fcntl           => 1.11,
        FileHandle      => 2.02,
    },
    'PM'                => { 'lib/File/Data.pm' => '$(INST_LIBDIR)/File/Data.pm' },
);
