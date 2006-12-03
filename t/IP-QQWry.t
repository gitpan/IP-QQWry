use strict;
use warnings;

use Test::More qw/no_plan/;

use lib './lib';

use IP::QQWry;

my $qqwry = IP::QQWry->new('QQWry.Dat');

isa_ok( $qqwry, 'IP::QQWry', '$qqwry is IP::QQWry' );

SKIP: {
    skip 'have no QQWry.Dat file', 6,  unless $qqwry->{fh};

    my $ip = '166.111.166.111';
    my ( $base, $extense ) = $qqwry->query($ip);

    is( $base,    '清华大学学生宿舍', 'the base part is ok' );
    is( $extense, '14号楼',           'the extense part is ok' );

    my $info = $qqwry->query($ip);

    is( $info, '清华大学学生宿舍14号楼', 'the full info is ok' );

    $ip = '211.99.222.1';

    ( $base, $extense ) = $qqwry->query($ip);

    is( $base,    '北京市',           'the base part is ok' );
    is( $extense, '世纪互联数据中心', 'the extense part is ok' );

    $info = $qqwry->query($ip);
    is( $info, '北京市世纪互联数据中心', 'the full info is ok' );

    $info = $qqwry->query('www.sunnavy.net');
    is( $info, '北京市歌华宽带', 'domain name lookup is ok');
}

