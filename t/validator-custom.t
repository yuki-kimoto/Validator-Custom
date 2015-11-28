use Test::More 'no_plan';

use strict;
use warnings;
use utf8;
use Validator::Custom;

# create new validation object
{
  my $vc = Validator::Custom->new;
  my $validation1 = $vc->validation;
  my $validation2 = $vc->validation;
  is(ref $validation1, 'Validator::Custom::Validation');
  is(ref $validation2, 'Validator::Custom::Validation');
  isnt($validation1, $validation2);
}

# not defined
{
  my $vc = Validator::Custom->new;
  my $k1;
  my $k2 = 'a';
  my $validation = $vc->validation;
  if (defined $k1) {
      $validation->add_failed('k1');
  }
  if (defined $k2) {
      $validation->add_failed('k2');
  }
  is_deeply($validation->failed, ['k2']);
}

# defined
{
  my $vc = Validator::Custom->new;
  my $k1 = undef;
  my $k2 = 'a';
    
  my $validation = $vc->validation;
  if (!defined $k1) {
      $validation->add_failed('k1');
  }
  if (!defined $k2) {
      $validation->add_failed('k2');
  }
  is_deeply($validation->failed, ['k1']);
}

# not blank
{
  my $vc = Validator::Custom->new;
  my $k1 = '';
  my $k2 = 'a';
  my $k3 = ' ';
    
  my $validation = $vc->validation;
  if (!length $k1) {
      $validation->add_failed('k1');
  }
  if (!length $k2) {
      $validation->add_failed('k2');
  }
  if (!length $k3) {
      $validation->add_failed('k3');
  }
  is_deeply($validation->failed, ['k1']);
}

# blank
{
  my $vc = Validator::Custom->new;
  my $k1 = '';
  my $k2 = 'a';
  my $k3 = ' ';
    
  my $validation = $vc->validation;
  if (!$vc->check('blank', $k1)) {
      $validation->add_failed('k1');
  }
  if (!$vc->check('blank', $k2)) {
      $validation->add_failed('k2');
  }
  if (!$vc->check('blank', $k3)) {
      $validation->add_failed('k3');
  }
  is_deeply($validation->failed, ['k2', 'k3']);
}

# uint
{
  my $vc = Validator::Custom->new;
  my $k1 = '19';
  my $k2 = '-10';
  my $k3 = 'a';
  my $k4 =  '10.0';
    
  my $validation = $vc->validation;
  if (!$vc->check('uint', $k1)) {
      $validation->add_failed('k1');
  }
  if (!$vc->check('uint', $k2)) {
    $validation->add_failed('k2');
  }
  if (!$vc->check('uint', $k3)) {
    $validation->add_failed('k3');
  }
  if (!$vc->check('uint', $k4)) {
    $validation->add_failed('k4');
  }

  is_deeply($validation->failed, ['k2', 'k3', 'k4']);
}

# ascii
{
  my $vc = Validator::Custom->new;
  my $k1 = '!~';
  my $k2 = ' ';
  my $k3 = "\0x7f";
    
  my $validation = $vc->validation;
  if (!$vc->check('ascii', $k1)) {
    $validation->add_failed('k1');
  }
  if (!$vc->check('ascii', $k2)) {
    $validation->add_failed('k2');
  }
  if (!$vc->check('ascii', $k3)) {
    $validation->add_failed('k3');
  }
  
  is_deeply($validation->failed, ['k2', 'k3']);
}

__END__

# length
{
  my $vc = Validator::Custom->new;
  my $k1 = '111';
  my $k2 = '111';
    
  my $validation = $vc->validation;
    $validation->add_failed('k1')
    $vc->check('length' => [3, 4])
    $vc->check('length' => [2, 3])
    $vc->check('length' => [3])
    $vc->check('length' => 3);
    $validation->add_failed('k2')$vc->check('length' => [4, 5]);

  is_deeply($validation->failed, ['k2']);
}

# duplication
{
  my $vc = Validator::Custom->new;
    k1_1 => 'a';
    k1_2 => 'a';
    
    k2_1 => 'a';
    k2_2 => 'b';
    
  my $validation = $vc->validation;
    $validation->add_failed([qw/k1_1 k1_2/])$vc->check('duplication')->name('k1');
    $validation->add_failed([qw/k2_1 k2_2/])$vc->check('duplication')->name('k2');

  is_deeply($validation->failed, ['k2']);
}

# regex
{
  my $vc = Validator::Custom->new;
  my $k1 = 'aaa';
  my $k2 = 'aa';
    
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check('regex' => "a{3}");
    $validation->add_failed('k2')$vc->check('regex' => "a{4}");

  is_deeply($validation->failed, ['k2']);
}

# http_url
{
  my $vc = Validator::Custom->new;
  my $k1 = 'http://www.lost-season.jp/mt/';
  my $k2 = 'iii';
    
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check('http_url');
    $validation->add_failed('k2')$vc->check('http_url');

  is_deeply($validation->failed, ['k2']);
}

# greater_than
{
  my $vc = Validator::Custom->new;
  my $k1 = 5;
  my $k2 = 5;
  my $k3 = 'a';
    
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check('greater_than' => 5);
    $validation->add_failed('k2')$vc->check('greater_than' => 4);
    $validation->add_failed('k3')$vc->check('greater_than' => 1);

  is_deeply($validation->failed, ['k1', 'k3']);
}

# less_than
{
  my $vc = Validator::Custom->new;
  my $k1 = 5;
  my $k2 = 5;
  my $k3 = 'a';
    
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check('less_than' => 5);
    $validation->add_failed('k2')$vc->check('less_than' => 6);
    $validation->add_failed('k3')$vc->check('less_than' => 1);

  is_deeply($validation->failed, ['k1', 'k3']);
}

