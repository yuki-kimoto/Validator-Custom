use Test::More tests => 144;

use strict;
use warnings;
use lib 't/validator-custom';

my $test;
sub test {$test = shift}

my $value;

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
    like($@, qr/\QConstraint name '===' must be [A-Za-z0-9_]/, 'constraint invalid name')
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
    ok(!$result->is_ok, 'is_ok');
    
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
    like($@, qr/"No" is not registered/, 'no custom type');
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
        k11 => [
            '@C6'
        ]
    ];
    
    my $vc = T5->new;
    my $result= $vc->validate($data, $rule);
    is_deeply([$result->errors], 
              ['k2Error1', 'Error message not specified',
               'Error message not specified'
              ], 'variouse options');
    
    is_deeply([$result->invalid_keys], [qw/k2 k4 k7/], 'invalid key');
    
    is_deeply($result->data->{k1},[1, [3, 4]], 'data');
    ok(!$result->data->{k2}, 'data not exist in error case');
    cmp_ok($result->data->{k3}, 'eq', 3, 'filter');
    ok(!$result->data->{k4}, 'data not set in case error');
    isa_ok($result->data->{k11}->[0], 'T5');
    isa_ok($result->data->{k11}->[1], 'T5');

    $data = {k5 => 5, k6 => 6};
    $rule = [
        [qw/k5 k6/] => [
            [{'C3' => [5]}, 'k5 k6 Error']
        ]
    ];
    
    $result= $vc->validate($data, $rule);
    local $SIG{__WARN__} = sub {};
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
    ok($result->is_ok, 'is_ok ok');
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
ok($vresult->is_ok, "$test : first key");

$params = {key1 => 'aaa', key0 => 1, key2 => 2};
$vresult = $vc->validate($params, $rule);
ok($vresult->is_ok, "$test : second key");

$params = {key1 => 'bbb', key0 => 1, key2 => 2};
$vresult = $vc->validate($params, $rule);
ok($vresult->is_ok, "$test : third key");
ok(!$vresult->error_reason('key1'), "$test : third key : error reason");
eval { $vresult->error_reason };
like($@, qr/Parameter name must be specified/, 'error_reason not Parameter name');

$params = {key1 => 'ccc', key0 => 1, key2 => 2};
$vresult = $vc->validate($params, $rule);
ok(!$vresult->is_ok, "$test : invalid");
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
ok(!$vresult->is_ok, "$test : invalid");
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

test 'shared_rule';
$vc = Validator::Custom->new;
$vc->register_constraint(
    defined   => sub { defined $_[0] },
    not_blank => sub { $_[0] ne '' },
    int       => sub { $_[0] =~ /\d+/ }
);
$data = {
    k1 => undef,
    k2 => 'a',
    k3 => 1
};
$rule = [
    k1 => [
        # Nothing
    ],
    k2 => [
        # Nothing
    ],
    k3 => [
        'int'
    ]
];
$vc->shared_rule([
    ['defined', 'Must be defined'],
    ['not_blank',   'Must be blank']
]);
$vresult = $vc->validate($data, $rule);
is_deeply($vresult->messages_to_hash, {k1 => 'Must be defined'},
          'shared rule');

test 'constraints default';

