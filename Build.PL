use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Feed::Pipe',
    license             => 'mit',
    dist_author         => q{Vince Veselosky <vince@control-escape.com>},
    dist_version_from   => 'lib/Feed/Pipe.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Feed-Pipe-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
