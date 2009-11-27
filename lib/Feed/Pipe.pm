package Feed::Pipe;
# Housekeeping
use Moose;
use Feed::Pipe::Types qw(ArrayRef AtomEntry AtomFeed Datetime Str Uri);
use Log::Any;

our $VERSION = '0.001';

# Code
use DateTime;
use DateTime::Format::HTTP;
use XML::Feed;
use XML::Atom;
use XML::Atom::Feed;
$XML::Atom::DefaultVersion = 1.0;

#--------------------------------------------------------------------
# ATTRIBUTES
#--------------------------------------------------------------------
# has feed => 
#     ( is => 'rw'
#     , isa => AtomFeed
#     , lazy_build => 1
#     # Note: entries() is handled by _entries below
#     , handles => [qw(as_xml author authors base category categories contributor contributors generator icon lang link links logo rights subtitle )]
#     );
# sub _build_feed { XML::Atom::Feed->new() }

has id => (is => 'rw', isa => Str, lazy_build => 1);
sub _build_id { 
    require Data::UUID; 
    my $gen = Data::UUID->new;
    return 'urn:'.$gen->to_string($gen->create()); 
}

has title => (is => 'rw', isa => Str, default => "Combined Feed");

has updated => (is => 'rw', isa => Datetime, lazy_build => 1, coerce => 1);
sub _build_updated { DateTime->now() }

has _entries => 
    ( is => 'rw'
    , traits => ['Array']
    , isa => ArrayRef[AtomEntry]
    , default => sub {[]}
    , handles =>
        { count => 'count'
        , entries => 'elements'
        , _clear => 'clear'
        , _delete => 'delete'
        , _entry_at => 'accessor'
        , _first => 'first'
        , _get => 'get'
        , _grep => 'grep'
        , _insert => 'insert'
        , _map => 'map'
        , _pop => 'pop'
        , _push => 'push'
        , _shift => 'shift'
        , _shuffle => 'shuffle'
        , _sort_in_place => 'sort_in_place'
        # , _splice => 'splice'
        , _unshift => 'unshift'
        }
    );

#--------------------------------------------------------------------
# FILTER METHODS
#--------------------------------------------------------------------

# FIXME: I really want this to add a <source> element to each entry so it can 
# be traced back to its origin. And to be much more clever. And not to rely
# on XML::Feed.
sub cat {
    my ($proto, @feed_urls) = @_;
    my $self = ref($proto) ? $proto : $proto->new();
    my $logger = Log::Any->get_logger(category => ref($self));
    $logger->debugf('cat: %s', \@feed_urls);
    
    # This is a horrible, terrible HACK. I wish I were smarter.
    # Use XML::Feed to convert from RSS to Atom.
    foreach my $f (@feed_urls) {
        my $feed = XML::Feed->parse($f);
        foreach my $entry ($feed->entries) {
            $self->_push( $entry->convert('Atom')->unwrap );
        }
    }
    return $self; # ALWAYS return $self for chaining!
}

# For the moment we implement only the default date sort. Later we will
# accept arguments that allow sorting by other properties.
sub sort {
    my ($self, $sub) = @_;
    $sub ||= sub { ($_[1]->updated||$_[1]->published) cmp ($_[0]->updated||$_[0]->published) };
    $self->_sort_in_place($sub);
    return $self; # ALWAYS return $self for chaining!
}

sub head {
    my ($self, $limit) = @_;
    $limit ||= 10;
    $self->_entries([splice(@{$self->_entries},0,$limit)]);
    return $self; # ALWAYS return $self for chaining!
}

sub tail {
    my ($self, $limit) = @_;
    $limit ||= 10;
    $self->_entries([splice(@{$self->_entries},-$limit)]);
    return $self; # ALWAYS return $self for chaining! 
}

#--------------------------------------------------------------------
# OTHER METHODS
#--------------------------------------------------------------------

sub as_xml {
    my ($self) = @_;
    my $feed = XML::Atom::Feed->new;
    # FIXME: Add support for (at least) the following elements: author category
    # contributor generator icon link logo rights subtitle
    $feed->title($self->title);
    $feed->id($self->id);
    $feed->updated(DateTime::Format::HTTP->format_isoz($self->updated));
    $feed->add_entry($_) for $self->entries;
    return $feed->as_xml;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

Feed::Pipe - Pipe Atom/RSS feeds through UNIX-style high-level filters

=head1 SYNOPSIS

    # TODO


=head1 DESCRIPTION

B<WARNING: This API is highly unstable. I am still noodling. Do not use this
in production unless your name is Veselosky, or you are willing to refactor
at my whim.>

This module is a Feed model that can mimic the functionality of standard UNIX pipe and filter style text processing tools. Instead of operating on lines from text files, itoperates on entries from Atom (or RSS) feeds. The idea is to provide ahigh-level tool set for combining, filtering, and otherwise manipulating bunchesof Atom data from various feeds.

Yes, you could do this with Yahoo Pipes. Until they decide to take it down, 
or start charging for it. And if your code is guaranteed to have Internet 
access.

Also, you could probably do it with Plagger, if you're genius enough to figure
out how.

=head1 CONSTRUCTOR

To construct a feed pipe, call C<new(%options)>, where C<%options> can include:

=over

=item title

Human readable title of the feed. Defaults to "Combined Feed".

=item id

A string conforming to the definition of an Atom ID. Defaults to a newly
generated UUID.

=item updated

A DateTime object representing when the feed should claim to have been updated.
Defaults to "now".

=back

=head1 FILTER METHODS

=head2 C<cat(@feeds)>

Combine entries from each feed listed, in the order received, into a single feed.
RSS feeds will automatically be converted to Atom before their entries are
added.

Returns the feed itself so that you can chain method calls.

=head2 C<head(Int $limit=10)>

Output C<$limit> entries from the top of the feed, where C<$limit> defaults to
10. If your entries are sorted in standard reverse chronological order, this
will pull the C<$limit> most recent entries.

Returns the feed itself so that you can chain method calls.

=head2 C<sort>

Sort the feed's entries in standard reverse chronological order. Sorry, no 
other sort order is possible in this release, but that is considered a bug 
and will be corrected in the future.

Returns the feed itself so that you can chain method calls.

=head2 C<tail(Int $limit=10)>

Output C<$limit> entries from the end of the feed, where C<$limit> defaults to
10. If your entries are sorted in standard reverse chronological order, this
will pull the C<$limit> oldest entries.

Returns the feed itself so that you can chain method calls.

=head1 OTHER METHODS

B<NOTE: These methods are not filters. They do not return the feed pipe and
must not be used in a filter chain (except maybe at the end).>

=head2 C<as_xml>

Serialize the feed object to an XML (Atom 1.0) string and return the string. 
(Delegated to L<XML::Atom>.)

=head2 C<count>

Returns the number of entries in the feed.

=head2 C<entries>

Returns the list of L<XML::Atom::Entry> objects in the feed.

=head2 C<id>

Returns the id of the feed.

=head2 C<title>

Returns the title of the feed.

=head2 C<updated>

Returns a DateTime object representing the updated time of the feed.

=head1 AUTHOR

Vince Veselosky, C<< <vince at control-escape.com> >>

=head1 BUGS

Oh yeah, there are bugs. Many big nasty ones. In fact, this is just one big
bundle of bugs. Stay away.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Vince Veselosky.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.


=cut

1; # End of Feed::Pipe
