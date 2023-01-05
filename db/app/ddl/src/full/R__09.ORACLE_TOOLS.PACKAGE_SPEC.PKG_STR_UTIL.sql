CREATE OR REPLACE PACKAGE "ORACLE_TOOLS"."PKG_STR_UTIL" AUTHID DEFINER IS /* -*-coding: utf-8-*- */

/**

String utilities.

**/

c_debugging constant naturaln := 0; -- 0: none, 1: standard, 2: verbose, 3: even more verbose

type t_clob_tab is table of clob;

function dbms_lob_substr
( p_clob in clob
, p_amount in naturaln := 32767
, p_offset in positiven := 1
)
return varchar2;

/**

An enhancement for dbms_lob.substr().

It appears that dbms_lob.substr(amount => 32767) returns at most 32764 characters.

This function corrects that.

**/

procedure split
( p_str in varchar2 -- The input string to split.
, p_delimiter in varchar2 := ',' -- The separator string.
, p_str_tab out nocopy dbms_sql.varchar2a -- The output table.
);

procedure split
( p_str in clob
, p_delimiter in varchar2 := ',' -- The separator string.
, p_str_tab out nocopy dbms_sql.varchar2a -- The output table.
);

procedure split
( p_str in clob
, p_delimiter in varchar2 := ',' -- The separator string.
, p_str_tab out nocopy t_clob_tab -- The output table.
);

/**

Split a string separated by a delimiter string.

**/

function join
( p_str_tab in dbms_sql.varchar2a
, p_delimiter in varchar2 := ','
)
return varchar2
deterministic;

procedure join
( p_str_tab in dbms_sql.varchar2a -- The input table.
, p_delimiter in varchar2 := ',' -- The separator string.
, p_str out nocopy clob
);

/**
 
Join a string separated by a delimiter string.

**/

procedure trim
( p_str in out nocopy clob
, p_set in varchar2 := ' '
);

procedure trim
( p_str_tab in out nocopy t_clob_tab -- A string collection.
, p_set in varchar2 := ' ' -- The set of characters to remove from the begin and end.
);

/**

Removes left and right from the input table all characters in a set.
All null elements will be removed.

**/

function compare
( p_str1_tab in t_clob_tab -- The first CLOB collection.
, p_str2_tab in t_clob_tab -- The second CLOB collection.
)
return integer;

/**

Compare two CLOB collections and returns 0 if totally equal (count and each element).

Returns:
- -1 if p_str1_tab.count < p_str2_tab.count or
             p_str1_tab.count = p_str2_tab.count and there is a row R for which
             dbms_lob.compare(p_str1_tab(R), p_str2_tab(R)) < 0 and
             for all rows R' < R dbms_lob.compare(p_str1_tab(R'), p_str2_tab(R')) = 0
- 0 if p_str1_tab.count = p_str2_tab.count and
             for all rows R dbms_lob.compare(p_str1_tab(R), p_str2_tab(R)) = 0
- 1 if p_str1_tab.count > p_str2_tab.count or
             if p_str1_tab.count = p_str2_tab.count and there is a row R with
             dbms_lob.compare(p_str1_tab(R), p_str2_tab(R)) > 0 and
             for all rows R' < R dbms_lob.compare(p_str1_tab(R'), p_str2_tab(R')) = 0

May throw ORA-06531  Reference to an uninitialized collection

**/

procedure compare
( p_str1_tab in t_clob_tab -- The first CLOB collection.
, p_str2_tab in t_clob_tab -- The second CLOB collection.
, p_first_line_not_equal out binary_integer -- The first line not equal (null when there are no differences).
, p_first_char_not_equal out binary_integer -- The first character position that differs for line p_first_line_not_equal.
);

/**

Compares two CLOB collections.

The output parameter p_first_char_not_equal will be:
- NULL when no differences or one collection is a sub set of the other (but not equal).
- Not NULL if there is a row R and character position C for which:
  dbms_lob.substr(lob_loc => p_str1_tab(R), offset => C, amount => 1) !=
  dbms_lob.substr(lob_loc => p_str2_tab(R), offset => C, amount => 1)

May throw ORA-06531  Reference to uninitialized collection

**/

