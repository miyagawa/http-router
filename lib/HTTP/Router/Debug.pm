package HTTP::Router::Debug;
use Text::SimpleTable;

sub show_table {
    my ( $class, @routes ) = @_;
    $report = $class->_make_table_report(\@routes);
    print $report . "\n";
}

sub _make_table_report {
    my ( $class, $routes ) = @_;
    my $t = Text::SimpleTable->new(
        [ 35, 'path' ],
        [ 10, 'method' ],
        [ 10, 'controller' ],
        [ 10, 'action' ]
    );
    foreach my $route ( @{$routes} ) {
        $t->row(
            $route->path,
            join( ',', @{ $route->conditions->{method} } ),
            $route->params->{controller},
            $route->params->{action}
        );
    }
    my $header = 'Routing Table:' . "\n";
    my $table = $t->draw;
    $header . $table . "\n";
}

1;
