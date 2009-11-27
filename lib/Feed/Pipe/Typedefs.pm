package Feed::Pipe::Typedefs;
use strict;

our $VERSION = '1.0';

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

Kit::Typedefs - Moose Types and coercions 

=head1 SYNOPSIS

    use Kit::Types;

=head1 ABSTRACT

Do not use this module directly. Instead use Kit::Types, which
combines everything here with other more general types into one handy
bundle.

=head1 SEE ALSO

L<Kit::Types>

=head1 COPYRIGHT

Copyright (C)2009 Vincent Veselosky
All rights Reserved

=cut



