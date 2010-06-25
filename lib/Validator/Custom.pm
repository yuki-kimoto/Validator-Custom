package Validator::Custom;

use strict;
use warnings;

use base 'Object::Simple';

use Carp 'croak';
use Validator::Custom::Result;

__PACKAGE__->dual_attr('constraints', default => sub { {} },
                                      inherit => 'hash_copy');
__PACKAGE__->attr('data_filter');
__PACKAGE__->attr(error_stock => 1);
__PACKAGE__->attr('rule');

__PACKAGE__->attr(syntax => <<'EOS');
### Syntax of validation rule
    my $rule = [                          # 1. Rule is array ref
        key1 => [                         # 2. Constraints is array ref
            'constraint1_1',              # 3. Constraint is string
            ['constraint1_2', 'error1_2'],#      or arrya ref (error message)
            {'constraint1_3' => 'string'} #      or hash ref (arguments)
              
        ],
        key2 => [
            {'constraint2_1'              # 4. Argument is string
              => 'string'},               #
            {'constraint2_2'              #     or array ref
              => ['arg1', 'arg2']},       #
            {'constraint1_3'              #     or hash ref
              => {k1 => 'v1', k2 => 'v2'}}#
        ],
        key3 => [                           
            [{constraint3_1 => 'string'}, # 5. Combination argument
             'error3_1' ]                 #     and error message
        ],
        { key4 => ['key4_1', 'key4_2'] }  # 6. Multi key validation
            => [
                'constraint4_1'
               ],
        key5 => [
            '@constraint5_1'              # 7. array's items validation
        ]
    ];

EOS

sub register_constraint {
    my $invocant = shift;
    
    # Merge
    my $constraints = ref $_[0] eq 'HASH' ? $_[0] : {@_};
    $invocant->constraints({%{$invocant->constraints}, %$constraints});
    
    return $invocant;
}