# less_than
{
  my $vc = Validator::Custom->new;
  my $k1 = 5;
  my $k2 = 5;
  my $k3 = 'a';
    
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check('equal_to' => 5);
    $validation->add_failed('k2')$vc->check('equal_to' => 4);
    $validation->add_failed('k3')$vc->check('equal_to' => 1);

  is_deeply($validation->failed, ['k2', 'k3']);
}

# between
{
  my $vc = Validator::Custom->new;
  my $k1 = 5;
  my $k2 = 5;
  my $k3 = 5;
  my $k4 =  5;
  my $k5 = 'a';
    
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check('between' => [5, 6]);
    $validation->add_failed('k2')$vc->check('between' => [4, 5]);
    $validation->add_failed('k3')$vc->check('between' => [6, 7]);
    $validation->add_failed('k4')$vc->check('between' => [5, 5]);
    $validation->add_failed('k5')$vc->check('between' => [5, 5]);

  is_deeply($validation->failed, ['k3', 'k5']);
}

# decimal
{
  my $vc = Validator::Custom->new;
  my $k1 = '12.123';
  my $k2 = '12.123';
  my $k3 = '12.123';
  my $k4 =  '12';
  my $k5 = '123';
    k6 => '123.a';
    k7 => '1234.1234';
    k8 => '';
    k9 => 'a';
    k10 => '1111111.12';
    k11 => '1111111.123';
    k12 => '12.1111111';
    k13 => '123.1111111';
    
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check('decimal' => [2,3]);
    $validation->add_failed('k2')$vc->check('decimal' => [1,3]);
    $validation->add_failed('k3')$vc->check('decimal' => [2,2]);
    $validation->add_failed('k4')$vc->check('decimal' => [2]);
    $validation->add_failed('k5')$vc->check('decimal' => 2);
    $validation->add_failed('k6')$vc->check('decimal' => 2);
    $validation->add_failed('k7')$vc->check('decimal');
    $validation->add_failed('k8')$vc->check('decimal');
    $validation->add_failed('k9')$vc->check('decimal');
    $validation->add_failed('k10')$vc->check('decimal' => [undef, 2]);
    $validation->add_failed('k11')$vc->check('decimal' => [undef, 2]);
    $validation->add_failed('k12')$vc->check('decimal' => [2, undef]);
    $validation->add_failed('k13')$vc->check('decimal' => [2, undef]);

  is_deeply($validation->failed, [qw/k2 k3 k5 k6 k8 k9 k11 k13/]);
}

# in_array
{
  my $vc = Validator::Custom->new;
  my $k1 = 'a';
  my $k2 = 'a';
  my $k3 = undef;
    
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check('in_array' => [qw/a b/]);
    $validation->add_failed('k2')$vc->check('in_array' => [qw/b c/]);
    $validation->add_failed('k3')$vc->check('in_array' => [qw/b c/]);

  is_deeply($validation->failed, ['k2', 'k3']);
}

# first
{
  my $vc = Validator::Custom->new;
  my $k1 = [1, 2];
    
  my $validation = $vc->validation;
    $validation->add_failed('k1')->filter('first');

  is_deeply($validation->output, {k1 => 1});
}

# first
{
  my $vc = Validator::Custom->new;
  my $k1 = 1;
    
  my $validation = $vc->validation;
    $validation->add_failed('k1')->filter('first');

  is_deeply($validation->output, {k1 => 1});
}

__END__

my $vc_common = Validator::Custom->new;
$vc_common->add_check(
  Int => sub {
    my ($validation, $args, $key, $params) = @_;
    
    my $value = $params->{$key};
    
    return $value =~ /^\d+$/;
  },
  Num => sub {
    my ($validation, $args, $key, $params) = @_;
    
    my $value = $params->{$key};

    require Scalar::Util;
    return Scalar::Util::looks_like_number($value);
  },
  aaa => sub {
    my ($validation, $args, $key, $params) = @_;
    
    my $value = $params->{$key};

    return $value eq 'aaa';
  },
  bbb => sub {
    my ($validation, $args, $key, $params) = @_;
    
    my $value = $params->{$key};

    return $value eq 'bbb';
  }
);
$vc_common->add_filter(
  C1 => sub {
    my ($validation, $args, $key, $params) = @_;
    
    my $value = $params->{$key};
    
    return [$key => {$key => $value * 2}];
  }
);

# selected_at_least
{
  my $vc = Validator::Custom->new;
  my $k1 = 1;
  my $k2 = [1];
  my $k3 = [1, 2];
  my $k4 =  [];
  my $k5 = [1,2];
    
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check(selected_at_least => 1);
    $validation->add_failed('k2')$vc->check(selected_at_least => 1);
    $validation->add_failed('k3')$vc->check(selected_at_least => 2);
    $validation->add_failed('k4')$vc->check('selected_at_least');
    $validation->add_failed('k5')$vc->check('selected_at_least' => 3);

  is_deeply($validation->failed, ['k5']);
}

# merge
{
  my $vc = Validator::Custom->new;
  my $k1 = 'a'; my $k2 ='b'; my $k3 ='c';
  my $validation = $vc->validation;
    $validation->add_failed(['k1', 'k2', 'k3'])->name('k123')->filter('merge' => 'key');
  is($validation->output->{key}, 'abc');
}

