package Validator::Custom;
use Object::Simple;

use strict;
use warnings;
use Carp 'croak';

use Validator::Custom::Result;

# Get constraint functions
sub constraints : HybridAttr {
    type  => 'hash',
    build => sub {{}},
    clone => 'hash',
    deref => 1,
}

# Add constraint function
sub add_constraint {
    my $invocant = shift;
    
    my $constraints = ref $_[0] eq 'HASH' ? $_[0] : {@_};
    $invocant->constraints(%{$invocant->constraints}, %$constraints);
    
    return $invocant;
}

### Accessors

# Validation rule
sub validation_rule : Attr {}

# Error is stock?
sub error_stock  : Attr { default => 1 }

### Methods

# Validate
sub validate {
    my ($self, $data, $validation_rule) = @_;
    my $class = ref $self;
    
    # Validation rule
    $validation_rule ||= $self->validation_rule;
    
    # Data must be hash ref
    croak "Data which passed to validate method must be hash ref"
      unless ref $data eq 'HASH';
    
    # Validation rule must be array ref
    croak "Validation rule must be array ref\n" .
          "(see syntax of validation rule 1)\n" .
          $self->_validation_rule_usage($validation_rule)
      unless ref $validation_rule eq 'ARRAY';
    
    # Result object
    my $result = Validator::Custom::Result->new;
    
    # Error is stock?
    my $error_stock = $self->error_stock;
    
    # Process each key
    VALIDATOR_LOOP:
    for (my $i = 0; $i < @{$validation_rule}; $i += 2) {
        my ($key, $constraints) = @{$validation_rule}[$i, ($i + 1)];
        
        croak "Constraints of validation rule must be array ref\n" .
              "(see syntax of validation rule 2)\n" .
              $self->_validation_rule_usage($validation_rule)
          unless ref $constraints eq 'ARRAY';
        
        # Rearrange key
        my $product_key = $key;
        
        if (ref $key eq 'HASH') {
            my $first_key = (keys %$key)[0];
            ($product_key, $key) = ($first_key, $key->{$first_key});
        }
        elsif (ref $key eq 'ARRAY') {
            $product_key = "$key";
        }
        
        my $value;
        my $products;
        foreach my $constraint (@$constraints) {
            
            # Rearrange validator information
            my ($constraint, $error_message)
              = ref $constraint eq 'ARRAY' ? @$constraint : ($constraint);
            
            my $data_type = {};
            my $arg;
            
            if(ref $constraint eq 'HASH') {
                my $first_key = (keys %$constraint)[0];
                ($constraint, $arg) = ($first_key, $constraint->{$first_key});
            }
            
            my $constraint_function;
            # Expression is code reference
            if( ref $constraint eq 'CODE') {
                $constraint_function = $constraint;
            }
            
            # Expression is string
            else {
                if($constraint =~ /^\@(.+)$/) {
                    $data_type->{array} = 1;
                    $constraint = $1;
                }
                
                croak "Constraint type '$constraint' must be [A-Za-z0-9_]"
                  if $constraint =~ /\W/;
                
                # Get validator function
                $constraint_function = $self->constraints->{$constraint};
                
                croak "'$constraint' is not resisted"
                  unless ref $constraint_function eq 'CODE'
            }
            
            # Validate
            my $is_valid;
            if($data_type->{array}) {
                
                $value = ref $data->{$key} eq 'ARRAY' ? $data->{$key} : [$data->{$key}]
                  unless defined $value;
                
                my $first_validation = 1;
                foreach my $data (@$value) {
                    my $product;
                    eval {
                        ($is_valid, $product) = $constraint_function->($data, $arg, $self);
                    };
                    
                    croak "Constraint exception(Key '$product_key'). Error message: $@\n"
                      if $@;
                    
                    last unless $is_valid;
                    
                    if (defined $product) {
                        if ($first_validation) {
                            $products = [];
                            $first_validation = 0;
                        }
                        push @{$products}, $product;
                    }
                }
                $value = $products if defined $products;
            }
            else {
                $value = ref $key eq 'ARRAY' ? [map { $data->{$_} } @$key] : $data->{$key}
                  unless defined $value;
                
                eval {
                    ($is_valid, $products) = $constraint_function->($value, $arg, $self);
                };
                
                croak "Constraint exception(Key '$product_key'). Error message: $@\n"
                  if $@;
                
                $value = $products if $is_valid && defined $products;
            }
            
            # Add error if it is invalid
            unless($is_valid){
                $products = undef;
                
                # Resist error info
                push @{$result->_errors},
                     {invalid_key => $product_key, message => $error_message};
                
                last VALIDATOR_LOOP unless $error_stock;
                next VALIDATOR_LOOP;
            }
        }
        $result->products->{$product_key} = $products if defined $products;
    }
    return $result;
}

