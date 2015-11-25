package Validator::Custom::Rule;
use Object::Simple -base;
use Carp 'croak';

has 'topic_info' => sub { {} };
has 'content' => sub { [] };
has 'validator';

sub default {
  my ($self, $default) = @_;
  
  $self->topic_info->{default} = $default;
  
  return $self;
}

sub optional {
  my ($self, $key) = @_;
  
  # Version 0 logic(Not used now)
  if (defined $key) {
    # Create topic
    $self->topic_v0($key);
  }
  
  # Value is optional
  $self->content->[-1]{option}{optional} = 1;
  
  return $self;
}

sub run_check {
  my ($self, $name, $args, $key, $params) = @_;
  
  my $checks = $self->validator->{checks} || {};
  my $check = $checks->{$name};
  unless ($check) {
    croak "Can't call $name check";
  }
  
  my $ret = $check->($self, $args, $key, $params);
  
  if (ref $ret eq 'HASH') {
    return 0;
  }
  else {
    return $ret ? 1: 0;
  }
}

sub run_filter {
  my ($self, $name, $args, $key, $params) = @_;
  
  my $filters = $self->validator->{filters} || {};
  my $filter = $filters->{$name};
  unless ($filter) {
    croak "Can't call $name filter";
  }
  
  my $new_params = $filter->($self, $args, $key, $params);
  
  return $new_params;
}

sub fallback {
  my ($self, $fallback) = @_;
  
  $self->topic_info->{fallback} = $fallback;
  
  return $self;
}

sub name {
  my ($self, $name) = @_;
  
  $self->topic_info->{name} = $name;
  
  return $self;
}

sub validate {
  my ($self, $input) = @_;
  
  # Check data
  croak "Input must be hash reference."
    unless ref $input eq 'HASH';
  
  # Result
  my $result = Validator::Custom::Result->new;
  $result->{_error_infos} = {};
  
  # Output
  my $output = {};
  
  # Error position
  my $pos = 0;
  
  
  # Process each param
  for my $r (@{$self->content}) {
    
    # Key
    my $key = $r->{key};
    
    # Optional
    my $optional = $r->{optional};
    
    # Name
    my $name;
    if (ref $key eq 'ARRAY' && !defined $r->{name}) {
      croak "name is needed for multiple topic values";
    }
    if ($r->{name}) {
      $name = $r->{name};
    }
    else {
      $name = $key;
    }
    
    # Function information
    my $func_infos = $r->{func_infos} || [];
    
    # Process funcs
    my $current_key = $key;
    my $current_params;
    if (ref $current_key eq 'ARRAY') {
      $current_params = {};
      for my $key (@$current_key) {
        if (exists $input->{$key}) {
          $current_params->{$key} = $input->{$key};
        }
      }
    }
    else {
      if (exists $input->{$key}) {
        $current_params->{$key} = $input->{$key};
      }
    }
    
    # Is invalid
    my $is_invalid;
    
    # Message
    my $message;
    
    for my $func_info (@$func_infos) {
      
      # Constraint information
      my $func_name = $func_info->{name};
      my $func;
      if (ref $func_name eq 'CODE') {
        $func = $func_name;
      }
      else {
        if ($func_info->{type} eq 'check') {
          $func = $self->validator->{checks}{$func_name};
          croak "Can't find \"$func_name\" check"
            unless $func;
        }
        elsif ($func_info->{type} eq 'filter') {
          $func = $self->validator->{filters}{$func_name};
          croak "Can't find \"$func_name\" filter"
            unless $func;
        }
      }
      
      my $args = $func_info->{args};
      my $func_info_message = $func_info->{message};
      my $each = $func_info->{each};
      
      # Is valid
      my $is_valid;
      
      # Each value
      if ($func_info->{each}) {
        
        # Check
        if ($func_info->{type} eq 'check') {
          my $values = $current_params->{$current_key};
          
          croak "check_each can receive only array reference values"
            unless ref $values eq 'ARRAY';
          
          # Validation loop
          for (my $k = 0; $k < @$values; $k++) {
            my $value = $values->[$k];
            
            # Set current key and params
            
            # Validate
            my $is_valid = $func->($self, $args, $current_key, {$current_key => $value});
            
            # Constrint result
            if (ref $is_valid eq 'HASH') {
              $is_invalid = 1;
              $message = $is_valid->{message};
              warn "$name message is empty(Validator::Custom::Rule::validate)"
                unless defined $is_valid->{message};              
            }
            elsif (!$is_valid) {
              $is_invalid = 1;
              if (defined $func_info_message) {
                $message = $func_info_message;
              }
              else {
                $message = "$name is invalid";
              }
            }
            
            # Validation failed
            last if $is_invalid;
          }
        }
        # Filter
        elsif ($func_info->{type} eq 'filter') {
          my $values = $current_params->{$current_key};
          
          croak "filter_each can receive only array reference values"
            unless ref $values eq 'ARRAY';
          
          
          # Validation loop
          my $new_values = [];
          for (my $k = 0; $k < @$values; $k++) {
            my $value = $values->[$k];
            
            # Set current key and params
            
            my $ret = $func->($self, $args, $current_key, {$current_key => $value});
            croak "Filter return value must be array refernce"
              unless ref $ret eq 'ARRAY';
            
            my $new_key = $ret->[0];
            
            croak "Filter function must retrun same key as original key"
              unless $new_key eq $current_key;
            
            my $new_params = $ret->[1];
            
            push @$new_values, $new_params->{$new_key};
          }
          
          $current_params = {$current_key => $new_values};
        }
      }
      
      # Single value
      else {      
        # Set current key and params
        
        if ($func_info->{type} eq 'check') {
          my $is_valid = $func->($self, $args, $current_key, $current_params);
          
          if (ref $is_valid eq 'HASH') {
            $is_invalid = 1;
            $message = $is_valid->{message};
            warn "$name message is empty(Validator::Custom::Rule::validate)"
              unless defined $is_valid->{message};              
          }
          elsif (!$is_valid) {
            $is_invalid = 1;
            if (defined $func_info_message) {
              $message = $func_info_message;
            }
            else {
              $message = "$name is invalid";
            }
          }
        }
        elsif ($func_info->{type} eq 'filter') {
          my $ret = $func->($self, $args, $current_key, $current_params);
          croak "Filter return value must be array refernce"
            unless ref $ret eq 'ARRAY';
          
          $current_key = $ret->[0];
          $current_params = $ret->[1];
        }
      }
      last if $is_invalid;
    }
    
    # Set output
    if (!$is_invalid) {
      # Set output
      if (ref $current_key eq 'ARRAY') {
        for(my $i = 0; $i < @$current_key; $i++) {
          my $key = $current_key->[$i];
          $output->{$key} = $current_params->{$key};
        }
      }
      else {
        $output->{$current_key} = $current_params->{$current_key};
      }
    }
    elsif ($is_invalid && exists $r->{fallback}) {
      if (ref $current_key eq 'ARRAY') {
        for (my $i = 0; $i < @$current_key; $i++) {
          my $key = $current_key->[$i];
          my $fallback = $r->{fallback}[$i];
          $output->{$key} =
            ref $fallback eq 'CODE'
            ? $fallback->($self)
            : $fallback;
        }
      }
      else {
        $output->{$current_key}
          = ref $r->{fallback} eq 'CODE'
          ? $r->{fallback}->($self)
          : $r->{fallback};
      }
      
      $is_invalid = 0;
    }
    
    # Add result information
    if ($is_invalid) {
      $result->{_error_infos}->{$name} = {
        message      => $message,
        position     => $pos,
      };
    }
    
    # Increment position
    $pos++;
  }
  
  $result->output($output);
  
  return $result;
}

