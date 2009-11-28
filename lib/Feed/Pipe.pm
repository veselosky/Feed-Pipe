package Feed::Pipe;
# Housekeeping
use Moose;
use Feed::Pipe::Types qw(ArrayRef AtomEntry AtomFeed Datetime Str Uri);
use Log::Any;

our $VERSION = '1.0';

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
    #$logger->debugf('cat: %s', \@feed_urls);
    
    foreach my $f (@feed_urls) {
        if (ref($f) eq 'Feed::Pipe' or ref($f) eq 'XML::Atom::Feed') {
            $logger->debug("Adding a Feed::Pipe or XML::Atom::Feed");
            $self->_push($f->entries);
        } elsif (ref($f) =~ /^XML::Feed/) {
            $logger->debug("Adding a XML::Feed");
            $self->_push( map {$_->convert('Atom')->unwrap} $f->entries );
        } else {
            # Use XML::Feed to convert from RSS to Atom.
            $logger->debug("Using XML::Feed for conversion");
            my $feed = XML::Feed->parse($f);
            $self->_push( map {$_->convert('Atom')->unwrap} $feed->entries );
        }
    }
    return $self; # ALWAYS return $self for chaining!
}

sub sort {
    my ($self, $sub) = @_;
    $sub ||= sub { ($_[1]->updated||$_[1]->published) cmp ($_[0]->updated||$_[0]->published) };
    $self->_sort_in_place($sub);
    return $self; # ALWAYS return $self for chaining!
}

