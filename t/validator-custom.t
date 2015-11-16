use Test::More 'no_plan';

use strict;
use warnings;
use utf8;
use Validator::Custom;
use Validator::Custom::Rule;

{
  my $vc = Validator::Custom->new;
  $vc->register_constraint(Int => sub{$_[0] =~ /^\d+$/});
  my $input = { k1 => 1, k2 => [1,2], k3 => [1,'a', 'b'], k4 => 'a'};
  my $rule = $vc->create_rule;
  $rule->topic('k1')->each(1)->check('Int')->message("k1Error1");
  $rule->topic('k2')->each(1)->check('Int')->message("k2Error1");
  $rule->topic('k3')->each(1)->check('Int')->message("k3Error1");
  $rule->topic('k4')->each(1)->check('Int')->message("k4Error1");

  my $messages = $vc->validate($input, $rule)->messages;

  is_deeply($messages, [qw/k3Error1 k4Error1/], 'array validate');
}

my $vc_common = Validator::Custom->new;
$vc_common->register_constraint(
  Int => sub{$_[0] =~ /^\d+$/},
  Num => sub{
      require Scalar::Util;
      Scalar::Util::looks_like_number($_[0]);
  },
  C1 => sub {
      my ($value, $args, $options) = @_;
      return [1, $value * 2];
  },
  aaa => sub {$_[0] eq 'aaa'},
  bbb => sub {$_[0] eq 'bbb'}
);

# to_array_remove_blank filter
{
  my $vc = Validator::Custom->new;
  my $input = {key1 => 1, key2 => [1, 2], key3 => '', key4 => [1, 3, '', '']};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->filter('to_array_remove_blank');
  $rule->topic('key2')->filter('to_array_remove_blank');
  $rule->topic('key3')->filter('to_array_remove_blank');
  $rule->topic('key4')->filter('to_array_remove_blank');
  
  my $vresult = $vc->validate($input, $rule);
  is_deeply($vresult->output->{key1}, [1]);
  is_deeply($vresult->output->{key2}, [1, 2]);
  is_deeply($vresult->output->{key3}, []);
  is_deeply($vresult->output->{key4}, [1, 3]);
}

# Validator::Custom::Resut filter method
{
  my $vc = Validator::Custom->new;
  my $input = {
    k1 => ' 123 ',
  };
  my $rule = $vc->create_rule;
  $rule->topic('k1')->filter('trim');

  my $vresult= Validator::Custom->new->validate($input, $rule)->output;

  is_deeply($vresult, {k1 => '123'});
}

# array validation new syntax
{
  my $vc = Validator::Custom->new;
  my $rule = $vc->create_rule;
  my $input = { k1 => 1, k2 => [1,2], k3 => [1,'a', 'b'], k4 => 'a', k5 => []};
  $rule->topic('k1')->filter('to_array')->check({selected_at_least => 1})->each(1)->check('int')->message('k1Error1');
  $rule->topic('k2')->filter('to_array')->check({selected_at_least => 1})->each(1)->check('int')->message('k2Error1');
  $rule->topic('k3')->filter('to_array')->check({selected_at_least => 1})->each(1)->check('int')->message('k3Error1');
  $rule->topic('k4')->filter('to_array')->check({selected_at_least => 1})->each(1)->check('int')->message('k4Error1');
  $rule->topic('k5')->filter('to_array')->check({selected_at_least => 1})->each(1)->check('int')->message('k5Error1');
  
  my $messages = $vc->validate($input, $rule)->messages;

  is_deeply($messages, [qw/k3Error1 k4Error1 k5Error1/], 'array validate');
}

{
  my $vc = Validator::Custom->new;
  my $input = {k1 => 1, k2 => 2, k3 => 3};
  my $rule = $vc->create_rule;
  $rule->topic('k1')
    ->check(sub{$_[0] == 1})->message("k1Error1")
    ->check(sub{$_[0] == 2})->message("k1Error2")
    ->check(sub{$_[0] == 3})->message("k1Error3");
  $rule->topic('k2')
    ->check(sub{$_[0] == 2})->message("k2Error1")
    ->check(sub{$_[0] == 3})->message("k2Error2");

  my $vresult   = $vc->validate($input, $rule);
  
  my $messages      = $vresult->messages;
  my $messages_hash = $vresult->messages_to_hash;
  
  is_deeply($messages, [qw/k1Error2 k2Error2/], 'rule');
  is_deeply($messages_hash, {k1 => 'k1Error2', k2 => 'k2Error2'}, 'rule errors hash');
  
  my $messages_hash2 = $vresult->messages_to_hash;
  is_deeply($messages_hash2, {k1 => 'k1Error2', k2 => 'k2Error2'}, 'rule errors hash');
  
  $messages = Validator::Custom->new(rule => $rule)->validate($input)->messages;
  is_deeply($messages, [qw/k1Error2 k2Error2/], 'rule');
}

{
  ok(!Validator::Custom->new->rule, 'rule default');
}

{
  my $result = Validator::Custom::Result->new;
  $result->output({k => 1});
  is_deeply($result->output, {k => 1}, 'data attribute');
}

{
  my $vc = $vc_common;
  my $input = { k1 => 1, k2 => 'a', k3 => 3.1, k4 => 'a' };
  my $rule = $vc->create_rule;
  $rule->topic('k1')->check('Int')->message("k1Error1");
  $rule->topic('k2')->check('Int')->message("k2Error1");
  $rule->topic('k3')->check('Num')->message("k3Error1");
  $rule->topic('k4')->check('Num')->message("k4Error1");
  my $result= $vc->validate($input, $rule);
  is_deeply($result->messages, [qw/k2Error1 k4Error1/], 'Custom validator');
  is_deeply($result->invalid_rule_keys, [qw/k2 k4/], 'invalid keys hash');
  ok(!$result->is_ok, 'is_ok');
  
  {
    my $vc = $vc_common;
    my $constraints = $vc->constraints;
    ok(exists($constraints->{Int}), 'get constraints');
    ok(exists($constraints->{Num}), 'get constraints');
  }
}

{
  my $vc = $vc_common;
  my $input = { k1 => 1, k2 => 'a', k3 => 3.1, k4 => 'a' };
  my $rule = $vc->create_rule;
  $rule->topic('k1')->check('Int')->message("k1Error1");
  $rule->topic('k2')->check('Int')->message("k2Error1");
  $rule->topic('k3')->check('Num')->message("k3Error1");
  $rule->topic('k4')->check('Num')->message("k4Error1");
  
  my $messages = $vc->validate($input, $rule)->messages;
  is_deeply($messages, [qw/k2Error1 k4Error1/], 'Custom validator one');
  
  $messages = $vc->validate($input, $rule)->messages;
  is_deeply($messages, [qw/k2Error1 k4Error1/], 'Custom validator two');
}

{
  my $vc = $vc_common;
  my $input = {k1 => 1};
  my $rule = $vc->create_rule;
  eval { $rule->topic('k1')->check('No')->message("k1Error1") };
  like($@, qr/"No" is not registered/, 'no custom type');
}

{
  my $vc = Validator::Custom->new;
  $vc->register_constraint(
    C1 => sub {
      my ($value, $args, $options) = @_;
      return [1, $value * 2];
    }
  );
  my $input = {k1 => [1,2]};
  my $rule = $vc->create_rule;
  $rule->topic('k1')->each(1)->check('C1')->message("k1Error1")
    ->check('C1')->message("k1Error1");

  my $result= $vc->validate($input, $rule);
  is_deeply(scalar $result->messages, [], 'no error');
  
  is_deeply(scalar $result->output, {k1 => [4,8]}, 'array validate2');
}


