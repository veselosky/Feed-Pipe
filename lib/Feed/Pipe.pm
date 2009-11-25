package Feed::Pipe;
use Moose;
our $VERSION = '0.001';
use Log::Any;

use XML::Feed;
use XML::Atom;
$XML::Atom::DefaultVersion = 1.0;

has feed => 
    ( is => 'ro'
    , isa => 'XML::Feed'
    , lazy_build => 1
    , handles => [qw(as_xml author category contributor entries generator icon id link logo rights subtitle title updated)]
    );
sub _build_feed { XML::Feed->new('Atom') }

# FIXME: I really want this to add a <source> element to each entry so it can 
# be traced back to its origin. And to be much more clever. And not to rely
# on XML::Feed.
sub cat {
    my ($proto, @feed_urls) = @_;
    my $self = ref($proto) ? $proto : $proto->new();
    
    # This is a horrible, terrible HACK. I wish I were smarter.
    my @feeds = map { my $f = XML::Feed->parse($_); $f->convert('Atom'); $f } @feed_urls;
    $self->feed->splice($_) for @feeds;
    
    return $self; # ALWAYS return $self for chaining!
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

Yes, you could do this with Yahoo Pipes. Until they decide to take it down, or start charging for it. And if your code is guaranteed to have Internet access.

Also, you could probably do it with Plagger, if you're genius enough to figure out how.

=head1 METHODS

=head2 C<as_xml>

Serialize the feed object to an XML string and return the string. If you call
this in a chain, it must be the last thing you do, since it returns a string
and not the pipe itself.

=head2 C<cat(@feeds)>

Effectively the constructor, every pipe begins by calling C<cat> on some list
of feeds. This will combine entries in the order received into a single feed.
Like most methods, returns the pipe itself so that you can chain method calls.


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
