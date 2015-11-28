package Validator::Custom::Validation;
use Object::Simple -base;

use Carp 'croak';

sub is_valid {
  my ($self, $name) = @_;
 
  if (defined $name) {
    return exists $self->{_error_infos}->{$name} ? 0 : 1;
  }
  else {
    return !(keys %{$self->{_error_infos}}) ? 1 : 0;
  }
}

sub failed {
  my $self = shift;
  
  # Invalid rule keys
  my $error_infos = $self->{_error_infos};
  my @invalid_rule_keys = sort { $error_infos->{$a}{position} <=>
    $error_infos->{$b}{position} } keys %$error_infos;
  
  return \@invalid_rule_keys;
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

=head1 NAME

Validator::Custom::Validation - Validation result

=head1 SYNOPSYS

  my $validation = $vc->validation;
  
  $validation->add_failed(title => 'title is invalid');
  $validation->add_failed(name => 'name is invalid');
  
  # Is valid
  my $is_valid = $validation->is_valid;
  my $title_is_valid = $validation->is_valid('title');
  
  # Failed keys
  my $failed = $validation->failed;
  
  # Message
  my $messages = $validation->messages;
  my $title_message = $validation->message('title');
  my $messages_h = $validation->messages_to_hash;
