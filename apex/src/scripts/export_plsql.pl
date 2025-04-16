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

my $fh = undef;

while (<>) {
    if (m!^-- === (file \d+: (.+)) ===$!) {
        my ($description, $file) = ($1, $2);
        
        print STDOUT "creating $description\n";
        $fh->close
            if defined($fh);
        $fh = new IO::File "> $file";
    } elsif ($fh) {
        $fh->print($_);
    }
}

$fh->close
    if defined($fh);