# check_each
{
  # check_each - basic
  {
    my $vc = Validator::Custom->new;
    my $validation = $vc->validation;
    my $k1 = 1; k2 => [1,2]; k3 => [1,'a', 'b']; k4 => 'a'; k5 => [];
      $validation->add_failed('k1')->filter('to_array')$vc->check(selected_at_least => 1)$vc->check_each('int')->message('k1Error1');
      $validation->add_failed('k2')->filter('to_array')$vc->check(selected_at_least => 1)$vc->check_each('int')->message('k2Error1');
      $validation->add_failed('k3')->filter('to_array')$vc->check(selected_at_least => 1)$vc->check_each('int')->message('k3Error1');
      $validation->add_failed('k4')->filter('to_array')$vc->check(selected_at_least => 1)$vc->check_each('int')->message('k4Error1');
      $validation->add_failed('k5')->filter('to_array')$vc->check(selected_at_least => 1)$vc->check_each('int')->message('k5Error1');
    
    my $messages = $validation->validate($input)->messages;

    is_deeply($messages, [qw/k3Error1 k4Error1 k5Error1/]);
  }

  # check_each - repeat
  {
    my $vc = Validator::Custom->new;
    my $k1 = ['a', 'a']; my $k2 =[1, 1];
    my $validation = $vc->validation;
      $validation->add_failed('k1')
      $vc->check_each('not_blank')
      $vc->check_each(sub {
        my ($validation, $args, $key, $params) = @_;
        
        return !$validation->run_check('int', [], $key, $params);
      });
      $validation->add_failed('k2')
      $vc->check_each('not_blank')
      $vc->check_each(sub {
        my ($validation, $args, $key, $params) = @_;
        
        return !$validation->run_check('int', [], $key, $params);
      });
    
    
    is_deeply($validation->failed, ['k2']);
  }
}

# filter_each
{
  my $vc = $vc_common;
  my $k1 = [1,2];
  my $validation = $vc->validation;
    $validation->add_failed('k1')->filter_each('C1')->filter_each('C1');

  my $validation= $validation->validate($input);
  is_deeply($validation->messages, []);
  is_deeply($validation->output, {k1 => [4,8]});
}

# check - code reference
{
  my $vc = Validator::Custom->new;
  my $k1 = 1; k2 => 2;
  my $check = sub {
    my ($self, $args, $key, $params) = @_;
    
    my $values = $params->{$key};
    
    return defined $values->[0] && defined $values->[1] && $values->[0] eq $values->[1];
    
  my $validation = $vc->validation;
    $validation->add_failed(['k1', 'k2'])->name('k1_2')$vc->check($check)->message('error_k1_2');
  my $messages = $validation->validate($input)->messages;
  is_deeply($messages, ['error_k1_2']);
}

# validate exception
{
  my $vc = Validator::Custom->new;

  # validate exception - allow a key
  {
    my $validation = $vc->validation;
    my $k1 = 'a'};
      $validation->add_failed('k1')$vc->check('not_blank');
    eval { $validation->validate($input) };
    ok(!$@);
  }
  # validate exception - allow a key and name
  {
    my $validation = $vc->validation;
    my $k1 = 'a'};
      $validation->add_failed('k1')->name('k2')$vc->check('not_blank');
    eval { $validation->validate($input) };
    ok(!$@);
  }
  # validate exception - allow multiple keys and name
  {
    my $validation = $vc->validation;
    my $k1 = 'a'; my $k2 ='b';
      $validation->add_failed(['k1', 'k2'])->name('k12')$vc->check('not_blank');
    eval { $validation->validate($input) };
    ok(!$@);  
  }
  # validate exception - deny only multiple keys
  {
    my $validation = $vc->validation;
    my $k1 = 'a'; my $k2 ='b';
      $validation->add_failed(['k1', 'k2'])$vc->check('not_blank');
    eval { $validation->validate($input) };
    like($@, qr/name is needed for multiple topic values/);
  }
}

# topic exception
{
  my $vc = Validator::Custom->new;
  # topic exception - allow a string;
  {
    my $validation = $vc->validation;
    eval { $validation->add_failed('k1') };
    ok(!$@);
  }
  # topic exception - allow array refernce
  {
    my $validation = $vc->validation;
    eval { $validation->add_failed(['k1', 'k2']) };
    ok(!$@);
  }
  # topic exception - deny undef
  {
    my $validation = $vc->validation;
    eval { $validation->add_failed(undef) };
    like($@, qr/topic must be a string or array reference/);
  }
  # topic exception - deny hash refernce
  {
    my $validation = $vc->validation;
    eval { $validation->add_failed({}) };
    like($@, qr/topic must be a string or array reference/);
  }
}

# Cuastom validator
{
  my $vc = $vc_common;
  my $k1 = 1; k2 => 'a'; k3 => 3.1; k4 => 'a';
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check('Int')->message("k1Error1");
    $validation->add_failed('k2')$vc->check('Int')->message("k2Error1");
    $validation->add_failed('k3')$vc->check('Num')->message("k3Error1");
    $validation->add_failed('k4')$vc->check('Num')->message("k4Error1");
  my $validation= $validation->validate($input);
  is_deeply($validation->messages, [qw/k2Error1 k4Error1/]);
  is_deeply($validation->failed, [qw/k2 k4/]);
  ok(!$validation->is_valid);
}

# int
{
  my $vc = Validator::Custom->new;
    k1  => '19';
    k2  => '-10';
  my $k3 = 'a';
  my $k4 =  '10.0';
    
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check('int');
    $validation->add_failed('k2')$vc->check('int');
    $validation->add_failed('k3')$vc->check('int');
    $validation->add_failed('k4')$vc->check('int');

  is_deeply($validation->failed, ['k3', 'k4']);
}

