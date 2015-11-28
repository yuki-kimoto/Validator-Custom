package Validator::Custom;
use Object::Simple -base;
use 5.008001;
our $VERSION = '1.00';

use Carp 'croak';
use Validator::Custom::Validation;
use Validator::Custom::FilterFunction;
use Validator::Custom::CheckFunction;

# Version 0 modules(Not used now)
use Validator::Custom::Constraints;
use Validator::Custom::Constraint;
use Validator::Custom::Result;
use Validator::Custom::Rule;

sub validation { Validator::Custom::Validation->new }

sub new {
  my $self = shift->SUPER::new(@_);
  
  # Add checks
  $self->add_check(
    ascii             => \&Validator::Custom::CheckFunction::ascii,
    decimal           => \&Validator::Custom::CheckFunction::decimal,
    int               => \&Validator::Custom::CheckFunction::int,
    in                => \&Validator::Custom::CheckFunction::in,
    uint              => \&Validator::Custom::CheckFunction::uint,
    regex             => \&Validator::Custom::CheckFunction::regex,
  );
  
  # Add filters
  $self->add_filter(
    remove_blank      => \&Validator::Custom::FilterFunction::remove_blank,
    trim              => \&Validator::Custom::FilterFunction::trim,
    trim_collapse     => \&Validator::Custom::FilterFunction::trim_collapse,
    trim_lead         => \&Validator::Custom::FilterFunction::trim_lead,
    trim_trail        => \&Validator::Custom::FilterFunction::trim_trail,
    trim_uni          => \&Validator::Custom::FilterFunction::trim_uni,
    trim_uni_collapse => \&Validator::Custom::FilterFunction::trim_uni_collapse,
    trim_uni_lead     => \&Validator::Custom::FilterFunction::trim_uni_lead,
    trim_uni_trail    => \&Validator::Custom::FilterFunction::trim_uni_trail
  );
  
  # Version 0 constraints
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
    string            => \&Validator::Custom::Constraint::string,
    to_array          => \&Validator::Custom::Constraint::to_array,
    to_array_remove_blank => \&Validator::Custom::Constraint::to_array_remove_blank,
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

sub check_each {
  my ($self, $name, $values, $arg) = @_;
  
  if (@_ < 3) {
    croak "value must be passed";
  }
  
  my $checks = $self->{checks} || {};
  
  croak "Can't call \"$name\" check"
    unless $checks->{$name};
  
  croak "values must be array refernce"
    unless ref $values eq 'ARRAY';
  
  my $is_invalid;
  for my $value (@$values) {
    my $is_valid = $checks->{$name}->($self, $value, $arg);
    unless ($is_valid) {
      $is_invalid = 1;
      last;
    }
  }
  
  return $is_invalid ? 0 : 1;
}

sub filter_each {
  my ($self, $name, $values, $arg) = @_;
  
  if (@_ < 3) {
    croak "value must be passed";
  }
  
  my $filters = $self->{filters} || {};
  
  croak "Can't call \"$name\" filter"
    unless $filters->{$name};
  
  croak "values must be array refernce"
    unless ref $values eq 'ARRAY';
  
  my $new_values = [];
  for my $value (@$values) {
    my $new_value = $filters->{$name}->($self, $value, $arg);
    push @$new_values, $new_value;
  }
  
  return $new_values;
}

sub check {
  my ($self, $name, $value, $arg) = @_;

  if (@_ < 3) {
    croak "value must be passed";
  }
  
  my $checks = $self->{checks} || {};
  
  croak "Can't call \"$name\" check"
    unless $checks->{$name};
  
  return $checks->{$name}->($self, $value, $arg);
}

sub filter {
  my ($self, $name, $value, $arg) = @_;
  
  if (@_ < 3) {
    croak "value must be passed";
  }
  
  my $filters = $self->{filters} || {};
  
  croak "Can't call \"$name\" filter"
    unless $filters->{$name};
  
  return $filters->{$name}->($self, $value, $arg);
}

sub add_check {
  my $self = shift;
  
  # Merge
  my $checks = ref $_[0] eq 'HASH' ? $_[0] : {@_};
  $self->{checks} = ({%{$self->{checks} || {}}, %$checks});
  
  return $self;
}

sub add_filter {
  my $self = shift;
  
  # Merge
  my $filters = ref $_[0] eq 'HASH' ? $_[0] : {@_};
  $self->{filters} = ({%{$self->{filters} || {}}, %$filters});
  
  return $self;
}

our %VALID_OPTIONS = map {$_ => 1} qw/message default copy require optional/;

sub _parse_constraint {
  my ($self, $c) = @_;

  # Constraint information
  my $cinfo = {};

  # Arrange constraint information
  my $constraint = $c->{constraint};
  $cinfo->{message} = $c->{message};
  $cinfo->{original_constraint} = $c->{constraint};
  
  # Code reference
  if (ref $constraint eq 'CODE') {
    $cinfo->{funcs} = [$constraint];
  }
  # Simple constraint name
  else {
    my $constraints;
    if (ref $constraint eq 'ARRAY') {
      $constraints = $constraint;
    }
    else {
      if ($constraint =~ /\|\|/) {
        $constraints = [split(/\|\|/, $constraint)];
      }
      else {
        $constraints = [$constraint];
      }
    }
    
    # Constraint functions
    my @cfuncs;
    my @cargs;
    for my $cname (@$constraints) {
      # Arrange constraint
      if (ref $cname eq 'HASH') {
        my $first_key = (keys %$cname)[0];
        push @cargs, $cname->{$first_key};
        $cname = $first_key;
      }

      # Target is array elements
      $cinfo->{each} = 1 if $cname =~ s/^@//;
      croak qq{"\@" must be one at the top of constrinat name}
        if index($cname, '@') > -1;
      
      
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
    $cinfo->{args} = \@cargs;
  }
  
  return $cinfo;
}

# DEPRECATED!
has shared_rule => sub { [] };
# DEPRECATED!
__PACKAGE__->dual_attr('constraints',
  default => sub { {} }, inherit => 'hash_copy');

# Version method(Not used now)
sub create_rule { Validator::Custom::Rule->new(validator => shift) }

# Version 0 method(Not used now)
sub register_constraint {
  my $self = shift;
  
  # Merge
  my $constraints = ref $_[0] eq 'HASH' ? $_[0] : {@_};
  $self->constraints({%{$self->constraints}, %$constraints});
  
  return $self;
}

# Version 0 method(Not used now)
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

# Version 0 method(Not used now)
sub validate {
  my ($self, $input, $rule) = @_;
  
  # Class
  my $class = ref $self;
  
  # Validation rule
  $rule ||= $self->rule;
  
  # Data filter
  my $filter = $self->data_filter;
  $input = $filter->($input) if $filter;
  
  # Check data
  croak "First argument must be hash ref"
    unless ref $input eq 'HASH';
  
  # Check rule
  unless (ref $rule eq 'Validator::Custom::Rule') {
    croak "Invalid rule structure" unless ref $rule eq 'ARRAY';
  }
  
  # Result
  my $result = Validator::Custom::Result->new;
  $result->{_error_infos} = {};
  
  # Save raw data
  $result->raw_data($input);
  
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
  warn "Validator::Custom::shared_rule is DEPRECATED!"
    if @$shared_rule;
  
  if (ref $rule eq 'Validator::Custom::Rule') {
    $self->rule_obj($rule);
  }
  else {
    my $rule_obj = $self->create_rule;
    $rule_obj->parse($rule, $shared_rule);
    $self->rule_obj($rule_obj);
  }
  my $rule_obj = $self->rule_obj;

  if ($rule_obj->{version} && $rule_obj->{version} == 1) {
    croak "Can't call validate method(Validator::Custom). Use \$rule->validate(\$input) instead";
  }
  
  # Process each key
  OUTER_LOOP:
  for (my $i = 0; $i < @{$rule_obj->rule}; $i++) {
    
    my $r = $rule_obj->rule->[$i];
    
    # Increment position
    $pos++;
    
    # Key, options, and constraints
    my $key = $r->{key};
    my $opts = $r->{option};
    my $cinfos = $r->{constraints} || [];
    
    # Check constraints
    croak "Invalid rule structure"
      unless ref $cinfos eq 'ARRAY';

    # Arrange key
    my $result_key = $key;
    if (ref $key eq 'HASH') {
      my $first_key = (keys %$key)[0];
      $result_key = $first_key;
      $key         = $key->{$first_key};
    }
    elsif (defined $r->{name}) {
      $result_key = $r->{name};
    }
    
    # Real keys
    my $keys;
    
    if (ref $key eq 'ARRAY') { $keys = $key }
    elsif (ref $key eq 'Regexp') {
      $keys = [];
      for my $k (keys %$input) {
         push @$keys, $k if $k =~ /$key/;
      }
    }
    else { $keys = [$key] }
    
    # Check option
    if (exists $opts->{optional}) {
      if ($opts->{optional}) {
        $opts->{require} = 0;
      }
      delete $opts->{optional};
    }
    for my $oname (keys %$opts) {
      croak qq{Option "$oname" of "$result_key" is invalid name}
        unless $VALID_OPTIONS{$oname};
    }
    
    # Default
    if (exists $opts->{default}) {
      $r->{default} = $opts->{default};
    }
    
    # Is data copy?
    my $copy = 1;
    $copy = $opts->{copy} if exists $opts->{copy};
    
    # Check missing parameters
    my $require = exists $opts->{require} ? $opts->{require} : 1;
    my $found_missing_param;
    my $missing_params = $result->missing_params;
    for my $key (@$keys) {
      unless (exists $input->{$key}) {
        if ($require && !exists $r->{default}) {
          push @$missing_params, $key
            unless $found_missing_params->{$key};
          $found_missing_params->{$key}++;
        }
        $found_missing_param = 1;
      }
    }
    if ($found_missing_param) {
      $result->data->{$result_key} = ref $r->{default} eq 'CODE'
          ? $r->{default}->($self) : $r->{default}
        if exists $r->{default} && $copy;
      next if $r->{default} || !$require;
    }
    
    # Already valid
    next if $valid_keys->{$result_key};
    
    # Validation
    my $value = @$keys > 1
      ? [map { $input->{$_} } @$keys]
      : $input->{$keys->[0]};
    
    for my $cinfo (@$cinfos) {
      
      # Constraint information
      my $args = $cinfo->{args};
      my $message = $cinfo->{message};
                                      
      # Constraint function
      my $cfuncs = $cinfo->{funcs};
      
      # Is valid?
      my $is_valid;
      
      # Data is array
      if($cinfo->{each}) {
          
        # To array
        $value = [$value] unless ref $value eq 'ARRAY';
        
        # Validation loop
        for (my $k = 0; $k < @$value; $k++) {
          my $input = $value->[$k];
          
          # Validation
          for (my $j = 0; $j < @$cfuncs; $j++) {
            my $cfunc = $cfuncs->[$j];
            my $arg = $args->[$j];
            
            # Validate
            my $cresult;
            {
              local $_ = Validator::Custom::Constraints->new(
                constraints => $self->constraints
              );
              $cresult= $cfunc->($input, $arg, $self);
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
        for (my $k = 0; $k < @$cfuncs; $k++) {
          my $cfunc = $cfuncs->[$k];
          my $arg = $args->[$k];
        
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
        if (exists $r->{default}) {
          # Set default value
          $result->data->{$result_key} = ref $r->{default} eq 'CODE'
                                       ? $r->{default}->($self)
                                       : $r->{default}
            if exists $r->{default} && $copy;
          $valid_keys->{$result_key} = 1
        }
        else {
          # Resist error info
          $message = $opts->{message} unless defined $message;
          $result->{_error_infos}->{$result_key} = {
            message      => $message,
            position     => $pos,
            reason       => $cinfo->{original_constraint},
            original_key => $key
          } unless exists $result->{_error_infos}->{$result_key};
          
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

# Version 0 attributes(Not used now)
has 'data_filter';
has 'rule';
has 'rule_obj';
has error_stock => 1;

# Version 0 method(Not used now)
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

1;

=head1 NAME

Validator::Custom - HTML form Validation, simple and good flexibility

=head1 SYNOPSYS

  use Validator::Custom;
  my $vc = Validator::Custom->new;
  
  # Input
  my $id = 1;
  my $name = 'Ken Suzuki';
  my $age = ' 19 ';
  my $favorite = ['apple', 'orange'];
  
  # Create validation object
  my $validation = $vc->validation;
  
  # Check id and set failed message
  if (!(length $id && $vc->check('int', $id))) {
    $validation->add_failed(id => 'id must be integer');
  }
  
  # Check name and set failed message
  if (!(length $name)) {
    $validation->add_failed(name => 'name must have length');
  }
  elsif (!(length $name < 30)) {
    $validation->add_failed(name => 'name is too long');
  }
  
  # Filter and check age, and set default value
  $age = $vc->filter('trim', $age);
  if (!(length $id && $vc->check('int', $id))) {
    $age = 20;
  
  # Filter and check each favorite value
  $favorite = $vc->filter_each('trim', $fovorite);
  if (@$favorite == 0) {
    $validation->add_failed(favorite => 'favorite must be selected more than one');
  }
  elsif (!($vc->check_each('in', $favorite, ['apple', 'ornge', 'peach']))) {
    $validation->add_failed(favorite => 'favorite is invalid');
  }
  
  # Get result
  if ($validation->is_valid) {
    # ...
  }
  else {
    # Error messgaes
    my $messages = $vresult->messages;
  }
  
=head1 DESCRIPTION

L<Validator::Custom> validate HTML form data easy and flexibly.
The features are the following ones.

=over 4

=item *

Many check functions are available by default, such as C<not_blank>,
C<int>, C<defined>, C<in_array>, C<length>.

=item *

Several filter functions are available by default, such as C<trim>,
C<datetime_to_timepiece>, C<date_to_timepiece>.

=item *

You can add your check function.

=item *

You can set error messages for invalid parameter value.
The order of messages is kept.

=item *

Support C<OR> condition check and negative check,

=back

=head1 GUIDE

=head2 1. Basic

B<1. Create a new Validator::Custom object>

  use Validator::Custom;
  my $vc = Validator::Custom->new;

B<2. Prepare data for validation>

  my $input = {age => 19, name => 'Ken Suzuki'};

Data must be hash reference.

B<3. Prepare a rule for validation>

  my $ruel = $vc->create_rule;
  $rule->topic('age')
    ->check('not_blank')
    ->check('int')->message('age must be integer');
  
  $rule->topic('name')
    ->check('not_blank')->message('name is empty')
    ->check(length => [1, 5])->message('name must be length 1 to 5');

Please see L<Validator::Custom/"RULE"> about rule syntax.

You can use many check function,
such as C<int>, C<not_blank>, C<length>.
See L<Validator::Custom/"CONSTRAINTS">
to know all check functions.

Rule details is explained in L</"3. Rule syntax"> section.

B<4. Validate data>
  
  my $validation = $vc->validate($input, $rule);

use C<validate()> to validate the data applying the rule.
C<validate()> return L<Validator::Custom::Result> object.

B<5. Manipulate the validation result>
  
  if ($validation->is_ok) {
    my $output = $validation->data;
  }
  else {
    # Handle error
  }

If you check the data is completely valid, use C<is_ok()>.
C<is_ok()> return true value

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

C<is_ok()>, C<has_invalid()>
C<messages_to_hash()> is already explained in L</"1. Basic">

The following ones is often used methods.

B<output> method

  my $output = $validation->data;

Get the data in the end state. L<Validator::Custom> has filtering ability.
The parameter values in data passed to C<validate()>
is maybe converted to other data by filter.
You can get filtered data using C<data()>.

B<messages()>

  my $messages = $validation->messages;

Get messages corresponding to the parameter names which value is invalid.
Messages keep the order of parameter names of the rule.

B<message()>

  my $message = $validation->message('name');

Get a message corresponding to the parameter name which value is invalid.

All L<Validator::Custom::Result>'s APIs is explained
in the POD of L<Validator::Custom::Result>

=head2 RULE

  # Create Rule
  my $rule = $vc->create_rule;
  
  # Rule syntax - integer, have error message
  $rule->topic('id')->check('int')->message('id should be integer');
  
  # Rule syntax - not blank, length is 1 to 5, have error messages
  $rule->topic('name')
    ->check('not_blank')->message('name is emtpy')
    ->check(length => [1, 5])->message('name is too long');
  
  # Rule syntax - value is optional, default is 20
  $rule->topic('age')->optional->check('int')->default(20);

Rule is L<Validator::Custom::Rule> ojbect.
You can create C<create_rule> method of L<Validator::Custom>.

  my $rule = $vc->create_rule

At first you set topic by C<topic> method.
If the value is not always required, you use C<optional> method after call C<topic> method.
  
  # Set topic
  $rule->topic('age');
  
  # If value is optional, call optional methods
  $rule->topic('age')->optional;

If you set topic to multiple keys, you should set key name by C<name> method.

  # Key name
  $rule->topic(['mail1', 'mail2'])->name('mail');

You can set options, C<message>, C<default>, and C<copy>.

=over 4

=item 1. message

 $rule->topic('age')->message('age is invalid');

Message corresponding to the parameter name which value is invalid. 

=item 2. default

  $rule->topic('age')->default(5)

Default value. 
If the parameter value is invalid,
This value is set to output.

If you set not string or number value, you should the value which surrounded by code reference

  $rule->topic('age')->default(sub { [] })
  
=item 3. copy

  $rule->topic('age')->copy(0)

If this value is 0, The parameter value is not copied to result data. 
Default to 1. Parameter value is copied to the data.

=back

You set checks by C<check> method.

  $rule->topic('age')->check('length' => [1, 5]);

You can set message for each check function

  $rule->topic('name')
    ->check('not_blank')->message('name must be not blank')
    ->check(length => [1, 5])->message('name must be 1 to 5 length');

You can create original check function using
original checks.
you can call checks from $_ in subroutine.

  # You original check(you can call check from $_)
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

  Input: {password1 => 'xxx', password2 => 'xxx'}
  Rule:  $rule->topic(['password1', 'password2'])->name('password_check)
          ->check('duplication')

In this example, We check if 'password1' and 'password2' is same.
The following value is passed to check function C<duplication>.

  ['xxx', 'xxx']

You must specify new key, such as C<password_check>.
This is used by L<Validator::Result> object.

All matched value is passed to check function as array reference.
In this example, the following value is passed.

  ['Taro', 'Rika', 'Ken']

=head3 Array validation

You can C<check_each> method if all the elements of array is valid.

The following is old syntax. Please use above syntax.

  Input: {nums => [1, 2, 3]}
  Rule:  $rule->topic('nums')->check_each('int')

=head2 4. Check functions

=head3 Register check function

L<Validator::Custom> has various check functions.
You can see check functions added by default
L<Validator::Custom/"CONSTRAINTS">.

and you can add your check function if you need.

  $vc->add_check(
    telephone => sub {
      my $value = shift;
      
      my $is_valid;
      if ($value =~ /^[\d-]+$/) {
        $is_valid = 1;
      }
      return $is_valid;
    }
  );

Check function for telephone number is added.

Check function receive a scalar value as first argument and
return boolean value which check if the value is valid.

Check function receive argument of check function as second argument
and L<Validator::Custom> object as third argument.

  $vc->add_check(
    telephone => sub {
      my ($rule, $args, $key, $params) = @_;
      
      my $value = $params->{$key};
      
      my $is_valid;
      # ...
      
      return $is_valid;
    }
  );

=head3 Register filter function

Filter function is registered by C<add_filter> method.

  $vc->add_filter(
    to_upper_case => sub {
      my ($rule, $args, $key, $params) = @_;
      
      my $value = $params->{$key};
      
      $value = uc $value;
                  
      return [$key, {$key => $value}];
    }
  );

=head1 CHECKS

=head2 blank

  Input: {name => ''}
  Rule:  $rule->topic('name')->check('blank')

Blank.

=head2 space

  Input: {name => '   '}
  Rule:  $rule->topic('name')->check('space') # '', ' ', '   '

White space or empty string.
Not that space is only C<[ \t\n\r\f]>
which don't contain unicode space character.

=head2 ascii
  
  my $is_valid = $vc->check('ascii', $value);
  
Ascii graphic characters(hex 21-7e).

Valid example:

  "Ken"

Invalid example:
  
  "aa aa"
  "\taaa"

=head2 decimal
  
  Input: {num1 => '123', num2 => '1.45'}
  Rule:  $rule->topic('num1')->check('decimal' => 3)
        $rule->topic('num2')->check('decimal' => [1, 2])

Decimal. You can specify maximum digits number at before
and after '.'.

If you set undef value or don't set any value, that means there is no maximum limit.
  
  Input: {num1 => '1233555.89345', num2 => '1121111.45', num3 => '12.555555555'}
  Rule:  $rule->topic('num1')->check('decimal')
        $rule->topic('num2')->check('decimal' => [undef, 2])
        $rule->topic('num2')->check('decimal' => [2, undef])

=head2 http_url

  Input: {url => 'http://somehost.com'};
  Rule:  $rule->topic('url')->check('http_url')

HTTP(or HTTPS) URL.

=head2 int

  Input: {age => 19};
  Rule:  $rule->topic('age')->check('int')

Integer.

=head2 in

  Input: {food => 'sushi'};
  Rule:  $rule->topic('food')->check('in' => [qw/sushi bread apple/])

Check if the values is in array.

=head2 uint

  Input: {age => 19}
  Rule:  $rule->topic('age')->check('uint')

Unsigned integer(contain zero).
  
=head2 selected_at_least

  Input: {hobby => ['music', 'movie' ]}
  Rule:  $rule->topic('hobby')->check(selected_at_least => 1)

Selected at least specified count item.
In other word, the array contains at least specified count element.

=head1 FILTERS

You can use the following filter by default.

=head2 trim

  Input: {name => '  Ken  '}
  Rule:  $rule->topic('name')->filter('trim')
  Output:{name => 'Ken'}

Trim leading and trailing white space.
Not that trim only C<[ \t\n\r\f]>
which don't contain unicode space character.

=head2 trim_collapse

  Input: {name => '  Ken   Takagi  '}
  Rule:  $rule->topic('name')->filter('trim_collapse') # 
  Output:{name => 'Ken Takagi'}

Trim leading and trailing white space,
and collapse all whitespace characters into a single space.
Not that trim only C<[ \t\n\r\f]>
which don't contain unicode space character.

=head2 trim_lead

  Input: {name => '  Ken  '}
  Rule:  $rule->topic('name')->filter('trim_lead')
  Output:{name => 'Ken  '}

Trim leading white space.
Not that trim only C<[ \t\n\r\f]>
which don't contain unicode space character.

=head2 trim_trail

  Input: {name => '  Ken  '}
  Rule:  $rule->topic('name')->filter('trim_trail')
  Output:{name => '  Ken'}

Trim trailing white space.
Not that trim only C<[ \t\n\r\f]>
which don't contain unicode space character.

=head2 trim_uni

  Input: {name => '  Ken  '}
  Rule:  $rule->topic('name')->filter('trim_uni')
  Output:{name => 'Ken'}

Trim leading and trailing white space, which contain unicode space character.

=head2 trim_uni_collapse

  Input: {name => '  Ken   Takagi  '};
  Rule:  $rule->topic('name')->filter('trim_uni_collapse')
  Output:{name => 'Ken Takagi'}

Trim leading and trailing white space, which contain unicode space character.

=head2 trim_uni_lead

  Input: {name => '  Ken  '};
  Rule:  $rule->topic('name')->filter('trim_uni_lead')
  Output:{name => 'Ken  '}

Trim leading white space, which contain unicode space character.

=head2 trim_uni_trail
  
  Input: {name => '  Ken  '};
  Rule:  $rule->topic('name')->filter('trim_uni_trail')
  Output:{name => '  Ken'}

Trim trailing white space, which contain unicode space character.

=head1 METHODS

L<Validator::Custom> inherits all methods from L<Object::Simple>
and implements the following new ones.

=head2 new

  my $vc = Validator::Custom->new;

Create a new L<Validator::Custom> object.

=head2 add_check

  $vc->add_check(%check);
  $vc->add_check(\%check);

Add check function.
It receives four arguments,
Validator::Custom::Rule object, arguments of check function,
current key name, and parameters
  
  $vc->add_check(
    int => sub {
      my ($rule, $args, $key, $params) = @_;
      
      my $value = $params->{$key};
      
      my $is_valid = $value =~ /^\-?[\d]+$/;
      
      return $is_valid;
    },
    greater_than => sub {
      my ($rule, $args, $key, $params) = @_;
      
      my ($arg_value) = @$args;
      
      if ($value > $arg_value) {
        return 1;
      }
      else {
        return 0;
      }
    }
  );

=head2 add_filter

Add filter function. 
It receives four arguments,
Validator::Custom::Rule object, arguments of check function,
current key name, and parameters,

  $vc->add_filter(
    trim => sub {
      my ($rule, $args, $key, $params) = @_;
      
      my $value = $params->{$key};
      
      $value =~ s/^\s+//;
      $value =~ s/\s+$//;
      
      return $value;
    }
  );

=head2 check

  my $is_valid = $vc->check('int', $value);
  my $is_valid = $vc->check('length', $value, $arg);

Run check.

=head2 check_each

  my $is_valid = $vc->check_each('int', $values);
  my $is_valid = $vc->check_each('length', $values, $arg);

Run check all elements of array refernce.
If more than one element is invalid, check_each reterun false.

=head2 filter

  my $new_value = $vc->filter('trim', $value);
  my $new_value = $vc->filter('trim', $value, $arg);

Run filter.

=head2 filter_each

  my $new_values = $vc->filter_each('trim', $values);
  my $new_values = $vc->filter_each('trim', $values, $arg);

Run filter all elements of array reference.

=head1 FAQ

=head2 How to do check box validation?

Check box validation is a little difficult because
check box value is not exists or one or multiple.

  # Data
  my $input = {}
  my $input = {feature => 1}
  my $input = {feature => [1, 2]}

You can do the following way.

  $rule->topic('feature')
    ->filter('to_array')
    ->check(selected_at_least => 1)->message('feature should select at least 1')
    ->check_each('int')->message('features should be integer');

=head2 How to do validation of "or" condition

You create your check code using code reference.
You can use check function by C<run_check> method.

  # Data
  my $input = {age => ''};
  my $input = {age => 3};
  
  # Check blank or int
  $rule->topic('age')->check(sub {
    my ($rule, $args, $key, $params) = @_;
    
    my $is_blank = $rule->run_check('blank', [], $key, $params);
    my $is_int = $rule->run_check('int', [], $key, $params);
    
    return $is_blank || $is_int;
  });

=head1 AUTHOR

Yuki Kimoto, C<< <kimoto.yuki at gmail.com> >>

L<http://github.com/yuki-kimoto/Validator-Custom>

=head1 COPYRIGHT & LICENCE

Copyright 2009-2015 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
