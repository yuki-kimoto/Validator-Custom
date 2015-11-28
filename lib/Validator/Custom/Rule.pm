# Validator::Custom::Rule is removed at Version 1.00

package Validator::Custom::Rule;
use Object::Simple -base;
use Carp 'croak';

has 'topic_info' => sub { {} };
has 'rule' => sub { [] };
has 'validator';

sub default {
  my ($self, $default) = @_;
  
  $self->topic_info->{default} = $default;
  
  return $self;
}

sub name {
  my ($self, $name) = @_;
  
  $self->topic_info->{name} = $name;
  
  return $self;
}

sub filter {
  my $self = shift;
  
  return $self->check(@_)
}

sub check {
  my $self = shift;
  
  my @constraints = @_;

  my $constraints_h = [];
  for my $constraint (@constraints) {
    my $constraint_h = {};
    if (ref $constraint eq 'ARRAY') {
      $constraint_h->{constraint} = $constraint->[0];
      $constraint_h->{message} = $constraint->[1];
    }
    else {
      $constraint_h->{constraint} = $constraint;
    }
    my $cinfo = $self->validator->_parse_constraint($constraint_h);
    $cinfo->{each} = $self->topic_info->{each};
    push @$constraints_h, $cinfo;
  }

  $self->topic_info->{constraints} ||= [];
  $self->topic_info->{constraints} = [@{$self->topic_info->{constraints}}, @{$constraints_h}];
  
  return $self;
}

sub message {
  my ($self, $message) = @_;
  
  my $constraints = $self->topic_info->{constraints} || [];
  for my $constraint (@$constraints) {
    $constraint->{message} ||= $message;
  }
  
  return $self;
}

sub topic {
  my ($self, $key) = @_;
  
  # Create topic
  my $topic_info = {};
  $topic_info->{key} = $key;
  $self->topic_info($topic_info);

  # Add topic to rule
  push @{$self->rule}, $self->topic_info;
  
  return $self;
}

sub each {
  my $self = shift;
  
  if (@_) {
    $self->topic_info->{each} = $_[0];
    return $self;
  }
  else {
    return $self->topic_info->{each};
  }
  
  return $self;
}

sub optional {
  my ($self, $key) = @_;
  
  if (defined $key) {
    # Create topic
    $self->topic($key);
  }
  
  # Value is optional
  $self->rule->[-1]{option}{optional} = 1;
  
  return $self;
}

sub require {
  my ($self, $key) = @_;

  # Create topic
  if (defined $key) {
    $self->topic($key);
  }
  
  return $self;
}

sub parse {
  my ($self, $rule, $shared_rule) = @_;
  
  $shared_rule ||= [];
  
  my $normalized_rule = [];
  
  for (my $i = 0; $i < @{$rule}; $i += 2) {
    
    my $r = {};
    
    # Key, options, and constraints
    my $key = $rule->[$i];
    my $option = $rule->[$i + 1];
    my $constraints;
    if (ref $option eq 'HASH') {
      $constraints = $rule->[$i + 2];
      $i++;
    }
    else {
      $constraints = $option;
      $option = {};
    }
    my $constraints_h = [];
    
    if (ref $constraints eq 'ARRAY') {
      for my $constraint (@$constraints, @$shared_rule) {
        my $constraint_h = {};
        if (ref $constraint eq 'ARRAY') {
          $constraint_h->{constraint} = $constraint->[0];
          $constraint_h->{message} = $constraint->[1];
        }
        else {
          $constraint_h->{constraint} = $constraint;
        }
        push @$constraints_h, $self->validator->_parse_constraint($constraint_h);
      }
    } else {
      $constraints_h = {
        'ERROR' => {
          value => $constraints,
          message => 'Constraints must be array reference'
        }
      };
    }
    
    $r->{key} = $key;
    $r->{constraints} = $constraints_h;
    $r->{option} = $option;
    
    push @$normalized_rule, $r;
  }
  
  $self->rule($normalized_rule);
  
  return $self;
}

sub copy {
  my ($self, $copy) = @_;

  $self->topic_info->{option}{copy} = $copy;
  
  return $self;
}

sub check_or {
  my ($self, @constraints) = @_;

  my $constraint_h = {};
  $constraint_h->{constraint} = \@constraints;
  
  my $cinfo = $self->validator->_parse_constraint($constraint_h);
  $cinfo->{each} = $self->topic_info->{each};
  
  $self->topic_info->{constraints} ||= [];
  push @{$self->topic_info->{constraints}}, $cinfo;
  
  return $self;
}

1;

=head1 NAME

Validator::Custom::Rule - Removed