sub validate {
    my ($self, $data, $rule) = @_;
    
    # Class
    my $class = ref $self;
    
    # Validation rule
    $rule ||= $self->rule;
    
    # Data filter
    my $filter = $self->data_filter;
    $data = $filter->($data) if $filter;
    
    # Check data
    croak "First argument must be hash ref"
      unless ref $data eq 'HASH';
    
    # Check rule
    croak "Validation rule must be array ref\n" .
          "(see syntax of validation rule 1)\n" .
          $self->_rule_syntax($rule)
      unless ref $rule eq 'ARRAY';
    
    # Result
    my $result = Validator::Custom::Result->new;
    
    # Error is stock?
    my $error_stock = $self->error_stock;
    
    # Valid keys
    my $valid_keys = {};
    
    # Error position
    my $position = 0;
    
    # Process each key
    OUTER_LOOP:
    for (my $i = 0; $i < @{$rule}; $i += 2) {
        
        # Increment position
        $position++;
        
        # Key and constraints
        my ($key, $constraints) = @{$rule}[$i, ($i + 1)];
        
        # Check constraints
        croak "Constraints of validation rule must be array ref\n" .
              "(see syntax of validation rule 2)\n" .
              $self->_rule_syntax($rule)
          unless ref $constraints eq 'ARRAY';
        
        # Arrange key
        my $result_key = $key;
        if (ref $key eq 'HASH') {
            my $first_key = (keys %$key)[0];
            $result_key = $first_key;
            $key         = $key->{$first_key};
        }
        elsif (ref $key eq 'ARRAY') {
            $result_key = "$key";
        }
        
        # Already valid
        next if $valid_keys->{$result_key};
        
        # Validation
        my $value;
        foreach my $constraint (@$constraints) {
            
            # Arrange constraint information
            my ($constraint, $message)
              = ref $constraint eq 'ARRAY' ? @$constraint : ($constraint);
            
            # Data type
            my $data_type = {};
            
            # Arguments
            my $arg;
            
            # Arrange constraint
            if(ref $constraint eq 'HASH') {
                my $first_key = (keys %$constraint)[0];
                $arg        = $constraint->{$first_key};
                $constraint = $first_key;
            }
            
            # Constraint function
            my $constraint_function;
            
            # Sub reference
            if( ref $constraint eq 'CODE') {
                
                # Constraint function
                $constraint_function = $constraint;
            }
            
            # Constraint key
            else {
                
                # Array constraint
                if($constraint =~ /^\@(.+)$/) {
                    $data_type->{array} = 1;
                    $constraint = $1;
                }
                
                # Check constraint key
                croak "Constraint type '$constraint' must be [A-Za-z0-9_]"
                  if $constraint =~ /\W/;
                
                # Constraint function
                $constraint_function = $self->constraints->{$constraint};
                
                # Check constraint function
                croak "'$constraint' is not resisted"
                  unless ref $constraint_function eq 'CODE'
            }
            
            # Is valid?
            my $is_valid;
            
            # Data is array
            if($data_type->{array}) {
                
                # Set value
                unless (defined $value) {
                    $value = ref $data->{$key} eq 'ARRAY' 
                           ? $data->{$key}
                           : [$data->{$key}]
                }
                
                # Validation loop
                my $elements;
                foreach my $data (@$value) {
                    
                    # Array element
                    my $element;
                    
                    # Validation
                    my $constraint_result
                      = $constraint_function->($data, $arg, $self);
                    
                    # Constrint result
                    if (ref $constraint_result eq 'ARRAY') {
                        ($is_valid, $element) = @$constraint_result;
                        
                        $elements ||= [];
                        push @$elements, $element;
                    }
                    else {
                        $is_valid = $constraint_result;
                    }
                    
                    # Validation error
                    last unless $is_valid;
                }
                
                # Update value
                $value = $elements if $elements;
            }
            
            # Data is scalar
            else {
                
                # Set value
                $value = ref $key eq 'ARRAY'
                       ? [map { $data->{$_} } @$key]
                       : $data->{$key}
                  unless defined $value;
                
                # Validation
                my $constraint_result
                  = $constraint_function->($value, $arg, $self);
                
                if (ref $constraint_result eq 'ARRAY') {
                    ($is_valid, $value) = @$constraint_result;
                }
                else {
                    $is_valid = $constraint_result;
                }
            }
            
            # Add error if it is invalid
            unless ($is_valid) {
                
                # Resist error info
                $result->add_error_info(
                    $result_key => {message  => $message,
                                    position => $position,
                                    reason   => $constraint})
                  unless exists $result->error_infos->{$result_key};
                
                # No Error strock
                unless ($error_stock) {
                    # Check rest constraint
                    my $found;
                    for (my $k = $i + 2; $k < @{$rule}; $k += 2) {
                        my $key = $rule->[$k];
                        $key = (keys %$key)[0] if ref $key eq 'HASH';
                        $found = 1 if $key eq $result_key;
                    }
                    last OUTER_LOOP unless $found;
                }
                next OUTER_LOOP;
            }
        }
        
        # Product
        $result->data->{$result_key} = $value;
        
        # Key is valid
        $valid_keys->{$result_key} = 1;
        
        # Remove invalid key
        $result->remove_error_info($result_key);
    }
    
    return $result;
}

sub _rule_syntax {
    my ($self, $rule) = @_;
    
    my $message = $self->syntax;
    
    require Data::Dumper;
    $message .= "### Your validation rule:\n";
    $message .= Data::Dumper->Dump([$rule], ['$rule']);
    $message .= "\n";
    return $message;
}

=head1 NAME

Validator::Custom - Simple Data Validation

=head1 VERSION

Version 0.1103

=cut

our $VERSION = '0.1103';

