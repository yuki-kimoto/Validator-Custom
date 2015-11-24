package Validator::Custom::FilterFunction;

use strict;
use warnings;

use Carp 'croak';

sub merge {
  my ($rule, $args, $key, $params) = @_;
  
  croak "Input key of filter \"merge\" must be array refernce"
    unless ref $key eq 'ARRAY';

  my ($new_key) = @$args;
  croak "filter \"merge\" need output key"
    unless defined $new_key;
  
  my $new_value;
  for my $k (@$key) {
    $new_value .= $params->{$k};
  }
  
  return [$new_key, {$new_key => $new_value}];
}

sub first {
  my ($rule, $args, $key, $params) = @_;
  
  my $values = $params->{$key};
  
  my $new_value;
  if (ref $values eq 'ARRAY') {
    $new_value = shift @$values;
  }
  else {
    $new_value = $values;
  }
  
  return [$key, {$key => $new_value}];
}

sub to_array {
  my ($rule, $args, $key, $params) = @_;
  
  my $values;
  if (exists $params->{$key}) {
    $values = $params->{$key};
    
    $values = [$values] unless ref $values eq 'ARRAY';
  }
  else {
    $values = [];
  }
  
  return [$key, {$key => $values}];
}

sub remove_blank {
  my ($rule, $args, $key, $params) = @_;
  
  my $values = $params->{$key};
  
  croak "filter \"remove_blank\" need array reference"
    unless ref $values eq 'ARRAY';
  
  $values = [grep { defined $_ && CORE::length $_} @$values];
  
  return [$key, {$key => $values}];
}

sub trim {
  my ($rule, $args, $key, $params) = @_;
  
  my $value = $params->{$key};

  $value =~ s/^[ \t\n\r\f]*(.*?)[ \t\n\r\f]*$/$1/ms if defined $value;

  return [$key, {$key => $value}];
}

sub trim_collapse {
  my ($rule, $args, $key, $params) = @_;
  
  my $value = $params->{$key};

  if (defined $value) {
    $value =~ s/[ \t\n\r\f]+/ /g;
    $value =~ s/^[ \t\n\r\f]*(.*?)[ \t\n\r\f]*$/$1/ms;
  }

  return [$key, {$key => $value}];
}

sub trim_lead {
  my ($rule, $args, $key, $params) = @_;
  
  my $value = $params->{$key};

  $value =~ s/^[ \t\n\r\f]+(.*)$/$1/ms if defined $value;

  return [$key, {$key => $value}];
}

sub trim_trail {
  my ($rule, $args, $key, $params) = @_;
  
  my $value = $params->{$key};

  $value =~ s/^(.*?)[ \t\n\r\f]+$/$1/ms if defined $value;

  return [$key, {$key => $value}];
}

sub trim_uni {
  my ($rule, $args, $key, $params) = @_;
  
  my $value = $params->{$key};

  $value =~ s/^\s*(.*?)\s*$/$1/ms if defined $value;

  return [$key, {$key => $value}];
}

sub trim_uni_collapse {
  my ($rule, $args, $key, $params) = @_;
  
  my $value = $params->{$key};

  if (defined $value) {
    $value =~ s/\s+/ /g;
    $value =~ s/^\s*(.*?)\s*$/$1/ms;
  }

  return [$key, {$key => $value}];
}

sub trim_uni_lead {
  my ($rule, $args, $key, $params) = @_;
  
  my $value = $params->{$key};
  
  $value =~ s/^\s+(.*)$/$1/ms if defined $value;
  
  return [$key, {$key => $value}];
}

sub trim_uni_trail {
  my ($rule, $args, $key, $params) = @_;
  
  my $value = $params->{$key};
  
  $value =~ s/^(.*?)\s+$/$1/ms if defined $value;

  return [$key, {$key => $value}];
}

1;

=head1 NAME

Validator::Custom::FilterFunction - Filter functions

1;