# exists
{
  my $vc = Validator::Custom->new;
    k1  => 1;
    k2  => undef;
    
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check('exists');
    $validation->add_failed('k2')$vc->check('exists');
    $validation->add_failed('k3')$vc->check('exists');

  is_deeply($validation->failed, ['k3']);
}

# remove_blank filter
{
  my $vc = Validator::Custom->new;
  my $k1 = 1; my $k2 =[1, 2]; my $k3 =''; my $key4 = [1, 3, '', ''];
  my $validation = $vc->validation;
    $validation->add_failed('k1')->filter('to_array')->filter('remove_blank');
    $validation->add_failed('k2')->filter('to_array')->filter('remove_blank');
    $validation->add_failed('k3')->filter('to_array')->filter('remove_blank');
    $validation->add_failed('key4')->filter('to_array')->filter('remove_blank');
  my $vresult = $validation->validate($input);
  is_deeply($vresult->output->{k1}, [1]);
  is_deeply($vresult->output->{k2}, [1, 2]);
  is_deeply($vresult->output->{k3}, []);
  is_deeply($vresult->output->{key4}, [1, 3]);
}

# Validator::Custom::Resut filter method
{
  my $vc = Validator::Custom->new;
  my $k1 = ' 123 ';
    
  my $validation = $vc->validation;
    $validation->add_failed('k1')->filter('trim');

  my $vresult= $validation->validate($input)->output;

  is_deeply($vresult, {k1 => '123'});
}

{
  my $vc = Validator::Custom->new;
  my $k1 = 1; k2 => 2; k3 => 3;;
  my $validation = $vc->validation;
    $validation->add_failed('k1')
    $vc->check(sub{
      my ($validation, $args, $key, $params) = @_;
      
      my $value = $params->{$key};
      
      return $value == 1;
    })->message("k1Error1")
    $vc->check(sub {
      my ($validation, $args, $key, $params) = @_;
      
      my $value = $params->{$key};

      return $value == 2;
    })->message("k1Error2")
    $vc->check(sub{
      my ($validation, $args, $key, $params) = @_;
      
      my $value = $params->{$key};

      return $value == 3;
    })->message("k1Error3");
    $validation->add_failed('k2')
    $vc->check(sub{
      my ($validation, $args, $key, $params) = @_;
      
      my $value = $params->{$key};

      return $value == 2;
    })->message("k2Error1")
    $vc->check(sub{
      my ($validation, $args, $key, $params) = @_;
      
      my $value = $params->{$key};

      return $value == 3;
    })->message("k2Error2");

  my $vresult   = $validation->validate($input);
  my $messages      = $vresult->messages;
  my $messages_hash = $vresult->messages_to_hash;
  is_deeply($messages, [qw/k1Error2 k2Error2/]);
  is_deeply($messages_hash, {k1 => 'k1Error2', k2 => 'k2Error2'});
  my $messages_hash2 = $vresult->messages_to_hash;
  is_deeply($messages_hash2, {k1 => 'k1Error2', k2 => 'k2Error2'});
  $messages = $validation->validate($input)->messages;
  is_deeply($messages, [qw/k1Error2 k2Error2/]);
}

{
  ok(!Validator::Custom->new->rule);
}

{
  my $validation = Validator::Custom::Result->new;
    $validation->output({k => 1});
  is_deeply($validation->output, {k => 1});
}

{
  my $vc = $vc_common;
  my $k1 = 1; k2 => 'a'; k3 => 3.1; k4 => 'a';
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check('Int')->message("k1Error1");
    $validation->add_failed('k2')$vc->check('Int')->message("k2Error1");
    $validation->add_failed('k3')$vc->check('Num')->message("k3Error1");
    $validation->add_failed('k4')$vc->check('Num')->message("k4Error1");
  my $messages = $validation->validate($input)->messages;
  is_deeply($messages, [qw/k2Error1 k4Error1/]);
  $messages = $validation->validate($input)->messages;
  is_deeply($messages, [qw/k2Error1 k4Error1/]);
}

# Check function not found
{
  my $vc = Validator::Custom->new;
  my $k1 = 1;
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check('No')->message("k1Error1");
  eval { $validation->validate($input) };
  like($@, qr/Can't find "No" check/);
}

# Filter function not found
{
  my $vc = Validator::Custom->new;
  my $k1 = 1;
  my $validation = $vc->validation;
    $validation->add_failed('k1')->filter('No')->message("k1Error1");
  eval { $validation->validate($input) };
  like($@, qr/Can't find "No" filter/);
}

{
  my $vc = $vc_common;
  my $k1 = 1;
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check('Int')->message("k1Error1");
  my $messages = $validation->validate($input)->messages;
  is(scalar @$messages, 0);
}

{
  my $vc = Validator::Custom->new;
  my $validation = $vc->validation;
  eval{$validation->validate([])};
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
      my ($validation, $args, $key, $params) = @_;
      
      my $value = $params->{$key};
      
      my $min;
      my $max;
      
      ($min, $max) = @{$args->[0]};
      my $length  = length $value;
      return $min <= $length && $length <= $max ? 1 : 0;
    }
  );
    name => 'zz' x 30;
    age => 'zz';
    
  my $validation = $vc->validation;
    $validation->add_failed('name')$vc->check(length => [1, 2]);
  my $vresult = $validation->validate($input);
  my $failed = $vresult->failed;
  is_deeply($failed, ['name']);
  my $messages_hash = $vresult->messages_to_hash;
  is_deeply($messages_hash, {name => 'name is invalid'});
  is($vresult->message('name'), 'name is invalid');
  $failed = $validation->validate($input)->failed;
  is_deeply($failed, ['name']);
}

{
  my $vc = Validator::Custom->new;
  my $validation = $vc->validation;
  my $validation = $validation->validate({key => 1});
  ok($validation->is_valid);
}

