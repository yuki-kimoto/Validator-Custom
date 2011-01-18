use strict;
use warnings;

use Test::More;

eval "use Time::Piece;";
plan skip_all => 'Time::Piece required for this test!' if $@;

plan 'no_plan';

sub test { print "# $_[0]\n" }

use Validator::Custom;

my $vc;
my $rule;
my $data;
my $result;

test 'date_to_timepiece';
$vc = Validator::Custom->new;
$data = {date1 => '2010/11/12', date2 => '2010111106'};
$rule = [
    date1 => [
        'date_to_timepiece'
    ],
    date2 => [
        'date_to_timepiece'
    ],
];
$result = $vc->validate($data, $rule);
is_deeply($result->invalid_params, ['date2']);
is($result->data->{date1}->year, 2010);
is($result->data->{date1}->mon, 11);
is($result->data->{date1}->mday, 12);

$data = {date1 => '2010/33/12'};
$rule = [
    date1 => [
        'date_to_timepiece'
    ],
];
$result = $vc->validate($data, $rule);
ok($result->has_invalid);

$data = {year => 2011, month => 3, mday => 9};
$rule = [
    {date => ['year', 'month', 'mday']} => [
        'date_to_timepiece'
    ]
];
$result = $vc->validate($data, $rule);
ok($result->is_ok);
is($result->data->{date}->year, 2011);
is($result->data->{date}->mon, 3);
is($result->data->{date}->mday, 9);

$data = {year => 20115, month => 3, mday => 9};
$rule = [
    {date => ['year', 'month', 'mday']} => [
        'date_to_timepiece'
    ]
];
$result = $vc->validate($data, $rule);
ok($result->has_invalid);

$data = {year => 20115, month => 333, mday => 9};
$rule = [
    {date => ['year', 'month', 'mday']} => [
        'date_to_timepiece'
    ]
];
$result = $vc->validate($data, $rule);
ok($result->has_invalid);

$data = {year => 20115, month => 3, mday => 999};
$rule = [
    {date => ['year', 'month', 'mday']} => [
        'date_to_timepiece'
    ]
];
$result = $vc->validate($data, $rule);
ok($result->has_invalid);

$data = {year => 2011, month => 33, mday => 9};
$rule = [
    {date => ['year', 'month', 'mday']} => [
        'date_to_timepiece'
    ]
];
$result = $vc->validate($data, $rule);
ok($result->has_invalid);

$data = {year => 'a', month => 9, mday => 9};
$rule = [
    {date => ['year', 'month', 'mday']} => [
        'date_to_timepiece'
    ]
];
$result = $vc->validate($data, $rule);
ok($result->has_invalid);

$data = {year => 2010, month => 'a', mday => 9};
$rule = [
    {date => ['year', 'month', 'mday']} => [
        'date_to_timepiece'
    ]
];
$result = $vc->validate($data, $rule);
ok($result->has_invalid);

$data = {year => 2010, month => 11, mday => 'a'};
$rule = [
    {date => ['year', 'month', 'mday']} => [
        'date_to_timepiece'
    ]
];
$result = $vc->validate($data, $rule);
ok($result->has_invalid);

test 'datetime_to_timepiece';

$data = {datetime => '2010/11/12 12:14:45'};
$rule = [
    datetime => [
        'datetime_to_timepiece'
    ]
];
$result = $vc->validate($data, $rule);
ok($result->is_ok);
is($result->data->{datetime}->year, 2010);
is($result->data->{datetime}->mon, 11);
is($result->data->{datetime}->mday, 12);
is($result->data->{datetime}->hour, 12);
is($result->data->{datetime}->min, 14);
is($result->data->{datetime}->sec, 45);

$data = {datetime => '2010/11/12 12:14:4'};
$rule = [
    datetime => [
        'datetime_to_timepiece'
    ]
];
$result = $vc->validate($data, $rule);
ok(!$result->is_ok);

$data = {datetime => '2010/11/12 12:14:69'};
$rule = [
    datetime => [
        'datetime_to_timepiece'
    ]
];
$result = $vc->validate($data, $rule);
ok(!$result->is_ok);

