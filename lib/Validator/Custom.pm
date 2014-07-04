package Validator::Custom;
use Object::Simple -base;
use 5.008001;
our $VERSION = '0.23';

use Carp 'croak';
use Validator::Custom::Constraint;
use Validator::Custom::Result;
use Validator::Custom::Rule;
use Validator::Custom::Constraints;

has ['data_filter', 'rule', 'rule_obj'];
has error_stock => 1;

sub create_rule { Validator::Custom::Rule->new }

sub js_fill_form_button {
  my ($self, $rule) = @_;
  
  my $r = $self->_parse_random_string_rule($rule);
  
  require JSON;
  my $r_json = JSON->new->encode($r);
  
  my $javascript = << "EOS";
(function () {

  var rule = $r_json;

  var create_random_value = function (rule, name) {
    var patterns = rule[name];
    if (patterns === undefined) {
      return "";
    }
    
    var value = "";
    for (var i = 0; i < patterns.length; i++) {
      var pattern = patterns[i];
      var num = Math.floor(Math.random() * pattern.length);
      value = value + pattern[num];
    }
    
    return value;
  };
  
  var addEvent = (function(){
    if(document.addEventListener) {
      return function(node,type,handler){
        node.addEventListener(type,handler,false);
      };
    } else if (document.attachEvent) {
      return function(node,type,handler){
        node.attachEvent('on' + type, function(evt){
          handler.call(node, evt);
        });
      };
    }
  })();
  
  var button = document.createElement("input");
  button.setAttribute("type","button");
  button.value = "Fill Form";
  document.body.insertBefore(button, document.body.firstChild)

  addEvent(
    button,
    "click",
    function () {
      
      var input_elems = document.getElementsByTagName('input');
      var radio_names = {};
      var checkbox_names = {};
      for (var i = 0; i < input_elems.length; i++) {
        var e = input_elems[i];

        var name = e.getAttribute("name");
        var type = e.getAttribute("type");
        if (type === "text" || type === "hidden" || type === "password") {
          var value = create_random_value(rule, name);
          e.value = value;
        }
        else if (type === "checkbox") {
          e.checked = Math.floor(Math.random() * 2) ? true : false;
        }
        else if (type === "radio") {
          radio_names[name] = 1;
        }
      }
      
      for (name in radio_names) {
        var elems = document.getElementsByName(name);
        var num = Math.floor(Math.random() * elems.length);
        elems[num].checked = true;
      }
      
      var textarea_elems = document.getElementsByTagName("textarea");
      for (var i = 0; i < textarea_elems.length; i++) {
        var e = textarea_elems[i];
        
        var name = e.getAttribute("name");
        var value = create_random_value(rule, name);
        
        var text = document.createTextNode(value);
        
        if (e.firstChild) {
          e.removeChild(e.firstChild);
        }
        
        e.appendChild(text);
      }
      
      var select_elems = document.getElementsByTagName("select");
      for (var i = 0; i < select_elems.length; i++) {
        var e = select_elems[i];
        var options = e.options;
        if (e.multiple) {
          for (var k = 0; k < options.length; k++) {
            options[k].selected = Math.floor(Math.random() * 2) ? true : false;
          }
        }
        else {
          var num = Math.floor(Math.random() * options.length);
          e.selectedIndex = num;
        }
      }
    }
  );
})();
EOS

  return $javascript;
}

sub new {
  my $self = shift->SUPER::new(@_);

  $self->register_constraint(
    any               => sub { 1 },
    ascii             => \&Validator::Custom::Constraint::ascii,
    between           => \&Validator::Custom::Constraint::between,
    blank             => \&Validator::Custom::Constraint::blank,
    date_to_timepiece => \&Validator::Custom::Constraint::date_to_timepiece,
    datetime_to_timepiece => \&Validator::Custom::Constraint::datetime_to_timepiece,
    decimal           => \&Validator::Custom::Constraint::decimal,
    defined           => sub { defined $_[0] },
    duplication       => \&Validator::Custom::Constraint::duplication,
    equal_to          => \&Validator::Custom::Constraint::equal_to,
    greater_than      => \&Validator::Custom::Constraint::greater_than,
    http_url          => \&Validator::Custom::Constraint::http_url,
    int               => \&Validator::Custom::Constraint::int,
    in_array          => \&Validator::Custom::Constraint::in_array,
    length            => \&Validator::Custom::Constraint::length,
    less_than         => \&Validator::Custom::Constraint::less_than,
    merge             => \&Validator::Custom::Constraint::merge,
    not_defined       => \&Validator::Custom::Constraint::not_defined,
    not_space         => \&Validator::Custom::Constraint::not_space,
    not_blank         => \&Validator::Custom::Constraint::not_blank,
    uint              => \&Validator::Custom::Constraint::uint,
    regex             => \&Validator::Custom::Constraint::regex,
    selected_at_least => \&Validator::Custom::Constraint::selected_at_least,
    shift             => \&Validator::Custom::Constraint::shift_array,
    space             => \&Validator::Custom::Constraint::space,
    to_array          => \&Validator::Custom::Constraint::to_array,
    trim              => \&Validator::Custom::Constraint::trim,
    trim_collapse     => \&Validator::Custom::Constraint::trim_collapse,
    trim_lead         => \&Validator::Custom::Constraint::trim_lead,
    trim_trail        => \&Validator::Custom::Constraint::trim_trail,
    trim_uni          => \&Validator::Custom::Constraint::trim_uni,
    trim_uni_collapse => \&Validator::Custom::Constraint::trim_uni_collapse,
    trim_uni_lead     => \&Validator::Custom::Constraint::trim_uni_lead,
    trim_uni_trail    => \&Validator::Custom::Constraint::trim_uni_trail
  );
  
  return $self;
}

