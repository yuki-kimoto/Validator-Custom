package T5;
use base 'Validator::Custom';

__PACKAGE__->add_constraint(
    C1 => sub {
        my ($value, $args, $options) = @_;
        
        return (1, [$value, $args, $options]);
    },
    C2 => sub {
        my ($value, $args, $options) = @_;
        
        return (0, [$value, $args, $options]);
    }
);


