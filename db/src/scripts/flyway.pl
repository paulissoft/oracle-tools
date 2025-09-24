#!/usr/bin/env perl

=pod

=head1 NAME

flyway.pl - Invoke the Flyway CLI and optionally generate a Flyway migrations SQL*Plus script

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

=item Generate a Flyway migrations SQL*Plus script when C<flyway info> is invoked with JSON output

Relevant Flyway command line options are C<-outputType=json>,
C<-outputFile=${flyway_info_json}> and the C<info> command. Only when those
three are available, the SQL*Plus script will be created. The SQL
script will be stored in the same directory as the Flyway JSON file with
naming convention C<flyway-migrations-${DB_SCHEMA}-${YYYYMMDDHH24MISS}.sql>. After invoking C<flyway
info> of course.

This SQL script should execute the same actions as the C<flyway
migrate> command, but now the actions are not executed just written to the SQL
script.

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

=item B<--configFiles=value>

Here C<value> is a comma-separated list of properties files.

=item B<--outputType=value>

The only possible C<value> is B<json>.

=item B<-outputFile=file>

The file to write the JSON to. An eventual SQL script will be written to
the directory of this JSON file with naming convention
C<flyway-migrations-${DB_SCHEMA}-${YYYYMMDDHH24MISS}.sql>, where YYYYMMDDHH24MISS is the Oracle date
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
sub generate_sql_script_preamble($$$$);
sub generate_sql_script(); 

# global variables
my $debug = 0;
my $dir = dirname($0);
my $oracle_tools_dir = File::Spec->catdir($dir, '..', '..', '..');

# command line options
my $manual = 0;
my $config_files = undef;
my $output_type = undef;
my $output_file = undef;
my $flyway_command = undef;

# derived from $config_files
my %flyway_properties = {};

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

    generate_sql_script();

    die "THE END" if $debug;
}

