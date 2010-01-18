package Validator::Custom::Result;
use base 'Object::Simple::Base';

my $p = __PACKAGE__;

$p->attr(_errors  => (type => 'array', default => sub { []} ))
  ->attr(products => (type => 'hash',  default => sub { {} }, deref => 1));

# Invalid keys 
sub invalid_keys {
    my $self = shift;
    
    # Extract invalid keys
    my @invalid_keys;
    foreach my $error (@{$self->_errors}) {
        
        push @invalid_keys, $error->{invalid_key};
        
    }
    
    return wantarray ? @invalid_keys : \@invalid_keys;
}

# Error messages
sub errors {
    my $self = shift;
    
    # Extract error messages
    my @errors;
    foreach my $error (@{$self->_errors}) {

        push @errors, $error->{message} if defined $error->{message};
        
    }
    
    return wantarray ? @errors : \@errors;
}

# Check valid or not
sub is_valid {
    my ($self, $key) = @_;
    
    # Nothing errors
    return @{$self->invalid_keys} ? 0 : 1 unless defined $key;
    
    # Specified key is invalid
    foreach my $error ($self->_errors) {
        
        return if $error->{invalid_key} eq $key;
        
    }
    return 1;
}

# error message
sub error {
    my ($self, $key) = @_;
    
    foreach my $error ($self->_errors) {
    
        return $error->{message} if $error->{invalid_key} eq $key;
    
    }
    
    return;
}

=head1 Validator::Custom::Result

=head1 NAME

Validator::Custom::Result - Validator::Custom result object

=head1 SYNOPSYS
    
    # Error message
    @errors = $result->errors;
    
    # A Error message
    $error = $result->error('title');
    
    # Invalid keys
    @invalid_keys = $result->invalid_keys;
    
    # Producted values
    $products = $result->products;
    $product  = $products->{key1};
    
    # Is it valid all?
    $is_valid = $result->is_valid;
    
    # Is it valid a value
    $is_valid = $result->is_valid('title');

=head1 Accessors

=head2 products

Set and get producted values

    $result   = $result->products($products);
    $products = $result->products;

    $product = $products->{key};

=head1 Methods

=head2 is_valid

Check if invalid_keys exsits

    $is_valid = $result->is_valid;

You can specify a key to check if that key is invalid.

    $is_valid = $result->is_valid('title');

=head2 errors

Get error messages

    $errors = $result->errors;
    @errors = $result->errors;

=head2 error

Get error message corresponding to a key.

    $error = $result->error('title');

=head2 invalid_keys

Get invalid keys

    @invalid_keys = $result->invalid_keys;
    $invalid_keys = $result->invalid_keys;

=head1 See also

L<Validator::Custom>

=cut