sub syntax {return <<'EOS' }
### Syntax of validation rule         
my $validation_rule = [               # 1.Validation rule must be array ref
    key1 => [                         # 2.Constraints must be array ref
        'constraint1_1',              # 3.Constraint can be string
        ['constraint1_2', 'error1_2'],#     or arrya ref (error message)
        {'constraint1_3' => 'string'} #     or hash ref (arguments)
          
    ],
    key2 => [
        {'constraint2_1'              # 4.Argument can be string
          => 'string'},               #
        {'constraint2_2'              #     or array ref
          => ['arg1', 'arg2']},       #
        {'constraint1_3'              #     or hash ref
          => {k1 => 'v1', k2 => 'v2}} #
    ],
    key3 => [                           
        [{constraint3_1' => 'string'},# 5.Combination argument
         'error3_1' ]                 #     and error message
    ],
    { key4 => ['key4_1', 'key4_2'] }  # 6.Multi key validation
        => [
            'constraint4_1'
           ]
    key5 => [
        '@constraint5_1'              # 7.Array each value validation
    ]
];

EOS

# Validation rule usage
sub _validation_rule_usage {
    my ($self, $validation_rule) = @_;
    
    my $message = $self->syntax;
    
    require Data::Dumper;
    $message .= "### Your validation rule:\n";
    $message .= Data::Dumper->Dump([$validation_rule], ['$validation_rule']);
    $message .= "\n";
    return $message;
}

# Build class
Object::Simple->build_class;

=head1 NAME

Validator::Custom - Custom validator

=head1 VERSION

Version 0.0703

=cut

our $VERSION = '0.0703';

=head1 SYNOPSYS
    
    ### How to use Validator::Custom
    
    
    # Validate
    my $vc = Validator::Custom->new
    
    # Constraint
    $vc->add_constraint(
        int => sub {
            my $value    = shift;
            my $is_valid = $value =~ /^\d+$/;
            return $is_valid;
        },
        ascii => sub {
            my $value    = shift;
            my $is_valid = $value =~ /^[\x21-\x7E]+$/;
            return $is_valid;
        },
        not_blank => sub {
            my $value = shift;
            my $is_valid = $value ne '';
            return $is_valid;
        }
        length => sub {
            my ($value, $args) = @_;
            my ($min, $max) = @$args;
            my $is_valid = $min <= $length && $length <= $max;
            return $is_valid;
        }
    );
    
    # Data
    my $data = { age => 19, names => ['abc', 'def'] };
    
    # Validation rule
    $vc->validation_rule([
        age => [
            'int'
        ],
        '@names' => [
            ['not_blank',          "name must exist"],
            ['ascii',              "name must be ascii"],
            [{'length' => [1, 5]}, "name must be 1 to 5"]
        ]
    ]);
    
    # Validation
    my $result = $vc->validate($data, $validation_rule);
    
    # Get errors
    my @errors = $result->errors;
    
    # Handle errors
    foreach my $error (@errors) {
        # ...
    }
    
    # Get invalid keys
    my @invalid_keys = $result->invalid_keys;
    
    # Get producted value
    my $products = $result->products;
    
    # Check valid or not
    if($result->is_valid) {
        # ...
    }
    
    # Corelative check
    my $validation_rule => [
        [qw/password1 password2/] => [
            ['duplicate', 'Passwor is not same']
        ]
    ]
    
    # Specify key
    my $validation_rule => [
        {password_check => [qw/password1 password2/]} => [
            ['duplicate', 'Passwor is not same']
        ]
    ]
    
=head1 Accessors

=head2 constraints

get constraints
    
Set and get constraint functions

    $vc          = $vc->constraints($constraints); # hash or hash ref
    $constraints = $vc->constraints;

constraints sample

    $vc->constraints(
        int    => sub { ... },
        string => sub { ... }
    );

See also 'add_constraint' method

=head2 error_stock

Set and get whether error is stocked or not.

    $vc          = $vc->error_stock(1);
    $error_stock = $vc->error_stcok;
    
If you set stock_error 1, occured error on validation is stocked,
and you can get all errors by errors mehtods.

If you set stock_error 0, you can get only first error by errors method.

This is very high performance if you know only whether error occur or not.

    $vc->stock_error(0);
    $is_valid = $vc->validate($data, $validation_rule)->is_valid;

error_stock default is 1. 

=head2 validation_rule

Set and get validation rule

    $vc              = $vc->validation_rule($validation_rule);
    $validation_rule = $vc->validation_rule;

Validation rule has the following syntax

    ### Syntax of validation rule         
    my $validation_rule = [               # 1.Validation rule must be array ref
        key1 => [                         # 2.Constraints must be array ref
            'constraint1_1',              # 3.Constraint can be string
            ['constraint1_2', 'error1_2'],#     or arrya ref (error message)
            {'constraint1_3' => 'string'} #     or hash ref (arguments)
              
        ],
        key2 => [
            {'constraint2_1'              # 4.Argument can be string
              => 'string'},               #
            {'constraint2_2'              #     or array ref
              => ['arg1', 'arg2']},       #
            {'constraint1_3'              #     or hash ref
              => {k1 => 'v1', k2 => 'v2}} #
        ],
        key3 => [                           
            [{constraint3_1' => 'string'},# 5.Combination argument
             'error3_1' ]                 #     and error message
        ],
        { key4 => ['key4_1', 'key4_2'] }  # 6.Multi key validation
            => [
                'constraint4_1'
               ]
        key5 => [
            '@constraint5_1'              # 7. array ref each value validation
        ]
    ];
    
You can see this syntax using 'syntax' method

    print $vc->syntax;

=head1 Mehtods

=head2 new

Create object

    $vc = Validator::Costom->new;

=head2 validate

validate data

    # Validation
    $result = $vc->validate($data, $validation_rule);
    $result = $vc->validate($data);

If you omit $validation_rule, $vc->validation_rule is used.

See 'validation_rule' description about validation rule.

This method return L<Validator::Custom::Result> object,

See also L<Validator::Custom::Result>.

=head2 add_constraint

Add constraint

    $vc->add_constraint($constraint); # hash or hash ref

'add_constraint' sample
    
    $vc->add_constraint(
        int => sub {
            my $value    = shift;
            my $is_valid = $value =~ /^\-?[\d]+$/;
            return $is_valid;
        },
        ascii => sub {
            my $value    = shift;
            my $is_valid = $value =~ /^[\x21-\x7E]+$/;
            return $is_valid;
        }
    );

=head2 syntax

Set and get syntax of validation rule

    $vc     = $vc->syntax($syntax);
    $syntax = $vc->syntax;

=head1 Validator::Custom::Result

'validate' method return L<Validator::Custom::Result> object.

See L<Validator::Custom::Result>.

The following is L<Validator::Custom::Result> sample

    # Restlt
    $result = $vc->validate($data, $validation_rule);
    
    # Error message
    @errors = $result->errors;
    
    # Invalid keys
    @invalid_keys = $result->invalid_keys;
    
    # Producted values
    $products = $result->products;
    $product  = $products->{key1};
    
    # Is it valid?
    $is_valid = $result->is_valid;

=head1 Constraint function

You can resist your constraint function using 'add_constraint' method.

canstrant function can receive two argument.

    1. value in validating data
    2. argument passed in validation rule

I explain using sample. You can pass argument in validation rule.
and you can receive the argument in constraint function

    my $data = {key => 'value'}; # 1. value
    my $validation_rule => {
        key => [
            {'name' => $args} # 2. arguments
        ],
    }

    $vc->add_constraint(name => sub {
        my ($value, $args) = @_;
        
        # ...
        
        return $is_valid;
    });

constraint function also can return producted value.

    $vc->add_constraint(name => sub {
        my ($value, $args) = @_;
        
        # ...
        
        return ($is_valid, $product);
    });

L<Validator::Custom::HTML::Form> 'time' constraint function is good sample.

=head1 Create custom class extending Validator::Custom 

You can create your custom class extending Validator::Custom.

    package Validator::Custom::Yours;
    use base 'Validator::Custom';

    __PACKAGE__->add_constraint(
        int => sub {
            my $value    = shift;
            my $is_valid = $value =~ /^\-?[\d]+$/;
            return $is_valid;
        },
        ascii => sub {
            my $value    = shift;
            my $is_valid = $value =~ /^[\x21-\x7E]+$/;
            return $is_valid;
        }
    );

This class is avalilable same way as Validator::Custom

   $vc = Validator::Custom::Yours->new;

L<Validator::Custom::Trim>, L<Validator::Custom::HTMLForm> is good sample.

=head1 Author

Yuki Kimoto, C<< <kimoto.yuki at gmail.com> >>

Github L<http://github.com/yuki-kimoto>

I develope this module at L<http://github.com/yuki-kimoto/Validator-Custom>

I also support at IRC irc.perl.org#validator-custom

=head1 Copyright & licence

Copyright 2009 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Validator::Custom