my @infos = (
    [
        'not_defined',
        {
            k1 => undef,
            k2 => 'a',
        },
        [
            k1 => [
                'not_defined'
            ],
            k2 => [
                'not_defined'
            ],
        ],
        [qw/k2/]
    ],
    [
        'defined',
        {
            k1 => undef,
            k2 => 'a',
        },
        [
            k1 => [
                'defined'
            ],
            k2 => [
                'defined'
            ],
        ],
        [qw/k1/]
    ],
    [
        'not_space',
        {
            k1 => '',
            k2 => ' ',
            k3 => ' a '
        },
        [
            k1 => [
                'not_space'
            ],
            k2 => [
                'not_space'
            ],
            k3 => [
                'not_space'
            ],
        ],
        [qw/k1 k2/]
    ],
    [
        'not_blank',
        {
            k1 => '',
            k2 => 'a',
            k3 => ' '
        },
        [
            k1 => [
                'not_blank'
            ],
            k2 => [
                'not_blank'
            ],
            k3 => [
                'not_blank'
            ],
        ],
        [qw/k1/]
    ],
    [
        'blank',
        {
            k1 => '',
            k2 => 'a',
            k3 => ' '
        },
        [
            k1 => [
                'blank'
            ],
            k2 => [
                'blank'
            ],
            k3 => [
                'blank'
            ],
        ],
        [qw/k2 k3/]
    ],    
    [
        'int',
        {
            k8  => '19',
            k9  => '-10',
            k10 => 'a',
            k11 => '10.0',
        },
        [
            k8 => [
                'int'
            ],
            k9 => [
                'int'
            ],
            k10 => [
                'int'
            ],
            k11 => [
                'int'
            ],
        ],
        [qw/k10 k11/]
    ],
    [
        'uint',
        {
            k12  => '19',
            k13  => '-10',
            k14 => 'a',
            k15 => '10.0',
        },
        [
            k12 => [
                'uint'
            ],
            k13 => [
                'uint'
            ],
            k14 => [
                'uint'
            ],
            k15 => [
                'uint'
            ],
        ],
        [qw/k13 k14 k15/]
    ],
    [
        'ascii',
        {
            k16 => '!~',
            k17 => ' ',
            k18 => "\0x7f",
        },
        [
            k16 => [
                'ascii'
            ],
            k17 => [
                'ascii'
            ],
            k18 => [
                'ascii'
            ],
        ],
        [qw/k17 k18/]
    ],
    [
        'length',
        {
            k19 => '111',
            k20 => '111',
        },
        [
            k19 => [
                {'length' => [3, 4]},
                {'length' => [2, 3]},
                {'length' => [3]},
                {'length' => 3},
            ],
            k20 => [
                {'length' => [4, 5]},
            ]
        ],
        [qw/k20/],
    ],
    [
        'duplication',
        {
            k1_1 => 'a',
            k1_2 => 'a',
            
            k2_1 => 'a',
            k2_2 => 'b'
        },
        [
            {k1 => [qw/k1_1 k1_2/]} => [
                'duplication'
            ],
            {k2 => [qw/k2_1 k2_2/]} => [
                'duplication'
            ]
        ],
        [qw/k2/]
    ],
    [
        'regex',
        {
            k1 => 'aaa',
            k2 => 'aa',
        },
        [
            k1 => [
                {'regex' => "a{3}"}
            ],
            k2 => [
                {'regex' => "a{4}"}
            ]
        ],
        [qw/k2/]
    ],
    [
        'http_url',
        {
            k1 => 'http://www.lost-season.jp/mt/',
            k2 => 'iii',
        },
        [
            k1 => [
                'http_url'
            ],
            k2 => [
                'http_url'
            ]
        ],
        [qw/k2/]
    ],
    [
        'selected_at_least',
        {
            k1 => 1,
            k2 =>[1],
            k3 => [1, 2],
            k4 => [],
            k5 => [1,2]
        },
        [
            k1 => [
                {selected_at_least => 1}
            ],
            k2 => [
                {selected_at_least => 1}
            ],
            k3 => [
                {selected_at_least => 2}
            ],
            k4 => [
                'selected_at_least'
            ],
            k5 => [
                {'selected_at_least' => 3}
            ]
        ],
        [qw/k5/]
    ],
    [
        'greater_than',
        {
            k1 => 5,
            k2 => 5,
            k3 => 'a',
        },
        [
            k1 => [
                {'greater_than' => 5}
            ],
            k2 => [
                {'greater_than' => 4}
            ],
            k3 => [
                {'greater_than' => 1}
            ]
        ],
        [qw/k1 k3/]
    ],
    [
        'less_than',
        {
            k1 => 5,
            k2 => 5,
            k3 => 'a',
        },
        [
            k1 => [
                {'less_than' => 5}
            ],
            k2 => [
                {'less_than' => 6}
            ],
            k3 => [
                {'less_than' => 1}
            ]
        ],
        [qw/k1 k3/]
    ],
    [
        'equal_to',
        {
            k1 => 5,
            k2 => 5,
            k3 => 'a',
        },
        [
            k1 => [
                {'equal_to' => 5}
            ],
            k2 => [
                {'equal_to' => 4}
            ],
            k3 => [
                {'equal_to' => 1}
            ]
        ],
        [qw/k2 k3/]
    ],
    [
        'between',
        {
            k1 => 5,
            k2 => 5,
            k3 => 5,
            k4 => 5,
            k5 => 'a',
        },
        [
            k1 => [
                {'between' => [5, 6]}
            ],
            k2 => [
                {'between' => [4, 5]}
            ],
            k3 => [
                {'between' => [6, 7]}
            ],
            k4 => [
                {'between' => [5, 5]}
            ],
            k5 => [
                {'between' => [5, 5]}
            ]
        ],
        [qw/k3 k5/]
    ],
    [
        'decimal',
        {
            k1 => '12.123',
            k2 => '12.123',
            k3 => '12.123',
            k4 => '12',
            k5 => '123',
            k6 => '123.a',
        },
        [
            k1 => [
                {'decimal' => [2,3]}
            ],
            k2 => [
                {'decimal' => [1,3]}
            ],
            k3 => [
                {'decimal' => [2,2]}
            ],
            k4 => [
                {'decimal' => [2]}
            ],
            k5 => [
                {'decimal' => 2}
            ],
            k6 => [
                {'decimal' => 2}
            ]
        ],
        [qw/k2 k3 k5 k6/]
    ],
    [
        'in_array',
        {
            k1 => 'a',
            k2 => 'a',
            k3 => undef
        },
        [
            k1 => [
                {'in_array' => [qw/a b/]}
            ],
            k2 => [
                {'in_array' => [qw/b c/]}
            ],
            k3 => [
                {'in_array' => [qw/b c/]}
            ]
        ],
        [qw/k2 k3/]
    ],
    [
        'shift array',
        {
            k1 => [1, 2]
        },
        [
            k1 => [
                'shift'
            ]
        ],
        [],
        {k1 => 1}
    ],
    [
        'shift scalar',
        {
            k1 => 1
        },
        [
            k1 => [
                'shift'
            ]
        ],
        [],
        {k1 => 1}
    ],
);

