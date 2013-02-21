#!perl

package MyDSL;

use Moo;

with qw(DSL::Tiny::Role);

use MyDelegate;
use Sub::Exporter::Util qw(curry_chain curry_method);

sub build_dsl_keywords {
    return [
        qw(callme incr),
        break_encapsulation => { as => curry_method('return_self'), },
        beep                => {
            before => [ curry_method('bleeper'), curry_method('blooper'), ],
            as    => curry_chain( delegate => 'beep' ),
            after => curry_method('do_it_after'),
        },
        value => {
            before => [
                curry_method('do_it_before'), curry_method('blooper'),
                curry_method('bleeper'),
            ]
        },
    ];
}

has before_counter => ( is => 'rw', default => sub {0}, );
has counter        => ( is => 'rw', default => sub {0}, );
has after_counter  => ( is => 'rw', default => sub {0}, );

sub do_it_before {
    my $self = shift;
    my $i    = $self->before_counter() + 1;
    $self->before_counter($i);
}

sub blooper { print "BLOOP\n"; }
sub bleeper { print "BLEEP\n"; }

sub do_it_after {
    my $self = shift;
    my $i    = $self->after_counter() + 1;
    $self->after_counter($i);
}

sub callme { return "sometime..." }

sub return_self { return $_[0] }

sub delegate { return MyDelegate->new() }

sub incr { $_[0]->counter( $_[0]->counter() + 1 ) }

sub value { $_[0]->counter }

1;
