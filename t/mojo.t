use strict;
use warnings;
use Mojolicious 6.02;
use Test::More;
use AnyEvent::Open3::Simple;
use Mojo::IOLoop;
use Mojo::Reactor;

plan tests => 8;

$ENV{MOJO_REACTOR} = 'Mojo::Reactor::Bogus';

isnt(Mojo::Reactor->detect, 'Mojo::Reactor::EV', "Mojo::Reactor->detect = @{[ Mojo::Reactor->detect ]}");

Mojo::IOLoop->timer( 7 => sub {
  Mojo::IOLoop->stop;
  fail 'called on_exit';
});

my $called_on_start = 0;
my $exit_value      = 0;
my @out;
my @err;

my $ipc = AnyEvent::Open3::Simple->new(
  implementation => 'mojo',
  on_start => sub {
    $called_on_start = 1;
  },
  on_exit => sub {
    (undef, $exit_value, undef) = @_;
    Mojo::IOLoop->stop;
    pass 'called on_exit';
  },
  on_stdout => sub {
    my $line = pop;
    push @out, $line;
    note "[out] $line";
  },
  on_stderr => sub {
    my $line = pop;
    push @err, $line;
    note "[err] $line";
  },
);

$ipc->run($^X, -e => 'print "dragon\n"; print STDERR "lime\n"; exit 22');

Mojo::IOLoop->start;

ok $called_on_start, 'called on start';
is $exit_value, 22, 'exit = 22';
is_deeply \@out, ['dragon'], 'stdout';
is_deeply \@err, ['lime'], 'stderr';

is $ipc->{impl}, 'mojo', 'used mojo implementation';

ok !$INC{'AnyEvent.pm'}, 'did not load AnyEvent';
diag "AnyEvent.pm = $INC{'AnyEvent.pm'}" if $INC{'AnyEvent.pm'};
