use Test::More 'no_plan';

use strict;
use warnings;
use utf8;
use Validator::Custom;
use Validator::Custom::Rule;

# TODO
# run_filter
# run_check
# to_array

my $vc_common = Validator::Custom->new;
$vc_common->add_check(
  Int => sub {
    my ($rule, $key, $params) = @_;
    
    my $value = $params->{$key};
    
    return $value =~ /^\d+$/;
  },
  Num => sub {
    my ($rule, $key, $params) = @_;
    
    my $value = $params->{$key};

    require Scalar::Util;
    return Scalar::Util::looks_like_number($value);
  },
  aaa => sub {
    my ($rule, $key, $params) = @_;
    
    my $value = $params->{$key};

    return $value eq 'aaa';
  },
  bbb => sub {
    my ($rule, $key, $params) = @_;
    
    my $value = $params->{$key};

    return $value eq 'bbb';
  }
);
$vc_common->add_filter(
  C1 => sub {
    my ($rule, $key, $params) = @_;
    
    my $value = $params->{$key};
    
    return {$key => $value * 2};
  }
);

# filter_each
{
  my $vc = $vc_common;
  my $input = {k1 => [1,2]};
  my $rule = $vc->create_rule;
  $rule->topic('k1')->filter_each('C1')->filter_each('C1');

  my $result= $rule->validate($input);
  is_deeply($result->messages, []);
  is_deeply($result->output, {k1 => [4,8]});
}

# check_each
{
  my $vc = Validator::Custom->new;
  my $input = {key1 => ['a', 'a'], key2 => [1, 1]};
  my $rule = $vc->create_rule;
  $rule->topic('key1')
    ->check_each('not_blank')
    ->check_each(sub { !shift->run_check('int') });
  $rule->topic('key2')
    ->check_each('not_blank')
    ->check_each(sub { !shift->run_check('int') });
  
  my $result = $rule->validate($input);
  is_deeply($result->invalid_rule_keys, ['key2']);
}

# check - code reference
{
  my $vc = Validator::Custom->new;
  my $input = { k1 => 1, k2 => 2};
  my $check = sub {
    my ($self, $values) = @_;
    return $values->[0] eq $values->[1];
  };
  
  my $rule = $vc->create_rule;
  $rule->topic(['k1', 'k2'])->name('k1_2')->check($check)->message('error_k1_2');
  my $messages = $rule->validate($input)->messages;
  is_deeply($messages, ['error_k1_2']);
}

# validate exception
{
  my $vc = Validator::Custom->new;

  # validate exception - allow a key
  {
    my $rule = $vc->create_rule;
    my $input = {key1 => 'a'};
    $rule->topic('key1')->check('not_blank');
    eval { $rule->validate($input) };
    ok(!$@);
  }
  
  # validate exception - allow a key and name
  {
    my $rule = $vc->create_rule;
    my $input = {key1 => 'a'};
    $rule->topic('key1')->name('k2')->check('not_blank');
    eval { $rule->validate($input) };
    ok(!$@);
  }
  
  # validate exception - allow multiple keys and name
  {
    my $rule = $vc->create_rule;
    my $input = {key1 => 'a', key2 => 'b'};
    $rule->topic(['key1', 'key2'])->name('key12')->check('not_blank');
    eval { $rule->validate($input) };
    ok(!$@);  
  }
  
  # validate exception - deny only multiple keys
  {
    my $rule = $vc->create_rule;
    my $input = {key1 => 'a', key2 => 'b'};
    $rule->topic(['key1', 'key2'])->check('not_blank');
    eval { $rule->validate($input) };
    like($@, qr/name is needed for multiple topic values/);
  }
}

# topic exception
{
  my $vc = Validator::Custom->new;
  
  # topic exception - allow a string;
  {
    my $rule = $vc->create_rule;
    eval { $rule->topic('key1') };
    ok(!$@);
  }
  
  # topic exception - allow array refernce
  {
    my $rule = $vc->create_rule;
    eval { $rule->topic(['key1', 'key2']) };
    ok(!$@);
  }
  
  # topic exception - deny undef
  {
    my $rule = $vc->create_rule;
    eval { $rule->topic(undef) };
    like($@, qr/topic must be a string or array reference/);
  }
  
  # topic exception - deny hash refernce
  {
    my $rule = $vc->create_rule;
    eval { $rule->topic({}) };
    like($@, qr/topic must be a string or array reference/);
  }
}

