## no critic (TestingAndDebugging::RequireUseStrict)
package DSL::Tiny::Role;
## critic

# ABSTRACT: Import a DSL into a package.

=head1 SYNOPSIS

    # in e.g. MyDSL.pm
    # put together class with a simple dsl
    package MyDSL;
    
    use Moo;
    
    with qw(DSL::Tiny::Role);
    
    use MyDelegate;
    use Sub::Exporter::Util qw(curry_chain curry_method);
    
    sub build_dsl_keywords {
        return [
            qw(callme incr),
            break_encapsulation => { as => curry_method('return_self'), },
            beep                => {
                as    => curry_chain( delegate => 'beep' ),
                after => curry_method('do_it_after'),
            },
            value => { before => curry_method('do_it_before'), },
        ];
    }
    
    has before_counter => ( is => 'rw', default => sub {0}, );
    has counter        => ( is => 'rw', default => sub {0}, );
    has after_counter  => ( is => 'rw', default => sub {0}, );
    
    sub do_it_before {
        my $self = shift;
        my $i    = $self->before_counter() + 1;
        $self->before_counter($i);
    }
    
    sub do_it_after {
        my $self = shift;
        my $i    = $self->after_counter() + 1;
        $self->after_counter($i);
    }
    
    sub callme { return "sometime..." }
    
    sub return_self { return $_[0] }
    
    sub delegate { return MyDelegate->new() }
    
    sub incr { $_[0]->counter( $_[0]->counter() + 1 ) }
    
    sub value { $_[0]->counter }
    
    1;
    
    ################################################################

    # and then in another package

    use MyDSL;

    use Test::More;

    is(value, 0, "Got the correct value");
    incr;
    incr;
    is(value, 2, "Got the correct value");

    is(callme, "sometime...", "Got the right response");

    # etc....
    done_testing;

=head1 DESCRIPTION

=cut

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

    my %dsl = map {
        $_ => $instance->_compile_keyword( $_,
            $keywords->{$_} )    ## no critic (ProhibitAccessOfPrivateData)
        }
        keys $keywords;

    return \%dsl;
}

=method _compile_keyword

=cut

sub _compile_keyword {
    my ( $self, $keyword, $args ) = @_;

    my $generator = $args->{as}    ## no critic (ProhibitAccessOfPrivateData)
        || curry_method($keyword);
    my $before_generator
        = $args->{before};         ## no critic (ProhibitAccessOfPrivateData)
    my $after_generator
        = $args->{after};          ## no critic (ProhibitAccessOfPrivateData)

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
