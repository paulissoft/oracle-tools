use strict;
use File::Basename;

my $srcdir = dirname($0);

# Usage: perl find_non_fq_objects.pl [ FILE... ]

# Take the list between ( and ) from pom.xml

my $line_no = 0;
my $file = '';
my $object_names;

sub main();
sub match($);

main();

sub main() {
    open(POM, "$srcdir/../../pom.xml") or die "Can not open POM: $!";
    
    my $parse_object_names = 0;
    my @object_name;
    
    while (<POM>) {
        my $line = $_;
        
        if (!$parse_object_names && $line =~ m!<db.object.names>\s*(\S+)?\s*$!) {
            $parse_object_names = 1;
            push(@object_name, $1)
                if (defined($1));
        } elsif ($parse_object_names && $line =~ m!^\s*(\S+)?\s*</db.object.names>!) {
            $parse_object_names = 0;
            push(@object_name, $1)
                if (defined($1));
        } elsif ($parse_object_names && $line =~ m!^\s*,\s*(\S+)!) {
            push(@object_name, $1);
        }
    }

    $object_names = join('|', @object_name);

    warn("\$object_names: $object_names");

    close(POM);
    
    while (<>) {
        if ($ARGV ne $file) {
            $line_no = 0;
        }

        $file = $ARGV;
        $line_no++;

        my $object = match('oracle_tools');
        
        printf("[%s#%04d] %s", $file, $line_no, $_)
            if ( defined($object) && !m/("ORACLE_TOOLS"."|(create|alter|comment on) (table|index) |store as |constraint |constructor function |end |--.*|dbug.print\(.*|'|`|"|\/\*.*)$object/i );
    }
}

sub match($) {
    my ($look_behind) = @_;    
    
    if (m/(?<!$look_behind\.)\b($object_names)\b/i) { return $1; };
    return undef;
}
