#!perl

## Import the DSL keywords into an arbitrary package (TestMe), providing an
## existing instance and then create a bespoke package in which to run the DSL
## commands.


use strict;
use warnings;

use DSL::Tiny::Class;

my $fb = DSL::Tiny::Class->new();
$fb->import({into => 'TestMe'}, '-install_dsl');
$fb->counter(2000);

my $code = << 'EOT';
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
EOT

eval $code;
