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

# length
{
  my $vc = Validator::Custom->new;
  my $k1 = '111';
  my $k2 = '11';
    
  my $validation = $vc->validation;
  if (!(length $k2 && length $k1 < 3)) {
    $validation->add_failed('k1');
  }
  
  if(!(length $k2 && length $k2 < 3)) {
    $validation->add_failed('k2');
  }

  is_deeply($validation->failed, ['k1']);
}

# duplication
{
  my $vc = Validator::Custom->new;
  my $k1_1 = 'a';
  my $k1_2 = 'a';
  
  my $k2_1 = 'a';
  my $k2_2 = 'b';
  
  my $validation = $vc->validation;
  if (!($k1_1 eq $k1_2)) {
    $validation->add_failed('k1_check');
  }
  if (!($k2_1 eq $k2_2)) {
    $validation->add_failed('k2_check');
  }

  is_deeply($validation->failed, ['k2_check']);
}

# regex
{
  my $vc = Validator::Custom->new;
  my $k1 = 'aaa';
  my $k2 = 'aa';
    
  my $validation = $vc->validation;
  if (!($k1 =~ qr/a{3}/)) {
    $validation->add_failed('k1');
  }
  if (!($k2 =~ qr/a{4}/)) {
    $validation->add_failed('k2');
  }

  is_deeply($validation->failed, ['k2']);
}

# http_url
{
  my $vc = Validator::Custom->new;
  my $k1 = 'http://www.lost-season.jp/mt/';
  my $k2 = 'iii';
    
  my $validation = $vc->validation;
  if (!$vc->check('http_url', $k1)) {
    $validation->add_failed('k1');
  }
  if (!$vc->check('http_url', $k2)) {
    $validation->add_failed('k2');
  }

  is_deeply($validation->failed, ['k2']);
}

# greater than
{
  my $vc = Validator::Custom->new;
  my $k1 = 5;
  my $k2 = 5;
    
  my $validation = $vc->validation;
  if (!($k1 > 5)) {
    $validation->add_failed('k1');;
  }
  if (!($k2 > 4)) {
    $validation->add_failed('k2');
  }

  is_deeply($validation->failed, ['k1']);
}

# less than
{
  my $vc = Validator::Custom->new;
  my $k1 = 5;
  my $k2 = 5;
    
  my $validation = $vc->validation;
  if (!($k1 < 5)) {
    $validation->add_failed('k1');
  }
  if (!($k2 < 6)) {
    $validation->add_failed('k2');
  }

  is_deeply($validation->failed, ['k1']);
}

# equal
{
  my $vc = Validator::Custom->new;
  my $k1 = 5;
  my $k2 = 5;
    
  my $validation = $vc->validation;
  if (!($k1 == 5)) {
    $validation->add_failed('k1');
  }
  if (!($k1 == 4)) {
    $validation->add_failed('k2');
  }

  is_deeply($validation->failed, ['k2']);
}

# decimal
{
  my $vc = Validator::Custom->new;
  my $k1 = '12.123';
  my $k2 = '12.123';
  my $k3 = '12.123';
  my $k4 =  '12';
  my $k5 = '123';
  my $k6 = '123.a';
  my $k7 = '1234.1234';
  my $k8 = '';
  my $k9 = 'a';
  my $k10 = '1111111.12';
  my $k11 = '1111111.123';
  my $k12 = '12.1111111';
  my $k13 = '123.1111111';
    
  my $validation = $vc->validation;
  if (!$vc->check('decimal', $k1, [2,3])) {
    $validation->add_failed('k1');
  }
  if (!$vc->check('decimal', $k2,  [1,3])) {
    $validation->add_failed('k2');
  }
  if (!$vc->check('decimal', $k3, [2,2])) {
    $validation->add_failed('k3');
  }
  if (!$vc->check('decimal', $k4, [2])) {
    $validation->add_failed('k4');
  }
  if (!$vc->check('decimal', $k5, 2)) {
    $validation->add_failed('k5');
  }
  if (!$vc->check('decimal', $k6, 2)) {
    $validation->add_failed('k6');
  }
  if (!$vc->check('decimal', $k7)) {
    $validation->add_failed('k7');
  }
  if (!$vc->check('decimal', $k8)) {
    $validation->add_failed('k8');
  }
  if (!$vc->check('decimal', $k9)) {
    $validation->add_failed('k9');
  }
  if (!$vc->check('decimal', $k10, [undef, 2])) {
    $validation->add_failed('k10');
  }
  if (!$vc->check('decimal', $k11, [undef, 2])) {
    $validation->add_failed('k11');
  }
  if (!$vc->check('decimal', $k12, [2, undef])) {
    $validation->add_failed('k12');
  }
  if (!$vc->check('decimal', $k13, [2, undef])) {
    $validation->add_failed('k13');
  }

  is_deeply($validation->failed, [qw/k2 k3 k5 k6 k8 k9 k11 k13/]);
}

