

use File::Stat qw/:stat/;

$base_path = $ARGV[0];

process_files ($base_path);


# Accepts one argument: the full path to a directory.
# Returns: A list of files that reside in that path.
sub process_files {
    my $path = shift;
    print "starting at $path\n";

    opendir (DIR, $path)
        or die "Unable to open $path: $!";

    # We are just chaining the grep and map from
    # the previous example.
    # You'll see this often, so pay attention ;)
    # This is the same as:
    # LIST = map(EXP, grep(EXP, readdir()))
    my @files =
        # Third: Prepend the full path
        map { $path . '/' . $_ }
        # Second: take out '.' and '..'
        grep { !/^\.{1,2}$/ }
        # First: get all files
        readdir (DIR);

    closedir (DIR);

    for (@files) {
        if (-d $_) {
            # Add all of the new files from this directory
            # (and its subdirectories, and so on... if any)
            push @files, process_files ($_);

        } else {
            # Do whatever you want here =) .. if anything.
        print "file $_\n";
        $stats = stat($_);
        my $time = $stats->[9];
        my $user = $stats->[4];
        print "$user $time\n";;
        }
    }
    # NOTE: we're returning the list of files
    return @files;
#    print "@files\n";
          
}
