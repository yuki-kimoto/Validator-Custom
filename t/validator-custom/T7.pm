package T7;
use base 'Validator::Custom';

__PACKAGE__->register_constraint(
    c1 => \&T7::Constraints::c1
);

package T7::Constraints;
use Carp 'croak';

sub c1 {
    croak "aaa";
}


1;