# in
{
  my $vc = Validator::Custom->new;
  my $k1 = 'a';
  my $k2 = 'a';
  
  my $validation = $vc->validation;
  if (!($vc->check('in', $k1, [qw/a b/]))) {
    $validation->add_failed('k1');
  }
  if (!($vc->check('in', $k2, [qw/b c/]))) {
    $validation->add_failed('k2');
  }
  
  is_deeply($validation->failed, ['k2']);
}

# int
{
  my $vc = Validator::Custom->new;
  my $k1 = '19';
  my $k2 = '-10';
  my $k3 = 'a';
  my $k4 = '10.0';
    
  my $validation = $vc->validation;
  if (!$vc->check('int')) {
    $validation->add_failed('k1');
  }
  if (!$vc->check('int')) {
    $validation->add_failed('k2');
  }
  if (!$vc->check('int')) {
    $validation->add_failed('k3');
  }
  if (!$vc->check('int')) {
    $validation->add_failed('k4');
  }

  is_deeply($validation->failed, ['k3', 'k4']);
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
  
  is_deeply($validation->output->{k1}, [1]);
  is_deeply($validation->output->{k2}, [1, 2]);
  is_deeply($validation->output->{k3}, []);
  is_deeply($validation->output->{key4}, [1, 3]);
}

# selected_at_least
{
  my $vc = Validator::Custom->new;
  my $k1 = 1;
  my $k2 = [1];
  my $k3 = [1, 2];
  my $k4 =  [];
  my $k5 = [1,2];
    
  my $validation = $vc->validation;
    $validation->add_failed('k1');$vc->check(selected_at_least => 1);
    $validation->add_failed('k2');$vc->check(selected_at_least => 1);
    $validation->add_failed('k3');$vc->check(selected_at_least => 2);
    $validation->add_failed('k4');$vc->check('selected_at_least');
    $validation->add_failed('k5');$vc->check('selected_at_least' => 3);

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
    my $k1 = 1; my $k2 = [1,2]; my $k3 = [1,'a', 'b']; my $k4 = 'a'; my $k5 = [];
      $validation->add_failed('k1')->filter('to_array');$vc->check(selected_at_least => 1);$vc->check_each('int');
      $validation->add_failed('k2')->filter('to_array');$vc->check(selected_at_least => 1);$vc->check_each('int');
      $validation->add_failed('k3')->filter('to_array');$vc->check(selected_at_least => 1);$vc->check_each('int');
      $validation->add_failed('k4')->filter('to_array');$vc->check(selected_at_least => 1);$vc->check_each('int');
      $validation->add_failed('k5')->filter('to_array');$vc->check(selected_at_least => 1);$vc->check_each('int');

  }

  # check_each - repeat
  {
    my $vc = Validator::Custom->new;
    my $k1 = ['a', 'a']; my $k2 =[1, 1];
    my $validation = $vc->validation;
      $validation->add_failed('k1')
      ;$vc->check_each('not_blank')
      ;$vc->check_each(sub {
        my ($validation, $args, $key, $params) = @_;
        
        return !$validation->run_check('int', [], $key, $params);
      });
      $validation->add_failed('k2')
      ;$vc->check_each('not_blank')
      ;$vc->check_each(sub {
        my ($validation, $args, $key, $params) = @_;
        
        return !$validation->run_check('int', [], $key, $params);
      });
    
    
    is_deeply($validation->failed, ['k2']);
  }
}


# Validator::Custom::Resut filter method
{
  my $vc = Validator::Custom->new;
  my $k1 = ' 123 ';
    
  my $validation = $vc->validation;
    $validation->add_failed('k1')->filter('trim');

  is_deeply($validation, {k1 => '123'});
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
  my $k1 = 1; my $k2 = 2; my $k3 = 3; my $k4 = 1;
  my $validation = $vc->validation;
    $validation->add_failed(['k1', 'k2'])->name('k12');$vc->check('p');
    $validation->add_failed('k3');$vc->check('q');
    $validation->add_failed('k4');$vc->check('q');
  

  is_deeply($validation->failed, ['k12', 'k3']);
}

