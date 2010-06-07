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

sub add_constraint {
    warn "\"add_constraint \"is now depricated. " .
         "Please \"use register_constraint\"";
    
    shift->register_constraint(@_);
}

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
                
                # Is first validation?
                my $first_validation = 1;
                
                # Validation loop
                my $converted_values;
                foreach my $data (@$value) {
                    
                    # Converted value
                    my $converted_value;
                    
                    # Validation
                    eval {
                        ($is_valid, $converted_value)
                          = $constraint_function->($data, $arg, $self);
                    };
                    croak "Constraint exception(Key '$result_key')." .
                          " Error message: $@\n"
                      if $@;
                    
                    # Validation error
                    last unless $is_valid;
                    
                    # Add converted value
                    if (defined $converted_value) {
                        if ($first_validation) {
                            $converted_values  = [];
                            $first_validation = 0;
                        }
                        push @{$converted_values}, $converted_value;
                    }
                }
                
                # Update value
                $value = $converted_values if defined $converted_values;
            }
            
            # Data is scalar
            else {
                
                # Set value
                unless (defined $value) {
                    $value = ref $key eq 'ARRAY'
                           ? [map { $data->{$_} } @$key]
                           : $data->{$key}
                }
                
                my $converted_value;
                
                # Validation
                eval {
                    ($is_valid, $converted_value)
                      = $constraint_function->($value, $arg, $self);
                };
                croak "Constraint exception(Key '$result_key'). " .
                      "Error message: $@\n"
                  if $@;
                
                # Update value
                $value = $converted_value 
                  if $is_valid && defined $converted_value;
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

Validator::Custom - Custamizable validator

=head1 VERSION

Version 0.1101

=cut

our $VERSION = '0.1101';
$VERSION = eval $VERSION;

=head1 STATE

This module is not stable. APIs will be changed for a while.

=head1 SYNOPSYS
    
    use Validator::Custom;

    # New
    my $validator = Validator::Custom->new;
    
    # Add Constraint
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
    
    # "or" validation
    $rule = [
        email => [
            'blank'
        ],
        # or
        email => [
            'not_blank',
            'email'
        ]
    ];
        
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

=head1 Validator::Custom::Result

'validate' method return L<Validator::Custom::Result> object.

See L<Validator::Custom::Result>.

The following is L<Validator::Custom::Result> example

    # Restlt
    my $result = $validator->validate($data, $rule);
    
    # Error message
    my @errors = $result->errors;
    
    # Invalid keys
    my @invalid_keys = $result->invalid_keys;
    
    # Producted values
    my $data   = $result->data;
    my $value1 = $data->{key1};
    
    # Is it valid?
    my $is_valid = $result->is_valid;

=head1 CONSTRAINT FUNCTION

You can resist your constraint function using 'register_constraint' method.

Constrant function can receive three argument.

    1. validating data(which is first argument of validator())
    2. arguments(which is in validation rule)
    3. Validator::Cotsom object

I explain using example. You can pass argument in validation rule.
and you can receive the argument in constraint function

    my $data = {key => 'value'}; # 1. value
    my $rule => {
        key => [
            {'name' => $args} # 2. arguments
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

L<Validator::Custom::HTML::Form> is good example.

=head1 CUSTOM CLASS

You can create your custom class extending Validator::Custom.

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

This class is avalilable same way as Validator::Custom

   $validator = Validator::Custom::Yours->new;

L<Validator::Custom::Trim>, L<Validator::Custom::HTMLForm> is good example.

=head1 OR VALIDATION

This module also provide 'or' validation.
You write key constaraint in a rule repeateadly.
one of the constraint is valid, the key is valid.

$validator->rule(
    key1 => ['constraint'],
    key1 => ['constraint2']
);

C<Example>

"email" is valid, if 'email' is blank or mail address, 
To understand "or validation" easily,
it is good practice to add "# or" comment to your code.
    
    $validator->rule([
        email => [
            'blank'
        ],
        # or
        email => [
            'not_blank',
            'email'
        ]
    ]);

=head1 AUTHOR

Yuki Kimoto, C<< <kimoto.yuki at gmail.com> >>

Development L<http://github.com/yuki-kimoto/Validator-Custom>

=head1 COPYRIGHT & LICENCE

Copyright 2009 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Validator::Custom