=head1 SYNOPSYS
    
    use Validator::Custom;

    # New
    my $validator = Validator::Custom->new;
    
    # Register constraint
    $validator->register_constraint(
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
        },
        length => sub {
            my ($value, $args) = @_;
            my ($min, $max) = @$args;
            my $length = length $value;
            my $is_valid = $length >= $min && $length <= $max;
            return $is_valid;
        },
        trim => sub {
            my $value = shift;
            
            $value =~ s/^\s+/;
            $value =~ s/\s+$/;
            
            return [1, $value];
        }
    );
    
    # Data
    my $data = { 
        age => 19, 
        names => ['abcoooo', 'def']
    };
    
    # Validation rule
    $validator->rule([
        age => [
            'int'
        ],
        names => [
            ['@not_blank',          "name must exist"],
            ['@ascii',              "name must be ascii"],
            [{'@length' => [1, 5]}, "name must be 1 to 5"]
        ]
    ]);
    
    # Data filter
    $validator->data_filter(
        sub { 
            my $data = shift;
            
            # Do something
            
            return $data;
        }
    );
    
    # Validation
    my $result = $validator->validate($data);
    
    # Error messages
    my @errors = $result->errors;
    
    # One error message
    my $error = $result->error('age');

    # Error messages by hash ref
    my $errors = $result->errors_to_hash;

    # Invalid keys
    my @invalid_keys = $result->invalid_keys;
    
    # Result data
    my $result_data = $result->data;
    
    # Is the result valid?
    my $ret = $result->is_valid;
    
    # Is one data valid
    $ret = $result->is_valid('age');
    
    # Corelative validation
    my $rule = [
        {password_check => [qw/password1 password2/]} => [
            ['duplicate', 'Passwor is not same']
        ]
    ];
    
    # "OR" validation
    $rule = [
        email => [
            'blank'
        ],
        email => [
            'not_blank',
            'emai_address'
        ]
    ];

=head1 DESCRIPTIONS

Data validation is offten needed in HTML form data. 
L<Validator::Custom> help you to do this.
L<Validator::Custom> is very simple and useful validator.

You can register your constraint functions easily.
you can get ordered error message.
L<Validator::Custom> also provide OR validation.

At first, I explain the simplest example.

    # Load module and create object
    use Validator::Custom;
    my $validator = Validator::Custom->new;
    

You can register constraint function. This function receive a value.
If the value is integer, return ture. If the value is not integer,
return false.
   
    # Register constraint function
    $validator->register_constraint(
        int => sub {
            my $value    = shift;
            my $is_valid = $value =~ /^\d+$/;
            return $is_valid;
        }        
    );

Data which will be used on validation must be hash refernce.

    # Data
    my $data = { 
        age => 19, 
        height => 189
    };    

Validation rule is defined. The rule must be array reference.
Odd number argument is data's key. 
Even number argument is constarint functions.
constraint functions must be array referecne.

    # Validation rule
    my $rule = [
        age => [
            'int'
        ],
        height => [
            'int'
        ]
    ]);

Validation is done by using data and rule.

    my $result = $validator->validate($data, $rule);

validate() return value is L<Validator::Custom::Result> object.
This has validation result, such as error message, invalid keys,
converted data.

    # Restlt
    my $result = $validator->validate($data, $rule);
    
    # Error message
    my @errors = $result->errors;
    
    # Invalid keys
    my @invalid_keys = $result->invalid_keys;
    
    # Producted values
    my $data   = $result->data;
    my $value = $data->{key};
    
    # Is it valid?
    my $is_valid = $result->is_valid;

I explanin constraint function's more details.

    # Register constraint
    $validator->register_constraint(
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
        },
        length => sub {
            my ($value, $args) = @_;
            my ($min, $max) = @$args;
            my $length = length $value;
            my $is_valid = $length >= $min && $length <= $max;
            return $is_valid;
        },
        trim => sub {
            my $value = shift;
            
            $value =~ s/^\s+/;
            $value =~ s/\s+$/;
            
            return [1, $value];
        }
    );

Constrant function receive three arguments.

    1. value
    2. arguments
    3. Validator::Cotsom object

    my $data = {key => 'value'};
    my $rule => {
        key => [
            {'name' => $args}
        ],
    }

    $validator->register_constraint(name => sub {
        my ($value, $args, $self) = @_;
        
        # ...
        
        return $is_valid;
    });

constraint function also can return converted value.

    $validator->register_constraint(name => sub {
        my ($value, $args, $self) = @_;
        
        $value += 3;
        
        return ($is_valid, $value);
    });

