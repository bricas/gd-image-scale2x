use strict;

use Module::Build;

my $build = Module::Build->new(
    module_name        => 'GD::Image::Scale2x',
    dist_author        => 'Brian Cassidy <bricas@cpan.org>',
    license            => 'perl',
    create_readme      => 1,
    create_makefile_pl => 'traditional',
    script_files       => [ qw( bin/scale2x ) ],
    requires           => {
        'GD' => 0
    },
    build_requires     => {
        'Test::More'  => 0
    },
);
$build->create_build_script;