sub register_constraint {
  my $self = shift;
  
  # Merge
  my $constraints = ref $_[0] eq 'HASH' ? $_[0] : {@_};
  $self->constraints({%{$self->constraints}, %$constraints});
  
  return $self;
}

our %VALID_OPTIONS = map {$_ => 1} qw/message default copy require/;

sub validate {
  my ($self, $data, $rule) = @_;
  
  # Class
  my $class = ref $self;
  
  # Validation rule
  $rule ||= $self->rule;
  
  # Data filter
  my $filter = $self->data_filter;
  $data = $filter->($data) if $filter;
  
  # Check data
  croak "First argument must be hash ref"
    unless ref $data eq 'HASH';
  
  # Check rule
  unless (ref $rule eq 'Validator::Custom::Rule') {
    croak "Invalid rule structure" unless ref $rule eq 'ARRAY';
  }
  
  # Result
  my $result = Validator::Custom::Result->new;
  $result->{_error_infos} = {};
  
  # Save raw data
  $result->raw_data($data);
  
  # Error is stock?
  my $error_stock = $self->error_stock;
  
  # Valid keys
  my $valid_keys = {};
  
  # Error position
  my $pos = 0;
  
  # Found missing parameters
  my $found_missing_params = {};
  
  # Shared rule
  my $shared_rule = $self->shared_rule;
  warn "DBIx::Custom::shared_rule is DEPRECATED!"
    if @$shared_rule;
  
  if (ref $rule eq 'Validator::Custom::Rule') {
    $self->rule_obj($rule);
  }
  else {
    my $rule_obj = Validator::Custom::Rule->new;
    $rule_obj->parse($rule, $shared_rule);
    $self->rule_obj($rule_obj);
  }
  my $rule_obj = $self->rule_obj;

  # Process each key
  OUTER_LOOP:
  for (my $i = 0; $i < @{$rule_obj->rule}; $i++) {
    
    my $r = $rule_obj->rule->[$i];
    
    # Increment position
    $pos++;
    
    # Key, options, and constraints
    my $key = $r->{key};
    my $opts = $r->{option};
    my $constraints = $r->{constraints};
    
    # Check constraints
    croak "Invalid rule structure"
      unless ref $constraints eq 'ARRAY';
    
    # Arrange key
    my $result_key = $key;
    if (ref $key eq 'HASH') {
      my $first_key = (keys %$key)[0];
      $result_key = $first_key;
      $key         = $key->{$first_key};
    }
    
    # Real keys
    my $keys;
    
    if (ref $key eq 'ARRAY') { $keys = $key }
    elsif (ref $key eq 'Regexp') {
      $keys = [];
      for my $k (keys %$data) {
         push @$keys, $k if $k =~ /$key/;
      }
    }
    else { $keys = [$key] }
    
    # Check option
    for my $oname (keys %$opts) {
      croak qq{Option "$oname" of "$result_key" is invalid name}
        unless $VALID_OPTIONS{$oname};
    }
    
    # Is data copy?
    my $copy = 1;
    $copy = $opts->{copy} if exists $opts->{copy};
    
    # Check missing parameters
    my $require = exists $opts->{require} ? $opts->{require} : 1;
    my $found_missing_param;
    my $missing_params = $result->missing_params;
    for my $key (@$keys) {
      unless (exists $data->{$key}) {
        if ($require) {
          push @$missing_params, $key
            unless $found_missing_params->{$key};
          $found_missing_params->{$key}++;
        }
        $found_missing_param = 1;
      }
    }
    if ($found_missing_param) {
      $result->data->{$result_key} = ref $opts->{default} eq 'CODE'
          ? $opts->{default}->($self) : $opts->{default}
        if exists $opts->{default} && $copy;
      next if $opts->{default} || !$require;
    }
    
    # Already valid
    next if $valid_keys->{$result_key};
    
    # Validation
    my $value = @$keys > 1
      ? [map { $data->{$_} } @$keys]
      : $data->{$keys->[0]};

    for my $c (@$constraints) {
      
      # Arrange constraint information
      my $constraint = $c->{constraint};
      my $message = $c->{message};
      
      # Data type
      my $data_type = {};
      
      # Arguments
      my $arg;
      
      # Arrange constraint
      if(ref $constraint eq 'HASH') {
        my $first_key = (keys %$constraint)[0];
        $arg        = $constraint->{$first_key};
        $constraint = $first_key;
      }
      
      # Constraint function
      my $cfuncs;
      my $negative;
      
      # Sub reference
      if( ref $constraint eq 'CODE') {
        # Constraint function
        $cfuncs = [$constraint];
      }
      
      # Constraint key
      else {
        # Constraint information
        my $cinfo = $self->_parse_constraint($constraint);
        $data_type->{array} = 1 if $cinfo->{array};
                                        
        # Constraint function
        $cfuncs = $cinfo->{funcs};
      }
      
      # Is valid?
      my $is_valid;
      
      # Data is array
      if($data_type->{array}) {
          
        # To array
        $value = [$value] unless ref $value eq 'ARRAY';
        
        # Validation loop
        for (my $k = 0; $k < @$value; $k++) {
          my $data = $value->[$k];
          
          # Validation
          for (my $j = 0; $j < @$cfuncs; $j++) {
            my $cfunc = $cfuncs->[$j];
            
            # Validate
            my $cresult;
            {
              local $_ = Validator::Custom::Constraints->new(
                constraints => $self->constraints
              );
              $cresult= $cfunc->($data, $arg, $self);
            }
            
            # Constrint result
            my $v;
            if (ref $cresult eq 'ARRAY') {
              ($is_valid, $v) = @$cresult;
              $value->[$k] = $v;
            }
            elsif (ref $cresult eq 'HASH') {
              $is_valid = $cresult->{result};
              $message = $cresult->{message} unless $is_valid;
              $value->[$k] = $cresult->{output} if exists $cresult->{output};
            }
            else { $is_valid = $cresult }
            
            last if $is_valid;
          }
          
          # Validation error
          last unless $is_valid;
        }
      }
      
      # Data is scalar
      else {
        # Validation
        for my $cfunc (@$cfuncs) {
        
          my $cresult;
          {
            local $_ = Validator::Custom::Constraints->new(
              constraints => $self->constraints
            );
            $cresult = $cfunc->($value, $arg, $self);
          }
          
          if (ref $cresult eq 'ARRAY') {
            my $v;
            ($is_valid, $v) = @$cresult;
            $value = $v if $is_valid;
          }
          elsif (ref $cresult eq 'HASH') {
            $is_valid = $cresult->{result};
            $message = $cresult->{message} unless $is_valid;
            $value = $cresult->{output} if exists $cresult->{output} && $is_valid;
          }
          else { $is_valid = $cresult }
          
          last if $is_valid;
        }
      }
      
      # Add error if it is invalid
      unless ($is_valid) {
        # Resist error info
        $message = $opts->{message} unless defined $message;
        $result->{_error_infos}->{$result_key} = {
          message      => $message,
          position     => $pos,
          reason       => $constraint,
          original_key => $key
        } unless exists $result->{_error_infos}->{$result_key};
        
        # Set default value
        $result->data->{$result_key} = ref $opts->{default} eq 'CODE'
                                     ? $opts->{default}->($self)
                                     : $opts->{default}
          if exists $opts->{default} && $copy;
        
        # No Error stock
        unless ($error_stock) {
          # Check rest constraint
          my $found;
          for (my $k = $i + 1; $k < @{$rule_obj->rule}; $k++) {
            my $r_next = $rule_obj->rule->[$k];
            my $key_next = $r_next->{key};
            $key_next = (keys %$key)[0] if ref $key eq 'HASH';
            $found = 1 if $key_next eq $result_key;
          }
          last OUTER_LOOP unless $found;
        }
        next OUTER_LOOP;
      }
    }
    
    # Result data
    $result->data->{$result_key} = $value if $copy;
    
    # Key is valid
    $valid_keys->{$result_key} = 1;
    
    # Remove invalid key
    delete $result->{_error_infos}->{$key};
  }
  
  return $result;
}