{
  my $vc = $vc_common;
  my $input = { k1 => 1};
  my $rule = $vc->create_rule;
  $rule->topic('k1')->check('Int')->message("k1Error1");
  my $messages = $vc->validate($input, $rule)->messages;
  is(scalar @$messages, 0, 'no error');
}

{
  my $vc = Validator::Custom->new;
  my $input = { k1 => 1, k2 => 'a', k3 => '  3  ', k4 => 4, k5 => 5, k6 => 5, k7 => 'a', k11 => [1,2]};

  $vc->register_constraint(
    C1 => sub {
      my ($value, $args) = @_;
      
      return [1, [$value, $args]];
    },
    
    C2 => sub {
      my ($value, $args) = @_;
      
      return [0, [$value, $args]];
    },
    
    TRIM_LEAD => sub {
      my $value = shift;
      
      $value =~ s/^ +//;
      
      return [1, $value];
    },
    
    TRIM_TRAIL => sub {
      my $value = shift;
      
      $value =~ s/ +$//;
      
      return [1, $value];
    },
    
    NO_ERROR => sub {
      return [0, 'a'];
    },
    
    C3 => sub {
      my ($values, $args) = @_;
      if ($values->[0] == $values->[1] && $values->[0] == $args->[0]) {
          return 1;
      }
      else {
          return 0;
      }
    },
    C4 => sub {
      my ($value, $arg) = @_;
      return defined $arg ? 1 : 0;
    },
    C5 => sub {
      my ($value, $arg) = @_;
      return [1, $arg];
    },
    C6 => sub {
      my $self = $_[2];
      return [1, $self];
    }
  );

  my $rule = $vc->create_rule;
  $rule->topic('k1')->check({'C1' => [3, 4]})->message("k1Error1");
  $rule->topic('k2')->check({'C2' => [3, 4]})->message("k2Error1");
  $rule->topic('k3')->filter('TRIM_LEAD')->filter('TRIM_TRAIL');
  $rule->topic('k4')->check('NO_ERROR');
  $rule->topic(['k5', 'k6'])->check({'C3' => [5]})->message('k5 k6 Error');
  $rule->topic('k7')->check({'C2' => [3, 4]});
  $rule->topic('k11')->each(1)->check('C6');
  
  {
    my $result= $vc->validate($input, $rule);
    is_deeply($result->messages, 
              ['k2Error1', 'Error message not specified',
               'Error message not specified'
              ], 'variouse options');
    
    is_deeply($result->invalid_rule_keys, [qw/k2 k4 k7/], 'invalid key');
    
    is_deeply($result->output->{k1},[1, [3, 4]], 'data');
    ok(!$result->output->{k2}, 'data not exist in error case');
    cmp_ok($result->output->{k3}, 'eq', 3, 'filter');
    ok(!$result->output->{k4}, 'data not set in case error');
  }
  {
    my $input = {k5 => 5, k6 => 6};
    my $rule = [
      [qw/k5 k6/] => [
        [{'C3' => [5]}, 'k5 k6 Error']
      ]
    ];
    
    my $result = $vc->validate($input, $rule);
    local $SIG{__WARN__} = sub {};
    ok(!$result->is_valid, 'corelative invalid_rule_keys');
    is(scalar @{$result->invalid_rule_keys}, 1, 'corelative invalid_rule_keys');
  }
}

{
  my $vc = Validator::Custom->new;
  my $input = { k1 => 1, k2 => 2};
  my $constraint = sub {
    my $values = shift;
    return $values->[0] eq $values->[1];
  };
  
  my $rule = $vc->create_rule;
  $rule->topic([qw/k1 k2/])->name('k1_2')->check($constraint)->message('error_k1_2');
  my $messages = $vc->validate($input, $rule)->messages;
  is_deeply($messages, ['error_k1_2'], 'specify key');
}

{
  eval{Validator::Custom->new->validate([])};
  like($@, qr/First argument must be hash ref/, 'Data not hash ref');
}

{
  eval{Validator::Custom->new->rule({})->validate({})};
  like($@, qr/Invalid rule structure/sm,
           'Validation rule not array ref');
}

{
  eval{Validator::Custom->new->rule([key => 'Int'])->validate({})};
  like($@, qr/Invalid rule structure/sm, 
           'Constraints of key not array ref');
}

{
  my $vc = Validator::Custom->new;
  $vc->register_constraint(
      length => sub {
          my ($value, $args) = @_;
          
          my $min;
          my $max;
          
          ($min, $max) = @$args;
          my $length  = length $value;
          return $min <= $length && $length <= $max ? 1 : 0;
      }
  );
  my $input = {
    name => 'zz' x 30,
    age => 'zz',
  };
  
  my $rule = $vc->create_rule;
  $rule->topic('name')->check({length => [1, 2]});
  
  my $vresult = $vc->validate($input, $rule);
  my $invalid_rule_keys = $vresult->invalid_rule_keys;
  is_deeply($invalid_rule_keys, ['name'], 'constraint argument first');
  
  my $messages_hash = $vresult->messages_to_hash;
  is_deeply($messages_hash, {name => 'Error message not specified'},
            'errors_to_hash message not specified');
  
  is($vresult->message('name'), 'Error message not specified', 'error default message');
  
  $invalid_rule_keys = $vc->validate($input, $rule)->invalid_rule_keys;
  is_deeply($invalid_rule_keys, ['name'], 'constraint argument second');
}

{
  my $result = Validator::Custom->new->rule([])->validate({key => 1});
  ok($result->is_ok, 'is_ok ok');
}

{
  my $vc = Validator::Custom->new;
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
  
  my $input = {k1_1 => 1, k1_2 => 2, k2_1 => 5, k2_2 => 6};
  
  my $rule = $vc->create_rule;
  $rule->topic('k1_1')->check('C1');
  $rule->topic('k1_2')->check('C1');
  $rule->topic('k2_1')->check('C2');
  $rule->topic('k2_2')->check('C2');
  
  is_deeply($vc->validate($input, $rule)->invalid_rule_keys, [qw/k1_1 k2_1/], 'register_constraints object');
}

# Validator::Custom::Result raw_invalid_rule_keys'
{
  my $vc = Validator::Custom->new;
  $vc->register_constraint(p => sub {
    my $values = shift;
    return $values->[0] eq $values->[1];
  });
  $vc->register_constraint(q => sub {
    my $value = shift;
    return $value eq 1;
  });
  
  my $input = {k1 => 1, k2 => 2, k3 => 3, k4 => 1};
  my $rule = $vc->create_rule;
  $rule->topic(['k1', 'k2'])->check('p')->name('k12');
  $rule->topic('k3')->check('q');
  $rule->topic('k4')->check('q');
  my $vresult = $vc->validate($input, $rule);

  is_deeply($vresult->invalid_rule_keys, ['k12', 'k3'], 'invalid_rule_keys');
  is_deeply($vresult->invalid_params, ['k1', 'k2', 'k3'],
          'invalid_params');
}

# constraints default;

