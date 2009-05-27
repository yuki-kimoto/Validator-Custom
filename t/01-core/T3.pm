package T3;
use base 'Validator::Custom';

__PACKAGE__->add_validator(
    {
        Int => sub{$_[0] =~ /^\d+$/},
    }
);
