package Validator::Custom;

our $VERSION = '0.1410';

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
    space             => \&Validator::Custom::Basic::Constraints::space,
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
    ],
    key => [
        '!constraint'                     # 8 Negativate constraint
    ],
    key => [
        'constraint1 || constraint2'      # 9 "OR" condition
    ],
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
    my $pos = 0;
    
    # Found missing paramteters
    my $found_missing_params = {};

    # Process each key
    OUTER_LOOP:
    for (my $i = 0; $i < @{$rule}; $i += 2) {
        
        # Increment position
        $pos++;
        
        # Key, options, and constraints
        my $key = $rule->[$i];
        my $opts = $rule->[$i + 1];
        my $constraints;
        if (ref $opts eq 'HASH') {
            $constraints = $rule->[$i + 2];
            $i++;
        }
        else {
            $constraints = $opts;
            $opts = {};
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
        foreach my $oname (keys %$opts) {
            croak qq{Option "$oname" of "$result_key" is invalid name}
              unless $VALID_OPTIONS{$oname};
        }
        
        # Is data copy?
        my $copy = 1;
        $copy = $opts->{copy} if exists $opts->{copy};
        
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
            $result->data->{$result_key} = $opts->{default}
              if exists $opts->{default} && $copy;
            next;
        }
        
        # Already valid
        next if $valid_keys->{$result_key};
        
        # Add shared rule
        push @$constraints, @$shared_rule;
        
        # Validation
        my $value = @$keys > 1
                  ? [map { $data->{$_} } @$keys]
                  : $data->{$keys->[0]};

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
            my $cfuncs;
            my $negative;
            
            # Sub reference
            if( ref $constraint eq 'CODE') {
                
                # Constraint function
                $cfuncs = [$constraint];
            }
            
            # Constraint key
            else {
                
                # Constirnt infomation
                my $cinfo = $self->_parse_constraint($constraint);
                $data_type->{array} = 1 if $cinfo->{array};
                                                
                # Constraint function
                $cfuncs = $cinfo->{funcs};
            }
            
            # Is valid?
            my $is_valid;
            
            # Data is array
            if($data_type->{array}) {
                
                # To array
                $value = [$value] unless ref $value eq 'ARRAY';
                
                # Validation loop
                for (my $i = 0; $i < @$value; $i++) {
                    my $data = $value->[$i];
                    
                    # Validation
                    for (my $k = 0; $k < @$cfuncs; $k++) {
                        my $cfunc = $cfuncs->[$k];
                        
                        # Validate
                        my $cresult = $cfunc->($data, $arg, $self);
                        
                        # Constrint result
                        my $v;
                        if (ref $cresult eq 'ARRAY') {
                            ($is_valid, $v) = @$cresult;
                            $value->[$i] = $v;
                        }
                        else {
                            $is_valid = $cresult;
                        }
                        
                        last if $is_valid;
                    }
                    
                    # Validation error
                    last unless $is_valid;
                }
            }
            
            # Data is scalar
            else {

                # Validation
                foreach my $cfunc (@$cfuncs) {
                    my $cresult = $cfunc->($value, $arg, $self);
                    
                    if (ref $cresult eq 'ARRAY') {
                        my $v;
                        ($is_valid, $v) = @$cresult;
                        $value = $v if $is_valid;
                    }
                    else {
                        $is_valid = $cresult;
                    }
                    
                    last if $is_valid;
                }
            }
            
            # Add error if it is invalid
            unless ($is_valid) {
                
                # Resist error info
                $message = $opts->{message} unless defined $message;
                $result->{_error_infos}->{$result_key} = {
                    message      => $message,
                    position     => $pos,
                    reason       => $constraint,
                    original_key => $key
                }
                  unless exists $result->{_error_infos}->{$result_key};
                
                # Set default value
                $result->data->{$result_key} = $opts->{default}
                  if exists $opts->{default} && $copy;
                
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

sub _parse_constraint {
    my ($self, $constraint) = @_;
    
    # Constraint infomation
    my $cinfo = {};
    
    # Simple constraint name
    unless ($constraint =~ /\W/) {
        my $cfunc = $self->constraints->{$constraint} || '';
        croak qq{"$constraint" is not registered}
          unless ref $cfunc eq 'CODE';
        
        $cinfo->{funcs} = [$cfunc];
        return $cinfo;
    }

    # Trim space
    $constraint ||= '';
    $constraint =~ s/^\s+//;
    $constraint =~ s/\s+$//;
    
    # Target is array elemetns
    $cinfo->{array} = 1 if $constraint =~ s/^@//;
    croak qq{"\@" must be one at the top of constrinat name}
      if index($constraint, '@') > -1;
    
    # Constraint functions
    my @cfuncs;
    
    # Constraint names
    my @cnames = split(/\|\|/, $constraint);
    
    # Convert constarint names to constraint funcions
    foreach my $cname (@cnames) {
        $cname ||= '';
        
        # Trim space
        $cname =~ s/^\s+//;
        $cname =~ s/\s+$//;
        
        # Negative
        my $negative = $cname =~ s/^!// ? 1 : 0;
        croak qq{"!" must be one at the top of constraint name}
          if index($cname, '!') > -1;
        
        # Trim space
        $cname =~ s/^\s+//;
        $cname =~ s/\s+$//;
        
        # Constraint function
        croak "Constraint name '$cname' must be [A-Za-z0-9_]"
          if $cname =~ /\W/;
        my $cfunc = $self->constraints->{$cname} || '';
        croak qq{"$cname" is not registered}
          unless ref $cfunc eq 'CODE';
        
        # Negativate
        my $f = $negative ? sub {
            my $ret = $cfunc->(@_);
            
            if (ref $ret eq 'ARRAY') {
                $ret->[0] = ! $ret->[0];
                return $ret;
            }
            else {
                return ! $ret;
            }
        } : $cfunc;
        
        # Add
        push @cfuncs, $f;
    }
    
    $cinfo->{funcs} = \@cfuncs;
    
    return $cinfo;
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

    use Validator::Custom;
    my $vc = Validator::Custom->new;

    my $data = {age => 19, name => 'Ken Suzuki'};
    
    my $rule = [
        age => {message => 'age must be integer'} => [
            'not_blank',
            'int'
        ],
        name => {message => 'name must be string. the length 1 to 5'} => [
            'not_blank',
            {length => [1, 5]}
        ],
        price => [
            'not_blank',
            'int'
        ]
    ];
    
    my $result = $vc->validate($data, $rule);

    unless ($result->is_ok) {
        if ($result->has_missing) {
            my $missing_params = $result->missing_params;
        }
        
        if ($result->has_invalid) {
            my $messages = $result->messages_to_hash;
        }
    }
    
=head1 DESCRIPTION

L<Validator::Custom> validates user input.
The features are the following ones.

=over 4

=item *

Can set messages for each parameter when data has invalid parameter.
The order of messages is keeped, and also can set messages for each reason.

=item *

Can register constraint functions or filter functions.
And useful constraint and filter is registered by default,
such as C<not_blank>, C<int>, C<trim>, etc.

=item *

Support C<OR> condition validation, negativate validation, 
array validation, 

=back

See L<Validator::Custom::Guides> to know usages of L<Validator::Custom>.

=head1 ATTRIBUTES

=head2 C<constraints>

    my $constraints = $vc->constraints;
    $vc             = $vc->constraints(\%constraints);

Constraint functions.

=head2 C<data_filter>

    my $filter = $vc->data_filter;
    $vc        = $vc->data_filter(\&data_filter);

Filter input data. If data is not hash reference, you can convert the data to hash reference.

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
        ],
        key => [
            '!constraint'                     # 8 Negativate constraint
        ],
        key => [
            'constraint1 || constraint2'      # 9 "OR" condition
        ],
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
If the rule of second arument is ommited,
The value of C<rule> attribute is used for validation.

=head2 C<register_constraint>

    $vc->register_constraint(%constraint);
    $vc->register_constraint(\%constraint);

Register a constraint function or filter function.
    
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
        },
        trim => sub {
            my $value = shift;
            $value =~ s/^\s+//;
            $value =~ s/\s+$//;
            
            return [1, $value];
        }
    );

