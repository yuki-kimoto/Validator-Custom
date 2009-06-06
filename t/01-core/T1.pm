package T1;
use base 'Validator::Custom';

__PACKAGE__->add_constraint(
    {
        Int => sub{$_[0] =~ /^\d+$/},
    },
    
    {
        Num => sub{
            require Scalar::Util;
            Scalar::Util::looks_like_number($_[0]);
        }
    }
);
