package DSL::Tiny::Class;

use Moo;

use Sub::Exporter -setup => { groups => { install_dsl => \&dsl_build } };

use Data::OptList;

sub dsl_build {
    my ( $invocant, $group, $arg ) = @_;

    my $instance = ref $invocant ? $invocant : $invocant->new();

    my $keywords = Data::OptList::mkopt_hash( $instance->dsl_keywords,
        { moniker => 'keyword list' }, ['HASH'], );

    my %dsl = map { $_ => $instance->compile_keyword( $_, $keywords->{$_} ) }
        keys $keywords;

    return \%dsl;
}

sub dsl_keywords {
    return [ qw(ape incr site value), baz => { method => 'bar' } ];
}

sub compile_keyword {
    my ( $self, $keyword, $args ) = @_;

    my $method = $args->{method} || $keyword;

    return sub { $self->$method(@_) };
}

has counter => ( is => 'rw', default => sub {0}, );

sub ape { return "DSL sez: ape" }

sub bar { return $_[0] }

sub incr { $_[0]->counter( $_[0]->counter() + 1 ) }

sub site { return "DSL sez: site" }

sub value { $_[0]->counter }

1;