If you register filter function, you must return array reference,
which contain [IS_VALID_OR_NOT, FILTERED_VALUE].

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

    my $data => {name => 'Ken'};
    my $rule = [
        name => [
            'ascii'
        ]
    ];

Ascii.

=head2 C<between>

    my $data = {age => 19};
    my $rule = [
        age => [
            {between => [1, 20]} # (1, 2, .. 19, 20)
        ]
    ];

Between A and B.

=head2 C<blank>

    my $data => {name => ''};
    my $rule = [
        name => [
            'blank'
        ]
    ];

Blank.

=head2 C<decimal>
    
    my $data = {num1 => '123.45678', num2 => '1.45'};
    my $rule => [
        num1 => [
            'decimal'
        ],
        num2 => [
            {'decimal' => [1, 2]}
        ]
    ];

Decimal. You can specify maximus digits number at before
and after '.'.

=head2 C<defined>

    my $data => {name => 'Ken'};
    my $rule = [
        name => [
            'defined'
        ]
    ];

Defined.

=head2 C<duplication>

    my $data = {mail1 => 'a@somehost.com', mail2 => 'a@somehost.com'};
    my $rule => [
        [qw/mail1 mail2/] => [
            'duplication'
        ]
    ];

Check if the two data are same or not.

=head2 C<equal_to>

    my $data = {price => 1000};
    my $rule = [
        price => [
            {'equal_to' => 1000}
        ]
    ];

