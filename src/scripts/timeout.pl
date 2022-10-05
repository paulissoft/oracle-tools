#!/usr/bin/env perl

=pod

=head1 NAME

timeout.pl - Run a command with a timeout.

=head1 SYNOPSIS

perl timeout.pl [-h|--help] [-t|--timeout] [-v|--verbose] [COMMAND ARGUMENTS...]

=head1 DESCRIPTION

This script creates a child process to run the command with its arguments. The parent process will then wait the number of seconds specified by the timeout option.

=head1 OPTIONS

=over 4

=item B<-h|--help>

This help.

=item B<-t|--timeout>

The timeout specified in seconds. Defaults to 10 seconds. A timeout less than 1 will be set to 10.

=item B<-v|--verbose>

Increasing the verbosity.

=back

=head1 NOTES

=head1 EXAMPLES

=head1 BUGS

=head1 SEE ALSO

=head1 AUTHOR

Gert-Jan Paulissen, E<lt>paulissoft@gmail.comE<gt>.

=head1 VERSION

$Header$

=head1 HISTORY

=cut

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use POSIX ":sys_wait_h";

my $timeout = 10;
my $verbose = 0;

# prototypes
sub main ();
sub parse_command_line ();
sub error ($);
sub warning ($);
sub info ($);
sub process (@);

main();

sub main () {
    # Windows FTYPE and ASSOC cause the command 'textrepl  -h -c file'
    # to have ARGV[0] == '  -h -c file' and number of arguments 1.
    # Hence strip the spaces from $ARGV[0] and recreate @ARGV.
    if ( @ARGV == 1 && $ARGV[0] =~ s/^\s+//o ) {
        @ARGV = split( / /, $ARGV[0] );
    }

    parse_command_line();
    
    process(@ARGV);
}

sub parse_command_line () {
    Getopt::Long::Configure(qw(require_order));

    #
    GetOptions('help' => sub { pod2usage(-verbose => 2) },
               'timeout=i' => \$timeout,
               'verbose+' => \$verbose
        )
        or pod2usage(-verbose => 0);

    $timeout = 10
        if (!defined($timeout) || $timeout < 1);
} # parse_command_line

sub error ($) {
    die "ERROR: $_[0]\n";
}
    
sub warning ($) {
    print STDERR "WARNING: $_[0]\n";
}
    
sub info ($) {
    print STDERR "INFO: $_[0]\n"
        if ($verbose > 0);
}
    
sub process (@) {
    my @args = @_;
    my $seconds_to_sleep = $timeout;
    
    my $pid = fork();

    if (!$pid) {
        exec { $args[0] } @args;
        # no more code here!!!
    } else {
        info("waiting for child process with pid $pid");
        
        # Continue to sleep 1 second as long as there is time left and the child is still there

        my $kid = 0;
        
        while (--$seconds_to_sleep >= 0 && $kid <= 0) {
            $kid = waitpid($pid, WNOHANG);

            info("waitpid($pid, WNOHANG): $kid");
            
            sleep(1)
                if $kid <= 0;
        }
        
        if ($kid <= 0) {
            # child still there: kill it
            warning("command '@args' still runs: about to kill it");
            
            kill(9, $pid);
            
            error "timeout occurred after $timeout seconds for command '@args'";
        } else {
            my $status = $?;
            
            info("command '@args' status: $status");

            if ($status == -1) {
                die "command '@args' failed to execute: $!";
            }
            elsif ($status & 127) {
                die sprintf("command '@args' died with signal %d, %s coredump",
                            ($status & 127),  ($status & 128) ? 'with' : 'without');
            }
            else {
                $status >>= 8;                
                if ($status == 0) {
                    info sprintf("command '@args' exited with value %d", $status);
                } else {
                    warning sprintf("command '@args' exited with value %d", $status);
                }
                exit $status;
            }
        }
    }
}
