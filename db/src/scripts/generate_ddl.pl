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
installation sequence order as specified in file install_sequence.txt which is
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

=item B<--help>

This help.

=item B<--input-file>

For debugging purposes.

=item B<--output-directory>

The output directory, default the current directory.

=item B<--remove-output-directory>

A boolean toggle to indicate whether the output-directory option must be
removed before creating scripts. Default value is NO.

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

Gert-Jan Paulissen, E<lt>gert.jan.paulissen@gmail.comE<gt>.

=head1 VERSION

$Header$

=head1 HISTORY

=over 4

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
use Data::Dumper;
use English;
use File::Basename;
use File::Copy;
use File::Path qw(make_path remove_tree);
use File::Spec;
use Getopt::Long;
use Pod::Usage;
use strict;
use utf8;
use warnings;
 
# CONSTANTS
use constant PKG_DDL_UTIL_V4 => 'pkg_ddl_util v4';
use constant PKG_DDL_UTIL_V5 => 'pkg_ddl_util v5';

# VARIABLES

my $program = &basename($0);
my $encoding = ''; # was :crlf:encoding(UTF-8)
my $install_sql_preamble_printed = 0;
    
# command line options
my $dynamic_sql = 0; # displayed in print_run_info()
my $force_view = 1; # displayed in print_run_info()
my $input_file = undef;
my $output_directory = '.';
my $remove_output_directory = 0; # displayed in print_run_info()
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

my %object_type_info = (
    # all object types are from pkg_ddl_util.object_type_order:
    'SEQUENCE' => { expr => [ $sequence_expr ], seq => 1, repeatable => 0, plsql => 0 },
    'TYPE_SPEC' => { expr => [ $type_spec_expr ], seq => 2, repeatable => 0, plsql => 1, terminator => ';/' }, # create or replace type may fail when it already exists due to dependent objects (e.g. collection of other types)
    'CLUSTER' => { expr => [ $cluster_expr ], seq => 3, repeatable => 0, plsql => 0 },
    # 'AQ_QUEUE_TABLE' => { seq => 4, repeatable => 0 },
    # 'AQ_QUEUE' => { seq => 5, repeatable => 0 },
    'TABLE' => { expr => [ $table_expr ], seq => 6, repeatable => 0, plsql => 0 },
    # 'DB_LINK' => { seq => 7, repeatable => 0, plsql => 0 },
    'FUNCTION' => { expr => [ $function_expr ], seq => 8, repeatable => 1, plsql => 1 },
    'PACKAGE_SPEC' => { expr => [ $package_spec_expr ], seq => 9, repeatable => 1, plsql => 1 },
    'VIEW' => { expr => [ $view_expr ], seq => 10, repeatable => 1, plsql => 0 },
    'PROCEDURE' => { expr => [ $procedure_expr ], seq => 11, repeatable => 1, plsql => 1 },
    'MATERIALIZED_VIEW' => { expr => [ $materialized_view_expr ], seq => 12, repeatable => 0, plsql => 0 },
    'MATERIALIZED_VIEW_LOG' => { expr => [ $materialized_view_log_expr ], seq => 13, repeatable => 0, plsql => 0 },
    'PACKAGE_BODY' => { expr => [ $package_body_expr ], seq => 14, repeatable => 1, plsql => 1 },
    'TYPE_BODY' => { expr => [ $type_body_expr ], seq => 15, repeatable => 1, plsql => 1 },
    'INDEX' => { expr => [ $index_expr ], seq => 16, repeatable => 0, plsql => 0, use_base_object_name => 1 },
    'TRIGGER' => { expr => [ $trigger_expr ], seq => 17, repeatable => 1, plsql => 1, use_base_object_name => 0 }, # do not put them in one file because of instead trigger moves
    'OBJECT_GRANT' => { expr => [ $object_grant_expr ], seq => 18, repeatable => 1, plsql => 0, use_base_object_name => 1 },
    'CONSTRAINT' => { expr => [ $constraint_expr ], seq => 19, repeatable => 0, plsql => 0, use_base_object_name => 1 },
    'REF_CONSTRAINT' => { expr => [ $ref_constraint_expr ], seq => 20, repeatable => 0, plsql => 0, use_base_object_name => 1 },
    'SYNONYM' => { expr => [ $synonym_expr ], seq => 21, repeatable => 1, plsql => 0 },
    # Must be created after the TABLE/VIEW
    'COMMENT' => { expr => [ $comment_expr ], seq => 22, repeatable => 1, plsql => 0, use_base_object_name => 1 },
    # 'DIMENSION' => { seq => 23, repeatable => 0, plsql => 0 },
    # 'INDEXTYPE' => { seq => 24, repeatable => 1, plsql => 0 },
    'JAVA_SOURCE' => { seq => 25, repeatable => 1, plsql => 0, terminator => '/' },
    # 'LIBRARY' => { seq => 26, repeatable => 1, plsql => 0 },
    # 'OPERATOR' => { seq => 27, repeatable => 1, plsql => 0 },
    'REFRESH_GROUP' => { expr => \@refresh_group_expr, seq => 28, repeatable => 0, plsql => 1 },
    # 'XMLSCHEMA' => { seq => 29, repeatable => 0 },
    'PROCOBJ' => { expr => \@procobj_expr, seq => 30, repeatable => 0, plsql => 1 },
    );

