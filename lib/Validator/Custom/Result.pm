package Validator::Custom::Result;

use strict;
use warnings;

use base 'Object::Simple';

__PACKAGE__->attr(error_infos => sub { [] });
__PACKAGE__->attr(products    => sub { {} });

sub add_error_info {
    my ($self, $error_info) = @_;
    
    # Add error information
    push @{$self->error_infos}, $error_info;
    
    return $self;
}

sub error {
    my ($self, $key) = @_;
    
    # Error message
    foreach my $error (@{$self->error_infos}) {
        return $error->{message} if $error->{invalid_key} eq $key;
    }
    
    return;
}

sub errors {
    my $self = shift;
    
    # Error messages
    my @errors;
    foreach my $error (@{$self->error_infos}) {
        push @errors, $error->{message} if defined $error->{message};
    }
    
    return wantarray ? @errors : \@errors;
}

sub invalid_keys {
    my $self = shift;
    
    # Invalid keys
    my @invalid_keys;
    foreach my $error (@{$self->error_infos}) {
        push @invalid_keys, $error->{invalid_key};
    }
    
    return wantarray ? @invalid_keys : \@invalid_keys;
}

sub is_valid {
    my ($self, $key) = @_;
    
    # Error is nothing
    return @{$self->invalid_keys} ? 0 : 1 unless defined $key;
    
    # Specified key is invalid
    foreach my $error (@{$self->error_infos}) {
        return if $error->{invalid_key} eq $key;
    }
    
    return 1;
}

1;

=head1 Validator::Custom::Result

=head1 NAME

Validator::Custom::Result - Validator::Custom validation result

=head1 SYNOPSYS
    
    # All error messages
    @errors = $result->errors;
    
    # A error message
    $error = $result->error('title');
    
    # Invalid keys
    @invalid_keys = $result->invalid_keys;
    
    # Producted values
    $products = $result->products;
    $product  = $products->{key1};
    
    # Is All data valid?
    $is_valid = $result->is_valid;
    
    # Is a data valid?
    $is_valid = $result->is_valid('title');

=head1 ATTRIBUTES

=head2 products

Producted values

    $result   = $result->products($products);
    $products = $result->products;

=head2 error_infos

Error infos

    $result      = $result->error_infos($error_infos);
    $error_infos = $result->error_infos;

=head1 METHODS

=head2 add_error_info

Add error informations

    $result->add_error_info($error_info);

Sample

    $result->add_error_info({invalid_key => $product_key,
                             message     => $message});

=head2 is_valid

Check if result is valid.

    $is_valid = $result->is_valid;

Check if the data corresponding to the key is valid.

    $is_valid = $result->is_valid('title');

=head2 error

Get error message corresponding to a key.

    $error = $result->error('title');

=head2 errors

Get all error messages

    $errors = $result->errors;
    @errors = $result->errors;

=head2 invalid_keys

Get invalid keys

    @invalid_keys = $result->invalid_keys;
    $invalid_keys = $result->invalid_keys;
    
=cut