# not_defined
{
  my $vc = Validator::Custom->new;
  my $input = {
    k1 => undef,
    k2 => 'a'
  };
  my $rule = $vc->create_rule;
  $rule->topic('k1')->check('not_defined');
  $rule->topic('k2')->check('not_defined');

  my $result = $vc->validate($input, $rule);
  is_deeply($result->invalid_rule_keys, ['k2']);
}

# defined
{
  my $vc = Validator::Custom->new;
  my $input = {
    k1 => undef,
    k2 => 'a',
  };
  my $rule = $vc->create_rule;
  $rule->topic('k1')->check('defined');
  $rule->topic('k2')->check('defined');

  my $result = $vc->validate($input, $rule);
  is_deeply($result->invalid_rule_keys, ['k1']);
}

# not_space
{
  my $vc = Validator::Custom->new;
  my $input = {
    k1 => '',
    k2 => ' ',
    k3 => ' a '
  };
  my $rule = $vc->create_rule;
  $rule->topic('k1')->check('not_space');
  $rule->topic('k2')->check('not_space');
  $rule->topic('k3')->check('not_space');

  my $result = $vc->validate($input, $rule);
  is_deeply($result->invalid_rule_keys, ['k1', 'k2']);
}

# not_blank
{
  my $vc = Validator::Custom->new;
  my $input = {
    k1 => '',
    k2 => 'a',
    k3 => ' '
  };
  my $rule = $vc->create_rule;
  $rule->topic('k1')->check('not_blank');
  $rule->topic('k2')->check('not_blank');
  $rule->topic('k3')->check('not_blank');

  my $result = $vc->validate($input, $rule);
  is_deeply($result->invalid_rule_keys, ['k1']);
}

# blank
{
  my $vc = Validator::Custom->new;
  my $input = {
    k1 => '',
    k2 => 'a',
    k3 => ' '
  };
  my $rule = $vc->create_rule;
  $rule->topic('k1')->check('blank');
  $rule->topic('k2')->check('blank');
  $rule->topic('k3')->check('blank');

  my $result = $vc->validate($input, $rule);
  is_deeply($result->invalid_rule_keys, ['k2', 'k3']);
}

# int
{
  my $vc = Validator::Custom->new;
  my $input = {
    k1  => '19',
    k2  => '-10',
    k3 => 'a',
    k4 => '10.0',
  };
  my $rule = $vc->create_rule;
  $rule->topic('k1')->check('int');
  $rule->topic('k2')->check('int');
  $rule->topic('k3')->check('int');
  $rule->topic('k4')->check('int');

  my $result = $vc->validate($input, $rule);
  is_deeply($result->invalid_rule_keys, ['k3', 'k4']);
}

# uint
{
  my $vc = Validator::Custom->new;
  my $input = {
    k1  => '19',
    k2  => '-10',
    k3 => 'a',
    k4 => '10.0',
  };
  my $rule = $vc->create_rule;
  $rule->topic('k1')->check('uint');
  $rule->topic('k2')->check('uint');
  $rule->topic('k3')->check('uint');
  $rule->topic('k4')->check('uint');

  my $result = $vc->validate($input, $rule);
  is_deeply($result->invalid_rule_keys, ['k2', 'k3', 'k4']);
}

# uint
{
  my $vc = Validator::Custom->new;
  my $input = {
    k1 => '!~',
    k2 => ' ',
    k3 => "\0x7f",
  };
  my $rule = $vc->create_rule;
  $rule->topic('k1')->check('ascii');
  $rule->topic('k2')->check('ascii');
  $rule->topic('k3')->check('ascii');

  my $result = $vc->validate($input, $rule);
  is_deeply($result->invalid_rule_keys, ['k2', 'k3']);
}

# length
{
  my $vc = Validator::Custom->new;
  my $input = {
    k1 => '111',
    k2 => '111',
  };
  my $rule = $vc->create_rule;
  $rule->topic('k1')
    ->check({'length' => [3, 4]})
    ->check({'length' => [2, 3]})
    ->check({'length' => [3]})
    ->check({'length' => 3});
  $rule->topic('k2')->check({'length' => [4, 5]});

  my $result = $vc->validate($input, $rule);
  is_deeply($result->invalid_rule_keys, ['k2']);
}

# duplication
{
  my $vc = Validator::Custom->new;
  my $input = {
    k1_1 => 'a',
    k1_2 => 'a',
    
    k2_1 => 'a',
    k2_2 => 'b'
  };
  my $rule = $vc->create_rule;
  $rule->topic([qw/k1_1 k1_2/])->check('duplication')->name('k1');
  $rule->topic([qw/k2_1 k2_2/])->check('duplication')->name('k2');

  my $result = $vc->validate($input, $rule);
  is_deeply($result->invalid_rule_keys, ['k2']);
}

# regex
{
  my $vc = Validator::Custom->new;
  my $input = {
    k1 => 'aaa',
    k2 => 'aa',
  };
  my $rule = $vc->create_rule;
  $rule->topic('k1')->check({'regex' => "a{3}"});
  $rule->topic('k2')->check({'regex' => "a{4}"});

  my $result = $vc->validate($input, $rule);
  is_deeply($result->invalid_rule_keys, ['k2']);
}

# http_url
{
  my $vc = Validator::Custom->new;
  my $input = {
    k1 => 'http://www.lost-season.jp/mt/',
    k2 => 'iii',
  };
  my $rule = $vc->create_rule;
  $rule->topic('k1')->check('http_url');
  $rule->topic('k2')->check('http_url');

  my $result = $vc->validate($input, $rule);
  is_deeply($result->invalid_rule_keys, ['k2']);
}

# selected_at_least
{
  my $vc = Validator::Custom->new;
  my $input = {
    k1 => 1,
    k2 =>[1],
    k3 => [1, 2],
    k4 => [],
    k5 => [1,2]
  };
  my $rule = $vc->create_rule;
  $rule->topic('k1')->check({selected_at_least => 1});
  $rule->topic('k2')->check({selected_at_least => 1});
  $rule->topic('k3')->check({selected_at_least => 2});
  $rule->topic('k4')->check('selected_at_least');
  $rule->topic('k5')->check({'selected_at_least' => 3});

  my $result = $vc->validate($input, $rule);
  is_deeply($result->invalid_rule_keys, ['k5']);
}

# greater_than
{
  my $vc = Validator::Custom->new;
  my $input = {
    k1 => 5,
    k2 => 5,
    k3 => 'a',
  };
  my $rule = $vc->create_rule;
  $rule->topic('k1')->check({'greater_than' => 5});
  $rule->topic('k2')->check({'greater_than' => 4});
  $rule->topic('k3')->check({'greater_than' => 1});

  my $result = $vc->validate($input, $rule);
  is_deeply($result->invalid_rule_keys, ['k1', 'k3']);
}

# less_than
{
  my $vc = Validator::Custom->new;
  my $input = {
    k1 => 5,
    k2 => 5,
    k3 => 'a',
  };
  my $rule = $vc->create_rule;
  $rule->topic('k1')->check({'less_than' => 5});
  $rule->topic('k2')->check({'less_than' => 6});
  $rule->topic('k3')->check({'less_than' => 1});

  my $result = $vc->validate($input, $rule);
  is_deeply($result->invalid_rule_keys, ['k1', 'k3']);
}

