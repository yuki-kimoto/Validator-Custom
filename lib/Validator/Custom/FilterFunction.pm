package Validator::Custom::FilterFunction;

use strict;
use warnings;

use Carp 'croak';

sub to_array {
  my ($rule, $args, $values) = @_;
  
  $values = [$values] unless ref $values eq 'ARRAY';
  
  return $values;
}

sub merge {
  my ($rule, $args, $values) = @_;
  
  my $new_value = join('', @$values);
  
  return $new_value;
}

sub first {
  my ($rule, $args, $values) = @_;
  
  my $new_value;
  if (ref $values eq 'ARRAY') {
    $new_value = shift @$values;
  }
  else {
    $new_value = $values;
  }
  
  return $new_value;
}

sub remove_blank {
  my ($rule, $args, $values) = @_;
  
  croak "filter \"remove_blank\" need array reference"
    unless ref $values eq 'ARRAY';
  
  $values = [grep { defined $_ && CORE::length $_} @$values];
  
  return $values;
}

sub trim {
  my ($rule, $args, $value) = @_;
  
  $value =~ s/^[ \t\n\r\f]*(.*?)[ \t\n\r\f]*$/$1/ms if defined $value;

  return $value;
}

sub trim_collapse {
  my ($rule, $args, $value) = @_;
  
  if (defined $value) {
    $value =~ s/[ \t\n\r\f]+/ /g;
    $value =~ s/^[ \t\n\r\f]*(.*?)[ \t\n\r\f]*$/$1/ms;
  }

  return $value;
}

sub trim_lead {
  my ($rule, $args, $value) = @_;
  
  $value =~ s/^[ \t\n\r\f]+(.*)$/$1/ms if defined $value;

  return $value;
}

sub trim_trail {
  my ($rule, $args, $value) = @_;
  
  $value =~ s/^(.*?)[ \t\n\r\f]+$/$1/ms if defined $value;

  return $value;
}

sub trim_uni {
  my ($rule, $args, $value) = @_;
  
  $value =~ s/^\s*(.*?)\s*$/$1/ms if defined $value;

  return $value;
}

sub trim_uni_collapse {
  my ($rule, $args, $value) = @_;
  
  if (defined $value) {
    $value =~ s/\s+/ /g;
    $value =~ s/^\s*(.*?)\s*$/$1/ms;
  }

  return $value;
}

sub trim_uni_lead {
  my ($rule, $args, $value) = @_;
  
  $value =~ s/^\s+(.*)$/$1/ms if defined $value;
  
  return $value;
}

sub trim_uni_trail {
  my ($rule, $args, $value) = @_;
  
  $value =~ s/^(.*?)\s+$/$1/ms if defined $value;

  return $value;
}

1;

=head1 NAME

Validator::Custom::FilterFunction - Filter functions

1;