# Cuastom validator
{
  my $vc = $vc_common;
  my $input = {k1 => 1, k2 => 'a', k3 => 3.1, k4 => 'a'};
  my $rule = $vc->create_rule;
  $rule->topic('k1')->check('Int')->message("k1Error1");
  $rule->topic('k2')->check('Int')->message("k2Error1");
  $rule->topic('k3')->check('Num')->message("k3Error1");
  $rule->topic('k4')->check('Num')->message("k4Error1");
  my $result= $rule->validate($input);
  is_deeply($result->messages, [qw/k2Error1 k4Error1/]);
  is_deeply($result->invalid_rule_keys, [qw/k2 k4/]);
  ok(!$result->is_ok);
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

  my $result = $rule->validate($input);
  is_deeply($result->invalid_rule_keys, ['k3', 'k4']);
}



# to_array_remove_blank filter
{
  my $vc = Validator::Custom->new;
  my $input = {key1 => 1, key2 => [1, 2], key3 => '', key4 => [1, 3, '', '']};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->filter('to_array_remove_blank');
  $rule->topic('key2')->filter('to_array_remove_blank');
  $rule->topic('key3')->filter('to_array_remove_blank');
  $rule->topic('key4')->filter('to_array_remove_blank');
  
  my $vresult = $rule->validate($input);
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

  my $vresult= $rule->validate($input)->output;

  is_deeply($vresult, {k1 => '123'});
}

# array validation new syntax
{
  my $vc = Validator::Custom->new;
  my $rule = $vc->create_rule;
  my $input = { k1 => 1, k2 => [1,2], k3 => [1,'a', 'b'], k4 => 'a', k5 => []};
  $rule->topic('k1')->filter('to_array')->check(selected_at_least => 1)->check_each('int')->message('k1Error1');
  $rule->topic('k2')->filter('to_array')->check(selected_at_least => 1)->check_each('int')->message('k2Error1');
  $rule->topic('k3')->filter('to_array')->check(selected_at_least => 1)->check_each('int')->message('k3Error1');
  $rule->topic('k4')->filter('to_array')->check(selected_at_least => 1)->check_each('int')->message('k4Error1');
  $rule->topic('k5')->filter('to_array')->check(selected_at_least => 1)->check_each('int')->message('k5Error1');
  
  my $messages = $rule->validate($input)->messages;

  is_deeply($messages, [qw/k3Error1 k4Error1 k5Error1/]);
}

{
  my $vc = Validator::Custom->new;
  my $input = {k1 => 1, k2 => 2, k3 => 3};
  my $rule = $vc->create_rule;
  $rule->topic('k1')
    ->check(sub{$_[1] == 1})->message("k1Error1")
    ->check(sub{$_[1] == 2})->message("k1Error2")
    ->check(sub{$_[1] == 3})->message("k1Error3");
  $rule->topic('k2')
    ->check(sub{$_[1] == 2})->message("k2Error1")
    ->check(sub{$_[1] == 3})->message("k2Error2");

  my $vresult   = $rule->validate($input);
  
  my $messages      = $vresult->messages;
  my $messages_hash = $vresult->messages_to_hash;
  
  is_deeply($messages, [qw/k1Error2 k2Error2/]);
  is_deeply($messages_hash, {k1 => 'k1Error2', k2 => 'k2Error2'});
  
  my $messages_hash2 = $vresult->messages_to_hash;
  is_deeply($messages_hash2, {k1 => 'k1Error2', k2 => 'k2Error2'});
  
  $messages = $rule->validate($input)->messages;
  is_deeply($messages, [qw/k1Error2 k2Error2/]);
}

{
  ok(!Validator::Custom->new->rule);
}

{
  my $result = Validator::Custom::Result->new;
  $result->output({k => 1});
  is_deeply($result->output, {k => 1});
}

{
  my $vc = $vc_common;
  my $input = { k1 => 1, k2 => 'a', k3 => 3.1, k4 => 'a' };
  my $rule = $vc->create_rule;
  $rule->topic('k1')->check('Int')->message("k1Error1");
  $rule->topic('k2')->check('Int')->message("k2Error1");
  $rule->topic('k3')->check('Num')->message("k3Error1");
  $rule->topic('k4')->check('Num')->message("k4Error1");
  
  my $messages = $rule->validate($input)->messages;
  is_deeply($messages, [qw/k2Error1 k4Error1/]);
  
  $messages = $rule->validate($input)->messages;
  is_deeply($messages, [qw/k2Error1 k4Error1/]);
}

