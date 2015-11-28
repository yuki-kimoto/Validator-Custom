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
  my ($self, $name, $message) = @_;
  
  my $failed_infos = $self->{_failed_infos};
  
  if ($failed_infos->{$name}) {
    croak "\"$name\" is already exists";
  }
  
  my @failed_names = keys %$failed_infos;
  my $pos;
  if (@failed_names) {
    my $max_pos = 0;
    for my $failed_name (@failed_names) {
      my $pos = $failed_infos->{$failed_name}{position};
      if ($pos > $max_pos) {
        $max_pos = $pos;
      }
    }
    $pos = $max_pos + 1;
  }
  else {
    $pos = 0;
  }
  
  $failed_infos->{$name}{pos} = $pos;
  
  unless (defined $message) {
    $message = "$name is invalid";
  }
  $failed_infos->{$name}{message} = $message;
  
  return $self;
}

sub failed {
  my $self = shift;
  
  my $failed_infos = $self->{_failed_infos};
  my @failed = sort { $failed_infos->{$a}{position} <=>
    $failed_infos->{$b}{position} } keys %$failed_infos;
  
  return \@failed;
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
  my @names = sort { $failed_infos->{$a}{position} <=>
    $failed_infos->{$b}{position} } keys %$failed_infos;
  foreach my $name (@names) {
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

1;

=head1 NAME

Validator::Custom::Validation - Validation result

=head1 SYNOPSYS

  my $validation = $vc->validation;
  
  $validation->add_failed(title => 'title is invalid');
  $validation->add_failed(name => 'name is invalid');
  
  # Is valid
  my $is_valid = $validation->is_valid;
  my $title_is_valid = $validation->is_valid('title');
  
  # Failed key names
  my $failed = $validation->failed;
  
  # Message
  my $messages = $validation->messages;
  my $title_message = $validation->message('title');
  my $messages_h = $validation->messages_to_hash;
