package Feed::Pipe::Types;
use strict;
use base 'MooseX::Types::Combine';
__PACKAGE__->provide_types_from(qw(
    MooseX::Types::Moose 
    Feed::Pipe::Typedefs
));

our $VERSION = 1.0;


1;
__END__

=head1 NAME

Kit::Types - Import common Moose type constraints

=head1 SYNOPSIS

    use Moose;
    use Kit::Types qw(ArrayRef Datetime Dir File HashRef Str);
    has aString => (is => 'rw', isa => Str);
    has aFile => (is => 'ro', isa => File, coerce => 1);

=head1 ABSTRACT

A one-stop Moose Type shop.

=head1 DESCRIPTION

Makes available for import all types from the following libraries:

=over

=item L<MooseX::Types::Moose>

=item L<MooseX::Types::Path::Class>

=item L<Kit::Typedefs>

=back

=head1 COPYRIGHT

Copyright (C)2009 Vincent Veselosky
All rights Reserved

=cut



