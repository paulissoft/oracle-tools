#!/usr/bin/env perl

=pod

=head1 NAME

generate_ddl.pl - Generate DDL for database schema(s)

=head1 SYNOPSIS

  generate_ddl.pl [OPTION...]

=head1 DESCRIPTION

This script will 

=over 4

=item GENERATE DDL SCRIPTS FOR A FULL INSTALLATION

The SOURCE schema (including database link) is used to generate the DDL
scripts for that schema. The TARGET schema (and database link) must be
unspecified (or empty).

In this situation you should set the output directory.

The following files will be created:
- <seq>.[<owner>.]<type>.<name> (incremental scripts)
- R__<seq>.[<owner>.]<type>.<name> (repeatable scripts)

The owner will not be part of the file name if the strip source schema command line option is true.

If the pkg_ddl_util interface version is 4 the sequence number is dependent on the type.

If the pkg_ddl_util interface version is 5 the sequence number depends on the
installation sequence order as specified in file !README_BEFORE_ANY_CHANGE.txt which is
initially created in object dependency order.

=item GENERATE DDL SCRIPTS FOR AN INCREMENTAL INSTALLATION

The SOURCE and TARGET schema (including database links) are used to generate
the DDL scripts to migrate the TARGET schema to the SOURCE state.  When the
generated script is run against the TARGET schema, the result is that the
TARGET schema is identical to the SOURCE schema (excluding data).

In this situation you should set the single output file.

The single output file may include a filter for the SQL statement number like this:

  <prefix>@nr@<suffix>

This way it is easier to recover from a Flyway versioned migration.

=item GENERATE DDL SCRIPTS FOR AN UNINSTALL

The SOURCE (and database link) schema is empty. Please note that comparing an
empty source schema to a target schema will generate DDL statements for the
target schema such that it becomes empty after running those statements
against that schema.

For the rest see GENERATE DDL SCRIPTS FOR AN INCREMENTAL INSTALLATION. 

=back

=head1 OPTIONS

=over 4

=item B<--dynamic-sql>

Use dbms_sql.parse() to parse the actual SQL statement. This may be necessary
if the script(s) will be executed by a tool which does not recognize the
Oracle SQL syntax but which simply recognizes PL/SQL blocks.

The generated statement will be something like:

  /* Use dbms_sql.parse() to execute the SQL statement since it is easier to parse and because it supports a statement size > 32K. */
  declare
    c integer := dbms_sql.open_cursor;
    s dbms_sql.varchar2a;
    procedure add(l in varchar2)
    is
    begin
      s(s.count+1) := l || chr(10);
    end add;
  begin
    add(q'{CREATE OR REPLACE PACKAGE BODY "COMP_STM"."STM_DDL_UTIL" is}');
    add(q'{}');
    add(q'{  /* TYPES */}');
  ...
    add(q'{end stm_ddl_util;}');
    dbms_sql.parse(c => c, statement => s, lb => s.first, ub => s.last, lfflg => false, language_flag => dbms_sql.native);
    dbms_sql.close_cursor(c);
  end;
  /

=item B<--force-view>

If this option is enabled (the default) the FORCE keyword in CREATE OR REPLACE FORCE VIEW ... is NOT removed.

Example: the option

  --noforce-view

disables this option and thus the FORCE keyword will be removed.

=item B<--group-constraints>

If this option is enabled (the default) and the interface is not version 4,
all constraints will be grouped in one file for the referential constraints
per base object and one for the other constraints per base object.  The
install.sql will then create the referential constraints at the end.

=item B<--help>

This help.

=item B<--input-file>

For debugging purposes.

=item B<--output-directory>

The output directory, default the current directory.

=item B<--single-output-file>

Normally output files will be created for each object in the output
(sub)directories.  For example every object SCHEMA.TABLE.NAME will have as
output file <output directory>/SCHEMA/TABLE/NAME.sql.  When this option is
set, the (single) output file will be <output directory>/<single output file>.

=item B<--skip-install-sql>

Skip creating the install.sql file while generation scripts. Default true (skip).

=item B<--source-schema>

A SOURCE schema.

=item B<--strip-source-schema>

Strip the SOURCE schema from the CREATE DDL and from the generated file name. Defaults to false.

=item B<--test>

Run a unit test.

=item B<--verbose>

Increase verbose logging. Defaults to environment variable VERBOSE if set to a number, otherwise 0.

=item B<--version>

Show the version.

=back

=head1 NOTES

=head1 EXAMPLES

=head1 BUGS

=head1 SEE ALSO

=head1 AUTHOR

Gert-Jan Paulissen

=head1 HISTORY

=over 4

=item 2023-05-03

The DDL for a view with an instead of trigger should be placed into the same
file. Due to the fact that the temporary file was removed after printing the
view DDL, the trigger DDL later on replaced the view DDL (instead of being
appended).

=item 2023-01-05

This DDL:

CREATE OR REPLACE VIEW "ORACLE_TOOLS"."V_DISPLAY_DDL_SCHEMA" ("SCHEMA_DDL")  BEQUEATH CURRENT_USER  AS select  value(t) as schema_ddl
from  table(oracle_tools.pkg_ddl_util.display_ddl_schema) t;

should transform into:

CREATE OR REPLACE VIEW "ORACLE_TOOLS"."V_DISPLAY_DDL_SCHEMA" ("SCHEMA_DDL")  BEQUEATH CURRENT_USER  AS 
select  value(t) as schema_ddl
from  table(oracle_tools.pkg_ddl_util.display_ddl_schema) t;

=item 2022-12-02

The strip source schema functionality did not work well: reading existing
scripts, writing scripts, replacement of schema in DDL (schema.object).

=item 2022-09-28

Constraints can be grouped in one file per base object (one for referential and one for the rest).

=item 2022-09-06

Making it easier to see duplicate objects in the output directory.

=item 2022-07-17 (2)

ENHANCEMENT: The generated DDL install.sql should use show errors after every stored procedure.

See also L<https://github.com/paulissoft/oracle-tools/issues/37>.

=item 2022-07-17 (1)

BUG: the referential constraints are not created in the correct order in the install.sql file.

This is the case when the interface is version 5 and there are two referential constraints T1-R1 and T1-R2 for table T1, where T1-R2 depends on a primary key constraint T2-C1. The old behaviour was to combine (referential) contraints per table in a file, meaning files like *.REF_CONSTRAINT.T1.sql and *.CONSTRAINT.T2.sql. Hence the referential constraint T1-R2 would be created in the install.sql before the primary key T2-C1 since T1-R1 is mentioned earlier than T2-C1 in the DDL info file (order is T1-R1, T2-C1, T1-R2) and T1-R2 is added to its referential constraint file.

The solution is to have a single file for each (referental) constraint and not to combine them. The file name part <name> will be a combination of the table, a dash and the name of the constraint.

Another solution would be to postpone creation of *.REF_CONSTRAINT.*.sql files and only create them at the end. But that is a little bit more difficult to implement.

See also L<https://github.com/paulissoft/oracle-tools/issues/35>.

=item 2022-04-26

Solved bug for objects named like "name" where name is not totally upper case.

=item 2021-08-27

Create the file in the output directory only when it is different from the
existing one (or when it does not exist).  This assures that the file
modification date will not change when the DDL has not changed.

The command line option remove-output-directory is not necessary anymore since
files are first created in a temporary directory and copied only when not the
same. Files not created in the temporary directory will be removed at the end
from the output directory.

For example, say install.sql exists in the output directory.

=item 2021-08-25

Solved bug for interface version 5 when file instal_sequence.txt is not there.

=item 2021-08-24

Version 5 of the pkg_ddl_util interface has been added. 
Only supports version 4 and 5 of that interface now.

=item 2021-07-28

Version is now shown as the change date. All relevant command line options are
printed to standard error on start up.

=item 2017-05-10

As a developer I want to be able to have versioned migration scripts with just
one statement so I can easy recover from a failed versioned migration.

Versioned migrations are named VZ<><timestamp>*.sql. When the migration fails
after the first statement it is hard to recover. So it is better to have one
script per statement. Adding a filter @nr@ to the single output file in
generate_ddl.(xml|pl) does the trick.

=item 2017-02-28

Unique constraints must be created before a referencing key is created.

When an incremental script was generated (using the --single-output-file
option) a foreign constraint was created before the primary key was there.
The problem was that the database correctly determined the order, but all the
DDL statements were saved for each and every object. Later on the objects are
retrieved and their DDL statements were printed to a single output file. The
solution is to use one dummy object so the order of DDL statements is preserved.

=item 2016-10-19

The option force-view is added.

=item 2016-10-18

Instead of triggers are put together with their view because when a view is
created or replaced the trigger is dropped. Putting them in one script
enforces the recreation of the trigger.

=item 2016-04-12  G.J. Paulissen

Handling of whitespace at the end of the line and empty lines enhanced.

=item 2016-01-06  G.J. Paulissen

Handling of SQL and PL/SQL delimiters enhanced. Now the SQL delimiter (;) is
written on the same line as the DDL so a comment line will not issue old DDL
as before.

=item 2015-07-21  G.J. Paulissen

First version.

=back

=cut

# use POSIX;
#use autodie qw(:all);

use 5.016003; # Strawberry perl: 5.18.2, Jenkins server: 5.16.3

use Carp;
use English;
use File::Basename;
use File::Compare;
use File::Copy;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Getopt::Long;
use Pod::Usage;
use strict;
use utf8;
use warnings;