foreach my $info (@infos) {
    validate_ok(@$info);
}

# exception
my @exception_infos = (
    [
        'duplication value1 undefined',
        {
            k1_1 => undef,
            k1_2 => 'a',
        },
        [
            [qw/k1_1 k1_2/] => [
                ['duplication']
            ],
        ],
        qr/\QConstraint 'duplication' needs two keys of data/
    ],
    [
        'duplication value2 undefined',
        {
            k2_1 => 'a',
            k2_2 => undef,
        },
        [
            [qw/k2_1 k2_2/] => [
                ['duplication']
            ]
        ],
        qr/\QConstraint 'duplication' needs two keys of data/
    ],
    [
        'length need parameter',
        {
            k1 => 'a',
        },
        [
            k1 => [
                'length'
            ]
        ],
        qr/\QConstraint 'length' needs one or two arguments/
    ],
    [
        'greater_than target undef',
        {
            k1 => 1
        },
        [
            k1 => [
                'greater_than'
            ]
        ],
        qr/\QConstraint 'greater_than' needs a numeric argument/
    ],
    [
        'greater_than not number',
        {
            k1 => 1
        },
        [
            k1 => [
                {'greater_than' => 'a'}
            ]
        ],
        qr/\QConstraint 'greater_than' needs a numeric argument/
    ],
    [
        'less_than target undef',
        {
            k1 => 1
        },
        [
            k1 => [
                'less_than'
            ]
        ],
        qr/\QConstraint 'less_than' needs a numeric argument/
    ],
    [
        'less_than not number',
        {
            k1 => 1
        },
        [
            k1 => [
                {'less_than' => 'a'}
            ]
        ],
        qr/\QConstraint 'less_than' needs a numeric argument/
    ],
    [
        'equal_to target undef',
        {
            k1 => 1
        },
        [
            k1 => [
                'equal_to'
            ]
        ],
        qr/\QConstraint 'equal_to' needs a numeric argument/
    ],
    [
        'equal_to not number',
        {
            k1 => 1
        },
        [
            k1 => [
                {'equal_to' => 'a'}
            ]
        ],
        qr/\QConstraint 'equal_to' needs a numeric argument/
    ],
    [
        'between target undef',
        {
            k1 => 1
        },
        [
            k1 => [
                {'between' => [undef, 1]}
            ]
        ],
        qr/\QConstraint 'between' needs two numeric arguments/
    ],
    [
        'between target undef or not number1',
        {
            k1 => 1
        },
        [
            k1 => [
                {'between' => ['a', 1]}
            ]
        ],
        qr/\QConstraint 'between' needs two numeric arguments/
    ],
    [
        'between target undef or not number2',
        {
            k1 => 1
        },
        [
            k1 => [
                {'between' => [1, undef]}
            ]
        ],
        qr/\QConstraint 'between' needs two numeric arguments/
    ],
    [
        'between target undef or not number3',
        {
            k1 => 1
        },
        [
            k1 => [
                {'between' => [1, 'a']}
            ]
        ],
        qr/\Qbetween' needs two numeric arguments/
    ],
    [
        'decimal target undef',
        {
            k1 => 1
        },
        [
            k1 => [
                'decimal'
            ]
        ],
        qr/\QConstraint 'decimal' needs one or two numeric arguments/
    ],
    [
        'decimal target not number 1',
        {
            k1 => 1
        },
        [
            k1 => [
                {'decimal' => ['a']}
            ]
        ],
        qr/\QConstraint 'decimal' needs one or two numeric arguments/
    ],
    [
        'DECIMAL target not number 2',
        {
            k1 => 1
        },
        [
            k1 => [
                {'decimal' => [1, 'a']}
            ]
        ],
        qr/\QConstraint 'decimal' needs one or two numeric arguments/
    ],
);