my %object_seq = ();

# A list of modified files so we can remove non-modified files in non single output mode.
my %file_modified = ();

my $VERSION = "2021-08-24";

    
# PROTOTYPES

sub main ();
sub process_command_line ();
sub process ();
sub process_object_type ($$$$);
sub get_object_type_line ($$);
sub parse_object ($);
sub get_object ($$$;$$$);
sub object_file_name ($$$);                  
sub open_file ($$$$);
sub sql_statement_add ($$$$;$);
sub sort_sql_statements ($$$);
sub sort_dependent_objects ($$$);
sub all_sql_statements_flush ($$$$);
sub object_sql_statements_flush ($$$$$);
sub sql_statement_flush ($$$$$$);
sub print_run_info ($$);
sub remove_cr_lf ($);
sub remove_leading_empty_lines ($);
sub remove_trailing_empty_lines ($);
sub beautify_line ($$$$$$);
sub split_single_output_file($);
sub error (@);
sub warning (@);
sub info (@);
sub debug (@);
                                                
# MAIN

main();

# SUBROUTINES

sub main () {
    info("\@ARGV: @ARGV");
    process_command_line();
    print_run_info(\*STDERR, 0);

    process();
}

sub process_command_line ()
{
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
               'help' => sub { pod2usage(-verbose => 2) },
               'input-file=s' => \$input_file,
               'output-directory=s' => \$output_directory,
               'remove-output-directory!' => \$remove_output_directory,
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
}

sub process () {
    my $install_sql = ($skip_install_sql ? undef : File::Spec->catfile($output_directory, 'install.sql'));
    my $install_sequence_txt = File::Spec->catfile($output_directory, 'install_sequence.txt');
    my $in;

    if (defined($input_file)) {
        open $in, "< $input_file"
            or error("Can not open '$input_file': $!");
    } else {
        $in = \*STDIN;
    }

    my $fh_seq = undef;
    
    # read previous object sequence numbers first so we can recreate them even if the directory is removed after
    if ( -e $install_sequence_txt ) {
        open($fh_seq, '<', $install_sequence_txt)
            or error("Can not open '$install_sequence_txt': $!");

        my $line_nr = 0;
        
        while (<$fh_seq>) {
            if (m/^(.*)[:.](.*)[:.](.*)$/) {
                $_ = join(':', $1, $2, $3);
                error("Object must be unique: $_")
                    if exists($object_seq{$_});
                $object_seq{$_} = ++$line_nr;
                debug("\$object_seq{$_}:", $object_seq{$_});
            }
        }
        close $fh_seq;
        $fh_seq = undef;
    }

    if ($remove_output_directory) {
        # Only when a complete new tree is created, the install.sql script is reliable.
        # Because when the tree is not removed, the user may just create a single script and not the whole tree.
        remove_tree($output_directory, { verbose => 0 });
    }

    # always make the output directory
    make_path($output_directory, { verbose => 0 });

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
        open($fh, ">$encoding", $file) 
            or error("Can not write to '$file': $!");
    } else {
        # GJP 2021-07-27  $remove_output_directory should not be a condition so put defined() around it
        if (defined($remove_output_directory) && defined($install_sql)) {
            open($fh_install_sql, ">$encoding", $install_sql) 
                or error("Can not write to '$install_sql': $!");
        }
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
                $interface = $1;
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
                    beautify_line("\"$object_schema\".\"$object_name\"", $object_schema, $object_name, $object_type, $line_no, \$line);

                    sql_statement_add(\$line, \%sql_statements, $object, $ddl_no, $ddl_info);
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

    debug(Data::Dumper->Dump([%sql_statements], [qw(sql_statements)]));

    all_sql_statements_flush($fh_install_sql, \$fh, \$nr_sql_statements, \%sql_statements);
    close($fh);
    
    close($fh_install_sql)
        if defined($fh_install_sql);

    if (defined($input_file)) { # Suppress 'Filehandle STDIN reopened as $fh_seq only for output'
        close($in);
    }

    # do never remove the input file
    if (defined($single_output_file) && $single_output_file =~ m/\@nr\@/) {
        split_single_output_file($file);
    }

    # Only write $install_sequence_txt for version 5
    if ($interface eq PKG_DDL_UTIL_V5) {
        open($fh_seq, '>', $install_sequence_txt)
            or error("Can not write '$install_sequence_txt': $!");

        print $fh_seq "-- This file is maintained by generate_ddl.pl\n";
        print $fh_seq "-- DO NEVER REMOVE LINES BELOW BUT YOU MAY CHANGE THE ORDER OR ADD LINES (AT THE END)\n";
        foreach my $object (sort { $object_seq{$a} <=> $object_seq{$b} } keys %object_seq) {
            print $fh_seq "$object\n";
        }
        close $fh_seq;
    }

    # Remove obsolete SQL scripts matching the Flyway naming convention and not being modified.
    if (!$remove_output_directory && !defined($single_output_file)) {
        # GJP 2021-08-21
        my @obsolete_files = glob(File::Spec->catfile($output_directory, '*.sql'));

        @obsolete_files = grep { -f $_ && m/\b(R__)?(\d{2}|\d{4})\./ && !exists($file_modified{$_}) } @obsolete_files;

        info('obsolete files to delete:', @obsolete_files);
        
        unlink(@obsolete_files) == scalar(@obsolete_files) or error("Can not remove obsolete files");
    }
}