# CONSTANTS
use constant PKG_DDL_UTIL_V4 => 'pkg_ddl_util v4';
use constant PKG_DDL_UTIL_V5 => 'pkg_ddl_util v5';
use constant OLD_INSTALL_SEQUENCE_TXT => 'install_sequence.txt';
use constant NEW_INSTALL_SEQUENCE_TXT => '!README_BEFORE_ANY_CHANGE.txt';
use constant FILE_UNKNOWN => 'FILE_UNKNOWN'; 
use constant FILE_NOT_REUSED => 'FILE_NOT_REUSED'; 
use constant FILE_NOT_MODIFIED => 'FILE_NOT_MODIFIED';
use constant FILE_MODIFIED => 'FILE_MODIFIED';

# VARIABLES

my $VERSION = "2023-01-05";

my $program = &basename($0);
my $encoding = ''; # was :crlf:encoding(UTF-8)
my $install_sql_preamble_printed = 0;
    
# command line options
my $dynamic_sql = 0; # displayed in print_run_info()
my $force_view = 1; # displayed in print_run_info()
my $group_constraints = 1;
my $input_file = undef;
my $output_directory = '.';
my $single_output_file = undef;
my $skip_install_sql = 1; # displayed in print_run_info()
my $source_schema = ''; # displayed in print_run_info()
my $strip_source_schema = 0; # displayed in print_run_info()
my $verbose = ( exists($ENV{VERBOSE}) && $ENV{VERBOSE} =~ m/^\d+$/o ? $ENV{VERBOSE} : 0 );

my $interface = undef;

# use ?: to skip creating the back references by ()
my $id_expr = '(?:[a-zA-Z0-9_#$]+|"[^"]+")';
# use double slash because it is a double quoted string
my $object_expr = "($id_expr\\s*\\.\\s*)?($id_expr)";

# primary objects
my $cluster_expr = qr/(?:CREATE?|ALTER)\s+CLUSTER\s+(?<object>$object_expr)/i;
my $synonym_expr = qr/(?:CREATE(\s+OR\s+REPLACE)?|(\s+(NON)?EDITIONABLE)?|ALTER)\s+SYNONYM\s+(?<object>$object_expr)/i;
my $type_spec_expr = qr/(?:CREATE(\s+OR\s+REPLACE)?(\s+(NON)?EDITIONABLE)?|ALTER)\s+TYPE\s+(?<object>$object_expr)/i;
my $type_body_expr = qr/(?:CREATE(\s+OR\s+REPLACE)?(\s+(NON)?EDITIONABLE)?|ALTER)\s+TYPE\s+BODY\s+(?<object>$object_expr)/i;
my $sequence_expr = qr/(?:CREATE|ALTER)\s+SEQUENCE\s+(?<object>$object_expr)/i;
my $table_expr = qr/(?:CREATE(\s+GLOBAL\s+TEMPORARY)?|ALTER)\s+TABLE\s+(?<object>$object_expr)/i;
my $package_spec_expr = qr/(?:CREATE(\s+OR\s+REPLACE)?(\s+(NON)?EDITIONABLE)?|ALTER)\s+PACKAGE\s+(?<object>$object_expr)/i;
# alter package compile body ...
my $package_body_expr = qr/CREATE(\s+OR\s+REPLACE)?(\s+(NON)?EDITIONABLE)?\s+PACKAGE\s+BODY\s+(?<object>$object_expr)|ALTER\s+PACKAGE\s+(?<object>$object_expr)/i;
my $function_expr = qr/(?:CREATE(\s+OR\s+REPLACE)?(\s+(NON)?EDITIONABLE)?|ALTER)\s+FUNCTION\s+(?<object>$object_expr)/i;
my $procedure_expr = qr/(?:CREATE(\s+OR\s+REPLACE)?(\s+(NON)?EDITIONABLE)?|ALTER)\s+PROCEDURE\s+(?<object>$object_expr)/i;
my $view_expr = qr/CREATE(\s+OR\s+REPLACE)?\s+(FORCE\s+)?((EDITIONABLE|EDITIONING)\s+)?VIEW\s+(?<object>$object_expr)|ALTER\s+VIEW\s+(?<object>$object_expr)/i;
my $materialized_view_expr = qr/CREATE\s+MATERIALIZED\s+VIEW\s+(?<object>$object_expr)/i;
my $materialized_view_log_expr = qr/CREATE\s+MATERIALIZED\s+VIEW\s+LOG\+ON\+(?<object>$object_expr)/i;
my $index_expr = qr/CREATE\s+(UNIQUE\s+)?INDEX\s+(?<object>$object_expr)\s|ALTER\s+INDEX\s+(?<object>$object_expr)/i;
my $trigger_expr = qr/(?:CREATE(\s+OR\s+REPLACE)?(\s+(NON)?EDITIONABLE)?|ALTER)\s+TRIGGER\s+(?<object>$object_expr)/i;

