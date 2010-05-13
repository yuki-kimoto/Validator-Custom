package T3;
use base 'Validator::Custom';

__PACKAGE__->register_constraint(
    Int => sub{$_[0] =~ /^\d+$/}
);
