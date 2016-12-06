#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('BEGIN::Lift');

    BEGIN::Lift::install(
        ('main', 'double') => sub { $_[0] * 2 }
    );
}

# So to be totally honest, I would like something
# like this to work, but it doesn't, so I would
# instead like it to error appropriately, which
# it doesn't, but this is a test we can tweak for
# when it actually does.

our $EXCEPTION;

BEGIN {
    eval q{
        my $x = double(10);
        1;
    } or do {
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
