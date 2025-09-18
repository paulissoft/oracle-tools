#!/usr/bin/env perl

# usage: flyway.pl [flyway CLI command line argument...]

use strict;
use warnings;
use File::Basename;
use File::Spec;
use File::chdir;

# prototypes
sub main();
sub slurp($);
sub update_devbox();

my $dir = dirname($0);
my $oracle_tools_dir = File::Spec->catdir($dir, '..', '..', '..');

main();

sub main() {
    my $dir_sep = File::Spec->catfile('', ''); # file / or \
    my $path_sep = ( $dir_sep eq '/' ? ':' : ';' );
    my $CLASSPATH = exists $ENV{'CLASSPATH'} ? $ENV{'CLASSPATH'} : '';

    print "CLASSPATH: $CLASSPATH\n";
    
    my @oracle_libs = map { m/\boracle\b/ ? ($_) : () } split($path_sep, $CLASSPATH);

    # .devbox/nix/profile/default/bin/flyway example
    # ----------------------------------------------
    # #! /nix/store/a6akyvyh3j60yz9gajqbm155k2c7m5fc-bash-5.3p0/bin/bash -e
    # exec "/nix/store/rd89a3gnapg7wzs7w3h6vv3b4ha7md5x-zulu-ca-jdk-21.0.4/bin/java"  -Djava.security.egd=file:/dev/../dev/urandom -classpath '/nix/store/19hlwfnjgh4rz8syvfkfmwf6r7vsj906-flyway-11.7.0/share/flyway/lib/*:/nix/store/19hlwfnjgh4rz8syvfkfmwf6r7vsj906-flyway-11.7.0/share/flyway/drivers/*' org.flywaydb.commandline.Main "$@" 

    setup_devbox();
    
    my @flyway = split(/\R/, slurp(File::Spec->catfile($oracle_tools_dir, '.devbox', 'nix', 'profile', 'default', 'bin', 'flyway')));
    my $interpreter = shift(@flyway);

    # only the command rests
    
    # strip exec at the beginning of the command, append $CLASSPATH at the end of the -classpath command line option
    @flyway = map { ( m!^exec\s+("/nix/store/.+)(-classpath\s+')([^']+)('.+)$! ? ("$1$2$3$path_sep" . join($path_sep, @oracle_libs) . "$4") : ($_))} @flyway;

    my $command = shift(@flyway);

    # strip Shell (double) quotes around strings
    my @args = map { m/^("([^"]*)"|'([^']*)')$/ ? (substr($_, 1, -1)) : ($_) } split(/\s+/, $command);

    # remove "$@"
    pop(@args);

    # push flyway command line arguments
    push(@args, @ARGV);

    exec { $args[0] } @args;  # safe even with one-arg list
}

sub slurp($) {
    my $contents = do { local(@ARGV, $/) = $_[0]; <> };

    return $contents;
}

sub setup_devbox() {
    local $CWD = $oracle_tools_dir;

    my @args = ( 'devbox', 'run' );

    system(@args) == 0 or die "Can not run '@args': $!";
}
