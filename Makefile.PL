use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'GD::Image::Scale2x',
	VERSION_FROM => 'lib/GD/Image/Scale2x.pm',
	EXE_FILES    => [ qw( bin/scale2x ) ],
	PREREQ_PM    => {
		'Test::More'      => 0,
		'GD'              => 0
	},
);
