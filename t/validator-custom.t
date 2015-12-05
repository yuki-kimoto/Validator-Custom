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
    my $k1 = '19';
    my $k2 = '-10';
    my $k3 = 'a';
    my $k4 =  '10.0';
    my $k5 ='２';
      
    my $validation = $vc->validation;
    if (!$vc->check($k1, 'int')) {
        $validation->add_failed('k1');
    }
    if (!$vc->check($k2, 'int')) {
      $validation->add_failed('k2');
    }
    if (!$vc->check($k3, 'int')) {
      $validation->add_failed('k3');
    }
    if (!$vc->check($k4, 'int')) {
      $validation->add_failed('k4');
    }
    if (!$vc->check($k5, 'int')) {
      $validation->add_failed('k5');
    }

    is_deeply($validation->failed, ['k3', 'k4', 'k5']);
  }
  
  # check - unsigned int
  {
    my $vc = Validator::Custom->new;
    my $k1 = '123456789';
    my $k2 = '-10';
    my $k3 = 'a';
    my $k4 =  '10.0';
    my $k5 ='２';
      
    my $validation = $vc->validation;
    if (!($vc->check($k1, 'int') && $k1 > 0)) {
        $validation->add_failed('k1');
    }
    if (!($vc->check($k2, 'int') && $k2 > 0)) {
      $validation->add_failed('k2');
    }
    if (!($vc->check($k3, 'int') && $k3 > 0)) {
      $validation->add_failed('k3');
    }
    if (!($vc->check($k4, 'int') && $k4 > 0)) {
      $validation->add_failed('k4');
    }
    if (!($vc->check($k5, 'int') && $k5 > 0)) {
      $validation->add_failed('k5');
    }

    is_deeply($validation->failed, ['k2', 'k3', 'k4', 'k5']);
  }

  # check - ascii_graphic
  {
    my $vc = Validator::Custom->new;
    my $k1 = '!~';
    my $k2 = ' ';
    my $k3 = "\0x7f";
      
    my $validation = $vc->validation;
    if (!$vc->check($k1, 'ascii_graphic')) {
      $validation->add_failed('k1');
    }
    if (!$vc->check($k2, 'ascii_graphic')) {
      $validation->add_failed('k2');
    }
    if (!$vc->check($k3, 'ascii_graphic')) {
      $validation->add_failed('k3');
    }
    
    is_deeply($validation->failed, ['k2', 'k3']);
  }

  # check - number
  {
    my $vc = Validator::Custom->new;
    my $k1 = '1';
    my $k2 = '123';
    my $k3 = '456.123';
    my $k4 = '-1';
    my $k5 = '-789';
    my $k6 = '-100.456';
    my $k7 = '-100.789';
    
    my $k8 = 'a';
    my $k9 = '1.a';
    my $k10 = 'a.1';
    my $k11 = '';
    my $k12;
    
    my $validation = $vc->validation;
    if (!$vc->check($k1, 'number')) {
      $validation->add_failed('k1');
    }
    if (!$vc->check($k2, 'number')) {
      $validation->add_failed('k2');
    }
    if (!$vc->check($k3, 'number')) {
      $validation->add_failed('k3');
    }
    if (!$vc->check($k4, 'number')) {
      $validation->add_failed('k4');
    }
    if (!$vc->check($k5, 'number')) {
      $validation->add_failed('k5');
    }
    if (!$vc->check($k6, 'number')) {
      $validation->add_failed('k6');
    }
    if (!$vc->check($k7, 'number')) {
      $validation->add_failed('k7');
    }
    if (!$vc->check($k8, 'number')) {
      $validation->add_failed('k8');
    }
    if (!$vc->check($k9, 'number')) {
      $validation->add_failed('k9');
    }
    if (!$vc->check($k10, 'number')) {
      $validation->add_failed('k10');
    }
    if (!$vc->check($k11, 'number')) {
      $validation->add_failed('k11');
    }
    if (!$vc->check($k12, 'number')) {
      $validation->add_failed('k12');
    }
    is_deeply($validation->failed, [qw/k8 k9 k10 k11 k12/]);
  }

  # check - in
  {
    my $vc = Validator::Custom->new;
    my $k1 = 'a';
    my $k2 = 'a';
    
    my $validation = $vc->validation;
    if (!($vc->check($k1, 'in', [qw/a b/]))) {
      $validation->add_failed('k1');
    }
    if (!($vc->check($k2, 'in', [qw/b c/]))) {
      $validation->add_failed('k2');
    }
    
    is_deeply($validation->failed, ['k2']);
  }
}

# filter
{
  # remove_blank filter
  {
    my $vc = Validator::Custom->new;
    my $k1 =[1, 2];
    my $k2 = [1, 3, '', ''];
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
    
    $k1 = $vc->filter($k1, 'trim');
    
    is($k1, '123');
  }
}

# add_check
{
  my $vc = Validator::Custom->new;
  $vc->add_check('equal' => sub {
    my ($vc, $value, $arg) = @_;
    
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
}

# add_filter
{
  my $vc = Validator::Custom->new;
  $vc->add_filter('cat' => sub {
    my ($vc, $value, $arg) = @_;
    
    return "$value$arg";
  });
  
  my $k1 = 'a';
  
  my $validation = $vc->validation;
  
  $k1 = $vc->filter($k1, 'cat', 'b');
  
  is($k1, 'ab');
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
}