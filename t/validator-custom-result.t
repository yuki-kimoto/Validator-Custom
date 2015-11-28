use Test::More 'no_plan';

use strict;
use warnings;
use utf8;
use Validator::Custom;

my $vc = Validator::Custom->new;

# add failed
{
  # add failed - add one failed name
  {
    my $validation = $vc->validation;
    $validation->add_failed('k1');
    ok(!$validation->is_valid);
    ok(!$validation->is_valid('k1'));
    is($validation->message('k1'), 'k1 is invalid');
    is_deeply($validation->failed, ['k1']);
  }

  # add failed - add one failed name with message
  {
    my $validation = $vc->validation;
    $validation->add_failed('k1' => 'k1 is wrong value');
    ok(!$validation->is_valid);
    ok(!$validation->is_valid('k1'));
    is($validation->message('k1'), 'k1 is wrong value');
    is_deeply($validation->failed, ['k1']);
  }
}
