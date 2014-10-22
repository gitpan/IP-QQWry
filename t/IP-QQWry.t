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

    is( $base,    '�廪��ѧѧ������', 'the base part is ok' );
    is( $extense, '14��¥',           'the extense part is ok' );

    my $info = $qqwry->query($ip);

    is( $info, '�廪��ѧѧ������14��¥', 'the full info is ok' );

    $ip = '211.99.222.1';

    ( $base, $extense ) = $qqwry->query($ip);

    is( $base,    '������',           'the base part is ok' );
    is( $extense, '���ͻ�����������', 'the extense part is ok' );

    $info = $qqwry->query($ip);
    is( $info, '���������ͻ�����������', 'the full info is ok' );

    $info = $qqwry->query('www.sunnavy.net');
    is( $info, '�����и軪���', 'domain name lookup is ok');
}

