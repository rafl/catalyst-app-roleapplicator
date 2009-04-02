package TestApp;

use Moose;
use Catalyst::App::RoleApplicator;

use namespace::clean -except => 'meta';

extends 'Catalyst';

__PACKAGE__->request_roles([qw/Foo ~Bar/]);

__PACKAGE__->setup;

1;
