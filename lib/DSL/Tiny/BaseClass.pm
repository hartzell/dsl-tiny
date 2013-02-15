package DSL::Tiny::BaseClass;

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
    die "Must be implemented in subclass";
}

sub compile_keyword {
    my ( $self, $keyword, $args ) = @_;

    my $method = $args->{method} || $keyword;

    return sub { $self->$method(@_) };
}

1;
