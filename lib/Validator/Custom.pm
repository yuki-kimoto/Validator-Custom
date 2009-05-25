package Validator::Custom;
use Object::Simple;

our $VERSION = '0.01_01';

require Carp;

{
    # validator functions
    my $VALIDATORS = {};

    # add validator function
    sub validators {
        my $self = shift;
        if(@_) {
            $VALIDATORS = {%{$_[0]}};
        }
        return $VALIDATORS;
    }
}

# validation errors
sub errors : Attr {}

# validate!
sub validate {
    my ($self, $hash, $validator ) = @_;
    
    # process each key
    VALIDATOR_LOOP:
    while( my ($key, $validator_infos) = splice(@$validator, 0, 2)) {
        foreach my $validator_info (@$validator_infos){
            my($validator_expression, $error_message ) = @$validator_info;
            
            my $validator_function;
            # case: expression is code reference
            if( ref $validator_expression eq 'CODE') {
                $validator_function = $validator_expression;
            }
            
            # case: expression is string
            else{
                # get validator function
                $validator_function
                  = $self->validators->{$validator_expression};
                
                Carp::croak("'$validator_expression' is not resisted")
                    unless ref $validator_function eq 'CODE'
            }
            
            # validate
            my $is_valid = $validator_function->($hash->{$key});
            
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

Object::Simple->end; # End of Object::Simple!

=head1 NAME

Validator::Custom - Custom validator

=head1 VERSION

Version 0.01_01

=cut

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
    my $errors = $vc->validate($hash,$validator)->errors;
    
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
    __PACKAGE__->validators(
        {
            Int => sub {$_[0] =~ /^\d+$/},
            Num => sub {
                require Scalar::Util;
                Scalar::Util::looks_like_number($_[0]);
            }
        }
    );
    
    ### How to use customized validator class
    use Validator::Custom::Yours;
    my $hash = { age => 'aaa', weight => 'bbb' };
    
    my $validator = [
        title => [
            ['Int', "Must be integer"],
        ],
        content => [
            ['Num', "Must be number"],
        ]
    ];
    
    my $vc = Validator::Custom::Yours->new;
    my $errors = $vc->validate($hash,$validator)->errors;
    
=head1 CLASS METHOD

=head2 validators

set and get validators
    
    # get
    my $validators = __PACKAGE__->validators;
    
    # set
    __PACKAGE__->validators(
        {
            Int => sub {$_[0] =~ /^\d+$/},
        }
    );

You can use this method in custom class.
New validator function is added.
    
    package Validator::Custom::Yours;
    use base 'Validator::Custom';
    
    __PACKAGE__->validators(
        {
            Int => sub {$_[0] =~ /^\d+$/},
        }
    );


=head1 METHOD

=head2 new

create instance

    my $vc = Validator::Costom->new;

=head2 validate

validate

    $vc->validate($hash,$validator);

validator format is the following.

    my $validator = [
        key1 => [
            [ \&validator_function , "Error message1"],
        ],
        key2 => [
            [ 'CustomType' ,         "Error message2"],
        ]
    ];

this method retrun self.

=head2 errors

You can get validator errors

    my $errors = $vc->errors;

You can use this method after calling validate

    my $errors = $vc->validate($hash,$validator)->errors;

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
