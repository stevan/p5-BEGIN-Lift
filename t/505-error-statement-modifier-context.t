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

# FIXME:
# This is not actually erroring in a 
# controlled manner, basically we've
# confused the parser, so it breaks. 
# Ideally we improve this so that we 
# detect the error and provide a more
# appropriate error message.
# - SL

our $EXCEPTION;

BEGIN {
    eval q{
        double(10) if 100;
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