# these two are special since matching must be done one two lines, not just one
my @refresh_group_expr = ( qr/^\s*BEGIN\s*$/i, qr/^\s*DBMS_REFRESH\.MAKE\s*\(\s*'(?<object>$object_expr)'/i );
my @procobj_expr = ( qr/^\s*BEGIN\s*$/i, qr/^\s*DBMS_SCHEDULER\.CREATE_(\w+)\s*\(\s*'(?<object>$object_expr)'/i );
                      
# secondary objects: named after their base objects
my $constraint_expr     = qr/ALTER\s+TABLE\s+(?<object>$object_expr)\s+ADD\s+(CONSTRAINT\s+$id_expr\s+)?(?:PRIMARY\s+KEY|UNIQUE|CHECK)\s+/i;
my $ref_constraint_expr = qr/ALTER\s+TABLE\s+(?<object>$object_expr)\s+ADD\s+(CONSTRAINT\s+$id_expr\s+)?FOREIGN\s+KEY\s+/i;
my $comment_expr = qr/COMMENT\s+ON\s+(COLUMN|TABLE|MATERIALIZED\s+VIEW)\s+(?<object>$object_expr)(\.$id_expr)?/i;
# my $object_grant_expr = qr/(GRANT\s+.+\s+ON\s+(?<object>$object_expr)\s+TO\s+$object_expr|REVOKE\s+.+\s+ON\s+(?<object>$object_expr)\s+FROM\s+$object_expr)/i;
my $object_grant_expr = qr/GRANT\s+.+\s+ON\s+(?<object>$object_expr)\s+TO\s+$object_expr/i;

# GJP 2022-07-17 The generated DDL install.sql should use show errors after every stored procedure.
#
# SQL*Plus documentation:
# SHOW ERR[ORS] [{FUNCTION | PROCEDURE | PACKAGE | PACKAGE BODY | TRIGGER | VIEW | TYPE | TYPE BODY | DIMENSION | JAVA CLASS} [schema.]name]

my %object_type_info = (
    # all object types are from pkg_ddl_util.object_type_order:
    'SEQUENCE' => { expr => [ $sequence_expr ], seq => 1, repeatable => 0, plsql => 0 },
    # create or replace type may fail when it already exists due to dependent objects (e.g. collection of other types)
    'TYPE_SPEC' => { expr => [ $type_spec_expr ], seq => 2, repeatable => 0, plsql => 1, terminator => ';/', show_errors => 'TYPE' }, 
    'CLUSTER' => { expr => [ $cluster_expr ], seq => 3, repeatable => 0, plsql => 0 },
    # 'AQ_QUEUE_TABLE' => { seq => 4, repeatable => 0 },
    # 'AQ_QUEUE' => { seq => 5, repeatable => 0 },
    'TABLE' => { expr => [ $table_expr ], seq => 6, repeatable => 0, plsql => 0 },
    # 'DB_LINK' => { seq => 7, repeatable => 0, plsql => 0 },
    'FUNCTION' => { expr => [ $function_expr ], seq => 8, repeatable => 1, plsql => 1, show_errors => 'FUNCTION' },
    'PACKAGE_SPEC' => { expr => [ $package_spec_expr ], seq => 9, repeatable => 1, plsql => 1, show_errors => 'PACKAGE' },
    'VIEW' => { expr => [ $view_expr ], seq => 10, repeatable => 1, plsql => 0, show_errors => 'VIEW' },
    'PROCEDURE' => { expr => [ $procedure_expr ], seq => 11, repeatable => 1, plsql => 1, show_errors => 'PROCEDURE' },
    'MATERIALIZED_VIEW' => { expr => [ $materialized_view_expr ], seq => 12, repeatable => 0, plsql => 0 },
    'MATERIALIZED_VIEW_LOG' => { expr => [ $materialized_view_log_expr ], seq => 13, repeatable => 0, plsql => 0 },
    'PACKAGE_BODY' => { expr => [ $package_body_expr ], seq => 14, repeatable => 1, plsql => 1, show_errors => 'PACKAGE BODY' },
    'TYPE_BODY' => { expr => [ $type_body_expr ], seq => 15, repeatable => 1, plsql => 1, show_errors => 'TYPE BODY' },
    'INDEX' => { expr => [ $index_expr ], seq => 16, repeatable => 0, plsql => 0, use_base_object_name => 1 },
    'TRIGGER' => { expr => [ $trigger_expr ], seq => 17, repeatable => 1, plsql => 1, use_base_object_name => 0, show_errors => 'TRIGGER' }, # do not put them in one file because of instead trigger moves
    'OBJECT_GRANT' => { expr => [ $object_grant_expr ], seq => 18, repeatable => 1, plsql => 0, use_base_object_name => 1 },
    'CONSTRAINT' => { expr => [ $constraint_expr ], seq => 19, repeatable => 0, plsql => 0, use_base_object_name => 1 },
    'REF_CONSTRAINT' => { expr => [ $ref_constraint_expr ], seq => 20, repeatable => 0, plsql => 0, use_base_object_name => 1 },
    'SYNONYM' => { expr => [ $synonym_expr ], seq => 21, repeatable => 1, plsql => 0 },
    # Must be created after the TABLE/VIEW
    'COMMENT' => { expr => [ $comment_expr ], seq => 22, repeatable => 1, plsql => 0, use_base_object_name => 1 },
    # 'DIMENSION' => { seq => 23, repeatable => 0, plsql => 0, show_errors => 'DIMENSION' },
    # 'INDEXTYPE' => { seq => 24, repeatable => 1, plsql => 0 },
    'JAVA_SOURCE' => { seq => 25, repeatable => 1, plsql => 0, terminator => '/', show_errors => 'JAVA CLASS' },
    # 'LIBRARY' => { seq => 26, repeatable => 1, plsql => 0 },
    # 'OPERATOR' => { seq => 27, repeatable => 1, plsql => 0 },
    'REFRESH_GROUP' => { expr => \@refresh_group_expr, seq => 28, repeatable => 0, plsql => 1 },
    # 'XMLSCHEMA' => { seq => 29, repeatable => 0 },
    'PROCOBJ' => { expr => \@procobj_expr, seq => 30, repeatable => 0, plsql => 1 },
    );

my %object_info = (); # a hash table with key (object: schema, type, name) and data (file basename, sequence)
my %file_info = (); # a hash table with key file basename and data object ($object_info{$file_info{$file}}{file} eq $file)
my $object_seq_max = undef;

# Key: file handle; Value: base file name.
my %fh_modified = ();

my $TMPDIR = tempdir( CLEANUP => 1 );

my $object_sep = '.';
my $object_sep_rex = qr/\./;

# The lines to write to install.sql (if any).
my @install_sql_lines = ();
# The ref constraint lines to write to install.sql at the end (if any) if
# $group_constraints is true for interface >= v5.  Necessary to solve
# dependency order problems when all constraints are grouped in two files:
# one for referential constraints and one for the rest (per base object).
my @install_sql_ref_constraint_lines = ();

# PROTOTYPES

sub main ();
sub process_command_line ();
sub process ();
sub process_object_type ($$$$);
sub get_object_type_line ($$);
sub parse_object ($);
sub get_object ($$$;$$$);
sub object_file_name ($$$);                  
sub open_file ($$$$$$);
sub close_file ($$);
sub smart_open ($;$);
sub smart_close ($);
sub add_sql_statement ($$$$;$);
sub sort_sql_statements ($$$);
sub sort_dependent_objects ($$$);
sub all_sql_statements_flush ($$$$);
sub object_sql_statements_flush ($$$$$;$);
sub sql_statement_flush ($$$$$$);
sub print_run_info ($$);
sub remove_cr_lf ($);
sub remove_leading_empty_lines ($);
sub remove_trailing_empty_lines ($);
sub beautify_line ($$$$$$);
sub split_single_output_file($);
sub get_object_seq ($);
sub get_object_file ($);
sub add_object_info ($;$$);
sub set_file_status ($$;$);
sub get_files (@);
sub read_object_info ();
sub error (@);
sub warning (@);
sub info (@);
sub debug (@);
sub trace (@);
                                                
# MAIN

main();

# SUBROUTINES

sub main () {
    trace((caller(0))[3]);
    
    eval "use Data::Dumper; 1" or warn("Could not load Data::Dumper");

    info("\@ARGV: @ARGV");
    process_command_line();
    print_run_info(\*STDERR, 0);

    process();
}

sub process_command_line () {
    trace((caller(0))[3]);

    my @argv = @ARGV;

    # Windows FTYPE and ASSOC cause the command 'generate_ddl -h -c file'
    # to have ARGV[0] == ' -h -c file' and number of arguments 1.
    # Hence strip the spaces from $ARGV[0] and recreate @ARGV.
    if ( @ARGV == 1 && $ARGV[0] =~ s/^\s+//o ) {
        @ARGV = split( / /, $ARGV[0] );
    }

    Getopt::Long::Configure(qw(require_order));

    #
    GetOptions('dynamic-sql!' => \$dynamic_sql,
               'force-view!' => \$force_view,
               'group-constraints!' => \$group_constraints,
               'help' => sub { pod2usage(-verbose => 2) },
               'input-file=s' => \$input_file,
               'output-directory=s' => \$output_directory,
               'single-output-file:s' => \$single_output_file, # optional
               'skip-install-sql!' => \$skip_install_sql,
               'source-schema:s' => \$source_schema, # option may be empty
               'strip-source-schema!' => \$strip_source_schema,
               'test' => sub { print "Unit test not implemented yet\n"; exit(1); },
               'verbose+' => \$verbose,
               'version' => sub { print basename($0), " version $VERSION\n"; exit(0); }
        )
        or pod2usage(-verbose => 0);

    #

    if (defined($input_file)) {
        pod2usage(-message => "$0: input file must exist. Run with --help option.\n")
            unless (-r $input_file);
    }

    if (!defined($single_output_file)) {
        pod2usage(-message => "$0: output directory does not exist. Run with --help option.\n")
            unless (defined($output_directory) && -d $output_directory);
    }

    if ($verbose <= 1) {
        eval "use warnings FATAL => qw[uninitialized]";
        die $@ if $@;
    }

    print STDERR "Command line: $0 @argv\n"
        if ($verbose > 0);
}

sub process () {
    trace((caller(0))[3]);

    my $install_sql = ($skip_install_sql ? undef : File::Spec->catfile($output_directory, 'install.sql'));
    my $in;

    if (defined($input_file)) {
        open $in, "< $input_file"
            or error("Can not open '$input_file': $!");
    } else {
        $in = \*STDIN;
    }

    # These files are not needed anymore since the directory contents are used to determine the object sequence for interface V5
    unlink(File::Spec->catfile($output_directory, OLD_INSTALL_SEQUENCE_TXT),
           File::Spec->catfile($output_directory, NEW_INSTALL_SEQUENCE_TXT));

    # always make the output directory
    make_path($output_directory, { verbose => $verbose > 0 });

    # turn autoflush on for both STDOUT and STDERR
    select(STDERR);
    $| = 1;
    select(STDOUT); # back to the default
    $| = 1;

    my ($file, $fh) = (undef, undef);

    # in case of a set of output files, an install.sql is created in the output directory
    my $fh_install_sql = undef;

    if (defined($single_output_file)) {
        $file = File::Spec->catfile($output_directory, $single_output_file);
        $fh = smart_open($file);
    } else {
        $fh_install_sql = smart_open($install_sql)
            if (defined($install_sql));
    }

    print_run_info($fh, 0)
        if (defined($fh));

    # common variables
    my $nr_sql_statements = 0;
    my %sql_statements = (); # for each object (or file) it contains the DDL statements (an array) where a statement is also an array
    my %ddl_no;

    # interface pkg_ddl_util v4 till v5
    my $object = undef;
    my ($object_schema, $object_type, $object_name, $ddl_no, $line_no);

    # interface pkg_ddl_util v4 till v5
    my ($base_object_schema, $base_object_type, $base_object_name, $ddl_info);

    eval {
        # GPA 2016-11-17 There may be some debugging output before the interface line, so be aware
        #
        # read interface (first line with '-- ')
        #
        my $interface_expr = '^-- (' . PKG_DDL_UTIL_V4 . '|' . PKG_DDL_UTIL_V5 . ')$';

      INTERFACE:
        while (defined(my $line = <$in>)) {
            print $fh $line
                if (defined($fh));

            remove_cr_lf(\$line);
            
            debug("$.: $line");

            if ($line =~ m/$interface_expr/o) {
                if (!defined($interface)) {
                    $interface = $1;
                    read_object_info();
                } elsif ($interface ne $1) {
                    error("Interface changes from $interface to $1")
                }
                last INTERFACE;
            }
        }

        $interface = '' unless defined($interface);

        error("Unknown interface: $interface")
            unless ( $interface eq PKG_DDL_UTIL_V4 ||
                     $interface eq PKG_DDL_UTIL_V5 );

        # reset the line number back to 0 since the interface line may not be the first
        $. = 0; # $. = $. - 1;

        while (defined(my $line = <$in>)) {
            print $fh $line
                if (defined($fh) && !defined($single_output_file));

            remove_cr_lf(\$line);

            debug("line $.: $line");

            # $. starts from 1

            if ($interface eq PKG_DDL_UTIL_V4 || $interface eq PKG_DDL_UTIL_V5) {
                if ($line =~ m/^-- ddl info:\s*(?<ddl_info>\S.+)$/o) {
                    # Since all the grantees for one object will be saved in one file, we must determine the ddl# ourselves.
                    $ddl_info = $+{ddl_info};
                    
                    my @ddl_info = split(/;/, $ddl_info);

                    $object_schema = $ddl_info[1];
                    $object_type = $ddl_info[2];
                    $object_name = $ddl_info[3];
                    $base_object_schema =  $ddl_info[4];
                    $base_object_type = $ddl_info[5];
                    $base_object_name = $ddl_info[6];
                    
                    $object = get_object($object_schema, $object_type, $object_name, $base_object_schema, $base_object_type, $base_object_name);
                    
                    $ddl_no = $ddl_no{$object}++;
                    $line_no = 0;
                } else {
                    $line_no++;
                    if ($line_no == 1) {
                        error("\$object_name undefined")
                            unless (defined($object_name));
                    }

                    my $next_line;

                    ($line, $next_line) = beautify_line("\"$object_schema\".\"$object_name\"", $object_schema, $object_name, $object_type, $line_no == 1, $line);

                    add_sql_statement(\$line, \%sql_statements, $object, $ddl_no, $ddl_info);
                    add_sql_statement(\$next_line, \%sql_statements, $object, $ddl_no, $ddl_info)
                        if (defined($next_line));
                }
            }
        }
    };
    if ($@) {
        if ($@ !~ m/^EOF\b/) {
            warn $@;
            error("Could not generate DDL");
        }
    }

    eval {
        debug(Data::Dumper->Dump([%sql_statements], [qw(sql_statements)]));
    };

    all_sql_statements_flush($fh_install_sql, \$fh, \$nr_sql_statements, \%sql_statements);
    smart_close($fh)
        if defined($fh); # single output file
    
    smart_close($fh_install_sql)
        if defined($fh_install_sql);

    if (defined($input_file)) { # Suppress 'Filehandle STDIN reopened as $fh_seq only for output'
        close($in);
    }

    # do never remove the input file
    if (defined($single_output_file) && $single_output_file =~ m/\@nr\@/) {
        split_single_output_file($file);
    }

    # Remove obsolete SQL scripts matching the Flyway naming convention and not being modified.
    if (!defined($single_output_file)) {
        my @obsolete_files;

        # When those files have not been created/modified
        @obsolete_files = get_files(FILE_NOT_REUSED);

        # GJP 2021-08-27  Add install files too
        push(@obsolete_files, 'install.sql');
        
        foreach my $file (@obsolete_files) {
            my $output_file = File::Spec->rel2abs(File::Spec->catfile($output_directory, $file));

            error("File $output_file can not be removed")
                if (-f $output_file && unlink($output_file) != 1);
        }
    }
    info(sprintf("The number of files generated is %d (%d new or changed).", scalar(get_files(FILE_NOT_MODIFIED, FILE_MODIFIED)), scalar(get_files(FILE_MODIFIED))));
} # process

sub process_object_type ($$$$) {
    trace((caller(0))[3]);

    my ($object_type, $r_object_type_lines, $r_ddl_no, $r_sql_statements) = @_;

    debug("Process object type $object_type with $#$r_object_type_lines lines") if (defined($object_type));

    if (!(defined($object_type) && exists($object_type_info{$object_type}))) {
        @$r_object_type_lines = ();

        return;
    }

    my $last_line = undef;
    my $object = undef;
    my $r_expr = (exists($object_type_info{$object_type}) ? $object_type_info{$object_type}{'expr'} : undef);
    my $expr1 = (defined($r_expr) ? $r_expr->[0] : undef);
    my $expr2 = (defined($r_expr) && @$r_expr > 0 ? $r_expr->[1] : undef);

    my ($object_schema, $object_name, $ddl_no);

    my $line_no = 0;
        
    while (defined(my $line = get_object_type_line($object_type, $r_object_type_lines))) {
        $line_no++;

        debug(sprintf("[%05d]: '%s'", $line_no, $line));
        
        if (defined($expr1)) {
            if ((!defined($last_line) || $last_line =~ m!^\s*/\s*$! || $last_line =~ m!;\s*$!) &&
                # expr1 must match
                $line =~ qr/^\s*$expr1/i &&
                # expr2 must match too if it exists
                (!defined($expr2) || (@$r_object_type_lines > 0 && $r_object_type_lines->[0] =~ qr/^\s*$expr2/i))) {

                my $matched_object = $+{object};
                
                $object_name = $matched_object;
                        
                ($object_schema, $object_name) = parse_object($object_name);

                debug("Parsing object type $object_type and object $object_schema.$object_name");

                $object = get_object($object_schema, $object_type, $object_name);

                $ddl_no = $r_ddl_no->{$object}++;
                        
                my $next_line;
                    
                ($line, $next_line) = beautify_line($matched_object, $object_schema, $object_name, $object_type, 1, $line);

                $last_line = $line;
                $line =~ s/^\s+//; # strip leading space
                add_sql_statement(\$line, $r_sql_statements, $object, $ddl_no);
                
                if (defined($next_line)) {
                    $last_line = $next_line;
                    $next_line =~ s/^\s+//; # strip leading space
                    add_sql_statement(\$next_line, $r_sql_statements, $object, $ddl_no);
                }
            } elsif (!defined($object)) {
                warning("skipping '$line'")
                    if ($line =~ m/\S/);
            } elsif ($line =~ m/\S/) {
                # -- new object type path: SCHEMA_EXPORT/TABLE/INDEX/INDEX
                # BEGIN
                # NULL;
                # END;
                # /

                error("line did not match for $object_type: $line") 
                    unless defined($last_line);
                #
                $last_line = $line;
                add_sql_statement(\$line, $r_sql_statements, $object, $ddl_no);
            } else {
                # empty
                add_sql_statement(\$line, $r_sql_statements, $object, $ddl_no);
            }
        }
    }
}

sub get_object_type_line ($$) {
    trace((caller(0))[3]);
    
    my ($object_type, $r_object_type_lines) = @_;

    # Remove a block like this:
    #
    # BEGIN
    # NULL;
    # END;
    # /

    my $plsql = ( defined($object_type) && exists($object_type_info{$object_type}) && exists($object_type_info{$object_type}->{'plsql'}) ?
                  $object_type_info{$object_type}->{'plsql'} :
                  0 );
    
    while ($plsql eq 0 &&
           $#$r_object_type_lines >= 3 &&
           $r_object_type_lines->[0] eq 'BEGIN' &&
           $r_object_type_lines->[1] eq 'NULL;' &&
           $r_object_type_lines->[2] eq 'END;' &&
           $r_object_type_lines->[3] eq '/')
    {
        for my $i (0..3) { 
            shift(@$r_object_type_lines); 
        }
    }
    
    return shift(@$r_object_type_lines);
}
    
sub parse_object($) {
    trace((caller(0))[3]);
    
    my ($owner, $name) = ($source_schema, @_);

    if ($name =~ qr/(?<owner>$id_expr)\s*\.\s*(?<name>$id_expr)/) {
        ($owner, $name) = ($+{owner}, $+{name});
    } elsif ($name =~ qr/(?<name>$id_expr)/) {
        ($name) = ($+{name});
    } else {
        error("name '$name' can not be parsed");
    }

    $owner = ($owner =~ m/^"([^"]+)"$/ ? $1 : uc($owner));
    $name = ($name =~ m/^"([^"]+)"$/ ? $1 : uc($name));
    
    return ($owner, $name);
}

