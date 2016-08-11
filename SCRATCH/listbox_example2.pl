#!/usr/local/bin/perl -w
# -*- perl -*-

#
# $Id: listbox_example2.pl,v 1.2 2008/01/24 01:16:00 rajeevs Exp $
# Author: Slaven Rezic
#
# Copyright (C) 1999 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

@listing = (
[qw|drwxrwx--x  3 eserte  eserte  512 29 Nov 23:42 ./            |],
[qw|drwxrwxr-x  6 eserte  eserte  512 29 Nov 23:30 ../           |],
[qw|drwxrwx--x  2 eserte  eserte  512 29 Nov 23:41 RCS/          |],
[qw|-r-xr-xr-x  1 eserte  eserte  507 29 Nov 23:41 basic.pl*     |],
[qw|-rwxrwxr-x  1 eserte  eserte  458 29 Nov 23:41 basic.pl~*    |],
[qw|-rw-r--r--  1 eserte  eserte  871 29 Nov 23:42 hlist.html    |],
[qw|-rw-rw-r--  1 eserte  eserte  220 29 Nov 23:31 hlist.html~   |],
[qw|-rw-rw----  1 eserte  eserte  408 29 Nov 23:42 multicol.pl   |],
);

use Tk;
use Tk::HList;

$top = new MainWindow;

$hlist = $top->Scrolled("HList",
			-scrollbars => "osow",
			-columns => 9)->pack(-expand => 1, -fill => "both");
foreach (@listing) {
    $hlist->add(++$n, -text => $_->[0]);
    foreach my $item (1 .. $#$_) {
	$hlist->itemCreate($n, $item, -text => $_->[$item]);
    }
}

MainLoop;

