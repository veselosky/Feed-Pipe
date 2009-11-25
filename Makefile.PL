use inc::Module::Install;
include 'Module::AutoInstall';

name     'Feed-Pipe';
all_from 'lib/Feed/Pipe.pm';
author   q{Vince Veselosky <vince@control-escape.com>};
license  'mit';

# For Feed::Pipe
requires 'Log::Any', '0.05';
requires 'Moose', '0.92';
requires 'MooseX::Types', '0.19';
requires 'XML::Feed', '0.43';
requires 'XML::Atom', '0.35';


build_requires 'Test::More';

auto_install;

WriteAll;