sub get_object ($$$;$$$) {
    trace((caller(0))[3]);
    
    my ($object_schema, $object_type, $object_name, $base_object_schema, $base_object_type, $base_object_name) = @_;

    my $sep = $object_sep;

    # GPA 2017-02-28 #140681641 Unique constraints must be created before a referencing key is created.
    # All DDL stored must be saved for one and only one object name, otherwise the order of DDL statements determined by the database may change.
    if (defined($single_output_file)) {
        return sprintf("%s$sep$sep", $source_schema);
    } 
    # All comments, indexes and constraints in one file named after the base object
    elsif ( defined($base_object_schema) &&
            $object_schema eq $base_object_schema &&
            exists($object_type_info{$object_type}->{use_base_object_name}) &&
            $object_type_info{$object_type}->{use_base_object_name} ) {
        my $name = $base_object_name;
        
        # For constraints the name part is either <base_name>-<constraint_name> (<constraint_name> not empty) or <base_name> (else)
        if (!$group_constraints &&
            defined($interface) &&
            $interface ne PKG_DDL_UTIL_V4 &&
            $object_type =~ m/^(REF_)?CONSTRAINT$/ &&
            defined($object_name) &&
            length($object_name) > 0) {
            $name .= '-' . $object_name;
        }
        
        return sprintf("%s$sep%s$sep%s", 
                       $object_schema,
                       $object_type,
                       $name);
    } else {
        error("Both \$object_schema and \$base_object_schema undefined")
            unless (defined($object_schema) or defined($base_object_schema));
        error("Both \$object_type and \$base_object_type undefined")
            unless (defined($object_type) or defined($base_object_type));
        error("Both \$object_name and \$base_object_name undefined")
            unless (defined($object_name) or defined($base_object_name));
        return sprintf("%s$sep%s$sep%s", 
                       ( defined($object_schema) && length($object_schema) > 0 ? $object_schema : $base_object_schema ),
                       ( defined($object_type) && length($object_type) > 0 ? $object_type : $base_object_type ),
                       ( defined($object_name) && length($object_name) > 0 ? $object_name : $base_object_name ));
    }
}

sub object_file_name ($$$) {
    trace((caller(0))[3]);
    
    my ($object_schema, $object_type, $object_name) = @_;

    if (length($source_schema) > 0 && $object_schema !~ m/^(PUBLIC|$source_schema)$/) {
        warn "INFO: \$object_schema: $object_schema; \$object_type: $object_type; \$object_name: $object_name";
        warn "WARNING: Schema $object_schema not equal to PUBLIC or $source_schema";
    }

    # We must forbid objects like TRIGGER bi_CLEVE and BI_CLEVE to coexist together.
    # A solution to check this is to create the file in uppercase.
    # Now when the file already exists, we should raise an exception.
    error("\$object_type undefined") unless defined($object_type);
    error("\$object_type_info{$object_type} does not exist") unless exists($object_type_info{$object_type});
    error("\$object_type_info{$object_type}->{'repeatable'} does not exist") unless exists($object_type_info{$object_type}->{'repeatable'});
    error("\$object_type_info{$object_type}->{'seq'} does not exist") unless exists($object_type_info{$object_type}->{'seq'});
    error("\$object_schema undefined") unless defined($object_schema);
    error("\$object_name undefined") unless defined($object_name);

    my $object_info_key = join($object_sep, $object_schema, $object_type, $object_name);
    my $object_file_name = get_object_file($object_info_key);

    if (!defined($object_file_name)) {
        $object_file_name = add_object_info($object_info_key);
    }

    debug("object: $object_info_key; file: $object_file_name");
    
    return $object_file_name;
} # sub object_file_name

