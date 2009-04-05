package HTTP::Router;

use 5.008_001;
use strict;
use warnings;
use base 'Class::Accessor::Fast';
use HTTP::Router::Mapper;
use HTTP::Router::RouteSet;

our $VERSION = '0.01';

__PACKAGE__->mk_accessors('routeset');

sub _build_routeset { HTTP::Router::RouteSet->new }

sub routes { @{ shift->routeset->routes } }

sub define {
    my ($self, $block) = @_;

    unless (ref $self) {
        $self = $self->new;
    }
    unless ($self->routeset) {
        $self->routeset($self->_build_routeset);
    }

    if ($block) {
        local $_ = HTTP::Router::Mapper->new(routeset => $self->routeset);
        $block->($_);
    }

    $self;
}

sub reset {
    my $self = shift;
    $self->routeset($self->_build_routeset);
    $self;
}

sub match {
    my ($self, $req) = @_;

    for my $route ($self->routes) {
        next unless my $match = $route->match($req);
        return $match;
    }
}

sub route_for {
    my ($self, $req) = @_;
    my $match = $self->match($req);
    return defined $match ? $match->route : undef;
}

sub show_table {
    my $self = shift;
    require HTTP::Router::Debug;
    HTTP::Router::Debug->show_table( $self->routes );
}

1;

=for stopwords routeset

=head1 NAME

HTTP::Router - Yet Another Path Router for HTTP

=head1 SYNOPSIS

  use HTTP::Router;

  my $router = HTTP::Router->define(sub {
      $_->match('/')->to({ controller => 'Root', action => 'index' });
      $_->match('/index.{format}')->to({ controller => 'Root', action => 'index' });

      $_->match('/archives/{year}/{month}', { year => qr/\d{4}/, month => qr/\d{2}/ })
          ->to({ controller => 'Archive', action => 'by_month' });

      $_->match('/account/login', { method => ['GET', 'POST'] })
          ->to({ controller => 'Account', action => 'login' });

      $_->resources('users');

      $_->resource('account');

      $_->resources('members', sub {
          $_->resources('articles');
      });
  });

  # GET /index.html
  my $match = $router->match($req);
  $match->params;   # { controller => 'Root', action => 'index', format => 'html' }
  $match->captures; # { format => 'html' }

  $match->uri_for({ format => 'xml' }); # '/index.xml'

=head1 DESCRIPTION

HTTP::Router provides a Merb-like way of constructing routing tables.

=head1 METHODS

=head2 new

=head2 define($code)

=head2 reset

=head2 match($req)

=head2 route_for($req)

=head2 show_table

=head1 PROPERTIES

=head2 routeset

=head1 AUTHOR

NAKAGAWA Masaki E<lt>masaki@cpan.orgE<gt>

Takatoshi Kitano E<lt>kitano.tk@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::Router::Mapper>, L<HTTP::Router::Resources>,
L<HTTP::Router::Route>, L<HTTP::Router::Match>,

L<MojoX::Routes>, L<http://merbivore.com/>,
L<HTTPx::Dispatcher>, L<Path::Router>, L<Path::Dispatcher>

=cut
