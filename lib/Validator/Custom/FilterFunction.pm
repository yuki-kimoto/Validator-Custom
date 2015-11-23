package Validator::Custom::FilterFunction;

use strict;
use warnings;

use Carp 'croak';

sub date_to_timepiece {
  my ($rule, $key, $params) = @_;
  
  my $value = $params->{$key};
  
  require Time::Piece;
  
  # To Time::Piece object
  if (ref $value eq 'ARRAY') {
    my $year = $value->[0];
    my $mon  = $value->[1];
    my $mday = $value->[2];
    
    return undef
      unless defined $year && defined $mon && defined $mday;
    
    unless ($year =~ /^[0-9]{1,4}$/ && $mon =~ /^[0-9]{1,2}$/
     && $mday =~ /^[0-9]{1,2}$/) 
    {
      return undef;
    } 
    
    my $date = sprintf("%04s%02s%02s", $year, $mon, $mday);
    
    my $tp;
    eval {
      local $SIG{__WARN__} = sub { die @_ };
      $tp = Time::Piece->strptime($date, '%Y%m%d');
    };
    
    return $@ ? undef : $tp;
  }
  else {
    $value = '' unless defined $value;
    $value =~ s/[^0-9]//g;
    
    return undef unless $value =~ /^[0-9]{8}$/;
    
    my $tp;
    eval {
      local $SIG{__WARN__} = sub { die @_ };
      $tp = Time::Piece->strptime($value, '%Y%m%d');
    };
    return $@ ? undef : $tp;
  }
}

sub datetime_to_timepiece {
  my ($rule, $key, $params) = @_;
  
  my $value = $params->{$key};
  
  require Time::Piece;
  
  # To Time::Piece object
  if (ref $value eq 'ARRAY') {
    my $year = $value->[0];
    my $mon  = $value->[1];
    my $mday = $value->[2];
    my $hour = $value->[3];
    my $min  = $value->[4];
    my $sec  = $value->[5];

    return [0, undef]
      unless defined $year && defined $mon && defined $mday
        && defined $hour && defined $min && defined $sec;
    
    unless ($year =~ /^[0-9]{1,4}$/ && $mon =~ /^[0-9]{1,2}$/
      && $mday =~ /^[0-9]{1,2}$/ && $hour =~ /^[0-9]{1,2}$/
      && $min =~ /^[0-9]{1,2}$/ && $sec =~ /^[0-9]{1,2}$/) 
    {
      return undef;
    } 
    
    my $date = sprintf("%04s%02s%02s%02s%02s%02s", 
      $year, $mon, $mday, $hour, $min, $sec);
    my $tp;
    eval {
      local $SIG{__WARN__} = sub { die @_ };
      $tp = Time::Piece->strptime($date, '%Y%m%d%H%M%S');
    };
    
    return $@ ? undef : $tp;
  }
  else {
    $value = '' unless defined $value;
    $value =~ s/[^0-9]//g;
    
    return undef unless $value =~ /^[0-9]{14}$/;
    
    my $tp;
    eval {
      local $SIG{__WARN__} = sub { die @_ };
      $tp = Time::Piece->strptime($value, '%Y%m%d%H%M%S');
    };
    return $@ ? undef : $tp;
  }
}

sub merge {
  my ($rule, $key, $params, $args) = @_;
  
  my $values = $params->{$key};
  
  $values = [$values] unless ref $values eq 'ARRAY';
  
  my $new_key = $args->[0];
  
  return {$new_key => join('', @$values)};
}

sub first {
  my ($rule, $key, $params) = @_;
  
  my $values = $params->{$key};
  
  my $new_value;
  if (ref $values eq 'ARRAY') {
    $new_value = shift @$values;
  }
  else {
    $new_value = $values;
  }
  
  return {$key => $new_value};
}

sub to_array {
  my ($rule, $key, $params) = @_;
  
  my $values;
  if (exists $params->{$key}) {
    $values = [];
  }
  else {
    $values = $params->{$key};
    
    $values = [$values] unless ref $values eq 'ARRAY';
  }
  
  return {$key => $values};
}

sub to_array_remove_blank {
  my ($rule, $key, $params) = @_;
  
  my $values = $params->{$key};
  
  $values = [$values] unless ref $values eq 'ARRAY';
  $values = [grep { defined $_ && CORE::length $_} @$values];
  
  return {$key => $values};
}

sub trim {
  my ($rule, $key, $params) = @_;
  
  my $value = $params->{$key};

  $value =~ s/^[ \t\n\r\f]*(.*?)[ \t\n\r\f]*$/$1/ms if defined $value;

  return {$key => $value};
}

sub trim_collapse {
  my ($rule, $key, $params) = @_;
  
  my $value = $params->{$key};

  if (defined $value) {
    $value =~ s/[ \t\n\r\f]+/ /g;
    $value =~ s/^[ \t\n\r\f]*(.*?)[ \t\n\r\f]*$/$1/ms;
  }

  return {$key => $value};
}

sub trim_lead {
  my ($rule, $key, $params) = @_;
  
  my $value = $params->{$key};

  $value =~ s/^[ \t\n\r\f]+(.*)$/$1/ms if defined $value;

  return {$key => $value};
}

sub trim_trail {
  my ($rule, $key, $params) = @_;
  
  my $value = $params->{$key};

  $value =~ s/^(.*?)[ \t\n\r\f]+$/$1/ms if defined $value;

  return {$key => $value};
}

sub trim_uni {
  my ($rule, $key, $params) = @_;
  
  my $value = $params->{$key};

  $value =~ s/^\s*(.*?)\s*$/$1/ms if defined $value;

  return {$key => $value};
}

sub trim_uni_collapse {
  my ($rule, $key, $params) = @_;
  
  my $value = $params->{$key};

  if (defined $value) {
    $value =~ s/\s+/ /g;
    $value =~ s/^\s*(.*?)\s*$/$1/ms;
  }

  return {$key => $value};
}

sub trim_uni_lead {
  my ($rule, $key, $params) = @_;
  
  my $value = $params->{$key};
  
  $value =~ s/^\s+(.*)$/$1/ms if defined $value;
  
  return {$key => $value};
}

sub trim_uni_trail {
  my ($rule, $key, $params) = @_;
  
  my $value = $params->{$key};
  
  $value =~ s/^(.*?)\s+$/$1/ms if defined $value;

  return {$key => $value};
}

1;

=head1 NAME

Validator::Custom::FilterFunction - Filter functions

1;
