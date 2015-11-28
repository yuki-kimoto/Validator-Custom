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
  # check - uint
  {
    my $vc = Validator::Custom->new;
    my $k1 = '19';
    my $k2 = '-10';
    my $k3 = 'a';
    my $k4 =  '10.0';
    my $k5 ='２';
      
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
    if (!$vc->check('uint', $k5)) {
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

  # check - in
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
}

# filter
{
  # remove_blank filter
  {
    my $vc = Validator::Custom->new;
    my $k1 =[1, 2];
    my $k2 = [1, 3, '', ''];
    my $k3 = [];
    
    $k1 = $vc->filter('remove_blank', $k1);
    $k2 = $vc->filter('remove_blank', $k2);
    $k3 = $vc->filter('remove_blank', $k3);
    
    is_deeply($k1, [1, 2]);
    is_deeply($k2, [1, 3]);
    is_deeply($k3, []);
  }
  
  # filter - remove_blank, exception
  {
    my $vc = Validator::Custom->new;
    my $k1 = 1;
    eval {$k1 = $vc->filter('remove_blank', $k1)};
    like($@, qr/must be array reference/);
  }

  # filter - trim;
  {
    my $vc = Validator::Custom->new;
    
    my $k1 = ' 123 ';
    my $k2 = "  \n a \r\n b\nc  \t";
    my $k3 = '  abc  ';
    my $k4 = '  def  ';
    
    $k1 = $vc->filter('trim', $k1);
    $k2 = $vc->filter('trim_collapse', $k2);
    $k3 = $vc->filter('trim_lead', $k3);
    $k4 = $vc->filter('trim_trail', $k4);
    
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
    
    $k1 = $vc->filter('trim_uni', $k1);
    $k2 = $vc->filter('trim_uni_collapse', $k2);
    $k3 = $vc->filter('trim_uni_lead', $k3);
    $k4 = $vc->filter('trim_uni_trail', $k4);
    
    is($k1, '123');
    is($k2, "a b c");
    is($k3, "abc　　");
    is($k4, '　　def');
  }
}