$data = {year => 2011, month => 3, mday => 9,
         hour => 23, min => 45, sec => 19};
$rule = [
    {datetime => ['year', 'month', 'mday', 'hour', 'min', 'sec']} => [
        'datetime_to_timepiece'
    ]
];
$result = $vc->validate($data, $rule);
ok($result->is_ok);
is($result->data->{datetime}->year, 2011);
is($result->data->{datetime}->mon, 3);
is($result->data->{datetime}->mday, 9);
is($result->data->{datetime}->hour, 23);
is($result->data->{datetime}->min, 45);
is($result->data->{datetime}->sec, 19);

$data = {year => 2011, month => 3, mday => 9,
         hour => 23, min => 45, sec => 69};
$rule = [
    {datetime => ['year', 'month', 'mday', 'hour', 'min', 'sec']} => [
        'datetime_to_timepiece'
    ]
];
$result = $vc->validate($data, $rule);
ok(!$result->is_ok);

$data = {year => 'a', month => 3, mday => 9,
         hour => 23, min => 45, sec => 40};
$rule = [
    {datetime => ['year', 'month', 'mday', 'hour', 'min', 'sec']} => [
        'datetime_to_timepiece'
    ]
];
$result = $vc->validate($data, $rule);
ok(!$result->is_ok);

$data = {year => 'a', month => 3, mday => 9,
         hour => 23, min => 45, sec => 40};
$rule = [
    {datetime => ['year', 'month', 'mday', 'hour', 'min', 'sec']} => [
        'datetime_to_timepiece'
    ]
];
$result = $vc->validate($data, $rule);
ok(!$result->is_ok);

$data = {year => 'a', month => 3, mday => 9,
         hour => 23, min => 45, sec => 40};
$rule = [
    {datetime => ['year', 'month', 'mday', 'hour', 'min', 'sec']} => [
        'datetime_to_timepiece'
    ]
];
$result = $vc->validate($data, $rule);
ok(!$result->is_ok);

$data = {year => 'a', month => 3, mday => 9,
         hour => 23, min => 45, sec => 40};
$rule = [
    {datetime => ['year', 'month', 'mday', 'hour', 'min', 'sec']} => [
        'datetime_to_timepiece'
    ]
];
$result = $vc->validate($data, $rule);
ok(!$result->is_ok);

$data = {year => 2000, month => 'a', mday => 9,
         hour => 23, min => 45, sec => 40};
$rule = [
    {datetime => ['year', 'month', 'mday', 'hour', 'min', 'sec']} => [
        'datetime_to_timepiece'
    ]
];
$result = $vc->validate($data, $rule);
ok(!$result->is_ok);

$data = {year => 2000, month => 3, mday => 'a',
         hour => 23, min => 45, sec => 40};
$rule = [
    {datetime => ['year', 'month', 'mday', 'hour', 'min', 'sec']} => [
        'datetime_to_timepiece'
    ]
];
$result = $vc->validate($data, $rule);
ok(!$result->is_ok);

$data = {year => 2000, month => 3, mday => 9,
         hour => 'a', min => 45, sec => 40};
$rule = [
    {datetime => ['year', 'month', 'mday', 'hour', 'min', 'sec']} => [
        'datetime_to_timepiece'
    ]
];
$result = $vc->validate($data, $rule);
ok(!$result->is_ok);

$data = {year => 2000, month => 3, mday => 9,
         hour => 23, min => 'a', sec => 40};
$rule = [
    {datetime => ['year', 'month', 'mday', 'hour', 'min', 'sec']} => [
        'datetime_to_timepiece'
    ]
];
$result = $vc->validate($data, $rule);
ok(!$result->is_ok);

$data = {year => 2000, month => 3, mday => 9,
         hour => 23, min => 45, sec => 'a'};
$rule = [
    {datetime => ['year', 'month', 'mday', 'hour', 'min', 'sec']} => [
        'datetime_to_timepiece'
    ]
];
$result = $vc->validate($data, $rule);
ok(!$result->is_ok);

