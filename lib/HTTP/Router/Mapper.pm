package HTTP::Router::Mapper;

use strict;
use warnings;
use base 'Class::Accessor::Fast';
use Carp 'croak';
use Hash::Merge 'merge';
use HTTP::Router::Route;

__PACKAGE__->mk_ro_accessors('router');
__PACKAGE__->mk_accessors(qw'path params conditions route');

sub new {
    my ($class, $args) = @_;

    $args->{path}       ||= '';
    $args->{params}     ||= {};
    $args->{conditions} ||= {};

    return bless $args, $class;
}

sub _clone_mapper {
    my ($self, %params) = @_;

    for my $key (qw'path params conditions') {
        $params{$key} = $self->$key unless exists $params{$key};
    }

    my $class = ref $self || $self;
    return $class->new({ %params, router => $self->router });
}

sub _freeze_route {
    my $self = shift;

    my $route = HTTP::Router::Route->new({
        path       => $self->path,
        params     => $self->params,
        conditions => $self->conditions,
    });

    $self->router->add_route($route);
    $self->route($route);

    return $self;
}

sub match {
    my $self = shift;
    croak 'route has already been committed' if $self->route;

    # TODO: parameterize
    my $block = ref $_[-1] eq 'CODE' ? pop : undef;
    my ($path, $conditions) = @_;
    croak '$path or $conditions is required' unless $path or $conditions;

    my %extra = (
        $path       ? (path       => $self->path . $path)                   : (),
        $conditions ? (conditions => merge($conditions, $self->conditions)) : (),
    );
    my $mapper = $self->_clone_mapper(%extra);

    if ($block) {
        local $_ = $mapper;
        $block->($_);
    }

    return $mapper;
}

sub to {
    my $self = shift;
    croak 'route has already been committed' if $self->route;

    # TODO: parameterize
    my $block = ref $_[-1] eq 'CODE' ? pop : undef;
    my $params = shift;
    croak '$params is required' unless $params;

    $self->params(merge($params, $self->params));

    if ($block) {
        local $_ = $self;
        $block->($_);
    }
    else {
        $self->_freeze_route;
    }

    return $self;
}

sub with { 
    my $self = shift;
    croak 'route has already been committed' if $self->route;

    # TODO: parameterize
    my $block = ref $_[-1] eq 'CODE' ? pop : undef;
    my $params = shift;
    croak '$params and $block are required' unless $params and $block;

    local $_ = $self->_clone_mapper(params => merge($params, $self->params));
    $block->($_);

    return $_;
}

sub register {
    my $self = shift;
    croak 'route has already been committed' if $self->route;
    return $self->_freeze_route;
}

# TODO: not implemented yet
#sub namespace {}
#sub name {}

1;

=for stopwords params

=head1 NAME

HTTP::Router::Mapper

=head1 SYNOPSIS

  my $router = HTTP::Router->define(sub {
      $_->match('/index.{format}')
          ->to({ controller => 'Root', action => 'index' });

      $_->match('/archives/{year}', { year => qr/\d{4}/ })
          ->to({ controller => 'Archive', action => 'by_month' });

      $_->match('/account/login', { method => ['GET', 'POST'] })
          ->to({ controller => 'Account', action => 'login' });

      $_->with({ controller => 'Account' }, sub {
          $_->match('/account/signup')->to({ action => 'signup' });
          $_->match('/account/logout')->to({ action => 'logout' });
      });

      $_->match('/')->register;
  });

=head1 METHODS

=head2 match($path?, $conditions?, $block?)

=head2 to($params, $block?)

=head2 with($params, $block)

=head2 register

=head1 PROPERTIES

=head2 path

=head2 conditions

=head2 params

=head2 route

=head2 router

=head1 AUTHOR

NAKAGAWA Masaki E<lt>masaki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::Router>, L<HTTP::Router::Route>

=cut
