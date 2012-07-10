package Validator::Custom::Constraint;

use strict;
use warnings;

use Carp 'croak';

# Carp trust relationship
push @Validator::Custom::CARP_NOT, __PACKAGE__;

my $NUM_RE = qr/^[-+]?[0-9]+(:?\.[0-9]+)?$/;

sub ascii { defined $_[0] && $_[0] =~ /^[\x21-\x7E]+$/ ? 1 : 0 }

sub between {
  my ($value, $args) = @_;
  my ($start, $end) = @$args;

    
  croak "Constraint 'between' needs two numeric arguments"
    unless defined($start) && $start =~ /$NUM_RE/ && defined($end) && $end =~ /$NUM_RE/;
  
  return 0 unless defined $value && $value =~ /$NUM_RE/;
  return $value >= $start && $value <= $end ? 1 : 0;
}

sub blank { defined $_[0] && $_[0] eq '' }

sub date_to_timepiece {
  my $value = shift;
  
  require Time::Piece;
  
  # To Time::Piece object
  if (ref $value eq 'ARRAY') {
    my $year = $value->[0];
    my $mon  = $value->[1];
    my $mday = $value->[2];
    
    return [0, undef]
      unless defined $year && defined $mon && defined $mday;
    
    unless ($year =~ /^[0-9]{1,4}$/ && $mon =~ /^[0-9]{1,2}$/
     && $mday =~ /^[0-9]{1,2}$/) 
    {
      return [0, undef];
    } 
    
    my $date = sprintf("%04s%02s%02s", $year, $mon, $mday);
    
    my $tp;
    eval {
      local $SIG{__WARN__} = sub { die @_ };
      $tp = Time::Piece->strptime($date, '%Y%m%d');
    };
    
    return $@ ? [0, undef] : [1, $tp];
  }
  else {
    $value = '' unless defined $value;
    $value =~ s/[^0-9]//g;
    
    return [0, undef] unless $value =~ /^[0-9]{8}$/;
    
    my $tp;
    eval {
      local $SIG{__WARN__} = sub { die @_ };
      $tp = Time::Piece->strptime($value, '%Y%m%d');
    };
    return $@ ? [0, undef] : [1, $tp];
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
      return [0, undef];
    } 
    
    my $date = sprintf("%04s%02s%02s%02s%02s%02s", 
      $year, $mon, $mday, $hour, $min, $sec);
    my $tp;
    eval {
      local $SIG{__WARN__} = sub { die @_ };
      $tp = Time::Piece->strptime($date, '%Y%m%d%H%M%S');
    };
    
    return $@ ? [0, undef] : [1, $tp];
  }
  else {
    $value = '' unless defined $value;
    $value =~ s/[^0-9]//g;
    
    return [0, undef] unless $value =~ /^[0-9]{14}$/;
    
    my $tp;
    eval {
      local $SIG{__WARN__} = sub { die @_ };
      $tp = Time::Piece->strptime($value, '%Y%m%d%H%M%S');
    };
    return $@ ? [0, undef] : [1, $tp];
  }
}

sub decimal {
  my ($value, $digits) = @_;
  
  croak "Constraint 'decimal' needs one or two numeric arguments"
    unless $digits;
  
  $digits = [$digits] unless ref $digits eq 'ARRAY';
  
  $digits->[1] ||= 0;
  
  croak "Constraint 'decimal' needs one or two numeric arguments"
    unless $digits->[0] =~ /^[0-9]+$/ && $digits->[1] =~ /^[0-9]+$/;
  
  return 0 unless defined $value && $value =~ /^[0-9]+(\.[0-9]+)?$/;
  my $reg = qr/^[0-9]{1,$digits->[0]}(\.[0-9]{0,$digits->[1]})?$/;
  return $value =~ /$reg/ ? 1 : 0;
}

sub duplication {
  my $values = shift;

  return 0 unless defined $values->[0] && defined $values->[1];
  return $values->[0] eq $values->[1] ? [1, $values->[0]] : 0;
}

sub equal_to {
  my ($value, $target) = @_;
  
  croak "Constraint 'equal_to' needs a numeric argument"
    unless defined $target && $target =~ /^[0-9]+$/;
  
  return 0 unless defined $value && $value =~ /^[0-9]+$/;
  return $value == $target ? 1 : 0;
}