foreach my $exception_info (@exception_infos) {
    validate_exception(@$exception_info)
}

sub validate_ok {
    my ($test_name, $data, $validation_rule, $invalid_keys, $result_data) = @_;
    my $vc = Validator::Custom->new;
    my $r = $vc->validate($data, $validation_rule);
    is_deeply([$r->invalid_keys], $invalid_keys, "$test_name invalid_keys");
    
    if (ref $result_data eq 'CODE') {
        $result_data->($r);
    }
    elsif($result_data) {
        is_deeply($r->data, $result_data, "$test_name result data");
    }
}

sub validate_exception {
    my ($test_name, $data, $validation_rule, $error) = @_;
    my $vc = Validator::Custom->new;
    eval{$vc->validate($data, $validation_rule)};
    like($@, $error, "$test_name exception");
}

test 'trim';
{
    my $data = {
        int_param => ' 123 ',
        collapse  => "  \n a \r\n b\nc  \t",
        left      => '  abc  ',
        right     => '  def  '
    };

    my $validation_rule = [
      int_param => [
          ['trim']
      ],
      collapse  => [
          ['trim_collapse']
      ],
      left      => [
          ['trim_lead']
      ],
      right     => [
          ['trim_trail']
      ]
    ];

    my $result_data= Validator::Custom->new->validate($data,$validation_rule)->data;

    is_deeply(
        $result_data, 
        { int_param => '123', left => "abc  ", right => '  def', collapse => "a b c"},
        'trim check'
    );
}

test 'Carp trust relationship';
$data = {a => undef, b => undef};
$vc = Validator::Custom->new;
$rule = [
    {pass => [qw/a b/]} => [
        'duplication'
    ]
];
eval{$vc->validate($data, $rule)};
like($@, qr/\.t /, $test);


test 'Negative validation';
$data = {key1 => 'a', key2 => 1};
$vc = Validator::Custom->new;
$rule = [
    key1 => [
        'not_blank',
        '!int',
        'not_blank'
    ],
    key2 => [
        'not_blank',
        '!int',
        'not_blank'
    ]
];
my $result = $vc->validate($data, $rule);
is_deeply($result->invalid_params, ['key2'], "$test: single value");

$data = {key1 => ['a', 'a'], key2 => [1, 1]};
$vc = Validator::Custom->new;
$rule = [
    key1 => [
        '@not_blank',
        '@!int',
        '@not_blank'
    ],
    key2 => [
        '@not_blank',
        '@!int',
        '@not_blank'
    ]
];
$result = $vc->validate($data, $rule);
is_deeply($result->invalid_params, ['key2'], "$test: multi values");

$data = {key1 => 2, key2 => 1};
$vc = Validator::Custom->new;
$vc->register_constraint(
    one => sub {
        my $value = shift;
        
        if ($value == 1) {
            return [1, $value];
        }
        else {
            return [0, $value];
        }
    }
);
$rule = [
    key1 => [
        '!one',
    ],
    key2 => [
        '!one'
    ]
];
$result = $vc->validate($data, $rule);
is_deeply($result->invalid_params, ['key2'], "$test: filter value");


