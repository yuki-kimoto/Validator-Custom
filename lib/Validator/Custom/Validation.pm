package Validator::Custom::Validation;
use Object::Simple -base;

use Carp 'croak';

sub new {
  my $self = shift->SUPER::new(@_);
  
  $self->{_failed_infos} = {};
  
  return $self;
}

sub is_valid {
  my ($self, $name) = @_;
 
  if (defined $name) {
    return exists $self->{_failed_infos}->{$name} ? 0 : 1;
  }
  else {
    return !(keys %{$self->{_failed_infos}}) ? 1 : 0;
  }
}

sub add_failed {
  my ($self, $key, $message) = @_;
  
  my $failed_infos = $self->{_failed_infos};
  
  if ($failed_infos->{$key}) {
    croak "\"$key\" is already exists";
  }
  
  my $failed_keys = keys %$failed_infos;
  
  if (@$failed_keys) {
    my $max_pos = 0
    for my $key (@$failed_keys) {
      my $pos = $failed_infos->{$key}{position};
      if ($pos > $max_pos) {
        $max_pos = $pos;
      }
    }
    $pos = $max_pos + 1;
  }
  else {
    $pos = 0;
  }
  
  $failed_infos->{$key}{pos} = $pos;
  $failed_infos->{$key}{message} = $message;
  
  return $self;
}

sub failed {
  my $self = shift;
  
  # Invalid rule keys
  my $failed_infos = $self->{_failed_infos};
  my @invalid_rule_keys = sort { $failed_infos->{$a}{position} <=>
    $failed_infos->{$b}{position} } keys %$failed_infos;
  
  return \@invalid_rule_keys;
}

sub message {
  my ($self, $name) = @_;
  
  # Parameter name not specified
  croak 'Parameter name must be specified'
    unless $name;
  
  return $self->{_failed_infos}->{$name}{message}
    || $self->{_default_messages}{$name}
    || 'Error message not specified';
}

sub messages {
  my $self = shift;

  # Error messages
  my @messages;
  my $failed_infos = $self->{_failed_infos};
  my @keys = sort { $failed_infos->{$a}{position} <=>
    $failed_infos->{$b}{position} } keys %$failed_infos;
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
  foreach my $name (keys %{$self->{_failed_infos}}) {
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
