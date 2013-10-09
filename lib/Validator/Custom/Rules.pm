package Validator::Custom::Rules;
use Object::Simple -base;

has rules;

sub add {
  
}

sub get {
  
}

=head1 NAME

Validator::Custom::Rules - Rules

=head1 SYNOPSYS
  
  # Rules object
  my $rules = Validator::Custom::Rules->new;
  
  # Add rule
  $rules->add(user => [
    id => [
      'not_blank',
      'ascii'
    ],
    name => [
      'not_blank',
      {length => [1, 30]}
    ],
    age => [
      'uint'
    ]
  ]);
  
  # Define rule filter
  $rules->filter('user' => {
    insert => ['name', 'age'],
    update => ['id', 'name', 'age'],
    delete => ['id']
  });
  
  # Get rule
  my $rule_insert_user = $rules->get('user', 'insert');
  my $rule_update_user = $rules->get('user', 'update');
  my $rule_delete_user = $rules->get('user', 'delete');

=head2 DESCRIPTION

Validation::Custom::Rules is class to store and retreive rule set.

 
