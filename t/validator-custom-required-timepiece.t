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
