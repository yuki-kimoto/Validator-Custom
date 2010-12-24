package Validator::Custom;

our $VERSION = '0.1406';

use 5.008001;
use strict;
use warnings;

use base 'Object::Simple';

use Carp 'croak';
use Validator::Custom::Basic::Constraints;
use Validator::Custom::Result;

# Object::Simple "dual_attr" is deprecated. Don't use "dual_attr".
# I rest this for the promiss of keeping backword compatible.
__PACKAGE__->dual_attr('constraints', default => sub { {} },
                                      inherit => 'hash_copy');
__PACKAGE__->register_constraint(
    ascii             => \&Validator::Custom::Basic::Constraints::ascii,
    between           => \&Validator::Custom::Basic::Constraints::between,
    blank             => \&Validator::Custom::Basic::Constraints::blank,
    decimal           => \&Validator::Custom::Basic::Constraints::decimal,
    defined           => sub { defined $_[0] },
    duplication       => \&Validator::Custom::Basic::Constraints::duplication,
    equal_to          => \&Validator::Custom::Basic::Constraints::equal_to,
    greater_than      => \&Validator::Custom::Basic::Constraints::greater_than,
    http_url          => \&Validator::Custom::Basic::Constraints::http_url,
    int               => \&Validator::Custom::Basic::Constraints::int,
    in_array          => \&Validator::Custom::Basic::Constraints::in_array,
    length            => \&Validator::Custom::Basic::Constraints::length,
    less_than         => \&Validator::Custom::Basic::Constraints::less_than,
    merge             => \&Validator::Custom::Basic::Constraints::merge,
    not_defined       => \&Validator::Custom::Basic::Constraints::not_defined,
    not_space         => \&Validator::Custom::Basic::Constraints::not_space,
    not_blank         => \&Validator::Custom::Basic::Constraints::not_blank,
    uint              => \&Validator::Custom::Basic::Constraints::uint,
    regex             => \&Validator::Custom::Basic::Constraints::regex,
    selected_at_least => \&Validator::Custom::Basic::Constraints::selected_at_least,
    shift             => \&Validator::Custom::Basic::Constraints::shift_array,
    trim              => \&Validator::Custom::Basic::Constraints::trim,
    trim_collapse     => \&Validator::Custom::Basic::Constraints::trim_collapse,
    trim_lead         => \&Validator::Custom::Basic::Constraints::trim_lead,
    trim_trail        => \&Validator::Custom::Basic::Constraints::trim_trail
);

__PACKAGE__->attr('data_filter');
__PACKAGE__->attr(error_stock => 1);
__PACKAGE__->attr('rule');

__PACKAGE__->attr(syntax => <<'EOS');
### Syntax of validation rule
my $rule = [                              # 1 Rule is array ref
    key => [                              # 2 Constraints is array ref
        'constraint',                     # 3 Constraint is string
        {'constraint' => 'args'}          #     or hash ref (arguments)
        ['constraint', 'err'],            #     or arrya ref (message)
    ],
    key => [                           
        [{constraint => 'args'}, 'err']   # 4 With argument and message
    ],
    {key => ['key1', 'key2']} => [        # 5.1 Multi-parameters validation
        'constraint'
    ],
    {key => qr/^key/} => [                # 5.2 Multi-parameters validation
        'constraint'                              using regular expression
    ],
    key => [
        '@constraint'                     # 6 Multi-values validation
    ],
    key => {message => 'err', ... } => [  # 7 With options
        'constraint'
    ]
];

EOS

sub register_constraint {
    my $self = shift;
    
    # Merge
    my $constraints = ref $_[0] eq 'HASH' ? $_[0] : {@_};
    $self->constraints({%{$self->constraints}, %$constraints});
    
    return $self;
}