# trim;
{
  my $vc = Validator::Custom->new;
  my $int_param = ' 123 ';
  my $collapse  = "  \n a \r\n b\nc  \t";
  my $left      = '  abc  ';
  my $right     = '  def  ';

  my $validation = $vc->validation;
    $validation->add_failed('int_param')->filter('trim');
    $validation->add_failed('collapse')->filter('trim_collapse');
    $validation->add_failed('left')->filter('trim_lead');
    $validation->add_failed('right')->filter('trim_trail');

  my $validation_data= $validation->output;

  is_deeply(
      $validation_data, 
    { int_param => '123', left => "abc  ", right => '  def', collapse => "a b c"}
  );
}

# space
{
  my $vc = Validator::Custom->new;
  my $k1 = ''; my $k2 =' '; my $k3 ='a';
  my $validation = $vc->validation;
    $validation->add_failed('k1');$vc->check('space');
    $validation->add_failed('k2');$vc->check('space');
    $validation->add_failed('k3');$vc->check('space');

  is_deeply($validation->failed, ['k3']);
}

# undefined value
{
  my $vc = Validator::Custom->new;
  my $k1 = undef; my $k2 =''; my $k3 ='a';
  my $validation = $vc->validation;
    $validation->add_failed('k1');$vc->check('ascii');
    $validation->add_failed('k2');$vc->check('ascii');
    $validation->add_failed('k3');$vc->check('ascii');

  ok(!$validation->is_valid('k1'));
  ok(!$validation->is_valid('k2'));
  ok($validation->is_valid('k3'));
}

{
  my $vc = Validator::Custom->new;
  my $k1 = undef; my $k2 =''; my $k3 ='2';
  my $validation = $vc->validation;
    $validation->add_failed('k1');$vc->check(between => [1, 3]);
    $validation->add_failed('k2');$vc->check(between => [1, 3]);
    $validation->add_failed('k3');$vc->check(between => [1, 3]);

  ok(!$validation->is_valid('k1'));
  ok(!$validation->is_valid('k2'));
  ok($validation->is_valid('k3'));
}

{
  my $vc = Validator::Custom->new;
  my $k1 = undef; my $k2 ='';
  my $validation = $vc->validation;
    $validation->add_failed('k1');$vc->check('blank');
    $validation->add_failed('k2');$vc->check('blank');

  ok(!$validation->is_valid('k1'));
  ok($validation->is_valid('k2'));
}

{
  my $vc = Validator::Custom->new;
  my $k1 = undef; my $k2 =''; my $k3 ='2.1';
  my $validation = $vc->validation;
    $validation->add_failed('k1');$vc->check(decimal => 1);
    $validation->add_failed('k2');$vc->check(decimal => 1);
    $validation->add_failed('k3');$vc->check(decimal => [1, 1]);

  ok(!$validation->is_valid('k1'));
  ok(!$validation->is_valid('k2'));
  ok($validation->is_valid('k3'));
}

{
  my $vc = Validator::Custom->new;
  my $k1 = 'a';
  my $k2 ='a';
  my $k3 ='';
  my $key4 = '';
  my $key5 = undef;
  my $key6 = undef;
  my $validation = $vc->validation;
    $validation->add_failed(['k1', 'k2']);$vc->check('duplication')->name('k1-2');
    $validation->add_failed(['k3', 'key4']);$vc->check('duplication')->name('k3-4');
    $validation->add_failed(['k1', 'key5']);$vc->check('duplication')->name('k1-5');
    $validation->add_failed(['key5', 'k1']);$vc->check('duplication')->name('key5-1');
    $validation->add_failed(['key5', 'key6']);$vc->check('duplication')->name('key5-6');

  ok($validation->is_valid('k1-2'));
  ok($validation->is_valid('k3-4'));
  ok(!$validation->is_valid('k1-5'));
  ok(!$validation->is_valid('key5-1'));
  ok(!$validation->is_valid('key5-6'));
}

