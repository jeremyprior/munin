
use strict;
use warnings;

use Test::More;

use IO::Scalar;
use File::Find;

plan skip_all => 'set TEST_DOC to enable this test' unless $ENV{TEST_DOC};

# both are in standard distribution, but just in case...
eval {
    require Pod::Simple::SimpleTree;
    require Test::Differences;
};
plan skip_all =>
    'Pod::Simple::SimpleTree and Test::Differences required to run these tests'
    if $@;

Test::Differences->import();

sub check_munindoc {
    return if -d;

    my $plugin = $File::Find::name;

    my @sections = (
        'NAME',
        'APPLICABLE SYSTEMS',
        'CONFIGURATION',
        'INTERPRETATION',
        (m{snmp__} ? 'MIB INFORMATION' : ()),
        'MAGIC MARKERS',
        'BUGS',
        'AUTHOR',
        'LICENSE',
    );

    my $root = Pod::Simple::SimpleTree->new->parse_file($plugin)->root;

    # FIXME: check for POD errors?

    my @headings;

    foreach my $section (@$root) {

        # ignore any inapplicable headings
        next unless 'ARRAY' eq ref $section;
        next unless $section->[0] eq 'head1';
        next unless grep { $_ eq $section->[2] } @sections;

        push @headings, $section->[2];
    }

    eq_or_diff( \@headings, \@sections, "$plugin - All POD sections exist" );

    # additional tests?
}

# find_pod_files doesn't work because (a) they don't end in .p[lm], (b) their
# shebang file is "broken" and (c) some plugins aren't even perl (shock!  horror!).
find(
    {   wanted   => \&check_munindoc,
        no_chdir => 1,
    },
    glob('plugins/node.d*/')
);
