package DSL::Tiny::Role;




use Moo::Role;

use Sub::Exporter -setup => { groups => { install_dsl => \&_dsl_build, } };

use Data::OptList;
use MooX::Types::MooseLike::Base qw(ArrayRef);
use Sub::Exporter::Util qw(curry_method);

=attr dsl_keywords

Returns an arrayref of dsl keyword info.

It is lazy.  Classes which consume the role are required to supply a builder
named C<_build_dsl_keywords>.

=cut

has dsl_keywords => (
    is      => 'rw',
    isa     => ArrayRef,
    lazy    => 1,
    builder => 'build_dsl_keywords',
);

=requires build_dsl_keywords

A subroutine (used as the Moo{,se} builder for the L</dsl_keywords> attribute)
that returns an array reference containing information about the methods that
should be used as keywords in the DSL.

In its simplest form, the keyword arrayref contains a list of method names
relative to class which consumes this role.

  [ qw( m1 m2 ) ]

In its canonical form the contents of the array reference are a series of array
references containing keyword_name => { option_hash } pairs, e.g.

  [ [ k1 => { as => &generator } ], [ k2 => { before => &generator ] ]

Generators are as described in the L<Sub::Exporter> documentation.

However, as the contents of this array reference are processed with
Data::OptList there is a great deal of flexibility, e.g.

  [ qw( m1 m2 ), k4 => { as => &generator } ]

is equivalent to:

  [ m1 => undef, m2 => undef, k4 => { as => generator } ]

Supported options include:

=over 4

=item as

=item before

=item after

=back

Options are optional.  If no C<as> generator is provided then the keyword name
is presumed to also be the name of a method in the class and
C<Sub::Exporter::Utils::curry_method> will be applied to it.

=cut

=method _dsl_build

Build's up the set of keywords that L<Sub::Exporter> will install.

If it can be invoked on a class (a.k.a. as a class method), usually by C<use>.
If so, a new instance of the class will be constructed and the various keywords
I<may> be curried with respect to that instance.

If it is invoked on a class instance, usually via an explicit invocation of
L<import> then that instance is used when constructing the keywords.

It uses L<Data::OptList::mkopt_hash> to expand its argument passed in via
C<import>.

It returns a hashref whose keys are names of keywords and whose values are
coderefs implementing the respective behavior.

=cut

sub _dsl_build {
    my ( $invocant, $group, $arg, $col ) = @_;

    my $instance = ref $invocant ? $invocant : $invocant->new();

    my $keywords = Data::OptList::mkopt_hash( $instance->dsl_keywords,
        { moniker => 'keyword list' }, ['HASH'], );

    my %dsl = map { $_ => $instance->_compile_keyword( $_, $keywords->{$_} ) }
        keys $keywords;

    return \%dsl;
}

=method _compile_keyword

=cut

sub _compile_keyword {
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

sub goose_me { }

1;
