package Feed::Pipe::Typedefs;
use strict;

our $VERSION = '1.003';

use DateTime;
use DateTime::Locale;
use DateTime::TimeZone;
use DateTime::Format::HTTP;
use XML::Atom::Feed;

use MooseX::Types -declare => [qw( AtomEntry AtomFeed Datetime Timezone Uri )];
use MooseX::Types::Moose qw/ArrayRef FileHandle HashRef Num ScalarRef Str/;

class_type AtomFeed, {class => 'XML::Atom::Feed'};
class_type AtomEntry, {class => 'XML::Atom::Entry'};
class_type Datetime, {class => "DateTime"};
class_type Timezone, {class => "DateTime::TimeZone"};
class_type Uri, {class => "URI"};

# Feed constructor is pretty flexible
coerce AtomFeed,
    from ScalarRef, via { XML::Atom::Feed->new($_) },
    from Str, via { XML::Atom::Feed->new($_) },
    from FileHandle, via { XML::Atom::Feed->new($_) },
    from Uri, via { XML::Atom::Feed->new($_) },
    ;
coerce Datetime,
    from Num, via { DateTime->from_epoch( epoch => $_ ) },
    from HashRef, via { DateTime->new( %$_ ) },
    from Str, via { DateTime::Format::HTTP->parse_datetime($_) },
    ;
coerce Timezone,
    from Str, via { DateTime::TimeZone->new( name => $_ ) },
    ;

# optionally add Getopt option type
eval { require MooseX::Getopt; };
if ( !$@ ) {
    MooseX::Getopt::OptionTypeMap->add_option_type_to_map( $_, '=s', )
        for ( Datetime, Timezone );
}

1;
__END__

=head1 NAME

Feed::Pipe::Typedefs - Moose Types and coercions for Feed::Pipe

=head1 SYNOPSIS

    use Feed::Pipe::Typedefs qw(AtomEntry AtomFeed);

=head1 ABSTRACT

Note: This is just a support library. You should never need to use it
yourself, but it's documented for your curiosity anyway.

You probably do not want use this module directly. Instead use
L<Feed::Pipe::Types>, which combines everything here with other more
general types into one handy bundle.

=head1 TYPES AND COERCIONS

This module exports the following types and coercions.

=head2 AtomEntry

A class type of XML::Atom::Entry, with no declared coercions.

=head2 AtomFeed

A class type of XML::Atom::Feed, with declared coercions from ScalarRef,
Str, FileHandle, and Uri.

=head2 Datetime

A class type of DateTime, with declared coercions from Num, HashRef,
and Str. Note: you may want to use L<MooseX::Types::DateTime> instead.
I did not, because A) I don't like type constraint names being identical
to class names when conversions are declared, and B) I wanted some custom 
coercions that may not be suitable for all applications, namely, coercion
from Str using L<DateTime::Format::HTTP>.

=head2 Timezone

A class type of DateTime::TimeZone, with declared coercions from Str. Just
for completeness to complement Datetime.

=head2 Uri

A class type of URI, with no declared coercions. See L<MooseX::Types::URI>
if you need coercions.

=head1 SEE ALSO

L<Feed::Pipe::Types>, L<MooseX::Types::DateTime>, L<MooseX::Types::ISO8601>,
L<DateTime::Format::HTTP>, L<MooseX::Types::URI>

=head1 AUTHOR

Vince Veselosky, C<< <vince at control-escape.com> >>

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



