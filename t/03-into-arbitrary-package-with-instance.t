#!perl

## Import the DSL keywords into an arbitrary package (TestMe), providing an
## existing instance and then run some "DSldomain specific" commands in that
## Package, including using the "baz" command to break the encapsulation and
## get at the underlying instance of the DSL.
## This is a way station on the way to cramming it into a bespoke package/class.

use strict;
use warnings;

use DSL::Tiny::Class;

BEGIN {
    my $fb = DSL::Tiny::Class->new();
    $fb->import({into => 'TestMe'}, '-install_dsl');
    $fb->counter(2000);
}

package TestMe;
use Test::More;

is(ape, "DSL sez: ape", "Ape!");
is(site, "DSL sez: site", "Site!");

incr;
incr;

is(value, 2002, "Incr and value worked!");

my $bar = baz;

isa_ok($bar, "DSL::Tiny::Class");

$bar->counter(200);

is(value, 200, "Direct object access worked too...");

done_testing;
