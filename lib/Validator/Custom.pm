package Validator::Custom;
use Object::Simple;

our $VERSION = '0.0303';

require Carp;

### Class methods

# Get constraint functions
sub constraints : ClassAttr { type => 'hash', deref => 1,  auto_build => \&_inherit_constraints }

# Add constraint function
sub add_constraint {
    my $class = shift;
    my $caller_class = caller;
    
    Carp::croak("'add_constraint' must be called from $class")
      unless $class eq $caller_class;
    
    my %old_constraints = $class->constraints;
    my %new_constraints = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;
    $class->constraints(%old_constraints, %new_constraints);
}

# Inherit super class constraint functions
sub _inherit_constraints {
    my $class = shift;
    my $super =  do {
        no strict 'refs';
        ${"${class}::ISA"}[0];
    };
    my $constraints = eval{$super->can('constraints')}
                        ? $super->constraints
                        : {};
                      
    $class->constraints($constraints);
}



### Accessors

# Validation rule
sub validation_rule : Attr {}

# Error is stock?
sub error_stock  : Attr { default => 1 }

# Invalid keys
sub invalid_keys    : Attr   { type => 'array', deref => 1 }
sub invalid_keys_to : Output { target => 'invalid_keys' }

# Validation errors
sub errors       : Attr   { type => 'array', deref => 1 }
sub errors_to    : Output { target => 'errors' }

# Resutls after conversion
sub results      : Attr   { type => 'hash', deref => 1 }
sub results_to   : Output { target => 'results' }



### Methods

# Validate
sub validate {
    my ($self, $data, $validation_rule) = @_;
    my $class = ref $self;
    
    # Validation rule
    $validation_rule ||= $self->validation_rule;
    
    # Data must be hash ref
    Carp::croak("Data which passed to validate method must be hash ref")
      unless ref $data eq 'HASH';
    
    # Validation rule must be array ref
    Carp::croak("Validation rule must be array ref\n"
              . $self->_validation_rule_usage($validation_rule))
      unless ref $validation_rule eq 'ARRAY';
    
    # Initialize attributes for output
    $self->errors([]);
    $self->results({});
    $self->invalid_keys([]);
    
    # Error is stock?
    my $error_stock = $self->error_stock;
    
    # Process each key
    VALIDATOR_LOOP:
    for (my $i = 0; $i < @{$validation_rule}; $i += 2) {
        my ($key, $constraints) = @{$validation_rule}[$i, ($i + 1)];
        
        Carp::croak("Constraints of validation rule must be array ref\n"
                  . $self->_validation_rule_usage($validation_rule))
          unless ref $constraints eq 'ARRAY';
        
        # Rearrange key
        my $result_key = $key;
        
        if (ref $key eq 'HASH') {
            # Clear each iterator
            keys %$key;
            ($result_key, $key) = each %$key;
        }
        
        my $value;
        my $result;
        foreach my $constraint (@$constraints) {
            
            # Rearrange validator information
            my ($constraint, $error_message)
              = ref $constraint eq 'ARRAY' ? @$constraint : ($constraint);
            
            my $data_type = {};
            my $arg;
            
            if(ref $constraint eq 'HASH') {
                keys %$constraint;
                ($constraint, $arg) = each %$constraint;
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
                
                Carp::croak("Constraint type '$constraint' must be [A-Za-z0-9_]")
                  if $constraint =~ /\W/;
                
                # Get validator function
                $constraint_function
                  = $class->constraints->{$constraint};
                
                Carp::croak("'$constraint' is not resisted")
                    unless ref $constraint_function eq 'CODE'
            }
            
            # Validate
            my $is_valid;
            if($data_type->{array}) {
                
                $value = ref $data->{$key} eq 'ARRAY' ? $data->{$key} : [$data->{$key}]
                  unless defined $value;
                
                my $first_validation = 1;
                foreach my $data (@$value) {
                    my $result_item;
                    ($is_valid, $result_item) = $constraint_function->($data, $arg, $self);
                    last unless $is_valid;
                    
                    if (defined $result_item) {
                        if ($first_validation) {
                            $result = [];
                            $first_validation = 0;
                        }
                        push @{$result}, $result_item;
                    }
                }
                $value = $result if defined $result;
            }
            else {
                $value = ref $key eq 'ARRAY' ? [map { $data->{$_} } @$key] : $data->{$key}
                  unless defined $value;
                
                ($is_valid, $result) = $constraint_function->($value, $arg, $self);
                $value = $result if $is_valid && defined $result;
            }
            
            # Add error if it is invalid
            unless($is_valid){
                $result = undef;
                
                push @{$self->errors}, $error_message if defined $error_message;
                push @{$self->invalid_keys}, $result_key;
                
                last VALIDATOR_LOOP unless $error_stock;
                next VALIDATOR_LOOP;
            }
        }
        $self->results->{$result_key} = $result if defined $result;
    }
    return $self;
}

my $SYNTAX_OF_VALIDATION_RULE = <<'EOS';

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
];

EOS

