package Validator::Custom::FilterFunction;

use strict;
use warnings;

use Carp 'croak';

sub date_to_timepiece {
  my $value = shift;
  
  require Time::Piece;
  
  # To Time::Piece object
  if (ref $value eq 'ARRAY') {
    my $year = $value->[0];
    my $mon  = $value->[1];
    my $mday = $value->[2];
    
    return undef;
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
  my $value = shift;
  
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
  my $values = shift;
  
  $values = [$values] unless ref $values eq 'ARRAY';
  
  return join('', @$values);
}

sub shift_array {
  my $values = shift;
  
  $values = [$values] unless ref $values eq 'ARRAY';
  
  return shift @$values;
}

sub space { defined $_[0] && $_[0] =~ '^[ \t\n\r\f]*$' ? 1 : 0 }

sub to_array {
  my $value = shift;
  
  $value = [$value] unless ref $value eq 'ARRAY';
  
  return $value;
}

sub to_array_remove_blank {
  my $values = shift;
  
  $values = [$values] unless ref $values eq 'ARRAY';
  $values = [grep { defined $_ && CORE::length $_} @$values];
  
  return $values;
}

sub trim {
  my $value = shift;
  $value =~ s/^[ \t\n\r\f]*(.*?)[ \t\n\r\f]*$/$1/ms if defined $value;
  return $value;
}

sub trim_collapse {
  my $value = shift;
  if (defined $value) {
    $value =~ s/[ \t\n\r\f]+/ /g;
    $value =~ s/^[ \t\n\r\f]*(.*?)[ \t\n\r\f]*$/$1/ms;
  }
  return $value;
}

sub trim_lead {
  my $value = shift;
  $value =~ s/^[ \t\n\r\f]+(.*)$/$1/ms if defined $value;
  return $value;
}

sub trim_trail {
  my $value = shift;
  $value =~ s/^(.*?)[ \t\n\r\f]+$/$1/ms if defined $value;
  return $value;
}

sub trim_uni {
  my $value = shift;
  $value =~ s/^\s*(.*?)\s*$/$1/ms if defined $value;
  return $value;
}

sub trim_uni_collapse {
  my $value = shift;
  if (defined $value) {
    $value =~ s/\s+/ /g;
    $value =~ s/^\s*(.*?)\s*$/$1/ms;
  }
  return $value;
}

sub trim_uni_lead {
  my $value = shift;
  $value =~ s/^\s+(.*)$/$1/ms if defined $value;
  return $value;
}

sub trim_uni_trail {
  my $value = shift;
  $value =~ s/^(.*?)\s+$/$1/ms if defined $value;
  return $value;
}

=head1 NAME

Validator::Custom::FilterFunction - Filter functions

1;
