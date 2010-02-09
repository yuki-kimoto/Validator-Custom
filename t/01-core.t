use Test::More tests => 45;

use strict;
use warnings;
use lib 't/01-core';

my $test;
sub test {$test = shift}

eval"use Validator::Custom";

{
    my $data = { k1 => 1, k2 => 2, k3 => 3 };
    my $rule = [
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
    
    my $errors = Validator::Custom->new->validate($data, $rule)->errors;
    is_deeply($errors, [qw/k1Error2 k2Error2/], 'rule');
    
    my @errors = Validator::Custom->new(rule => $rule)->validate($data)->errors;
    is_deeply([@errors], [qw/k1Error2 k2Error2/], 'rule');
    
    @errors = Validator::Custom->new->error_stock(0)->validate($data, $rule)->errors;
    is(scalar @errors, 1, 'error_stock is 0');
    is($errors[0], 'k1Error2', 'error_stock is 0');
}

{
    ok(!Validator::Custom->new->rule, 'rule default');
}

{
    my $result = Validator::Custom::Result->new;
    $result->products({k => 1});
    is_deeply($result->products, {k => 1}, 'products attribute');
}

{
    eval{Validator::Custom->new->validate({k => 1}, [ k => [['===', 'error']]])->validate};
    like($@, qr/\QConstraint type '===' must be [A-Za-z0-9_]/, 'constraint invalid name')
}

use T1;
{
    my $data = { k1 => 1, k2 => 'a', k3 => 3.1, k4 => 'a' };
    my $rule = [
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
    my $vc = T1->new;
    my $result= $vc->validate($data, $rule);
    is_deeply([$result->errors], [qw/k2Error1 k4Error1/], 'Custom validator');
    is_deeply(scalar $result->invalid_keys, [qw/k2 k4/], 'invalid keys hash');
    is_deeply([$result->invalid_keys], [qw/k2 k4/], 'invalid keys hash');  
    ok(!$result->is_valid, 'is_valid');
    
    my $constraints = T1->constraints;
    ok(exists($constraints->{Int}), 'get constraints');
    ok(exists($constraints->{Num}), 'get constraints');
}

{
    my $data = { k1 => 1, k2 => 'a', k3 => 3.1, k4 => 'a' };
    my $rule = [
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
    my $errors = $t->validate($data, $rule)->errors;
    is_deeply($errors, [qw/k2Error1 k4Error1/], 'Custom validator one');
    
    $errors = $t->validate($data, $rule)->errors;
    is_deeply($errors, [qw/k2Error1 k4Error1/], 'Custom validator two');
    
}

{
    my $data = {k1 => 1};
    my $rule = [
        k1 => [
            ['No', "k1Error1"],
        ],
    ];    
    eval{T1->new->validate($data, $rule)};
    like($@, qr/'No' is not resisted/, 'no custom type');
}

{
    use T2;
    my $data = { k1 => 1, k2 => 'a', k3 => 3.1, k4 => 'a' };
    my $rule = [
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
    my $errors = T2->new->validate($data, $rule)->errors;
    is_deeply($errors, [qw/k2Error1 k4Error1/], 'mearge Custom validator');
    
    my $constraints = T2->constraints;
    ok(exists($constraints->{Int}), 'merge get constraints');
    ok(exists($constraints->{Num}), 'merge get constraints');
    
}

{
    my $data = { k1 => 1, k2 => [1,2], k3 => [1,'a', 'b'], k4 => 'a'};
    my $rule = [
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
    my $errors = $vc->validate($data, $rule)->errors;

    is_deeply($errors, [qw/k3Error1 k4Error1/], 'array validate');
}

{
    my $data = {k1 => [1,2]};
    my $rule = [
        k1 => [
            ['@C1', "k1Error1"],
            ['@C1', "k1Error1"]
        ],
    ];    
    
    my $vc = T1->new;
    my $result= $vc->validate($data, $rule);
    is_deeply(scalar $result->errors, [], 'no error');
    
    is_deeply(scalar $result->products, {k1 => [4,8]}, 'array validate2');
}


{
    my $data = { k1 => 1};
    my $rule = [
        k1 => [
            ['Int', "k1Error1"],
        ],
    ];    
    my @errors = T1->new->validate($data, $rule)->errors;
    is(scalar @errors, 0, 'no error');
}

{
    use T5;
    my $data = { k1 => 1, k2 => 'a', k3 => '  3  ', k4 => 4, k5 => 5, k6 => 5, k7 => 'a', k11 => [1,2]};
    my $rule = [
        k1 => [
            [{'C1' => [3, 4]}, "k1Error1"],
        ],
        k2 => [
            [{'C2' => [3, 4]}, "k2Error1" ],
        ],
        k3 => [
            'TRIM_LEAD',
            'TRIM_TRAIL'
        ],
        k4 => [
            ['NO_ERROR']
        ],
        [qw/k5 k6/] => [
            [{'C3' => [5]}, 'k5 k6 Error']
        ],
        k7 => [
            {'C2' => [3, 4]},
        ],
        k8 => [
            'C4'
        ],
        k9 => [
            {'C5' => 2}
        ],
        k10 => [
            'C6'
        ],
        k11 => [
            '@C6'
        ]
    ];
    
    my $vc = T5->new;
    my $result= $vc->validate($data, $rule);
    is_deeply([$result->errors], ['k2Error1'], 'variouse options');
    is_deeply([$result->invalid_keys], [qw/k2 k4 k7 k8/], 'invalid key');
    
    is_deeply($result->products->{k1},[1, [3, 4]], 'product');
    ok(!$result->products->{k2}, 'product not exist in error case');
    cmp_ok($result->products->{k3}, 'eq', 3, 'filter');
    ok(!$result->products->{k4}, 'product not set in case error');
    is($result->products->{k9}, 2, 'arg');
    isa_ok($result->products->{k10}, 'T5');
    isa_ok($result->products->{k11}->[0], 'T5');
    isa_ok($result->products->{k11}->[1], 'T5');

    $data = {k5 => 5, k6 => 6};
    $rule = [
        [qw/k5 k6/] => [
            [{'C3' => [5]}, 'k5 k6 Error']
        ]
    ];
    
    $result= $vc->validate($data, $rule);
    ok(!$result->is_valid, 'corelative invalid_keys');
    is(scalar @{$result->invalid_keys}, 1, 'corelative invalid_keys');
}

{
    my $data = { k1 => 1, k2 => 2};
    my $constraint = sub {
        my $values = shift;
        return $values->[0] eq $values->[1];
    };
    
    my $rule = [
        {k1_2 => [qw/k1 k2/]}  => [
            [$constraint, 'error_k1_2' ]
        ]
    ];
    
    my $vc = Validator::Custom->new;
    my @errors = $vc->validate($data, $rule)->errors;
    is_deeply([@errors], ['error_k1_2'], 'specify key');
}

{
    eval{Validator::Custom->new->validate([])};
    like($@, qr/Data which passed to validate method must be hash ref/, 'Data not hash ref');
}

{
    eval{Validator::Custom->new->rule({})->validate({})};
    like($@, qr/Validation rule must be array ref.+rule 1/sm,
             'Validation rule not array ref');
}

{
    eval{Validator::Custom->new->rule([key => 'Int'])->validate({})};
    like($@, qr/Constraints of validation rule must be array ref.+rule 2/sm, 
             'Constraints of key not array ref');
}

use T6;
{
    my $vc = T6->new;
    
    my $data = {
        name => 'zz' x 30,
        age => 'zz',
    };
    
    my $rule = [
        name => [
            {length => [1, 2]}
        ]
    ];
    
    my @invalid_keys = $vc->rule($rule)->validate($data)->invalid_keys;
    is_deeply([@invalid_keys], ['name'], 'constraint argument first');
    
    @invalid_keys = $vc->rule($rule)->validate($data)->invalid_keys;
    is_deeply([@invalid_keys], ['name'], 'constraint argument second');
}

{
    my $result = Validator::Custom->new->rule([])->validate({key => 1});
    ok($result->is_valid, 'is_valid ok');
}

{
    my $vc = T1->new;
    $vc->add_constraint(
       'C1' => sub {
            my $value = shift;
            return $value > 1 ? 1 : 0;
        },
       'C2' => sub {
            my $value = shift;
            return $value > 5 ? 1 : 0;
        }
    );
    
    my $data = {k1_1 => 1, k1_2 => 2, k2_1 => 5, k2_2 => 6};
    
    $vc->rule([
        k1_1 => [
            'C1'
        ],
        k1_2 => [
            'C1'
        ],
        k2_1 => [
            'C2'
        ],
        k2_2 => [
            'C2'
        ]
    ]);
    
    is_deeply([$vc->validate($data)->invalid_keys], [qw/k1_1 k2_1/], 'add_constraints object');
}

use T7;
test 'Constraint function croak';
{
    
    my $vc = T7->new;
    my $data = {a => 1};
    my $rule = [
        a => [
            'c1'
        ]
    ];
    eval{$vc->validate($data, $rule)};
    like($@, qr/Key 'a'.+01-core/ms, "$test : scalar");
    
    $data = {a => [1, 2]};
    $rule = [
        a => [
            '@c1'
        ]
    ];
    eval{$vc->validate($data, $rule)};
    like($@, qr/Key 'a'.+01-core/ms, "$test : array");
    
}