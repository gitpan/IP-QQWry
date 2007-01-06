package IP::QQWry;

use 5.008;
use warnings;
use strict;
use Carp;
use Socket;
use Regexp::Common qw /net/;

use version; our $VERSION = qv('0.0.10');

sub new {
    my ( $class, $db ) = @_;
    my $self = {};
    bless $self, $class;
    if ( $db && -r $db ) {
        $self->set_db($db);
    }
    return $self;
}

# set db file whose name is "PATH/QQWry.Dat" most of the time.
sub set_db {
    my ( $self, $db ) = @_;
    open $self->{fh}, '<', $db or croak "can not read file $db: $!";
    $self->_init_db();
}

sub _init_db {
    my $self = shift;
    read $self->{fh}, $_, 4;
    $self->{first_index} = unpack 'V', $_;
    read $self->{fh}, $_, 4;
    $self->{last_index} = unpack 'V', $_;
}

# query is the the interface for user.
# the parameter is a IPv4 address or a domain name.

sub query {
    my $self = shift;
    croak 'database is not provided' unless $self->{fh};
    my $ip = $self->_convert_input(shift);
    my $index = $self->_index($ip);
    return unless $index;             # return undef if can't find index
    return $self->_result($index);
}

sub db_version {
    return shift->query('255.255.255.0');
}

sub _convert_input {

    my ( $self, $input ) = @_;

    if ( $input =~ /^[.\d\s]*$/msx && $input !~ /$RE{net}{IPv4}/msx ) {
        croak 'wrong IPv4 address input';
    }
    my $str = inet_aton($input);    # convert input to an opaque string
    croak 'wrong input' unless $str;

    return unpack( 'N', $str );    # convert string to integer
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
        return;    # return undef if we get useless infomation
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

sub DESTROY {
    my $self = shift;
    close $self->{fh} if $self->{fh};
}

1;

__END__

=head1 NAME

IP::QQWry - a simple interface for QQWry IP database(file).


=head1 VERSION

This document describes IP::QQWry version 0.0.10


=head1 SYNOPSIS

    use IP::QQWry;
    my $qqwry = IP::QQWry->new('QQWry.Dat');
    my $info = $qqwry->query('166.111.166.111');
    my $info = $qqwry->query('www.perl.org');
    my $version = $qqwry->db_version();

=head1 DESCRIPTION


'QQWry.Dat' L<http://www.cz88.net/fox/> is a IP file database.  It provides
some useful infomation such as the geographical position of the host binded
with the queried IP, the IP's owner, etc. C<IP::QQWry> provides a simple
interface for this file database.

for more about the format of the database, take a look at this:
L<http://lumaqq.linuxsir.org/article/qqwry_format_detail.html>

Caveat: The 'QQWry.Dat' database uses gbk encoding, C<IP::QQWry> doesn't
provide any encoding conversion utility, so if you want some other encoding,
you have to do it yourself. (C<Encode> is a great module which can help you
much, ;-)

=head1 INTERFACE

=over 4

=item new

Accept one optional parameter for database file name.
Return an object of IP::QQWry.

=item set_db

Set database file.
Accept one parameter for database file name.

=item query

Accept one parameter, which can be an IPv4 address such as 166.11.166.111 or a
domain name.

In list context, it returns a list containing the base part and the extension
part of infomation, respectively. The base part is usually called the country
part though it doesn't refer to country all the time. The extension part is
usually called the area part.

In scalar context, it returns a string which is just a catenation of the base
and extension parts.

Caveat: Although query indeed do some validation for your input, it's a naive
one at least now. Maybe you want to do it yourself for better validation.


=item db_version

return database version.

=back

=head1 DEPENDENCIES

L<Socket>, L<Regexp::Common>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

sunnavy  C<< <sunnavy@gmail.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, 2007, sunnavy C<< <sunnavy@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
