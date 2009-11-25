#!/usr/bin/perl
use strict;
use Test::More tests =>
1;
use FindBin;
use Path::Class;
use Log::Log4perl qw(:easy);
use Log::Any::Adapter;
Log::Log4perl->easy_init($DEBUG);
Log::Any::Adapter->set('Log4perl');


use_ok('Feed::Pipe');

my $x = Feed::Pipe
    ->cat(file($FindBin::Bin, 'veselosky.xml')->stringify,
          file($FindBin::Bin, 'Webquills.atom')->stringify,
         )
    ->as_xml;
#diag $x;