You can create your validation class, which inherit Validator::Custom.
You can register_constraint() from package to register constraint to you class.

    package Validator::Custom::Yours;
    use base 'Validator::Custom';

    __PACKAGE__->register_constraint(
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

L<Validator::Custom::Trim>, L<Validator::Custom::HTMLForm> is good example.

L<Validator:Custom> provide 'OR' validation.
Key is written repeatedly in 'OR' validation.

    # OR validation
    $validator->rule(
        key1 => ['constraint'],
        key1 => ['constraint2']
    );

C<Example>

if "email" is blank or email address, "email" is valid, 
    
    $validator->rule([
        email => [
            'blank'
        ],
        email => [
            'not_blank',
            'email_address'
        ]
    ]);

=head1 ATTRIBUTES

=head2 C<constraints>

Constraint functions

    $validator          = $validator->constraints($constraints);
    $constraints = $validator->constraints;

Example

    $validator->constraints(
        int    => sub { ... },
        string => sub { ... }
    );
    
=head2 C<error_stock>

Are errors stocked?

    $validator   = $validator->error_stock(0);
    $error_stock = $validator->error_stcok;
    
If you set 0, validation errors is not stocked.
Validation is finished when one error is occured.
This is faster than stocking all errors.

Default is 1. All errors are stocked.

=head2 C<data_filter>

Data filtering function

    $validator = $validator->data_filter($filter);
    $filter    = $validator->data_filter;

Data filtering function is available.
This function receive data, which is first argument of validate().
and return converted data.

    $validator->data_filter(
        sub {
            my $data = shift;
            
            # Do someting
            
            return $data;
        }
    )

=head2 C<rule>

Validation rule

    $validator   = $validator->rule($rule);
    $rule        = $validator->rule;

Validation rule has the following syntax.

    ### Syntax of validation rule         
    my $rule = [                          # 1. Validation rule is array ref
        key1 => [                         # 2. Constraints is array ref
            'constraint1_1',              # 3. Constraint is string
            ['constraint1_2', 'error1_2'],#      or arrya ref (error message)
            {'constraint1_3' => 'string'} #      or hash ref (arguments)
              
        ],
        key2 => [
            {'constraint2_1'              # 4. Argument is string
              => 'string'},               #
            {'constraint2_2'              #     or array ref
              => ['arg1', 'arg2']},       #
            {'constraint1_3'              #     or hash ref
              => {k1 => 'v1', k2 => 'v2'}}#
        ],
        key3 => [                           
            [{constraint3_1 => 'string'}, # 5. Combination argument
             'error3_1' ]                 #     and error message
        ],
        { key4 => ['key4_1', 'key4_2'] }  # 6. Multi key validation
            => [
                'constraint4_1'
               ],
        key5 => [
            '@constraint5_1'              # 7. array's items validation
        ]
    ];

=head2 C<syntax>

Syntax of validation rule

    $validator = $validator->syntax($syntax);
    $syntax    = $validator->syntax;

=head1 MEHTODS

=head2 C<new>

Constructor

    $validator = Validator::Costom->new;
    $validator = Validator::Costom->new(rule => [ .. ]);

=head2 C<register_constraint>

Add constraint function

    $validator->register_constraint(%constraint);
    $validator->register_constraint(\%constraint);
    
Example
    
    $validator->register_constraint(
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

add_constraint() is now depricated. Please use register_constraint.

=head2 C<validate>

Validation

    $result = $validator->validate($data, $rule);
    $result = $validator->validate($data);

If you omit $rule, $validator->rule is used.
Return value is L<Validator::Custom::Result> object.

=head1 STABILITY

This module is stable. The following attribute and method names will not be changed in the future, and keep backword compatible.

    # DBIx::Custom
    constraints
    error_stock
    data_filter
    rule
    syntax
    new
    register_constraint
    validate

    # DBIx::Custom::Result
    error_infos
    data
    add_error_info
    is_valid
    error
    errors
    error_reason
    errors_to_hash
    invalid_keys
    remove_error_info

=head1 AUTHOR

Yuki Kimoto, C<< <kimoto.yuki at gmail.com> >>

Development L<http://github.com/yuki-kimoto/Validator-Custom>

=head1 COPYRIGHT & LICENCE

Copyright 2009 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
