package Validator::Custom;

our $VERSION = '0.1210';

use 5.008001;
use strict;
use warnings;

use base 'Object::Simple';

use Carp 'croak';
use Validator::Custom::Basic::Constraints;
use Validator::Custom::Result;

__PACKAGE__->dual_attr('constraints', default => sub { {} },
                                      inherit => 'hash_copy');

__PACKAGE__->register_constraint(
    not_defined       => \&Validator::Custom::Basic::Constraints::not_defined,
    defined           => \&Validator::Custom::Basic::Constraints::defined,
    not_space         => \&Validator::Custom::Basic::Constraints::not_space,
    not_blank         => \&Validator::Custom::Basic::Constraints::not_blank,
    blank             => \&Validator::Custom::Basic::Constraints::blank,
    int               => \&Validator::Custom::Basic::Constraints::int,
    uint              => \&Validator::Custom::Basic::Constraints::uint,
    ascii             => \&Validator::Custom::Basic::Constraints::ascii,
    shift             => \&Validator::Custom::Basic::Constraints::shift_array,
    duplication       => \&Validator::Custom::Basic::Constraints::duplication,
    length            => \&Validator::Custom::Basic::Constraints::length,
    regex             => \&Validator::Custom::Basic::Constraints::regex,
    http_url          => \&Validator::Custom::Basic::Constraints::http_url,
    selected_at_least => \&Validator::Custom::Basic::Constraints::selected_at_least,
    greater_than      => \&Validator::Custom::Basic::Constraints::greater_than,
    less_than         => \&Validator::Custom::Basic::Constraints::less_than,
    equal_to          => \&Validator::Custom::Basic::Constraints::equal_to,
    between           => \&Validator::Custom::Basic::Constraints::between,
    decimal           => \&Validator::Custom::Basic::Constraints::decimal,
    in_array          => \&Validator::Custom::Basic::Constraints::in_array,
    trim              => \&Validator::Custom::Basic::Constraints::trim,
    trim_lead         => \&Validator::Custom::Basic::Constraints::trim_lead,
    trim_trail        => \&Validator::Custom::Basic::Constraints::trim_trail,
    trim_collapse     => \&Validator::Custom::Basic::Constraints::trim_collapse
);

__PACKAGE__->attr('rule');
__PACKAGE__->attr(shared_rule => sub { [] });
__PACKAGE__->attr(error_stock => 1);
__PACKAGE__->attr('data_filter');
__PACKAGE__->attr(syntax => <<'EOS');


### Syntax of validation rule
    my $rule = [                          # 1. Rule is array ref
        key1 => [                         # 2. Constraints is array ref
            'constraint1_1',              # 3. Constraint is string
            ['constraint1_2', 'error1_2'],#      or arrya ref (message)
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
             'error3_1' ]                 #     and message
        ],
        { key4 => ['key4_1', 'key4_2'] }  # 6. Multi-paramters validation
            => [
                'constraint4_1'
               ],
        key5 => [
            '@constraint5_1'              # 7. Multi-values validation
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
    
    # Shared rule
    my $shared_rule = $self->shared_rule;
    
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

    # Save raw data
    $result->raw_data($data);
    
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
        
        # Add shared rule
        push @$constraints, @$shared_rule;
        
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
                croak "'$constraint' is not registered"
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
                    $result_key => {message      => $message,
                                    position     => $position,
                                    reason       => $constraint,
                                    original_key => $key})
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
        
        # Result data
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

1;

=head1 NAME

Validator::Custom - Validates user input easily

=head1 SYNOPSYS

Basic usages

    # Load module and create object
    use Validator::Custom;
    my $vc = Validator::Custom->new;

    # Data used at validation
    my $data = {age => 19, name => 'Ken Suzuki'};
    
    # Rule
    my $rule = [
        age => [
            'int'
        ],
        name => [
            ['not_blank',        "Name must be exists"],
            [{length => [1, 5]}, "Name length must be 1 to 5"]
        ]
    ];
    
    # Validate
    my $vresult = $vc->validate($data, $rule);

