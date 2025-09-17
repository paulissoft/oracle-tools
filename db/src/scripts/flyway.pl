#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;

# prototypes
sub slurp($);
    
my $dir = dirname($0);
my $flyway = slurp("$dir/../../../.devbox/nix/profile/default/bin/flyway");
my $classpath = slurp('classpath.txt');

print "command line arguments: @ARGV\n";
print "classpath: $classpath\n";
print "flyway: $flyway\n";

sub slurp($) {
    my $contents = do { local(@ARGV, $/) = $_[0]; <> };

    return $contents;
}
