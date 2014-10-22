use strict;
use warnings;
use Test::More qw/no_plan/;

use lib './lib';
use IP::QQWry;

my $qqwry = IP::QQWry->new;
isa_ok( $qqwry, 'IP::QQWry' );

$qqwry = IP::QQWry->new('QQWry.Dat');
isa_ok( $qqwry, 'IP::QQWry' );

SKIP: {
    skip 'have no QQWry.Dat file', 10, unless $qqwry->{fh};

    # these test are for gbk encoding database
    my %info = (
        '166.111.166.111' => {
            base => '�廪��ѧѧ������',
            ext  => '14��¥',
        },
        '211.99.222.1' => {
            base => '������',
            ext  => '���ͻ�����������',
        },
        2792334959 => {
            base => '�廪��ѧѧ������',
            ext  => '14��¥',
        },
    );
    for my $ip ( keys %info ) {
        my ( $base, $ext ) = $qqwry->query($ip);
        is( $base, $info{$ip}->{base}, 'list context query, the base part' );
        is( $ext,  $info{$ip}->{ext},  'list context query, the ext part' );
        my $info = $qqwry->query($ip);
        is( $info,
            $info{$ip}->{base} . $info{$ip}->{ext},
            'scalar context query'
        );
    }
    like( $qqwry->db_version, qr/��������\d{4}��\d{1,2}��\d{1,2}��IP����/,
        'db version' );
}

