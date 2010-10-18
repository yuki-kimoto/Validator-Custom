package Validator::Custom::Result;

use strict;
use warnings;

use base 'Object::Simple';

use Carp 'croak';

# Attrbutes
__PACKAGE__->attr(data           => sub { {} });
__PACKAGE__->attr(missing_params => sub { [] });
__PACKAGE__->attr(raw_data       => sub { {} });

# Default message
our $DEFAULT_MESSAGE = 'Error message not specified';

sub error_reason {
    my ($self, $name) = @_;
    
    # Parameter name not specifed
    croak 'Parameter name must be specified'
      unless $name;
    
    # Error reason
    return $self->{_error_infos}->{$name}{reason};
}

sub has_invalid {
    my $self = shift;
    
    # Has invalid parameter?
    return keys %{$self->{_error_infos}} ? 1 : 0;
}

sub has_missing { @{shift->missing_params} ? 1 : 0 }

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

sub is_valid {
    my ($self, $name) = @_;
    
    # Deprecated
    unless (defined $name) {
        warn "Validator::Custom::Result is_valid() method without argument" .
             " is deprecated. Use is_ok()";
        return $self->is_ok;
    }
    
    return exists $self->{_error_infos}->{$name} ? 0 : 1;
}

sub is_ok {
    my $self = shift;
    
    # Is ok?
    return !$self->has_invalid && !$self->has_missing ? 1 : 0;
}

sub message {
    my ($self, $name) = @_;
    
    # Parameter name not specifed
    croak 'Parameter name must be specified'
      unless $name;
    
    return $self->{_error_infos}->{$name}{message}
        || $self->{_default_messages}{$name}
        || $DEFAULT_MESSAGE;
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


### Deprecated attributes and methods

__PACKAGE__->attr(error_infos    => sub { {} });
sub add_error_info {
    my $self = shift;
    
    # Merge
    my $error_infos = ref $_[0] eq 'HASH' ? $_[0] : {@_};
    $self->error_infos({%{$self->error_infos}, %$error_infos});
    
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

sub remove_error_info {
    my ($self, $key) = @_;
    
    # Remove
    delete $self->error_infos->{$key};
    
    return $self;
}

1;

=head1 NAME

Validator::Custom::Result - Result of validation

=head1 SYNOPSYS
    
    # Result
    my $result = $vc->validate($data, $rule);
    
    # Check the existence of missing parameter
    my $has_missing_param = $result->has_missing;

    # Chack if the data has invalid parameter(except for missing parameter)
    my $has_invalid = $resutl->has_invalid;
    
    # Chacke if the result is valid.
    # (this means result have neither missing nor invalid parameter)
    my $is_ok = $result->is_ok;
    
    # Check if one parameter is valid
    my $title_is_valid = $result->is_valid('title');

    # Missing parameters(this is original keys)
    my $missing_params = $result->missing_params;
    
    # Invalid parameter names(this is original keys)
    my $invalid_params = $result->invalid_params;
    
    # Invalid rule keys
    my $invalid_rule_keys = $result->invalid_rule_keys;

    # A error message
    my $message = $result->message('title');

    # Error messages
    my $messages = $result->messages;

    # Error messages to hash ref
    my $messages_hash = $result->message_to_hash;
    
    # Raw data
    my $raw_data = $result->raw_data;
    
    # Result data
    my $result_data = $result->data;

=head1 ATTRIBUTES

=head2 C<data>

    my $data = $result->data;
    $result  = $result->data($data);

Result data.

=head2 C<missing_params>

    my $missing_params = $result->missing_params;
    $result            = $result->missing_params($missing_params);

Missing parameters

=head2 C<raw_data>

    my $data  = $result->raw_data;
    $result   = $result->raw_data($data);

Raw data soon after data_filter is excuted.

=head1 METHODS

L<Validator::Custom::Result> inherits all methods from L<Object::Simple>
and implements the following new ones.

=head2 C<error_reason>

    $error_reason = $result->error_reason('title');

Error reason. This is constraint name.

=head2 C<has_invalid>

    my $has_invalid = $result->has_invalid;

Check if the data has invalid parameter

=head2 C<has_missing>

    my $has_missing_param = $result->has_missing;

Check the existence of missing parameter.

=head2 C<invalid_params>

    $invalid_params = $result->invalid_params;

Invalid raw data parameter names.

=head2 C<invalid_rule_keys>

    $invalid_rule_keys = $result->invalid_rule_keys;

Invalid rule keys

=head2 C<is_ok>

    $is_ok = $result->is_ok;

Check if the result is ok. this means that
data has no missing parameter and no invalid parameter.

=head2 C<is_valid>

    my $title_is_valid = $result->is_valid('title');

Check if one paramter is valid.

=head2 C<message>

    $message = $result->message('title');

Error message.

=head2 C<messages>

    $messages = $result->messages;

Error messages.

=head2 C<messages_to_hash>

    $messages = $result->messages_to_hash;

Error messages to hash reference.

=cut
