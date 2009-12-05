package Feed::Pipe::Types;
use strict;
use base 'MooseX::Types::Combine';
__PACKAGE__->provide_types_from(qw(
    MooseX::Types::Moose 
    Feed::Pipe::Typedefs
));

our $VERSION = '1.002';


1;
__END__

=head1 NAME

Feed::Pipe::Types - Import Moose type constraints used by Feed::Pipe

=head1 SYNOPSIS

    use Moose;
    use Feed::Pipe::Types qw(ArrayRef HashRef Str);
    has aString => (is => 'rw', isa => Str);
    has aFile => (is => 'ro', isa => File, coerce => 1);

=head1 ABSTRACT

Exports Moose type constraints used by L<Feed::Pipe>. This is just a support 
library, you should never need to use it yourself, but it's documented for
your curiosity anyway.

=head1 DESCRIPTION

Makes available for import all types from the following libraries:

=over

=item L<MooseX::Types::Moose>

=item L<Feed::Pipe::Typedefs>

=back

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




