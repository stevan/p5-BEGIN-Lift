#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('Keyword::BeginLift');

    Keyword::BeginLift::install(
        ('main', 'double') => sub {
            die('Died within (' . (caller(0))[3] . ')');
        }
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
        double(10);
        1;
    } or do {
        $EXCEPTION = "$@";
    };
}

like(
    $EXCEPTION,
    qr/Died within \(main\:\:double\)/,
    '... got the error expected'
);

done_testing;

1;