sub greater_than {
  my ($value, $target) = @_;
  
  croak "Constraint 'greater_than' needs a numeric argument"
    unless defined $target && $target =~ /^[0-9]+$/;
  
  return 0 unless defined $value && $value =~ /^[0-9]+$/;
  return $value > $target ? 1 : 0;
}

sub http_url {
  return defined $_[0] && $_[0] =~ /^s?https?:\/\/[-_.!~*'()a-zA-Z0-9;\/?:\@&=+\$,%#]+$/ ? 1 : 0;
}

sub int { defined $_[0] && $_[0] =~ /^\-?[0-9]+$/ ? 1 : 0 }

sub in_array {
  my ($value, $args) = @_;
  $value = '' unless defined $value;
  my $match = grep { $_ eq $value } @$args;
  return $match > 0 ? 1 : 0;
}

sub length {
  my ($value, $args) = @_;
  
  return unless defined $value;
  
  my $min;
  my $max;
  if(ref $args eq 'ARRAY') { ($min, $max) = @$args }
  else { $min = $args }
  
  croak "Constraint 'length' needs one or two arguments"
    unless defined $min;
  
  my $length  = length $value;
  $max     ||= $min;
  $min += 0;
  $max += 0;
  return $min <= $length && $length <= $max ? 1 : 0;
}

sub less_than {
  my ($value, $target) = @_;
  
  croak "Constraint 'less_than' needs a numeric argument"
    unless defined $target && $target =~ /^[0-9]+$/;
  
  return 0 unless defined $value && $value =~ /^[0-9]+$/;
  return $value < $target ? 1 : 0;
}

sub merge {
  my $values = shift;
  
  $values = [$values] unless ref $values eq 'ARRAY';
  
  return [1, join('', @$values)];
}

sub not_blank   { defined $_[0] && $_[0] ne '' }
sub not_defined { !defined $_[0] }
sub not_space   { defined $_[0] && $_[0] !~ '^\s*$' ? 1 : 0 }

sub uint { defined $_[0] && $_[0] =~ /^[0-9]+$/ ? 1 : 0 }

sub regex {
  my ($value, $regex) = @_;
  defined $value && $value =~ /$regex/ ? 1 : 0;
}

sub selected_at_least {
  my ($values, $num) = @_;
  
  my $selected = ref $values ? $values : [$values];
  $num += 0;
  return scalar(@$selected) >= $num ? 1 : 0;
}

sub shift_array {
  my $values = shift;
  
  $values = [$values] unless ref $values eq 'ARRAY';
  
  return [1, shift @$values];
}

sub space { defined $_[0] && $_[0] =~ '^\s*$' ? 1 : 0 }

sub to_array {
  my $value = shift;
  
  $value = [$value] unless ref $value eq 'ARRAY';
  
  return [1, $value];
}

sub trim {
  my $value = shift;
  $value =~ s/^\s*(.*?)\s*$/$1/ms;
  return [1, $value];
}

sub trim_collapse {
  my $value = shift;
  if (defined $value) {
    $value =~ s/\s+/ /g;
    $value =~ s/^\s*(.*?)\s*$/$1/ms;
  }
  return [1, $value];
}

sub trim_lead {
  my $value = shift;
  $value =~ s/^\s+(.*)$/$1/ms;
  return [1, $value];
}

sub trim_trail{
  my $value = shift;
  $value =~ s/^(.*?)\s+$/$1/ms;
  return [1, $value];
}

1;

=head1 NAME

Validator::Custom::Constraint - Constraint functions

=head1 FUNCTIONS

These functions is explained in L<Validator::Custom>

=head2 C<ascii>

=head2 C<between>

=head2 C<blank>

=head2 C<date_to_timepiece>

=head2 C<datetime_to_timepiece>

=head2 C<decimal>
    
=head2 C<defined>

=head2 C<duplication>

=head2 C<equal_to>

=head2 C<greater_than>

=head2 C<http_url>

=head2 C<int>

=head2 C<in_array>

=head2 C<length>

=head2 C<less_than>

=head2 C<merge>

=head2 C<not_blank>

=head2 C<not_defined>

=head2 C<not_space>

=head2 C<uint>

=head2 C<regex>

=head2 C<selected_at_least>

=head2 C<shift_array>

=head2 C<space>

=head2 C<trim>

=head2 C<trim_collapse>

=head2 C<trim_lead>

=head2 C<trim_trail>

=cut

