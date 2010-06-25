package Validator::Custom::Result;

use strict;
use warnings;

use base 'Object::Simple';

use Carp 'croak';

__PACKAGE__->attr(error_infos  => sub { {} });
__PACKAGE__->attr(data         => sub { {} });

our $DEFAULT_MESSAGE = 'Error message not specified';

sub add_error_info {
    my $self = shift;
    
    # Merge
    my $error_infos = ref $_[0] eq 'HASH' ? $_[0] : {@_};
    $self->error_infos({%{$self->error_infos}, %$error_infos});
    
    return $self;
}

sub error {
    my ($self, $name) = @_;
    
    # Key name not specifed
    croak 'Key name must be specified'
      unless $name;
    
    # Error infomations
    my $error_infos = $self->error_infos;
    
    # Error
    my $error = exists $error_infos->{$name}
              ? $error_infos->{$name}{message} || $DEFAULT_MESSAGE
              : undef;
    
    return $error;
}

sub error_reason {
    my ($self, $name) = @_;
    
    # Key name not specifed
    croak 'Key name must be specified'
      unless $name;
    
    # Error reason
    return $self->error_infos->{$name}{reason};
}

sub errors {
    my $self = shift;

    # Errors
    my @errors;
    my $error_infos = $self->error_infos;
    my @keys = sort { $error_infos->{$a}{position} <=>
                      $error_infos->{$b}{position} }
               keys %$error_infos;
    foreach my $key (@keys) {
        my $message = $error_infos->{$key}{message} || $DEFAULT_MESSAGE;
        push @errors, $message if defined $message;
    }
    
    return wantarray ? @errors : \@errors;
}

sub errors_to_hash {
    my $self = shift;
    
    # Error informations
    my $error_infos = $self->error_infos;
    
    # Errors
    my $errors = {};
    foreach my $name (keys %$error_infos) {
        $errors->{$name} = $error_infos->{$name}{message} || 
                           $DEFAULT_MESSAGE;
    }
    
    return $errors;
}

sub invalid_keys {
    my $self = shift;
    
    # Invalid keys
    my $error_infos = $self->error_infos;
    my @invalid_keys = sort { $error_infos->{$a}{position} <=>
                              $error_infos->{$b}{position} }
                             keys %$error_infos;
    
    return wantarray ? @invalid_keys : \@invalid_keys;
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

=head1 METHODS

=head2 C<add_error_info>

Add error informations

    $result->add_error_info($error_info);

Example

    $result->add_error_info({invalid_key => $product_key,
                             message     => $message});

=head2 C<is_valid>

Check if result is valid.

    $is_valid = $result->is_valid;

Check if the data corresponding to the key is valid.

    $is_valid = $result->is_valid('title');

=head2 C<error>

Get one error message.

    $error = $result->error('title');

=head2 C<errors>

Get error messages

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

=head2 C<remove_error_info>

Remove error information

    $result->remove_error_info($key);
    
=cut
