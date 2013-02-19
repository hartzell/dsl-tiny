#!perl

## Import the DSL keywords into the current package (main) and then run some
## "domain specific" commands, including using the "baz" command to break the
## encapsulation and get at the underlying instance of the DSL.

use strict;
use warnings;

use lib qw(t/lib);

use Test::More;

use MyDSL qw( -install_dsl );

# simple sub worked
is( callme, "sometime...", "callme worked" );

# see if we can access an attr (and fire before sub)
is( value, 0, "Incr and value worked!" );
incr;
incr;
is( value, 2, "Incr and value worked!" );

# grab underlying instance, via renamed sub
my $instance = break_encapsulation;
isa_ok( $instance, "MyDSL", "Got a dsl back" );
is( $instance->value, 2, "Seems like the right instance" );

# see if we can poke it directly and expose the result
$instance->counter(200);
is( value, 200, "Direct object access worked too..." );

# call a method that's been curry_chained
is( beep,                       "beep beep", "curry_chain worked!" );

# see if the before/after subs ran as expected.
is( $instance->after_counter(), 1,           "after counter code ran" );
is( $instance->before_counter(), 3, "before counter code correctly" );

done_testing;