sub open_file ($$$$$$) {
    debug((caller(0))[3], @_);
    
    my ($file, $fh_install_sql, $r_fh, $ignore_warning_when_file_exists, $object_type, $object_name) = @_;
    
    if (defined $fh_install_sql) {
        my $r_lines = \@install_sql_lines;

        if ($object_type eq 'REF_CONSTRAINT' &&
            $group_constraints &&
            defined($interface) &&
            $interface ne PKG_DDL_UTIL_V4) {
            $r_lines = \@install_sql_ref_constraint_lines;
        }

        push(@$r_lines, "prompt \@\@$file\n\@\@$file\n");
        push(@$r_lines, sprintf("show errors %s \"%s\"\n", $object_type_info{$object_type}->{'show_errors'}, $object_name))
            if (defined($object_type) &&
                exists($object_type_info{$object_type}) &&
                exists($object_type_info{$object_type}->{'show_errors'}));

    }

    # GJP 2021-08-27 Create the file in $output_directory later on in close_file() so modification date will not change if file is the same

    my $tmpfile = File::Spec->catfile($TMPDIR, $file);

    $file = File::Spec->catfile($output_directory, $file);

    debug("$tmpfile exists? ", (-f $tmpfile));
    
    # Just issue a warning till now and append
    if (-f $tmpfile) {
        warn "WARNING: File $file already exists. Duplicate objects?"
            unless ($ignore_warning_when_file_exists);

        debug("$tmpfile exists");

        $$r_fh = smart_open($tmpfile, 1); # append
    } else {
        debug("$tmpfile does not exist");
        
        $$r_fh = smart_open($tmpfile);
    }
}

sub close_file ($$) {
    trace((caller(0))[3]);
    
    my ($file, $r_fh) = @_;

    # close before comparing/copying/removing
    smart_close($$r_fh);
    $$r_fh = undef;
}

# GJP 2021-08-27
# Create the file in $output_directory later on in close_file() so modification date will not change if file is the same.
# To do this use smart_open() and smart_close() instead of open()/close().

# open file for writing
sub smart_open ($;$) {
    debug((caller(0))[3], @_);

    my ($file, $append) = @_;
    my $basename = basename($file);
    my ($tmpfile, $fh) = (File::Spec->catfile($TMPDIR, $basename));

    # open
    open($fh, (defined($append) && $append ? ">>" : ">") . $encoding, $tmpfile)
        or error("Can not write to '$tmpfile': $!");

    $fh_modified{$fh} = $basename;

    return $fh;
}

sub smart_close ($) {
    trace((caller(0))[3]);

    my $fh = shift @_;

    error("File handle unknown")
        unless exists($fh_modified{$fh});
    
    my $basename = $fh_modified{$fh};

    close($fh)
        or error("Can not close file: $!");

    delete $fh_modified{$fh};

    # Now copy (smart) from temp to output directory
    my ($tmpfile, $file) = (File::Spec->catfile($TMPDIR, $basename), File::Spec->catfile($output_directory, $basename));

    if (-f $file && compare($tmpfile, $file) == 0) {
        set_file_status($file, FILE_NOT_MODIFIED);
    } else {
        # $file not existing yet or not equal to $tmpfile
        copy($tmpfile, $file) or error("Copy from '$tmpfile' to '$file' failed: $!");
        set_file_status($file, FILE_MODIFIED);
    }
    # GJP 2023-05-03
    # Never clean up temporary files here (since we may have instead of triggers!).
    # Files will be removed when Perl finishes (due to 'my $TMPDIR = tempdir( CLEANUP => 1 );')
}

sub add_sql_statement ($$$$;$) {
    trace((caller(0))[3]);

    my ($r_sql_line, $r_sql_statements, $object, $ddl_no, $ddl_info) = @_;

    error("SQL line undefined")
        if (!defined($r_sql_line) || !defined($$r_sql_line));

    debug("Adding '$$r_sql_line' for object $object and statement $ddl_no");

    $r_sql_statements->{$object}->{seq} = scalar(keys %$r_sql_statements)
        unless exists($r_sql_statements->{$object}->{seq});

    if (!get_object_seq($object)) {
        # ignore any error
        eval {
            add_object_info($object);
        };
    };

    $r_sql_statements->{$object}->{ddls}->[$ddl_no] = { 'ddl_info' => $ddl_info, 'ddl' => [] }
        unless exists($r_sql_statements->{$object}->{ddls}->[$ddl_no]);

    my $r_sql_statement = $r_sql_statements->{$object}->{ddls}->[$ddl_no]->{ddl};

    push(@$r_sql_statement, $$r_sql_line);

    error(sprintf("The number of statements for object '$object' is %d which is not the current ddl no (%d)", 
                  scalar(@{$r_sql_statements->{$object}->{ddls}}), 
                  $ddl_no + 1))
        unless $ddl_no + 1 == scalar(@{$r_sql_statements->{$object}->{ddls}});
    
    $$r_sql_line = '';
} # sub add_sql_statement

sub sort_sql_statements ($$$) {
    trace((caller(0))[3]);

    my ($r_sql_statements, $a, $b) = @_;
    my $result;

    if ($interface eq PKG_DDL_UTIL_V4) {
        # just sort by sequence
        $result = ($r_sql_statements->{$a}->{seq} <=> $r_sql_statements->{$b}->{seq});
    } else {
        my ($a_idx, $b_idx) = ($a, $b);
        my ($a_seq, $b_seq) = (get_object_seq($a_idx), get_object_seq($b_idx));

        if ($strip_source_schema) {
            if (!defined($a_seq)) {
                $a_idx =~ s/^$source_schema//;
                $a_seq = get_object_seq($a_idx);
            }
            if (!defined($b_seq)) {
                $b_idx =~ s/^$source_schema//;
                $b_seq = get_object_seq($b_idx);
            }
        }

        eval {
            my $dumper = Data::Dumper->new([\%object_info], [qw(*object_info)]);

            $dumper->Sortkeys(1);
            
            warning($dumper->Dump())
                unless ( defined($a_seq) && defined($b_seq) );
        };

        error("No object sequence for $a")
            unless defined($a_seq);
        error("No object sequence for $b")
            unless defined($b_seq);
        
        debug(sprintf("get_object_seq('%s'); '%s'; get_object_seq('%s'): '%s'", $a_idx, $a_seq, $b_idx, $b_seq));
        
        $result = $a_seq <=> $b_seq;
    }

    return $result;
}

sub sort_dependent_objects ($$$) {
    trace((caller(0))[3]);

    my ($object_type, $a, $b) = @_;

    if ($object_type eq 'OBJECT_GRANT') {
        # If $a is not a GRANT and $b a GRANT, $a (REVOKE) must come first
        # GPA 2016-11-21 #133915559 - Expand release procedure to make sure that grants without user wil be ignored
        # my $result = ($a->[0] =~ m/^\s*GRANT\b/) <=> ($b->[0] =~ m/^\s*GRANT\b/);
        my $result = ($a->{ddl}->[0] =~ m/^\bGRANT\b/) <=> ($b->{ddl}->[0] =~ m/^\bGRANT\b/);

        return $result
            if ($result != 0);
    }
    return $a->{ddl}->[0] cmp $b->{ddl}->[0];
}

sub all_sql_statements_flush ($$$$) {
    trace((caller(0))[3]);

    my ($fh_install_sql, $r_fh, $r_nr_sql_statements, $r_sql_statements) = @_;

    debug("Flushing all objects");

    # Does not have to be an error (there may be no differences, hey)
    carp "No sql statements parsed"
        if (scalar(keys %$r_sql_statements) == 0);

    # Sort by object type (sequence) and name and not by sequence in the schema export file, since Oracle might change order due to DDL changes.
    # And we want the install.sql file to be the same when no objects have been removed/added.
    
    foreach my $object (sort { sort_sql_statements($r_sql_statements, $a, $b); } (keys %$r_sql_statements)) {
        object_sql_statements_flush($fh_install_sql, $r_fh, $r_nr_sql_statements, $r_sql_statements->{$object}->{ddls}, $object);
    }

    # Now write tthe install.sql
    if (defined $fh_install_sql) {
        if (!$install_sql_preamble_printed) {
            my $preamble = << 'PREAMBLE';
REMARK Try to call Flyway script beforeEachMigrate.sql (add its directory to SQLPATH) so that PLSQL_CCFlags can be set.
REMARK But no harm done if it is not there.

whenever oserror continue
whenever sqlerror continue
@@beforeEachMigrate.sql

whenever oserror exit failure
whenever sqlerror exit failure
set define off sqlblanklines on
ALTER SESSION SET PLSQL_WARNINGS = 'ENABLE:ALL';

PREAMBLE

            print $fh_install_sql $preamble;

            $install_sql_preamble_printed = 1;
        }

        push(@install_sql_lines, @install_sql_ref_constraint_lines);
        
        foreach my $line (@install_sql_lines) {
            print $fh_install_sql $line;
        }
    }
}

