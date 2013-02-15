#!perl

package MyRoleConsumingDSL;

use Moo;

with qw(DSL::Tiny::Role);

sub _build_dsl_keywords {
    return [ qw(ape incr site value), baz => { method => 'bar' } ];
}

has counter => ( is => 'rw', default => sub {0}, );

sub ape { return "DSL sez: ape" }

sub bar { return $_[0] }

sub incr { $_[0]->counter( $_[0]->counter() + 1 ) }

sub site { return "DSL sez: site" }

sub value { $_[0]->counter }

1;
