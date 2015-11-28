package Validator::Custom::CheckFunction;

use strict;
use warnings;

use Carp 'croak';

my $NUM_RE = qr/^[-+]?[0-9]+(:?\.[0-9]+)?$/;

sub ascii {
  my ($vc, $value, $arg) = @_;
  
  return undef unless defined $value;
  
  my $is_valid = $value =~ /^[\x21-\x7E]+$/;
  
  return $is_valid;
}

sub decimal {
  my ($vc, $value, $arg) = @_;

  return undef unless defined $value;
  
  my $digits_tmp = $arg;
  
  # 桁数情報を整理
  my $digits;
  if (defined $digits_tmp) {
    if (ref $digits_tmp eq 'ARRAY') {
      $digits = $digits_tmp;
    }
    else {
      $digits = [$digits_tmp, undef];
    }
  }
  else {
    $digits = [undef, undef];
  }
  
  # 正規表現を作成
  my $re;
  if (defined $digits->[0] && defined $digits->[1]) {
    $re = qr/^[0-9]{1,$digits->[0]}(\.[0-9]{0,$digits->[1]})?$/;
  }
  elsif (defined $digits->[0]) {
    $re = qr/^[0-9]{1,$digits->[0]}(\.[0-9]*)?$/;
  }
  elsif (defined $digits->[1]) {
    $re = qr/^[0-9]+(\.[0-9]{0,$digits->[1]})?$/;
  }
  else {
    $re = qr/^[0-9]+(\.[0-9]*)?$/;
  }
  
  # 値をチェック
  if ($value =~ /$re/) {
    return 1;
  }
  else {
    return 0;
  }
}

sub int {
  my ($vc, $value, $arg) = @_;

  return undef unless defined $value;
  
  my $is_valid = $value =~ /^\-?[0-9]+$/;
  
  return $is_valid;
}

sub uint {
  my ($vc, $value, $arg) = @_;
  
  return undef unless defined $value;

  my $is_valid = $value =~ /^[0-9]+$/;
  
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