sub object_sql_statements_flush ($$$$$;$) {
    trace((caller(0))[3]);

    my ($fh_install_sql, $r_fh, $r_nr_sql_statements, $r_sql_statements, $object, $ignore_warning_when_file_exists) = @_;

    $ignore_warning_when_file_exists = 0
        unless (defined($ignore_warning_when_file_exists));
    
    my $file = undef;
    
    debug("Flushing $object with ", scalar(@$r_sql_statements), " statement(s)");

    return if scalar(@$r_sql_statements) == 0;
    
    # GPA 2017-02-28 #140681641 Unique constraints must be created before a referencing key is created.
    # All DDL stored must be saved for one and only one object name, otherwise the order of DDL statements determined by the database may change.
    if ( defined($single_output_file) ) {
        error("File handle must be defined") unless defined($$r_fh);

        print $$r_fh sprintf("call dbms_application_info.set_module('%s', null);\n", basename($single_output_file));
    } else {
        my ($object_schema, $object_type, $object_name) = split($object_sep_rex, $object);

        if (not(exists($object_type_info{$object_type})) ||
            not(exists($object_type_info{$object_type}->{'repeatable'})) ||
            not(exists($object_type_info{$object_type}->{'seq'})))
        {
            warning("Skipping object type $object_type");
            return;
        }

        $file = object_file_name($object_schema, $object_type, $object_name);
    
        #
        # remove ALTER ... COMPILE statements
        #
        if ( defined($object_type) && 
             $object_type =~ m/^(FUNCTION|PROCEDURE|PACKAGE_SPEC|PACKAGE_BODY|TYPE_SPEC|TYPE_BODY|TRIGGER)$/) {
            # loop through the array in reverse order so deletes do not affect later elements
            for my $ddl_no (reverse(0 .. scalar(@$r_sql_statements)-1)) {
                my $r_sql_statement = $r_sql_statements->[$ddl_no]->{ddl};

                my $compile_expr = ($object_type eq 'TRIGGER' ? qr/COMPILE\s*$/ : qr/COMPILE\s+(?:SPECIFICATION|BODY)\s*$/);

                if (scalar(@$r_sql_statement) >= 2) {
                    if ($r_sql_statement->[1] =~ m/^\s*($compile_expr)\b/m) {
                        debug("Removing element $ddl_no since $1 was found");
                        splice(@$r_sql_statements, $ddl_no, 1);
                    }
                }
            }
        }

        #
        # sort dependent objects
        #
        if ( defined($object_type) && 
             exists($object_type_info{$object_type}->{use_base_object_name}) &&
             $object_type_info{$object_type}->{use_base_object_name} ) {
            @$r_sql_statements = sort { sort_dependent_objects($object_type, $a, $b) } @$r_sql_statements;

            debug("Sorted $object_type $object_name");
        }

        # Handling instead of triggers
        if (defined($object_type) && $object_type eq 'TRIGGER') {
            my $r_sql_statement = $r_sql_statements->[0]->{ddl};

            my $sql_statement = join(" ", @$r_sql_statement);

            debug("Trigger statement: $sql_statement");

            if ($sql_statement =~ m/\bINSTEAD\s+OF\s+((?:OR|INSERT|DELETE|UPDATE)\s+)+ON\s+(?<object>$object_expr)/i) {
                my $comment = "Moving DDL of instead of trigger $object_schema.$object_name to DDL for view $+{object}";

                info($comment);

                # override $object_schema, $object_type and $object_name so that the 
                my ($object_schema, $object_type, $object_name);
                
                ($object_schema, $object_name) = parse_object($+{object});
                # $object_name = uc($object_name);

                $object_type = 'VIEW';

                # put it in the VIEW file!
                # $file = object_file_name($object_schema, $object_type, $object_name);
                # and ignore the warning
                # $ignore_warning_when_file_exists = 1;

                object_sql_statements_flush($fh_install_sql, $r_fh, $r_nr_sql_statements, $r_sql_statements, join($object_sep, $object_schema, $object_type, $object_name), 1);

                # Create an instead of trigger file with just a comment
                my @lines = ("-- $comment");
                
                $r_sql_statements->[0]->{ddl} = \@lines;
            }
        }
        open_file($file, $fh_install_sql, $r_fh, $ignore_warning_when_file_exists, $object_type, $object_name);
        if ($object_type eq 'OBJECT_GRANT') {
            error("File handle must be defined") unless defined($$r_fh);
            
            print $$r_fh sprintf("call dbms_application_info.set_module('%s', null);\n", basename($file));
        }
    }

    # GPA 2017-03-14 Number the number of SQL statements per file, so we can invoke dbms_application_info.set_action()
    my $nr_sql_statements = 0;
    
    for my $ddl_no (0 .. scalar(@$r_sql_statements)-1) {
        my $r_sql_statement = $r_sql_statements->[$ddl_no];

        sql_statement_flush($$r_fh, \$nr_sql_statements, $r_sql_statement->{ddl}, $object, $ddl_no, $r_sql_statement->{ddl_info});
    }

    close_file($file, $r_fh)
        if ( defined($file) );

    # Update the grand total
    $$r_nr_sql_statements += $nr_sql_statements;
} # object_sql_statements_flush

