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
            base => '清华大学学生宿舍',
            ext  => '14号楼',
        },
        '211.99.222.1' => {
            base => '北京市',
            ext  => '世纪互联数据中心',
        },
        2792334959 => {
            base => '清华大学学生宿舍',
            ext  => '14号楼',
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
    like( $qqwry->db_version, qr/纯真网络\d{4}年\d{1,2}月\d{1,2}日IP数据/,
        'db version' );
}

