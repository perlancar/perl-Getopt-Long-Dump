package Getopt::Long::Dump;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(dump_getopt_long_script);

our %SPEC;

$SPEC{dump_getopt_long_script} = {
    v => 1.1,
    summary => 'Run a Getopt::Long-based script but only to '.
        'dump the spec',
    description => <<'_',

This function runs a CLI script that uses `Getopt::Long` but monkey-patches
beforehand so that `run()` will dump the object and then exit. The goal is to
get the object without actually running the script.

This can be used to gather information about the script and then generate
documentation about it or do other things (e.g. `App::shcompgen` to generate a
completion script for the original script).

CLI script needs to use `Getopt::Long`. This is detected currently by a simple
regex. If script is not detected as using `Getopt::Long`, status 412 is
returned.

Will return the `Getopt::Long` specification.

_
    args => {
        filename => {
            summary => 'Path to the script',
            req => 1,
            schema => 'str*',
        },
        libs => {
            summary => 'Libraries to unshift to @INC when running script',
            schema  => ['array*' => of => 'str*'],
        },
    },
};
sub dump_getopt_long_script {
    require Capture::Tiny;
    require Getopt::Long::Util;
    require UUID::Random;

    my %args = @_;

    my $filename = $args{filename} or return [400, "Please specify filename"];
    my $detres = Getopt::Long::Util::detect_getopt_long_script(
        filename => $filename);
    return $detres if $detres->[0] != 200;
    return [412, "File '$filename' is not script using Getopt::Long (".
        $detres->[3]{'func.reason'}.")"] unless $detres->[2];

    my $libs = $args{libs} // [];

    my $tag = UUID::Random::generate();
    my @cmd = (
        $^X, (map {"-I$_"} @$libs),
        "-MGetopt::Long::Patch::DumpAndExit=-tag,$tag",
        $filename,
        "--version",
    );
    my ($stdout, $stderr, $exit) = Capture::Tiny::capture(
        local $ENV{GETOPT_LONG_DUMP} = 1;
        sub { system @cmd },
    );

    my $spec;
    if ($stdout =~ /^# BEGIN DUMP $tag\s+(.*)^# END DUMP $tag/ms) {
        $spec = eval $1;
        if ($@) {
            return [500, "Script '$filename' detected as using ".
                        "Getopt::Long, but error in eval-ing captured ".
                            "option spec: $@, raw capture: <<<$1>>>"];
        }
        if (ref($spec) ne 'HASH') {
            return [500, "Script '$filename' detected as using ".
                        "Getopt::Long, but didn't get a hash option spec, ".
                            "raw capture: stdout=<<$stdout>>"];
        }
    } else {
        return [500, "Script '$filename' detected as using Getopt::Long, ".
                    "but can't capture option spec, raw capture: ".
                        "stdout=<<$stdout>>, stderr=<<$stderr>>"];
    }

    [200, "OK", $spec];
}

1;
# ABSTRACT:

=head1 ENVIRONMENT

=head2 GETOPT_LONG_DUMP => bool

Will be set to 1 when executing the script to be dumped.
