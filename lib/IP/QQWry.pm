package IP::QQWry;

use warnings;
use strict;
use Carp;
use Socket;
use version; our $VERSION = qv('0.0.3');

# constructor method

sub new {
    my ( $class, $db ) = @_;
    my $self = {};
    bless $self, $class;
    if ( -r $db ) {
        $self->set_db($db);
    }
    return $self;
}

# set db file whose name is "$path/QQWry.Dat" most of the time.

sub set_db {
    my ( $self, $db ) = @_;
    open $self->{fh}, '<', $db or croak "can not read file $db: $!";

    read $self->{fh}, $_, 4;
    $self->{first_index} = unpack 'V', $_;
    read $self->{fh}, $_, 4;
    $self->{last_index} = unpack 'V', $_;
}

# user use this method to look up IP, which is offered as a parameter.  now it
# just support a string containing one IP address or domain name for
# parameter.

sub query {
    my ( $self, $input )  = @_;
    my $ip    = unpack( 'N', inet_aton($input) ); # convert IP addr to integer
    my $index = $self->_index($ip);
    return 'unknown' unless $index;
    return $self->_result($index);
}

sub _index {
    my ( $self, $ip ) = @_;
    my $low = 0;
    my $up = ( $self->{last_index} - $self->{first_index} ) / 7;
    my ( $mid, $ip_start, $ip_end );

    # find the index for $ip using binary search

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

    return;    # fails, so we return undef
}


# get the useful infomation which will be returned to user

sub _result {
    my ( $self, $index ) = @_;
    my ( $base, $extense );
    seek $self->{fh}, $index + 4, 0;
    read $self->{fh}, $_, 3;

    my $offset = unpack 'V', $_ . chr 0;
    seek $self->{fh}, $offset + 4, 0;
    read $self->{fh}, $_, 1;

    my $mode = ord;

    if ( $mode == 1 ) {
        read $self->{fh}, $_, 3;
        $offset = unpack 'V', $_ . chr 0;

        seek $self->{fh}, $offset, 0;
        read $self->{fh}, $_, 1;
        $mode = ord;
        if ( $mode == 2 ) {
            read $self->{fh}, $_, 3;
            my $base_offset = unpack 'V', $_ . chr 0;
            seek $self->{fh}, $base_offset, 0;
            $base = $self->_str();

            seek $self->{fh}, $offset + 4, 0;
            $extense = $self->_extense();
        }
        else {
            $base    = $self->_str();
            $extense = $self->_extense();
        }

    }
    elsif ( $mode == 2 ) {
        read $self->{fh}, $_, 3;
        my $base_offset = unpack 'V', $_ . chr 0;
        seek $self->{fh}, $base_offset, 0;
        $base = $self->_str();
        seek $self->{fh}, $offset + 8, 0;
        $extense = $self->_extense();
    }
    else {
        seek $self->{fh}, -1, 1;
        $base    = $self->_str();
        $extense = $self->_extense();
    }

    # 'CZ88.NET' means we have not retrieved useful infomation
    if ( ( $base . $extense ) =~ m/CZ88\.NET/msx ) {
        return 'unknown';
    }
    return wantarray ? ( $base, $extense ) : $base . $extense;
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

# get extense part ( area part ) of infomation

sub _extense {

    my $self = shift;

    read $self->{fh}, $_, 1;
    my $mode = $_;

    if ( ord $mode == 1 || ord $mode == 2 ) {
        read $self->{fh}, $_, 3;
        my $extense_offset = unpack 'V', $_ . chr 0;
        seek $self->{fh}, $extense_offset, 0;
        return $self->_str();
    }
    else {
        return $mode . $self->_str();
    }
}

1;

__END__

=head1 NAME

IP::QQWry - look up IP from QQWry database(file).


=head1 VERSION

This document describes IP::QQWry version 0.0.3


=head1 SYNOPSIS

    use IP::QQWry;
    my $qqwry = IP::QQWry->new('~/QQWry.Dat');
    my $info = $qqwry->query('166.111.166.111');
    my $info = $qqwry->query('www.sunnavy.net');

=head1 DESCRIPTION


'QQWry.Dat' L<http://www.cz88.net/fox/> is a file database for IP lookup.  It
provides some useful infomation such as the geographical position of the IP,
who owns the ip, and so on. This Module provides a simple interface for this
database.

for more about the format of the database, take a look at this:
L<http://lumaqq.linuxsir.org/article/qqwry_format_detail.html>

Caveat: The 'QQWry.Dat' database uses gbk encoding, this module doesn't
provide any encoding conversion utility, so if you want some other
encoding, you have to do it yourself. (C<Encode> is a great module which can
help you much.) In addition, the information retrieved from this database is
mostly in Chinese, so maybe it isn't suited for world wide usage, ;-)

=head1 INTERFACE

=over 4

=item new($dbfilename)

Return a new instance of IP::QQWry. You can offer a $dbfilename for parameter
instead of call set_db($dbfilename) method later on.

=item set_db($dbfilename)

Set database file provided by $dbfilename.

=item query($ip)

Query the database for $ip. The $ip can be an actual IPv4 address such as
166.111.166.111 or a domain name.

In list context, it returns a list containing base and extension part of
infomation, respectively. The base part is usually called country part though
it doesn't refer to country all the time. The extension part is usually called
area part.

In scalar context, it returns a string which is just a catenation of base and
extension part of infomation.

=back

=head1 DEPENDENCIES

L<Socket>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

sunnavy  C<< <sunnavy@gmail.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, sunnavy C<< <sunnavy@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