Result of validation

    ### Validator::Custom::Result
    
    # Chacke if the data is valid.
    my $is_valid = $vresult->is_valid;
    
    # Error messages
    my $messages = $vresult->messages;

    # Error messages to hash ref
    my $messages_hash = $vresult->messages_to_hash;
    
    # Error message
    my $message = $vresult->message('age');
    
    # Invalid parameter names
    my $invalid_params = $vresult->invalid_params;
    
    # Invalid rule keys
    my $invalid_rule_keys = $vresult->invalid_rule_keys;
    
    # Raw data
    my $raw_data = $vresult->raw_data;
    
    # Result data
    my $result_data = $vresult->data;
    
Advanced features

    # Register constraint
    $vc->register_constraint(
        email => sub {
            require Email::Valid;
            return 0 unless $_[0];
            return Email::Valid->address(-address => $_[0]) ? 1 : 0;
        }
    );
    
    # Multi parameters validation
    $data = {password1 => 'xxx', password2 => 'xxx'};
    $vc->register_constraint(
        same => sub {
            my $values = shift;
            my $is_valid = $values->[0] eq $values->[1];
            return [$is_valid, $values->[0]];
        }
    );
    $rule = [
        {password_check => [qw/password1 password2/]} => [
            ['same', 'Two password must be equal']
        ]
    ];
    $vresult = $vc->validate($data, $rule);

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

    # Data filter
    $vc->data_filter(
        sub { 
            my $data = shift;
            
            # Convert data to hash reference
            
            return $data;
        }
    );
            
    # Register filter , instead of constraint
    $vc->register_constraint(
        trim => sub {
            my $value = shift;
            
            $value =~ s/^\s+//;
            $value =~ s/\s+$//;
            
            return [1, $value];
        }
    );

