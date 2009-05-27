package T2;
use base 'Validator::Custom';

use T3;
use T4;

__PACKAGE__->add_validator(
    T3->validators,
    T4->validators
);