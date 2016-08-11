#!/usr/local/bin/perl -w
# -*- perl -*-

#
# $Id: listbox_example3.pl,v 1.2 2008/01/24 01:16:00 rajeevs Exp $
# Author: Slaven Rezic
#
# Copyright (C) 1999 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

use Tk;
use Tk::HList;

$top = new MainWindow;

$hlist = $top->Scrolled("HList",
			-header => 1,
			-columns => 4,
			-scrollbars => 'osoe',
			-width => 70,
			-selectbackground => 'SeaGreen3',
		       )->pack(-expand => 1, -fill => 'both');

$hlist->header('create', 0, -text => 'From');
$hlist->header('create', 1, -text => 'Subject');
$hlist->header('create', 2, -text => 'Date');
$hlist->header('create', 3, -text => 'Size');

$hlist->add(0);
$hlist->itemCreate(0, 0, -text => "eserte\@cs.tu-berlin.de");
$hlist->itemCreate(0, 1, -text => "Re: HList?");
$hlist->itemCreate(0, 2, -text => "1999-11-20");
$hlist->itemCreate(0, 3, -text => "1432");

$hlist->add(1);
$hlist->itemCreate(1, 0, -text => "dummy\@foo.com");
$hlist->itemCreate(1, 1, -text => "Re: HList?");
$hlist->itemCreate(1, 2, -text => "1999-11-21");
$hlist->itemCreate(1, 3, -text => "2335");

MainLoop;
