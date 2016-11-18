#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

our $TEST;
BEGIN {
	use_ok('BEGIN::Lift');

    $TEST = 0;
    BEGIN::Lift::install(
        ('main', 'test') => sub {
            $TEST = shift @_;
            return;
        }
    );
}

test( 10 );

$TEST++;
is($TEST, 11, '... got the expected value (RUN)');
BEGIN {
    is($TEST, 10, '... got the expected value (BEGIN)');
}

done_testing;

1;
