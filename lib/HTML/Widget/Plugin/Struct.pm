
use strict;
use warnings;

package HTML::Widget::Plugin::Struct;
use base qw(HTML::Widget::Plugin);

use Scalar::Util ();

sub provided_widgets { qw(struct) }

sub struct {
  my ($self, $factory, $arg) = @_;

  Carp::croak "no name provided for struct widget" unless
    defined $arg->{attr}{name} and length $arg->{attr}{name};

  return unless defined $arg->{value};

  my $ref_stack = [];

  $self->_build_struct($factory, $arg, $ref_stack);
}

sub _build_struct {
  my ($self, $factory, $arg, $ref_stack) = @_;

  Carp::croak "looping data structure detected while dumping struct"
    if ref $_
    and grep { $_ == Scalar::Util::refaddr($arg->{value}) } @$ref_stack;

  $self->_assert_value_ok($arg->{value});

  if (not ref $arg->{value}) {
    return $factory->hidden({
      name  => $arg->{attr}{name},
      id    => $arg->{attr}{id},
      value => $arg->{value},
      class => $arg->{attr}{class},
    });
  }

  my $has_id = defined $arg->{attr}{id} && length $arg->{attr}{id};

  if (ref $arg->{value} eq 'HASH') {
    my $widget = '';
    for my $key (keys %{ $arg->{value} }) {
      $widget .= $factory->struct({
        name  => "$arg->{attr}{name}.$key",
        ($has_id ? (id => "$arg->{attr}{id}.$key") : ()),
        value => $arg->{value}{$key},
        class => $arg->{attr}{class},
      });
    }
    return $widget;
  }

  if (ref $arg->{value} eq 'ARRAY') {
    my $widget = '';
    for my $index (0 .. $#{ $arg->{value} }) {
      next unless defined $arg->{value}[$index];
      $widget .= $factory->struct({
        name  => "$arg->{attr}{name}.$index",
        ($has_id ? (id => "$arg->{attr}{id}.$index") : ()),
        value => $arg->{value}[$index],
        class => $arg->{attr}{class},
      });
    }
    return $widget;
  }
}


sub _assert_value_ok {
  my ($self, $value) = @_;

  return unless length (my $ref = ref $value);
  Carp::croak "can't widgetize objects" if Scalar::Util::blessed($value);
  Carp::croak "can't serialize $ref references"
    unless grep { $_ eq $ref } qw(ARRAY HASH);
}

1;
