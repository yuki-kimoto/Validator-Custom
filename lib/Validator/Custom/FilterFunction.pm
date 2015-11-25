package Validator::Custom::FilterFunction;

use strict;
use warnings;

use Carp 'croak';

sub merge {
  my ($rule, $args) = @_;
  
  my $key = $rule->current_key;
  my $params = $rule->current_params;
  
  croak "Input key of filter \"merge\" must be array refernce"
    unless ref $key eq 'ARRAY';

  my ($new_key) = @$args;
  croak "filter \"merge\" need output key"
    unless defined $new_key;
  
  my $new_value;
  for my $k (@$key) {
    $new_value .= $params->{$k};
  }
  
  $rule->current_key($new_key);
  $rule->current_params({$new_key => $new_value});
}

sub first {
  my ($rule, $args) = @_;
  
  my $values = $rule->current_value;
  
  my $new_value;
  if (ref $values eq 'ARRAY') {
    $new_value = shift @$values;
  }
  else {
    $new_value = $values;
  }
  
  $rule->current_value($new_value);
}

sub to_array {
  my ($rule, $args) = @_;
  
  my $key = $rule->current_key;
  my $params = $rule->current_params;
  
  my $values;
  if (exists $params->{$key}) {
    $values = $params->{$key};
    
    $values = [$values] unless ref $values eq 'ARRAY';
  }
  else {
    $values = [];
  }
  
  $rule->current_value($values);
}

sub remove_blank {
  my ($rule, $args) = @_;
  
  my $values = $rule->current_value;
  
  croak "filter \"remove_blank\" need array reference"
    unless ref $values eq 'ARRAY';
  
  $values = [grep { defined $_ && CORE::length $_} @$values];
  
  $rule->current_value($values);
}

sub trim {
  my ($rule, $args) = @_;
  
  my $value = $rule->current_value;

  $value =~ s/^[ \t\n\r\f]*(.*?)[ \t\n\r\f]*$/$1/ms if defined $value;

  $rule->current_value($value);
}

sub trim_collapse {
  my ($rule, $args) = @_;
  
  my $value = $rule->current_value;

  if (defined $value) {
    $value =~ s/[ \t\n\r\f]+/ /g;
    $value =~ s/^[ \t\n\r\f]*(.*?)[ \t\n\r\f]*$/$1/ms;
  }

  $rule->current_value($value);
}

sub trim_lead {
  my ($rule, $args) = @_;
  
  my $value = $rule->current_value;

  $value =~ s/^[ \t\n\r\f]+(.*)$/$1/ms if defined $value;

  $rule->current_value($value);
}

sub trim_trail {
  my ($rule, $args) = @_;
  
  my $value = $rule->current_value;

  $value =~ s/^(.*?)[ \t\n\r\f]+$/$1/ms if defined $value;

  $rule->current_value($value);
}

sub trim_uni {
  my ($rule, $args) = @_;
  
  my $value = $rule->current_value;

  $value =~ s/^\s*(.*?)\s*$/$1/ms if defined $value;

  $rule->current_value($value);
}

sub trim_uni_collapse {
  my ($rule, $args) = @_;
  
  my $value = $rule->current_value;

  if (defined $value) {
    $value =~ s/\s+/ /g;
    $value =~ s/^\s*(.*?)\s*$/$1/ms;
  }

  $rule->current_value($value);
}

sub trim_uni_lead {
  my ($rule, $args) = @_;
  
  my $value = $rule->current_value;
  
  $value =~ s/^\s+(.*)$/$1/ms if defined $value;
  
  $rule->current_value($value);
}

sub trim_uni_trail {
  my ($rule, $args) = @_;
  
  my $value = $rule->current_value;
  
  $value =~ s/^(.*?)\s+$/$1/ms if defined $value;

  $rule->current_value($value);
}

1;

=head1 NAME

Validator::Custom::FilterFunction - Filter functions

1;