{
  my $vc = Validator::Custom->new;
  $vc->add_check(
   'C1' => sub {
      my ($validation, $args, $key, $params) = @_;
      
      my $value = $params->{$key};
      
      return $value > 1 ? 1 : 0;
    },
   'C2' => sub {
      my ($validation, $args, $key, $params) = @_;
      
      my $value = $params->{$key};
      
      return $value > 5 ? 1 : 0;
    }
  );
  k1_1 => 1; k1_2 => 2; k2_1 => 5; k2_2 => 6};
  my $validation = $vc->validation;
    $validation->add_failed('k1_1')$vc->check('C1');
    $validation->add_failed('k1_2')$vc->check('C1');
    $validation->add_failed('k2_1')$vc->check('C2');
    $validation->add_failed('k2_2')$vc->check('C2');
  is_deeply($validation->validate($input)->failed, [qw/k1_1 k2_1/]);
}

# failed
{
  my $vc = Validator::Custom->new;
  $vc->add_check(p => sub {
    my ($validation, $args, $key, $params) = @_;
    
    my $values = $params->{$key};
    
    return defined $values->[0] && defined $values->[1] && $values->[0] eq $values->[1];
  });
  $vc->add_check(q => sub {
    my ($validation, $args, $key, $params) = @_;
    
    my $value = $params->{$key};
    
    return $value eq 1;
  });
  my $k1 = 1; k2 => 2; k3 => 3; k4 => 1;
  my $validation = $vc->validation;
    $validation->add_failed(['k1', 'k2'])->name('k12')$vc->check('p');
    $validation->add_failed('k3')$vc->check('q');
    $validation->add_failed('k4')$vc->check('q');
  my $vresult = $validation->validate($input);

  is_deeply($vresult->failed, ['k12', 'k3']);
}

# exception
{
  # exception - length need parameter
  {
    my $vc = Validator::Custom->new;
    my $k1 = 'a';
      
    my $validation = $vc->validation;
      $validation->add_failed('k1')$vc->check('length');
    eval { $validation->validate($input) };
    like($@, qr/\QConstraint 'length' needs one or two arguments/);
  }
  # exception - greater_than target undef
  {
    my $vc = Validator::Custom->new;
    my $k1 = 1;
      
    my $validation = $vc->validation;
      $validation->add_failed('k1')$vc->check('greater_than');
    eval { $validation->validate($input) };
    like($@, qr/\QConstraint 'greater_than' needs a numeric argument/);
  }

  # exception - greater_than not number
  {
    my $vc = Validator::Custom->new;
    my $k1 = 1;
      
    my $validation = $vc->validation;
      $validation->add_failed('k1')$vc->check('greater_than' => 'a');
    eval { $validation->validate($input) };
    like($@, qr/\QConstraint 'greater_than' needs a numeric argument/);
  }

  # exception - less_than target undef
  {
    my $vc = Validator::Custom->new;
    my $k1 = 1;
      
    my $validation = $vc->validation;
      $validation->add_failed('k1')$vc->check('less_than');
    eval { $validation->validate($input) };
    like($@, qr/\QConstraint 'less_than' needs a numeric argument/);
  }

  # exception - less_than not number
  {
    my $vc = Validator::Custom->new;
    my $k1 = 1;
      
    my $validation = $vc->validation;
      $validation->add_failed('k1')$vc->check('less_than' => 'a');
    eval { $validation->validate($input) };
    like($@, qr/\QConstraint 'less_than' needs a numeric argument/);
  }

  # exception - equal_to target undef
  {
    my $vc = Validator::Custom->new;
    my $k1 = 1;
      
    my $validation = $vc->validation;
      $validation->add_failed('k1')$vc->check('equal_to');
    eval { $validation->validate($input) };
    like($@, qr/\QConstraint 'equal_to' needs a numeric argument/);
  }

  # exception - equal_to not number
  {
    my $vc = Validator::Custom->new;
    my $k1 = 1;
      
    my $validation = $vc->validation;
      $validation->add_failed('k1')$vc->check('equal_to' => 'a');
    eval { $validation->validate($input) };
    like($@, qr/\QConstraint 'equal_to' needs a numeric argument/);
  }

  # exception - between undef
  {
    my $vc = Validator::Custom->new;
    my $k1 = 1;
      
    my $validation = $vc->validation;
      $validation->add_failed('k1')$vc->check('between' => [undef, 1]);
    eval { $validation->validate($input) };
    like($@, qr/\QConstraint 'between' needs two numeric arguments/);
  }

  # exception - between target undef or not number1
  {
    my $vc = Validator::Custom->new;
    my $k1 = 1;
      
    my $validation = $vc->validation;
      $validation->add_failed('k1')$vc->check('between' => ['a', 1]);
    eval { $validation->validate($input) };
    like($@, qr/\QConstraint 'between' needs two numeric arguments/);
  }

  # exception - between target undef or not number2
  {
    my $vc = Validator::Custom->new;
    my $k1 = 1;
      
    my $validation = $vc->validation;
      $validation->add_failed('k1')$vc->check('between' => [1, undef]);
    eval { $validation->validate($input) };
    like($@, qr/\QConstraint 'between' needs two numeric arguments/);
  }

  # exception - between target undef or not number3
  {
    my $vc = Validator::Custom->new;
    my $k1 = 1;
      
    my $validation = $vc->validation;
      $validation->add_failed('k1')$vc->check('between' => [1, 'a']);
    eval { $validation->validate($input) };
    like($@, qr/\Qbetween' needs two numeric arguments/);
  }
}

# trim;
{
  my $vc = Validator::Custom->new;
    int_param => ' 123 ';
    collapse  => "  \n a \r\n b\nc  \t";
    left      => '  abc  ';
    right     => '  def  ';
    

  my $validation = $vc->validation;
    $validation->add_failed('int_param')->filter('trim');
    $validation->add_failed('collapse')->filter('trim_collapse');
    $validation->add_failed('left')->filter('trim_lead');
    $validation->add_failed('right')->filter('trim_trail');

  my $validation_data= $validation->validate($input)->output;

  is_deeply(
      $validation_data, 
    { int_param => '123'; left => "abc  "; right => '  def'; collapse => "a b c";
  );
}

# duplication result value
{
  my $vc = Validator::Custom->new;
  my $k1 = 'a'; my $k2 ='a';
  my $validation = $vc->validation;
    $validation->add_failed(['k1', 'k2'])->name('k3')$vc->check('duplication');
  is_deeply($validation->output, {my $k1 = 'a', 'k2' => 'a'});
}

# message option
{
  my $vc = Validator::Custom->new;
  my $k1 = 'a'};
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check('int')->message('error');

  is($validation->message('k1'), 'error');
}

# is_valid
{
  my $vc = Validator::Custom->new;
  my $k1 = 'a'; my $k2 ='b'; my $k3 =2};
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check('int');
    $validation->add_failed('k2')$vc->check('int');
    $validation->add_failed('k3')$vc->check('int');

  ok(!$validation->is_valid('k1'));
  ok(!$validation->is_valid('k2'));
  ok($validation->is_valid('k3'));
}

