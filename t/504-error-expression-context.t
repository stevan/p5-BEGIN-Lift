#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('BEGIN::Lift');

    BEGIN::Lift::install(
        ('main', 'double') => sub { 
            use Data::Dumper;
            warn Dumper \@_;
            $_[0] * 2 }
    );
}

our $EXCEPTION;
BEGIN {
    eval q{
        double(10) && 100;
        1;
    } or do {
        warn $@;
        $EXCEPTION = "$@";
    };
}

like(
    $EXCEPTION,
    qr/syntax error/,
    '... got the error expected'
);

done_testing;

1;