{
  my $vc = Validator::Custom->new;
  my $k1 = undef; my $k2 =''; my $k3 ='1';
  my $validation = $vc->validation;
    $validation->add_failed('k1');$vc->check(equal_to => 1);
    $validation->add_failed('k2');$vc->check(equal_to => 1);
    $validation->add_failed('k3');$vc->check(equal_to => 1);

  ok(!$validation->is_valid('k1'));
  ok(!$validation->is_valid('k2'));
  ok($validation->is_valid('k3'));
}

{
  my $vc = Validator::Custom->new;
  my $k1 = undef; my $k2 =''; my $k3 ='5';
  my $validation = $vc->validation;
    $validation->add_failed('k1');$vc->check(greater_than => 1);
    $validation->add_failed('k2');$vc->check(greater_than => 1);
    $validation->add_failed('k3');$vc->check(greater_than => 1);

  ok(!$validation->is_valid('k1'));
  ok(!$validation->is_valid('k2'));
  ok($validation->is_valid('k3'));
}

{
  my $vc = Validator::Custom->new;
  my $k1 = undef; my $k2 =''; my $k3 ='http://aaa.com';
  my $validation = $vc->validation;
    $validation->add_failed('k1');$vc->check('http_url');
    $validation->add_failed('k2');$vc->check('http_url');
    $validation->add_failed('k3');$vc->check('http_url');

  ok(!$validation->is_valid('k1'));
  ok(!$validation->is_valid('k2'));
  ok($validation->is_valid('k3'));
}

{
  my $vc = Validator::Custom->new;
  my $k1 = undef; my $k2 =''; my $k3 ='1';
  my $validation = $vc->validation;
    $validation->add_failed('k1');$vc->check('int');
    $validation->add_failed('k2');$vc->check('int');
    $validation->add_failed('k3');$vc->check('int');

  ok(!$validation->is_valid('k1'));
  ok(!$validation->is_valid('k2'));
  ok($validation->is_valid('k3'));
}

{
  my $vc = Validator::Custom->new;
  my $k1 = undef; my $k2 =''; my $k3 ='aaa';
  my $validation = $vc->validation;
    $validation->add_failed('k1');$vc->check('length' => [1, 4]);
    $validation->add_failed('k2');$vc->check('length' => [1, 4]);
    $validation->add_failed('k3');$vc->check('length' => [1, 4]);

  ok(!$validation->is_valid('k1'));
  ok(!$validation->is_valid('k2'));
  ok($validation->is_valid('k3'));
}

{
  my $vc = Validator::Custom->new;
  my $k1 = undef; my $k2 =''; my $k3 =3;
  my $validation = $vc->validation;
    $validation->add_failed('k1');$vc->check('less_than' => 4);
    $validation->add_failed('k2');$vc->check('less_than' => 4);
    $validation->add_failed('k3');$vc->check('less_than' => 4);

  ok(!$validation->is_valid('k1'));
  ok(!$validation->is_valid('k2'));
  ok($validation->is_valid('k3'));
}

{
  my $vc = Validator::Custom->new;
  my $k1 = undef; my $k2 =''; my $k3 =3;
  my $validation = $vc->validation;
    $validation->add_failed('k1');$vc->check('not_blank');
    $validation->add_failed('k2');$vc->check('not_blank');
    $validation->add_failed('k3');$vc->check('not_blank');

  ok(!$validation->is_valid('k1'));
  ok(!$validation->is_valid('k2'));
  ok($validation->is_valid('k3'));
}

{
  my $vc = Validator::Custom->new;
  my $k1 = undef; my $k2 =''; my $k3 =3;
  my $validation = $vc->validation;
    $validation->add_failed('k1');$vc->check('not_space');
    $validation->add_failed('k2');$vc->check('not_space');
    $validation->add_failed('k3');$vc->check('not_space');

  ok(!$validation->is_valid('k1'));
  ok(!$validation->is_valid('k2'));
  ok($validation->is_valid('k3'));
}

{
  my $vc = Validator::Custom->new;
  my $k1 = undef; my $k2 =''; my $k3 =3;
  my $validation = $vc->validation;
    $validation->add_failed('k1');$vc->check('uint');
    $validation->add_failed('k2');$vc->check('uint');
    $validation->add_failed('k3');$vc->check('uint');

  ok(!$validation->is_valid('k1'));
  ok(!$validation->is_valid('k2'));
  ok($validation->is_valid('k3'));
}

