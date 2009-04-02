package TestApp::Controller::Foo;

use Moose;

use namespace::clean -except => 'meta';

BEGIN { extends 'Catalyst::Controller' }

sub request : Local {
    my ($self, $ctx) = @_;
    $ctx->response->body(join q{, }, map { $_->name } @{ $ctx->response->meta->roles });
}

1;
