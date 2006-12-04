use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'IP::QQWry',
    license             => 'perl',
    dist_author         => 'sunnavy <sunnavy@gmail.com>',
    dist_version_from   => 'lib/IP/QQWry.pm',
    requires => {
        'version'    => 0.651,
    },
    add_to_cleanup      => [ 'IP-QQWry-*' ],
);

$builder->create_build_script();