# less_than
{
  my $vc = Validator::Custom->new;
  my $input = {
    k1 => 5,
    k2 => 5,
    k3 => 'a',
  };
  my $rule = $vc->create_rule;
  $rule->topic('k1')->check({'equal_to' => 5});
  $rule->topic('k2')->check({'equal_to' => 4});
  $rule->topic('k3')->check({'equal_to' => 1});

  my $result = $vc->validate($input, $rule);
  is_deeply($result->invalid_rule_keys, ['k2', 'k3']);
}

# between
{
  my $vc = Validator::Custom->new;
  my $input = {
    k1 => 5,
    k2 => 5,
    k3 => 5,
    k4 => 5,
    k5 => 'a',
  };
  my $rule = $vc->create_rule;
  $rule->topic('k1')->check({'between' => [5, 6]});
  $rule->topic('k2')->check({'between' => [4, 5]});
  $rule->topic('k3')->check({'between' => [6, 7]});
  $rule->topic('k4')->check({'between' => [5, 5]});
  $rule->topic('k5')->check({'between' => [5, 5]});

  my $result = $vc->validate($input, $rule);
  is_deeply($result->invalid_rule_keys, ['k3', 'k5']);
}

# decimal
{
  my $vc = Validator::Custom->new;
  my $input = {
    k1 => '12.123',
    k2 => '12.123',
    k3 => '12.123',
    k4 => '12',
    k5 => '123',
    k6 => '123.a',
    k7 => '1234.1234',
    k8 => '',
    k9 => 'a',
    k10 => '1111111.12',
    k11 => '1111111.123',
    k12 => '12.1111111',
    k13 => '123.1111111'
  };
  my $rule = $vc->create_rule;
  $rule->topic('k1')->check({'decimal' => [2,3]});
  $rule->topic('k2')->check({'decimal' => [1,3]});
  $rule->topic('k3')->check({'decimal' => [2,2]});
  $rule->topic('k4')->check({'decimal' => [2]});
  $rule->topic('k5')->check({'decimal' => 2});
  $rule->topic('k6')->check({'decimal' => 2});
  $rule->topic('k7')->check('decimal');
  $rule->topic('k8')->check('decimal');
  $rule->topic('k9')->check('decimal');
  $rule->topic('k10')->check({'decimal' => [undef, 2]});
  $rule->topic('k11')->check({'decimal' => [undef, 2]});
  $rule->topic('k12')->check({'decimal' => [2, undef]});
  $rule->topic('k13')->check({'decimal' => [2, undef]});

  my $result = $vc->validate($input, $rule);
  is_deeply($result->invalid_rule_keys, [qw/k2 k3 k5 k6 k8 k9 k11 k13/]);
}

# in_array
{
  my $vc = Validator::Custom->new;
  my $input = {
    k1 => 'a',
    k2 => 'a',
    k3 => undef
  };
  my $rule = $vc->create_rule;
  $rule->topic('k1')->check({'in_array' => [qw/a b/]});
  $rule->topic('k2')->check({'in_array' => [qw/b c/]});
  $rule->topic('k3')->check({'in_array' => [qw/b c/]});

  my $result = $vc->validate($input, $rule);
  is_deeply($result->invalid_rule_keys, ['k2', 'k3']);
}

# shift
{
  my $vc = Validator::Custom->new;
  my $input = {
    k1 => [1, 2]
  };
  my $rule = $vc->create_rule;
  $rule->topic('k1')->check('shift');

  my $result = $vc->validate($input, $rule);
  is_deeply($result->output, {k1 => 1});
}

# shift
{
  my $vc = Validator::Custom->new;
  my $input = {
    k1 => 1
  };
  my $rule = $vc->create_rule;
  $rule->topic('k1')->check('shift');

  my $result = $vc->validate($input, $rule);
  is_deeply($result->output, {k1 => 1});
}

