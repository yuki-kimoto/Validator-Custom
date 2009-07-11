use Test::More 'no_plan';

use strict;
use warnings;
use lib 't/01-core';

my $M = 'Validator::Custom';
eval"use $M";

{
    my $hash = { k1 => 1, k2 => 2, k3 => 3 };
    my $validators = [
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
    
    my $p = Validator::Custom->new;
    
    my $errors = $M->new->validate($hash, $validators)->errors;
    is_deeply($errors, [qw/k1Error2 k2Error2/], 'validators');
    
    my @errors = $M->new(validators => $validators)->validate($hash)->errors;
    is_deeply([@errors], [qw/k1Error2 k2Error2/], 'validators');
    
    @errors = $M->new->error_stock(0)->validate($hash, $validators)->errors;
    is(scalar @errors, 1, 'error_stock is 0');
    is($errors[0], 'k1Error2', 'error_stock is 0');
}

{
    is_deeply($M->new->validators, [], 'validators default');
}

{
    my $o = $M->new;
    $o->results(k => 1);
    is_deeply({$o->results}, {k => 1}, 'results attribute');
}

use T1;
{
    my $hash = { k1 => 1, k2 => 'a', k3 => 3.1, k4 => 'a' };
    my $validators = [
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
    my $errors = T1->new->validate($hash, $validators)->errors;
    is_deeply($errors, [qw/k2Error1 k4Error1/], 'Custom validator');
    
    my $constraints = T1->constraints;
    ok(exists($constraints->{Int}), 'get constraints');
    ok(exists($constraints->{Num}), 'get constraints');
}

{
    my $hash = { k1 => 1, k2 => 'a', k3 => 3.1, k4 => 'a' };
    my $validators = [
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
    
    my $t = T1->new;
    my $errors = $t->validate($hash, $validators)->errors;
    is_deeply($errors, [qw/k2Error1 k4Error1/], 'Custom validator one');
    
    $errors = $t->validate($hash, $validators)->errors;
    is_deeply($errors, [qw/k2Error1 k4Error1/], 'Custom validator two');
    
}

{
    my $hash = {k1 => 1};
    my $validators = [
        k1 => [
            ['No', "k1Error1"],
        ],
    ];    
    eval{T1->new->validate($hash, $validators)};
    like($@, qr/'No' is not resisted/, 'no custom type');
}

{
    use T2;
    my $hash = { k1 => 1, k2 => 'a', k3 => 3.1, k4 => 'a' };
    my $validators = [
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
    my $errors = T2->new->validate($hash, $validators)->errors;
    is_deeply($errors, [qw/k2Error1 k4Error1/], 'mearge Custom validator');
    
    my $constraints = T2->constraints;
    ok(exists($constraints->{Int}), 'merge get constraints');
    ok(exists($constraints->{Num}), 'merge get constraints');
    
}

{
    my $hash = { k1 => 1, k2 => [1,2], k3 => [1,'a', 'b'], k4 => 'a'};
    my $validators = [
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
    my $errors = T1->new->validate($hash, $validators)->errors;
    is_deeply($errors, [qw/k3Error1 k4Error1/], 'array validate');
}

{
    my $hash = { k1 => 1};
    my $validators = [
        k1 => [
            ['Int', "k1Error1"],
        ],
    ];    
    my @errors = T1->new->validate($hash, $validators)->errors;
    is(scalar @errors, 0, 'no error');
}


