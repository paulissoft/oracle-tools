# % git diff --stat
#  apex/app/src/export/application/create_application.sql | 2 +-
#  1 file changed, 1 insertion(+), 1 deletion(-)

# count the number of lines with create_application.sql where there are two changes: one insertion and one deletion
/create_application\.sql[ \t\r\n]+\|[ \t\r\n]+2[ \t\r\n]+\+-$/ { ++m }
# count all lines including the last line with totals
{ ++n }
# If only create_application.sql has changed with one insertion and one deletion print YES, else NO.
END { if ( m >= 1 && m == n - 1 ) { print "YES" } else { print "NO" } }
