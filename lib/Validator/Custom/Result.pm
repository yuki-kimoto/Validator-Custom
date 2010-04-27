package Validator::Custom::Result;

use strict;
use warnings;

use base 'Object::Simple';

__PACKAGE__->attr(error_infos    => sub { {} });
__PACKAGE__->attr(products       => sub { {} });

sub add_error_info {
    my $self = shift;
    
    # Merge
    my $error_infos = ref $_[0] eq 'HASH' ? $_[0] : {@_};
    $self->error_infos({%{$self->error_infos}, %$error_infos});
    
    return $self;
}

sub error        { shift->error_infos->{$_[0]}{message} }
sub error_reason { shift->error_infos->{$_[0]}{reason} }

sub errors {
    my $self = shift;

    # Errors
    my @errors;
    my $error_infos = $self->error_infos;
    my @keys = sort { $error_infos->{$a}{position} <=>
                      $error_infos->{$b}{position} }
               keys %$error_infos;
    foreach my $key (@keys) {
        my $message = $error_infos->{$key}{message};
        push @errors, $message if defined $message;
    }
    
    return wantarray ? @errors : \@errors;
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

=head2 C<add_error_info>

Add error informations

    $result->add_error_info($error_info);

Sample

    $result->add_error_info({invalid_key => $product_key,
                             message     => $message});

=head2 C<is_valid>

Check if result is valid.

    $is_valid = $result->is_valid;

Check if the data corresponding to the key is valid.

    $is_valid = $result->is_valid('title');

=head2 C<error>

Get error message corresponding to a key.

    $error = $result->error('title');

=head2 C<errors>

Get all error messages

    $errors = $result->errors;
    @errors = $result->errors;

=head2 C<error_reason>

Get error reason. this is same as constraint name.

    $error_reason = $result->error_reason($key);

=head2 C<invalid_keys>

Get invalid keys

    @invalid_keys = $result->invalid_keys;
    $invalid_keys = $result->invalid_keys;

=head2 C<remove_error_info>

Remove error information

    $result->remove_error_info($key);
    
=cut
