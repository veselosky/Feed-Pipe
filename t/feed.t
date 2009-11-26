#!/usr/bin/perl
use strict;
use Test::More tests =>
7;
use FindBin;
use Path::Class;
use Log::Log4perl qw(:easy);
use Log::Any::Adapter;
Log::Log4perl->easy_init($DEBUG);
Log::Any::Adapter->set('Log4perl');
my $logger = Log::Any->get_logger;

use_ok('Feed::Pipe');

my @feeds = 
( file($FindBin::Bin, 'atom1.atom')->stringify
, file($FindBin::Bin, 'rss1.xml')->stringify
);

my $feed = Feed::Pipe
    ->cat(@feeds)
    ->sort
;
$feed->title("Test Feed");

is scalar($feed->entries), 8, 'total entries';

my ($first) = $feed->entries;
is $first->published, '2009-11-14T20:25:01Z', 'sorted most recent first';
diag join "\n", map { $_->updated||$_->published } $feed->entries;

$feed->tail(7);
($first) = $feed->entries;
is scalar($feed->entries), 7, 'tail removes entries';
is $first->published, '2009-11-12T20:47:42Z', 'tail pulls from tail';

$feed->head(6);
($first) = $feed->entries;
is scalar($feed->entries), 6, 'head removes entries';
is $first->published, '2009-11-12T20:47:42Z', 'head pulls from head';
diag join "\n", map { $_->updated||$_->published } $feed->entries;

diag $feed->as_xml;