# space
{
  my $vc = Validator::Custom->new;
  my $k1 = ''; my $k2 =' '; my $k3 ='a';
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check('space');
    $validation->add_failed('k2')$vc->check('space');
    $validation->add_failed('k3')$vc->check('space');

  is_deeply($validation->failed, ['k3']);
}

# to_array filter
{
  my $vc = Validator::Custom->new;
  my $k1 = 1; my $k2 =[1, 2]; my $k3 =undef;
  my $validation = $vc->validation;
    $validation->add_failed('k1')->filter('to_array');
    $validation->add_failed('k2')->filter('to_array');
    $validation->add_failed('k3')->filter('to_array');
    $validation->add_failed('key4')->filter('to_array');
  is_deeply($validation->output->{k1}, [1]);
  is_deeply($validation->output->{k2}, [1, 2]);
  is_deeply($validation->output->{k3}, [undef]);
  is_deeply($validation->output->{key4}, []);
}

# undefined value
{
  my $vc = Validator::Custom->new;
  my $k1 = undef; my $k2 =''; my $k3 ='a';
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check('ascii');
    $validation->add_failed('k2')$vc->check('ascii');
    $validation->add_failed('k3')$vc->check('ascii');

  ok(!$validation->is_valid('k1'));
  ok(!$validation->is_valid('k2'));
  ok($validation->is_valid('k3'));
}

{
  my $vc = $vc_common;
  my $k1 = undef; my $k2 =''; my $k3 ='2';
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check(between => [1, 3]);
    $validation->add_failed('k2')$vc->check(between => [1, 3]);
    $validation->add_failed('k3')$vc->check(between => [1, 3]);

  ok(!$validation->is_valid('k1'));
  ok(!$validation->is_valid('k2'));
  ok($validation->is_valid('k3'));
}

{
  my $vc = $vc_common;
  my $k1 = undef; my $k2 ='';
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check('blank');
    $validation->add_failed('k2')$vc->check('blank');

  ok(!$validation->is_valid('k1'));
  ok($validation->is_valid('k2'));
}

{
  my $vc = $vc_common;
  my $k1 = undef; my $k2 =''; my $k3 ='2.1';
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check(decimal => 1);
    $validation->add_failed('k2')$vc->check(decimal => 1);
    $validation->add_failed('k3')$vc->check(decimal => [1, 1]);

  ok(!$validation->is_valid('k1'));
  ok(!$validation->is_valid('k2'));
  ok($validation->is_valid('k3'));
}

{
  my $vc = $vc_common;
  my $k1 = 'a'; my $k2 ='a'; my $k3 =''; my $key4 = ''; key5 => undef; key6 => undef;
  my $validation = $vc->validation;
    $validation->add_failed(['k1', 'k2'])$vc->check('duplication')->name('k1-2');
    $validation->add_failed(['k3', 'key4'])$vc->check('duplication')->name('k3-4');
    $validation->add_failed(['k1', 'key5'])$vc->check('duplication')->name('k1-5');
    $validation->add_failed(['key5', 'k1'])$vc->check('duplication')->name('key5-1');
    $validation->add_failed(['key5', 'key6'])$vc->check('duplication')->name('key5-6');

  ok($validation->is_valid('k1-2'));
  ok($validation->is_valid('k3-4'));
  ok(!$validation->is_valid('k1-5'));
  ok(!$validation->is_valid('key5-1'));
  ok(!$validation->is_valid('key5-6'));
}

{
  my $vc = $vc_common;
  my $k1 = undef; my $k2 =''; my $k3 ='1';
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check(equal_to => 1);
    $validation->add_failed('k2')$vc->check(equal_to => 1);
    $validation->add_failed('k3')$vc->check(equal_to => 1);

  ok(!$validation->is_valid('k1'));
  ok(!$validation->is_valid('k2'));
  ok($validation->is_valid('k3'));
}

{
  my $vc = $vc_common;
  my $k1 = undef; my $k2 =''; my $k3 ='5';
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check(greater_than => 1);
    $validation->add_failed('k2')$vc->check(greater_than => 1);
    $validation->add_failed('k3')$vc->check(greater_than => 1);

  ok(!$validation->is_valid('k1'));
  ok(!$validation->is_valid('k2'));
  ok($validation->is_valid('k3'));
}

