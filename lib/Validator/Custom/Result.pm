package Validator::Custom::Result;

use strict;
use warnings;

use base 'Object::Simple';

use Carp 'croak';

__PACKAGE__->attr(error_infos  => sub { {} });
__PACKAGE__->attr(data         => sub { {} });
__PACKAGE__->attr(raw_data     => sub { {} });

our $DEFAULT_MESSAGE = 'Error message not specified';

sub add_error_info {
    my $self = shift;
    
    # Merge
    my $error_infos = ref $_[0] eq 'HASH' ? $_[0] : {@_};
    $self->error_infos({%{$self->error_infos}, %$error_infos});
    
    return $self;
}

sub error { shift->error_message(@_) }

sub errors { 
    return wantarray
         ? @{shift->error_messages(@_)}
         : shift->error_messages(@_);
}

sub errors_to_hash { shift->error_messages_to_hash(@_) }

sub error_reason {
    my ($self, $name) = @_;
    
    # Parameter name not specifed
    croak 'Parameter name must be specified'
      unless $name;
    
    # Error reason
    return $self->error_infos->{$name}{reason};
}

sub invalid_keys {
    return wantarray
         ? @{shift->invalid_params(@_)}
         : shift->invalid_params(@_);
}

sub is_valid {
    my ($self, $key) = @_;
    
    # Error is nothing
    return keys %{$self->error_infos} ? 0 : 1 unless defined $key;
    
    # Specified key is invalid
    return exists $self->error_infos->{$key} ? 0 : 1;
}

sub remove_error_info {
    my ($self, $key) = @_;
    
    # Remove
    delete $self->error_infos->{$key};
    
    return $self;
}

sub error_message {
    my ($self, $name) = @_;
    
    # Parameter name not specifed
    croak 'Parameter name must be specified'
      unless $name;
    
    # Error infomations
    my $error_infos = $self->error_infos;
    
    # Error
    return exists $error_infos->{$name}
         ? $error_infos->{$name}{message} || $DEFAULT_MESSAGE
         : undef;
}

sub error_messages {
    my $self = shift;

    # Error messages
    my @error_messages;
    my $error_infos = $self->error_infos;
    my @keys = sort { $error_infos->{$a}{position} <=>
                      $error_infos->{$b}{position} }
               keys %$error_infos;
    foreach my $key (@keys) {
        my $message = $error_infos->{$key}{message} || $DEFAULT_MESSAGE;
        push @error_messages, $message if defined $message;
    }
    
    return \@error_messages;
}

sub error_messages_to_hash {
    my $self = shift;
    
    # Error informations
    my $error_infos = $self->error_infos;
    
    # Error messages
    my $error_messages = {};
    foreach my $name (keys %$error_infos) {
        $error_messages->{$name} = $error_infos->{$name}{message} || 
                           $DEFAULT_MESSAGE;
    }
    
    return $error_messages;
}

sub invalid_params {
    my $self = shift;
    
    # Invalid params
    my $error_infos = $self->error_infos;
    my @invalid_params = sort { $error_infos->{$a}{position} <=>
                              $error_infos->{$b}{position} }
                              keys %$error_infos;
    
    return \@invalid_params;
}

sub invalid_raw_params {
    my $self = shift;
    
    # Invalid params
    my $error_infos = $self->error_infos;
    my @invalid_params = sort { $error_infos->{$a}{position} <=>
                              $error_infos->{$b}{position} }
                              keys %$error_infos;
    
    # Invalid raw params
    my @invalid_raw_params;
    foreach my $name (@invalid_params) {
        my $raw_param = $error_infos->{$name}{original_key};
        $raw_param = [$raw_param] unless ref $raw_param eq 'ARRAY';
        push @invalid_raw_params, @$raw_param;
    }
    
    return \@invalid_raw_params;
}

1;

=head1 NAME

Validator::Custom::Result - Validator::Custom result

=head1 SYNOPSYS
    
    # Error messages
    @errors = $result->errors;
    
    # One error message
    $error = $result->error('title');
    
    # Error messages as hash ref
    $errors = $result->errors_to_hash;
    
    # Invalid keys
    @invalid_keys = $result->invalid_keys;
    
    # Result data
    $data   = $result->data;
    $value1 = $data->{key1};
    
    # Is the result valid?
    $is_valid = $result->is_valid;
    
    # Is one data valid?
    $is_valid = $result->is_valid('title');

=head1 ATTRIBUTES

=head2 C<error_infos>

Error infos

    $result      = $result->error_infos($error_infos);
    $error_infos = $result->error_infos;

=head2 C<data>

Result data

    $result = $result->data($data);
    $data   = $result->data;

=head2 C<raw_data>

Raw data soon after data_filter is excuted.

    $result = $result->raw_data($data);
    $data   = $result->raw_data;

=head1 METHODS

=head2 C<is_valid>

Check if result is valid.

    $is_valid = $result->is_valid;

Check if the data corresponding to the key is valid.

    $is_valid = $result->is_valid('title');

=head2 C<error>

Error message.

    $error = $result->error('title');

=head2 C<errors>

Error messages

    $errors = $result->errors;
    @errors = $result->errors;

=head2 C<error_reason>

Get error reason. this is same as constraint name.

    $error_reason = $result->error_reason($key);

=head2 C<errors_to_hash>

Get error messages as hash ref

    $errors = $result->errors_to_hash;

=head2 C<invalid_keys>

Get invalid keys

    @invalid_keys = $result->invalid_keys;
    $invalid_keys = $result->invalid_keys;

=head2 C<add_error_info>

Add error informations

    $result->add_error_info($name => $error_info);

=head2 C<remove_error_info>

Remove error information

    $result->remove_error_info($name);


=head2 error_message EXPERIMENTAL

Error message.

    $error_message = $result->error_message('title');

=head2 error_messages EXPERIMENTAL

Error messages.

    $error_messages = $result->error_messages;

=head2 error_messages_to_hash EXPERIMENTAL

Error messages as hash reference.

    $error_messages = $result->error_messages_to_hash;

=head2 invalid_params EXPERIMENTAL

Invalid parameter names

    $invalid_params = $result->invalid_params;

=head2 invalid_raw_params EXPERIMENTAL

Invalid raw data parameter names.

    $raw_invalid_params = $result->invalid_raw_params;

=cut