Numeric equal comparison.

=head2 C<greater_than>

    my $data = {price => 1000};
    my $rule = [
        price => [
            {'greater_than' => 900}
        ]
    ];

Numeric "greater than" comparison

=head2 C<http_url>

    my $data = {url => 'http://somehost.com'};
    my $rule => [
        url => [
            'http_url'
        ]
    ];

HTTP(or HTTPS) URL.

=head2 C<int>

    my $data = {age => 19};
    my $rule = [
        age => [
            'int'
        ]
    ];

Integer.

=head2 C<in_array>

    my $data = {food => 'sushi'};
    my $rule = [
        food => [
            {'in_array' => [qw/sushi bread apple/]}
        ]
    ];

Check if the values is in array.

=head2 C<length>

    my $data = {value1 => 'aaa', value2 => 'bbbbb'};
    my $rule => [
        value1 => [
            {'length' => 3}
        ],
        value2 => [
            {'length' => [2, 5]} # 'bb' to 'bbbbb'
        ]
    ];

Length of the value.

=head2 C<less_than>

    my $data = {num => 20};
    my $rule = [
        num => [
            {'less_than' => 25}
        ]
    ];

Numeric "less than" comparison.

=head2 C<not_blank>

    my $data = {name => 'Ken'};
    my $rule = [
        name => [
            'not_blank' # Except for ''
        ]
    ];

Not blank.

=head2 C<not_defined>

    my $data = {name => 'Ken'};
    my $rule = [
        name => [
            'not_defined'
        ]
    ];

Not defined.

=head2 C<not_space>

    my $data = {name => 'Ken'};
    my $rule = [
        name => [
            'not_space' # Except for '', ' ', '   '
        ]
    ];

Not contain only space characters. 

=head2 C<space>

    my $data = {name => '   '};
    my $rule = [
        name => [
            'space' # '', ' ', '   '
        ]
    ];

White space or empty stirng.

=head2 C<uint>

    my $data = {age => 19};
    my $rule = [
        age => [
            'uint'
        ]
    ];

Unsigned integer.
    
=head2 C<regex>

    my $data = {num => '123'};
    my $rule => [
        num => [
            {'regex' => qr/\d{0,3}/}
        ]
    ];

Match a regular expression.

=head2 C<selected_at_least>

    my $data = {hobby => ['music', 'movie' ]};
    my $rule => [
        hobby => [
            {selected_at_least => 1}
        ]
    ];

Selected at least specified count item.
In other word, the array contains at least specified count element.

=head1 FILTERS

=head2 C<merge>

    my $data = {name1 => 'Ken', name2 => 'Rika', name3 => 'Taro'};
    my $rule = [
        {merged_name => ['name1', 'name2', 'name3']} => [
            'merge' # KenRikaTaro
        ]
    ];

Merge the values.

=head2 C<shift>

    my $data = {names => ['Ken', 'Taro']};
    my $rule => [
        names => [
            'shift' # 'Ken'
        ]
    ];

Shift the head element of array.

=head2 C<trim>

    my $data = {name => '  Ken  '};
    my $rule = [
        name => [
            'trim' # 'Ken'
        ]
    ];

Trim leading and trailing white space.

=head2 C<trim_collapse>

    my $data = {name => '  Ken   Takagi  '};
    my $rule = [
        name => [
            'trim_collapse' # 'Ken Takagi'
        ]
    ];

Trim leading and trailing white space,
and collapse all whitespace characters into a single space.

=head2 C<trim_lead>

    my $data = {name => '  Ken  '};
    my $rule = [
        name => [
            'trim_lead' # 'Ken  '
        ]
    ];

Trim leading white space.

=head2 C<trim_trail>

    my $data = {name => '  Ken  '};
    my $rule = [
        name => [
            'trim_trail' # '  Ken'
        ]
    ];

Trim trailing white space.

=head1 BUGS

Please tell me the bugs.

C<< <kimoto.yuki at gmail.com> >>

=head1 STABILITY

L<Validator::Custom> and L<Validator::Custom::Result> is stable now.
All methods in these documentations
(except for experimantal marking ones)
keep backword compatible in the future.

=head1 AUTHOR

Yuki Kimoto, C<< <kimoto.yuki at gmail.com> >>

L<http://github.com/yuki-kimoto/Validator-Custom>

=head1 COPYRIGHT & LICENCE

Copyright 2009 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
