package Validator::Custom::Result;

use strict;
use warnings;

use base 'Object::Simple';

use Carp 'croak';

__PACKAGE__->attr(data           => sub { {} });
__PACKAGE__->attr(raw_data       => sub { {} });
__PACKAGE__->attr(missing_params => sub { [] });

our $DEFAULT_MESSAGE = 'Error message not specified';

sub is_valid {
    my $self = shift;
    
    # Is valid?
    return keys %{$self->{_error_infos}} || @{$self->missing_params}
         ? 0 : 1;
}

sub messages {
    my $self = shift;

    # Error messages
    my @messages;
    my $error_infos = $self->{_error_infos};
    my @keys = sort { $error_infos->{$a}{position} <=>
                      $error_infos->{$b}{position} }
               keys %$error_infos;
    foreach my $name (@keys) {
        my $message = $error_infos->{$name}{message}
                   || $self->{_default_messages}{$name}
                   || $DEFAULT_MESSAGE;
        push @messages, $message if defined $message;
    }
    
    return \@messages;
}

sub messages_to_hash {
    my $self = shift;
    
    # Error informations
    my $error_infos = $self->{_error_infos};
    
    # Error messages
    my $messages = {};
    foreach my $name (keys %$error_infos) {
        $messages->{$name} = $error_infos->{$name}{message}
                          || $self->{_default_messages}{$name}
                          || $DEFAULT_MESSAGE;
    }
    
    return $messages;
}

sub message {
    my ($self, $name) = @_;
    
    # Parameter name not specifed
    croak 'Parameter name must be specified'
      unless $name;
    
    return $self->messages_to_hash->{$name};
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

sub invalid_rule_keys {
    my $self = shift;
    
    # Invalid rule keys
    my $error_infos = $self->{_error_infos};
    my @invalid_rule_keys = sort { $error_infos->{$a}{position} <=>
                              $error_infos->{$b}{position} }
                              keys %$error_infos;
    
    return \@invalid_rule_keys;
}

sub error_reason {
    my ($self, $name) = @_;
    
    # Parameter name not specifed
    croak 'Parameter name must be specified'
      unless $name;
    
    # Error reason
    return $self->{_error_infos}->{$name}{reason};
}

### Deprecated attributes and methods

__PACKAGE__->attr(error_infos    => sub { {} });

sub add_error_info {
    my $self = shift;
    
    # Merge
    my $error_infos = ref $_[0] eq 'HASH' ? $_[0] : {@_};
    $self->error_infos({%{$self->error_infos}, %$error_infos});
    
    return $self;
}

sub remove_error_info {
    my ($self, $key) = @_;
    
    # Remove
    delete $self->error_infos->{$key};
    
    return $self;
}

sub error { shift->message(@_) }
sub errors { 
    return wantarray
         ? @{shift->messages(@_)}
         : shift->messages(@_);
}
sub errors_to_hash { shift->messages_to_hash(@_) }
sub invalid_keys {
    return wantarray
         ? @{shift->invalid_rule_keys(@_)}
         : shift->invalid_rule_keys(@_);
}

1;

=head1 NAME

Validator::Custom::Result - Result of validation

=head1 SYNOPSYS
    
    # Result
    my $result = $vc->validate($data, $rule);
    
    # Chacke if the result is valid.
    my $is_valid = $result->is_valid;
    
    # Missing parameters
    my $missing_params = $result->missing_params;
    
    # Error messages
    my $messages = $result->messages;

    # Error messages to hash ref
    my $messages_hash = $result->message_to_hash;
    
    # A error message
    my $message = $result->message('title');
    
    # Invalid parameter names
    my $invalid_params = $result->invalid_params;
    
    # Invalid rule keys
    my $invalid_rule_keys = $result->invalid_rule_keys;
    
    # Raw data
    my $raw_data = $result->raw_data;
    
    # Result data
    my $result_data = $result->data;

=head1 ATTRIBUTES

=head2 C<data>

Result data.

    my $data = $result->data;
    $result  = $result->data($data);

=head2 C<raw_data>

Raw data soon after data_filter is excuted.

    my $data  = $result->raw_data;
    $result   = $result->raw_data($data);

=head2 C<(experimental) missing_params>

Missing paramters

    my $missing_params = $result->missing_params;
    $result            = $result->missing_params($missing_params);

=head2 C<(depricated) error_infos>

Error informations.

    my $error_infos = $result->error_infos;
    $result         = $result->error_infos($error_infos);

=head1 METHODS

L<Validator::Custom::Result> inherits all methods from L<Object::Simple>
and implements the following new ones.

=head2 C<is_valid>

Check if the result is valid.

    $is_valid = $result->is_valid;

=head2 C<messages>

Error messages.

    $messages = $result->messages;

=head2 C<message>

Error message.

    $message = $result->message('title');

=head2 C<messages_to_hash>

Error messages to hash reference.

    $messages = $result->messages_to_hash;

=head2 C<invalid_params>

Invalid raw data parameter names.

    $invalid_params = $result->invalid_params;

=head2 C<invalid_rule_keys>

Invalid rule keys

    $invalid_rule_keys = $result->invalid_rule_keys;

=head2 C<error_reason>

Error reason. This is constraint name.

    $error_reason = $result->error_reason('title');

=head2 C<(depricated) add_error_info>

Add error informations.

    $result->add_error_info($name => $error_info);

=head2 C<(depricated) remove_error_info>

Remove error information.

    $result->remove_error_info($name);

=head2 C<(deprecated) errors>

errors() is deprecated. Please use message() instead.

Error messages.

    $errors = $result->errors;
    @errors = $result->errors;

=head2 C<(deprecated) errors_to_hash>

errors_to_hash() is deprecated. Please use messages_to_hash() instead.

Error messages to hash reference.

    $errors = $result->errors_to_hash;

=head2 C<(deprecated) error> 

error() is deprecated. Use message() instead.

A error message

    $error = $result->error('title');

=head2 C<(deprecated) invalid_keys>

invalid_keys() is deprecated. Use invalid_rule_keys() instead.

Invalid rule keys.

    @invalid_keys = $result->invalid_keys;
    $invalid_keys = $result->invalid_keys;

=cut
