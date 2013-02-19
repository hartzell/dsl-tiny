#!perl

use lib qw(t/lib);

use MyDSLWithEval;

my $dsl = MyDSLWithEval->new();

my $code = <<'EOT';
use Test::More;

# simple sub worked
is( callme, "sometime...", "callme worked" );

# see if we can access an attr (and fire before sub)
is( value, 0, "Incr and value worked!" );
incr;
incr;
is( value, 2, "Incr and value worked!" );

# grab underlying instance, via renamed sub
my $instance = break_encapsulation;
isa_ok( $instance, "MyDSLWithEval", "Got the right kind of thing back");
is( $instance->value, 2, "Seems like the right instance" );

# see if we can poke it directly and expose the result
$instance->counter(200);
is( value, 200, "Direct object access worked too..." );

# call a method that's been curry_chained
is( beep,                       "beep beep", "curry_chain worked!" );

# see if the before/after subs ran as expected.
is( $instance->after_counter(), 1,           "after counter code ran" );
is( $instance->before_counter(), 3, "before counter code correctly" );

done_testing
EOT

$dsl->instance_eval($code);
