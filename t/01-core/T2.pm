package T2;
use base 'Validator::Custom';

use T3;
use T4;

__PACKAGE__->add_constraint(T3->constraints);
__PACKAGE__->add_constraint(T4->constraints);