sub parse_command_line() {
    my @argv = @ARGV; # save @ARGV since GetOptions() will change it
    
    GetOptions("manual" => \$manual,
               "configFiles=s" => \$config_files,
               "outputType=s" => \$output_type,
               "outputFile=s" => \$output_file)   # flag
        or pod2usage(2);
    pod2usage(-exitval => 0, -verbose => 2) if $manual;

    $flyway_command = pop(@ARGV);

    # restore @ARGV
    @ARGV = @argv;

    # foreach config file
    foreach my $config_file (split(/,/, $config_files)) {
        # foreach line ($_)
        foreach (split(/\R/, slurp($config_file))) {
            $flyway_properties{$1} = $2 if m/^([^=]+)=(.*)$/;
        }
    }

    if ($debug) {
        print "-outputType=$output_type\n" if defined($output_type);
        print "-outputFile=$output_file\n" if defined($output_file);
        print "Flyway command: $flyway_command\n" if defined($flyway_command);
        foreach (sort keys %flyway_properties) {
            print "Flyway property $_=$flyway_properties{$_}\n";
        }
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

sub generate_sql_script_preamble($$$$) {
    my ($fh, $timestamp, $flyway_table, $db_schema) = @_;    

    # get max("installed_rank") + 1 as next_installed_rank variable
    # create flyway table if necessary
    my $preamble = <<"PREAMBLE";
pause Should be run by user $db_schema. Press RETURN to continue...
prompt flyway info timestamp: $timestamp
set define off
whenever sqlerror exit failure
whenever oserror exit failure

var next_installed_rank number;

declare
  l_table_name constant user_tables.table_name%type := '$flyway_table';
  l_cursor sys_refcursor;
  -- ORA-00942: table or view does not exist
  e_table_or_view_does_not_exist exception;
  pragma exception_init(e_table_or_view_does_not_exist, -942);
begin
  open l_cursor for 'select nvl(max("installed_rank"), 0) + 1 from "' || l_table_name || '"';
  fetch l_cursor into :next_installed_rank;
  close l_cursor;
exception
  when e_table_or_view_does_not_exist
  then
    if l_cursor%isopen then close l_cursor; end if;
    :next_installed_rank := 1;
    execute immediate utl_lms.format_message
                      ( '
CREATE TABLE "%s"
( "installed_rank" INTEGER NOT NULL, 
  "version" VARCHAR2(50 BYTE), 
  "description" VARCHAR2(200 BYTE) NOT NULL, 
  "type" VARCHAR2(20 BYTE) NOT NULL, 
  "script" VARCHAR2(1000 BYTE) NOT NULL, 
  "checksum" INTEGER, 
  "installed_by" VARCHAR2(100 BYTE) NOT NULL, 
  "installed_on" TIMESTAMP (6) DEFAULT CURRENT_TIMESTAMP NOT NULL, 
  "execution_time" INTEGER NOT NULL, 
  "success" NUMBER(1,0) NOT NULL, 
  CONSTRAINT "%s_pk" PRIMARY KEY ("installed_rank")
)'
                      , l_table_name
                      , l_table_name
                      );
    execute immediate utl_lms.format_message
                      ( 'CREATE INDEX "%s_s_idx" ON "%s" ("success")'
                      , l_table_name
                      , l_table_name
                      );
end;
/ 
PREAMBLE

    print $fh "$preamble\n";
}

sub generate_sql_script() {
    return unless (defined($output_type) && $output_type eq 'json');
    return unless (defined($output_file) && -f $output_file);
    return unless (defined($flyway_command) && $flyway_command eq 'info');

    # files must be relative to the parent project directory 
    my $parent_project_dir = File::Spec->catdir(Cwd::cwd(), '..', '..');

    my $json_contents = slurp($output_file);
    my $json = JSON::PP->new->decode($json_contents);    
    my $timestamp = $json->{timestamp}; # timestamp: 2025-09-23T13:57:19.490407
    my ($yyyy, $mm, $dd, $hh24, $mi, $ss) = ($timestamp =~ m/^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})/);
    my $flyway_table = $flyway_properties{'flyway.table'};
    my $db_schema = $flyway_properties{'flyway.user'};

    # BC_PROXY[BC_BO] => BC_BO
    $db_schema = $1
        if ($db_schema =~ m/\[([^\]]+)\]/);
    
    my $sql_output_file = File::Spec->catfile(dirname($output_file), "flyway-migrations-${db_schema}-${yyyy}${mm}${dd}${hh24}${mi}${ss}.sql");
    my $migrations = $json->{migrations};
    my $nr = 0;

    open(my $fh, '>', $sql_output_file);

    generate_sql_script_preamble($fh, $timestamp, $flyway_table, $db_schema);

    foreach my $migration (@{$migrations}) {
        if ($debug) {
            foreach my $key (sort keys %$migration) {
                my $value = $migration->{$key};
                
                print $fh "-- $key: $value\n" if defined($value);
            }
        }
            
        if ($migration->{state} eq 'Pending') {
            $nr++;

            my $filepath = $migration->{filepath};
            my $file = File::Spec->abs2rel($filepath, $parent_project_dir);
            my $version = defined($migration->{version}) ? $migration->{version} : '';
            my $description = $migration->{description};
            my $type = $migration->{type};
            my $script = basename($filepath);

            print $fh "prompt migration: ${nr} ---\n";
            print $fh "prompt file: $file\n";
            
            my $insert = <<"INSERT";
-- add flyway migration info (not successful for the moment)
insert into "$flyway_table"("installed_rank", "version", "description", "type", "script", "installed_by", "execution_time", "success")
values (:next_installed_rank, '$version', '$description', '$type', '$script', user, 0, 0);
-- start migration
INSERT

            print $fh "$insert\n";
            # execute the migration
            print $fh slurp($filepath);

            my $update = <<"UPDATE";
-- flyway migration is successful
begin
  update "$flyway_table" set "success" = 1 where "installed_rank" = :next_installed_rank;
  :next_installed_rank := :next_installed_rank + 1;
end;
/
-- next migration
UPDATE

            print $fh "$update\n";            
        }
    }
    
    close $fh;
}

