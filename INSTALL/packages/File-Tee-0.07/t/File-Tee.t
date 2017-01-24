#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 50;

use File::Tee qw(tee);

open my $tfh, '>', 't/test_data'
    or die "unable to open test file";
select((select($tfh), $| = 1)[0]);

open my $cfh, '>', 't/test_control'
    or die "unable to open test control file";

open my $cp4fh, '>', 't/test_copy_4';
select((select($cp4fh), $| = 1)[0]);

open my $cp5fh, '>', 't/test_copy_5';
select((select($cp5fh), $| = 1)[0]);

my @cap;

ok(my $pid = tee($tfh, '>', 't/test_copy', 't/test_copy_2',
                 { reopen => 't/test_copy_3' },
                 sub { print $cp4fh $_},
                 { process => sub { push @cap, $_ },
                   end => sub { print $cp5fh @cap } } ));

my $out = '';
my $l = '';
for (0..10) {
    $l = "hello world ($_)\n";
    $out .= $l;
    ok(print($tfh $l), "print $_ t");
    kill INT => $pid;
    ok(print($cfh $l), "print $_ c");
}

for $l ("missing end of line...", "more data...", "end of line\n") {
    chomp (my $l1 = $l);
    ok(print($tfh $l), "missing end of line - $l1");
    ok(print($cfh $l), "missing end of line - $l1 c");
    $out .= $l;
    sleep 3;
    ok(open my $meof, '<', 't/test_data');
    {
        local $/;
        is(scalar(<$meof>), $out);
    }
    close($meof);
}

alarm 10;
ok(close($tfh), "close tfh");
alarm 0;

sleep 3;

ok(open $tfh, '<', 't/test_data');
ok(open $cfh, '<', 't/test_control');
ok(open my $cpfh, '<', 't/test_copy');
ok(open my $cp2fh, '<', 't/test_copy_2');
ok(open my $cp3fh, '<', 't/test_copy_3');
ok(open $cp4fh, '<', 't/test_copy_4');
ok(open $cp5fh, '<', 't/test_copy_5');

{
    local $/;
    is(scalar(<$cfh>), $out, 'output $cfh');
    is(scalar(<$tfh>), $out, 'output $tfh');
    is(scalar(<$cpfh>), $out, 'output $cpfh');
    is(scalar(<$cp2fh>), $out, 'output $cp2fh');
    is(scalar(<$cp3fh>), $out, 'output $cp3fh');
    is(scalar(<$cp4fh>), $out, 'output $cp4fh');
    is(scalar(<$cp5fh>), $out, 'output $cp5fh');
}

END {
    unlink 't/test_data';
    unlink 't/test_control';
    unlink 't/test_copy';
    unlink 't/test_copy_2';
    unlink 't/test_copy_3';
    unlink 't/test_copy_4';
    unlink 't/test_copy_5';
}
