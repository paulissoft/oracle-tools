#!/usr/bin/env perl

=pod

=head1 NAME

flyway.pl - Invoke the Flyway CLI and optionally generate an upgrade SQL

=head1 SYNOPSIS

  flyway.pl [Flyway OPTION...] [Flyway COMMAND]

=head1 DESCRIPTION

This script will:

=over 4

=item Invoke the C<devbox> Flyway CLI

Since that C<devbox> Flyway CLI version lacks Oracle wallet libraries in its
class path, the CLASSPATH environment variable will be added to its command
line class path (C<-classpath>).  It is up to the user to set CLASSPATH before
invoking this script.  When necessary the C<devbox run> command will be
invoked to install this Flyway CLI.

The devbox Flyway CLI script will be parsed to accomplish this. This is an
example of the script:

  #! /nix/store/a6akyvyh3j60yz9gajqbm155k2c7m5fc-bash-5.3p0/bin/bash -e
  exec "/nix/store/rd89a3gnapg7wzs7w3h6vv3b4ha7md5x-zulu-ca-jdk-21.0.4/bin/java"  -Djava.security.egd=file:/dev/../dev/urandom -classpath '/nix/store/19hlwfnjgh4rz8syvfkfmwf6r7vsj906-flyway-11.7.0/share/flyway/lib/*:/nix/store/19hlwfnjgh4rz8syvfkfmwf6r7vsj906-flyway-11.7.0/share/flyway/drivers/*' org.flywaydb.commandline.Main "$@" 

=item Generate an upgrade SQL when C<flyway info> is invoked with JSON output

Relevant Flyway command line options are C<-outputType=json>,
C<-outputFile=${flyway_info_json}> and the C<info> command. Only when those
three are available, the upgrade SQL script will be created. The upgrade SQL
script will be stored in the same directory as the Flyway JSON file with
naming convention C<upgrade-${YYYYMMDDHH24MISS}.sql>. After invoking C<flyway
info> of course.

This SQL upgrade script should execute the same actions as the C<flyway
migrate> command, but now the actions are not executed just written to the SQL
upgrade script.

This may be handy when the target environment will be a database where you do
not have SQL*Net access, so you can not use C<flyway migrate> (or the PATO GUI
based on that).

When the command line options do no match the three criteria, the Flyway CLI
command is invoked with the command line options. So this Perl script is just
Flyway CLI+.

=back

=head1 OPTIONS

The Flyway options parsed by this script:

=over 4

=item B<--manual>

The only non-Flyway option for printing this Perl POD manual.

=item B<--outputType=value>

The only possible C<value> is B<json>.

=item B<-outputFile=file>

The file to write the JSON to. An eventual SQL upgrade file will be written to
the directory of this JSON file with naming convention
C<upgrade-${YYYYMMDDHH24MISS}.sql>, where YYYYMMDDHH24MISS is the Oracle date
format for Year (4 digits), Month (2 digits), Days (2 digits), Hours (0-23),
MInutes (0-59) and Seconds (0-59).

=back

=head1 NOTES

=head1 EXAMPLES

=head1 BUGS

=head1 SEE ALSO

=head1 AUTHOR

Gert-Jan Paulissen

=head1 HISTORY

=over 4

=item 2025-09-23 G.J. Paulissen

First version.

=back

=cut

use 5.016003; # Strawberry perl: 5.18.2, Jenkins server: 5.16.3

use Cwd qw();
use Data::Dumper;
use File::Basename;
use File::Spec;
use Getopt::Long qw(:config pass_through no_ignore_case);
use JSON::PP;
use Pod::Usage;
use strict;
use warnings;

# prototypes
sub main();
sub parse_command_line();
sub slurp($);
sub update_devbox();
sub generate_upgrade_sql(); 

# global variables
my $debug = 0;
my $dir = dirname($0);
my $oracle_tools_dir = File::Spec->catdir($dir, '..', '..', '..');

# command line options
my $manual = 0;
my $output_type = undef;
my $output_file = undef;
my $flyway_command = undef;

main();

sub main() {
    parse_command_line();

    my $dir_sep = File::Spec->catfile('', ''); # file / or \
    my $path_sep = ( $dir_sep eq '/' ? ':' : ';' );
    my $CLASSPATH = exists $ENV{'CLASSPATH'} ? $ENV{'CLASSPATH'} : '';

    print "CLASSPATH: $CLASSPATH\n" if $debug;
    
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

    print "About to run '@args'\n" if $debug;
    
    system(@args) == 0 or die "Can not execute '@args': $1";

    generate_upgrade_sql();

    die "THE END" if $debug;
}

sub parse_command_line() {
    my @argv = @ARGV; # save @ARGV since GetOptions() will change it
    
    GetOptions("manual" => \$manual,
               "outputType=s" => \$output_type,
               "outputFile=s" => \$output_file)   # flag
        or pod2usage(2);
    pod2usage(-exitval => 0, -verbose => 2) if $manual;

    $flyway_command = pop(@ARGV);

    # restore @ARGV
    @ARGV = @argv;

    if ($debug) {
        print "-outputType=$output_type\n" if defined($output_type);
        print "-outputFile=$output_file\n" if defined($output_file);
        print "Flyway command: $flyway_command\n" if defined($flyway_command);
    }
}

sub slurp($) {
    my $contents = do { local(@ARGV, $/) = $_[0]; <> };

    return $contents;
}

sub setup_devbox() {
    my $cwd = Cwd::cwd();
    
    eval {
        die "Can't cd to $oracle_tools_dir: $!\n" unless chdir $oracle_tools_dir;

        my @args = ( 'devbox', 'run' );

        system(@args) == 0 or die "Can not run '@args': $!";
    };

    # back
    chdir($cwd);
    
    if ($@) {
        die $@;
    }
}

sub generate_upgrade_sql() {
    return unless (defined($output_type) && $output_type eq 'json');
    return unless (defined($output_file) && -f $output_file);
    return unless (defined($flyway_command) && $flyway_command eq 'info');

    # files must be relative to this file
    my $parent_project_dir = File::Spec->catdir(Cwd::cwd(), '..', '..');

    my $json_contents = slurp($output_file);
    my $json = JSON::PP->new->decode($json_contents);    
    my $timestamp = $json->{timestamp}; # timestamp: 2025-09-23T13:57:19.490407
    my ($yyyy, $mm, $dd, $hh24, $mi, $ss) = ($timestamp =~ m/^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})/);
    my $sql_output_file = File::Spec->catfile(dirname($output_file), "upgrade-${yyyy}${mm}${dd}${hh24}${mi}${ss}.sql");
    my $migrations = $json->{migrations};
    my $nr = 0;

    open(my $fh, '>', $sql_output_file);
    
    print $fh "prompt timestamp: $timestamp\n";
    print $fh "set define off\n";
    print $fh "whenever sqlerror exit failure\n";
    print $fh "whenever oserror exit failure\n";

    foreach my $migration (@{$migrations}) {
        $nr++;
        
        my $filepath = $migration->{filepath};
        my $file = File::Spec->abs2rel($filepath, $parent_project_dir);

        print $fh "prompt migration: ${nr} ---\n";
        print $fh "prompt file: $file\n";
        print $fh slurp($filepath);        
    }
    
    close $fh;
}