test 'missing_params';
$data = {key1 => 1};
$vc = Validator::Custom->new;
$rule = [
    key1 => [
        'int'
    ],
    key2 => [
        'int'
    ],
    {rkey1 => ['key2', 'key3']} => [
        'duplication'
    ]
];
$result = $vc->validate($data, $rule);
ok(!$result->is_ok, "$test : invalid");
is_deeply($result->missing_params, ['key2', 'key3'], "$test : names");

test 'has_missing';
$data = {};
$vc = Validator::Custom->new;
$rule = [
    key1 => [
        'int'
    ]
];
$result = $vc->validate($data, $rule);
ok($result->has_missing, "$test : missing");

$data = {key1 => 'a'};
$vc = Validator::Custom->new;
$rule = [
    key1 => [
        'int'
    ]
];
$result = $vc->validate($data, $rule);
ok(!$result->has_missing, "$test : missing");


test 'duplication result value';
$data = {key1 => 'a', key2 => 'a'};
$rule = [
    {key3 => ['key1', 'key2']} => [
        'duplication'
    ]
];
$vc = Validator::Custom->new;
$result = $vc->validate($data, $rule);
is($result->data->{key3}, 'a', $test);


test 'message option';
$data = {key1 => 'a'};
$rule = [
    key1 => {message => 'error'} => [
        'int'
    ]
];
$vc = Validator::Custom->new;
$result = $vc->validate($data, $rule);
is($result->message('key1'), 'error', $test);


test 'default option';
$data = {};
$rule = [
    key1 => {default => 2} => [
    
    ]
];
$vc = Validator::Custom->new;
$result = $vc->validate($data, $rule);
ok($result->has_missing, "$test : has missing");
is($result->data->{key1}, 2, "$test : data value");

$data = {};
$rule = [
    key1 => {default => 2, copy => 0} => [
    
    ]
];
$vc = Validator::Custom->new;
$result = $vc->validate($data, $rule);
ok($result->has_missing, "$test : has missing ");
ok(!exists $result->data->{key1}, "$test : missing : data value and no copy");

$data = {key1 => 'a'};
$rule = [
    key1 => {default => 2} => [
        'int'
    ]
];
$vc = Validator::Custom->new;
$result = $vc->validate($data, $rule);
ok($result->has_invalid, "$test : has missing");
is($result->data->{key1}, 2, "$test : invalid : data value");

$data = {key1 => 'a'};
$rule = [
    key1 => {default => 2, copy => 0} => [
        'int'
    ]
];
$vc = Validator::Custom->new;
$result = $vc->validate($data, $rule);
ok($result->has_invalid, "$test : has missing");
ok(!exists $result->data->{key1}, "$test : invalid : data value and no copy");

test 'copy';
$data = {key1 => 'a', 'key2' => 'a'};
$rule = [
    {key3 => ['key1', 'key2']} => {copy => 0} => [
        'duplication'
    ]
];
$vc = Validator::Custom->new;
$result = $vc->validate($data, $rule);
ok($result->is_ok, "$test : ok");
is_deeply($result->data, {}, "$test : not copy");


test 'error_stock plus';
$data = {key1 => 'a', 'key2' => 'b', key4 => 'a'};
$rule = [
    key4  => {message => 'e1'} => [
        'int'
    ],
    {key3 => ['key1', 'key2']} => {message => 'e2'} => [
        'duplication'
    ],
];
$vc = Validator::Custom->new;
$vc->error_stock(0);
$result = $vc->validate($data, $rule);
is_deeply($result->messages, ['e1'], $test);


test 'is_valid';
$data = {key1 => 'a', key2 => 'b', key3 => 2};
$rule = [
    key1 => [
        'int'
    ],
    key2 => [
        'int'
    ],
    key3 => [
        'int'
    ]
];
$vc = Validator::Custom->new;
$result = $vc->validate($data, $rule);
ok(!$result->is_valid('key1'), "$test : 1");
ok(!$result->is_valid('key2'), "$test : 2");
ok($result->is_valid('key3'), "$test : 3");


test 'merge';
$data = {key1 => 'a', key2 => 'b', key3 => 'c'};
$rule = [
    {key => ['key1', 'key2', 'key3']} => [
        'merge'
    ],
];
$vc = Validator::Custom->new;
$result = $vc->validate($data, $rule);
is($result->data->{key}, 'abc', $test);

