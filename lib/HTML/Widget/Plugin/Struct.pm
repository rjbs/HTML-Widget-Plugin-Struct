use strict;
use warnings;
package HTML::Widget::Plugin::Struct;
# ABSTRACT: dump data structures for CGI::Expand expansion

use parent qw(HTML::Widget::Plugin);

=head1 DESCRIPTION

This plugin provides a means to dump a (somewhat) complex Perl data structure
to hidden widgets which can then be reconstructed by L<CGI::Expand>.

=cut

use Scalar::Util ();

=method provided_widgets

This plugin provides the following widgets: struct

=cut

sub provided_widgets { qw(struct) }

=method struct

C<struct> is the only widget provided by this plugin.  It accepts four
arguments:

 * name  - the base name for the widget (required, will default to id if given)
 * id    - the base id for the widget (optional)
 * class - a class to apply to each element generated (optional)
 * value - the structure to represent

The value can be an arbitrarily deep structure built from simple scalars, hash
references, and array references.  The inclusion of any other kind of data will
cause an exception to be raised.

References which appear twice will be treated as multiple occurances of
identical structures.  It won't be possible to tell that they were originally
references to the same datum.  Any circularity in the structure will cause an
exception to be raised.

=cut

sub struct {
  my ($self, $factory, $arg) = @_;

  $arg->{attr}{name} = $arg->{attr}{id}
    if ! defined $arg->{attr}{name} and defined $arg->{attr}{id};

  Carp::croak "no name provided for struct widget" unless
    defined $arg->{attr}{name} and length $arg->{attr}{name};

  return unless defined $arg->{value};

  my $ref_stack = [];

  $self->_build_struct($factory, $arg, $ref_stack);
}

my %DUMPER_FOR = (
  ''    => '_build_scalar_struct',
  HASH  => '_build_hash_struct',
  ARRAY => '_build_array_struct',
);

sub _build_struct {
  my ($self, $factory, $arg, $ref_stack) = @_;

  return '' unless defined $arg->{value};

  Carp::croak "looping data structure detected while dumping struct"
    if ref $arg->{value}
    and grep { $_ == Scalar::Util::refaddr($arg->{value}) } @$ref_stack;

  $self->_assert_value_ok($arg->{value});

  my $method = $DUMPER_FOR{ ref $arg->{value} };

  return $self->$method($factory, $arg, $ref_stack);
}

sub _build_scalar_struct {
  my ($self, $factory, $arg) = @_;

  return $factory->hidden({
    name  => $arg->{attr}{name},
    id    => $arg->{attr}{id},
    value => $arg->{value},
    class => $arg->{attr}{class},
  });
}

sub _build_hash_struct {
  my ($self, $factory, $arg, $ref_stack) = @_;

  my $has_id = defined $arg->{attr}{id} && length $arg->{attr}{id};

  my $widget = '';
  push @$ref_stack, Scalar::Util::refaddr($arg->{value});
  for my $key (keys %{ $arg->{value} }) {
    $widget .= $self->_build_struct(
      $factory,
      {
        value => $arg->{value}{$key},
        attr  => {
          ($has_id ? (id => "$arg->{attr}{id}.$key") : ()),
          name  => "$arg->{attr}{name}.$key",
          class => $arg->{attr}{class},
        },
      },
      $ref_stack,
    );
  }
  pop @$ref_stack;
  return $widget;
}

sub _build_array_struct {
  my ($self, $factory, $arg, $ref_stack) = @_;

  my $has_id = defined $arg->{attr}{id} && length $arg->{attr}{id};

  my $widget = '';
  push @$ref_stack, Scalar::Util::refaddr($arg->{value});
  for my $index (0 .. $#{ $arg->{value} }) {
    next unless defined $arg->{value}[$index];
    $widget .= $self->_build_struct(
      $factory,
      {
        value => $arg->{value}[$index],
        attr  => {
          name  => "$arg->{attr}{name}.$index",
          ($has_id ? (id => "$arg->{attr}{id}.$index") : ()),
          class => $arg->{attr}{class},
        },
      },
      $ref_stack,
    );
  }
  pop @$ref_stack;
  return $widget;
}

sub _assert_value_ok {
  my ($self, $value) = @_;

  return unless length (my $ref = ref $value);
  Carp::croak "can't widgetize objects" if Scalar::Util::blessed($value);
  Carp::croak "can't serialize $ref references" unless $DUMPER_FOR{ $ref };
}

=head1 TODO

=for :list
* improve the test suite

=cut

1;