procedure compare
( p_source_line_tab in dbms_sql.varchar2a -- The source lines
, p_target_line_tab in dbms_sql.varchar2a -- The target lines
, p_stop_after_first_diff in boolean default false -- Stop after the first difference?
, p_show_equal_lines in boolean default true -- Show equal lines?
, p_convert_to_base64 in boolean default false -- Convert a line to base64 (hex) while displaying differences?
, p_compare_line_tab out nocopy dbms_sql.varchar2a -- The comparison
);

/**

Compare two line arrays and return diff like results.

The idea is that the output shows you how to turn the source into the target, i.e. which lines have to be added or removed.

The code is taken from Diff.java, Copyright © 2000-2017, Robert Sedgewick and Kevin Wayne.
Originally found on http://introcs.cs.princeton.edu/java/96optimization/Diff.java.html
but it seems now to reside on https://introcs.cs.princeton.edu/java/23recursion/Diff.java.html.

The output format is:

  [source line index][target line index][marker] line

where marker is one of '=', '-' or '+'. 
Line is the source line if marker is '-' (remove) and the target line if marker is '+' (add). 
When marker is '=' both the source and target line are equal so it is one of those.
The line displayed is converted to base64 when the parameter p_convert_to_base64 equals true.

**/

procedure compare
( p_source in clob -- The source CLOB 
, p_target in clob -- The target CLOB 
, p_delimiter in varchar2 default chr(10) -- The delimiter to split by
, p_stop_after_first_diff in boolean default false -- Stop after the first difference?
, p_show_equal_lines in boolean default true -- Show equal lines?
, p_convert_to_base64 in boolean default false -- Convert a line to base64 (hex) while displaying differences?
, p_compare_line_tab out nocopy dbms_sql.varchar2a -- The comparison
);

/**

Compare two CLOBs, split them by a delimiter and return diff like results.

See compare() above.

**/

procedure append_text
( pi_buffer in varchar2 -- The buffer.
, pio_clob in out nocopy clob -- The CLOB.
);

/**

Append a buffer to a CLOB using dbms_lob.writeappend().

**/

procedure append_text
( pi_text in varchar2 -- The text to write to the buffer.
, pio_buffer in out nocopy varchar2 -- The buffer that, when full, is flushed to the CLOB.
, pio_clob in out nocopy clob -- The CLOB.
);

/**

Append a text to a buffer and flush the buffer to a CLOB when full.

See also http://www.talkapex.com/2009/06/how-to-quickly-append-varchar2-to-clob.html

**/

procedure text2clob
( pi_text_tab in oracle_tools.t_text_tab -- The text collection.
, pio_clob in out nocopy clob -- The CLOB. If null a temporary is created.
, pi_append in boolean := false -- Should we append or not? If not the CLOB will be trimmed to zero bytes.
);

/**

Write or append a text collection to a CLOB.

**/

function text2clob
( pi_text_tab in oracle_tools.t_text_tab
)
return clob;

function clob2text
( pi_clob in clob -- The CLOB. If null a temporary is created.
, pi_trim in naturaln default 0 -- Trim at both ends?
)
return oracle_tools.t_text_tab;

/**

Write or append a text collection to a CLOB.

**/

$if oracle_tools.cfg_pkg.c_testing $then

-- test functions

--%suitepath(DDL)
--%suite

--%test
procedure ut_split1;

--%test
procedure ut_split2;

--%test
procedure ut_split3;

--%test
procedure ut_trim1;

--%test
--%disabled
procedure ut_trim2;

--%test
--%disabled
procedure ut_compare1;

--%test
--%disabled
procedure ut_compare2;

--%test
--%disabled
procedure ut_append_text1;

--%test
--%disabled
procedure ut_append_text2;

--%test
--%disabled
procedure ut_text2clob1;

--%test
--%disabled
procedure ut_text2clob2;

--%test
--%disabled
procedure ut_clob2text;

$end -- $if oracle_tools.cfg_pkg.c_testing $then

END pkg_str_util;
/