{
  my $vc = Validator::Custom->new;
  my $k1 = undef; my $k2 =''; my $k3 =3;
  my $validation = $vc->validation;
    $validation->add_failed('k1');$vc->check('regex' => qr/3/);
    $validation->add_failed('k2');$vc->check('regex' => qr/3/);
    $validation->add_failed('k3');$vc->check('regex' => qr/3/);

  ok(!$validation->is_valid('k1'));
  ok(!$validation->is_valid('k2'));
  ok($validation->is_valid('k3'));
}

{
  my $vc = Validator::Custom->new;
  my $k1 = undef; my $k2 =''; my $k3 =' ';
  my $validation = $vc->validation;
    $validation->add_failed('k1');$vc->check('space');
    $validation->add_failed('k2');$vc->check('space');
    $validation->add_failed('k3');$vc->check('space');

  ok(!$validation->is_valid('k1'));
  ok($validation->is_valid('k2'));
  ok($validation->is_valid('k3'));
}

{
  my $vc = Validator::Custom->new;
  my $k2 = 2;
  my $validation = $vc->validation;
    $validation->add_failed('k1');$vc->check('defined');

  ok(!$validation->is_valid('k1'));
}

# int unicode
{
  my $vc = Validator::Custom->new;
  my $k1 = 0; my $k2 =9; my $k3 ='２';
  my $validation = $vc->validation;
    $validation->add_failed('k1');$vc->check('int');
    $validation->add_failed('k2');$vc->check('int');
    $validation->add_failed('k3');$vc->check('int');

  ok($validation->is_valid('k1'));
  ok($validation->is_valid('k2'));
  ok(!$validation->is_valid('k3'));
}

# uint unicode
{
  my $vc = Validator::Custom->new;
  my $k1 = 0; my $k2 =9; my $k3 ='２';
  my $validation = $vc->validation;
    $validation->add_failed('k1');$vc->check('uint');
    $validation->add_failed('k2');$vc->check('uint');
    $validation->add_failed('k3');$vc->check('uint');

  ok($validation->is_valid('k1'));
  ok($validation->is_valid('k2'));
  ok(!$validation->is_valid('k3'));
}

# space unicode
{
  my $vc = Validator::Custom->new;
  my $k1 = ' '; my $k2 ='　';
  my $validation = $vc->validation;
    $validation->add_failed('k1');$vc->check('space');
    $validation->add_failed('k2');$vc->check('space');

  ok($validation->is_valid('k1'));
  ok(!$validation->is_valid('k2'));
}

# not_space unicode
{
  my $vc = Validator::Custom->new;
  my $k1 = ' '; my $k2 ='　';
  my $validation = $vc->validation;
    $validation->add_failed('k1');$vc->check('not_space');
    $validation->add_failed('k2');$vc->check('not_space');

  ok(!$validation->is_valid('k1'));
  ok($validation->is_valid('k2'));
}

# not_space unicode
{
  my $vc = Validator::Custom->new;
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
  my $vc = Validator::Custom->new;
  my $k1_1 = 'a';
  my $k1_2 = 'aa';
  my $k1_3 = 'aaa';
  my $k1_4 = 'aaaa';
  my $k1_5 = 'aaaaa';
  my $k2_1 = 'a';
  my $k2_2 = 'aa';
  my $k2_3 = 'aaa';
  my $k3_1 = 'aaa';
  my $k3_2 = 'aaaa';
  my $k3_3 = 'aaaaa';
    
  my $validation = $vc->validation;
    $validation->add_failed('k1_1');$vc->check('length' => {min => 2, max => 4});
    $validation->add_failed('k1_2');$vc->check('length' => {min => 2, max => 4});
    $validation->add_failed('k1_3');$vc->check('length' => {min => 2, max => 4});
    $validation->add_failed('k1_4');$vc->check('length' => {min => 2, max => 4});
    $validation->add_failed('k1_5');$vc->check('length' => {min => 2, max => 4});
    $validation->add_failed('k2_1');$vc->check('length' => {min => 2});
    $validation->add_failed('k2_2');$vc->check('length' => {min => 2});
    $validation->add_failed('k2_3');$vc->check('length' => {min => 2});
    $validation->add_failed('k3_1');$vc->check('length' => {max => 4});
    $validation->add_failed('k3_2');$vc->check('length' => {max => 4});
    $validation->add_failed('k3_3');$vc->check('length' => {max => 4});
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

  is_deeply(
      {}, 
    { int_param => '123', left => "abc　　", right => '　　def', collapse => "a b c"}
  );
}
