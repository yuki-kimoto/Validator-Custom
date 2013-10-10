package Validator::Custom::Rule;
use Object::Simple -base;

has 'rule';

sub parse {
  my ($self, $rule, $shared_rule) = @_;
  
  $shared_rule ||= [];
  
  my $normalized_rule = [];
  
  for (my $i = 0; $i < @{$rule}; $i += 2) {
    
    my $r = {};
    
    # Key, options, and constraints
    my $key = $rule->[$i];
    my $option = $rule->[$i + 1];
    my $constraints;
    if (ref $option eq 'HASH') {
      $constraints = $rule->[$i + 2];
      $i++;
    }
    else {
      $constraints = $option;
      $option = {};
    }
    my $constraints_h = [];
    
    if (ref $constraints eq 'ARRAY') {
      for my $constraint (@$constraints, @$shared_rule) {
        my $constraint_h = {};
        if (ref $constraint eq 'ARRAY') {
          $constraint_h->{constraint} = $constraint->[0];
          $constraint_h->{message} = $constraint->[1];
        }
        else {
          $constraint_h->{constraint} = $constraint;
        }
        push @$constraints_h, $constraint_h;
      }
    } else {
      $constraints_h = {
        'ERROR' => {
          value => $constraints,
          message => 'Constraints must be array reference'
        }
      };
    }
    
    $r->{key} = $key;
    $r->{constraints} = $constraints_h;
    $r->{option} = $option;
    
    push @$normalized_rule, $r;
  }
  
  $self->rule($normalized_rule);
  
  return $self;
}

1;

=head1 NAME

Validator::Custom::Rule - Rule object

=head1 SYNOPSYS
  
  # Create rule object and parse rule
  my $rule_obj = Validator::Custom::Rule->new;
  my $rule = [
    id => [
      'ascii'
    ],
    name => [
      'not_blank'
    ]
  ]
  $rule_obj->parse($rule);
  
  # Pass rule object to validate method
  my $vc = Validator::Custom->new;
  my $data = {id => '001', name => 'kimoto'};
  my $result = $vc->validate($data, $rule_obj);

  # Usual way is shortcut of above
  my $result2 = $vc->validate($date, $rule);
  
=head1 DESCRIPTION

Validator::Custom::Rule is the class to parse rule and store it as object.

=head1 ATTRIBUTES

=head2 rule

  my $content = $rule_obj->rule;
  $rule_obj = $rule->rule($content);

Content of rule object.

=head1 METHODS

=head2 parse

  $rule_obj = $rule_obj->parse($rule);

Parse rule and store it to C<rule> attribute.
