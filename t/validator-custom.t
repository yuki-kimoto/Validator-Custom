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
  
  # check - uint
  {
    my $vc = Validator::Custom->new;
    my $k1 = '19';
    my $k2 = '-10';
    my $k3 = 'a';
    my $k4 =  '10.0';
    my $k5 ='２';
      
    my $validation = $vc->validation;
    if (!$vc->check($k1, 'uint')) {
        $validation->add_failed('k1');
    }
    if (!$vc->check($k2, 'uint')) {
      $validation->add_failed('k2');
    }
    if (!$vc->check($k3, 'uint')) {
      $validation->add_failed('k3');
    }
    if (!$vc->check($k4, 'uint')) {
      $validation->add_failed('k4');
    }
    if (!$vc->check($k5, 'uint')) {
      $validation->add_failed('k5');
    }

    is_deeply($validation->failed, ['k2', 'k3', 'k4', 'k5']);
  }

  # check - ascii
  {
    my $vc = Validator::Custom->new;
    my $k1 = '!~';
    my $k2 = ' ';
    my $k3 = "\0x7f";
      
    my $validation = $vc->validation;
    if (!$vc->check($k1, 'ascii')) {
      $validation->add_failed('k1');
    }
    if (!$vc->check($k2, 'ascii')) {
      $validation->add_failed('k2');
    }
    if (!$vc->check($k3, 'ascii')) {
      $validation->add_failed('k3');
    }
    
    is_deeply($validation->failed, ['k2', 'k3']);
  }

  # check - regex
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

  # check - decimal
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
    if (!$vc->check($k1, 'decimal', [2,3])) {
      $validation->add_failed('k1');
    }
    if (!$vc->check($k2, 'decimal', [1,3])) {
      $validation->add_failed('k2');
    }
    if (!$vc->check($k3, 'decimal', [2,2])) {
      $validation->add_failed('k3');
    }
    if (!$vc->check($k4, 'decimal', [2])) {
      $validation->add_failed('k4');
    }
    if (!$vc->check($k5, 'decimal', 2)) {
      $validation->add_failed('k5');
    }
    if (!$vc->check($k6, 'decimal', 2)) {
      $validation->add_failed('k6');
    }
    if (!$vc->check($k7, 'decimal')) {
      $validation->add_failed('k7');
    }
    if (!$vc->check($k8, 'decimal')) {
      $validation->add_failed('k8');
    }
    if (!$vc->check($k9, 'decimal')) {
      $validation->add_failed('k9');
    }
    if (!$vc->check($k10, 'decimal', [undef, 2])) {
      $validation->add_failed('k10');
    }
    if (!$vc->check($k11, 'decimal', [undef, 2])) {
      $validation->add_failed('k11');
    }
    if (!$vc->check($k12, 'decimal', [2, undef])) {
      $validation->add_failed('k12');
    }
    if (!$vc->check($k13, 'decimal', [2, undef])) {
      $validation->add_failed('k13');
    }

    is_deeply($validation->failed, [qw/k2 k3 k5 k6 k8 k9 k11 k13/]);
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

  # filter - trim;
  {
    my $vc = Validator::Custom->new;
    
    my $k1 = ' 123 ';
    my $k2 = "  \n a \r\n b\nc  \t";
    my $k3 = '  abc  ';
    my $k4 = '  def  ';
    
    $k1 = $vc->filter($k1, 'trim');
    $k2 = $vc->filter($k2, 'trim_collapse');
    $k3 = $vc->filter($k3, 'trim_lead');
    $k4 = $vc->filter($k4, 'trim_trail');
    
    is($k1, '123');
    is($k2, "a b c");
    is($k3, "abc  ");
    is($k4, '  def');
  }

  # filter - trim_uni
  {
    my $vc = Validator::Custom->new;
    my $k1 = '　　123　　';
    my $k2 = "　　\n a \r\n b\nc  \t　　";
    my $k3 = '　　abc　　';
    my $k4 = '　　def　　';
    
    $k1 = $vc->filter($k1, 'trim_uni');
    $k2 = $vc->filter($k2, 'trim_uni_collapse');
    $k3 = $vc->filter($k3, 'trim_uni_lead');
    $k4 = $vc->filter($k4, 'trim_uni_trail');
    
    is($k1, '123');
    is($k2, "a b c");
    is($k3, "abc　　");
    is($k4, '　　def');
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