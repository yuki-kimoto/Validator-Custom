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
    
    my $o = Validator::Custom->new;
    
    my $errors = $o->validate($hash, $validators)->errors;
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

{
    eval{$M->new->validate({k => 1}, [ k => [['===', 'error']]])->validate};
    like($@, qr/\QConstraint type '===' must be [A-Za-z0-9_]/, 'constraint invalid name')
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
    
    my $o = T1->new->validate($hash, $validators);
    my $errors = $o->errors;
    is_deeply($errors, [qw/k2Error1 k4Error1/], 'Custom validator');
    
    is_deeply(scalar $o->invalid_keys, {k2 => 1, k4 => 1}, 'invalid keys hash');
    is_deeply({$o->invalid_keys}, {k2 => 1, k4 => 1}, 'invalid keys hash');
    
    is_deeply(scalar $o->invalid_positions, {1 => 1, 3 => 1}, 'invalid positions hash');
    is_deeply({$o->invalid_positions}, {1 => 1, 3 => 1}, 'invalid positions hash');
    
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
    
    my $vc = T1->new;
    my $errors = $vc->validate($hash, $validators)->errors;

    is_deeply($errors, [qw/k3Error1 k4Error1/], 'array validate');
}

{
    my $hash = {k1 => [1,2]};
    my $validators = [
        k1 => [
            ['@C1', "k1Error1"],
            ['@C1', "k1Error1"]
        ],
    ];    
    
    my $vc = T1->new;
    my $errors = $vc->validate($hash, $validators)->errors;
    is_deeply($errors, [], 'no error');
    
    my $results = $vc->results;
    is_deeply($results, {k1 => [4,8]}, 'array validate2');
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

{
    use T5;
    my $hash = { k1 => 1, k2 => 'a', k3 => '  3  ', k4 => 4, k5 => 5, k6 => 5};
    my $validators = [
        k1 => [
            [['C1', 3, 4], "k1Error1"],
        ],
        k2 => [
            [['C2', 3, 4], "k2Error1" ],
        ],
        k3 => [
            [ 'TRIM_LEAD'  ],
            [ 'TRIM_TRAIL' ]
        ],
        k4 => [
            ['NO_ERROR']
        ],
        [qw/k5 k6/] => [
            [['C3', 5], 'k5 k6 Error']
        ]
    ];
    
    my $t = T5->new;
    my @errors = $t->validate($hash, $validators)->errors;
    is_deeply([@errors], ['k2Error1'], 'variouse options');
    
    is_deeply($t->results->{k1},[1, [3, 4]], 'result');
    ok(!$t->results->{k2}, 'result not exist in error case');
    cmp_ok($t->results->{k3}, 'eq', 3, 'filter');
    ok(!$t->results->{k4}, 'result not set in case error');
        
    # clear
    $t->validate;
    is_deeply([$t->errors], [], 'clear error');
    is_deeply(scalar $t->results, {}, 'clear results');
    is_deeply({$t->invalid_keys}, {}, 'clear error');
    is_deeply({$t->invalid_positions}, {}, 'clear error');
}