sub _parse_constraint {
  my ($self, $constraint) = @_;
  
  # Constraint information
  my $cinfo = {};
  
  # Simple constraint name
  unless ($constraint =~ /\W/) {
    my $cfunc = $self->constraints->{$constraint} || '';
    croak qq{"$constraint" is not registered}
      unless ref $cfunc eq 'CODE';
    $cinfo->{funcs} = [$cfunc];
    return $cinfo;
  }

  # Trim space
  $constraint ||= '';
  $constraint =~ s/^\s+//;
  $constraint =~ s/\s+$//;
  
  # Target is array elements
  $cinfo->{array} = 1 if $constraint =~ s/^@//;
  croak qq{"\@" must be one at the top of constrinat name}
    if index($constraint, '@') > -1;
  
  # Constraint functions
  my @cfuncs;
  
  # Constraint names
  my @cnames = split(/\|\|/, $constraint);
  
  # Convert constraint names to constraint functions
  for my $cname (@cnames) {
    $cname ||= '';
    
    # Trim space
    $cname =~ s/^\s+//;
    $cname =~ s/\s+$//;
    
    # Negative
    my $negative = $cname =~ s/^!// ? 1 : 0;
    croak qq{"!" must be one at the top of constraint name}
      if index($cname, '!') > -1;
    
    # Trim space
    $cname =~ s/^\s+//;
    $cname =~ s/\s+$//;
    
    # Constraint function
    croak "Constraint name '$cname' must be [A-Za-z0-9_]"
      if $cname =~ /\W/;
    my $cfunc = $self->constraints->{$cname} || '';
    croak qq{"$cname" is not registered}
      unless ref $cfunc eq 'CODE';
    
    # Negativate
    my $f = $negative ? sub {
      my $ret = $cfunc->(@_);
      if (ref $ret eq 'ARRAY') {
        $ret->[0] = ! $ret->[0];
        return $ret;
      }
      else { return !$ret }
    } : $cfunc;
    
    # Add
    push @cfuncs, $f;
  }
  
  $cinfo->{funcs} = \@cfuncs;
  
  return $cinfo;
}

