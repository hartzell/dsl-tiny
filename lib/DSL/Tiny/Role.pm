package DSL::Tiny::Role;

use Moo::Role;

use Sub::Exporter -setup => { groups => { install_dsl => \&dsl_build } };

use Data::OptList;
use MooX::Types::MooseLike::Base qw(ArrayRef);
use Sub::Exporter::Util qw(curry_method);

=attr dsl_keywords

Returns an arrayref of dsl keyword info.

It is lazy.  Classes which consume the role are required to supply a builder
named C<_build_dsl_keywords>.

=requires _build_dsl_keywords

A subroutine (used as the Moo{,se} builder for the L</dsl_keywords> attribute)
that returns an array reference containing information about the methods that
should be used as keywords in the DSL.

In its canonical form the contents of the array reference are a series of array
references containing method_name => { option_hash } pairs, e.g.

  [ [ m1 => { as => kw1 } ], [ m2 => { as => kw2 ] ]

However, as the contents of this array reference are processed with
Data::OptList there is a great deal of flexibility.

  [ qw( m1 m2 ), m4 => { as => kw4 } ]

is equivalent to:

  [ m1 => undef, m2 => undef, m4 => { as => kw4 } ]

Options are optional, currently the only supported option is "as", to
explicitly associate a keyword name with a method name.

=cut

has dsl_keywords => (
    is      => 'rw',
    isa     => ArrayRef,
    lazy    => 1,
    builder => 1,

    #    trigger => sub { $_[0]->clear__instance_evalator },
);

requires qw(_build_dsl_keywords);

sub dsl_build {
    my ( $invocant, $group, $arg ) = @_;

    my $instance = ref $invocant ? $invocant : $invocant->new();

    my $keywords = Data::OptList::mkopt_hash( $instance->dsl_keywords,
        { moniker => 'keyword list' }, ['HASH'], );

    my %dsl = map { $_ => $instance->compile_keyword( $_, $keywords->{$_} ) }
        keys $keywords;

    return \%dsl;
}

sub compile_keyword {
    my ( $self, $keyword, $args ) = @_;

    my $generator        = $args->{as} || curry_method($keyword);
    my $before_generator = $args->{before};
    my $after_generator  = $args->{after};

    my $before_code = $before_generator ? $before_generator->($self) : undef;
    my $code        = $generator->($self);
    my $after_code  = $after_generator ? $after_generator->($self) : undef;

    if ( $before_code or $after_code ) {
        my $new_code = sub {
            my @rval;

            $before_code->(@_) if $before_code;

            # Cribbed from $Class::MOP::Method::Wrapped::_build_wrapped_method
            # not sure that it doesn't have more parens then necessary, but...
            (   ( defined wantarray )
                ? (   (wantarray)
                    ? ( @rval = $code->(@_) )
                    : ( $rval[0] = $code->(@_) )
                    )
                : $code->(@_)
            );

            $after_code->(@_) if $after_code;

            return unless defined wantarray;
            return wantarray ? @rval : $rval[0];
        };
        return $new_code;
    }
    return $code;
}

1;
