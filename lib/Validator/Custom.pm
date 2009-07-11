package Validator::Custom;
use Object::Simple;

our $VERSION = '0.0207';

require Carp;

### class method

# add validator function
sub add_constraint {
    my $class = shift;
    my %old_constraints = $class->constraints;
    my %new_constraints = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;
    $class->constraints(%old_constraints, %new_constraints);
}

# get validator function
sub constraints : ClassAttr { type => 'hash', deref => 1,  auto_build => \&_inherit_constraints }

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

### attribute

# validators
sub validators  : Attr { type => 'array', default => sub { [] } }

# validation errors
sub errors      : Attr { type => 'array', default => sub { [] }, deref => 1 }

# error is stock?
sub error_stock : Attr { default => 1 }

# converted resutls
sub results     : Attr { type => 'hash', default => sub{ {} }, deref => 1 }

### method

# validate!
sub validate {
    my ($self, $hash, $validators ) = @_;
    
    my $class = ref $self;
    
    $validators ||= $self->validators;
    
    $self->errors([]);
    my $error_stock = $self->error_stock;
    
    # process each key
    VALIDATOR_LOOP:
    for (my $i = 0; $i < @{$validators}; $i += 2) {
        my ($key, $validator_infos) = @{$validators}[$i, ($i + 1)];
        
        foreach my $validator_info (@$validator_infos){
            my($constraint_expression, $error_message, $options ) = @$validator_info;
            
            my $constraint_function;
            my $data_type = {};
            my $args = [];
            
            if(ref $constraint_function eq 'ARRAY') {
                $args = [@{$constraint_function}[1 .. @$constraint_function - 1]];
                $constraint_function = $constraint_function->[0];
            }
            
            # expression is code reference
            if( ref $constraint_expression eq 'CODE') {
                $constraint_function = $constraint_expression;
            }
            
            # expression is string
            else {
                if($constraint_expression =~ /^(\@)?(.+)$/) {
                    if($1 && $1 eq '@') {
                        $data_type->{array}++;
                    }
                    $constraint_expression = $2;
                    Carp::croak("Type name must be [A-Za-z0-9_]")
                        if $constraint_expression =~ /\W/;
                }
                
                # get validator function
                $constraint_function
                  = $class->constraints->{$constraint_expression};
                
                Carp::croak("'$constraint_expression' is not resisted")
                    unless ref $constraint_function eq 'CODE'
            }
            
            # validate
            my $is_valid;
            my $result;
            if($data_type->{array} && ref $hash->{$key} eq 'ARRAY') {
                foreach my $data (@{$hash->{$key}}) {
                    ($is_valid, $result) = $constraint_function->($data, $args, $options->{options});
                    last unless $is_valid;
                    
                    if (my $key = $options->{result}) {
                        $self->results->{$key} ||= [];
                        push @{$self->results->{$key}}, $result;
                    }
                }
            }
            else {
                ($is_valid, $result) = $constraint_function->(
                    ref $key eq 'ARRAY' ? [map { $hash->{$_} } @$key] : $hash->{$key},
                    $args,
                    $options->{options}
                );
                
                if ($is_valid && $options->{result}) {
                    $self->results->{$options->{result}} = $result;
                }
            }
            
            # add error if it is invalid
            unless($is_valid){
                push @{$self->errors}, $error_message;
                last VALIDATOR_LOOP unless $error_stock;
                next VALIDATOR_LOOP;
            }
        }
    }
    return $self;
}

Object::Simple->build_class;

=head1 NAME

Validator::Custom - Custom validator

=head1 VERSION

Version 0.0207

=head1 CAUTION

Validator::Custom is yew experimental stage.

=head1 SYNOPSIS
    
    ### How to use Validator::Custom
    
    # data
    my $hash = { title => 'aaa', content => 'bbb' };
    
    # validator functions
    my $validators = [
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
    my $vc = Validator::Custom->new;
    my @errors = $vc->validate($hash,$validators)->errors;
    
    # or
    my $vc = Validator::Custom->new( validators => $validators);
    my @errors = $vc->validate($hash)->errors;
    
    # process in error case
    if($errors){
        foreach my $error (@$errors) {
            # process all errors
        }
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
    my $hash = { age => 'aaa', weight => 'bbb', favarite => [qw/sport food/};
    
    my $validators = [
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
    
    my $vc = Validator::Custom::Yours->new;
    my $errors = $vc->validate($hash,$validators)->errors;
    
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

    my @errors = $vc->validate($hash,$validators)->errors;

=head2 error_stock

If you stock error, set 1, or set 0.

Default is 1. 

=head2 validators

You can set validators

    $vc->validators($validators);

=head2 results

You can get converted result if any.

    $vc->results

=head1 METHOD

=head2 new

create instance

    my $vc = Validator::Costom->new;

=head2 validate

validate

    $vc->validate($hash,$validators);

validator format is like the following.

    my $validators = [
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

this method retrun self.

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
