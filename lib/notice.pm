package notice;

use 5.014;

use strict;
use warnings;

use Carp;
use Time::Piece;

# VERSION

# FUNCTIONS

sub import {
  my ($class, %args) = @_;

  return if exists $ENV{ACK_NOTICE};

  notice(scalar(caller), %args);

  return;
}

sub check {
  my ($class, %args) = @_;

  for my $name (sort keys %args) {
    my %config = %{$args{$name}};
    my $until = $config{until} or next;
    my $varname = envvar($config{space} || $class, $name);
    next if time > timepiece($until)->epoch;
    next if exists $ENV{$varname};
    return [$class, $name, $varname, $until, $config{notes}];
  }

  return;
}

sub envvar {
  my ($class, $name) = @_;

  my $string = join '_', 'ack', 'notice', map {s/[^a-zA-Z0-9]+/_/gr} $class, $name;

  return uc($string);
}

sub message {
  my ($class, $name, $varname, $expiry, $notes) = @_;

  return "Unacknowledged notice for $class ($name):\n".
  ($notes ? (ref($notes) ? (join("", map "- $_\n", @$notes)) : "- $notes\n") : "").
  "- Notice can be supressed by setting the \"$varname\" environment variable\n".
  "- Notice expires after $expiry\n"
}

sub notice {
  my ($class, %args) = @_;

  my $found = check($class, %args) or return;

  croak(message(@$found));

  return;
}

sub timepiece {
  my ($time) = @_;

  return Time::Piece->strptime($time, timeformat());
}

sub timeformat {
  return '%Y-%m-%d';
}

1;