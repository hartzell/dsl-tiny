#!perl

{

    package TestMe;

    use Moo;
    with qw(DSL::Tiny::Role DSL::Tiny::InstanceEval);
    
    sub build_dsl_keywords { return [ qw(ape) ] }

    sub ape { return "DSL sez: ape" }
}

use Test::More;

my $tm = TestMe->new();

$DB::single = 1;


done_testing;
