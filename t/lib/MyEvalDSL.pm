#!perl

package MyEvalDSL;

use Moo;

with qw(DSL::Tiny::Role DSL::Tiny::InstanceEval);

use MyDelegate;
use Sub::Exporter::Util qw(curry_chain curry_method);

sub build_dsl_keywords {
    return [
        qw(ape incr site value),
        baz  => { as => curry_method('bar'), },
        beep => {
            as    => curry_chain( delegate => 'beep' ),
            after => curry_method('do_it_after'),
        },
        blap => {
            before => curry_method('do_it_before'),
            as     => curry_method('site'),
        },
    ];
}

has counter => ( is => 'rw', default => sub {0}, );

sub do_it_before {
    my $self = shift;
    print "before counter = " . $self->counter . "\n";
}

sub do_it_after {
    my $self = shift;
    print "after counter = " . $self->counter . "\n";
}

sub ape { return "DSL sez: ape" }

sub bar { return $_[0] }

sub delegate { return MyDelegate->new() }

sub incr { $_[0]->counter( $_[0]->counter() + 1 ) }

sub site { return "DSL sez: site" }

sub value { $_[0]->counter }

1;