sub sql_statement_flush ($$$$$$) {
    trace((caller(0))[3]);

    my ($fh, $r_nr_sql_statements, $r_sql_statement, $object, $ddl_no, $ddl_info) = @_;

    debug("Flushing statement for $object with ", scalar(@$r_sql_statement), " line(s)");

    error("File handle must be defined") unless defined($fh);
    
    return if ( scalar(@$r_sql_statement) == 0 );

    # 1) From the Flyway documentation:
    #
    # Sql Script Syntax
    #
    # Standard Sql syntax with statement delimiter ;
    # PL/SQL blocks starting with DECLARE or BEGIN and finishing with END; /
    # 
    # 2) We always create a PL/SQL block for Flyway.
    #    So we append always with a slash on the next line unless the SQL statement begins with a single line comment.
    #

    # If the sql terminator must not be added, i.e. it is already there 
    # we must strip it first because Flyway may expect a different one.
    for my $try ( ($interface eq PKG_DDL_UTIL_V4 or $interface eq PKG_DDL_UTIL_V5 ? 1 : 0) .. 1 ) {
        remove_trailing_empty_lines($r_sql_statement);

        if ($try == 0) {
            my $statement = pop(@$r_sql_statement);

            # skip single line comments
            if (defined($statement) && $statement !~ m/^\s*--/o) {
                my $terminator = substr($statement, length($statement)-1);

                error(sprintf("Wrong SQL or PL/SQL terminator '%s' (%d)\n", $terminator, ord($terminator)))
                    unless ($terminator eq ';' or $terminator eq '/');
                
                debug(sprintf("Removing the SQL or PL/SQL terminator '%s' (%d)\n", $terminator, ord($terminator)));
                
                $statement = substr($statement, 0, length($statement)-1); # remove the last character, i.e. the terminator
                $statement =~ s/\s+$//; # strip trailing white space
            }
            push(@$r_sql_statement, $statement) if length($statement) > 0;
        }
    }

    return if ( scalar(@$r_sql_statement) == 0 );

    my $last_line = $r_sql_statement->[$#$r_sql_statement];

    debug("Last line after removing trailing empty lines and/or an empty pl/sql block: '$last_line'");

    # When all the lines are empty or when they start with a comment, there is no real sql statement to parse
    my $is_sql_statement = 0;

  LINE: {
      foreach my $line (@$r_sql_statement) {
          if (!($line =~ m/^\s*--/o)) {
              debug("SQL statement is set to true: $line");
              
              $is_sql_statement = 1;
              last LINE;
          }
      }
    }

    debug("\$is_sql_statement: $is_sql_statement");

    my $sql_statement = join("\n", @$r_sql_statement);

    # increment scripts do not need thousands of action comments
    return if ($verbose <= 1 && $is_sql_statement == 0 && $sql_statement =~ m/^-- action: /);

    if ($dynamic_sql && $is_sql_statement) {
        # 1) Place all SQL lines in a PL/SQL block

        # string:
        # q'{ }'
        # q'! !'
        # q'[ ]'
        # q'( )'
        # q'< >'
        # ' '
        my @b = ("q'{", "q'!", "q'[", "q'(", "q'<", "'"); # begin of literal string
        my @e = ( "}'",  "!'",  "]'",  ")'",  ">'", "'"); #   end of literal string

        # To handle blocks > 32K: use dbms_sql.parse(c in integer, statement in varchar2a, lb in integer, ub in integer, lfflg in boolean, language_flag in integer);
            
        if (length($sql_statement) <= 32000) {
          LOOP: {
              for (my $i = 0; $i < scalar(@b); $i++) {
                  if (index($sql_statement, $b[$i]) == -1 && ($b[$i] eq $e[$i] || index($sql_statement, $e[$i]) == -1)) {
                      # Er is geen literal string in $sql_statement beginnend met $b[$i] en eindigend met $e[$i],
                      # dus we kunnen $b[$i] en $e[$i] gebruiken om een literal string te maken.
                      $sql_statement = sprintf("begin\n  execute immediate %s%s%s;\nend;", $b[$i], $sql_statement, $e[$i]);
                      last LOOP;
                  }
              }
            }
        } else {
            for (my $line = 0; $line < scalar(@$r_sql_statement); $line++) {
              LOOP: {
                  for (my $i = 0; $i < scalar(@b); $i++) {
                      if (index($r_sql_statement->[$line], $b[$i]) == -1 && ($b[$i] eq $e[$i] || index($r_sql_statement->[$line], $e[$i]) == -1)) {
                          # Er is geen literal string in $r_sql_statement->[$line] beginnend met $b[$i] en eindigend met $e[$i],
                          # dus we kunnen $b[$i] en $e[$i] gebruiken om een literal string te maken.
                          $r_sql_statement->[$line] = sprintf("  add(%s%s%s);", $b[$i], $r_sql_statement->[$line], $e[$i]);
                          last LOOP;
                      }
                  }
                }
            }

            #
            # 2) Start with the declaration of the cursor, array variable and an add() procedure
            unshift(@$r_sql_statement,
                    "/* Use dbms_sql.parse() to execute the SQL statement since it is easier to parse and because it supports a statement size > 32K. */", 
                    "declare",
                    "  c integer := dbms_sql.open_cursor;",
                    "  s dbms_sql.varchar2a;",
                    "  procedure add(l in varchar2)",
                    "  is",
                    "  begin",
                    "    s(s.count+1) := l || chr(10);", # De database migratietool genereert niet de goede code voor package body met lege lijnen
                    "  end add;",
                    "begin");

            # 3) Now parse and close the cursor and finish
            push(@$r_sql_statement,
                 # De database migratietool genereert niet de goede code voor package body met lege lijnen
                 "  dbms_sql.parse(c => c, statement => s, lb => s.first, ub => s.last, lfflg => false, language_flag => dbms_sql.native);",
                 "  dbms_sql.close_cursor(c);",
                 "end;");
            
            $sql_statement = join("\n", @$r_sql_statement);
        }
    }

    $$r_nr_sql_statements++;

    if (defined($single_output_file)) {
        print $fh "/* SQL statement $$r_nr_sql_statements (" . (defined($ddl_info) ? $ddl_info : $object) . ") */\n";
    }

    my (undef, $object_type, undef) = split($object_sep_rex, $object);
    my $terminator = ($is_sql_statement ? ';' : '');

    if (defined($single_output_file) || $object_type eq 'OBJECT_GRANT') {
        print $fh sprintf("call dbms_application_info.set_action('SQL statement %s');\n", $$r_nr_sql_statements);
    }
    
    # GPA 2016-11-14 #133852433 Object grants should be ignored when they return an error during an installation.
    # GPA 2016-11-29 #133915559 Expand release procedure to make sure that grants without user wil be ignored (add pl/sql block)
    if ($is_sql_statement) {
        if ($dynamic_sql) {
            $terminator = '/';
            # GPA 2017-03-14 #141588789 As a CD developer I need to be able to import tables/grants into an Oracle XE database
            # if ($object_type eq 'OBJECT_GRANT') {
            #     $sql_statement = "-- ORA-01927: grant errors\nBEGIN EXECUTE IMMEDIATE '" . $sql_statement . "'; EXCEPTION WHEN OTHERS THEN IF SQLCODE NOT IN (-1927) THEN RAISE; END IF; END;";
            # }
        # GPA 2017-03-14 #141588789 As a CD developer I need to be able to import tables/grants into an Oracle XE database
        # } elsif ($object_type eq 'OBJECT_GRANT') {
        #     $terminator = '/';
        #     $sql_statement = "-- ORA-01917/ORA-02204/ORA-02214: grant errors\nBEGIN EXECUTE IMMEDIATE '" . $sql_statement . "'; EXCEPTION WHEN OTHERS THEN IF SQLCODE NOT IN (-1917, -2204, -2214) THEN RAISE; END IF; END;";
        # } elsif ($object_type eq 'TYPE_SPEC') {
        #     $terminator = '/';
        #
        #     # GPA 2016-11-30
        #     # Flyway on Oracle 10 had problems with several types in a row. 
        #     # So embed it in a dynamic statement.
        #     # And use q'[]' since the type may containt methods with string parameters with a default
        #     $sql_statement = "/* To help Flyway */\nBEGIN\n  EXECUTE IMMEDIATE q'[\n" . $sql_statement . "\n]';\nEND;";
        } else {
            # Only the first statement is relevant. Statement 2 and further are never "create or replace" statements

            debug("\$ddl_no:", $ddl_no, "; \$object_type:", $object_type);
            debug("object type terminator:", (exists($object_type_info{$object_type}->{'terminator'}) ? $object_type_info{$object_type}->{'terminator'} : 'UNKNOWN'));
            debug("object type plsql:", (exists($object_type_info{$object_type}->{'plsql'}) ? $object_type_info{$object_type}->{'plsql'} : 'UNKNOWN'));

            # GPA 2016-11-14 #133852433 Object grants should be ignored when they return an error during an installation.
            if ( $ddl_no == 0 && exists($object_type_info{$object_type}->{'terminator'}) ) {
                $terminator = $object_type_info{$object_type}->{'terminator'};
            } elsif ( $ddl_no == 0 && exists($object_type_info{$object_type}->{'plsql'}) && $object_type_info{$object_type}->{'plsql'} ) {
                $terminator = '/';
            } elsif ( $r_sql_statement->[scalar(@$r_sql_statement)-1] =~ m/;\s*$/i ) {
                # Is it a PL/SQL statement, i.e. last line ends with a semi-colon (and maybe some whitespace)
                $terminator = '/';
            }
        }
    }

    debug("\$terminator: $terminator");

    error(sprintf("Wrong SQL or PL/SQL terminator '%s' (%d)\n", $terminator, ord($terminator)))
        unless (($is_sql_statement == 1 and ($terminator eq ';' or $terminator eq '/' or $terminator eq ';/')) or 
                ($is_sql_statement == 0 and $terminator eq ''));
            
    if ($terminator eq ';/') {
        # For type specifications
        # GJP 2021-07-29 No ;;\n/
        my $last_ch = substr($sql_statement, length($sql_statement)-1);
        
        $sql_statement .= ($last_ch eq ';' ? "\n/" : ";\n/");
    } elsif ($terminator eq '/') {
        # close PL/SQL block
        # GJP 2022-01-18 Unless the last line already ends with a /
        $sql_statement .= "\n/"
            unless $r_sql_statement->[scalar(@$r_sql_statement)-1] =~ m!^/\s*$!;
    } elsif ($terminator eq ';') {
        # close SQL statement with a ;
        $last_line = $r_sql_statement->[$#$r_sql_statement];

        # Does the last line end with a single line comment?
        # If so, we must add the semi-colon on a new line otherwise it will be ignored.
        if ($last_line =~ m/\s*--.*$/o) { 
            $sql_statement .= "\n;";
        } else {
            $sql_statement .= ";";
        }
    }

    $sql_statement .= "\n\n";
    
    print $fh $sql_statement;
}

sub print_run_info ($$) {
    trace((caller(0))[3]);

    my ($fh, $install) = @_;

    error("File handle must be defined") unless defined($fh);
    
    print $fh '/* ', "perl generate_ddl.pl (version $VERSION)";
    print $fh sprintf(" --%s%s", ($dynamic_sql ? '' : 'no'), 'dynamic-sql');
    print $fh sprintf(" --%s%s", ($force_view ? '' : 'no'), 'force-view');
    print $fh sprintf(" --%s%s", ($group_constraints ? '' : 'no'), 'group-constraints');
    print $fh sprintf(" --%s%s", ($skip_install_sql ? '' : 'no'), 'skip-install-sql');
    print $fh " --source-schema=$source_schema" if (length($source_schema) > 0);
    print $fh sprintf(" --%s%s", ($strip_source_schema ? '' : 'no'), 'strip-source-schema');
    print $fh ' */', "\n\n";
    print $fh "whenever sqlerror exit failure\nwhenever oserror exit failure\n\nset define off\n\n"
        if ($install);
}

sub remove_cr_lf ($) {
    trace((caller(0))[3]);

    my $r_line = $_[0];
    
    $$r_line =~ s/\r?\n//mg;
}

sub remove_leading_empty_lines ($) {
    trace((caller(0))[3]);

    my $r_lines = $_[0];
    
  REMOVE_LEADING_EMPTY_LINES: {
      if (@$r_lines > 0) {
          my $line = shift(@$r_lines);
          
          if (defined($line) && $line =~ m/\S/) {
              unshift(@$r_lines, $line);
          } else {
              redo REMOVE_LEADING_EMPTY_LINES;
          }
      }
    }
}

sub remove_trailing_empty_lines ($) {
    trace((caller(0))[3]);

    my $r_lines = $_[0];
    
  REMOVE_TRAILING_EMPTY_LINES: {
      if (@$r_lines > 0) {
          my $line = pop(@$r_lines);
          
          if (defined($line) && $line =~ m/\S/) {
              push(@$r_lines, $line);
          } else {
              redo REMOVE_TRAILING_EMPTY_LINES;
          }
      }
    }
}

sub beautify_line ($$$$$$) {
    trace((caller(0))[3]);

    my ($matched_object, $object_schema, $object_name, $object_type, $first_line, $line) = @_;

    return ($line)
        unless defined($line) && $line ne '';

    debug("before beautify line; \$line[0]: $line");
    
    if ($first_line) {
        if ($object_type eq 'VIEW') {
            $line =~ s/\s+DEFAULT COLLATION "USING_NLS_COMP"//g;
            $line =~ s/\s+FORCE\s+/ /i
                if (!$force_view); 
            $line =~ s/\s+(as\s*)$/' ' . $1/ie;
        } elsif ($object_type_info{$object_type}->{'repeatable'}) {
            # create => create or replace
            $line =~ s/^\s*CREATE\s+/CREATE OR REPLACE /i
                unless $line =~ m/^\s*CREATE\s+OR\s+REPLACE\b/i;
        } elsif ($object_type eq 'TYPE_SPEC') {
            # create or replace => create (TYPE)
            $line =~ s/^\s*CREATE\s+OR\s+REPLACE\s+/CREATE /i;
        }
            
        # Do not change NONEDITIONABLE since some views may need it (APEX views for instance)
        $line =~ s/\bEDITIONABLE\s+//i; # Flyway does not like CREATE OR REPLACE EDITIONABLE PACKAGE 

        my $object_fq_name = ($strip_source_schema && $object_schema eq $source_schema ? '' : "\"$object_schema\".");

        $object_fq_name .= "\"$object_name\"";

        # beautify the name
        $line =~ s/(.*\S)\s+$matched_object(\s+(?:AS|IS)\b)?(\s+OBJECT\b)?/uc($1).' '.$object_fq_name.(defined($2)?uc($2):'').(defined($3)?uc($3):'')/ie;
    }

    if ($object_type eq 'TABLE') {
        # "ADDRESS_TYPE" VARCHAR2(30) COLLATE "USING_NLS_COMP",
        # =>
        # "ADDRESS_TYPE" VARCHAR2(30),
        
        $line =~ s/\s+COLLATE "USING_NLS_COMP"//g;
    }        

    if ($strip_source_schema && defined($source_schema)) {
        $line =~ s/"$source_schema"\.//g;
        $line =~ s/\b$source_schema\.//g;
    }

    my @line = ($line);

    if ($first_line && $object_type eq 'VIEW') {    
        # We need to split something like
        #
        # CREATE OR REPLACE VIEW "ORACLE_TOOLS"."V_DISPLAY_DDL_SCHEMA" ("SCHEMA_DDL")  BEQUEATH CURRENT_USER  AS select  value(t) as schema_ddl
        #
        # in two lines, one till the AS (non-greedy) and the rest after without leading spaces
        if ($line =~ m/^(\s*create\s+or\s+replace\s+(force\s+)?view\s+.+?\b(?:as|is))\s+(\S+.*)$/i) {
            # split this in two lines
            @line = ($1, $3);
        }
    }

    for (my $nr = 0; $nr < @line; ++$nr) {
        debug("after beautify line; \$line[$nr]: $line[$nr]");
    }

    return @line;
}

sub split_single_output_file ($) {
    trace((caller(0))[3]);

    my $input_file = shift @_;
    
    # only one SQL statement allowed
    my ($output_file, $output_fh, $line, $nr);
        
    open(my $input_fh, $input_file) || error("Can not open $input_file: $!");
            
    while (defined($line = <$input_fh>)) {
        # new sql statement greater than 1 or first line?
        if (($line =~ m!^/\* SQL statement (\d+) .*\*/! && $1 > 1) || !defined($output_fh)) {
            # new file
            $nr = (defined($1) ? $1 : 1);
            $output_file = $input_file;
            $output_file =~ s/\@nr\@/sprintf("%04d", $nr)/e;
            
            smart_close($output_fh) if (defined($output_fh));
                
            $output_fh = smart_open($output_file) 
                or error("Can not write to '$output_file': $!");
        }

        error("File handle must be defined") unless defined($$output_fh);

        print $output_fh $line
            unless $line =~ m/^call\s+dbms_application_info\.(set_module|set_action)\b/;
    }
    
    smart_close($output_fh) if (defined($output_fh));
    close($input_fh);

    unlink($input_file);
}

sub get_object_seq ($) {
    trace((caller(0))[3]);

    my ($object, $object_seq) = @_;

    $object = uc($object);

    error("Object '$object' must be in upper case")
        unless $object eq uc($object);

    return exists($object_info{$object}) ? $object_info{$object}{seq} : undef;
}

sub get_object_file ($) {
    trace((caller(0))[3]);

    my ($object, $object_seq) = @_;

    $object = uc($object);

    error("Object '$object' must be in upper case")
        unless $object eq uc($object);

    return exists($object_info{$object}) && exists($object_info{$object}{file}) ? $object_info{$object}{file} : undef;
}

sub add_object_info ($;$$) {
    trace((caller(0))[3]);

    my ($object, $object_seq, $file) = @_;

    $object = uc($object);

    error("Object '$object' must be in upper case")
        unless $object eq uc($object);

    error("Object '$object' should match 'SCHEMA:TYPE:NAME'")
        unless $object =~ m/^.+\..+\..+$/;

    error("File ($file) must be a base name")
        if (defined($file) && basename($file) ne $file);

    error("Object '$object' already exists.")
        if defined(get_object_file($object));

    debug(sprintf("Add object info for object '%s', object sequence '%s' and file '%s'.",
                  (defined($object) ? $object : 'UNKNOWN'),
                  (defined($object_seq) ? sprintf("%d", $object_seq) : 'UNKNOWN'),
                  (defined($file) ? $file : 'UNKNOWN')));

    my $status = (defined($file) ? FILE_NOT_REUSED : FILE_UNKNOWN);
    
    if (defined($object_seq) && defined($file)) {
        # strip leading zeros otherwise it will be treated as an octal number
        $object_seq =~ m/^0*(\d+)$/;
        $object_seq = int($1);
        $object_seq_max = $object_seq
            if ($interface ne PKG_DDL_UTIL_V4 && $object_seq > $object_seq_max);
    } elsif (!(defined($object_seq) && defined($file))) {
        my ($object_schema, $object_type, $object_name) = split($object_sep_rex, $object);
        my $nr_zeros = ($interface eq PKG_DDL_UTIL_V4 ? 2 : 4);

        # get the highest plus 1
        $object_seq = ($interface eq PKG_DDL_UTIL_V4 ? $object_type_info{$object_type}->{'seq'} : ++$object_seq_max);
        $file = uc(sprintf("%s%0${nr_zeros}d.%s%s.%s", 
                           ($object_type_info{$object_type}->{'repeatable'} ? 'R__' : ''),
                           $object_seq,
                           (${strip_source_schema} && $source_schema eq $object_schema ? '' : $object_schema . '.'),
                           $object_type,
                           $object_name)) . '.sql';
    } else {
        error("Programming error.");
    }
    
    $object_info{$object}{seq} = $object_seq;
    $object_info{$object}{file} = $file;

    # set status, just once
    set_file_status($file, $status, $object);

    info("File '$file' is used for object '$object' and has sequence $object_seq");

    return $file;
}

sub set_file_status ($$;$) {
    trace((caller(0))[3]);

    my ($file, $status, $object) = ($_[0], $_[1], $_[2]);
    my $base_file = basename($file);

    info("File '$base_file' has been " . (-f $file ? "changed": "created"))
        if ($status eq FILE_NOT_MODIFIED || $status eq FILE_MODIFIED);

    $file = $base_file;

    debug(sprintf("Set file status for file '%s', status '%s' and object '%s'.",
                  (defined($file) ? $file : 'UNKNOWN'),
                  (defined($status) ? $status : 'UNKNOWN'),
                  (defined($object) ? $object : 'UNKNOWN')));

    error("File status set twice for file $file, status $status and object $object")
        if (defined($object) && exists($file_info{$file}));

    if (defined($object)) {
        $file_info{$file}{object} = $object;
    }
    $file_info{$file}{status} = $status;
}

sub get_files (@) {
    trace((caller(0))[3]);
    
    my @status = @_;
    my @file = ();

    debug("Getting files for status(es) @status");

    foreach my $file (keys %file_info) {
        my $status = $file_info{$file}{status};

        if (grep(/^$status$/, @status)) {
            debug("Adding file $file with status $status");
            push(@file, $file);
        }
    }
    return @file;
}
                          
sub read_object_info () {
    trace((caller(0))[3]);

    error("Interface must be defined")
        unless (defined($interface));

    $object_seq_max = 0
        if (!defined($object_seq_max) && $interface ne PKG_DDL_UTIL_V4 );
        
    my %objects;
    my $dir = File::Spec->rel2abs($output_directory);

    info(sprintf("checking output directory %s for files to reuse", $dir));

    my ($seq, $schema, $type, $name);

    opendir my $dh, $dir or die "Could not open '$dir' for reading '$!'\n";
    while (my $file = readdir $dh) {
        debug("Checking whether file $file can be reused");
        if ($file =~ m/^(R__)?(?<seq>(\d{4}|\d{2}(\.\d{2})?))\.(?<schema>[^.]+)\.(?<type>[^.]+)\.(?<name>[^.]+)\.sql$/) {
            ($seq, $schema, $type, $name) = ($+{seq}, $+{schema}, $+{type}, $+{name});
            $objects{$seq}{object} = join($object_sep, $schema, $type, $name);
            $objects{$seq}{file} = $file;
            add_object_info($objects{$seq}{object}, $seq, $objects{$seq}{file});
        } elsif ($file =~ m/^(R__)?(?<seq>(\d{4}|\d{2}(\.\d{2})?))\.(?<type>[^.]+)\.(?<name>[^.]+)\.sql$/) {
            ($seq, $schema, $type, $name) = ($+{seq}, $source_schema, $+{type}, $+{name});
            $objects{$seq}{object} = join($object_sep, $schema, $type, $name);
            $objects{$seq}{file} = $file;
            add_object_info($objects{$seq}{object}, $seq, $objects{$seq}{file});
        } else {
            warning("File $file does not match naming conventions for reuse")
                unless ($file eq '.' || $file eq '..');
        }
    }
    closedir $dh;
} # sub read_object_info

sub error (@) {
    croak "ERROR: @_";
}

sub warning (@) {
    print STDERR "WARNING: @_\n";
}

sub info (@) {
    print STDERR "INFO: @_\n"
        if ($verbose >= 1);
}

sub debug (@) {
    print STDERR "DEBUG: @_\n"
        if ($verbose >= 2);
}

sub trace (@) {
    carp "TRACE: @_\n"
        if ($verbose >= 3);
}
