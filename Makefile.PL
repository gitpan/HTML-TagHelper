use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTML::TagHelper',
    AUTHOR              => 'Gitte Wange Olrik <gitte@olrik.dk>',
    VERSION_FROM        => 'lib/HTML/TagHelper.pm',
    ABSTRACT_FROM       => 'lib/HTML/TagHelper.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
				'Class::Accessor::Fast' => 0,
				'HTML::Element' => 0,
				'Carp' => 0,
				'DateTime' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTML-TagHelper-*' },
);
