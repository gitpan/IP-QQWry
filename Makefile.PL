use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'IP::QQWry',
    AUTHOR        => 'sunnavy <sunnavy@gmail.com>',
    VERSION_FROM  => 'lib/IP/QQWry.pm',
    ABSTRACT_FROM => 'lib/IP/QQWry.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'version'        => 0.651,
        'Regexp::Common' => 2.120,
        'Readonly'       => 1.03,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'IP-QQWry-*' },
);
