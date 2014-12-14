package Getopt::Long::Patch::DumpAndExit;

# DATE
# VERSION

use 5.010001;
use strict;
no warnings;

use Data::Dump;
use Module::Patch 0.19 qw();
use base qw(Module::Patch);

our %config;

sub _dump {
    print "# BEGIN DUMP $config{-tag}\n";
    dd @_;
    print "# END DUMP $config{-tag}\n";
}

sub _GetOptions(@) {
    # discard optional first hash argument
    if (ref($_[0]) eq 'HASH') {
        shift;
    }
    my %spec = @_;
    _dump(\%spec);
    $config{-exit_method} eq 'exit' ? exit(0) : die;
}

sub _GetOptionsFromArray(@) {
    # discard array
    shift;
    # discard optional first hash argument
    if (ref($_[0]) eq 'HASH') {
        shift;
    }
    my %spec = @_;
    _dump(\%spec);
    $config{-exit_method} eq 'exit' ? exit(0) : die;
}

sub _GetOptionsFromString(@) {
    # discard string
    shift;
    # discard optional first hash argument
    if (ref($_[0]) eq 'HASH') {
        shift;
    }
    my %spec = @_;
    _dump(\%spec);
    $config{-exit_method} eq 'exit' ? exit(0) : die;
}

sub patch_data {
    return {
        v => 3,
        patches => [
            {
                action      => 'replace',
                sub_name    => 'GetOptions',
                code        => \&_GetOptions,
            },
            {
                action      => 'replace',
                sub_name    => 'GetOptionsFromArray',
                code        => \&_GetOptionsFromArray,
            },
            {
                action      => 'replace',
                sub_name    => 'GetOptionsFromString',
                code        => \&_GetOptionsFromString,
            },
        ],
        config => {
            -tag => {
                schema  => 'str*',
                default => 'TAG',
            },
            -exit_method => {
                schema  => 'str*',
                default => 'exit',
            },
        },
   };
}

1;
# ABSTRACT: Patch Getopt::Long to dump option spec and exit

=for Pod::Coverage ^(patch_data)$

=head1 DESCRIPTION

This patch can be used to extract Getopt::Long options specification from a
script by running the script but exiting early after getting the specification.