sub _parse_random_string_rule {
  my $self = shift;
  
  # Rule
  my $rule = ref $_[0] eq 'HASH' ? $_[0] : {@_};
  
  # Result
  my $result = {};
  
  # Parse string rule
  for my $name (keys %$rule) {
    # Pettern
    my $pattern = $rule->{$name};
    $pattern = '' unless $pattern;
    
    # State
    my $state = 'character';

    # Count
    my $count = '';
    
    # Chacacter sets
    my $csets = [];
    my $cset = [];
    
    # Parse pattern
    my $c;
    while (defined ($c = substr($pattern, 0, 1, '')) && length $c) {
      # Character class
      if ($state eq 'character_class') {
        if ($c eq ']') {
          $state = 'character';
          push @$csets, $cset;
          $cset = [];
          $state = 'character';
        }
        else { push @$cset, $c }
      }
      
      # Count
      elsif ($state eq 'count') {
        if ($c eq '}') {
          $count = 1 if $count < 1;
          for (my $i = 0; $i < $count - 1; $i++) {
              push @$csets, [@{$csets->[-1] || ['']}];
          }
          $count = '';
          $state = 'character';
        }
        else { $count .= $c }
      }
      
      # Character
      else {
        if ($c eq '[') { $state = 'character_class' }
        elsif ($c eq '{') { $state = 'count' }
        else { push @$csets, [$c] }
      }
    }
    
    # Add Charcter sets
    $result->{$name} = $csets;
  }
  
  return $result;
}

# DEPRECATED!
has shared_rule => sub { [] };
# DEPRECATED!
__PACKAGE__->dual_attr('constraints',
  default => sub { {} }, inherit => 'hash_copy');

1;

=head1 NAME

Validator::Custom - HTML form Validation, easy and flexibly

=head1 SYNOPSYS

  use Validator::Custom;
  my $vc = Validator::Custom->new;
  
  # Data
  my $data = {id => 1, name => 'Ken Suzuki', age => 19};

  # Create Rule
  my $rule = $vc->create_rule;
  
  # Rule syntax - integer, have error message
  $rule->require('id')->check(
    'int'
  )->message('id should be integer');
  
  # Rule syntax - not blank, length is 1 to 5, have error messages
  $rule->require('name')->check(
    ['not_blank' => 'name is emtpy'],
    [{length => [1, 5]} => 'name is too long']
  );
  
  # Rule syntax - value is optional, default is 20
  $rule->optional('age')->check(
    'int'
  )->default(20);
  
  # Validation
  my $result = $vc->validate($data, $rule);
  if ($result->is_ok) {
    # Safety data
    my $safe_data = $vresult->data;
  }
  else {
    # Error messgaes
    my $errors = $vresult->messages;
  }
  
  # You original constraint(you can call constraint from $_)
  my $blank_or_number = sub {
    my $value = shift;
    return $_->blank($value) || $_->regex($value, qr/[0-9]+/);
  };
  $rule->require('age')->check(
    [$blank_or_number => 'age must be blank or number']
  );
  
  # Rule old syntax
  my $rule = [
    id => {message => 'id should be integer'} => [
      'int'
    ],
    name => [
      ['not_blank' => 'name is emtpy'],
      [{length => [1, 5]} => 'name is too long']
    ],
    age => {require => 0, default => 20} => [
      ['not_blank' => 'age is empty.'],
      ['int' => 'age must be integer']
    ]
  ];
  
=head1 DESCRIPTION

L<Validator::Custom> validate HTML form data easy and flexibly.
The features are the following ones.

=over 4

=item *

Many constraint functions are available by default, such as C<not_blank>,
C<int>, C<defined>, C<in_array>, C<length>.

=item *

Several filter functions are available by default, such as C<trim>,
C<datetime_to_timepiece>, C<date_to_timepiece>.

=item *

You can register your constraint function.

=item *

You can set error messages for invalid parameter value.
The order of messages is kept.

=item *

Support C<OR> condition constraint and negative constraint,

=back

=head1 GUIDE

=head2 1. Basic

B<1. Create a new Validator::Custom object>

  use Validator::Custom;
  my $vc = Validator::Custom->new;

B<2. Prepare data for validation>

  my $data = {age => 19, name => 'Ken Suzuki'};

Data must be hash reference.

B<3. Prepare a rule for validation>

  my $ruel = $vc->create_rule;
  $rule->require('age')->message('age must be integer')->check(
    'not_blank',
    'int'
  );
  $rule->require('name')->check(
    ['not_blank' => 'name is empty']
    [{length => [1, 5]} => 'name must be length 1 to 5']
  );

Please see L<Validator::Custom/"RULE"> about rule syntax.

You can use many constraint function,
such as C<int>, C<not_blank>, C<length>.
See L<Validator::Custom/"CONSTRAINTS">
to know all constraint functions.

Rule details is explained in L</"3. Rule syntax"> section.

B<4. Validate data>
  
  my $result = $vc->validate($data, $rule);

use C<validate()> to validate the data applying the rule.
C<validate()> return L<Validator::Custom::Result> object.

B<5. Manipulate the validation result>

  unless ($result->is_ok) {
    if ($result->has_missing) {
      my $missing_params = $result->missing_params;
    }
    
    if ($result->has_invalid) {
      my $messages = $result->messages_to_hash;
    }
  }

If you check the data is completely valid, use C<is_ok()>.
C<is_ok()> return true value
if invalid parameter values is not found and all parameter
names specified in the rule is found in the data.

If at least one of parameter names specified in the rule
is not found in the data,
C<has_missing()> return true value.

