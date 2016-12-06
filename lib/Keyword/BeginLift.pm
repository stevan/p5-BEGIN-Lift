package Keyword::BeginLift;

use strict;
use warnings;

our $VERSION;
our $AUTHORITY;

use Sub::Name ();

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

    Keyword::BeginLift::Util::install_keyword_handler(
        $cv,
        sub {
            # read till the end of the statement ...
            my $stmt = Keyword::BeginLift::Util::parse_full_statement;
            # then execute that callback and pass the
            # result to the handler, this basically
            # evaluates all the arguments, so make
            # sure they are BEGIN time clean
            $handler->( $stmt->() );
            return (sub {}, 1);
        }
    );

    Keyword::BeginLift::Util::install_keyword_cleanup_handler(
        sub {
            no strict 'refs';
            delete ${"${pkg}::"}{$method}
        }
    );
}

1;

__END__

=pod

=head1 NAME

Keyword::BeginLift - Lift subroutine calls into the BEGIN phase

=head1 SYNOPSIS

    package Cariboo;
    use strict;
    use warnings;

    use Keyword::BeginLift;

    sub import {
        my $caller = caller;

        Keyword::BeginLift::install(
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


