package DSL::Tiny::InstanceEval;

use Moo::Role;

use MooX::Types::MooseLike::Base qw(ArrayRef CodeRef Str);
use Sub::Exporter::Util qw(curry_method);

=attr _instance_evalator

PRIVATE

There is no 'u' in _instance_evalator.  That means there should be no
you in there either....

Returns a coderef that is used by the instance_eval() method.

=cut

has _instance_evalator => (
    is       => 'ro',
    isa      => CodeRef,
    lazy     => 1,
    builder  => 1,
    clearer  => 1,
    init_arg => undef,
);

has _anon_pkg_name => (
    is => 'ro',
    isa => Str,
    lazy => 1,
    builder => 1,
);

{
    my $ANON_SERIAL = 0;

    sub _build__anon_pkg_name {
        return __PACKAGE__ . "::ANON_" . ++$ANON_SERIAL;
    }
}

##
## - set up an environment (anonymous package) in which to execute code that is
##   being instance_eval'ed,
## - push curried closures into the package for each of the closures,
## - and build a coderef that switches to that package, does the eval,
##   dies if the eval had trouble andotherwise returns the eval's return value.
##
sub _build__instance_evalator {
    my $self = shift;

    my $pkg_name = $self->_anon_pkg_name();

    $self->import({into => $pkg_name}, qw(-install_dsl));

    my $coderef = $self->can('_evalate');

    return $coderef;
}

=method instance_eval

Something kind-a-similar to Ruby's instance_eval.  Takes a string and evaluates
it using eval(), The evaluation happens in a package that has been populated
with a set of functions that map to methods in this class with the instance
curried out.

See the synopsis for an example.

=cut

sub instance_eval {
    my $self = shift;

    $self->_instance_evalator()->(@_);
}

requires qw(build_dsl_keywords);

1;
