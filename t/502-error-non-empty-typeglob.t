#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('Keyword::BeginLift');
}

sub foo;

our $EXCEPTION;
BEGIN {
    eval {
        Keyword::BeginLift::install(
            ('main', 'foo') => sub { $_[0] * 2 }
        );
        1;
    } or do {
        $EXCEPTION = "$@";
    };
}

like(
    $EXCEPTION,
    qr/Cannot install the lifted keyword \(foo\) into package \(main\) when that typeglob \(\*main\:\:foo\) already exists/,
    '... got the error expected'
);

done_testing;

1;
