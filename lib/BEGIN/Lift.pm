package BEGIN::Lift;

use strict;
use warnings;

our $VERSION;
our $AUTHORITY;

use Devel::CallParser;
use XSLoader;
BEGIN {
    $VERSION   = '0.01';
    $AUTHORITY = 'cpan:STEVAN';
    XSLoader::load( __PACKAGE__, $VERSION );
}

sub install {
    my ($pkg, $method, $handler) = @_;

    # need to force a new CV each time here
    my $cv = eval 'sub {}';

    # NOTE:
    # if we want to be able to easily delete
    # an installed method in a teardown scenario
    # then we will likely need to enforce that
    # the keyword has an empty typeglob. When
    # I did try to just delete the CODE slot in
    # the keyword typeglob, stuff broke in
    # weird ways.
    # - Sl
    {
        no strict 'refs';
        *{"${pkg}::${method}"} = $cv;
    }

    BEGIN::Lift::Util::install_keyword_handler(
        $cv, sub {
            # read till the end of the statement ...
            my $stmt = BEGIN::Lift::Util::parse_full_statement;
            # then execute that callback and pass the
            # result to the handler, this basically
            # evaluates all the arguments, so make
            # sure they are BEGIN time clean
            my $resp = $handler->( $stmt->() );
            $resp = sub {()} unless $resp && ref $resp eq 'CODE';
            return ($resp, 1);
        }
    );
}

1;

__END__

=pod

=head1 NAME

BEGIN::Lift - Lift subroutine calls into the BEGIN phase

=head1 SYNOPSIS

    package My::OO::Module;
    use strict;
    use warnings;

    use BEGIN::Lift;

    sub import {
        my ($class, @args) = @_;

        my $caller = caller;

        BEGIN::Lift::install(
            ($caller, 'extends') => sub {
                my @isa = @_;
                no strict 'refs';
                @{$caller . '::ISA'} = @isa;
                return;
            }
        );
    }

    package Foo;
    use My::OO::Module;

    extends 'Bar';

    # functionally equivalent to ...
    # BEGIN { @ISA = ('Bar') }

=head1 DESCRIPTION

=cut


