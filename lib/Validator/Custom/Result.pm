package Validator::Custom::Result;
use Object::Simple -base;

use Carp 'croak';

# Attrbutes
has output => sub { {} };

sub invalid_rule_keys {
  my $self = shift;
  
  # Invalid rule keys
  my $error_infos = $self->{_error_infos};
  my @invalid_rule_keys = sort { $error_infos->{$a}{position} <=>
    $error_infos->{$b}{position} } keys %$error_infos;
  
  return \@invalid_rule_keys;
}

sub is_valid {
  my ($self, $name) = @_;
 
  if (defined $name) {
    return exists $self->{_error_infos}->{$name} ? 0 : 1;
  }
  else {
    return !(keys %{$self->{_error_infos}}) ? 1 : 0;
  }
}

sub message {
  my ($self, $name) = @_;
  
  # Parameter name not specified
  croak 'Parameter name must be specified'
    unless $name;
  
  return $self->{_error_infos}->{$name}{message}
    || $self->{_default_messages}{$name}
    || 'Error message not specified';
}

sub messages {
  my $self = shift;

  # Error messages
  my @messages;
  my $error_infos = $self->{_error_infos};
  my @keys = sort { $error_infos->{$a}{position} <=>
    $error_infos->{$b}{position} } keys %$error_infos;
  foreach my $name (@keys) {
    my $message = $self->message($name);
    push @messages, $message;
  }
  
  return \@messages;
}

sub messages_to_hash {
  my $self = shift;

  # Error messages
  my $messages = {};
  foreach my $name (keys %{$self->{_error_infos}}) {
    $messages->{$name} = $self->message($name);
  }
  
  return $messages;
}

# Version 0 method(Not used now)
sub is_ok {
  my $self = shift;
  
  # Is ok?
  return !$self->has_invalid && !$self->has_missing ? 1 : 0;
}

# Version 0 method(Not used now)
sub to_hash {
  my $self = shift;
  
  # Result
  my $result = {};
  $result->{ok}      = $self->is_ok;
  $result->{invalid} = $self->has_invalid;
  $result->{missing} = $self->has_missing;
  $result->{missing_params} = $self->missing_params;
  $result->{messages} = $self->messages_to_hash;
  
  return $result;
}

# Version 0 method(Not used now)
sub has_missing { @{shift->missing_params} ? 1 : 0 }

# Version 0 method(Not used now)
sub has_invalid {
  my $self = shift;
  
  # Has invalid parameter?
  return keys %{$self->{_error_infos}} ? 1 : 0;
}

# Version 0 method(Not used now)
sub loose_data {
  my $self = shift;
  return {%{$self->raw_data}, %{$self->output}};
}

# Version 0 method(Not used now)
sub invalid_params {
  my $self = shift;
  
  # Invalid parameter names
  my @invalid_params;
  foreach my $name (@{$self->invalid_rule_keys}) {
      my $param = $self->{_error_infos}->{$name}{original_key};
      $param = [$param] unless ref $param eq 'ARRAY';
      push @invalid_params, @$param;
  }
  
  return \@invalid_params;
}

# Version 0 attributes(Not used now)
sub data {
  my $self = shift;
  
  if (@_) {
    return $self->output(@_);
  }
  else {
    return $self->output;
  }
}
has raw_data  => sub { {} };
has missing_params => sub { [] };

# DEPRECATED!
sub error_reason {

  warn "Validator::Custom::Result error_reason is DEPRECATED!.";

  my ($self, $name) = @_;
  
  # Parameter name not specified
  croak 'Parameter name must be specified'
    unless $name;
  
  # Error reason
  return $self->{_error_infos}->{$name}{reason};
}

# DEPRECATED!
has error_infos => sub { {} };
# DEPRECATED!
sub add_error_info {
  my $self = shift;
  warn "add_error_info method is DEPRECATED!";
  # Merge
  my $error_infos = ref $_[0] eq 'HASH' ? $_[0] : {@_};
  $self->error_infos({%{$self->error_infos}, %$error_infos});
  return $self;
}
# DEPRECATED!
sub error {
  warn "error_info method is DEPRECATED!";
  shift->message(@_)
}
# DEPRECATED!
sub errors { 
  warn "errors method is DEPRECATED!";
  return wantarray
       ? @{shift->messages(@_)}
       : shift->messages(@_);
}
# DEPRECATED!
sub errors_to_hash {
  warn "errors_to_hash method is DEPRECATED!";
  shift->messages_to_hash(@_)
}
# DEPRECATED!
sub invalid_keys {
  warn "invalid_keys method is DEPRECATED!";
  return wantarray
     ? @{shift->invalid_rule_keys(@_)}
     : shift->invalid_rule_keys(@_);
}
# DEPRECATED!
sub remove_error_info {
  my ($self, $key) = @_;
  warn "remove_error_info method is DEPRECATED!";
  # Remove
  delete $self->error_infos->{$key};
  return $self;
}

1;

=head1 NAME

Validator::Custom::Result - Result of validation

=head1 SYNOPSYS
    
  # Result
  my $result = $rule->validate($input);

  # Output
  my $output = $result->output;

  # Chacke if the result is valid.
  my $is_ok = $result->is_ok;

  # Check if one parameter is valid
  my $title_is_valid = $result->is_valid('title');

  # Invalid rule keys
  my $invalid_rule_keys = $result->invalid_rule_keys;

  # A error message
  my $message = $result->message('title');

  # Error messages
  my $messages = $result->messages;

  # Error messages to hash ref
  my $messages_hash = $result->message_to_hash;
  
  # Result to hash
  my $rhash = $result->to_hash;

=head1 ATTRIBUTES

=head2 output

  my $output = $result->output;
  $result  = $result->output($output);

Get the output in the end state. L<Validator::Custom> has filtering ability
if you need.
Input is passed to C<validate()> method, and after validation the input is converted to output by filter.
You can get filtered output using C<output>.

=head1 METHODS

L<Validator::Custom::Result> inherits all methods from L<Object::Simple>
and implements the following new ones.

=head2 invalid_rule_keys

  my $invalid_rule_keys = $result->invalid_rule_keys;

Invalid rule keys

=head2 is_ok

  my $is_ok = $result->is_ok;

If you check the data is completely valid, use C<is_ok()>.
C<is_ok()> return true value
if invalid parameter values is not found and all parameter
names specified in the rule is found in the data.

=head2 is_valid

  my $title_is_valid = $result->is_valid('title');

Check if one parameter is valid.

=head2 message

  my $message = $result->message('title');

Get a message corresponding to the parameter name which value is invalid.

=head2 messages

  my $messages = $result->messages;

Get messages corresponding to the parameter names which value is invalid.
Messages keep the order of parameter names of the rule.

=head2 messages_to_hash

  my $messages = $result->messages_to_hash;

You can get the pairs of invalid parameter name and message
using C<messages_to_hash()>.

=head2 to_hash

  my $rhash = $result->to_hash;

Convert result information to hash reference.
The following keys is set.

  {
    ok =>      $result->is_ok,
    messages => $result->messages_to_hash
  }

=cut
