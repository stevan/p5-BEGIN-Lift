package BEGIN::Lift;
# ABSTRACT: Lift subroutine calls into the BEGIN phase

use strict;
use warnings;

our $VERSION;
our $AUTHORITY;

use Sub::Name              ();
use B::CompilerPhase::Hook ();

use Devel::CallParser;
use XSLoader;
BEGIN {
    $VERSION   = '0.01';
    $AUTHORITY = 'cpan:STEVAN';
    XSLoader::load( __PACKAGE__, $VERSION );
}

sub install {
    my ($pkg, $method, $handler) = @_;

    die 'Lifted keywords must be created during BEGIN time, not (' . ${^GLOBAL_PHASE}. ')'
        unless ${^GLOBAL_PHASE} eq 'START';

    # need to force a new CV each time here
    my $cv = eval 'sub {}';

    {
        no strict 'refs';

        die "Cannot install the lifted keyword ($method) into package ($pkg) when that typeglob (\*${pkg}::${method}) already exists"
            if exists ${"${pkg}::"}{$method};

        *{"${pkg}::${method}"} = $cv;
    }

    Sub::Name::subname( "${pkg}::${method}", $handler );

    BEGIN::Lift::Util::install_keyword_handler(
        $cv,
        sub {
            # read till the end of the statement ...
            my $stmt = BEGIN::Lift::Util::parse_full_statement;
            # then execute that callback and pass the
            # result to the handler, this basically
            # evaluates all the arguments, so make
            # sure they are BEGIN time clean
            $handler->( $stmt->() );
            return (sub {}, 1);
        }
    );

    B::CompilerPhase::Hook::enqueue_UNITCHECK {
        no strict 'refs';
        delete ${"${pkg}::"}{$method}
    };
}

1;

__END__

=pod

=head1 NAME

BEGIN::Lift - Lift subroutine calls into the BEGIN phase

=head1 SYNOPSIS

    package Cariboo;
    use strict;
    use warnings;

    use BEGIN::Lift;

    sub import {
        my $caller = caller;

        BEGIN::Lift::install(
            ($caller, 'extends') => sub {
                no strict 'refs';
                @{$caller . '::ISA'} = @_;
            }
        );
    }

    package Foo;
    use Cariboo;

    extends 'Bar';

    # functionally equivalent to ...
    # BEGIN { @ISA = ('Bar') }

=head1 DESCRIPTION

=cut