sub process_object_type ($$$$)
{
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
                        
                beautify_line($matched_object, $object_schema, $object_name, $object_type, 1, \$line);
                
                $last_line = $line;
                $line =~ s/^\s+//; # strip leading space
                sql_statement_add(\$line, $r_sql_statements, $object, $ddl_no);
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
                sql_statement_add(\$line, $r_sql_statements, $object, $ddl_no);
            } else {
                # empty
                sql_statement_add(\$line, $r_sql_statements, $object, $ddl_no);
            }
        }
    }
}

sub get_object_type_line ($$)
{
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
    
sub parse_object($)
{
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
    my ($object_schema, $object_type, $object_name, $base_object_schema, $base_object_type, $base_object_name) = @_;

    my $sep = ':';

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
        return sprintf("%s$sep%s$sep%s", 
                       $object_schema,
                       $object_type,
                       $base_object_name);
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

sub object_file_name ($$$)
{
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

    my $object_seq_key = join(':', $object_schema, $object_type, $object_name);
    my $object_file_name;
    my $nr_zeros = ($interface eq PKG_DDL_UTIL_V4 ? 2 : 4);

    if (!exists($object_seq{$object_seq_key})) {
        $object_seq{$object_seq_key} = keys(%object_seq) + 1;
        debug("\$object_seq{$object_seq_key}:", $object_seq{$object_seq_key});
    }
    $object_file_name = 
        uc(sprintf("%s%0${nr_zeros}d.%s%s.%s", 
                   ($object_type_info{$object_type}->{'repeatable'} ? 'R__' : ''),
                   ($interface eq PKG_DDL_UTIL_V4 ? $object_type_info{$object_type}->{'seq'} : $object_seq{$object_seq_key}),
                   (${strip_source_schema} && $source_schema eq $object_schema ? '' : $object_schema . '.'),
                   $object_type,
                   $object_name)) . '.sql';
    
    return $object_file_name;
}

sub open_file ($$$$)
{
    my ($file, $fh_install_sql, $r_fh, $ignore_warning_when_file_exists) = @_;

    if (defined $fh_install_sql && !$install_sql_preamble_printed) {
        print $fh_install_sql "whenever oserror exit failure\nwhenever sqlerror exit failure\nset define off sqlblanklines on\nALTER SESSION SET PLSQL_WARNINGS = 'ENABLE:ALL';\n\n";
        $install_sql_preamble_printed = 1;
    }
    
    print $fh_install_sql "prompt \@\@$file\n\@\@$file\n"
        if (defined $fh_install_sql);

    $file = File::Spec->catfile($output_directory, $file);

    # Just issue a warning till now and append
    if ($remove_output_directory && -f $file) {
        warn "WARNING: File $file already exists. Duplicate objects?"
            unless ($ignore_warning_when_file_exists);
        
        open($$r_fh, ">>$encoding", $file)
            or error("Can not append to '$file': $!");

        info("Appending to $file");
    } else {
        open($$r_fh, ">$encoding", $file)
            or error("Can not write to '$file': $!");

        info("Writing to $file");
    }

    $file_modified{$file} = 1;
}
                                    
sub sql_statement_add ($$$$;$)
{
    my ($r_sql_line, $r_sql_statements, $object, $ddl_no, $ddl_info) = @_;

    debug("Adding '$$r_sql_line' for object $object and statement $ddl_no");

    $r_sql_statements->{$object}->{seq} = scalar(keys %$r_sql_statements)
        unless exists($r_sql_statements->{$object}->{seq});

    $r_sql_statements->{$object}->{ddls}->[$ddl_no] = { 'ddl_info' => $ddl_info, 'ddl' => [] }
        unless exists($r_sql_statements->{$object}->{ddls}->[$ddl_no]);

    my $r_sql_statement = $r_sql_statements->{$object}->{ddls}->[$ddl_no]->{ddl};

    push(@$r_sql_statement, $$r_sql_line);

    error(sprintf("The number of statements for object '$object' is %d which is not the current ddl no (%d)", 
                  scalar(@{$r_sql_statements->{$object}->{ddls}}), 
                  $ddl_no + 1))
        unless $ddl_no + 1 == scalar(@{$r_sql_statements->{$object}->{ddls}});
    
    $$r_sql_line = '';
}

sub sort_sql_statements ($$$) {
    my ($r_sql_statements, $a, $b) = @_;
    my $result;

    if ($interface eq PKG_DDL_UTIL_V4) {
        # just sort by sequence
        $result = ($r_sql_statements->{$a}->{seq} <=> $r_sql_statements->{$b}->{seq});
    } else {
        error("\$object_seq{$a} does not exist")
            unless exists($object_seq{$a});
        error("\$object_seq{$b} does not exist")
            unless exists($object_seq{$b});
        
        $result = ($object_seq{$a} <=> $object_seq{$b});
    }

    return $result;
}

sub sort_dependent_objects ($$$) {
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

sub all_sql_statements_flush ($$$$)
{
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
}

sub object_sql_statements_flush ($$$$$)
{
    my ($fh_install_sql, $r_fh, $r_nr_sql_statements, $r_sql_statements, $object) = @_;

    my $ignore_warning_when_file_exists = 0;
    
    debug("Flushing $object with ", scalar(@$r_sql_statements), " statement(s)");

    return if scalar(@$r_sql_statements) == 0;
    
    # GPA 2017-02-28 #140681641 Unique constraints must be created before a referencing key is created.
    # All DDL stored must be saved for one and only one object name, otherwise the order of DDL statements determined by the database may change.
    if ( defined($single_output_file) ) {
        error("File handle must be defined") unless defined($$r_fh);

        print $$r_fh sprintf("call dbms_application_info.set_module('%s', null);\n", basename($single_output_file));
    } else {
        my ($object_schema, $object_type, $object_name) = split(/:/, $object);

        if (not(exists($object_type_info{$object_type})) ||
            not(exists($object_type_info{$object_type}->{'repeatable'})) ||
            not(exists($object_type_info{$object_type}->{'seq'})))
        {
            warning("Skipping object type $object_type");
            return;
        }

        my $file = object_file_name($object_schema, $object_type, $object_name);
    
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
                info("Moving DDL of instead of trigger $object_schema.$object_name to DDL for view $+{object}");

                # override $object_schema, $object_type and $object_name so that the 
                my ($object_schema, $object_type, $object_name);
                
                ($object_schema, $object_name) = parse_object($+{object});

                $object_type = 'VIEW';

                # put it in the VIEW file!
                $file = object_file_name($object_schema, $object_type, $object_name);
                # and ignore the warning
                $ignore_warning_when_file_exists = 1;
            }
        }
        open_file($file, $fh_install_sql, $r_fh, $ignore_warning_when_file_exists);
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

    # Update the grand total
    $$r_nr_sql_statements += $nr_sql_statements;
}

sub sql_statement_flush ($$$$$$)
{
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

    my (undef, $object_type, undef) = split(/:/, $object);
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
            # Only the first statement is relevant. Statement 2 and further are never create or replace statements

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
        $sql_statement .= "\n/";
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

sub print_run_info ($$)
{
    my ($fh, $install) = @_;

    error("File handle must be defined") unless defined($fh);
    
    print $fh '/* ', "perl generate_ddl.pl (version $VERSION)";
    print $fh sprintf(" --%s%s", ($dynamic_sql ? '' : 'no'), 'dynamic-sql');
    print $fh sprintf(" --%s%s", ($force_view ? '' : 'no'), 'force-view');
    print $fh sprintf(" --%s%s", ($remove_output_directory ? '' : 'no'), 'remove-output-directory');
    print $fh sprintf(" --%s%s", ($skip_install_sql ? '' : 'no'), 'skip-install-sql');
    print $fh " --source-schema=$source_schema" if (length($source_schema) > 0);
    print $fh sprintf(" --%s%s", ($strip_source_schema ? '' : 'no'), 'strip-source-schema');
    print $fh ' */', "\n\n";
    print $fh "whenever sqlerror exit failure\nwhenever oserror exit failure\n\nset define off\n\n"
        if ($install);
}

sub remove_cr_lf ($) {
    my $r_line = $_[0];
    
    $$r_line =~ s/\r?\n//mg;
}

sub remove_leading_empty_lines ($) 
{
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

sub remove_trailing_empty_lines ($) 
{
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
    my ($matched_object, $object_schema, $object_name, $object_type, $line_no, $r_line) = @_;

    return
        unless defined($$r_line) && $$r_line ne '';
        
    debug("\$\$r_line before: $$r_line");

    if ($line_no == 1) {
        if ($object_type eq 'VIEW') {
            $$r_line =~ s/\s+DEFAULT COLLATION "USING_NLS_COMP"//g;
            $$r_line =~ s/\s+FORCE\s+/ /i
                if (!$force_view); 
            $$r_line =~ s/\s+(as\s*)$/' ' . $1/ie;
        } elsif ($object_type_info{$object_type}->{'repeatable'}) {
            # create => create or replace
            $$r_line =~ s/^\s*CREATE\s+/CREATE OR REPLACE /i
                unless $$r_line =~ m/^\s*CREATE\s+OR\s+REPLACE\b/i;
        } elsif ($object_type eq 'TYPE_SPEC') {
            # create or replace => create (TYPE)
            $$r_line =~ s/^\s*CREATE\s+OR\s+REPLACE\s+/CREATE /i;
        }
            
        # Do not change NONEDITIONABLE since some views may need it (APEX views for instance)
        $$r_line =~ s/\bEDITIONABLE\s+//i; # Flyway does not like CREATE OR REPLACE EDITIONABLE PACKAGE 

        my $object_fq_name = ($strip_source_schema && $object_schema eq $source_schema ? '' : "\"$object_schema\".");

        $object_fq_name .= "\"$object_name\"";

        # beautify the name
        $$r_line =~ s/(.*\S)\s+$matched_object(\s+(?:AS|IS)\b)?(\s+OBJECT\b)?/uc($1).' '.$object_fq_name.(defined($2)?uc($2):'').(defined($3)?uc($3):'')/ie;
    }

    if ($object_type eq 'TABLE') {
        # "ADDRESS_TYPE" VARCHAR2(30) COLLATE "USING_NLS_COMP",
        # =>
        # "ADDRESS_TYPE" VARCHAR2(30),
        
        $$r_line =~ s/\s+COLLATE "USING_NLS_COMP"//g;
    }        

    if ($strip_source_schema && defined($source_schema)) {
        $$r_line =~ s/"$source_schema"\.//g;
    }

    debug("\$\$r_line after : $$r_line");
}

sub split_single_output_file ($) {
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
            
            close($output_fh) if (defined($output_fh));
                
            open($output_fh, ">$encoding", $output_file) 
                or error("Can not write to '$output_file': $!");
        }

        error("File handle must be defined") unless defined($$output_fh);

        print $output_fh $line
            unless $line =~ m/^call\s+dbms_application_info\.(set_module|set_action)\b/;
    }
    
    close($output_fh) if (defined($output_fh));
    close($input_fh);

    unlink($input_file);
}

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