sub filter_each {
  my $self = shift;
  
  my $func_info = {};
  $func_info->{type} = 'filter';
  $func_info->{name} = shift;
  $func_info->{args} = [@_];
  $func_info->{each} = 1;
  $self->topic_info->{func_infos} ||= [];
  push @{$self->topic_info->{func_infos}}, $func_info;
  
  return $self;
}

sub check_each {
  my $self = shift;
  
  my $func_info = {};
  $func_info->{type} = 'check';
  $func_info->{name} = shift;
  $func_info->{args} = [@_];
  $func_info->{each} = 1;
  $self->topic_info->{func_infos} ||= [];
  push @{$self->topic_info->{func_infos}}, $func_info;
  
  return $self;
}

sub filter {
  my $self = shift;
  
  my $version = $self->{version};
  if ($version && $version == 1) {
    my $func_info = {};
    $func_info->{type} = 'filter';
    $func_info->{name} = shift;
    $func_info->{args} = [@_];
    $self->topic_info->{func_infos} ||= [];
    push @{$self->topic_info->{func_infos}}, $func_info;
    
    return $self;
  }
  # Version 0(Not used now)
  else {
    return $self->check(@_)
  }
}

sub check {
  my $self = shift;
  
  my $version = $self->{version};
  if ($version && $version == 1) {
    my $func_info = {};
    $func_info->{type} = 'check';
    $func_info->{name} = shift;
    $func_info->{args} = [@_];
    $self->topic_info->{func_infos} ||= [];
    push @{$self->topic_info->{func_infos}}, $func_info;
    
    return $self;
  }
  # Version 0(Not used now)
  else {
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
}

sub message {
  my ($self, $message) = @_;
  
  my $version = $self->{version};
  if ($version && $version == 1) {
    my $func_infos = $self->topic_info->{func_infos} || [];
    for my $func_info (@$func_infos) {
      unless (defined $func_info->{message}) {
        $func_info->{message} = $message;
      }
    }
  }
  # Version 0 logica(Not used now)
  else {
    my $constraints = $self->topic_info->{constraints} || [];
    for my $constraint (@$constraints) {
      $constraint->{message} ||= $message;
    }
  }
  
  return $self;
}

sub topic {
  my ($self, $key) = @_;
  
  $self->{version} = 1;
  
  # Check
  croak "topic must be a string or array reference"
    unless defined $key && (!ref $key || ref $key eq 'ARRAY');
  
  # Create topic
  my $topic_info = {};
  $topic_info->{key} = $key;
  $self->topic_info($topic_info);

  # Add topic to rule
  push @{$self->content}, $self->topic_info;
  
  return $self;
}

# Version 0 method(Not used now)
sub each {
  my $self = shift;
  
  if ($self->{version} && $self->{version} == 1) {
    croak "Can't call each method(Validator::Custom::Rule)";
  }
  
  if (@_) {
    $self->topic_info->{each} = $_[0];
    return $self;
  }
  else {
    return $self->topic_info->{each};
  }
  
  return $self;
}

# Version 0 method(Not used now)
sub require {
  my ($self, $key) = @_;

  if ($self->{version} && $self->{version} == 1) {
    croak "Can't call require method(Validator::Custom::Rule)";
  }
    
  # Create topic
  if (defined $key) {
    $self->topic_v0($key);
  }
  
  return $self;
}

# Version 0 method(Not used now)
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
  
  $self->content($normalized_rule);
  
  return $self;
}