You can get missing parameter names using C<missing_params()>.
In this example, return value is the following one.

  ['price']

If at least one of parameter value is invalid,
C<has_invalid()> return true value.

You can get the pairs of invalid parameter name and message
using C<messages_to_hash()>.
In this example, return value is the following one.

  {
    name => 'name must be string. the length 1 to 5'
  }

L<Validator::Custom::Result> details is explained
in L</"2. Validation result">.

=head2 2. Validation result

C<validate()> return L<Validator::Custom::Result> object.
You can manipulate the result by various methods.

C<is_ok()>, C<has_missing()>, C<has_invalid()>, C<missing_params()>,
C<messages_to_hash()> is already explained in L</"1. Basic">

The following ones is often used methods.

B<data()>

  my $data = $result->data;

Get the data in the end state. L<Validator::Custom> has filtering ability.
The parameter values in data passed to C<validate()>
is maybe converted to other data by filter.
You can get filtered data using C<data()>.

B<messages()>

  my $messages = $result->messages;

Get messages corresponding to the parameter names which value is invalid.
Messages keep the order of parameter names of the rule.

B<message()>

  my $message = $result->message('name');

Get a message corresponding to the parameter name which value is invalid.

All L<Validator::Custom::Result>'s APIs is explained
in the POD of L<Validator::Custom::Result>

=head2 RULE

  # Create Rule
  my $rule = $vc->create_rule;
  
  # Rule syntax - integer, have error message
  $rule->require('id')->check(
    'int'
  )->message('id should be integer');
  
  # Rule syntax - not blank, length is 1 to 5, have error messages
  $rule->require('name')->check(
    ['not_blank' => 'name is emtpy'],
    [{length => [1, 5]} => 'name is too long']
  );
  
  # Rule syntax - value is optional, default is 20
  $rule->optional('age')->check(
    'int'
  )->default(20);

Rule is L<Validator::Custom::Rule> ojbect.
You can create C<create_rule> method of L<Validator::Custom>.

  my $rule = $vc->create_rule

At first you set topic, C<require> method or C<optional> method.
If the value is required, you use C<require> method.
If the value is not always required, you use C<optional> method.
  
  # Required
  $rule->require('age');
  
  # Optional
  $rule->optional('age');

If you set topic to multiple keys, you should set key name by C<name> method.

  # Key name
  $rule->require(['mail1', 'mail2'])->name('mail');

You can set options, C<message>, C<default>, and C<copy>.

=over 4

=item 1. message

 $rule->require('age')->message('age is invalid');

Message corresponding to the parameter name which value is invalid. 

=item 2. default

  $rule->require('age')->default(5)

Default value. This value is automatically set to result data
if the parameter value is invalid or the parameter name specified in rule is missing in the data.

=item 3. copy

  $rule->require('age')->copy(0)

If this value is 0, The parameter value is not copied to result data. 
Default to 1. Parameter value is copied to the data.

=back

You set constraints by C<check> method.

  $rule->require('age')->check(
    {'length' => [1, 5]}
  );

You can set message for each constraint function

  $rule->require('name')->check(
    ['not_blank' => 'name must be not blank'],
    [{length => [1, 5]} => 'name must be 1 to 5 length']
  );

You can create original constraint function using
original constraints.
you can call constraints from $_ in subroutine.

  # You original constraint(you can call constraint from $_)
  my $blank_or_number = sub {
    my $value = shift;
    return $_->blank($value) || $_->regex($value, qr/[0-9]+/);
  };
  my $rule = [
    name => [
      [$blank_or_number => 'name must be blank or number']
    ]
  ];

=head3 Multiple parameters validation

