package DSL::Tiny::InstanceEval;
# ABSTRACT: Add DSL features to your class.

=head1 SYNOPSIS

    use Test::More;
    use Test::Deep;

    # put together class with a simple dsl
    {
      package MyClassWithDSL;
      use Moo;                      # or Moose
      with qw(DSL::Tiny::Role DSL::Tiny::InstanceEval);

      sub _build_dsl_keywords { [ qw(add_values) ] };

      has values => (is => 'ro',
                     default => sub { [] },
                    );

      sub add_values {
          my $self = shift;
          push @{$self->values}, @_;
      }
    }

    # make a new instance
    my $dsl = MyClassWithDSL->new();

    my $code = <<EOC;
    add_values(qw(2 1));
    add_values(qw(3));
    EOC

    my $return_value = $dsl->instance_eval($code);
    cmp_deeply($dsl->values, bag(qw(1 2 3)), "Values were added");

    done_testing;

=head1 DESCRIPTION

This package provides a simple interface, L</instance_eval>, for evaluating
snippets of a DSL (implemented with L<DSL::Tiny::Role) with respect to a
particular instance of a class that consumes the role.

=cut

use Moo::Role;

use MooX::Types::MooseLike::Base qw(CodeRef Str);
use Sub::Exporter::Util qw(curry_method);


# have Sub::Exporter build and install a sub named "_install_evalator" (instead
# of the using the name "import") into class that use us (directly or via
# consuming the role).  It has the full horsepower of a
# Sub::Exporter::import().  Calling it with no group will cause it to install
# the default group, which causes it to install an evalator routine.  We call
# it below with an 'into' arg and for that evalator routine into our own
# private package.

use Sub::Exporter -setup => {
    -as     => '_install_evalator',
    exports => { _evalator => curry_method, },
    groups  => { default => [qw(_evalator)], },
};

sub _evalator {
    $DB::single = 1;
    my $self = shift;
    my $code = shift;

    $code = 'package ' . $self->_anon_pkg_name . '; ' . $code;

    my $result = eval $code;
    die $@ if $@;

    return $result;
}

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
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    builder => qw(_build__anon_pkg_name),
);

{
    # no one can see me if I have my curly braces over my eyes....
    my $ANON_SERIAL = 0;

    # close over $ANON_SERIAL
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

    # make up a fairly unique package
    my $pkg_name = $self->_anon_pkg_name();

    # stuff the DSL into the fairly unique package
    $self->import( { into => $pkg_name }, qw(-install_dsl) );

    # stuff an evalator routine into the same package
    $self->_install_evalator( { into => $pkg_name } );

    # return a coderef to the evalator routine that
    # we pushed into the package.
    return \&{ $pkg_name . '::_evalator' };
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
