use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME                => 'HTML-Widget-Plugin-Struct',
	AUTHOR              => 'Ricardo SIGNES <rjbs@cpan.org>',
	VERSION_FROM        => 'lib/HTML/Widget/Plugin/Struct.pm',
	PL_FILES            => {},
	PREREQ_PM => {
		'HTML::Widget::Factory' => 0.00, # prereq unknown
    'Scalar::Util'          => 0.00, # min unknown; refaddr, reftype, blessed
	},
	dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean               => { FILES => 'HTML-Widget-Factory-*' },
  (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'perl') : ()),
);