# Check function not found
{
  my $vc = Validator::Custom->new;
  my $input = {k1 => 1};
  my $rule = $vc->create_rule;
  $rule->topic('k1')->check('No')->message("k1Error1");
  eval { $rule->validate($input) };
  like($@, qr/Can't find "No" check/);
}

# Filter function not found
{
  my $vc = Validator::Custom->new;
  my $input = {k1 => 1};
  my $rule = $vc->create_rule;
  $rule->topic('k1')->filter('No')->message("k1Error1");
  eval { $rule->validate($input) };
  like($@, qr/Can't find "No" filter/);
}

{
  my $vc = $vc_common;
  my $input = { k1 => 1};
  my $rule = $vc->create_rule;
  $rule->topic('k1')->check('Int')->message("k1Error1");
  my $messages = $rule->validate($input)->messages;
  is(scalar @$messages, 0);
}

{
  my $vc = Validator::Custom->new;
  my $rule = $vc->create_rule;
  eval{$rule->validate([])};
  like($@, qr/Input must be hash reference/);
}

{
  eval{Validator::Custom->new->rule({})->validate({})};
  like($@, qr/Invalid rule structure/sm);
}

{
  eval{Validator::Custom->new->rule([key => 'Int'])->validate({})};
  like($@, qr/Invalid rule structure/sm);
}

{
  my $vc = Validator::Custom->new;
  $vc->add_check(
    length => sub {
      my ($rule, $key, $params, $args) = @_;
      
      my $value = $params->{$key};
      
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
  $rule->topic('name')->check(length => [1, 2]);
  
  my $vresult = $rule->validate($input);
  my $invalid_rule_keys = $vresult->invalid_rule_keys;
  is_deeply($invalid_rule_keys, ['name']);
  
  my $messages_hash = $vresult->messages_to_hash;
  is_deeply($messages_hash, {name => 'name is invalid'});
  
  is($vresult->message('name'), 'name is invalid');
  
  $invalid_rule_keys = $rule->validate($input)->invalid_rule_keys;
  is_deeply($invalid_rule_keys, ['name']);
}

{
  my $vc = Validator::Custom->new;
  my $rule = $vc->create_rule;
  my $result = $rule->validate({key => 1});
  ok($result->is_ok);
}

{
  my $vc = Validator::Custom->new;
  $vc->add_check(
   'C1' => sub {
      my ($rule, $key, $params) = @_;
      
      my $value = $params->{$key};
      
      return $value > 1 ? 1 : 0;
    },
   'C2' => sub {
      my ($rule, $key, $params) = @_;
      
      my $value = $params->{$key};
      
      return $value > 5 ? 1 : 0;
    }
  );
  
  my $input = {k1_1 => 1, k1_2 => 2, k2_1 => 5, k2_2 => 6};
  
  my $rule = $vc->create_rule;
  $rule->topic('k1_1')->check('C1');
  $rule->topic('k1_2')->check('C1');
  $rule->topic('k2_1')->check('C2');
  $rule->topic('k2_2')->check('C2');
  
  is_deeply($rule->validate($input)->invalid_rule_keys, [qw/k1_1 k2_1/]);
}

# Validator::Custom::Result raw_invalid_rule_keys'
{
  my $vc = Validator::Custom->new;
  $vc->add_check(p => sub {
    my ($rule, $key, $params) = @_;
    
    my $values = $params->{$key};
    
    return $values->[0] eq $values->[1];
  });
  $vc->add_check(q => sub {
    my ($rule, $key, $params) = @_;
    
    my $value = $params->{$key};
    
    return $value eq 1;
  });
  
  my $input = {k1 => 1, k2 => 2, k3 => 3, k4 => 1};
  my $rule = $vc->create_rule;
  $rule->topic(['k1', 'k2'])->name('k12')->check('p');
  $rule->topic('k3')->check('q');
  $rule->topic('k4')->check('q');
  my $vresult = $rule->validate($input);

  is_deeply($vresult->invalid_rule_keys, ['k12', 'k3']);
}

# check default;

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

  my $result = $rule->validate($input);
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

  my $result = $rule->validate($input);
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

  my $result = $rule->validate($input);
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

  my $result = $rule->validate($input);
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

  my $result = $rule->validate($input);
  is_deeply($result->invalid_rule_keys, ['k2', 'k3']);
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

  my $result = $rule->validate($input);
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

  my $result = $rule->validate($input);
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
    ->check('length' => [3, 4])
    ->check('length' => [2, 3])
    ->check('length' => [3])
    ->check('length' => 3);
  $rule->topic('k2')->check('length' => [4, 5]);

  my $result = $rule->validate($input);
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

  my $result = $rule->validate($input);
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
  $rule->topic('k1')->check('regex' => "a{3}");
  $rule->topic('k2')->check('regex' => "a{4}");

  my $result = $rule->validate($input);
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

  my $result = $rule->validate($input);
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
  $rule->topic('k1')->check(selected_at_least => 1);
  $rule->topic('k2')->check(selected_at_least => 1);
  $rule->topic('k3')->check(selected_at_least => 2);
  $rule->topic('k4')->check('selected_at_least');
  $rule->topic('k5')->check('selected_at_least' => 3);

  my $result = $rule->validate($input);
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
  $rule->topic('k1')->check('greater_than' => 5);
  $rule->topic('k2')->check('greater_than' => 4);
  $rule->topic('k3')->check('greater_than' => 1);

  my $result = $rule->validate($input);
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
  $rule->topic('k1')->check('less_than' => 5);
  $rule->topic('k2')->check('less_than' => 6);
  $rule->topic('k3')->check('less_than' => 1);

  my $result = $rule->validate($input);
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
  $rule->topic('k1')->check('equal_to' => 5);
  $rule->topic('k2')->check('equal_to' => 4);
  $rule->topic('k3')->check('equal_to' => 1);

  my $result = $rule->validate($input);
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
  $rule->topic('k1')->check('between' => [5, 6]);
  $rule->topic('k2')->check('between' => [4, 5]);
  $rule->topic('k3')->check('between' => [6, 7]);
  $rule->topic('k4')->check('between' => [5, 5]);
  $rule->topic('k5')->check('between' => [5, 5]);

  my $result = $rule->validate($input);
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
  $rule->topic('k1')->check('decimal' => [2,3]);
  $rule->topic('k2')->check('decimal' => [1,3]);
  $rule->topic('k3')->check('decimal' => [2,2]);
  $rule->topic('k4')->check('decimal' => [2]);
  $rule->topic('k5')->check('decimal' => 2);
  $rule->topic('k6')->check('decimal' => 2);
  $rule->topic('k7')->check('decimal');
  $rule->topic('k8')->check('decimal');
  $rule->topic('k9')->check('decimal');
  $rule->topic('k10')->check('decimal' => [undef, 2]);
  $rule->topic('k11')->check('decimal' => [undef, 2]);
  $rule->topic('k12')->check('decimal' => [2, undef]);
  $rule->topic('k13')->check('decimal' => [2, undef]);

  my $result = $rule->validate($input);
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
  $rule->topic('k1')->check('in_array' => [qw/a b/]);
  $rule->topic('k2')->check('in_array' => [qw/b c/]);
  $rule->topic('k3')->check('in_array' => [qw/b c/]);

  my $result = $rule->validate($input);
  is_deeply($result->invalid_rule_keys, ['k2', 'k3']);
}

# first
{
  my $vc = Validator::Custom->new;
  my $input = {
    k1 => [1, 2]
  };
  my $rule = $vc->create_rule;
  $rule->topic('k1')->filter('first');

  my $result = $rule->validate($input);
  is_deeply($result->output, {k1 => 1});
}

# first
{
  my $vc = Validator::Custom->new;
  my $input = {
    k1 => 1
  };
  my $rule = $vc->create_rule;
  $rule->topic('k1')->filter('first');

  my $result = $rule->validate($input);
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
    eval { $rule->validate($input) };
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
    eval { $rule->validate($input) };
    like($@, qr/\QConstraint 'greater_than' needs a numeric argument/);
  }

  # exception - greater_than not number
  {
    my $vc = Validator::Custom->new;
    my $input = {
      k1 => 1
    };
    my $rule = $vc->create_rule;
    $rule->topic('k1')->check('greater_than' => 'a');
    eval { $rule->validate($input) };
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
    eval { $rule->validate($input) };
    like($@, qr/\QConstraint 'less_than' needs a numeric argument/);
  }

  # exception - less_than not number
  {
    my $vc = Validator::Custom->new;
    my $input = {
      k1 => 1
    };
    my $rule = $vc->create_rule;
    $rule->topic('k1')->check('less_than' => 'a');
    eval { $rule->validate($input) };
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
    eval { $rule->validate($input) };
    like($@, qr/\QConstraint 'equal_to' needs a numeric argument/);
  }

  # exception - equal_to not number
  {
    my $vc = Validator::Custom->new;
    my $input = {
      k1 => 1
    };
    my $rule = $vc->create_rule;
    $rule->topic('k1')->check('equal_to' => 'a');
    eval { $rule->validate($input) };
    like($@, qr/\QConstraint 'equal_to' needs a numeric argument/);
  }

  # exception - between undef
  {
    my $vc = Validator::Custom->new;
    my $input = {
      k1 => 1
    };
    my $rule = $vc->create_rule;
    $rule->topic('k1')->check('between' => [undef, 1]);
    eval { $rule->validate($input) };
    like($@, qr/\QConstraint 'between' needs two numeric arguments/);
  }

  # exception - between target undef or not number1
  {
    my $vc = Validator::Custom->new;
    my $input = {
      k1 => 1
    };
    my $rule = $vc->create_rule;
    $rule->topic('k1')->check('between' => ['a', 1]);
    eval { $rule->validate($input) };
    like($@, qr/\QConstraint 'between' needs two numeric arguments/);
  }

  # exception - between target undef or not number2
  {
    my $vc = Validator::Custom->new;
    my $input = {
      k1 => 1
    };
    my $rule = $vc->create_rule;
    $rule->topic('k1')->check('between' => [1, undef]);
    eval { $rule->validate($input) };
    like($@, qr/\QConstraint 'between' needs two numeric arguments/);
  }

  # exception - between target undef or not number3
  {
    my $vc = Validator::Custom->new;
    my $input = {
      k1 => 1
    };
    my $rule = $vc->create_rule;
    $rule->topic('k1')->check('between' => [1, 'a']);
    eval { $rule->validate($input) };
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

  my $result_data= $rule->validate($input)->output;

  is_deeply(
    $result_data, 
    { int_param => '123', left => "abc  ", right => '  def', collapse => "a b c"},
  );
}

# duplication result value
{
  my $vc = Validator::Custom->new;
  my $input = {key1 => 'a', key2 => 'a'};
  my $rule = $vc->create_rule;
  $rule->topic(['key1', 'key2'])->name('key3')->check('duplication');
  
  my $result = $rule->validate($input);
  is_deeply($result->output, {key1 => 'a', 'key2' => 'a'});
}

# message option
{
  my $vc = Validator::Custom->new;
  my $input = {key1 => 'a'};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check('int')->message('error');

  my $result = $rule->validate($input);
  is($result->message('key1'), 'error');
}

# is_valid
{
  my $vc = Validator::Custom->new;
  my $input = {key1 => 'a', key2 => 'b', key3 => 2};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check('int');
  $rule->topic('key2')->check('int');
  $rule->topic('key3')->check('int');

  my $result = $rule->validate($input);
  ok(!$result->is_valid('key1'));
  ok(!$result->is_valid('key2'));
  ok($result->is_valid('key3'));
}

# merge
{
  my $vc = Validator::Custom->new;
  my $input = {key1 => 'a', key2 => 'b', key3 => 'c'};
  my $rule = $vc->create_rule;
  $rule->topic( ['key1', 'key2', 'key3'])->name('key123')->filter('merge' => ['key']);
  
  my $result = $rule->validate($input);
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

  my $result = $rule->validate($input);
  is_deeply($result->invalid_rule_keys, ['key3']);
}

# to_array filter
{
  my $vc = Validator::Custom->new;
  my $input = {key1 => 1, key2 => [1, 2]};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->filter('to_array');
  $rule->topic('key2')->filter('to_array');

  my $result = $rule->validate($input);
  is_deeply($result->output->{key1}, [1]);
  is_deeply($result->output->{key2}, [1, 2]);
}

# undefined value
{
  my $vc = Validator::Custom->new;
  my $input = {key1 => undef, key2 => '', key3 => 'a'};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check('ascii');
  $rule->topic('key2')->check('ascii');
  $rule->topic('key3')->check('ascii');

  my $result = $rule->validate($input);
  ok(!$result->is_valid('key1'));
  ok(!$result->is_valid('key2'));
  ok($result->is_valid('key3'));
}

{
  my $vc = $vc_common;
  my $input = {key1 => undef, key2 => '', key3 => '2'};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check(between => [1, 3]);
  $rule->topic('key2')->check(between => [1, 3]);
  $rule->topic('key3')->check(between => [1, 3]);

  my $result = $rule->validate($input);
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

  my $result = $rule->validate($input);
  ok(!$result->is_valid('key1'));
  ok($result->is_valid('key2'));
}

{
  my $vc = $vc_common;
  my $input = {key1 => undef, key2 => '', key3 => '2.1'};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check(decimal => 1);
  $rule->topic('key2')->check(decimal => 1);
  $rule->topic('key3')->check(decimal => [1, 1]);

  my $result = $rule->validate($input);
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

  my $result = $rule->validate($input);
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
  $rule->topic('key1')->check(equal_to => 1);
  $rule->topic('key2')->check(equal_to => 1);
  $rule->topic('key3')->check(equal_to => 1);

  my $result = $rule->validate($input);
  ok(!$result->is_valid('key1'));
  ok(!$result->is_valid('key2'));
  ok($result->is_valid('key3'));
}

{
  my $vc = $vc_common;
  my $input = {key1 => undef, key2 => '', key3 => '5'};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check(greater_than => 1);
  $rule->topic('key2')->check(greater_than => 1);
  $rule->topic('key3')->check(greater_than => 1);

  my $result = $rule->validate($input);
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

  my $result = $rule->validate($input);
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

  my $result = $rule->validate($input);
  ok(!$result->is_valid('key1'));
  ok(!$result->is_valid('key2'));
  ok($result->is_valid('key3'));
}

{
  my $vc = $vc_common;
  my $input = {key1 => undef, key2 => '', key3 => '1'};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check('in_array' => [1, 2]);
  $rule->topic('key2')->check('in_array' => [1, 2]);
  $rule->topic('key3')->check('in_array' => [1, 2]);

  my $result = $rule->validate($input);
  ok(!$result->is_valid('key1'));
  ok(!$result->is_valid('key2'));
  ok($result->is_valid('key3'));
}

{
  my $vc = $vc_common;
  my $input = {key1 => undef, key2 => '', key3 => 'aaa'};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check('length' => [1, 4]);
  $rule->topic('key2')->check('length' => [1, 4]);
  $rule->topic('key3')->check('length' => [1, 4]);

  my $result = $rule->validate($input);
  ok(!$result->is_valid('key1'));
  ok(!$result->is_valid('key2'));
  ok($result->is_valid('key3'));
}

{
  my $vc = $vc_common;
  my $input = {key1 => undef, key2 => '', key3 => 3};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check('less_than' => 4);
  $rule->topic('key2')->check('less_than' => 4);
  $rule->topic('key3')->check('less_than' => 4);

  my $result = $rule->validate($input);
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

  my $result = $rule->validate($input);
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

  my $result = $rule->validate($input);
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

  my $result = $rule->validate($input);
  ok(!$result->is_valid('key1'));
  ok(!$result->is_valid('key2'));
  ok($result->is_valid('key3'));
}

{
  my $vc = $vc_common;
  my $input = {key1 => undef, key2 => '', key3 => 3};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check('regex' => qr/3/);
  $rule->topic('key2')->check('regex' => qr/3/);
  $rule->topic('key3')->check('regex' => qr/3/);

  my $result = $rule->validate($input);
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

  my $result = $rule->validate($input);
  ok(!$result->is_valid('key1'));
  ok($result->is_valid('key2'));
  ok($result->is_valid('key3'));
}

{
  my $vc = $vc_common;
  my $input = {key2 => 2};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check('defined')->message('key1 is undefined');

  my $result = $rule->validate($input);
  is_deeply($result->messages, ['key1 is undefined']);
  ok(!$result->is_valid('key1'));
}

# between 0-9
{
  my $vc = $vc_common;
  my $input = {key1 => 0, key2 => 9};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check(between => [0, 9]);
  $rule->topic('key2')->check(between => [0, 9]);

  my $result = $rule->validate($input);
  ok($result->is_ok);
}

# between decimal
{
  my $vc = $vc_common;
  my $input = {key1 => '-1.5', key2 => '+1.5', key3 => 3.5};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check(between => [-2.5, 1.9]);
  $rule->topic('key2')->check(between => ['-2.5', '+1.9']);
  $rule->topic('key3')->check(between => ['-2.5', '+1.9']);

  my $result = $rule->validate($input);
  ok($result->is_valid('key1'));
  ok($result->is_valid('key2'));
  ok(!$result->is_valid('key3'));
}

# equal_to decimal
{
  my $vc = $vc_common;
  my $input = {key1 => '+0.9'};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check(equal_to => '0.9');

  my $result = $rule->validate($input);
  ok($result->is_valid('key1'));
}

# greater_than decimal
{
  my $vc = $vc_common;
  my $input = {key1 => '+10.9'};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check(greater_than => '9.1');
  my $result = $rule->validate($input);
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

  my $result = $rule->validate($input);
  ok($result->is_valid('key1'));
  ok($result->is_valid('key2'));
  ok(!$result->is_valid('key3'));
}

# less_than decimal
{
  my $vc = $vc_common;
  my $input = {key1 => '+0.9'};
  my $rule = $vc->create_rule;
  $rule->topic('key1')->check(less_than => '10.1');

  my $result = $rule->validate($input);
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

  my $result = $rule->validate($input);
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

  my $result = $rule->validate($input);
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

  my $result = $rule->validate($input);
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

  my $result = $rule->validate($input);
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
  $rule->topic('key1_1')->check('length' => {min => 2, max => 4});
  $rule->topic('key1_2')->check('length' => {min => 2, max => 4});
  $rule->topic('key1_3')->check('length' => {min => 2, max => 4});
  $rule->topic('key1_4')->check('length' => {min => 2, max => 4});
  $rule->topic('key1_5')->check('length' => {min => 2, max => 4});
  $rule->topic('key2_1')->check('length' => {min => 2});
  $rule->topic('key2_2')->check('length' => {min => 2});
  $rule->topic('key2_3')->check('length' => {min => 2});
  $rule->topic('key3_1')->check('length' => {max => 4});
  $rule->topic('key3_2')->check('length' => {max => 4});
  $rule->topic('key3_3')->check('length' => {max => 4});
  
  my $result = $rule->validate($input);
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
  $rule->topic('int_param')->filter('trim_uni');
  $rule->topic('collapse')->filter('trim_uni_collapse');
  $rule->topic('left')->filter('trim_uni_lead');
  $rule->topic('right')->filter('trim_uni_trail');

  my $result_data= $rule->validate($input)->output;

  is_deeply(
    $result_data, 
    { int_param => '123', left => "abc　　", right => '　　def', collapse => "a b c"},
  );
}

# Custom error message
{
  my $vc = Validator::Custom->new;
  $vc->add_check(
    c1 => sub {
      my ($rule, $key, $params) = @_;
      
      my $value = $params->{$key};
      
      if ($value eq 'a') {
        return 1;
      }
      else {
        return {message => 'error1'};
      }
    },
    c2 => sub {
      my ($rule, $key, $params) = @_;
      
      my $value = $params->{$key};
      
      if ($value eq 'a') {
        return 1;
      }
      else {
        return {message => 'error2'};
      }
    }
  );
  my $rule = $vc->create_rule;
  $rule->topic('k1')->check('c1');
  $rule->topic('k2')->check_each('c2');
  my $vresult = $rule->validate({k1 => 'a', k2 => ['a']});
  ok($vresult->is_ok);
  $vresult = $rule->validate({k1 => 'b', k2 => ['b']});
  ok(!$vresult->is_ok);
  is_deeply($vresult->messages, ['error1', 'error2']);
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
    $rule->topic('k4')->optional->check('not_blank')->fallback(5);
    my $vresult = $rule->validate({k1 => 'aaa', k2 => '', k3 => '', k4 => ''});
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

    my $vresult = $rule->validate({k1 => ''});
    ok(!$vresult->is_valid('k1'));
    is($vresult->message('k1'), 'k1 is invalid');
  }
}

# string check
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
    
    my $vresult = $rule->validate($input);
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
      ->check('string')->message('k1_string_error')
      ->check('not_blank')->message('k1_not_blank_error')
      ->check('length' => {max => 3})->message('k1_length_error');
    
    $rule->topic('k2')
      ->check('int')->message('k2_int_error')
      ->check('greater_than' => 3)->message('k2_greater_than_error');
    
    my $vresult = $rule->validate({k1 => 'aaaa', k2 => 2});
    ok(!$vresult->is_valid('k1'));
    ok(!$vresult->is_valid('k2'));
    my $messages_h = $vresult->messages_to_hash;
    is($messages_h->{k1}, 'k1_length_error');
    is($messages_h->{k2}, 'k2_greater_than_error');
  }
}

