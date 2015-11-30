package Validator::Custom::Result;
use Object::Simple -base;

use Carp 'croak';

# Attrbutes
has data => sub { {} };
has raw_data  => sub { {} };
has missing_params => sub { [] };

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

sub is_ok {
  my $self = shift;
  
  # Is ok?
  return !$self->has_invalid && !$self->has_missing ? 1 : 0;
}

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

sub invalid_rule_keys {
  my $self = shift;
  
  # Invalid rule keys
  my $error_infos = $self->{_error_infos};
  my @invalid_rule_keys = sort { $error_infos->{$a}{position} <=>
    $error_infos->{$b}{position} } keys %$error_infos;
  
  return \@invalid_rule_keys;
}

sub has_missing { @{shift->missing_params} ? 1 : 0 }

sub has_invalid {
  my $self = shift;
  
  # Has invalid parameter?
  return keys %{$self->{_error_infos}} ? 1 : 0;
}

sub loose_data {
  my $self = shift;
  return {%{$self->raw_data}, %{$self->data}};
}

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

Validator::Custom::Result - DEPRECATED
