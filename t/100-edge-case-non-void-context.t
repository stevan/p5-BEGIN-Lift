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

our $EXCEPTION;
BEGIN {
    eval q{
        my $x = double(10);
        ok(not(defined($x)), '... there is no value for $x');
        1;
    } or do {
        $EXCEPTION = "$@";
    };
    is($EXCEPTION, undef, '... got no error (as expected)');
}

done_testing;

1;
