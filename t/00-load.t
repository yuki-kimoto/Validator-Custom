#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Validator::Custom' );
}

diag( "Testing Validator::Custom $Validator::Custom::VERSION, Perl $], $^X" );
