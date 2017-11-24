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

# check
{
  # check - int
  {
    my $vc = Validator::Custom->new;
    my %values = (
      k1 => '19',
      k2 => '-10',
      k3 => 'a',
      k4 => '10.0',
      k5 => '２',
      k6 => undef);

    my $validation = $vc->validation;
    for my $case (sort keys %values) {
      if (!$vc->check($values{$case}, 'int')) {
        $validation->add_failed($case);
      }
    }
    
    is_deeply($validation->failed, ['k3', 'k4', 'k5', 'k6']);
  }
  
  # check - ascii_graphic
  {
    my $vc = Validator::Custom->new;
    my %values = (
      k1 => '!~',
      k2 => ' ',
      k3 => "\0x7f",
      k4 => undef);

    my $validation = $vc->validation;
    for my $case (sort keys %values) {
        if (!$vc->check($values{$case}, 'ascii_graphic')) {
          $validation->add_failed($case);
        }
    }
    
    is_deeply($validation->failed, ['k2', 'k3', 'k4']);
  }

  # check - number
  {
    my $vc = Validator::Custom->new;
    my %values = (
      k01 => '1',
      k02 => '123',
      k03 => '456.123',
      k04 => '-1',
      k05 => '-789',
      k06 => '-100.456',
      k07 => '-100.789',
    
      k08 => 'a',
      k09 => '1.a',
      k10 => 'a.1',
      k11 => '',
      k12 => undef);

    my $validation = $vc->validation;
    for my $case (sort keys %values) {
      if (!$vc->check($values{$case}, 'number')) {
        $validation->add_failed($case);
      }
    }
    is_deeply($validation->failed, [qw/k08 k09 k10 k11 k12/]);
  }

  # check - number, decimal_part_max
  {
    my $vc = Validator::Custom->new;
    my %values = (
      k01 => '1',
      k02 => '123',
      k03 => '456.123',
      k04 => '-1',
      k05 => '-789',
      k06 => '-100.456',
      k07 => '-100.789',
    
      k08 => 'a',
      k09 => '1.a',
      k10 => 'a.1',
      k11 => '',
      k12 => undef,
      k13 => '456.1234',
      k14 => '-100.7894');
    
    my $validation = $vc->validation;
    for my $case (sort keys %values) {
      if (!$vc->check($values{$case}, 'number', {decimal_part_max => 3})) {
        $validation->add_failed($case);
      }
    }
    is_deeply($validation->failed, [qw/k08 k09 k10 k11 k12 k13 k14/]);
  }
  
  # check - in
  {
    my $vc = Validator::Custom->new;
    my %values = (
      k1 => ['a', ['a', 'b']],
      k2 => ['a', ['b', 'c']],
      k3 => [undef, ['b', 'c']],
      k4 => [undef, [undef]]);
    
    my $validation = $vc->validation;
    for my $case (sort keys %values) {
      if (!($vc->check($values{$case}[0], 'in', $values{$case}[1]))) {
        $validation->add_failed($case);
      }
    }
    
    is_deeply($validation->failed, ['k2', 'k3']);
  }

  # check - exception, few arguments
  {
    my $vc = Validator::Custom->new;
    eval { $vc->check() };
    like($@, qr/value and the name of a checking function must be passed/);
    
    eval { $vc->check(3) };
    like($@, qr/value and the name of a checking function must be passed/);
  }

  # check - exception, checking function not found
  {
    my $vc = Validator::Custom->new;
    eval { $vc->check(1, 'foo') };
    like($@, qr/Can't call "foo" checking function/);
  }
}

# filter
{
  # remove_blank filter
  {
    my $vc = Validator::Custom->new;
    my $k1 =[1, 2];
    my $k2 = [1, 3, '', '', undef];
    my $k3 = [];
    
    $k1 = $vc->filter($k1, 'remove_blank');
    $k2 = $vc->filter($k2, 'remove_blank');
    $k3 = $vc->filter($k3, 'remove_blank');
    
    is_deeply($k1, [1, 2]);
    is_deeply($k2, [1, 3]);
    is_deeply($k3, []);
  }
  
  # filter - remove_blank, exception
  {
    my $vc = Validator::Custom->new;
    my $k1 = 1;
    eval {$k1 = $vc->filter($k1, 'remove_blank')};
    like($@, qr/must be array reference/);
  }

  # filter - trim
  {
    my $vc = Validator::Custom->new;
    my $k1 = ' 　　123　　 ';
    my $k2;
    
    $k1 = $vc->filter($k1, 'trim');
    $k2 = $vc->filter($k2, 'trim');
    
    is($k1, '123');
    ok(!defined $k2);
  }

  # filter - exception, few arguments
  {
    my $vc = Validator::Custom->new;
    eval { $vc->filter() };
    like($@, qr/value and the name of a filtering function must be passed/);
    
    eval { $vc->filter(3) };
    like($@, qr/value and the name of a filtering function must be passed/);
  }

  # filter - exception, filtering function not found
  {
    my $vc = Validator::Custom->new;
    eval { $vc->filter(1, 'foo') };
    like($@, qr/Can't call "foo" filtering function/);
  }
}

# add_check
{
  my $vc = Validator::Custom->new;
  my $is_first_arg_object;
  $vc->add_check('equal' => sub {
    my ($vc2, $value, $arg) = @_;
    
    if ($vc eq $vc2) {
      $is_first_arg_object = 1;
    }
    
    if ($value eq $arg) {
      return 1;
    }
    else {
      return 0;
    }
  });
  
  my $k1 = 'a';
  my $k2 = 'a';
  
  my $validation = $vc->validation;
  
  if (!($vc->check($k1, 'equal', 'a'))) {
    $validation->add_failed('k1');
  }
  
  if (!($vc->check($k1, 'equal', 'b'))) {
    $validation->add_failed('k2');
  }
  
  is_deeply($validation->failed, ['k2']);
  ok($is_first_arg_object);
}

# add_filter
{
  my $vc = Validator::Custom->new;
  my $is_first_arg_object;
  $vc->add_filter('cat' => sub {
    my ($vc2, $value, $arg) = @_;
    
    if ($vc eq $vc2) {
      $is_first_arg_object = 1;
    }
    
    return "$value$arg";
  });
  
  my $k1 = 'a';
  
  my $validation = $vc->validation;
  
  $k1 = $vc->filter($k1, 'cat', 'b');
  
  is($k1, 'ab');
  ok($is_first_arg_object);
}

# check_each
{
  # check_each - int
  {
    my $vc = Validator::Custom->new;
    my $k1 = ['19', '20'];
    my $k2 = ['a', '19'];
      
    my $validation = $vc->validation;
    if (!$vc->check_each($k1, 'int')) {
      $validation->add_failed('k1');
    }
    if (!$vc->check_each($k2, 'int')) {
      $validation->add_failed('k2');
    }
    is_deeply($validation->failed, ['k2']);
  }
  
  # check_each - arguments
  {
    my $vc = Validator::Custom->new;
    my $is_first_arg_object;
    my $validation = $vc->validation;
    $vc->add_check('equal' => sub {
      my ($vc2, $value, $arg) = @_;
      
      if ($vc eq $vc2) {
        $is_first_arg_object = 1;
      }
      
      if ($value eq $arg) {
        return 1;
      }
      else {
        return 0;
      }
    });
    
    my $k1 = ['a', 'a'];
    my $k2 = ['a', 'b'];
    
    if (!$vc->check_each($k1, 'equal', 'a')) {
      $validation->add_failed('k1');
    }

    if (!$vc->check_each($k2, 'equal', 'a')) {
      $validation->add_failed('k2');
    }
    
    is_deeply($validation->failed, ['k2']);
    ok($is_first_arg_object);
  }

  # check_each - exception, few arguments
  {
    my $vc = Validator::Custom->new;
    eval { $vc->check_each() };
    like($@, qr/values and the name of a checking function must be passed/);
    
    eval { $vc->check_each([]) };
    like($@, qr/values and the name of a checking function must be passed/);
  }

  # check_each - exception, checking function not found
  {
    my $vc = Validator::Custom->new;
    eval { $vc->check_each([1], 'foo') };
    like($@, qr/Can't call "foo" checking function/);
  }

  # check - exception, values is not array reference
  {
    my $vc = Validator::Custom->new;
    eval { $vc->check_each(1, 'int') };
    like($@, qr/values must be array reference/);
  }
}

# filter_each
{
  # filter_each - int
  {
    my $vc = Validator::Custom->new;
    my $k1 = [' a ', ' b '];
      
    my $validation = $vc->validation;
    $k1 = $vc->filter_each($k1, 'trim');

    is_deeply($k1, ['a', 'b']);
  }
  
  # filter_each - arguments
  {
    my $vc = Validator::Custom->new;
    my $is_first_arg_object;
    $vc->add_filter('cat' => sub {
      my ($vc2, $value, $arg) = @_;
      
      if ($vc eq $vc2) {
        $is_first_arg_object = 1;
      }
      
      return "$value$arg";
    });
    
    my $k1 = ['a', 'c'];
    
    my $validation = $vc->validation;
    
    $k1 = $vc->filter_each($k1, 'cat', 'b');
    
    is_deeply($k1, ['ab', 'cb']);
    ok($is_first_arg_object);
  }
  
  # filter_each - exception, few arguments
  {
    my $vc = Validator::Custom->new;
    eval { $vc->filter_each() };
    like($@, qr/values and the name of a filtering function must be passed/);
    
    eval { $vc->filter_each([]) };
    like($@, qr/values and the name of a filtering function must be passed/);
  }

  # filter_each - exception, filtering function not found
  {
    my $vc = Validator::Custom->new;
    eval { $vc->filter_each([1], 'foo') };
    like($@, qr/Can't call "foo" filtering function/);
  }

  # filter - exception, values is not array reference
  {
    my $vc = Validator::Custom->new;
    eval { $vc->filter_each(1, 'trim') };
    like($@, qr/values must be array reference/);
  }
}