Extending

    ### Extending Validator:Custom
    
    package YourValidator;
    use base 'Validator::Custom';
    
    __PACKAGE__->register_constraint(
    $vc->register_constraint(
        email => sub {
            require Email::Valid;
            return 0 unless $_[0];
            return Email::Valid->address(-address => $_[0]) ? 1 : 0;
        }
    );
    
    1;

=head1 DESCRIPTIONS

L<Validator::Custom> validates user input.

=head2 1. Features

=over 4

=item *

Can set a message for each parameter. the messages is added to
the result when the paramter is invalid. the messages keeps the order.

=item *

Can register constraint function. such as "int", "defined".
constraint function can receive any arguments, other than parameter value.

=item *

Can create original class, extending Validator::Custom
(See L<Validator::Custom::HTMLFOrm>)

=item *

Support multi-paramters validation, multi-values validation,
OR condition validation.

=back

=head2 2. Basic usages

Create a new L<Validator::Custom> object.

    use Validator::Custom;
    my $vc = Validator::Custom->new;

Data used in validation must be hash reference.

    my $data = { 
        age => 19, 
        name => 'Ken Suzuki'
    };

Register constraint function.
constraint must be sub reference, which check if the value is valid.

    $vc->register_constraint(
        int => sub {
            my $value    = shift;
            my $is_valid = $value =~ /^\d+$/;
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
    );

Rule for validation has a specific format. the pairs of parameter name
and constraint expressions. the format detail is explained in
"4. Syntex of rule".

    my $rule = [
        age => [
            'int'
        ],
        name => [
            ['not_blank',        "Name must be exists"],
            [{length => [1, 5]}, "Name length must be 1 to 5"]
        ],
        # PARAMETER_NAME => [
        #    CONSTRIANT_EXPRESSION1
        #    CONSTRAINT_EXPRESSION2
        # ]
    ];

Validate the data. validate() return L<Validator::Custom::Result> object.

    my $vresult = $vc->validate($data, $rule);

=head2 3. Result of validation

L<Validator::Custom::Result> object has the result of validation.

Check if the data is valid.
    
    my $is_valid = $vresult->is_valid;

Error messages
    
    # Error messages
    my $messages = $vresult->messages;

    # Error messages to hash ref
    my $messages_hash = $vresult->messages_to_hash;
    
    # A error message
    my $message = $vresult->message('age');

Invalid paramter names and invalid result keys

    # Invalid parameter names
    my $invalid_params = $vresult->invalid_params;
    
    # Invalid rule keys
    my $invalid_rule_keys = $vresult->invalid_rule_keys;

Raw data and result data

    # Raw data
    my $raw_data = $vresult->raw_data;
    
    # Result data
    my $result_data = $vresult->data;

B<Examples:>

Check the result and get error messages.

    unless ($vresult->is_valid) {
        my $messages = $vresult->messages;
        
        # Do something
    }

Check the result and get error messages as hash reference

    unless ($vresult->is_valid) {
        my $messages = $vresult->messages_to_hash;

        # Do something
    }

Combination with L<HTML::FillInForm>

    unless ($vresult->is_valid) {
        
        my $html = get_something_way();
        
        # Fill in form
        $html = HTML::FillInForm->fill(
            \$html, $vresult->raw_data,
            ignore_fields => $vresult->invalid_params
        );
        
        # Do something
    }

=head2 4. Syntax of rule

=head3 C<Basic syntax>

Rule must be array reference. This is for keeping the order of
invalid parameter names.

    my $rule = [
    
    ];

Rule contains the pairs of parameter name and list of constraint
expression.

    my $rule = [
        name => [
            'not_blank'
        ],
        age => [
            'not_blank',
            'int'
        ]
        # PARAMETER_NAME => [
        #    CONSTRIANT_EXPRESSION1
        #    CONSTRAINT_EXPRESSION2
        # ]
    ];

=head3 C<Constraint expression>

Constraint expression is one of four.

=over 4

=item 1.

constraint name

    CONSTRAINT_NAME

=item 2.

constraint name and message

    [CONSTRIANT_NAME, MESSAGE]

=item 3.

constraint name and argument

    {CONSTRAINT_NAME => ARGUMENT}

=item 4.

constraint name and argument and message

    [{CONSTRAINT_NAME => ARGUMENT}, MESSAGE]

=back

B<Example:>

    my $rule = [
        age => [
            # 1. constraint name
            'defined',
            
            # 2. constraint name and message
            ['not_blank', 'Must be not blank'],
            
            # 3. constraint name and argument
            {length => [1, 5]},
            
            # 4. constraint name and argument and message
            [{regex => qr/\d+/}, 'Invalid string']
        ]
    ];

=head3 C<Multi-paramters validation>

Multi-paramters validation is available.

    $data = {password1 => 'xxx', password2 => 'xxx'};

    $rule = [
        {password_check => [qw/password1 password2/]} => [
            ['duplication', 'Two password must be equal']
        ]
    ];

"password1" and "password2" is parameter names.
"password_check" is result key.

=head3 C<Multi-values validation>

Multi-values validation is available
if the paramter value is array reference.
Add "@" mark before constraint name.

    $data = {
        nums => [1, 2, 3]
    };
    
    $rule = [
        'nums' => [
            '@int'
        ]
    ];

=head3 C<Validation of OR condition>

OR condition validation is available.
Write paramter name repeatedly.

    $rule = [
        email => [
            'blank'
        ],
        email => [
            'not_blank',
            'emai_address'
        ]
    ];

=head3 C<Shared rule>

Can share rule with all parameters.
Shared rule is added to the
head of each list of constraint expression.

    $vc->shared_rule([
        ['defined',   'Must be defined'],
        ['not_blank', 'Must be not blank']
    ]);

=head2 5. Specification of constraint

I explain the specification of constraint.

    # Register constraint
    $vc->register_constraint(
        consrtaint_name => sub {
            my ($value, $args, $vc) = @_;
            
            # Do something
            
            return $is_valid;
        }
    )

=head3 C<Arguments and return value>

Constraint function receive three arguments.

=over 4

=item 1.

value

=item 2.

argument

=item 3.

Validator::Custom object

=back

=over 4

=item 1. value

This is the value of data.

    my $data = {name => 'Ken Suzuki'};

In this example, value is I<'Ken Suzuki'>

=item 2. argument

You can pass argument to consraint in the rule.

    my $rule = [
        name => [
            {length => [1, 5]}
        ]
    ];

In this example, argument is I<[1, 5]>.

=back

And this function must return a value to check if the value is valid.

In Multi-paramters validation, values is packed to array reference,
value is ['xxx', 'xxx'].

    $data = {password1 => 'xxx', password2 => 'xxx'};

    $rule = [
        {password_check => [qw/password1 password2/]} => [
            ['duplication', 'Two password must be equal']
        ]
    ];

=head3 C<Filtering function>

Constraint function can be also return converted value. If you return converted value, you must return array reference, which contains two
element, value to check if the value is valid,
and converted value.

    $vc->register_constraint(
        trim => sub {
            my $value = shift;
            
            $value =~ s/^\s+//;
            $value =~ s/\s+$//;
            
            return [1, $value];
        }
    );

=head2 6. Extending

Validator::Custom is easy to extend. You can register constraint
to Your class by register_constraint().
    
    package YourValidator;
    use base 'Validator::Custom';
    
    __PACKAGE__->register_constraint(
        defined  => sub { defined $_[0] }
    );
    
    1;
    
L<Validator::Custom::Trim>, L<Validator::Custom::HTMLForm> is good examples.

=head2 7. Advanced features

=head3 C<Data filtering>

If data is not hash reference, you can converted data to hash reference
by data_filter().

    $vc->data_filter(
        sub { 
            my $data = shift;
            
            # Convert data to hash reference
            
            return $data;
        }
    );

=head3 C<Stock of messages>

By default, all parameters is checked by validate(). If you want to
check only if the data is valid, it is good to finish validation when
the invalid value is found. If you set error_stock to 0, Validation is
finished soon after invalid value is found.

    $vc->error_stock(0);

=head1 ATTRIBUTES

=head2 C<constraints>

    $vc          = $vc->constraints(\%constraints);
    $constraints = $vc->constraints;

Constraint functions.

=head2 C<error_stock>

    $vc          = $vc->error_stock(1);
    $error_stock = $vc->error_stcok;

If error_stock is set to 1, all validation error is stocked.
If error_stock is set 0, Validation is finished soon after a error occur.

Default to 1. 

=head2 C<data_filter>

    $vc     = $vc->data_filter(\&filter);
    $filter = $vc->data_filter;

Filter input data. If data is not hash reference, you can convert the data to hash reference.

    $vc->data_filter(
        sub {
            my $data = shift;
            
            # Convert data to hash reference.
            
            return $data;
        }
    )

=head2 C<rule>

    $vc   = $vc->rule($rule);
    $rule = $vc->rule;

Rule for validation.
Validation rule has the following syntax.

    # Rule syntax
    my $rule = [                          # 1. Validation rule is array ref
        key1 => [                         # 2. Constraints is array ref
            'constraint1_1',              # 3. Constraint is string
            ['constraint1_2', 'error1_2'],#      or arrya ref (message)
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
             'error3_1' ]                 #     and message
        ],
        { key4 => ['key4_1', 'key4_2'] }  # 6. Multi-parameters validation
            => [
                'constraint4_1'
               ],
        key5 => [
            '@constraint5_1'              # 7. Multi-values validation
        ]
    ];

=head2 C<shared_rule>

    $vc          = $vc->shared_rule(\@rule);
    $shared_rule = $vc->shared_rule;

Shared rule. Shared rule is added the head of normal rule.

    $vc->shared_rule([
        ['defined',   'Must be defined'],
        ['not_blank', 'Must be not blank']
    ]);

=head2 C<syntax>

    $vc     = $vc->syntax($syntax);
    $syntax = $vc->syntax;

Syntax of rule.

=head1 METHODS

L<Validator::Custom> inherits all methods from L<Object::Simple>
and implements the following new ones.

=head2 C<register_constraint>

    $vc->register_constraint(%constraint);
    $vc->register_constraint(\%constraint);

Register constraint. constraint must be sub reference, which check if
the value is valid.
    
    $vc->register_constraint(
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

=head2 C<validate>

    $vresult = $vc->validate($data, $rule);
    $vresult = $vc->validate($data);

Validate the data.
Return value is L<Validator::Custom::Result> object.
If the rule of second arument is ommited, rule attribute is used for validation.

=head1 Constraints

=head2 C<defined>

Check if the data is defined.

=head2 C<not_defined>

Check if the data is not defined.

=head2 C<not_blank>

Check if the data is not blank.

=head2 C<blank>

Check if the is blank.

=head2 C<not_space>

Check if the data do not containe space.

=head2 C<int>

Check if the data is integer.
    
    # valid data
    123
    -134

=head2 C<uint>

Check if the data is unsigned integer.

    # valid data
    123
    
=head2 C<decimal>
    
    my $data = { num => '123.45678' };
    my $rule => [
        num => [
            {'decimal' => [3, 5]}
        ]
    ];

    Validator::Custom::HTMLForm->new->validate($data,$rule);

Each numbers (3,5) mean maximum digits before/after '.'

=head2 C<ascii>

check is the data consists of only ascii code.

=head2 C<length>

Check the length of the data.

The following sample check if the length of the data is 4 or not.

    my $data = { str => 'aaaa' };
    my $rule => [
        num => [
            {'length' => 4}
        ]
    ];

When you set two arguments, it checks if the length of data is in
the range between 4 and 10.
    
    my $data = { str => 'aaaa' };
    my $rule => [
        num => [
            {'length' => [4, 10]}
        ]
    ];

=head2 C<http_url>

Verify it is a http(s)-url

    my $data = { url => 'http://somehost.com' };
    my $rule => [
        url => [
            'http_url'
        ]
    ];

=head2 C<selected_at_least>

Verify the quantity of selected parameters is counted over allowed minimum.

    <input type="checkbox" name="hobby" value="music" /> Music
    <input type="checkbox" name="hobby" value="movie" /> Movie
    <input type="checkbox" name="hobby" value="game"  /> Game
    
    
    my $data = {hobby => ['music', 'movie' ]};
    my $rule => [
        hobby => [
            {selected_at_least => 1}
        ]
    ];

=head2 C<regex>

Check with regular expression.
    
    my $data = {str => 'aaa'};
    my $rule => [
        str => [
            {regex => qr/a{3}/}
        ]
    ];

=head2 C<duplication>

Check if the two data are same or not.

    my $data = {mail1 => 'a@somehost.com', mail2 => 'a@somehost.com'};
    my $rule => [
        [qw/mail1 mail2/] => [
            'duplication'
        ]
    ];

=head2 C<shift>

Shift the head of array reference.

    my $data = {nums => [1, 2]};
    my $rule => [
        nums => [
            'shift'
        ]
    ];

=head2 C<greater_than>

Numeric comparison

    my $rule = [
        age => [
            {greater_than => 25}
        ]
    ];

=head2 C<less_than>

Numeric comparison

    my $rule = [
        age => [
            {less_than => 25}
        ]
    ];

=head2 C<equal_to>

Numeric comparison

    my $rule = [
        age => [
            {equal_to => 25}
        ]
    ];
    
=head2 C<between>

Numeric comparison

    my $rule = [
        age => [
            {between => [1, 20]}
        ]
    ];

=head2 C<in_array>

Check if the food ordered is in menu

    my $rule = [
        food => [
            {in_array => [qw/sushi bread apple/]}
        ]
    ];

=head2 C<trim>

Trim leading and trailing white space

    my $rule = [
        key1 => [
            ['trim']           # ' 123 ' -> '123'
        ],
    ];
    
=head2 C<trim_lead>

Trim leading white space

    my $rule = [
        key1 => [
            ['trim_lead']      # '  abc  ' -> 'abc   '
        ],
    ];

=head2 C<trim_trail>

Trim trailing white space

    my $rule = [
        key1 => [
            ['trim_trail']     # '  def  ' -> '   def'
        ]
    ];

=head2 C<trim_collapse>

Trim leading and trailing white space, and collapse all whitespace characters into a single space.

    my $rule = [
        key1 => [
            ['trim_collapse']  # "  \n a \r\n b\nc  \t" -> 'a b c'
        ],
    ];

=head1 BUGS

Please tell me the bugs.

C<< <kimoto.yuki at gmail.com> >>

=head1 STABILITY

L<Validator::Custom> and L<Validator::Custom::Result> is now stable. all methods(except for experimantal marking ones) keep backword compatible in the future.

=head1 AUTHOR

Yuki Kimoto, C<< <kimoto.yuki at gmail.com> >>

L<http://github.com/yuki-kimoto/Validator-Custom>

=head1 COPYRIGHT & LICENCE

Copyright 2009 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
