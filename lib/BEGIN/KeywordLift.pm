package BEGIN::KeywordLift;

use strict;
use warnings;

our $VERSION;
our $AUTHORITY;

use Devel::GlobalPhase;
use Devel::CallParser;
use XSLoader;
BEGIN {
    $VERSION   = '0.01';
    $AUTHORITY = 'cpan:STEVAN';
    XSLoader::load( __PACKAGE__, $VERSION );
}

sub install {
    my ($pkg, $method, $handler) = @_;

    my $global_phase = Devel::GlobalPhase::global_phase();
    die "Lifted keywords must be created during BEGIN time, not ($global_phase)"
        unless $global_phase eq 'START';

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
    # - SL
    {
        no strict 'refs';
        *{"${pkg}::${method}"} = $cv;
    }

    # XXX:
    # should we do a Sub::Name thing here with $cv?
    # It might not actually be needed, especially
    # if we decide to automatically remove the
    # keywords.
    # - SL

    BEGIN::KeywordLift::Util::install_keyword_handler(
        $cv,
        sub {
            # read till the end of the statement ...
            my $stmt = BEGIN::KeywordLift::Util::parse_full_statement;
            # then execute that callback and pass the
            # result to the handler, this basically
            # evaluates all the arguments, so make
            # sure they are BEGIN time clean
            $handler->( $stmt->() );
            return (sub {}, 1);
        }
    );

    # XXX:
    # Perhaps install a UNITCHECK callback here that will remove
    # the keyword glob from the package, this would serve to
    # enforce the BEGIN time nature of things.
    # - SL
}

1;

__END__

=pod

=head1 NAME

BEGIN::KeywordLift - Lift subroutine calls into the BEGIN phase

=head1 SYNOPSIS

    package Cariboo;
    use strict;
    use warnings;

    use BEGIN::KeywordLift;

    sub import {
        my $caller = caller;

        BEGIN::KeywordLift::install(
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


