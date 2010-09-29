package Validator::Custom::Result;

use strict;
use warnings;

use base 'Object::Simple';

use Carp 'croak';

__PACKAGE__->attr(data           => sub { {} });
__PACKAGE__->attr(raw_data       => sub { {} });
__PACKAGE__->attr(missing_params => sub { [] });

our $DEFAULT_MESSAGE = 'Error message not specified';

sub is_ok {
    my $self = shift;
    
    # Is ok?
    return !$self->has_invalid && !$self->has_missing ? 1 : 0;
}

sub has_invalid {
    my $self = shift;
    
    # Has invalid parameter?
    return keys %{$self->{_error_infos}} ? 1 : 0;
}

sub has_missing { @{shift->missing_params} ? 1 : 0 }

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

sub is_valid { shift->is_ok(@_) }

1;

=head1 NAME

Validator::Custom::Result - Result of validation

=head1 SYNOPSYS
    
    # Result
    my $result = $vc->validate($data, $rule);
    
    # (experimental) Chacke if the result is valid.
    my $is_ok = $result->is_ok;
    
    # (experimental) Check the existence of missing parameter
    my $has_missing_param = $result->has_missing
    
    # (experimental) Missing parameters
    my $missing_params = $result->missing_params;
    
    # (experimental) Chack if the data has invalid parameter
    my $has_invalid = $result->has_invalid;
    
    # Invalid parameter names
    my $invalid_params = $result->invalid_params;
    
    # Invalid rule keys
    my $invalid_rule_keys = $result->invalid_rule_keys;

    # Error messages
    my $messages = $result->messages;

    # Error messages to hash ref
    my $messages_hash = $result->message_to_hash;
    
    # A error message
    my $message = $result->message('title');
    
    # Raw data
    my $raw_data = $result->raw_data;
    
    # Result data
    my $result_data = $result->data;

=head1 ATTRIBUTES

=head2 C<data>

    my $data = $result->data;
    $result  = $result->data($data);

Result data.

=head2 C<raw_data>

    my $data  = $result->raw_data;
    $result   = $result->raw_data($data);

Raw data soon after data_filter is excuted.

=head2 C<(experimental) missing_params>

    my $missing_params = $result->missing_params;
    $result            = $result->missing_params($missing_params);

Missing parameters

=head2 C<(depricated) error_infos>

    my $error_infos = $result->error_infos;
    $result         = $result->error_infos($error_infos);

Error informations.

=head1 METHODS

L<Validator::Custom::Result> inherits all methods from L<Object::Simple>
and implements the following new ones.

=head2 C<is_ok>

    $is_ok = $result->is_ok;

Check if the result is ok. ok means that
data has no missing parameter and no invalid parameter.

=head2 C<(experimental) has_missing>

    my $has_missing_param = $result->has_missing;

Check the existence of missing parameter.

=head2 C<messages>

    $messages = $result->messages;

Error messages.

=head2 C<message>

    $message = $result->message('title');

Error message.

=head2 C<messages_to_hash>

    $messages = $result->messages_to_hash;

Error messages to hash reference.

=head2 C<(experimental) has_invalid>

    my $has_invalid = $result->has_invalid;

Check if the data has invalid parameter

=head2 C<invalid_params>

    $invalid_params = $result->invalid_params;

Invalid raw data parameter names.

=head2 C<invalid_rule_keys>

    $invalid_rule_keys = $result->invalid_rule_keys;

Invalid rule keys

=head2 C<error_reason>

    $error_reason = $result->error_reason('title');

Error reason. This is constraint name.

=head2 C<(depricated) add_error_info>

    $result->add_error_info($name => $error_info);

Add error informations.

=head2 C<(depricated) remove_error_info>

    $result->remove_error_info($name);

Remove error information.

=head2 C<(deprecated) errors>

errors() is deprecated. Please use message() instead.

    $errors = $result->errors;
    @errors = $result->errors;

Error messages.

=head2 C<(deprecated) errors_to_hash>

errors_to_hash() is deprecated. Please use messages_to_hash() instead.

    $errors = $result->errors_to_hash;

Error messages to hash reference.

=head2 C<(deprecated) error> 

error() is deprecated. Use message() instead.

    $error = $result->error('title');

A error message

=head2 C<(deprecated) invalid_keys>

invalid_keys() is deprecated. Use invalid_rule_keys() instead.

    @invalid_keys = $result->invalid_keys;
    $invalid_keys = $result->invalid_keys;

Invalid rule keys.

=head2 C<(deprecated) is_valid>

is_valid() is deprecated. Use is_ok() instead.

    $is_valid = $result->is_valid;

Check if the result is valid.


=cut
