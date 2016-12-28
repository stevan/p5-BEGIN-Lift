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
        sub { $handler->( $_[0] ? $_[0]->() : () ) }
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

This module serves a very specific purpose, which is to provide a 
mechanism through which we can "lift" a given subroutine to be 
executed entirely within the C<BEGIN> phase of the Perl compiler
and to leave no trace of itself in the C<RUN> phase.

=head1 CAVEAT

Ideally we can (eventually) detect these situations and error 
accordingly so that this is no longer a burden to the user of this 
module, but instead just part of the normal operation of it.

=head2 Non-void context

If, for instance, a lifted sub is called such that the return value
is to be assigned to a variable, such as:

    my $x = my_lifted_sub();

It will not behave as expected, since C<my_lifted_sub> is evaluated 
entirely at C<BEGIN> time, the resulting value for C<$x> at C<RUN> 
time is C<undef>. 

=head2 Expression context

If, for instance, a lifted sub is called within an expression where
the return value is important, such as:

    if ( my_lifted_sub() && 10 ) { ... }

It will not behave as expected, since C<my_lifted_sub> is evaluated 
entirely at C<BEGIN> time and has the value of C<undef> at runtime, 
the conditional will always fail. 

=head2 Statement modifier context

If, for instance, a lifted sub call is guarded by a statement modifier, 
such as:

    my_lifted_sub() if 0;

It will not behave as expected, since the lifted sub call is evaluated 
entirely at C<BEGIN> time the statement modifier has no affect at all
and <my_lifted_sub> will always be executed. 

=cut


