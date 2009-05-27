use Test::More 'no_plan';

use strict;
use warnings;
use lib 't/01-core';

my $M = 'Validator::Custom';
eval"use $M";

{
    my $hash = { k1 => 1, k2 => 2, k3 => 3 };
    my $validator = [
        k1 => [
            [sub{$_[0] == 1}, "k1Error1"],
            [sub{$_[0] == 2}, "k1Error2"],
            [sub{$_[0] == 3}, "k1Error3"],
        ],
        k2 => [
            [sub{$_[0] == 2}, "k2Error1"],
            [sub{$_[0] == 3}, "k2Error2"]
        ]
    ];
    
    my $errors = $M->new->validate($hash, $validator)->errors;
    is_deeply($errors, [qw/k1Error2 k2Error2/], 'validator');
}

use T1;
{
    my $hash = { k1 => 1, k2 => 'a', k3 => 3.1, k4 => 'a' };
    my $validator = [
        k1 => [
            ['Int', "k1Error1"],
        ],
        k2 => [
            ['Int', "k2Error1"],
        ],
        k3 => [
            ['Num', "k3Error1"],
        ],
        k4 => [
            ['Num', "k4Error1"],
        ],
    ];    
    my $errors = T1->new->validate($hash, $validator)->errors;
    is_deeply($errors, [qw/k2Error1 k4Error1/], 'Custom validator');
    
    my $validators = T1->validators;
    ok(exists($validators->{Int}), 'get validators');
    ok(exists($validators->{Num}), 'get validators');
    
    
}

{
    my $hash = {k1 => 1};
    my $validator = [
        k1 => [
            ['No', "k1Error1"],
        ],
    ];    
    eval{T1->new->validate($hash, $validator)};
    like($@, qr/'No' is not resisted/, 'no custom type');
}

{
    eval{T1->validators({})};
    like($@, qr/'validators' is read only/, 'validators is read only');
}

{
    use T2;
    my $hash = { k1 => 1, k2 => 'a', k3 => 3.1, k4 => 'a' };
    my $validator = [
        k1 => [
            ['Int', "k1Error1"],
        ],
        k2 => [
            ['Int', "k2Error1"],
        ],
        k3 => [
            ['Num', "k3Error1"],
        ],
        k4 => [
            ['Num', "k4Error1"],
        ],
    ];    
    my $errors = T2->new->validate($hash, $validator)->errors;
    is_deeply($errors, [qw/k2Error1 k4Error1/], 'mearge Custom validator');
    
    my $validators = T2->validators;
    ok(exists($validators->{Int}), 'merge get validators');
    ok(exists($validators->{Num}), 'merge get validators');
    
}

{
    my $hash = { k1 => 1, k2 => [1,2], k3 => [1,'a', 'b'], k4 => 'a'};
    my $validator = [
        k1 => [
            ['@Int', "k1Error1"],
        ],
        k2 => [
            ['@Int', "k2Error1"],
        ],
        k3 => [
            ['@Int', "k3Error1"],
        ],
        k4 => [
            ['@Int', "k4Error1"],
        ],
    ];    
    my $errors = T1->new->validate($hash, $validator)->errors;
    is_deeply($errors, [qw/k3Error1 k4Error1/], 'array validate');
}

