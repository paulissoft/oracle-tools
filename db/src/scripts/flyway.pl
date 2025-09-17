#!/usr/bin/env perl

# usage: flyway.pl <text file with CLASSPATH> [flyway CLI command line argument...]

use strict;
use warnings;
use File::Basename;
use File::Spec;

# prototypes
sub main();
sub slurp($);

main();

sub main() {
    my $dir_sep = File::Spec->catfile('', ''); # file a/b/c
    my $path_sep = ( $dir_sep eq '/' ? ':' : ';' );
    my $dir = dirname($0);

    # classpath.txt example
    # ---------------------
    # /Users/gpaulissen/dev/bc/backoffice_rel_mgt/db/BC_HUBSPOT/target/classes:/Users/gpaulissen/.m2/repository/com/oracle/database/jdbc/ojdbc11/23.3.0.23.09/ojdbc11-23.3.0.23.09.jar:/Users/gpaulissen/.m2/repository/com/oracle/database/jdbc/ucp11/23.3.0.23.09/ucp11-23.3.0.23.09.jar:/Users/gpaulissen/.m2/repository/com/oracle/database/jdbc/rsi/23.3.0.23.09/rsi-23.3.0.23.09.jar:/Users/gpaulissen/.m2/repository/com/oracle/database/security/oraclepki/23.3.0.23.09/oraclepki-23.3.0.23.09.jar:/Users/gpaulissen/.m2/repository/com/oracle/database/ha/simplefan/23.3.0.23.09/simplefan-23.3.0.23.09.jar:/Users/gpaulissen/.m2/repository/com/oracle/database/ha/ons/23.3.0.23.09/ons-23.3.0.23.09.jar:/Users/gpaulissen/.m2/repository/com/oracle/database/nls/orai18n/23.3.0.23.09/orai18n-23.3.0.23.09.jar:/Users/gpaulissen/.m2/repository/com/oracle/database/xml/xdb/23.3.0.23.09/xdb-23.3.0.23.09.jar:/Users/gpaulissen/.m2/repository/com/oracle/database/xml/xmlparserv2/23.3.0.23.09/xmlparserv2-23.3.0.23.09.jar:/Users/gpaulissen/.m2/repository/com/oracle/database/security/osdt_core/21.11.0.0/osdt_core-21.11.0.0.jar:/Users/gpaulissen/.m2/repository/com/oracle/database/security/osdt_cert/21.11.0.0/osdt_cert-21.11.0.0.jar

    my $classpath_txt = shift(@ARGV);
    my $classpath = slurp('classpath.txt');

    $classpath =~ s/\R//g; # strip newline

    my @oracle_libs = map { m/\boracle\b/ ? ($_) : () } split($path_sep, $classpath);

    # .devbox/nix/profile/default/bin/flyway example
    # ----------------------------------------------
    # #! /nix/store/a6akyvyh3j60yz9gajqbm155k2c7m5fc-bash-5.3p0/bin/bash -e
    # exec "/nix/store/rd89a3gnapg7wzs7w3h6vv3b4ha7md5x-zulu-ca-jdk-21.0.4/bin/java"  -Djava.security.egd=file:/dev/../dev/urandom -classpath '/nix/store/19hlwfnjgh4rz8syvfkfmwf6r7vsj906-flyway-11.7.0/share/flyway/lib/*:/nix/store/19hlwfnjgh4rz8syvfkfmwf6r7vsj906-flyway-11.7.0/share/flyway/drivers/*' org.flywaydb.commandline.Main "$@" 

    my @flyway = split(/\R/, slurp("$dir/../../../.devbox/nix/profile/default/bin/flyway"));
    my $interpreter = shift(@flyway);

    @flyway = map { ( m!^exec\s+("/nix/store/.+)(-classpath\s+')([^']+)('.+)$! ? ("$1$2$3$path_sep" . join($path_sep, @oracle_libs) . "$4") : ($_))} @flyway;

    my $command = shift(@flyway);

    my @args = map { m/^("([^"]*)"|'([^']*)')$/ ? (substr($_, 1, -1)) : ($_) } split(/\s+/, $command);

    # remove "$@"
    pop(@args);

    push(@args, @ARGV);

    exec { $args[0] } @args;  # safe even with one-arg list
}

sub slurp($) {
    my $contents = do { local(@ARGV, $/) = $_[0]; <> };

    return $contents;
}
