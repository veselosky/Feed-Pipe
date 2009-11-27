#!/usr/bin/perl
use strict;
use Test::More tests =>
9;
use FindBin;
use Path::Class;
use Log::Log4perl qw(:easy);
use Log::Any::Adapter;
Log::Log4perl->easy_init($DEBUG);
Log::Any::Adapter->set('Log4perl');
my $logger = Log::Any->get_logger;

use_ok('Feed::Pipe');

my @feeds = 
( file($FindBin::Bin, 'atom1.atom')->stringify # valid atom feed
, file($FindBin::Bin, 'rss1.xml')->stringify # RSS 1 from delicious
, file($FindBin::Bin, 'rss2wp.xml')->stringify # RSS 2 from Wordpress
);

my $feed = Feed::Pipe->new(title => 'Test Feed')
    ->cat(@feeds)
    ->sort
;
$feed->title("Test Feed");

is $feed->count, 10, 'total entries';

my ($first) = $feed->entries;
#is $first->published, '2009-11-14T20:25:01Z', 'sorted most recent first';
is $first->published, '2009-11-18T03:48:04Z', 'sorted most recent first';
diag join "\n", map { $_->updated||$_->published } $feed->entries;

$feed->tail(7);
($first) = $feed->entries;
is $feed->count, 7, 'tail removes entries';
is $first->published, '2009-11-12T20:47:42Z', 'tail pulls from tail';

$feed->head(6);
($first) = $feed->entries;
is $feed->count, 6, 'head removes entries';
is $first->published, '2009-11-12T20:47:42Z', 'head pulls from head';
diag join "\n", map { $_->updated||$_->published } $feed->entries;

my $xml = $feed->as_xml;
my $atom = XML::Atom::Feed->new(\$xml);
isa_ok($atom, 'XML::Atom::Feed', 'round trip serialization appears to work,');
is $atom->title, 'Test Feed', 'title set and preserved';