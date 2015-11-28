package Validator::Custom::FilterFunction;

use strict;
use warnings;

use Carp 'croak';

sub remove_blank {
  my ($rule, $values, $arg) = @_;
  
  croak "filter \"remove_blank\" need array reference"
    unless ref $values eq 'ARRAY';
  
  $values = [grep { defined $_ && CORE::length $_} @$values];
  
  return $values;
}

sub trim {
  my ($rule, $value, $arg) = @_;
  
  $value =~ s/^[ \t\n\r\f]*(.*?)[ \t\n\r\f]*$/$1/ms if defined $value;

  return $value;
}

sub trim_collapse {
  my ($rule, $value, $arg) = @_;
  
  if (defined $value) {
    $value =~ s/[ \t\n\r\f]+/ /g;
    $value =~ s/^[ \t\n\r\f]*(.*?)[ \t\n\r\f]*$/$1/ms;
  }

  return $value;
}

sub trim_lead {
  my ($rule, $value, $arg) = @_;
  
  $value =~ s/^[ \t\n\r\f]+(.*)$/$1/ms if defined $value;

  return $value;
}

sub trim_trail {
  my ($rule, $value, $arg) = @_;
  
  $value =~ s/^(.*?)[ \t\n\r\f]+$/$1/ms if defined $value;

  return $value;
}

sub trim_uni {
  my ($rule, $value, $arg) = @_;
  
  $value =~ s/^\s*(.*?)\s*$/$1/ms if defined $value;

  return $value;
}

sub trim_uni_collapse {
  my ($rule, $value, $arg) = @_;
  
  if (defined $value) {
    $value =~ s/\s+/ /g;
    $value =~ s/^\s*(.*?)\s*$/$1/ms;
  }

  return $value;
}

sub trim_uni_lead {
  my ($rule, $value, $arg) = @_;
  
  $value =~ s/^\s+(.*)$/$1/ms if defined $value;
  
  return $value;
}

sub trim_uni_trail {
  my ($rule, $value, $arg) = @_;
  
  $value =~ s/^(.*?)\s+$/$1/ms if defined $value;

  return $value;
}

1;

=head1 NAME

Validator::Custom::FilterFunction - Filter functions

1;