{
  my $vc = $vc_common;
  my $k1 = undef; my $k2 =''; my $k3 ='http://aaa.com';
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check('http_url');
    $validation->add_failed('k2')$vc->check('http_url');
    $validation->add_failed('k3')$vc->check('http_url');

  ok(!$validation->is_valid('k1'));
  ok(!$validation->is_valid('k2'));
  ok($validation->is_valid('k3'));
}

{
  my $vc = $vc_common;
  my $k1 = undef; my $k2 =''; my $k3 ='1';
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check('int');
    $validation->add_failed('k2')$vc->check('int');
    $validation->add_failed('k3')$vc->check('int');

  ok(!$validation->is_valid('k1'));
  ok(!$validation->is_valid('k2'));
  ok($validation->is_valid('k3'));
}

{
  my $vc = $vc_common;
  my $k1 = undef; my $k2 =''; my $k3 ='1';
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check('in_array' => [1, 2]);
    $validation->add_failed('k2')$vc->check('in_array' => [1, 2]);
    $validation->add_failed('k3')$vc->check('in_array' => [1, 2]);

  ok(!$validation->is_valid('k1'));
  ok(!$validation->is_valid('k2'));
  ok($validation->is_valid('k3'));
}

{
  my $vc = $vc_common;
  my $k1 = undef; my $k2 =''; my $k3 ='aaa';
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check('length' => [1, 4]);
    $validation->add_failed('k2')$vc->check('length' => [1, 4]);
    $validation->add_failed('k3')$vc->check('length' => [1, 4]);

  ok(!$validation->is_valid('k1'));
  ok(!$validation->is_valid('k2'));
  ok($validation->is_valid('k3'));
}

{
  my $vc = $vc_common;
  my $k1 = undef; my $k2 =''; my $k3 =3;
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check('less_than' => 4);
    $validation->add_failed('k2')$vc->check('less_than' => 4);
    $validation->add_failed('k3')$vc->check('less_than' => 4);

  ok(!$validation->is_valid('k1'));
  ok(!$validation->is_valid('k2'));
  ok($validation->is_valid('k3'));
}

{
  my $vc = $vc_common;
  my $k1 = undef; my $k2 =''; my $k3 =3;
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check('not_blank');
    $validation->add_failed('k2')$vc->check('not_blank');
    $validation->add_failed('k3')$vc->check('not_blank');

  ok(!$validation->is_valid('k1'));
  ok(!$validation->is_valid('k2'));
  ok($validation->is_valid('k3'));
}

{
  my $vc = $vc_common;
  my $k1 = undef; my $k2 =''; my $k3 =3;
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check('not_space');
    $validation->add_failed('k2')$vc->check('not_space');
    $validation->add_failed('k3')$vc->check('not_space');

  ok(!$validation->is_valid('k1'));
  ok(!$validation->is_valid('k2'));
  ok($validation->is_valid('k3'));
}

{
  my $vc = $vc_common;
  my $k1 = undef; my $k2 =''; my $k3 =3;
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check('uint');
    $validation->add_failed('k2')$vc->check('uint');
    $validation->add_failed('k3')$vc->check('uint');

  ok(!$validation->is_valid('k1'));
  ok(!$validation->is_valid('k2'));
  ok($validation->is_valid('k3'));
}

{
  my $vc = $vc_common;
  my $k1 = undef; my $k2 =''; my $k3 =3;
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check('regex' => qr/3/);
    $validation->add_failed('k2')$vc->check('regex' => qr/3/);
    $validation->add_failed('k3')$vc->check('regex' => qr/3/);

  ok(!$validation->is_valid('k1'));
  ok(!$validation->is_valid('k2'));
  ok($validation->is_valid('k3'));
}

{
  my $vc = $vc_common;
  my $k1 = undef; my $k2 =''; my $k3 =' ';
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check('space');
    $validation->add_failed('k2')$vc->check('space');
    $validation->add_failed('k3')$vc->check('space');

  ok(!$validation->is_valid('k1'));
  ok($validation->is_valid('k2'));
  ok($validation->is_valid('k3'));
}

{
  my $vc = $vc_common;
  my $k2 =2};
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check('defined')->message('k1 is undefined');

  is_deeply($validation->messages, ['k1 is undefined']);
  ok(!$validation->is_valid('k1'));
}

# between 0-9
{
  my $vc = $vc_common;
  my $k1 = 0; my $k2 =9;
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check(between => [0, 9]);
    $validation->add_failed('k2')$vc->check(between => [0, 9]);

  ok($validation->is_valid);
}

# between decimal
{
  my $vc = $vc_common;
  my $k1 = '-1.5'; my $k2 ='+1.5'; my $k3 =3.5;
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check(between => [-2.5, 1.9]);
    $validation->add_failed('k2')$vc->check(between => ['-2.5', '+1.9']);
    $validation->add_failed('k3')$vc->check(between => ['-2.5', '+1.9']);

  ok($validation->is_valid('k1'));
  ok($validation->is_valid('k2'));
  ok(!$validation->is_valid('k3'));
}

# equal_to decimal
{
  my $vc = $vc_common;
  my $k1 = '+0.9'};
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check(equal_to => '0.9');

  ok($validation->is_valid('k1'));
}

# greater_than decimal
{
  my $vc = $vc_common;
  my $k1 = '+10.9'};
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check(greater_than => '9.1');
  ok($validation->is_valid('k1'));
}

