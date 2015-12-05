package Validator::Custom::CheckFunction;

use strict;
use warnings;

use Carp 'croak';

sub ascii_graphic {
  my ($vc, $value, $arg) = @_;
  
  return undef unless defined $value;
  
  my $is_valid = $value =~ /^[\x21-\x7E]+$/;
  
  return $is_valid;
}

sub number {
  my ($vc, $value, $arg) = @_;

  return undef unless defined $value;
  
  if ($value =~ /^-?[0-9]+(\.[0-9]*)?$/) {
    return 1;
  }
  else {
    return undef;
  }
}

sub int {
  my ($vc, $value, $arg) = @_;

  return undef unless defined $value;
  
  my $is_valid = $value =~ /^\-?[0-9]+$/;
  
  return $is_valid;
}

sub in {
  my ($vc, $value, $arg) = @_;
  
  return undef unless defined $value;
  
  my $valid_values = $arg;
  
  croak "\"in\" check argument must be array reference"
    unless ref $valid_values eq 'ARRAY';
  
  my $match = grep { $_ eq $value } @$valid_values;
  return $match > 0 ? 1 : 0;
}

1;

=head1 NAME

Validator::Custom::CheckFunction - Checking functions