# Version 0 method(Not used now)
sub topic_v0 {
  my $self = shift;
  
  $self->topic(@_);

  delete $self->{version};
  
  return $self;
}

# Version 0 method(Not used now)
sub copy {
  my ($self, $copy) = @_;

  if ($self->{version} && $self->{version} == 1) {
    croak "Can't call copy method(Validator::Custom::Rule)";
  }
    
  $self->topic_info->{option}{copy} = $copy;
  
  return $self;
}

# Version 0 method(Not used now)
sub check_or {
  my ($self, @constraints) = @_;

  if ($self->{version} && $self->{version} == 1) {
    croak "Can't call check_or method(Validator::Custom::Rule)";
  }
    
  my $constraint_h = {};
  $constraint_h->{constraint} = \@constraints;
  
  my $cinfo = $self->validator->_parse_constraint($constraint_h);
  $cinfo->{each} = $self->topic_info->{each};
  
  $self->topic_info->{constraints} ||= [];
  push @{$self->topic_info->{constraints}}, $cinfo;
  
  return $self;
}

# Version 0 attributes(Not used now)
has 'rule' => sub {
  my $self = shift;
  
  if (@_) {
    return $self->content(@_);
  }
  else {
    return $self->content;
  }
};


1;

=head1 NAME

Validator::Custom::Rule - Rule object

=head1 SYNOPSYS
  
  use Validator::Custom;
  my $vc = Validator::Custom->new;
  
  # Create rule object
  my $rule = $vc->create_rule;
  $rule->topic('id')->check('ascii')->message('Error');
  $rule->topic('name')->optional->check('not_blank')->default(4);
  
  # Validate
  my $data = {id => '001', name => 'kimoto'};
  my $result = $rule->validate($data);

=head1 DESCRIPTION

Validator::Custom::Rule - Rule of validation

=head1 ATTRIBUTES

=head2 content

  my $content = $rule->content;
  $content = $rule->content($content);

Content of rule object.

=head1 METHODS

=head2 check

  $rule->check('not_blank');

Add a check to current topic.

=head2 check_each

  $rule->check_each('not_blank');

Add a check for each value to current topic.

=head2 default

  $rule->default(0);
  $rule->default(sub { Time::Piece::localtime });

Set default value.

=head2 filter

  $rule->filter('trim');

Add a filter to current topic.

=head2 filter_each

  $rule->filter_each('trim');

Add a filter for each value to current topic.

=head2 message

  $rule->topic('name')
    ->check('not_blank')->message('should be not blank')
    ->check('int')->message('should be int');

Set message for each check.

Message is fallback to before check
so you can write the following way.

  $rule->topic('name')
    ->check('not_blank')
    ->check('int')->message('should be not blank and int');

=head2 name

  $rule->name('key1');

Set result key name

=head2 optional

  $rule->optional;

The topic becomes optional. Even if the value doesn't exists, validation succeed.

=head2 default

  $rule->default('foo');
  
Set default value when the value doesn't exists.

=head2 fallback
  
  $rule->fallback;
  $rule->fallback('foo');
  
Set fallback value. Cancel invalid status and set output value.

=head2 run_check

Execute check fucntion.

  my $is_valid = $rule->run_check('length', $args, $key, $params);

if return value is hash reference or false value, C<run_check> method return false value.
In other cases, C<run_check> method return true value.

=head2 run_filter

Execute filter function.

  my $new_params = $vc->run_check('length', $args, $key, $params);

=head1 FAQ