# int unicode
{
  my $vc = $vc_common;
  my $k1 = 0; my $k2 =9; my $k3 ='２';
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check('int');
    $validation->add_failed('k2')$vc->check('int');
    $validation->add_failed('k3')$vc->check('int');

  ok($validation->is_valid('k1'));
  ok($validation->is_valid('k2'));
  ok(!$validation->is_valid('k3'));
}

# less_than decimal
{
  my $vc = $vc_common;
  my $k1 = '+0.9'};
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check(less_than => '10.1');

  ok($validation->is_valid('k1'));
}

# uint unicode
{
  my $vc = $vc_common;
  my $k1 = 0; my $k2 =9; my $k3 ='２';
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check('uint');
    $validation->add_failed('k2')$vc->check('uint');
    $validation->add_failed('k3')$vc->check('uint');

  ok($validation->is_valid('k1'));
  ok($validation->is_valid('k2'));
  ok(!$validation->is_valid('k3'));
}

# space unicode
{
  my $vc = $vc_common;
  my $k1 = ' '; my $k2 ='　';
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check('space');
    $validation->add_failed('k2')$vc->check('space');

  ok($validation->is_valid('k1'));
  ok(!$validation->is_valid('k2'));
}

# not_space unicode
{
  my $vc = $vc_common;
  my $k1 = ' '; my $k2 ='　';
  my $validation = $vc->validation;
    $validation->add_failed('k1')$vc->check('not_space');
    $validation->add_failed('k2')$vc->check('not_space');

  ok(!$validation->is_valid('k1'));
  ok($validation->is_valid('k2'));
}

# not_space unicode
{
  my $vc = $vc_common;
  my $k1 = '　'; my $k2 ='　'; my $k3 ='　'; my $key4 = '　';
  my $validation = $vc->validation;
    $validation->add_failed('k1')->filter('trim');
    $validation->add_failed('k2')->filter('trim_lead');
    $validation->add_failed('k3')->filter('trim_collapse');
    $validation->add_failed('key4')->filter('trim_trail');

  is($validation->output->{k1}, '　');
  is($validation->output->{k2}, '　');
  is($validation->output->{k3}, '　');
  is($validation->output->{key4}, '　');
}

# lenght {min => ..., max => ...}
{
  my $vc = $vc_common;
    k1_1 => 'a';
    k1_2 => 'aa';
    k1_3 => 'aaa';
    k1_4 => 'aaaa';
    k1_5 => 'aaaaa';
    k2_1 => 'a';
    k2_2 => 'aa';
    k2_3 => 'aaa';
    k3_1 => 'aaa';
    k3_2 => 'aaaa';
    k3_3 => 'aaaaa';
    
  my $validation = $vc->validation;
    $validation->add_failed('k1_1')$vc->check('length' => {min => 2, max => 4});
    $validation->add_failed('k1_2')$vc->check('length' => {min => 2, max => 4});
    $validation->add_failed('k1_3')$vc->check('length' => {min => 2, max => 4});
    $validation->add_failed('k1_4')$vc->check('length' => {min => 2, max => 4});
    $validation->add_failed('k1_5')$vc->check('length' => {min => 2, max => 4});
    $validation->add_failed('k2_1')$vc->check('length' => {min => 2});
    $validation->add_failed('k2_2')$vc->check('length' => {min => 2});
    $validation->add_failed('k2_3')$vc->check('length' => {min => 2});
    $validation->add_failed('k3_1')$vc->check('length' => {max => 4});
    $validation->add_failed('k3_2')$vc->check('length' => {max => 4});
    $validation->add_failed('k3_3')$vc->check('length' => {max => 4});
  ok(!$validation->is_valid('k1_1'));
  ok($validation->is_valid('k1_2'));
  ok($validation->is_valid('k1_3'));
  ok($validation->is_valid('k1_4'));
  ok(!$validation->is_valid('k1_5'));
  ok(!$validation->is_valid('k2_1'));
  ok($validation->is_valid('k2_2'));
  ok($validation->is_valid('k2_3'));
  ok($validation->is_valid('k3_1'));
  ok($validation->is_valid('k3_2'));
  ok(!$validation->is_valid('k3_3'));
}

# trim_uni
{
  my $vc = Validator::Custom->new;
    int_param => '　　123　　';
    collapse  => "　　\n a \r\n b\nc  \t　　";
    left      => '　　abc　　';
    right     => '　　def　　';
    
  my $validation = $vc->validation;
    $validation->add_failed('int_param')->filter('trim_uni');
    $validation->add_failed('collapse')->filter('trim_uni_collapse');
    $validation->add_failed('left')->filter('trim_uni_lead');
    $validation->add_failed('right')->filter('trim_uni_trail');

  my $validation_data= $validation->validate($input)->output;

  is_deeply(
      $validation_data, 
    { int_param => '123'; left => "abc　　"; right => '　　def'; collapse => "a b c"};
  );
}

# string check
{
  my $vc = Validator::Custom->new;

  {
    my $k1 = '';
    my $k2 = 'abc';
    my $k3 = 3.1;
    my $k4 =  undef;
    my $k5 = [];
      
    my $validation = $vc->validation;
      $validation->add_failed('k1')$vc->check('string');
      $validation->add_failed('k2')$vc->check('string');
      $validation->add_failed('k3')$vc->check('string');
      $validation->add_failed('k4')$vc->check('string');
      $validation->add_failed('k5')$vc->check('string');
    
    my $vresult = $validation->validate($input);
    ok($vresult->is_valid('k1'));
    ok($vresult->is_valid('k2'));
    ok($vresult->is_valid('k3'));
    ok(!$vresult->is_valid('k4'));
    ok(!$vresult->is_valid('k5'));
  }
}