our %VALID_OPTIONS = map {$_ => 1} qw/message default copy/;

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
    $result->{_error_infos} = {};
    
    # Save raw data
    $result->raw_data($data);
    
    # Error is stock?
    my $error_stock = $self->error_stock;
    
    # Valid keys
    my $valid_keys = {};
    
    # Error position
    my $position = 0;
    
    # Found missing paramteters
    my $found_missing_params = {};

    # Process each key
    OUTER_LOOP:
    for (my $i = 0; $i < @{$rule}; $i += 2) {
        
        # Increment position
        $position++;
        
        # Key, options, and constraints
        my $key = $rule->[$i];
        my $options = $rule->[$i + 1];
        my $constraints;
        if (ref $options eq 'HASH') {
            $constraints = $rule->[$i + 2];
            $i++;
        }
        else {
            $constraints = $options;
            $options = {};
        }
        
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
        
        # Real keys
        my $keys;
        
        if (ref $key eq 'ARRAY') {
            $keys = $key;
        }
        elsif (ref $key eq 'Regexp') {
           $keys = [];
           foreach my $k (keys %$data) {
               push @$keys, $k if $k =~ /$key/;
           }
        }
        else {
            $keys = [$key];
        }
        # Check option
        foreach my $oname (keys %$options) {
            croak qq{Option "$oname" of "$result_key" is invalid name}
              unless $VALID_OPTIONS{$oname};
        }
        
        # Is data copy?
        my $copy = 1;
        $copy = $options->{copy} if exists $options->{copy};
        
        # Check missing parameters
        my $found_missing_param;
        my $missing_params = $result->missing_params;
        foreach my $key (@$keys) {
            unless (exists $data->{$key}) {
                push @$missing_params, $key
                  unless $found_missing_params->{$key};
                $found_missing_params->{$key}++;
                $found_missing_param = 1;
            }
        }
        if ($found_missing_param) {
            $result->data->{$result_key} = $options->{default}
              if exists $options->{default} && $copy;
            next;
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
            my $negative;
            
            # Sub reference
            if( ref $constraint eq 'CODE') {
                
                # Constraint function
                $constraint_function = $constraint;
            }
            
            # Constraint key
            else {
                
                # Array constraint
                if($constraint =~ /^(\@?)(\!?)(.+)$/) {
                    $data_type->{array} = 1 if ($1 || '') eq '@';
                    $negative = 1 if ($2 || '') eq '!';
                    $constraint = $3;
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
                    $value = ref $data->{$keys->[0]} eq 'ARRAY' 
                           ? $data->{$keys->[0]}
                           : [$data->{$keys->[0]}]
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
                    
                    # Negative
                    $is_valid = !$is_valid if $negative;
                    
                    # Validation error
                    last unless $is_valid;
                }
                
                # Update value
                $value = $elements if $elements;
            }
            
            # Data is scalar
            else {
                
                # Set value
                $value = @$keys > 1
                       ? [map { $data->{$_} } @$keys]
                       : $data->{$keys->[0]}
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

                # Negative
                $is_valid = !$is_valid if $negative;
            }
            
            # Add error if it is invalid
            unless ($is_valid) {
                
                # Resist error info
                $message = $options->{message} unless defined $message;
                $result->{_error_infos}->{$result_key} = {
                    message      => $message,
                    position     => $position,
                    reason       => $constraint,
                    original_key => $key
                }
                  unless exists $result->{_error_infos}->{$result_key};
                
                # Set default value
                $result->data->{$result_key} = $options->{default}
                  if exists $options->{default} && $copy;
                
                # No Error strock
                unless ($error_stock) {
                    # Check rest constraint
                    my $found;
                    for (my $k = $i + 2; $k < @{$rule}; $k += 2) {
                        my $key = $rule->[$k];
                        $k++ if ref $rule->[$k + 1] eq 'HASH';
                        $key = (keys %$key)[0] if ref $key eq 'HASH';
                        $found = 1 if $key eq $result_key;
                    }
                    last OUTER_LOOP unless $found;
                }
                next OUTER_LOOP;
            }
        }
        
        # Result data
        $result->data->{$result_key} = $value if $copy;
        
        # Key is valid
        $valid_keys->{$result_key} = 1;
        
        # Remove invalid key
        delete $result->{_error_infos}->{$key};
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

# Deprecated
__PACKAGE__->attr(shared_rule => sub { [] });


1;

=head1 NAME

Validator::Custom - Validates user input easily

=head1 SYNOPSYS

Basic usages

    use Validator::Custom;
    my $vc = Validator::Custom->new;

    my $data = {age => 19, name => 'Ken Suzuki'};
    
    my $rule = [
        age => [
            'int'
        ],
        name => [
            ['not_blank',        "Name must be exists"],
            [{length => [1, 5]}, "Name length must be 1 to 5"]
        ],
        price => {default => 1000, message => 'price must be integer'} => [
            'int'
        ]
    ];
    
    my $result = $vc->validate($data, $rule);

Result of validation
    
    unless ($result->is_ok) {
        if ($result->has_missing) {
            my $missing_params = $result->missing_params;
            # Found missing parameters
        }
        elsif ($result->has_invalid) {
            my $messages = $result->messages_to_hash;
        }
    }
    
More features

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
    $result = $vc->validate($data, $rule);

    # Negative validateion
    $rule = [
        'age' => [
            '!int'
        ]
    ];

=head1 DESCRIPTION

L<Validator::Custom> validates user input.
The features are the following ones.

=over 4

=item *

Can set a message for each parameter. the messages is added to
the result when the parameter is invalid. the messages keeps the order.

=item *

Can register constraint function. such as "int", "defined".
constraint function can receive any arguments, other than parameter value.

=item *

Can create original class, extending Validator::Custom
(See L<Validator::Custom::HTMLForm>)

=item *

Support multi-parameters validation, multi-values validation,
OR condition validation, negative validation.

=back

See L<Validator::Custom::Guides> to know usages of L<Validator::Custom>.

=head1 ATTRIBUTES

=head2 C<constraints>

    my $constraints = $vc->constraints;
    $vc             = $vc->constraints(\%constraints);

Constraint functions.

=head2 C<data_filter>

    my $filter = $vc->data_filter;
    $vc        = $vc->data_filter(\&filter);

Filter input data. If data is not hash reference, you can convert the data to hash reference.

    $vc->data_filter(
        sub {
            my $data = shift;
            
            # Convert data to hash reference.
            
            return $data;
        }
    );

=head2 C<error_stock>

    my $error_stock = $vc->error_stcok;
    $vc             = $vc->error_stock(1);

If error_stock is set to 1, all validation error is stocked.
If error_stock is set 0, Validation is finished soon after a error occur.

Default to 1. 

=head2 C<rule>

    my $rule = $vc->rule;
    $vc      = $vc->rule($rule);

Rule for validation.
Validation rule has the following syntax.

    # Rule syntax
    my $rule = [                              # 1. Rule is array ref
        key => [                              # 2. Constraints is array ref
            'constraint',                     # 3. Constraint is string
            {'constraint' => 'args'}          #      or hash ref (arguments)
            ['constraint', 'err'],            #      or arrya ref (message)
        ],
        key => [                           
            [{constraint => 'args'}, 'err']   # 4. With argument and message
        ],
        {key => ['key1', 'key2']} => [        # 5. Multi-parameters validation
            'constraint'
        ],
        key => [
            '@constraint'                     # 6. Multi-values validation
        ],
        key => \%OPTIONS => [                 # 7. With options
            'constraint'
        ]
    ];

=head2 C<syntax>

    my $syntax = $vc->syntax;
    $vc        = $vc->syntax($syntax);

Syntax of rule.

=head1 METHODS

L<Validator::Custom> inherits all methods from L<Object::Simple>
and implements the following new ones.

=head2 C<validate>

    $result = $vc->validate($data, $rule);
    $result = $vc->validate($data);

Validate the data.
Return value is L<Validator::Custom::Result> object.
If the rule of second arument is ommited, rule attribute is used for validation.

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

=head2 C<(deprecated) shared_rule>

B<This method is now deprecated> because I know in almost all case
We specify a constraint for each paramters.

    my $shared_rule = $vc->shared_rule;
    $vc             = $vc->shared_rule(\@rule);

Shared rule. Shared rule is added the head of normal rule.

    $vc->shared_rule([
        ['defined',   'Must be defined'],
        ['not_blank', 'Must be not blank']
    ]);

=head1 CONSTRAINTS

=head2 C<ascii>

check is the data consists of only ascii code.

=head2 C<between>

Numeric comparison

    my $rule = [
        age => [
            {between => [1, 20]}
        ]
    ];

=head2 C<blank>

Check if the is blank.

=head2 C<decimal>
    
    my $data = { num => '123.45678' };
    my $rule => [
        num => [
            {'decimal' => [3, 5]}
        ]
    ];

    Validator::Custom::HTMLForm->new->validate($data,$rule);

Each numbers (3,5) mean maximum digits before/after '.'

=head2 C<defined>

Check if the data is defined.

=head2 C<duplication>

Check if the two data are same or not.

    my $data = {mail1 => 'a@somehost.com', mail2 => 'a@somehost.com'};
    my $rule => [
        [qw/mail1 mail2/] => [
            'duplication'
        ]
    ];

=head2 C<equal_to>

Numeric comparison

    my $rule = [
        age => [
            {equal_to => 25}
        ]
    ];
    
=head2 C<greater_than>

Numeric comparison

    my $rule = [
        age => [
            {greater_than => 25}
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

=head2 C<int>

Check if the data is integer.
    
    # valid data
    123
    -134

=head2 C<in_array>

Check if the food ordered is in menu

    my $rule = [
        food => [
            {in_array => [qw/sushi bread apple/]}
        ]
    ];

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

=head2 C<less_than>

Numeric comparison

    my $rule = [
        age => [
            {less_than => 25}
        ]
    ];

=head2 C<merge>

Merge the values
    
    $data = {key1 => 'a', key2 => 'b', key3 => 'c'};
    $rule = [
        {key => ['key1', 'key2', 'key3']} => [
            'merge'
        ],
    ];
    
    $result->data->{key} is 'abc'

=head2 C<not_blank>

Check if the data is not blank.

=head2 C<not_defined>

Check if the data is not defined.

=head2 C<not_space>

Check if the data do not containe space.

=head2 C<uint>

Check if the data is unsigned integer.

    # valid data
    123
    
=head2 C<regex>

Check with regular expression.
    
    my $data = {str => 'aaa'};
    my $rule => [
        str => [
            {regex => qr/a{3}/}
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

=head2 C<shift>

Shift the head of array reference.

    my $data = {nums => [1, 2]};
    my $rule => [
        nums => [
            'shift'
        ]
    ];

=head2 C<trim>

Trim leading and trailing white space

    my $rule = [
        key1 => [
            ['trim']           # ' 123 ' -> '123'
        ],
    ];
    
=head2 C<trim_collapse>

Trim leading and trailing white space, and collapse all whitespace characters into a single space.

    my $rule = [
        key1 => [
            ['trim_collapse']  # "  \n a \r\n b\nc  \t" -> 'a b c'
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

=head1 BUGS

Please tell me the bugs.

C<< <kimoto.yuki at gmail.com> >>

=head1 STABILITY

L<Validator::Custom> and L<Validator::Custom::Result> is stable. All methods in 
this documentation (except for experimantal marking ones) keep backword compatible in the future.

=head1 AUTHOR

Yuki Kimoto, C<< <kimoto.yuki at gmail.com> >>

L<http://github.com/yuki-kimoto/Validator-Custom>

=head1 COPYRIGHT & LICENCE

Copyright 2009 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
