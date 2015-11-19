package Validator::Custom;
use Object::Simple -base;
use 5.008001;
our $VERSION = '1.00';

use Carp 'croak';
use Validator::Custom::Constraint;
use Validator::Custom::Result;
use Validator::Custom::Rule;
use Validator::Custom::Constraints;

sub create_rule { Validator::Custom::Rule->new(validator => shift) }

sub new {
  my $self = shift->SUPER::new(@_);
  
  # Add checks
  $self->add_check(
    ascii             => \&Validator::Custom::CheckFunction::ascii,
    between           => \&Validator::Custom::CheckFunction::between,
    blank             => \&Validator::Custom::CheckFunction::blank,
    decimal           => \&Validator::Custom::CheckFunction::decimal,
    defined           => sub { defined $_[0] },
    duplication       => \&Validator::Custom::CheckFunction::duplication,
    equal_to          => \&Validator::Custom::CheckFunction::equal_to,
    greater_than      => \&Validator::Custom::CheckFunction::greater_than,
    http_url          => \&Validator::Custom::CheckFunction::http_url,
    int               => \&Validator::Custom::CheckFunction::int,
    in_array          => \&Validator::Custom::CheckFunction::in_array,
    length            => \&Validator::Custom::CheckFunction::length,
    less_than         => \&Validator::Custom::CheckFunction::less_than,
    not_defined       => \&Validator::Custom::CheckFunction::not_defined,
    not_space         => \&Validator::Custom::CheckFunction::not_space,
    not_blank         => \&Validator::Custom::CheckFunction::not_blank,
    uint              => \&Validator::Custom::CheckFunction::uint,
    regex             => \&Validator::Custom::CheckFunction::regex,
    selected_at_least => \&Validator::Custom::CheckFunction::selected_at_least,
    space             => \&Validator::Custom::CheckFunction::space,
    string            => \&Validator::Custom::CheckFunction::string,
    date              => \&Validator::Custom::CheckFunction::date_to_timepiece,
    datetime          => \&Validator::Custom::CheckFunction::datetime_to_timepiece,
  );
  
  # Add filters
  $self->add_filter(
    date_to_timepiece => \&Validator::Custom::FilterFunction::date_to_timepiece,
    datetime_to_timepiece => \&Validator::Custom::FilterFunction::datetime_to_timepiece,
    shift             => \&Validator::Custom::FilterFunction::shift_array,
    merge             => \&Validator::Custom::FilterFunction::merge,
    to_array          => \&Validator::Custom::FilterFunction::to_array,
    to_array_remove_blank => \&Validator::Custom::FilterFunction::to_array_remove_blank,
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

sub add_check {
  my $self = shift;
  
  # Merge
  my $checks = ref $_[0] eq 'HASH' ? $_[0] : {@_};
  $self->{checks} = ({%{$self->{checks} || {}}, %$checks});
  
  return $self;
}

sub run_check {
  my ($self, $name, $values, $args) = @_;
  
  my $checks = $self->{checks} || {};
  my $check = $checks->{$name};
  unless ($check) {
    croak "Can't call $name check";
  }
  
  my $ret = $check->($values, $args);
  
  if (ref $ret eq 'HASH') {
    return 0;
  }
  else {
    return $ret ? 1: 0;
  }
}

sub run_filter {
  my ($self, $name, $values, $args) = @_;
  
  my $filters = $self->{filters} || {};
  my $filter = $filters->{$name};
  unless ($filter) {
    croak "Can't call $name filter";
  }
  
  my $new_value = $filter->($values, $args);
  
  return $new_value;
}

sub add_filter {
  my $self = shift;
  
  # Merge
  my $filters = ref $_[0] eq 'HASH' ? $_[0] : {@_};
  $self->{filters} = ({%{$self->{filters} || {}}, %$filters});
  
  return $self;
}

our %VALID_OPTIONS = map {$_ => 1} qw/message default copy require/;

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
  warn "DBIx::Custom::shared_rule is DEPRECATED!"
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
    if (exists $opts->{required}) {
      $opts->{require} = delete $opts->{required};
    }
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
      unless (exists $input->{$key}) {
        if ($require && !exists $opts->{default}) {
          push @$missing_params, $key
            unless $found_missing_params->{$key};
          $found_missing_params->{$key}++;
        }
        $found_missing_param = 1;
      }
    }
    if ($found_missing_param) {
      $result->output->{$result_key} = ref $opts->{default} eq 'CODE'
          ? $opts->{default}->($self) : $opts->{default}
        if exists $opts->{default} && $copy;
      next if $opts->{default} || !$require;
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
        if (exists $opts->{default}) {
          # Set default value
          $result->output->{$result_key} = ref $opts->{default} eq 'CODE'
                                       ? $opts->{default}->($self)
                                       : $opts->{default}
            if exists $opts->{default} && $copy;
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
    $result->output->{$result_key} = $value if $copy;
    
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

Validator::Custom - HTML form Validation, easy and flexibly

=head1 SYNOPSYS

  use Validator::Custom;
  my $vc = Validator::Custom->new;
  
  # Data
  my $input = {id => 1, name => 'Ken Suzuki', age => ' 19 '};

  # Create Rule
  my $rule = $vc->create_rule;
  
  # Rule syntax - integer, have error message
  $rule->topic('id')->check('int')->message('id should be integer');
  
  # Rule syntax - string, not blank, length is 1 to 5, have error messages
  $rule->topic('name')
    ->check('string')->message('name should be string')
    ->check('not_blank')->message('name should be not blank')
    ->check({length => [1, 5]})->message('name is too long');
  
  # Rule syntax - value is optional, default is 20
  $rule->topic('age')->optional->filter('trim')->check('int')->default(20);
  
  # Validation
  my $result = $rule->validate($input);
  if ($result->is_ok) {
    # Output
    my $output = $vresult->output;
  }
  else {
    # Error messgaes
    my $messages = $vresult->messages;
  }
  
  # You can create your original check
  my $blank_or_number = sub {
    my ($vc, $value, $arg) = @_;
    
    my $is_valid
      = $vc->run_check('blank', $value) || $vc->run_check('regex', $value, qr/[0-9]+/);
    
    return $is_valid;
  };
  $rule->topic('age')
    ->check($blank_or_number)->message('age must be blank or number')
  
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
    ->check({length => [1, 5]})->message('name must be length 1 to 5');

Please see L<Validator::Custom/"RULE"> about rule syntax.

You can use many check function,
such as C<int>, C<not_blank>, C<length>.
See L<Validator::Custom/"CONSTRAINTS">
to know all check functions.

Rule details is explained in L</"3. Rule syntax"> section.

B<4. Validate data>
  
  my $result = $vc->validate($input, $rule);

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

B<output> method

  my $output = $result->output;

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
  $rule->topic('id')->check('int')->message('id should be integer');
  
  # Rule syntax - not blank, length is 1 to 5, have error messages
  $rule->topic('name')
    ->check('not_blank')->message('name is emtpy')
    ->check({length => [1, 5]})->message('name is too long');
  
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

Default value. This value is automatically set to result data
if the parameter value is invalid or the parameter name specified in rule is missing in the data.

If you set not string or number value, you should the value which surrounded by code reference

  $rule->topic('age')->default(sub { [] })
  
=item 3. copy

  $rule->topic('age')->copy(0)

If this value is 0, The parameter value is not copied to result data. 
Default to 1. Parameter value is copied to the data.

=back

You set checks by C<check> method.

  $rule->topic('age')->check({'length' => [1, 5]});

You can set message for each check function

  $rule->topic('name')
    ->check('not_blank')->message('name must be not blank')
    ->check({length => [1, 5]})->message('name must be 1 to 5 length');

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

  Data: {password1 => 'xxx', password2 => 'xxx'}
  Rule: $rule->topic(['password1', 'password2'])->name('password_check)
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

  Data: {nums => [1, 2, 3]}
  Rule: $rule->topic('nums')->check_each('int')

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
      my ($vc, $value, $args) = @_;
      
      return $is_valid;
    }
  );

=head3 Register filter function

Filter function is registered by C<add_filter> method.

  $vc->add_filter(
    to_upper_case => sub {
      my ($vc, $value, $args) = @_;
      
      $value = uc $value;
                  
      return $value;
    }
  );

=head1 CHECKS

=head2 ascii

  Data: {name => 'Ken'}
  Rule: $rule->topic('name')->check('ascii')

Ascii graphic characters(hex 21-7e).

=head2 between

  # Check (1, 2, .. 19, 20)
  Data: {age => 19}
  Rule: $rule->topic('age')->check({between => [1, 20]})

Between A and B.

=head2 blank

  Data: {name => ''}
  Rule: $rule->topic('name')->check('blank')

Blank.

=head2 decimal
  
  Data: {num1 => '123', num2 => '1.45'}
  Rule: $rule->topic('num1')->check({'decimal' => 3})
        $rule->topic('num2')->check({'decimal' => [1, 2]})

Decimal. You can specify maximum digits number at before
and after '.'.

If you set undef value or don't set any value, that means there is no maximum limit.
  
  Data: {num1 => '1233555.89345', num2 => '1121111.45', num3 => '12.555555555'}
  Rule: $rule->topic('num1')->check('decimal')
        $rule->topic('num2')->check({'decimal' => [undef, 2]})
        $rule->topic('num2')->check({'decimal' => [2, undef]})

=head2 defined

  Data: {name => 'Ken'}
  Rule: $rule->topic('name')->check('defined')

Defined.

=head2 duplication

  Data: {mail1 => 'a@somehost.com', mail2 => 'a@somehost.com'};
  Rule: $rule->topic(['mail1', 'mail2'])->name('mail')->check('duplication)

Check if the two data are same or not.

You can get result value

  my $mail = $vresult->data->{mail};

Note that if one value is not defined or both values are not defined,
result of validation is false.

=head2 equal_to

  Data: {price => 1000}
  Rule: $rule->topic('price')->check({'equal_to' => 1000})

Numeric equal comparison.

=head2 greater_than

  Data: {price => 1000}
  Rule: $rule->topic('price')->check({'greater_than' => 900})

Numeric "greater than" comparison

=head2 http_url

  Data: {url => 'http://somehost.com'};
  Rule: $rule->topic('url')->check('http_url')

HTTP(or HTTPS) URL.

=head2 int

  Data: {age => 19};
  Rule: $rule->topic('age')->check('int')

Integer.

=head2 in_array

  Data: {food => 'sushi'};
  Rule: $rule->topic('food')->check({'in_array' => [qw/sushi bread apple/]})

Check if the values is in array.

=head2 length

  Data: {value1 => 'aaa', value2 => 'bbbbb'};
  Rule: # length is equal to 3
        $rule->topic('value1')->check({'length' => 3}) 
        # length is greater than or equal to 2 and lower than or equeal to 5
        $rule->topic('value2')->check({'length' => [2, 5]}) 
        # length is greater than or equal to 2 and lower than or equeal to 5
        $rule->topic('value3')->check({'length' => {min => 2, max => 5}}) 
        # greater than or equal to 2
        $rule->topic('value4')->check({'length' => {min => 2}}) 
        # lower than or equal to 5
        $rule->topic('value5')->check({'length' => {max => 5}}) 

Length of the value.

Not that if value is internal string, length is character length.
if value is byte string, length is byte length.

=head2 less_than

  Data: {num => 20}
  Rule: $rule->topic('num')->check({'less_than' => 25});

Numeric "less than" comparison.

=head2 not_blank

  Data: {name => 'Ken'}
  Rule: $rule->topic('name')->check('not_blank') # Except for ''

Not blank.

=head2 not_defined

  Data: {name => 'Ken'}
  Rule: $rule->topic('name')->check('not_defined')

Not defined.

=head2 not_space

  Data: {name => 'Ken'}
  Rule: $rule->topic('name')->check('not_space') # Except for '', ' ', '   '

Not contain only space characters. 
Not that space is only C<[ \t\n\r\f]>
which don't contain unicode space character.

=head2 space

  Data: {name => '   '}
  Rule: $rule->topic('name')->check('space') # '', ' ', '   '

White space or empty string.
Not that space is only C<[ \t\n\r\f]>
which don't contain unicode space character.

=head2 string

  Data: {name => 'abc'}
  Rule: $rule->topic('name')->check('string') # '', 'abc', 0, 1, 1.23

Check if the value is string, which contain numeric value.
if value is not defined or reference, this check return false.

=head2 uint

  Data: {age => 19}
  Rule: $rule->topic('age')->check('uint')

Unsigned integer(contain zero).
  
=head2 regex

  Data: {num => '123'}
  Rule: $rule->topic('num')->check({'regex' => qr/\d{0,3}/})

Match a regular expression.

=head2 selected_at_least

  Data: {hobby => ['music', 'movie' ]}
  Rule: $rule->topic('hobby')->check({selected_at_least => 1})

Selected at least specified count item.
In other word, the array contains at least specified count element.

=head1 FILTERS

You can use the following filter by default.
C<filter> method is only alias for C<check> method for readability.

=head2 date_to_timepiece

  Data: {date => '2010/11/12'}
  Rule: $rule->topic('date')->filter('date_to_timepiece')

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
  Rule: $rule->topic(['year', 'month', 'mday'])->name('date')
                                          ->filter('date_to_timepiece')

You can get result value.

  my $date = $vresult->data->{date};

Note that L<Time::Piece> is required.

=head2 datetime_to_timepiece

  Data: {datetime => '2010/11/12 12:14:45'}
  Rule: $rule->topic('datetime')->filter('datetime_to_timepiece');

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
  Rule: $rule->topic(['year', 'month', 'mday', 'hour', 'min', 'sec'])
          ->name('datetime')->filter('datetime_to_timepiece')

You can get result value.

  my $date = $vresult->data->{datetime};

Note that L<Time::Piece> is required.

=head2 merge

  Data: {name1 => 'Ken', name2 => 'Rika', name3 => 'Taro'}
  Rule: $rule->topic(['name1', 'name2', 'name3'])->name('mergd_name')
          ->filter('merge') # KenRikaTaro

Merge the values.

You can get result value.

  my $merged_name = $vresult->data->{merged_name};

Note that if one value is not defined, merged value become undefined.

=head2 shift

  Data: {names => ['Ken', 'Taro']}
  Rule: $rule->topic('names')->filter('shift') # 'Ken'

Shift the head element of array.

=head2 to_array

  Data: {languages => 'Japanese'}
  Rule: $rule->topic('languages')->filter('to_array') # ['Japanese']
  
Convert non array reference data to array reference.
This is useful to check checkbox values or select multiple values.

=head2 trim

  Data: {name => '  Ken  '}
  Rule: $rule->topic('name')->filter('trim') # 'Ken'

Trim leading and trailing white space.
Not that trim only C<[ \t\n\r\f]>
which don't contain unicode space character.

=head2 trim_collapse

  Data: {name => '  Ken   Takagi  '}
  Rule: $rule->topic('name')->filter('trim_collapse') # 'Ken Takagi'

Trim leading and trailing white space,
and collapse all whitespace characters into a single space.
Not that trim only C<[ \t\n\r\f]>
which don't contain unicode space character.

=head2 trim_lead

  Data: {name => '  Ken  '}
  Rule: $rule->topic('name')->filter('trim_lead') # 'Ken  '

Trim leading white space.
Not that trim only C<[ \t\n\r\f]>
which don't contain unicode space character.

=head2 trim_trail

  Data: {name => '  Ken  '}
  Rule: $rule->topic('name')->filter('trim_trail') # '  Ken'

Trim trailing white space.
Not that trim only C<[ \t\n\r\f]>
which don't contain unicode space character.

=head2 trim_uni

  Data: {name => '  Ken  '}
  Rule: $rule->topic('name')->filter('trim_uni') # 'Ken'

Trim leading and trailing white space, which contain unicode space character.

=head2 trim_uni_collapse

  Data: {name => '  Ken   Takagi  '};
  Rule: $rule->topic('name')->filter('trim_uni_collapse') # 'Ken Takagi'

Trim leading and trailing white space, which contain unicode space character.

=head2 trim_uni_lead

  Data: {name => '  Ken  '};
  Rule: $rule->topic('name')->filter('trim_uni_lead') # 'Ken  '

Trim leading white space, which contain unicode space character.

=head2 trim_uni_trail
  
  Data: {name => '  Ken  '};
  Rule: $rule->topic('name')->filter('trim_uni_trail') # '  Ken'

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

Register check function.
It receives Validator::Custom object, value, and arguments.
  
  $vc->add_check(
    int => sub {
      my ($vc, $value, $args) = @_;
      
      my $is_valid = $value =~ /^\-?[\d]+$/;
      
      return $is_valid;
    },
    greater_than => sub {
      my ($rule, $value, $arg_value) = @_;
      
      if ($value > $arg_value) {
        return 1;
      }
      else {
        return 0;
      }
    }
  );

You can return a error message when the validation fail.
Return hash reference which constains C<message>.

  $vc->add_check(
    foo => sub {
      my $is_valid;
      
      ...
      
      if ($is_valid) {
        return 1;
      }
      else {
        return {message => "Validation fail"};
      }
    }
  );

=head2 add_filter

You can add filter function. 
It receives Validator::Custom object, value, and arguments.
Filter function should be new value.

  $vc->add_filter(
    trim => sub {
      my ($vc, $value, $args) = @_;
      
      my $value = shift;
      $value =~ s/^\s+//;
      $value =~ s/\s+$//;
      
      return $value;
    }
  );

=head2 run_check

You can execute check fucntion.

  my $is_valid = $vc->run_check('int', $value);
  my $is_valid = $vc->run_check('length', $value, $args);

if return value is hash reference or false value, C<run_check> method return false value.
In other cases, C<run_check> method return true value.

=head2 run_filter

You can execute filter function.

  my $new_value = $vc->run_filter('trim', $value);
  my $new_value = $vc->run_filter('foo', $value, $args);

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

=head1 AUTHOR

Yuki Kimoto, C<< <kimoto.yuki at gmail.com> >>

L<http://github.com/yuki-kimoto/Validator-Custom>

=head1 COPYRIGHT & LICENCE

Copyright 2009-2014 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
