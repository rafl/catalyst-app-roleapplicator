package Catalyst::App::RoleApplicator;

use Moose::Exporter;
use Carp qw/confess/;
use Moose::Util qw/find_meta/;
use String::RewritePrefix;

use namespace::clean -except => 'meta';

Moose::Exporter->setup_import_methods;

my @attributes = map {
    [ $_, "${_}_class", "${_}_roles" ]
} qw/
    dispatcher
    engine
    context
    request
    response
    stats
/;

sub init_meta {
    my ($class, %opts) = @_;

    my $caller = $opts{for_class};

    my $meta = find_meta($caller);
    confess 'oh noes' unless $meta;

    $caller->mk_classdata(map { $_->[2] } @attributes);

    $meta->add_after_method_modifier(setup_finalize => sub {
        my ($app) = @_;
        for my $attr (@attributes) {
            my $roles = $app->${ \$attr->[2] };
            next unless $roles;

            Class::MOP::load_class($_)
                for map {
                    $_ = $app->_transform_role_name($attr->[0], $_)
                } @{ $roles };

            my $superclass = $app->${ \$attr->[1] };

            # hack: context_class doesn't have a default until the
            #       first request
            $superclass = $app
                if $attr->[0] eq 'context' && !$superclass;

            my $meta = Class::MOP::Class->create_anon_class(
                superclasses => [ $superclass ],
                roles        => $roles,
                cache        => 1,
            );
            $meta->add_method(meta => sub { $meta });

            $app->${ \$attr->[1] }($meta->name);
        }
    });

    $meta->add_method(_transform_role_name => sub {
        my ($app, $kind, $short) = @_;
        my $part = ucfirst $kind;
        return String::RewritePrefix->rewrite(
            { ''  => qq{Catalyst::${part}::Role::},
            '~' => qq{${app}::${part}::Role::},
            '+' => '' },
            $short,
        );
    });
}

1;