# No check
{
  my $vc = Validator::Custom->new;
  
  # No check - valid
  {
    my $rule = $vc->create_rule;
    my $input = {k1 => 1, k2 => undef};
    $rule->topic('k1');
    $rule->topic('k2');
    my $vresult = $rule->validate($input);
    ok($vresult->is_ok);
  }
  
  # No check - invalid
  {
    my $input = {k1 => 1};
    my $rule = $vc->create_rule;
    $rule->topic('k1');
    $rule->topic('k2');
    my $vresult = $rule->validate($input);
    ok($vresult->is_ok);
  }
}

# call message by each check
{
  my $vc = Validator::Custom->new;
  
  # No check - valid
  {
    my $rule = $vc->create_rule;
    $rule->topic('k1')
      ->check('not_blank')->message('k1_not_blank_error')
      ->check('int')->message('k1_int_error');
    $rule->topic('k2')
      ->check('int')->message('k2_int_error');
    my $vresult1 = $rule->validate({k1 => '', k2 => 4});
    is_deeply(
      $vresult1->messages_to_hash,
      {k1 => 'k1_not_blank_error'}
    );
    my $vresult2 = $rule->validate({k1 => 'aaa', k2 => 'aaa'});
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
  
  # No check - valid
  {
    my $rule = $vc->create_rule;
    $rule->topic('k1')
      ->check('not_blank')
      ->check('int')->message('k1_int_not_blank_error');
    my $vresult1 = $rule->validate({k1 => ''});
    is_deeply(
      $vresult1->messages_to_hash,
      {k1 => 'k1_int_not_blank_error'}
    );
    my $vresult2 = $rule->validate({k1 => 'aaa'});
    is_deeply(
      $vresult2->messages_to_hash,
      {k1 => 'k1_int_not_blank_error'}
    );
  }
}

{
  my $vc = Validator::Custom->new;
  $vc->add_check(
    Int => sub{
      my ($rule, $key, $params) = @_;
      
      my $value = $params->{$key};
      
      return $value =~ /^\d+$/;
    }
  );
  my $input = { k1 => 1, k2 => [1,2], k3 => [1,'a', 'b'], k4 => 'a'};
  my $rule = $vc->create_rule;
  $rule->topic('k1')->filter('to_array')->check_each('Int')->message("k1Error1");
  $rule->topic('k2')->check_each('Int')->message("k2Error1");
  $rule->topic('k3')->check_each('Int')->message("k3Error1");
  $rule->topic('k4')->filter('to_array')->check_each('Int')->message("k4Error1");

  my $messages = $rule->validate($input)->messages;

  is_deeply($messages, [qw/k3Error1 k4Error1/]);
}

# fallback
{
  # fallback - undef
  {
    my $vc = Validator::Custom->new;
    my $input = {};
    my $rule = $vc->create_rule;
    $rule->topic('key1')->check('int')->fallback(2);

    my $result = $rule->validate($input);
    ok($result->is_ok);
    is_deeply($result->output, {key1 => 2});
  }
  
  # fallback - invalid
  {
    my $vc = Validator::Custom->new;
    my $input = {key1 => 'a'};
    my $rule = $vc->create_rule;
    $rule->topic('key1')->check('int')->fallback(2);
    $rule->topic('key2')->check('int');
    
    my $result = $rule->validate($input);
    ok(!$result->is_ok);
    is_deeply($result->invalid_rule_keys, ['key2']);
    is($result->output, {key1 => 2});
  }

  {
    my $vc = Validator::Custom->new;
    my $input = {key1 => 'a', key3 => 'b'};
    my $rule = $vc->create_rule;
    $rule->topic('key1')->check('int')->fallback(sub { return $_[1] });
    $rule->topic('key2')->check('int')->fallback(sub { return 5 });
    $rule->topic('key3')->check('int')->fallback(undef);
    
    my $result = $rule->validate($input);
    is($result->output->{key1}, $vc);
    is($result->output->{key2}, 5);
    ok(exists $result->output->{key3} && !defined $result->output->{key3});
  }
}
