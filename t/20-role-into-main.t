#!perl

## Import the DSL keywords into the current package (main) and then run some
## "domain specific" commands, including using the "baz" command to break the
## encapsulation and get at the underlying instance of the DSL.

use strict;
use warnings;

use lib qw(t/lib);

use Test::More;

use MyRoleConsumingDSL qw( -install_dsl );

is(ape, "DSL sez: ape", "Ape!");
is(site, "DSL sez: site", "Site!");

incr;
incr;

is(value, 2, "Incr and value worked!");

my $bar = baz;
isa_ok($bar, "MyRoleConsumingDSL", "Got a bar back");

$bar->counter(200);

is(value, 200, "Direct object access worked too...");

done_testing;
