package Validator::Custom::Rule;
use Object::Simple -base;
use Carp 'croak';

has 'topic_info' => sub { {} };
has 'content' => sub { [] };
has 'validator';

sub validate {
  my ($self, $input) = @_;
  
  # Set version
  $self->{version} = 1;
  
  # Class
  my $class = ref $self;
  
  # Check data
  croak "Input must be hash reference"
    unless ref $input eq 'HASH';
  
  # Result
  my $result = Validator::Custom::Result->new;
  $result->{_error_infos} = {};
  
  # Valid keys
  my $valid_keys = {};
  
  # Error position
  my $pos = 0;
  
  # Found missing parameters
  my $found_missing_params = {};

  # Process each key
  OUTER_LOOP:
  for (my $i = 0; $i < @{$self->content}; $i++) {
    
    my $r = $self->content->[$i];
    
    # Increment position
    $pos++;
    
    # Key, options, and constraints
    my $key = $r->{key};
    my $opts = $r->{option};
    my $func_infos = $r->{func_infos} || [];
    
    # Check constraints
    croak "Invalid rule structure"
      unless ref $func_infos eq 'ARRAY';

    # Arrange key
    my $result_key = $key;
    if (ref $key eq 'HASH') {
      my $first_key = (keys %$key)[0];
      $result_key = $first_key;
      $key         = $key->{$first_key};
    }
    
    # Real keys
    my $keys;
    
    if (ref $key eq 'ARRAY') { $keys = $key }
    else { $keys = [$key] }
    
    # Check missing parameters
    my $require = exists $opts->{require} ? $opts->{require} : 1;
    my $found_missing_param;
    my $missing_params = $result->missing_params;
    for my $key (@$keys) {
      unless (exists $input->{$key}) {
        if ($require && !exists $opts->{default}) {
          push @$missing_params, $key
            unless $found_missing_params->{$key};
          $found_missing_params->{$key}++;
        }
        $found_missing_param = 1;
      }
    }
    if ($found_missing_param) {
      $result->output->{$result_key} = ref $opts->{default} eq 'CODE'
          ? $opts->{default}->($self) : $opts->{default}
        if exists $opts->{default};
      next if $opts->{default} || !$require;
    }
    
    # Already valid
    next if $valid_keys->{$result_key};
    
    # Validation
    my $value = @$keys > 1
      ? [map { $input->{$_} } @$keys]
      : $input->{$keys->[0]};
    
    for my $func_info (@$func_infos) {
      
      # Constraint information
      my $cfunc = $func_info->{funcs}[0];
      my $arg = $func_info->{args}[0];
      my $message = $func_info->{message};
      
      # Is valid?
      my $is_valid;
      
      # Data is array
      if($func_info->{each}) {
          
        # To array
        $value = [$value] unless ref $value eq 'ARRAY';
        
        # Validation loop
        for (my $k = 0; $k < @$value; $k++) {
          my $input = $value->[$k];
          
          # Validate
          my $cresult;
          $cresult= $cfunc->($self, $input, $arg);
          
          # Constrint result
          my $v;
          if (ref $cresult eq 'HASH') {
            $is_valid = $cresult->{result};
            $message = $cresult->{message} unless $is_valid;
            $value->[$k] = $cresult->{output} if exists $cresult->{output};
          }
          else { $is_valid = $cresult }
          
          # Validation failed
          last unless $is_valid;
        }
      }
      
      # Data is scalar
      else {      
        my $cresult = $cfunc->($value, $arg, $self);
        
        if (ref $cresult eq 'HASH') {
          $is_valid = $cresult->{result};
          $message = $cresult->{message} unless $is_valid;
          $value = $cresult->{output} if exists $cresult->{output} && $is_valid;
        }
        else { $is_valid = $cresult }
      }
      
      # Add error if it is invalid
      unless ($is_valid) {
        if (exists $opts->{default}) {
          # Set default value
          $result->output->{$result_key} = ref $opts->{default} eq 'CODE'
                                       ? $opts->{default}->($self)
                                       : $opts->{default}
            if exists $opts->{default};
          $valid_keys->{$result_key} = 1
        }
        else {
          # Resister error info
          $message = $opts->{message} unless defined $message;
          $result->{_error_infos}->{$result_key} = {
            message      => $message,
            position     => $pos,
            original_key => $key
          } unless exists $result->{_error_infos}->{$result_key};
        }
        next OUTER_LOOP;
      }
    }
    
    # Result data
    $result->output->{$result_key} = $value;
    
    # Key is valid
    $valid_keys->{$result_key} = 1;
    
    # Remove invalid key
    delete $result->{_error_infos}->{$key};
  }
  
  return $result;
}

sub filter_each {
  my $self = shift;
  
  my $func_info = {};
  $func_info->{type} = 'filter';
  $func_info->{name} = shift;
  if (@_) {
    $func_info->{args} = shift;
  }
  $func_info->{each} = 1;
  $self->topic_info->{func_infos} ||= [];
  push @{$self->topic_fino->{func_infos}}, $func_info;
  
  return $self;
}

sub check_each {
  my $self = shift;
  
  my $func_info = {};
  $func_info->{type} = 'check';
  $func_info->{name} = shift;
  if (@_) {
    $func_info->{args} = shift;
  }
  $func_info->{each} = 1;
  $self->topic_info->{func_infos} ||= [];
  push @{$self->topic_fino->{func_infos}}, $func_info;
  
  return $self;
}

sub filter {
  my $self = shift;
  
  my $version = $self->{version};
  if ($version && $version == 1) {
    my $func_info = {};
    $func_info->{type} = 'filter';
    $func_info->{name} = shift;
    if (@_) {
      $func_info->{args} = shift;
    }
    $self->topic_info->{func_infos} ||= [];
    push @{$self->topic_fino->{func_infos}}, $func_info;
    
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
    if (@_) {
      $func_info->{args} = shift;
    }
    $self->topic_info->{func_infos} ||= [];
    push @{$self->topic_fino->{func_infos}}, $func_info;
    
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

sub default {
  my ($self, $default) = @_;
  
  $self->topic_info->{option}{default} = $default;
  
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

sub name {
  my ($self, $result_key) = @_;
  
  my $key = $self->topic_info->{key};
  $self->topic_info->{key} = {$result_key => $key};
  
  return $self;
}

sub topic {
  my ($self, $key) = @_;
  
  # Create topic
  my $topic_info = {};
  $topic_info->{key} = $key;
  $self->topic_info($topic_info);

  # Add topic to rule
  push @{$self->content}, $self->topic_info;
  
  return $self;
}

sub optional {
  my ($self, $key) = @_;
  
  # Version 0 logica(Not used now)
  if (defined $key) {
    # Create topic
    $self->topic($key);
  }
  
  # Value is optional
  $self->content->[-1]{option}{optional} = 1;
  
  return $self;
}

# Version 0 method(Not used now)
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

# Version 0 method(Not used now)
sub require {
  my ($self, $key) = @_;
  
  # Create topic
  if (defined $key) {
    $self->topic($key);
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
sub copy {
  my ($self, $copy) = @_;
  
  $self->topic_info->{option}{copy} = $copy;
  
  return $self;
}

# Version 0 method(Not used now)
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

The topic becomes optional.
