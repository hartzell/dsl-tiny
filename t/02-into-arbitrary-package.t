#!perl

## Import the DSL keywords into an arbitrary package (TestMe) and then run some
## "domain specific" commands in that Package, including using the "baz"
## command to break the encapsulation and get at the underlying instance of the
## DSL.
## This is a way station on the way to cramming it into a bespoke package/class.

use strict;
use warnings;

use DSL::Tiny::Class {into => 'TestMe'}, '-install_dsl';

package TestMe;
use Test::More;

is(ape, "DSL sez: ape", "Ape!");
is(site, "DSL sez: site", "Site!");

incr;
incr;

is(value, 2, "Incr and value worked!");

my $bar = baz;

isa_ok($bar, "DSL::Tiny::Class");

$bar->counter(200);

is(value, 200, "Direct object access worked too...");

done_testing;