test 'Multi-Paramater validation using regex';
$data = {key1 => 'a', key2 => 'b', key3 => 'c', p => 'd'};
$rule = [
    {key => qr/^key/} => [
        'merge'
    ],
];
$vc = Validator::Custom->new;
$result = $vc->validate($data, $rule);
$value = $result->data->{key};
ok(index($value, 'a') > -1, "$test : 1");
ok(index($value, 'b') > -1, "$test : 2");
ok(index($value, 'c') > -1, "$test : 3");
ok(index($value, 'd') == -1, "$test : 4");


test 'or condtioon new syntax';
$data = {key1 => '3', key2 => '', key3 => 'a'};
$rule = [
    key1 => [
        'blank || int'
    ],
    key2 => [
        'blank || int'
    ],
    key3 => [
        'blank || int'
    ],
];
$vc = Validator::Custom->new;
$result = $vc->validate($data, $rule);
is_deeply($result->invalid_rule_keys, ['key3']);


test 'or condition new syntax';
$data = {key1 => '3', key2 => '', key3 => 'a'};
$rule = [
    key1 => [
        'blank || !int'
    ],
    key2 => [
        'blank || !int'
    ],
    key3 => [
        'blank || !int'
    ],
];
$vc = Validator::Custom->new;
$result = $vc->validate($data, $rule);
is_deeply($result->invalid_rule_keys, ['key1']);


test 'space';
$data = {key1 => '', key2 => ' ', key3 => 'a'};
$rule = [
    key1 => [
        'space'
    ],
    key2 => [
        'space'
    ],
    key3 => [
        'space'
    ],
];
$vc = Validator::Custom->new;
$result = $vc->validate($data, $rule);
is_deeply($result->invalid_rule_keys, ['key3'], $test);


test 'or condition filter';
$data = {key1 => '2010/11/04', key2 => '2010-11-04', key3 => '2010 11 04'};
$rule = [
    key1 => [
        'date1 || date2 || date3'
    ],
    key2 => [
        'date1 || date2 || date3'
    ],
    key3 => [
        'date1 || date2 || date3'
    ],
];
$vc = Validator::Custom->new;
$vc->register_constraint(
    date1 => sub {
        my $value = shift;
        if ($value =~ m#(\d{4})/(\d{2})/(\d{2})#) {
            return [1, "$1$2$3"];
        }
        else {
            return [0, undef];
        }
    },
    date2 => sub {
        my $value = shift;
        if ($value =~ /(\d{4})-(\d{2})-(\d{2})/) {
            return [1, "$1$2$3"];
        }
        else {
            return [0, undef];
        }
    },
    date3 => sub {
        my $value = shift;
        if ($value =~ /(\d{4}) (\d{2}) (\d{2})/) {
            return [1, "$1$2$3"];
        }
        else {
            return [0, undef];
        }
    }

);
$result = $vc->validate($data, $rule);
ok($result->is_ok);
is_deeply($result->data, {key1 => '20101104', key2 => '20101104',
                          key3 => '20101104'}, $test);


test 'or condition filter array';
$data = {
    key1 => ['2010/11/04', '2010-11-04', '2010 11 04'],
    key2 => ['2010/11/04', '2010-11-04', 'xxx']
};
$rule = [
    key1 => [
        '@ date1 || date2 || date3'
    ],
    key2 => [
        '@ date1 || date2 || date3'
    ],
];
$vc = Validator::Custom->new;
$vc->register_constraint(
    date1 => sub {
        my $value = shift;
        if ($value =~ m#(\d{4})/(\d{2})/(\d{2})#) {
            return [1, "$1$2$3"];
        }
        else {
            return [0, undef];
        }
    },
    date2 => sub {
        my $value = shift;
        if ($value =~ /(\d{4})-(\d{2})-(\d{2})/) {
            return [1, "$1$2$3"];
        }
        else {
            return [0, undef];
        }
    },
    date3 => sub {
        my $value = shift;
        if ($value =~ /(\d{4}) (\d{2}) (\d{2})/) {
            return [1, "$1$2$3"];
        }
        else {
            return [0, undef];
        }
    }

);
$result = $vc->validate($data, $rule);
is_deeply($result->invalid_params, ['key2'], $test);
is_deeply($result->data, {key1 => ['20101104', '20101104', '20101104'],
                          }, $test);
