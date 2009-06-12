package Validator::Custom;
use Object::Simple;

our $VERSION = '0.0204';

require Carp;

### class method
{
    # constraint function
    my $CONSTRAINTS = {};

    # add validator function
    sub add_constraint{
        my $self = shift;
        $CONSTRAINTS = {%{$CONSTRAINTS}, ref $_[0] eq 'HASH' ? %{$_[0]} : @_};
    }
    # get validator function
    sub constraints {
        my $invocant = shift;
        if(@_){
            Carp::croak( "'constraints' is read only")
        }
        return $CONSTRAINTS;
    }
}


### attribute

# validator
sub validator : Attr { type => 'array', default => sub { [] } }

# validation errors
sub errors    : Attr { type => 'array', default => sub { [] }, deref => 1}


### method

# validate!
sub validate {
    my ($self, $hash, $validator ) = @_;
    
    $validator ||= $self->validator;
    
    $self->errors([]);
    # process each key
    VALIDATOR_LOOP:
    for (my $i = 0; $i < @{$validator}; $i += 2) {
        my ($key, $validator_infos) = @{$validator}[$i, ($i + 1)];
        
        foreach my $validator_info (@$validator_infos){
            my($validator_expression, $error_message ) = @$validator_info;
            
            my $validator_function;
            my $data_type = {};
            # case: expression is code reference
            if( ref $validator_expression eq 'CODE') {
                $validator_function = $validator_expression;
            }
            
            # case: expression is string
            else {
                if($validator_expression =~ /^(\@)?(.+)$/) {
                    if($1 && $1 eq '@') {
                    $DB::single = 1;
                        $data_type->{array}++;
                    }
                    $validator_expression = $2;
                    Carp::croak("Type name must be [A-Za-z_]")
                        if $validator_expression =~ /\W/;
                }
                # get validator function
                $validator_function
                  = $self->constraints->{$validator_expression};
                
                Carp::croak("'$validator_expression' is not resisted")
                    unless ref $validator_function eq 'CODE'
            }
            
            # validate
            my $is_valid;
            if($data_type->{array} && ref $hash->{$key} eq 'ARRAY') {
                foreach my $data (@{$hash->{$key}}) {
                    $is_valid = $validator_function->($data);
                    last unless $is_valid;
                }
            }
            else {
                $is_valid = $validator_function->($hash->{$key});
            }
            
            # add error if it is invalid
            unless($is_valid){
                $self->errors([]) unless $self->errors;
                push @{$self->errors}, $error_message;
                next VALIDATOR_LOOP;
            }
        }
    }
    return $self;
}

Object::Simple->build_class; # End of Object::Simple!

=head1 NAME

Validator::Custom - Custom validator

=head1 VERSION

Version 0.0204

=head1 CAUTION

Validator::Custom is yew experimental stage.

=head1 SYNOPSIS
    
    ### How to use Validator::Custom
    
    # data
    my $hash = { title => 'aaa', content => 'bbb' };
    
    # validator functions
    my $validator = [
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
    my @errors = $vc->validate($hash,$validator)->errors;
    
    # or
    my $vc = Validator::Custom->new( validator => $validator);
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
    
    my $validator = [
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
    my $errors = $vc->validate($hash,$validator)->errors;
    
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

You can get validator errors

    my @errors = $vc->errors;

You can use this method after calling validate

    my @errors = $vc->validate($hash,$validator)->errors;

=head2 validator

You can set validator

    $vc->validator($validator);

=head1 METHOD

=head2 new

create instance

    my $vc = Validator::Costom->new;

=head2 validate

validate

    $vc->validate($hash,$validator);

validator format is like the following.

    my $validator = [
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
