#!perl

use lib qw(t/lib);

use MyEvalDSL;

my $dsl = MyEvalDSL->new();

my $code = <<'EOT';
use Test::More;
is( ape,  "DSL sez: ape",  "Ape!" );
is( site, "DSL sez: site", "Site!" );

incr;
incr;

is( value, 2, "Incr and value worked!" );

my $bar = baz;
isa_ok( $bar, "MyEvalDSL", "Got a bar back" );

$bar->counter(200);

is( value, 200, "Direct object access worked too..." );

is( beep, "beep beep", "curry_chain worked!" );

done_testing

EOT

$dsl->instance_eval($code);