sub reverse {
    my ($self) = @_;
    $self->_entries([reverse $self->entries]);
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

sub grep {
    my ($self, $sub) = @_;
    $sub ||= sub { $_->content||$_->summary };
    $self->_entries([$self->_grep($sub)]);
    return $self; # ALWAYS return $self for chaining!
}

sub map {
    my ($self, $sub) = @_;
    unless ($sub) {
        my $logger = Log::Any->get_logger(category => ref($self));
        my ($package, $file, $line) = caller();
        $logger->warning('Ignoring map() without a code reference at %s:%s',$file,$line);
        warn sprintf('Ignoring map() without a code reference at %s:%s',$file,$line);
        return $self;
    }
    $self->_entries([$self->_map($sub)]);
    return $self; # ALWAYS return $self for chaining!
}


#--------------------------------------------------------------------
# OTHER METHODS
#--------------------------------------------------------------------
sub as_atom_obj {
    my ($self) = @_;
    my $feed = XML::Atom::Feed->new;
    # FIXME: Add support for (at least) the following elements: author category
    # contributor generator icon link logo rights subtitle
    $feed->title($self->title);
    $feed->id($self->id);
    $feed->updated(DateTime::Format::HTTP->format_isoz($self->updated));
    $feed->add_entry($_) for $self->entries;
    return $feed;
}

sub as_xml {
    my ($self) = @_;
    return $self->as_atom_obj->as_xml;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

Feed::Pipe - Pipe Atom/RSS feeds through UNIX-style high-level filters

=head1 SYNOPSIS

    use Feed::Pipe;
    my $pipe = Feed::Pipe
        ->new(title => "Mah Bukkit")
        ->cat( qw(1.xml 2.rss 3.atom) )
        ->grep(sub{$_->title =~ /lolrus/i })
        ->sort
        ->head
        ;
    my $feed = $pipe->as_atom_obj; # returns XML::Atom::Feed
    print $feed->as_xml;

=head1 DESCRIPTION

B<WARNING: This API is still evolving. I am still noodling. Do not use this
in production unless your name is Veselosky, or you are willing to refactor
at my whim.>

This module is a Feed model that can mimic the functionality of standard UNIX pipe and filter style text processing tools. Instead of operating on lines from text files, it operates on entries from Atom (or RSS) feeds. The idea is to provide a high-level tool set for combining, filtering, and otherwise manipulating bunches of Atom data from various feeds.

Yes, you could do this with Yahoo Pipes. Until they decide to take it down, 
or start charging for it. And if your code is guaranteed to have Internet 
access.

Also, you could probably do it with L<Plagger>, if you're genius enough to figure
out how.

=head1 CONSTRUCTOR

To construct a feed pipe, call C<new(%options)>, where the keys of C<%options> 
correspond to any of the method names described under ACCESSOR METHODS. If you 
do not need to set any options, C<cat> may also be called on a class and will
return an instance.

    my $pipe = Feed::Pipe->new(title => 'Test Feed');

=head1 FILTER METHODS

=head2 C<cat(@feeds)>

    my $pipe = Feed::Pipe->new(title => 'Test')->cat(@feeds);
    # This also works:
    my $pipe = Feed::Pipe->cat(@feeds);

Combine entries from each feed listed, in the order received, into a single feed.
RSS feeds will automatically be converted to Atom before their entries are
added. (NOTE: Some data may be lost in the conversion. See L<XML::Feed>.)

If called as a class method, will implicitly call C<new> with no options
to return an instance before adding the passed C<@feeds>.

Values passed to C<cat> may be an instance of Feed::Pipe, XML::Atom::Feed,
XML::Feed, or URI, a reference to a scalar variable containing the XML to
parse, or a filename that contains the XML to parse. URI objects will be 
dereferenced and fetched, and the result parsed.

Returns the feed pipe itself so that you can chain method calls.

=head2 C<grep(sub{})>

Filters the list of entries to those for which the passed function returns
true. If no function is passed, the default is to keep entries which have
C<content> (or a C<summary>). The function should test the entry object 
aliased in C<$_> which will be a L<XML::Atom::Entry>.

    # Keeps all entries with the word "Keep" in the title
    Feed::Pipe->new->cat($feed)->grep( sub { $_->title =~ /Keep/ } );

Returns the feed pipe itself so that you can chain method calls.

=head2 C<head(Int $limit=10)>

Output C<$limit> entries from the top of the feed, where C<$limit> defaults to
10. If your entries are sorted in standard reverse chronological order, this
will pull the C<$limit> most recent entries.

Returns the feed pipe itself so that you can chain method calls.

=head2 C<map(\&mapfunction)>

    # Converts upper CASE to lower case in each entry title.
    my $pipe = Feed::Pipe
    ->cat($feed)
    ->map( sub { $_->title =~ s/CASE/case/; return $_; } )
    ;

Constructs a new list of entries composed of the return values from 
C<mapfunction>. The mapfunc I<must> return one or more XML::Atom::Entry
objects, or an empty list. Within the C<mapfunction> C<$_> will be
aliased to the XML::Atom::Entry it is visiting.

Returns the feed pipe itself so that you can chain method calls.

=head2 C<reverse()>

Returns the feed with entries sorted in the opposite of the input order. This
is just for completeness, you could easily do this with C<sort> instead.

=head2 C<sort(sub{})>

Sort the feed's entries using the comparison function passed as the argument.
If no function is passed, sorts in standard reverse chronological order.
The sort function should be as described in Perl's L<sort>, but using
C<$_[0]> and C<$_[1]> in place of C<$a> and  C<$b>, respectively. The two
arguments will be L<XML::Atom::Entry> objects.

    # Returns a feed with entries sorted by title
    Feed::Pipe->cat($feed)->sort(sub{$_[0]->title cmp $_[1]->title});

Returns the feed pipe itself so that you can chain method calls.

=head2 C<tail(Int $limit=10)>

Output C<$limit> entries from the end of the feed, where C<$limit> defaults to
10. If your entries are sorted in standard reverse chronological order, this
will pull the C<$limit> oldest entries.

Returns the feed pipe itself so that you can chain method calls.

=head1 ACCESSOR METHODS

B<NOTE: These methods are not filters. They do not return the feed pipe and
must not be used in a filter chain (except maybe at the end).>

=head2 title

Human readable title of the feed. Defaults to "Combined Feed".

=head2 id

A string conforming to the definition of an Atom ID. Defaults to a newly
generated UUID.

=head2 updated

A DateTime object representing when the feed should claim to have been updated.
Defaults to "now".

=head1 OTHER METHODS

B<NOTE: These methods are not filters. They do not return the feed pipe and
must not be used in a filter chain (except maybe at the end).>

=head2 C<as_atom_obj>

Returns the L<XML::Atom::Feed> object represented by the feed pipe.

=head2 C<as_xml>

Serialize the feed object to an XML (Atom 1.0) string and return the string. 
Equivalent to calling C<$feed-E<gt>as_atom_obj-E<gt>as_xml>. NOTE: The current
implementation does not guarantee that the resultant output will be valid Atom.
In particular, you are likely to be missing required C<author> and C<link>
elements. For the moment, you should use C<as_atom_obj> and manipulate the
feed-level elements as needed if you require validatable output.

=head2 C<count>

Returns the number of entries in the feed.

=head2 C<entries>

Returns the list of L<XML::Atom::Entry> objects in the feed.

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
