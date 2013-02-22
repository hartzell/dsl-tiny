## no critic (RequireUseStrict RequireUseWarnings)
package DSL::Tiny::Role;
## critic
# ABSTRACT: Import a DSL into a package.

=head1 SYNOPSIS

    # in a file that ends up on @INC, e.g. MooseDSL.pm
    # put together class with a simple dsl
    package MooseDSL;
    
    use Moose;  # or use Moo;
    
    with qw(DSL::Tiny::Role);
    
    sub build_dsl_keywords {
        return [
            # simple keyword -> curry_method examples
            qw(argulator return_self clear_call_log),
        ];
    }
    
    has call_log => (
        clearer => 'clear_call_log',
        default => sub { [] },
        is      => 'rw',
        lazy    => 1
    );
    
    sub argulator {
        my $self = shift;
        push @{ $self->call_log }, join "::", @_;
    }
    
    sub return_self { return $_[0] }
    
    1;

    ################################################################

    # and then in another file you can use that DSL

    use Test::More;
    use Test::Deep;
    
    use MooseDSL qw( -install_dsl );
    
    # peek under the covers, get instance
    my $dsl = return_self;
    isa_ok( $dsl, 'MooseDSL' );
    
    # test argument handling, single scalar
    argulator("a scalar");
    cmp_deeply( $dsl->call_log, ['a scalar'], 'scalar arg works' );
    clear_call_log;
    
    # test argument handling, list of args
    argulator(qw(a list of things));
    cmp_deeply( $dsl->call_log, ['a::list::of::things'], 'list arg works' );
    clear_call_log;
    
    done_testing;

=head1 DESCRIPTION

=cut

use Moo::Role;

use Sub::Exporter -setup => { groups => { install_dsl => \&_dsl_build, } };

use Data::OptList;
use MooX::Types::MooseLike::Base qw(ArrayRef);
use Params::Util qw(_ARRAYLIKE);
use Sub::Exporter::Util qw(curry_method);

=method install_dsl

A synonym for the Sub::Exporter generated import method.  Sounds better when
one uses it to install into an instance.

=cut

BEGIN { *install_dsl = \&import; }

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

A subroutine, used as the Moo{,se} builder for the L</dsl_keywords> attribute.
It returns an array reference containing information about the methods and
subroutines that implement the keywords in the DSL.

In its canonical form the contents of the array reference are a series of array
references containing keyword_name => { option_hash } pairs, e.g.

  [ [ k1 => { as => &generator } ], [ k2 => { before => &generator ] ]

Generators are as described in the L<Sub::Exporter> documentation.

However, as the contents of this array reference are processed with
Data::OptList there is a great deal of flexibility, e.g.

  [ qw( m1 m2 ), k4 => { as => &generator } ]

is equivalent to:

  [ m1 => undef, m2 => undef, k4 => { as => generator } ]

In its simplest form, the keyword arrayref contains a list of method names
relative to class which consumes this role.

  [ qw( m1 m2 ) ]

Supported options include:

=over 4

=item as

=item before

=item after

=back

Options are optional.  In particular, if no C<as> generator is provided then
the keyword name is presumed to also be the name of a method in the class and
C<Sub::Exporter::Utils::curry_method> will be applied to that method to
generate the coderef for that keyword.

=cut

=method _dsl_build

C<_dsl_build> build's up the set of keywords that L<Sub::Exporter> will
install.

It returns a hashref whose keys are names of keywords and whose values are
coderefs implementing the respective behavior.

It can be invoked on a class (a.k.a. as a class method), usually by C<use>.  If
so, a new instance of the class will be constructed and the various keywords
are curried with respect to that instance.

It can be invoked on a class instance, e.g. via an explicit invocation of
L<import> on an instance.  If so, then that instance is used when constructing
the keywords.

=cut

sub _dsl_build {
    my ( $invocant, $group, $arg, $col ) = @_;

    # if not already an instance, create one.
    my $instance = ref $invocant ? $invocant : $invocant->new();

    # fluff up the keyword specification
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

    # generate code for keyword
    my $code_generator = $args->{as} || curry_method($keyword);
    my $code = $code_generator->( $self, $keyword );

    # generate before code, if any
    # make sure before is an array ref
    # call each generator (if any), save resulting coderefs
    my $before = $args->{before};
    $before = [$before] unless _ARRAYLIKE($before);
    my @before_code = map { $_->($self) } grep { defined $_ } @{$before};

    # generate after code, if any
    my $after = $args->{after};
    $after = [$after] unless _ARRAYLIKE($after);
    my @after_code = map { $_->($self) } grep { defined $_ } @{$after};

    if ( @before_code or @after_code ) {
        my $new_code = sub {
            my @rval;

            $_->(@_) for @before_code;

            # Cribbed from $Class::MOP::Method::Wrapped::_build_wrapped_method
            # not sure that it doesn't have more parens then necessary, but
            # if it works for them...
            (   ( defined wantarray )
                ? (   (wantarray)
                    ? ( @rval = $code->(@_) )
                    : ( $rval[0] = $code->(@_) )
                    )
                : $code->(@_)
            );

            $_->(@_) for @after_code;

            return unless defined wantarray;
            return wantarray ? @rval : $rval[0];
        };
        return $new_code;
    }

    return $code;
}

1;
