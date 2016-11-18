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

# NOTE:
# we should likely enforce that the keyword
# has an empty typeglob so that when we delete
# it in the teardown we are not removing
# anything. I did try to just delete the CODE
# slot in the keyword typeglob and it broke
# stuff in weird ways.
# - Sl

sub setup_keyword_handler {
    my ($pkg, $method, $handler) = @_;
    my $cv = eval 'sub { 1 }'; # need to force a new CV each time here
    {
        no strict 'refs';
        *{"${pkg}::${method}"} = $cv;
    }
    BEGIN::Lift::install_keyword_handler(
        $cv, sub {
            my $stmt = BEGIN::Lift::parse_full_statement;
            my $resp = $handler->( $stmt->() );
            $resp = sub {()} unless $resp && ref $resp eq 'CODE';
            return ($resp, 1);
        }
    );
}

sub teardown_keyword_handler {
    my ($pkg, $method) = @_;
    no strict 'refs';
    delete ${"${pkg}::"}{ $method };
}

1;

__END__
