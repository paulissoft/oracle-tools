#!/usr/bin/env perl

=pod

=head1 NAME

=head1 SYNOPSIS

perl export_pl.sql FILE...

=head1 DESCRIPTION

Parse output created by oracle_tools.ui_apex_export_pkg.get_application like this:

  -- === file 0001: f138/application/set_environment.sql ===
  prompt --application/set_environment
  set define off verify off feedback off
  whenever sqlerror exit sql.sqlcode rollback
  ...
  -- === file 0002: f138/application/delete_application.sql ===
  ...

For every header line (a line matching '^-- === (file \d+): (.+) ===$'),
the file ($2) must be created with as content the lines following this header line.

=cut

use autodie;
use warnings;
use IO::File;
use File::Path qw(make_path);
use File::Basename;

my ($fh, $description, $file) = (undef, undef, undef);
my $debug = 0;

while (<>) {
    # print STDERR $_;
    if (m!^-- === (file \d+): (.+) ===$!) {
        ($description, $file) = ($1, $2);
        
        print STDOUT "creating $description: $file\n";

        make_path(dirname($file));

        print STDOUT "created directory ", dirname($file), "\n"
            if ($debug);

        $fh->close
            if defined($fh);
        
        $fh = new IO::File "> $file";

        die "Could not open file $file: $!"
            unless defined($fh);

        print STDOUT "opened $file\n"
            if ($debug);
    } elsif ($fh) {
        $fh->print($_);

        print STDOUT "written $_ to $file\n"
            if ($debug);
    }
}

$fh->close
    if defined($fh);
