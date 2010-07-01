use Test::More tests => 69;

use strict;
use warnings;
use lib 't/validator-custom';

my $test;
sub test {$test = shift}

use Validator::Custom;

our $DEFAULT_MESSAGE = $Validator::Custom::Result::DEFAULT_MESSAGE;

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
    my $validator = Validator::Custom->new;
    my $vresult   = $validator->validate($data, $rule);
    
    my $errors      = $vresult->errors;
    my $errors_hash = $vresult->errors_to_hash;
    
    is_deeply($errors, [qw/k1Error2 k2Error2/], 'rule');
    is_deeply($errors_hash, {k1 => 'k1Error2', k2 => 'k2Error2'}, 'rule errors hash');
    
    my $errors_hash2 = $vresult->messages_to_hash;
    is_deeply($errors_hash2, {k1 => 'k1Error2', k2 => 'k2Error2'}, 'rule errors hash');
    
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
    $result->data({k => 1});
    is_deeply($result->data, {k => 1}, 'data attribute');
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
    is_deeply($result->invalid_rule_keys, [qw/k2 k4/], 'invalid params hash');
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
    
    is_deeply(scalar $result->data, {k1 => [4,8]}, 'array validate2');
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
    is_deeply([$result->errors], 
              ['k2Error1', 'Error message not specified',
               'Error message not specified', 'Error message not specified'
              ], 'variouse options');
    
    is_deeply([$result->invalid_keys], [qw/k2 k4 k7 k8/], 'invalid key');
    
    is_deeply($result->data->{k1},[1, [3, 4]], 'data');
    ok(!$result->data->{k2}, 'data not exist in error case');
    cmp_ok($result->data->{k3}, 'eq', 3, 'filter');
    ok(!$result->data->{k4}, 'data not set in case error');
    is($result->data->{k9}, 2, 'arg');
    isa_ok($result->data->{k10}, 'T5');
    isa_ok($result->data->{k11}->[0], 'T5');
    isa_ok($result->data->{k11}->[1], 'T5');

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
    like($@, qr/First argument must be hash ref/, 'Data not hash ref');
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
    
    my $vresult = $vc->rule($rule)->validate($data);
    my @invalid_keys = $vresult->invalid_keys;
    is_deeply([@invalid_keys], ['name'], 'constraint argument first');
    
    my $errors_hash = $vresult->errors_to_hash;
    is_deeply($errors_hash, {name => $DEFAULT_MESSAGE},
              'errors_to_hash message not specified');
    
    is($vresult->error('name'), $DEFAULT_MESSAGE, 'error default message');
    
    @invalid_keys = $vc->rule($rule)->validate($data)->invalid_keys;
    is_deeply([@invalid_keys], ['name'], 'constraint argument second');
}

{
    my $result = Validator::Custom->new->rule([])->validate({key => 1});
    ok($result->is_valid, 'is_valid ok');
}

{
    my $vc = T1->new;
    $vc->register_constraint(
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
    
    is_deeply([$vc->validate($data)->invalid_keys], [qw/k1_1 k2_1/], 'register_constraints object');
}

my $vc;
my $params;
my $rule;
my $vresult;
my $errors;
my @errors;
my $data;


test 'or expression';
$vc = T1->new;
$rule = [
    key0 => [
        ['Int', 'Error-key0']
    ],
    key1 => [
        ['Int', 'Error-key1-0'],
        'Int'
    ],
    key1 => [
        ['aaa', 'Error-key1-1'],
        'aaa'
    ],
    key1 => [
        ['bbb', 'Error-key1-2']
    ],
    key2 => [
        ['Int', 'Error-key2']
    ]
];
$params = {key1 => 1, key0 => 1, key2 => 2};
$vresult = $vc->validate($params, $rule);
ok($vresult->is_valid, "$test : first key");

$params = {key1 => 'aaa', key0 => 1, key2 => 2};
$vresult = $vc->validate($params, $rule);
ok($vresult->is_valid, "$test : second key");

$params = {key1 => 'bbb', key0 => 1, key2 => 2};
$vresult = $vc->validate($params, $rule);
ok($vresult->is_valid, "$test : third key");
ok(!$vresult->error_reason('key1'), "$test : third key : error reason");
eval { $vresult->error_reason };
like($@, qr/Parameter name must be specified/, 'error_reason not Parameter name');

$params = {key1 => 'ccc', key0 => 1, key2 => 2};
$vresult = $vc->validate($params, $rule);
ok(!$vresult->is_valid, "$test : invalid");
is_deeply([$vresult->invalid_keys], ['key1'], "$test : invalid_keys");
is_deeply([$vresult->errors], ['Error-key1-0'], "$test : errors");
is_deeply($vresult->messages, ['Error-key1-0'], "$test : messages");
is($vresult->error_reason('key1'), 'Int', "$test : error reason");
is($vresult->error('key1'), 'Error-key1-0', "$test: error");
is($vresult->message('key1'), 'Error-key1-0', "$test: error");
eval{ $vresult->error };
like($@, qr/Parameter name must be specified/, 'error not Parameter name');

$vc = T1->new(error_stock => 0);
$params = {key1 => 'ccc', key0 => 1, key2 => 'no_num'};
$vresult = $vc->validate($params, $rule);
ok(!$vresult->is_valid, "$test : invalid");
is_deeply([$vresult->invalid_keys], ['key1'], "$test : invalid_keys");
is_deeply([$vresult->errors], ['Error-key1-0'], "$test : errors");
is($vresult->error_reason('key1'), 'Int', "$test : error reason");


test 'data_filter';
$vc = T1->new;
$params = {key1 => 1};
$vc->data_filter(sub {
    my $data = shift;
    
    $data->{key1} = 'a';
    
    return $data;
});
$vc->rule([
    key1 => [
        'Int'
    ]
]);
$vresult = $vc->validate($params);
is_deeply([$vresult->invalid_keys], ['key1'], "$test: basic");
is_deeply($vresult->raw_data, {key1 => 'a'}, "raw_data");


test 'Validator::Custom::Result raw_invalid_rule_keys';
$vc = Validator::Custom->new;
$vc->register_constraint(p => sub {
    my $values = shift;
    return $values->[0] eq $values->[1];
});
$vc->register_constraint(q => sub {
    my $value = shift;
    return $value eq 1;
});


$data = {k1 => 1, k2 => 2, k3 => 3, k4 => 1};
$rule = [
    {k12 => ['k1', 'k2']} => [
        'p'
    ],
    k3 => [
        'q'
    ],
    k4 => [
        'q'
    ]
];
$vresult = $vc->validate($data, $rule);

is_deeply($vresult->invalid_rule_keys, ['k12', 'k3'], 'invalid_rule_keys');
is_deeply($vresult->invalid_params, ['k1', 'k2', 'k3'],
          'invalid_params');
