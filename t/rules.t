use Test::More 'no_plan';

use strict;
use warnings;
use Validator::Custom::Rules;
use Validator::Custom::Rule;

$SIG{__WARN__} = sub { warn $_[0] unless $_[0] =~ /DEPRECATED!/ };

# add and get method
{
  my $rules = Validator::Custom::Rules->new;
  
  # Add
  $rules->add(user => [
    id => [
      'ascii'
    ],
    name => [
      'not_blank'
    ],
    age => [
      'uint'
    ],
    {password_check => ['password1', 'password2']} => [
      'duplication'
    ]
  ]);
  
  $rules->add(book => [
    id => [
      'ascii'
    ],
    title => [
      'not_blank'
    ]
  ]);
  
  # Add rule object
  my $rule_obj = Validator::Custom::Rule->new;
  $rule_obj->parse(
    [
      id2 => [
        'ascii'
      ]
    ]
  );
  $rules->add(user2 => $rule_obj);

  my $rule_user = $rules->get('user');
  is($rule_user->rule->[1]->{key}, 'name');
  
  my $rule_book = $rules->get('book');
  is($rule_book->rule->[1]->{key}, 'title');
  
  my $rule_user2 = $rules->get('user2');
  is($rule_user2->rule->[0]->{key}, 'id2');
}

# filter
{
  my $rules = Validator::Custom::Rules->new;
  
  # Add
  $rules->add(user => [
    id => [
      'ascii'
    ],
    name => [
      'not_blank'
    ],
    age => [
      'uint'
    ],
    {password_check => ['password1', 'password2']} => [
      'duplication'
    ]
  ]);
  
  $rules->filter(user => {
    insert => ['name', 'age'],
    update => ['id', 'name', 'password_check']
  });
  
  # User insert
  my $rule_user_insert = $rules->get('user', 'insert');
  is(scalar @{$rule_user_insert->rule}, 2);
  is($rule_user_insert->rule->[0]->{key}, 'name');
  is($rule_user_insert->rule->[1]->{key}, 'age');

  # User update
  $DB::single = 1;
  my $rule_user_update = $rules->get('user', 'update');
  is(scalar @{$rule_user_update->rule}, 3);
  is($rule_user_update->rule->[0]->{key}, 'id');
  is($rule_user_update->rule->[1]->{key}, 'name');
  is((keys %{$rule_user_update->rule->[2]->{key}})[0], 'password_check');
}