# Validation rule usage
sub _validation_rule_usage {
    my ($self, $validation_rule) = @_;
    
    my $message = $SYNTAX_OF_VALIDATION_RULE;
    
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

Version 0.0303

=head1 CAUTION

Validator::Custom is yew experimental stage.

=head1 SYNOPSIS
    
    ### How to use Validator::Custom
    
    # data
    my $data = { title => 'aaa', content => 'bbb' };
    
    # validator functions
    my $validation_rule = [
        title => [
            [sub{$_[0]},              "Specify title"],
            [sub{length $_[0] < 128}, "Too long title"]
        ],
        content => [
            [sub{$_[0]},               "Specify content"],
            [sub{length $_[0] < 1024}, "Too long content"]
        ]
    ];
    
    # validate
    Validator::Custom
      ->new
      ->validate($data,$validation_rule)
      ->errors_to(\my $errors);
    ;
    
    # or
    Validator::Custom
      ->new
      ->validation_rule($validation_rule)
      ->validate($data)
      ->errors_to(\my $errors)
    ;
    
    # handle errors
    foreach my $error (@$errors) {
        # ...
    }
    
    ### How to costomize Validator::Custom
    package Validator::Custom::Yours;
    use base 'Validator::Custom';
    
    # regist custom type
    __PACKAGE__->add_constraint(
        Int => sub {$_[0] =~ /^\d+$/},
        Num => sub {
            require Scalar::Util;
            Scalar::Util::looks_like_number($_[0]);
        },
        Str => sub {!ref $_[0]}
    );
    
    ### How to use customized validator class
    use Validator::Custom::Yours;
    my $data = { age => 'aaa', weight => 'bbb', favarite => [qw/sport food/};
    
    # Validation rule normal syntax
    my $validation_rule = [
        title => [
            ['Int', "Must be integer"],
        ],
        content => [
            ['Num', "Must be number"],
        ],
        favorite => [
            ['@Str', "Must be string"]
        ]
    ];
    
    # Validation rule light syntax
    my $validation_rule = [
        title => [
            'Int',
        ],
        content => [
            'Num',
        ],
        favorite => [
            '@Str'
        ]
    ];
    
    Validator::Custom::Yours
      ->new
      ->validate($data,$validation_rule)
      ->errors_to(\my $errors)
      ->invalid_keys_to(\my $invalid_keys)
    ;
    
    # Corelative check
    my $validation_rule => [
        [qw/password1 password2/] => [
            ['Same', 'passwor is not same']
        ]
    ]
    
    # Specify keys
    my $validation_rule => [
        {password_check => [qw/password1 password2/]} => [
            ['Same', 'passwor is not same']
        ]
    ]    
    
    
=head1 CLASS METHOD

=head2 constraints

get constraints
    
    # get
    my $constraints = Validator::Custom::Your->constraints;
    

=head2 add_constraint

You can use this method in custom class.
New validator functions is added.
    
    package Validator::Custom::Yours;
    use base 'Validator::Custom';
    
    __PACKAGE__->add_constraint(
        Int => sub {$_[0] =~ /^\d+$/}
    );

You can merge multiple custom class

    package Validator::Custom::YoursNew;
    use base 'Validator::Custom';
    
    use Validator::Custum::Yours1;
    use Validatro::Cumtum::Yours2;
    
    __PACAKGE__->add_constraint(
        %{Validator::Custom::Yours1->constraints},
        %{Validator::Custom::Yours2->constraints}
    );

=head1 ACCESSORS

=head2 errors

You can get validating errors

    my @errors = $vc->errors;

You can use this method after calling validate

    my @errors = $vc->validate($data,$validation_rule)->errors;

=head2 invalid_keys

You can get invalid keys by hash

    my $invalid_keys = $c->invalid_keys;

You can use this method after calling validate

    my $invalid_keys = $vc->validate($hash,$validation_rule)->invalid_keys;

=head2 error_stock

If you stock error, set 1, or set 0.

Default is 1. 

=head2 validation_rule

You can set validation_rule

    $vc->validation_rule($validation_rule);

=head2 results

You can get converted result if any.

    $vc->results

=head1 OUTPUT

=head2 validate method output

=head3 errors_to

$vc->errors_to(\my $errors);

=head3 invalid_keys_to

$vc->invalid_keys_to(\my $invalid_keys);

=head3 results_to

$vc->results_to(\my $results);

=head1 METHOD

=head2 new

create instance

    my $vc = Validator::Costom->new;

=head2 validate

validate

    $vc->validate($data,$validation_rule);

validator format is like the following.

    my $validation_rule = [
        # Function
        key1 => [
            [ \&validator_function1, "Error message1-1"],
            [ \&validator_function2, "Error message1-2"] 
        ],
        
        # Custom Type
        key2 => [
            [ 'CustomType' ,         "Error message2-1"],
        ],
        
        # Array of Custom Type
        key3 => [
            [ '@CustomType',         "Error message3-1"]
        ]
    ];

This method retrun self.

Output is saved to 'errors', 'invalid_keys', and 'results'.

Error messages is saved to 'errors' if some error occured.

Invalid keys is saved to 'invalid_keys' if some error occured.

Conversion results is saved to 'results' if convertion is excuted.

=cut

=head1 AUTHOR

Yuki Kimoto, C<< <kimoto.yuki at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-validator-custom at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Validator-Custom>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Validator::Custom


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Validator-Custom>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Validator-Custom>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Validator-Custom>

=item * Search CPAN

L<http://search.cpan.org/dist/Validator-Custom/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Validator::Custom