Multiple parameters validation is available.

  Data: {password1 => 'xxx', password2 => 'xxx'}
  Rule: require([qw/password1 password2/])->name('password_check)
          ->check('duplication')

In this example, We check if 'password1' and 'password2' is same.
The following value is passed to constraint function C<duplication>.

  ['xxx', 'xxx']

You must specify new key, such as C<password_check>.
This is used by L<Validator::Result> object.

You can also use the reference of regular expression if you need.

  Data: {person1 => 'Taro', person2 => 'Rika', person3 => 'Ken'}
  Rule: require(qr/^person/)->name('merged_person')
          ->check('merge') # TaroRikaKen

All matched value is passed to constraint function as array reference.
In this example, the following value is passed.

  ['Taro', 'Rika', 'Ken']

=head3 Negative constraint function

You can negative a constraint function

  Rule: require('age')->check('!int')

"!" is added to the head of the constraint name
if you negative a constraint function.
'!int' means not 'int'.

In this example, 

=head3 "OR" of constraint functions

You can create "OR" of constraint functions

  Rule: require('email')->check('blank || email')

Use "||" to create "OR" of constraint functions.
'blank || email' means 'blank' or 'email'.

You can combine "||" and "!".

  Rule: require('email')->check('blank || !int')

=head3 Array validation

You can check if all the elements of array is valid.

  Data: {nums => [1, 2, 3]}
  Rule: require('nums')->check('@int')

"@" is added to the head of constraint function name
to validate all the elements of array.

=head2 4. Constraint functions

=head3 Register constraint function

L<Validator::Custom> has various constraint functions.
You can see constraint functions registered by default
L<Validator::Custom/"CONSTRAINTS">.

and you can register your constraint function if you need.

  $vc->register_constraint(
    telephone => sub {
      my $value = shift;
      
      my $is_valid;
      if ($value =~ /^[\d-]+$/) {
        $is_valid = 1;
      }
      return $is_valid;
    }
  );

Constraint function for telephone number is registered.

Constraint function receive a scalar value as first argument and
return boolean value which check if the value is valid.

Constraint function receive argument of constraint function as second argument
and L<Validator::Custom> object as third argument.

  $vc->register_constraint(
    telephone => sub {
      my ($value, $arg, $vc) = @_;
      
      return $is_valid;
    }
  );

If you know the implementations of constraint functions,
see the source of L<Validator::Custom::Constraint>.

If you want to return custom message, you can use hash reference as return value.

  $vc->register_constraint(
    telephone => sub {
      my ($value, $arg, $vc) = @_;
      
      # Process
      my $is_valid = ...;
      
      if ($is_valid) {
        return 1;
      }
      else {
        return {result => 0, message => 'Custom error message'};
      }
    }
  );

=head3 Register filter function

C<register_constraint()> is also used to register filter function.

Filter function is same as constraint function except for return value;

  $vc->register_constraint(
    to_upper_case => sub {
      my $value = shift;
      
      $value = uc $value;
                  
      return {result => 1, output => $value};
    }
  );

Return value of filter function must be array reference.
First element is boolean value which check if the value is valid.
Second element is filtered value.

In this example, First element of array reference is set to 1
because this function is intended to filter only.

You can also use array reference representation.
This is old syntax. I recommend hash reference.
  
  # This is old syntax
  $vc->register_constraint(
    to_upper_case => sub {
      my $value = shift;
      
      $value = uc $value;
                  
      return [1, $value];
    }
  );

=head2 Old rule syntax

This is rule old syntax. Plese use new rule syntax.

=head3 Basic

Rule has specified structure.

Rule must be array reference. 

  my $rule = [
  
  ];

This is for keeping the order of
parameter names.

Rule has pairs of parameter name and constraint functions.

  my $rule = [
    age =>  [            # parameter name1
      'not_blank',       #   constraint function1
      'int'              #   constraint function2
    ],                                                   
                                                         
    name => [              # parameter name2       
      'not_blank',         #   constraint function1
      {'length' => [1, 5]} #   constraint function2
    ]
  ];

Constraint function can receive arguments using hash reference.

  my $rule = [
    name => [
        {'length' => [1, 5]}
    ]
  ];

You can set message for each constraint function

  my $rule = [
    name => [
        ['not_blank', 'name must be not blank'],
        [{length => [1, 5]}, 'name must be 1 to 5 length']
    ]
  ];

You can pass subroutine reference as constraint.

  # You original constraint(you can call constraint from $_)
  my $blank_or_number = sub {
    my $value = shift;
    return $_->blank($value) || $_->regex($value, qr/[0-9]+/);
  };
  my $rule = [
    name => [
      [$blank_or_number => 'name must be blank or number']
    ]
  ];

=head3 Option

You can set options for each parameter name.

  my $rule = [
           # Option
    age => {message => 'age must be integer'} => [
        'not_blank',
    ]
  ];

Option is located after the parameter name,
and option must be hash reference.

The following options is available.

=over 4

=item 1. message

 {message => "This is invalid"}

Message corresponding to the parameter name which value is invalid. 

=item 2. default

  {default => 5}

Default value. This value is automatically set to result data
if the parameter value is invalid or the parameter name specified in rule is missing in the data.

=item 3. copy

  {copy => 0}

If this value is 0, The parameter value is not copied to result data. 

Default to 1. Parameter value is copied to the data.

=item 4. require

If this value is 0 and parameter value is not found,
the parameter is not added to missing parameter list.

Default to 1.

=back

=head1 CONSTRAINTS

=head2 ascii

  Data: {name => 'Ken'}
  Rule: require('name')->check('ascii')

Ascii graphic characters(hex 21-7e).

=head2 between

  # Check (1, 2, .. 19, 20)
  Data: {age => 19}
  Rule: require('age')->check({between => [1, 20]})

Between A and B.

=head2 blank

  Data: {name => ''}
  Rule: require('name')->check('blank')

Blank.

=head2 decimal
  
  Data: {num1 => '123', num2 => '1.45'}
  Rule: require('num1')->check({'decimal' => 3})
        require('num2')->check({'decimal' => [1, 2]})

Decimal. You can specify maximum digits number at before
and after '.'.

=head2 defined

  Data: {name => 'Ken'}
  Rule: require('name')->check('defined')

Defined.

=head2 duplication

  Data: {mail1 => 'a@somehost.com', mail2 => 'a@somehost.com'};
  Rule: require(['mail1', 'mail2'])->name('mail')->check('duplication)

Check if the two data are same or not.

You can get result value

  my $mail = $vresult->data->{mail};

Note that if one value is not defined or both values are not defined,
result of validation is false.

=head2 equal_to

  Data: {price => 1000}
  Rule: require('price')->check({'equal_to' => 1000})

Numeric equal comparison.

=head2 greater_than

  Data: {price => 1000}
  Rule: require('price')->check({'greater_than' => 900})

Numeric "greater than" comparison

=head2 http_url

  Data: {url => 'http://somehost.com'};
  Rule: require('url')->check('http_url')

HTTP(or HTTPS) URL.

=head2 int

  Data: {age => 19};
  Rule: require('age')->check('int')

Integer.

=head2 in_array

  Data: {food => 'sushi'};
  Rule: require('food')->check({'in_array' => [qw/sushi bread apple/]})

Check if the values is in array.

=head2 length

  Data: {value1 => 'aaa', value2 => 'bbbbb'};
  Rule: # length is equal to 3
        require('value1')->check({'length' => 3}) 
        # length is greater than or equal to 2 and lower than or equeal to 5
        require('value2')->check({'length' => [2, 5]}) 
        # length is greater than or equal to 2 and lower than or equeal to 5
        require('value3')->check({'length' => {min => 2, max => 5}}) 
        # greater than or equal to 2
        require('value4')->check({'length' => {min => 2}}) 
        # lower than or equal to 5
        require('value5')->check({'length' => {max => 5}}) 

Length of the value.

Not that if value is internal string, length is character length.
if value is byte string, length is byte length.

=head2 less_than

  Data: {num => 20}
  Rule: require('num')->check({'less_than' => 25});

Numeric "less than" comparison.

=head2 not_blank

  Data: {name => 'Ken'}
  Rule: require('name')->check('not_blank') # Except for ''

Not blank.

=head2 not_defined

  Data: {name => 'Ken'}
  Rule: require('name')->check('not_defined')

Not defined.

=head2 not_space

  Data: {name => 'Ken'}
  Rule: require('name')->check('not_space') # Except for '', ' ', '   '

Not contain only space characters. 
Not that space is only C<[ \t\n\r\f]>
which don't contain unicode space character.

=head2 space

  Data: {name => '   '}
  Rule: require('name')->check('space') # '', ' ', '   '

White space or empty string.
Not that space is only C<[ \t\n\r\f]>
which don't contain unicode space character.

=head2 uint

  Data: {age => 19}
  Rule: require('age')->check('uint')

Unsigned integer(contain zero).
  
=head2 regex

  Data: {num => '123'}
  Rule: require('num')->check({'regex' => qr/\d{0,3}/})

Match a regular expression.

=head2 selected_at_least

  Data: {hobby => ['music', 'movie' ]}
  Rule: require('hobby')->check({selected_at_least => 1})

Selected at least specified count item.
In other word, the array contains at least specified count element.

=head1 FILTERS

=head2 date_to_timepiece

  Data: {date => '2010/11/12'}
  Rule: require('date')->check('date_to_timepiece')

The value which looks like date is converted
to L<Time::Piece> object.
If the value contains 8 digits, the value is assumed date.

  2010/11/12 # ok
  2010-11-12 # ok
  20101112   # ok
  2010       # NG
  2010111106 # NG

And year and month and mday combination is ok.

  Data: {year => 2011, month => 3, mday => 9}
  Rule: require(['year', 'month', 'mday'])->name('date')
                                          ->check('date_to_timepiece')

You can get result value.

  my $date = $vresult->data->{date};

Note that L<Time::Piece> is required.

=head2 datetime_to_timepiece

  Data: {datetime => '2010/11/12 12:14:45'}
  Rule: require('datetime')->check('datetime_to_timepiece');

The value which looks like date and time is converted
to L<Time::Piece> object.
If the value contains 14 digits, the value is assumed date and time.

  2010/11/12 12:14:45 # ok
  2010-11-12 12:14:45 # ok
  20101112 121445     # ok
  2010                # NG
  2010111106 12       # NG

And year and month and mday combination is ok.

  Data: {year => 2011, month => 3, mday => 9
         hour => 10, min => 30, sec => 30}
  Rule: require(['year', 'month', 'mday', 'hour', 'min', 'sec'])
          ->name('datetime')->check('datetime_to_timepiece')

You can get result value.

  my $date = $vresult->data->{datetime};

Note that L<Time::Piece> is required.

=head2 merge

  Data: {name1 => 'Ken', name2 => 'Rika', name3 => 'Taro'}
  Rule: require(['name1', 'name2', 'name3'])->name('mergd_name')
          ->check('merge') # KenRikaTaro

Merge the values.

You can get result value.

  my $merged_name = $vresult->data->{merged_name};

Note that if one value is not defined, merged value become undefined.

=head2 shift

  Data: {names => ['Ken', 'Taro']}
  Rule: require('names')->check('shift') # 'Ken'

Shift the head element of array.

=head2 to_array

  Data: {languages => 'Japanese'}
  Rule: require('languages')->check('to_array') # ['Japanese']
  
Convert non array reference data to array reference.
This is useful to check checkbox values or select multiple values.

=head2 trim

  Data: {name => '  Ken  '}
  Rule: require('name')->check('trim') # 'Ken'

Trim leading and trailing white space.
Not that trim only C<[ \t\n\r\f]>
which don't contain unicode space character.

=head2 trim_collapse

  Data: {name => '  Ken   Takagi  '}
  Rule: require('name')->check('trim_collapse') # 'Ken Takagi'

Trim leading and trailing white space,
and collapse all whitespace characters into a single space.
Not that trim only C<[ \t\n\r\f]>
which don't contain unicode space character.

=head2 trim_lead

  Data: {name => '  Ken  '}
  Rule: require('name')->check('trim_lead') # 'Ken  '

Trim leading white space.
Not that trim only C<[ \t\n\r\f]>
which don't contain unicode space character.

=head2 trim_trail

  Data: {name => '  Ken  '}
  Rule: require('name')->check('trim_trail') # '  Ken'

Trim trailing white space.
Not that trim only C<[ \t\n\r\f]>
which don't contain unicode space character.

=head2 trim_uni

  Data: {name => '  Ken  '}
  Rule: require('name')->check('trim_uni') # 'Ken'

Trim leading and trailing white space, which contain unicode space character.

=head2 trim_uni_collapse

  Data: {name => '  Ken   Takagi  '};
  Rule: require('name')->check('trim_uni_collapse') # 'Ken Takagi'

Trim leading and trailing white space, which contain unicode space character.

=head2 trim_uni_lead

  Data: {name => '  Ken  '};
  Rule: require('name')->check('trim_uni_lead') # 'Ken  '

Trim leading white space, which contain unicode space character.

=head2 trim_uni_trail
  
  Data: {name => '  Ken  '};
  Rule: require('name')->check('trim_uni_trail') # '  Ken'

Trim trailing white space, which contain unicode space character.

=head1 ATTRIBUTES

=head2 constraints

  my $constraints = $vc->constraints;
  $vc             = $vc->constraints(\%constraints);

Constraint functions.

=head2 data_filter

  my $filter = $vc->data_filter;
  $vc        = $vc->data_filter(\&data_filter);

Filter for input data. If data is not hash reference, you can convert
the data to hash reference.

  $vc->data_filter(sub {
    my $data = shift;
    
    my $hash = {};
    
    # Convert data to hash reference
    
    return $hash;
  });

=head2 error_stock

  my $error_stock = $vc->error_stcok;
  $vc             = $vc->error_stock(1);

If error_stock is set to 0, C<validate()> return soon after invalid value is found.

Default to 1. 

=head2 rule_obj EXPERIMENTAL

  my $rule_obj = $vc->rule_obj($rule);

L<Validator::Custom> rule is a little complex.
You maybe make mistakes often.
If you want to know that how Validator::Custom parse rule,
See C<rule_obj> attribute after calling C<validate> method.
This is L<Validator::Custom::Rule> object.
  
  my $vresult = $vc->validate($data, $rule);

  use Data::Dumper;
  print Dumper $vc->rule_obj->rule;

If you see C<ERROR> key, rule syntax is wrong.

=head2 rule

  my $rule = $vc->rule;
  $vc      = $vc->rule(\@rule);

Validation rule. If second argument of C<validate()> is not specified.
this rule is used.

=head1 METHODS

L<Validator::Custom> inherits all methods from L<Object::Simple>
and implements the following new ones.

=head2 new

  my $vc = Validator::Custom->new;

Create a new L<Validator::Custom> object.

=head2 js_fill_form_button

  my $button = $self->js_fill_form_button(
    mail => '[abc]{3}@[abc]{2}.com,
    title => '[pqr]{5}'
  );

Create javascript button source code to fill form.
You can specify string or pattern like regular expression.

If you click this button, each text box is filled with the
specified pattern string,
and checkbox, radio button, and list box is automatically selected.

Note that this methods require L<JSON> module.

=head2 validate

  $result = $vc->validate($data, $rule);
  $result = $vc->validate($data);

Validate the data.
Return value is L<Validator::Custom::Result> object.
If second argument isn't passed, C<rule> attribute is used as rule.

$rule is array reference
(or L<Validator::Custom::Rule> object, this is EXPERIMENTAL).

=head2 register_constraint

  $vc->register_constraint(%constraint);
  $vc->register_constraint(\%constraint);

Register constraint function.
  
  $vc->register_constraint(
    int => sub {
      my $value    = shift;
      my $is_valid = $value =~ /^\-?[\d]+$/;
      return $is_valid;
    },
    ascii => sub {
      my $value    = shift;
      my $is_valid = $value =~ /^[\x21-\x7E]+$/;
      return $is_valid;
    }
  );

You can register filter function.

  $vc->register_constraint(
    trim => sub {
      my $value = shift;
      $value =~ s/^\s+//;
      $value =~ s/\s+$//;
      
      return {result => 1, output => $value];
    }
  );

Filter function return array reference,
first element is the value if the value is valid or not,
second element is the converted value by filter function.

=head1 EXAMPLES

See L<Validator::Custom Wiki|https://github.com/yuki-kimoto/Validator-Custom/wiki>.
There are many examples.

=head1 DEPRECATED FUNCTIONALITIES

L<Validator::Custom>
  
  # Atrribute methods
  shared_rule # Removed at 2017/1/1
  
  # Methods
  __PACKAGE__->constraints(...); # Call constraints method as class method
                                 # Removed at 2017/1/1
L<Validator::Custom::Result>

  # Attribute methods
  error_infos # Removed at 2017/1/1 

  # Methods
  add_error_info # Removed at 2017/1/1
  error # Removed at 2017/1/1
  errors # Removed at 2017/1/1
  errors_to_hash # Removed at 2017/1/1
  invalid_keys # Removed at 2017/1/1
  remove_error_info# Removed at 2017/1/1

=head1 BACKWORD COMPATIBLE POLICY

If a functionality is DEPRECATED, you can know it by DEPRECATED warnings.
DEPRECATED functionality is removed after five years,
but if at least one person use the functionality and tell me that thing
I extend one year each time you tell me it.

EXPERIMENTAL functionality will be changed without warnings.

=head1 AUTHOR

Yuki Kimoto, C<< <kimoto.yuki at gmail.com> >>

L<http://github.com/yuki-kimoto/Validator-Custom>

=head1 COPYRIGHT & LICENCE

Copyright 2009-2014 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
