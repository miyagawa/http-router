package Test::HTTP::Router;

use strict;
use warnings;
use Exporter 'import';
use Test::Builder;
use Test::MockObject;

our @EXPORT = qw(path_ok match_ok);

our $Test = Test::Builder->new;

sub request {
    my $args = ref $_[0] ? shift : { @_ };
    my $req = Test::MockObject->new;
    $req->set_always($_ => $args->{$_}) for keys %$args;
    $req;
}

sub path_ok {
    my ($router, $path, $message) = @_;

    my $req = request path => $path;
    $Test->ok($router->match($req) ? 1 : 0, $message);
}

sub match_ok {
    my ($router, $path, $conditions, $message) = @_;

    my $req = request %{ $conditions || {} }, path => $path;
    $Test->ok($router->match($req) ? 1 : 0, $message);
}

1;