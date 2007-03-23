package IP::QQWry;

use 5.008;
use warnings;
use strict;
use Carp;
use version; our $VERSION = qv('0.0.11');

sub new {
    my ( $class, $db ) = @_;
    my $self = {};
    bless $self, $class;
    if ($db) {
        $self->set_db($db);
    }
    return $self;
}

# set db file of which the name is `QQWry.Dat' most of the time.
sub set_db {
    my ( $self, $db ) = @_;
    if ( $db && -r $db ) {
        open $self->{fh}, '<', $db or croak "how can this happen? $!";
        $self->_init_db;
        return 1;
    }
    carp 'set_db failed';
    return;
}

sub _init_db {
    my $self = shift;
    read $self->{fh}, $_, 4;
    $self->{first_index} = unpack 'V', $_;
    read $self->{fh}, $_, 4;
    $self->{last_index} = unpack 'V', $_;
}

# sub query is the the interface for user.
# the parameter is a IPv4 address

sub query {
    my ( $self, $ip ) = @_;
    unless ( $self->{fh} ) {
        carp 'database is not provided';
        return;
    }

    if ( $ip =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/ ) {

        # $ip is like '166.111.166.111'
        return $self->_result( $1 * 256**3 + $2 * 256**2 + $3 * 256 + $4 );
    }
    elsif ( $ip =~ /(\d+)/ ) {

        # $ip is an IP integer like 2792334959
        return $self->_result($1);
    }
    return;
}

sub db_version {
    return shift->query('255.255.255.0');    # db version info is held there
}

# get the useful infomation which will be returned to user

sub _result {
    my ( $self, $ip ) = @_;
    my $index = $self->_index($ip);
    return unless $index;    # can't find index

    my ( $base, $ext );
    seek $self->{fh}, $index + 4, 0;
    read $self->{fh}, $_, 3;

    my $offset = unpack 'V', $_ . chr 0;
    seek $self->{fh}, $offset + 4, 0;
    read $self->{fh}, $_, 1;

    my $mode = ord;

    if ( $mode == 1 ) {
        $self->_seek;
        $offset = tell $self->{fh};
        read $self->{fh}, $_, 1;
        $mode = ord;
        if ( $mode == 2 ) {
            $self->_seek;
            $base = $self->_str;
            seek $self->{fh}, $offset + 4, 0;
            $ext = $self->_ext;
        }
        else {
            $base = $self->_str;
            $ext  = $self->_ext;
        }
    }
    elsif ( $mode == 2 ) {
        $self->_seek;
        $base = $self->_str;
        seek $self->{fh}, $offset + 8, 0;
        $ext = $self->_ext;
    }
    else {
        seek $self->{fh}, -1, 1;
        $base = $self->_str;
        $ext  = $self->_ext;
    }

    # 'CZ88.NET' means we don't have useful information
    if ( ( $base . $ext ) =~ m/CZ88\.NET/msx ) {
        return;
    }
    return wantarray ? ( $base, $ext ) : $base . $ext;
}

sub _index {
    my ( $self, $ip ) = @_;
    my $low = 0;
    my $up  = ( $self->{last_index} - $self->{first_index} ) / 7;
    my ( $mid, $ip_start, $ip_end );

    # find the index using binary search
    while ( $low <= $up ) {
        $mid = int( ( $low + $up ) / 2 );
        seek $self->{fh}, $self->{first_index} + $mid * 7, 0;
        read $self->{fh}, $_, 4;
        $ip_start = unpack 'V', $_;

        if ( $ip < $ip_start ) {
            $up = $mid - 1;
        }
        else {
            read $self->{fh}, $_, 3;
            $_ = unpack 'V', $_ . chr 0;
            seek $self->{fh}, $_, 0;
            read $self->{fh}, $_, 4;
            $ip_end = unpack 'V', $_;

            if ( $ip > $ip_end ) {
                $low = $mid + 1;
            }
            else {
                return $self->{first_index} + $mid * 7;
            }
        }
    }

    return;
}

sub _seek {
    my $self = shift;
    read $self->{fh}, $_, 3;
    my $offset = unpack 'V', $_ . chr 0;
    seek $self->{fh}, $offset, 0;
}

# get string ended by \0

sub _str {
    my $self = shift;
    my $str;

    read $self->{fh}, $_, 1;
    while ( ord > 0 ) {
        $str .= $_;
        read $self->{fh}, $_, 1;
    }
    return $str;
}

sub _ext {
    my $self = shift;
    read $self->{fh}, $_, 1;
    my $mode = ord $_;

    if ( $mode == 1 || $mode == 2 ) {
        $self->_seek;
        return $self->_str;
    }
    else {
        return chr($mode) . $self->_str;
    }
}

sub DESTROY {
    my $self = shift;
    close $self->{fh} if $self->{fh};
}

1;

__END__

=head1 NAME

IP::QQWry - a simple interface for QQWry IP database(file).


=head1 VERSION

This document describes IP::QQWry version 0.0.11


=head1 SYNOPSIS

    use IP::QQWry;
    my $qqwry = IP::QQWry->new('QQWry.Dat');
    my $info = $qqwry->query('166.111.166.111');
    my ( $base, $ext ) = $qqwry->query(2792334959);
    my $version = $qqwry->db_version;

=head1 DESCRIPTION


'QQWry.Dat' L<http://www.cz88.net/fox/> is an IP file database.  It provides
some useful infomation such as the geographical position of the host bound
with some IP address, the IP's owner, etc. L<IP::QQWry> provides a simple
interface for this file database.

for more about the format of the database, take a look at this:
L<http://lumaqq.linuxsir.org/article/qqwry_format_detail.html>

Caveat: The 'QQWry.Dat' database uses gbk or big5 encoding, C<IP::QQWry> doesn't
provide any encoding conversion utility, so if you want some other encoding,
you have to do it yourself. (BTW, L<Encode> is a great module for this.)

=head1 INTERFACE

=over 4

=item new

Accept one optional parameter for database file name.
Return an object of L<IP::QQWry>.

=item set_db

Set database file.
Accept a IP database file path as a parameter.
Return 1 for success, undef for failure.

=item query

Accept one parameter, which has to be an IPv4 address such as
`166.111.166.111` or an integer like 2792334959.

In list context, it returns a list containing the base part and the extension
part of infomation, respectively. The base part is usually called the country
part though it doesn't refer to country all the time. The extension part is
usually called the area part.

In scalar context, it returns a string which is just a catenation of the base
and extension parts.

If it can't find useful information, return undef.

Caveat: the domain name as an argument is not supported any more since 0.0.11.
Because a domain name could have more than one IP address bound, the
previous implementation is lame and not graceful, so I dumped it.

=item db_version

return database version.

=back

=head1 DEPENDENCIES

L<version>

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

sunnavy  C<< <sunnavy@gmail.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, 2007, sunnavy C<< <sunnavy@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
