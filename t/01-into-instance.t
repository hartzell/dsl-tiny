#!perl

## Import the DSL keywords into an existing instance of DSL::Tiny::Class and
## then run some "domain specific" commands, including using the "baz" command
## to break the encapsulation and get at the underlying instance of the DSL
## (and check that it returns the instance we fed in at the top).

use strict;
use warnings;

use Test::More;

use DSL::Tiny::Class;

my $bar;
BEGIN {
    $bar = DSL::Tiny::Class->new();
    $bar->import('-install_dsl');
}

is(ape, "DSL sez: ape", "Ape!");
is(site, "DSL sez: site", "Site!");

incr;
incr;

is(value, 2, "Incr and value worked!");

is(baz(), $bar, "Using the expected instance");
isa_ok($bar, "DSL::Tiny::Class", "Got a bar back");

$bar->counter(200);

is(value, 200, "Direct object access worked too...");

done_testing;