# exception
{
  # exception - length need parameter
  {
    my $vc = Validator::Custom->new;
    my $input = {
      k1 => 'a',
    };
    my $rule = $vc->create_rule;
    $rule->topic('k1')->check('length');
    eval { $vc->validate($input, $rule) };
    like($@, qr/\QConstraint 'length' needs one or two arguments/);
  }
  
  # exception - greater_than target undef
  {
    my $vc = Validator::Custom->new;
    my $input = {
      k1 => 1
    };
    my $rule = $vc->create_rule;
    $rule->topic('k1')->check('greater_than');
    eval { $vc->validate($input, $rule) };
    like($@, qr/\QConstraint 'greater_than' needs a numeric argument/);
  }

  # exception - greater_than not number
  {
    my $vc = Validator::Custom->new;
    my $input = {
      k1 => 1
    };
    my $rule = $vc->create_rule;
    $rule->topic('k1')->check({'greater_than' => 'a'});
    eval { $vc->validate($input, $rule) };
    like($@, qr/\QConstraint 'greater_than' needs a numeric argument/);
  }

  # exception - less_than target undef
  {
    my $vc = Validator::Custom->new;
    my $input = {
      k1 => 1
    };
    my $rule = $vc->create_rule;
    $rule->topic('k1')->check('less_than');
    eval { $vc->validate($input, $rule) };
    like($@, qr/\QConstraint 'less_than' needs a numeric argument/);
  }

  # exception - less_than not number
  {
    my $vc = Validator::Custom->new;
    my $input = {
      k1 => 1
    };
    my $rule = $vc->create_rule;
    $rule->topic('k1')->check({'less_than' => 'a'});
    eval { $vc->validate($input, $rule) };
    like($@, qr/\QConstraint 'less_than' needs a numeric argument/);
  }

  # exception - equal_to target undef
  {
    my $vc = Validator::Custom->new;
    my $input = {
      k1 => 1
    };
    my $rule = $vc->create_rule;
    $rule->topic('k1')->check('equal_to');
    eval { $vc->validate($input, $rule) };
    like($@, qr/\QConstraint 'equal_to' needs a numeric argument/);
  }

  # exception - equal_to not number
  {
    my $vc = Validator::Custom->new;
    my $input = {
      k1 => 1
    };
    my $rule = $vc->create_rule;
    $rule->topic('k1')->check({'equal_to' => 'a'});
    eval { $vc->validate($input, $rule) };
    like($@, qr/\QConstraint 'equal_to' needs a numeric argument/);
  }

  # exception - between undef
  {
    my $vc = Validator::Custom->new;
    my $input = {
      k1 => 1
    };
    my $rule = $vc->create_rule;
    $rule->topic('k1')->check({'between' => [undef, 1]});
    eval { $vc->validate($input, $rule) };
    like($@, qr/\QConstraint 'between' needs two numeric arguments/);
  }

  # exception - between target undef or not number1
  {
    my $vc = Validator::Custom->new;
    my $input = {
      k1 => 1
    };
    my $rule = $vc->create_rule;
    $rule->topic('k1')->check({'between' => ['a', 1]});
    eval { $vc->validate($input, $rule) };
    like($@, qr/\QConstraint 'between' needs two numeric arguments/);
  }

  # exception - between target undef or not number2
  {
    my $vc = Validator::Custom->new;
    my $input = {
      k1 => 1
    };
    my $rule = $vc->create_rule;
    $rule->topic('k1')->check({'between' => [1, undef]});
    eval { $vc->validate($input, $rule) };
    like($@, qr/\QConstraint 'between' needs two numeric arguments/);
  }

  # exception - between target undef or not number3
  {
    my $vc = Validator::Custom->new;
    my $input = {
      k1 => 1
    };
    my $rule = $vc->create_rule;
    $rule->topic('k1')->check({'between' => [1, 'a']});
    eval { $vc->validate($input, $rule) };
    like($@, qr/\Qbetween' needs two numeric arguments/);
  }
}

# trim;
{
  my $vc = Validator::Custom->new;
  my $input = {
    int_param => ' 123 ',
    collapse  => "  \n a \r\n b\nc  \t",
    left      => '  abc  ',
    right     => '  def  '
  };

  my $rule = $vc->create_rule;
  $rule->topic('int_param')->filter('trim');
  $rule->topic('collapse')->filter('trim_collapse');
  $rule->topic('left')->filter('trim_lead');
  $rule->topic('right')->filter('trim_trail');

  my $result_data= $vc->validate($input, $rule)->output;

  is_deeply(
    $result_data, 
    { int_param => '123', left => "abc  ", right => '  def', collapse => "a b c"},
    'trim check'
  );
}

# Negative validation
{
  my $vc = Validator::Custom->new;
  my $input = {key1 => 'a', key2 => 1};
  my $rule = $vc->create_rule;
  $rule->topic('key1')
    ->check('not_blank')
    ->check('!int')
    ->check('not_blank');
  $rule->topic('key2')
    ->check('not_blank')
    ->check('!int')
    ->check('not_blank');

  my $result = $vc->validate($input, $rule);
  is_deeply($result->invalid_params, ['key2'], "single value");
}

{
  my $vc = Validator::Custom->new;
  my $input = {key1 => ['a', 'a'], key2 => [1, 1]};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->each(1)
    ->check('@not_blank')
    ->check('@!int')
    ->check('@not_blank');
  $rule->topic('key2')->each(1)
    ->check('@not_blank')
    ->check('@!int')
    ->check('@not_blank');
  
  my $result = $vc->validate($input, $rule);
  is_deeply($result->invalid_params, ['key2'], "multi values");
}

{
  my $vc = Validator::Custom->new;
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
  my $input = {key1 => 2, key2 => 1};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check('!one');
  $rule->topic('key2')->check('!one');

  my $result = $vc->validate($input, $rule);
  is_deeply($result->invalid_params, ['key2'], "filter value");
}

# missing_params
{
  my $vc = Validator::Custom->new;
  my $input = {key1 => 1};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check('int');
  $rule->topic('key2')->check('int');
  $rule->topic(['key2', 'key3'])->check('duplication')->name('rkey1');

  my $result = $vc->validate($input, $rule);
  ok(!$result->is_ok, "invalid");
  is_deeply($result->missing_params, ['key2', 'key3'], "names");
}

# has_missing
{
  my $input = {};
  my $vc = Validator::Custom->new;
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check('int');

  my $result = $vc->validate($input, $rule);
  ok($result->has_missing, "missing");
}

{
  my $vc = Validator::Custom->new;
  my $input = {key1 => 'a'};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check('int');

  my $result = $vc->validate($input, $rule);
  ok(!$result->has_missing, "missing");
}

# duplication result value
{
  my $vc = Validator::Custom->new;
  my $input = {key1 => 'a', key2 => 'a'};
  my $rule = $vc->create_rule;
  $rule->topic(['key1', 'key2'])->check('duplication')->name('key3');
  
  my $result = $vc->validate($input, $rule);
  is($result->output->{key3}, 'a');
}

# message option
{
  my $vc = Validator::Custom->new;
  my $input = {key1 => 'a'};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check('int')->message('error');

  my $result = $vc->validate($input, $rule);
  is($result->message('key1'), 'error');
}

# default option
{
  my $vc = Validator::Custom->new;
  my $input = {};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check('int')->default(2);

  my $result = $vc->validate($input, $rule);
  ok($result->is_ok);
  is($result->output->{key1}, 2, "data value");
}

{
  my $vc = Validator::Custom->new;
  my $input = {key1 => 'a'};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check('int')->default(2);

  my $result = $vc->validate($input, $rule);
  ok($result->is_ok);
  is($result->output->{key1}, 2, "invalid : data value");
}

{
  my $vc = Validator::Custom->new;
  my $input = {key1 => 'a', key3 => 'b'};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check('int')->default(sub { return $_[0] });
  $rule->topic('key2')->check('int')->default(sub { return 5 });
  $rule->topic('key3')->check('int')->default(undef);
  
  my $result = $vc->validate($input, $rule);
  is($result->output->{key1}, $vc, "data value");
  is($result->output->{key2}, 5, "data value");
  ok(exists $result->output->{key3} && !defined $result->output->{key3});
}

# is_valid
{
  my $vc = Validator::Custom->new;
  my $input = {key1 => 'a', key2 => 'b', key3 => 2};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check('int');
  $rule->topic('key2')->check('int');
  $rule->topic('key3')->check('int');

  my $result = $vc->validate($input, $rule);
  ok(!$result->is_valid('key1'));
  ok(!$result->is_valid('key2'));
  ok($result->is_valid('key3'));
}

# merge
{
  my $vc = Validator::Custom->new;
  my $input = {key1 => 'a', key2 => 'b', key3 => 'c'};
  my $rule = $vc->create_rule;
  $rule->topic( ['key1', 'key2', 'key3'])->filter('merge')->name('key');

  my $result = $vc->validate($input, $rule);
  is($result->output->{key}, 'abc');
}

# space
{
  my $vc = Validator::Custom->new;
  my $input = {key1 => '', key2 => ' ', key3 => 'a'};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check('space');
  $rule->topic('key2')->check('space');
  $rule->topic('key3')->check('space');

  my $result = $vc->validate($input, $rule);
  is_deeply($result->invalid_rule_keys, ['key3']);
}

# any
{
  my $vc = Validator::Custom->new;
  my $input = {
    key1 => undef, key2 => 1
  };
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check('any');
  $rule->topic('key2')->check('any');

  my $result = $vc->validate($input, $rule);
  ok($result->is_ok);
}


# to_hash
{
  my $vc = Validator::Custom->new;
  my $input = {key1 => 1, key2 => 'a', key3 => 'a'};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check('int');
  $rule->topic('key2')->check('int')->message('a');
  $rule->topic('key3')->check('int')->message('b');
  $rule->topic('key4')->check('int')->message('key4 must be int');
  $rule->topic('key5')->check('int')->message('key5 must be int');
  
  my $result = $vc->validate($input, $rule);
  is_deeply($result->to_hash, {
    ok => $result->is_ok, invalid => $result->has_invalid,
    missing => $result->has_missing,
    missing_params => $result->missing_params,
    messages => $result->messages_to_hash
  });
  is_deeply($result->to_hash, {
    ok => 0, invalid => 1,
    missing => 1,
    missing_params => ['key4', 'key5'],
    messages => {key2 => 'a', key3 => 'b', key4 => 'key4 must be int', key5 => 'key5 must be int'}
  });
}

# optional
{
  my $vc = Validator::Custom->new;
  my $input = {key1 => 1};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check('int');
  $rule->topic('key2')->check('int')->message('a');
  $rule->topic('key3')->optional->check('int');

  my $result = $vc->validate($input, $rule);
  is_deeply($result->missing_params, ['key2']);
  ok(!$result->is_ok);
}

{
  my $vc = Validator::Custom->new;
  my $input = {key1 => 1};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->optional->check('int');
  $rule->topic('key2')->optional->check('int');
  $rule->topic('key3')->optional->check('int');

  my $result = $vc->validate($input, $rule);
  ok($result->is_ok);
  ok(!$result->has_invalid);
}

# to_array filter
{
  my $vc = Validator::Custom->new;
  my $input = {key1 => 1, key2 => [1, 2]};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check('to_array');
  $rule->topic('key2')->check('to_array');

  my $result = $vc->validate($input, $rule);
  is_deeply($result->output->{key1}, [1]);
  is_deeply($result->output->{key2}, [1, 2]);
}

# loose_data
{
  my $vc = Validator::Custom->new;
  my $input = {key1 => 1, key2 => 2};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->filter('to_array');

  my $result = $vc->validate($input, $rule);
  is_deeply($result->loose_data->{key1}, [1]);
  is_deeply($result->loose_data->{key2}, 2);
}

{
  my $vc = Validator::Custom->new;
  my $input = {key1 => 'a'};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check('int')->default(5);

  my $result = $vc->validate($input, $rule);
  is_deeply($result->loose_data->{key1}, 5);
}

# undefined value
{
  my $vc = Validator::Custom->new;
  my $input = {key1 => undef, key2 => '', key3 => 'a'};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check('ascii');
  $rule->topic('key2')->check('ascii');
  $rule->topic('key3')->check('ascii');

  my $result = $vc->validate($input, $rule);
  ok(!$result->is_valid('key1'));
  ok(!$result->is_valid('key2'));
  ok($result->is_valid('key3'));
}

{
  my $vc = $vc_common;
  my $input = {key1 => undef, key2 => '', key3 => '2'};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check({between => [1, 3]});
  $rule->topic('key2')->check({between => [1, 3]});
  $rule->topic('key3')->check({between => [1, 3]});

  my $result = $vc->validate($input, $rule);
  ok(!$result->is_valid('key1'));
  ok(!$result->is_valid('key2'));
  ok($result->is_valid('key3'));
}

{
  my $vc = $vc_common;
  my $input = {key1 => undef, key2 => ''};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check('blank');
  $rule->topic('key2')->check('blank');

  my $result = $vc->validate($input, $rule);
  ok(!$result->is_valid('key1'));
  ok($result->is_valid('key2'));
}

{
  my $vc = $vc_common;
  my $input = {key1 => undef, key2 => '', key3 => '2.1'};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check({decimal => 1});
  $rule->topic('key2')->check({decimal => 1});
  $rule->topic('key3')->check({decimal => [1, 1]});

  my $result = $vc->validate($input, $rule);
  ok(!$result->is_valid('key1'));
  ok(!$result->is_valid('key2'));
  ok($result->is_valid('key3'));
}

{
  my $vc = $vc_common;
  my $input = {key1 => 'a', key2 => 'a', key3 => '', key4 => '', key5 => undef, key6 => undef};
  my $rule = $vc->create_rule;
  $rule->topic(['key1', 'key2'])->check('duplication')->name('key1-2');
  $rule->topic(['key3', 'key4'])->check('duplication')->name('key3-4');
  $rule->topic(['key1', 'key5'])->check('duplication')->name('key1-5');
  $rule->topic(['key5', 'key1'])->check('duplication')->name('key5-1');
  $rule->topic(['key5', 'key6'])->check('duplication')->name('key5-6');

  my $result = $vc->validate($input, $rule);
  ok($result->is_valid('key1-2'));
  ok($result->is_valid('key3-4'));
  ok(!$result->is_valid('key1-5'));
  ok(!$result->is_valid('key5-1'));
  ok(!$result->is_valid('key5-6'));
}

{
  my $vc = $vc_common;
  my $input = {key1 => undef, key2 => '', key3 => '1'};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check({equal_to => 1});
  $rule->topic('key2')->check({equal_to => 1});
  $rule->topic('key3')->check({equal_to => 1});

  my $result = $vc->validate($input, $rule);
  ok(!$result->is_valid('key1'));
  ok(!$result->is_valid('key2'));
  ok($result->is_valid('key3'));
}

{
  my $vc = $vc_common;
  my $input = {key1 => undef, key2 => '', key3 => '5'};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check({greater_than => 1});
  $rule->topic('key2')->check({greater_than => 1});
  $rule->topic('key3')->check({greater_than => 1});

  my $result = $vc->validate($input, $rule);
  ok(!$result->is_valid('key1'));
  ok(!$result->is_valid('key2'));
  ok($result->is_valid('key3'));
}

{
  my $vc = $vc_common;
  my $input = {key1 => undef, key2 => '', key3 => 'http://aaa.com'};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check('http_url');
  $rule->topic('key2')->check('http_url');
  $rule->topic('key3')->check('http_url');

  my $result = $vc->validate($input, $rule);
  ok(!$result->is_valid('key1'));
  ok(!$result->is_valid('key2'));
  ok($result->is_valid('key3'));
}

{
  my $vc = $vc_common;
  my $input = {key1 => undef, key2 => '', key3 => '1'};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check('int');
  $rule->topic('key2')->check('int');
  $rule->topic('key3')->check('int');

  my $result = $vc->validate($input, $rule);
  ok(!$result->is_valid('key1'));
  ok(!$result->is_valid('key2'));
  ok($result->is_valid('key3'));
}

{
  my $vc = $vc_common;
  my $input = {key1 => undef, key2 => '', key3 => '1'};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check({'in_array' => [1, 2]});
  $rule->topic('key2')->check({'in_array' => [1, 2]});
  $rule->topic('key3')->check({'in_array' => [1, 2]});

  my $result = $vc->validate($input, $rule);
  ok(!$result->is_valid('key1'));
  ok(!$result->is_valid('key2'));
  ok($result->is_valid('key3'));
}

{
  my $vc = $vc_common;
  my $input = {key1 => undef, key2 => '', key3 => 'aaa'};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check({'length' => [1, 4]});
  $rule->topic('key2')->check({'length' => [1, 4]});
  $rule->topic('key3')->check({'length' => [1, 4]});

  my $result = $vc->validate($input, $rule);
  ok(!$result->is_valid('key1'));
  ok(!$result->is_valid('key2'));
  ok($result->is_valid('key3'));
}

{
  my $vc = $vc_common;
  my $input = {key1 => undef, key2 => '', key3 => 3};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check({'less_than' => 4});
  $rule->topic('key2')->check({'less_than' => 4});
  $rule->topic('key3')->check({'less_than' => 4});

  my $result = $vc->validate($input, $rule);
  ok(!$result->is_valid('key1'));
  ok(!$result->is_valid('key2'));
  ok($result->is_valid('key3'));
}

{
  my $vc = $vc_common;
  my $input = {key1 => undef, key2 => '', key3 => 3};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check('not_blank');
  $rule->topic('key2')->check('not_blank');
  $rule->topic('key3')->check('not_blank');

  my $result = $vc->validate($input, $rule);
  ok(!$result->is_valid('key1'));
  ok(!$result->is_valid('key2'));
  ok($result->is_valid('key3'));
}

{
  my $vc = $vc_common;
  my $input = {key1 => undef, key2 => '', key3 => 3};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check('not_space');
  $rule->topic('key2')->check('not_space');
  $rule->topic('key3')->check('not_space');

  my $result = $vc->validate($input, $rule);
  ok(!$result->is_valid('key1'));
  ok(!$result->is_valid('key2'));
  ok($result->is_valid('key3'));
}

{
  my $vc = $vc_common;
  my $input = {key1 => undef, key2 => '', key3 => 3};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check('uint');
  $rule->topic('key2')->check('uint');
  $rule->topic('key3')->check('uint');

  my $result = $vc->validate($input, $rule);
  ok(!$result->is_valid('key1'));
  ok(!$result->is_valid('key2'));
  ok($result->is_valid('key3'));
}

{
  my $vc = $vc_common;
  my $input = {key1 => undef, key2 => '', key3 => 3};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check({'regex' => qr/3/});
  $rule->topic('key2')->check({'regex' => qr/3/});
  $rule->topic('key3')->check({'regex' => qr/3/});

  my $result = $vc->validate($input, $rule);
  ok(!$result->is_valid('key1'));
  ok(!$result->is_valid('key2'));
  ok($result->is_valid('key3'));
}

{
  my $vc = $vc_common;
  my $input = {key1 => undef, key2 => '', key3 => ' '};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check('space');
  $rule->topic('key2')->check('space');
  $rule->topic('key3')->check('space');

  my $result = $vc->validate($input, $rule);
  ok(!$result->is_valid('key1'));
  ok($result->is_valid('key2'));
  ok($result->is_valid('key3'));
}

{
  my $vc = $vc_common;
  my $input = {key2 => 2};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check('defined')->message('key1 is undefined');

  my $result = $vc->validate($input, $rule);
  is_deeply($result->missing_params, ['key1']);
  is_deeply($result->messages, ['key1 is undefined']);
  ok(!$result->is_valid('key1'));
}

# between 0-9
{
  my $vc = $vc_common;
  my $input = {key1 => 0, key2 => 9};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check( {between => [0, 9]});
  $rule->topic('key2')->check({between => [0, 9]});

  my $result = $vc->validate($input, $rule);
  ok($result->is_ok);
}

# between decimal
{
  my $vc = $vc_common;
  my $input = {key1 => '-1.5', key2 => '+1.5', key3 => 3.5};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check({between => [-2.5, 1.9]});
  $rule->topic('key2')->check({between => ['-2.5', '+1.9']});
  $rule->topic('key3')->check({between => ['-2.5', '+1.9']});

  my $result = $vc->validate($input, $rule);
  ok($result->is_valid('key1'));
  ok($result->is_valid('key2'));
  ok(!$result->is_valid('key3'));
}

# equal_to decimal
{
  my $vc = $vc_common;
  my $input = {key1 => '+0.9'};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check({equal_to => '0.9'});

  my $result = $vc->validate($input, $rule);
  ok($result->is_valid('key1'));
}

# greater_than decimal
{
  my $vc = $vc_common;
  my $input = {key1 => '+10.9'};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check({greater_than => '9.1'});
  my $result = $vc->validate($input, $rule);
  ok($result->is_valid('key1'));
}

# int unicode
{
  my $vc = $vc_common;
  my $input = {key1 => 0, key2 => 9, key3 => '２'};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check('int');
  $rule->topic('key2')->check('int');
  $rule->topic('key3')->check('int');

  my $result = $vc->validate($input, $rule);
  ok($result->is_valid('key1'));
  ok($result->is_valid('key2'));
  ok(!$result->is_valid('key3'));
}

# less_than decimal
{
  my $vc = $vc_common;
  my $input = {key1 => '+0.9'};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check({less_than => '10.1'});

  my $result = $vc->validate($input, $rule);
  ok($result->is_valid('key1'));
}

# uint unicode
{
  my $vc = $vc_common;
  my $input = {key1 => 0, key2 => 9, key3 => '２'};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check('uint');
  $rule->topic('key2')->check('uint');
  $rule->topic('key3')->check('uint');

  my $result = $vc->validate($input, $rule);
  ok($result->is_valid('key1'));
  ok($result->is_valid('key2'));
  ok(!$result->is_valid('key3'));
}

# space unicode
{
  my $vc = $vc_common;
  my $input = {key1 => ' ', key2 => '　'};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check('space');
  $rule->topic('key2')->check('space');

  my $result = $vc->validate($input, $rule);
  ok($result->is_valid('key1'));
  ok(!$result->is_valid('key2'));
}

# not_space unicode
{
  my $vc = $vc_common;
  my $input = {key1 => ' ', key2 => '　'};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check('not_space');
  $rule->topic('key2')->check('not_space');

  my $result = $vc->validate($input, $rule);
  ok(!$result->is_valid('key1'));
  ok($result->is_valid('key2'));
}

# not_space unicode
{
  my $vc = $vc_common;
  my $input = {key1 => '　', key2 => '　', key3 => '　', key4 => '　'};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->filter('trim');
  $rule->topic('key2')->filter('trim_lead');
  $rule->topic('key3')->filter('trim_collapse');
  $rule->topic('key4')->filter('trim_trail');

  my $result = $vc->validate($input, $rule);
  is($result->output->{key1}, '　');
  is($result->output->{key2}, '　');
  is($result->output->{key3}, '　');
  is($result->output->{key4}, '　');
}

# lenght {min => ..., max => ...}
{
  my $vc = $vc_common;
  my $input = {
    key1_1 => 'a',
    key1_2 => 'aa',
    key1_3 => 'aaa',
    key1_4 => 'aaaa',
    key1_5 => 'aaaaa',
    key2_1 => 'a',
    key2_2 => 'aa',
    key2_3 => 'aaa',
    key3_1 => 'aaa',
    key3_2 => 'aaaa',
    key3_3 => 'aaaaa'
  };
  my $rule = $vc->create_rule;
  $rule->topic('key1_1')->check({'length' => {min => 2, max => 4}});
  $rule->topic('key1_2')->check({'length' => {min => 2, max => 4}});
  $rule->topic('key1_3')->check({'length' => {min => 2, max => 4}});
  $rule->topic('key1_4')->check({'length' => {min => 2, max => 4}});
  $rule->topic('key1_5')->check({'length' => {min => 2, max => 4}});
  $rule->topic('key2_1')->check({'length' => {min => 2}});
  $rule->topic('key2_2')->check({'length' => {min => 2}});
  $rule->topic('key2_3')->check({'length' => {min => 2}});
  $rule->topic('key3_1')->check({'length' => {max => 4}});
  $rule->topic('key3_2')->check({'length' => {max => 4}});
  $rule->topic('key3_3')->check({'length' => {max => 4}});
  
  my $result = $vc->validate($input, $rule);
  ok(!$result->is_valid('key1_1'));
  ok($result->is_valid('key1_2'));
  ok($result->is_valid('key1_3'));
  ok($result->is_valid('key1_4'));
  ok(!$result->is_valid('key1_5'));
  ok(!$result->is_valid('key2_1'));
  ok($result->is_valid('key2_2'));
  ok($result->is_valid('key2_3'));
  ok($result->is_valid('key3_1'));
  ok($result->is_valid('key3_2'));
  ok(!$result->is_valid('key3_3'));
}

# trim_uni
{
  my $vc = Validator::Custom->new;
  my $input = {
    int_param => '　　123　　',
    collapse  => "　　\n a \r\n b\nc  \t　　",
    left      => '　　abc　　',
    right     => '　　def　　'
  };
  my $rule = $vc->create_rule;
  $rule->topic('int_param')->check('trim_uni');
  $rule->topic('collapse')->check('trim_uni_collapse');
  $rule->topic('left')->check('trim_uni_lead');
  $rule->topic('right')->check('trim_uni_trail');

  my $result_data= Validator::Custom->new->validate($input,$rule)->output;

  is_deeply(
    $result_data, 
    { int_param => '123', left => "abc　　", right => '　　def', collapse => "a b c"},
    'trim check'
  );
}

# Custom error message
{
  my $vc = Validator::Custom->new;
  $vc->register_constraint(
    c1 => sub {
      my $value = shift;
      
      if ($value eq 'a') {
        return 1;
      }
      else {
        return {result => 0, message => 'error1'};
      }
    },
    c2 => sub {
      my $value = shift;
      
      if ($value eq 'a') {
        return {result => 1};
      }
      else {
        return {message => 'error2'};
      }
    }
  );
  my $rule = $vc->create_rule;
  $rule->topic('k1')->check('c1');
  $rule->topic('k2')->each(1)->check('c2');
  my $vresult = $vc->validate({k1 => 'a', k2 => 'a'}, $rule);
  ok($vresult->is_ok);
  $vresult = $vc->validate({k1 => 'b', k2 => 'b'}, $rule);
  ok(!$vresult->is_ok);
  is_deeply($vresult->messages, ['error1', 'error2']);
}

# Filter hash representation
{
  my $vc = Validator::Custom->new;
  $vc->register_constraint(
    c1 => sub {
      my $value = shift;
      
      return {result => 1, output => $value * 2};
    }
  );
  my $rule = $vc->create_rule;
  $rule->topic('k1')->check('c1');
  $rule->topic('k2')->each(1)->check('c1');
  my $vresult = $vc->validate({k1 => 1, k2 => [2, 3]}, $rule);
  ok($vresult->is_ok);
  is($vresult->output->{k1}, 2);
  is_deeply($vresult->output->{k2}, [4, 6]);
}

# Use constraints function from $_
{
  my $vc = Validator::Custom->new;
  my $rule = $vc->create_rule;
  $rule->topic('k1')->check(sub { $_->blank(@_) || $_->regex($_[0], qr/[0-9]+/) });
  $rule->topic('k2')->check(sub { $_->blank(@_) || $_->regex($_[0], qr/[0-9]+/) });
  $rule->topic('k3')->check(sub { $_->blank(@_) || $_->regex($_[0], qr/[0-9]+/) });
  
  my $vresult = $vc->validate({k1 => '', k2 => '123', k3 => 'abc'}, $rule);
  ok($vresult->is_valid('k1'));
  ok($vresult->is_valid('k2'));
  ok(!$vresult->is_valid('k3'));
}

# new rule syntax
{
  my $vc = Validator::Custom->new;

  # new rule syntax - basic
  {
    my $rule = $vc->create_rule;
    $rule->topic('k1')->check('not_blank');
    $rule->topic('k2')->check('not_blank');
    $rule->topic('k3')->check('not_blank')->message('k3 is empty');
    $rule->topic('k4')->optional->check('not_blank')->default(5);
    my $vresult = $vc->validate({k1 => 'aaa', k2 => '', k3 => '', k4 => ''}, $rule);
    ok($vresult->is_valid('k1'));
    is($vresult->output->{k1}, 'aaa');
    ok(!$vresult->is_valid('k2'));
    ok(!$vresult->is_valid('k3'));
    is($vresult->messages_to_hash->{k3}, 'k3 is empty');
    is($vresult->output->{k4}, 5);
  }
  
  # new rule syntax - message option
  {
    my $rule = $vc->create_rule;
    $rule->topic('k1')->check('not_blank')->message('k1 is invalid');

    my $vresult = $vc->validate({k1 => ''}, $rule);
    ok(!$vresult->is_valid('k1'));
    is($vresult->message('k1'), 'k1 is invalid');
  }
}

# string constraint
{
  my $vc = Validator::Custom->new;

  {
    my $input = {
      k1 => '',
      k2 => 'abc',
      k3 => 3.1,
      k4 => undef,
      k5 => []
    };
    my $rule = $vc->create_rule;
    $rule->topic('k1')->check('string');
    $rule->topic('k2')->check('string');
    $rule->topic('k3')->check('string');
    $rule->topic('k4')->check('string');
    $rule->topic('k5')->check('string');
    
    my $vresult = $vc->validate($input, $rule);
    ok($vresult->is_valid('k1'));
    ok($vresult->is_valid('k2'));
    ok($vresult->is_valid('k3'));
    ok(!$vresult->is_valid('k4'));
    ok(!$vresult->is_valid('k5'));
  }
}

# call multiple check
{
  my $vc = Validator::Custom->new;
  
  {
    my $rule = $vc->create_rule;
    $rule->topic('k1')
      ->check(['string' => 'k1_string_error'])
      ->check(['not_blank' => 'k1_not_blank_error'])
      ->check([{'length' => {max => 3}} => 'k1_length_error']);
;
    $rule->topic('k2')
      ->check(['int' => 'k2_int_error'])
      ->check([{'greater_than' => 3} => 'k2_greater_than_error']);
    
    my $vresult = $vc->validate({k1 => 'aaaa', k2 => 2}, $rule);
    ok(!$vresult->is_valid('k1'));
    ok(!$vresult->is_valid('k2'));
    my $messages_h = $vresult->messages_to_hash;
    is($messages_h->{k1}, 'k1_length_error');
    is($messages_h->{k2}, 'k2_greater_than_error');
  }
}

# No constraint
{
  my $vc = Validator::Custom->new;
  
  # No constraint - valid
  {
    my $rule = $vc->create_rule;
    my $input = {k1 => 1, k2 => undef};
    $rule->topic('k1');
    $rule->topic('k2');
    my $vresult = $vc->validate($input, $rule);
    ok($vresult->is_ok);
  }
  
  # No constraint - invalid
  {
    my $rule = $vc->create_rule;
    my $input = {k1 => 1};
    $rule->topic('k1');
    $rule->topic('k2');
    my $vresult = $vc->validate($input, $rule);
    ok(!$vresult->is_ok);
  }
}

# call message by each constraint
{
  my $vc = Validator::Custom->new;
  
  # No constraint - valid
  {
    my $rule = $vc->create_rule;
    $rule->topic('k1')
      ->check('not_blank')->message('k1_not_blank_error')
      ->check('int')->message('k1_int_error');
    $rule->topic('k2')
      ->check('int')->message('k2_int_error');
    my $vresult1 = $vc->validate({k1 => '', k2 => 4}, $rule);
    is_deeply(
      $vresult1->messages_to_hash,
      {k1 => 'k1_not_blank_error'}
    );
    my $vresult2 = $vc->validate({k1 => 'aaa', k2 => 'aaa'}, $rule);
    is_deeply(
      $vresult2->messages_to_hash,
      {
        k1 => 'k1_int_error',
        k2 => 'k2_int_error'
      }
    );
  }
}

# message fallback
{
  my $vc = Validator::Custom->new;
  
  # No constraint - valid
  {
    my $rule = $vc->create_rule;
    $rule->topic('k1')
      ->check('not_blank')
      ->check('int')->message('k1_int_not_blank_error');
    my $vresult1 = $vc->validate({k1 => ''}, $rule);
    is_deeply(
      $vresult1->messages_to_hash,
      {k1 => 'k1_int_not_blank_error'}
    );
    my $vresult2 = $vc->validate({k1 => 'aaa'}, $rule);
    is_deeply(
      $vresult2->messages_to_hash,
      {k1 => 'k1_int_not_blank_error'}
    );
  }
}
