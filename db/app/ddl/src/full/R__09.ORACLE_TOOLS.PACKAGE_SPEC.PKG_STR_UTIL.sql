CREATE OR REPLACE PACKAGE "ORACLE_TOOLS"."PKG_STR_UTIL" IS
/**
 * <h1>Functionality</h1>
 * <p>
 * String utilities.
 * </p>
 * <h2>NOTE 1</h2>
 * <p>
 * The documentation is in PLDoc format
 * (<a href="http://www.sourceforge.net/projects/pldoc">http://www.sourceforge.net/projects/pldoc</a>).
 * </p>
 * @headcom
 *
 */

c_debugging constant naturaln := 0; -- 0: none, 1: standard, 2: verbose, 3: even more verbose

type t_clob_tab is table of clob;

/**
 * An enhancement for dbms_lob.substr().
 *
 * It appears that dbms_lob.substr(amount => 32767) returns at most 32764 characters.
 * This function corrects that.
 *
 * @param p_clob       The CLOB.
 * @param p_amount     The amount.
 * @param p_offset     The offset.
 *
 * @return The substring
 */
function dbms_lob_substr
( p_clob in clob
, p_amount in naturaln := 32767
, p_offset in positiven := 1
)
return varchar2;

/**
 * Split a string separated by a delimiter string.
 *
 * @param p_str        The input string to split.
 * @param p_delimiter  The separator string.
 * @param p_str_tab    The output table.
 */
procedure split
( p_str in varchar2
, p_delimiter in varchar2 := ','
, p_str_tab out nocopy dbms_sql.varchar2a
);

procedure split
( p_str in clob
, p_delimiter in varchar2 := ','
, p_str_tab out nocopy dbms_sql.varchar2a
);

procedure split
( p_str in clob
, p_delimiter in varchar2 := ','
, p_str_tab out nocopy t_clob_tab
);

/**
 * Removes left and right from the input string all characters in a set.
 *
 * @param p_str  The input string. If it consists only of characters from the set it will become empty.
 * @param p_set  The set of characters to remove from the begin and end.
 */
procedure trim
( p_str in out nocopy clob
, p_set in varchar2 := ' '
);

/**
 * Removes left and right from the input table all characters in a set.
 * All null elements will be removed.
 *
 * @param p_str_tab  A string collection.
 * @param p_set      The set of characters to remove from the begin and end.
 */
procedure trim
( p_str_tab in out nocopy t_clob_tab
, p_set in varchar2 := ' '
);

/**
 * Compare two CLOB collections and returns 0 if totally equal (count and each element).
 *
 * @param p_str1_tab  The first CLOB collection.
 * @param p_str2_tab  The second CLOB collection.
 *
 * @return -1 if p_str1_tab.count < p_str2_tab.count or
 *            p_str1_tab.count = p_str2_tab.count and there is a row R for which
 *            dbms_lob.compare(p_str1_tab(R), p_str2_tab(R)) < 0 and
 *            for all rows R' < R dbms_lob.compare(p_str1_tab(R'), p_str2_tab(R')) = 0
 *          0 if p_str1_tab.count = p_str2_tab.count and
 *            for all rows R dbms_lob.compare(p_str1_tab(R), p_str2_tab(R)) = 0
 *          1 if p_str1_tab.count > p_str2_tab.count or
 *            if p_str1_tab.count = p_str2_tab.count and there is a row R with
 *            dbms_lob.compare(p_str1_tab(R), p_str2_tab(R)) > 0 and
 *            for all rows R' < R dbms_lob.compare(p_str1_tab(R'), p_str2_tab(R')) = 0

 * @throws ORA-06531  Reference to an uninitialized collection
 */
function compare
( p_str1_tab in t_clob_tab
, p_str2_tab in t_clob_tab
)
return integer;

/**
 * Compares two CLOB collections.
 *
 * @param p_str1_tab              The first CLOB collection.
 * @param p_str2_tab              The second CLOB collection.
 * @param p_first_line_not_equal  The first line not equal (null when there are no differences).
 * @param p_first_char_not_equal  The first character position that differs for line p_first_line_not_equal.
 *                                NULL when no differences or one collection is a sub set of the other (but not equal).
 *                                Not NULL if there is a row R and character position C for which:
 *
 *                                dbms_lob.substr(lob_loc => p_str1_tab(R), offset => C, amount => 1) !=
 *                                dbms_lob.substr(lob_loc => p_str2_tab(R), offset => C, amount => 1)
 *
 * @throws ORA-06531  Reference to uninitialized collection
 */
procedure compare
( p_str1_tab in t_clob_tab
, p_str2_tab in t_clob_tab
, p_first_line_not_equal out binary_integer
, p_first_char_not_equal out binary_integer
);

/**
 * Append a buffer to a CLOB using dbms_lob.writeappend().
 *
 * @param pi_buffer     The buffer.
 * @param pio_clob      The CLOB.
 */
procedure append_text
( pi_buffer in varchar2
, pio_clob in out nocopy clob
);

/**
 * Append a text to a buffer and flush the buffer to a CLOB when full.
 *
 * <p>
 * See also http://www.talkapex.com/2009/06/how-to-quickly-append-varchar2-to-clob.html
 * </p>
 *
 * @param pi_text       The text to write to the buffer.
 * @param pio_buffer    The buffer that, when full, is flushed to the CLOB.
 * @param pio_clob      The CLOB.
 */
procedure append_text
( pi_text in varchar2
, pio_buffer in out nocopy varchar2
, pio_clob in out nocopy clob
);

/**
 * Write or append a text collection to a CLOB.
 *
 * @param pi_text_tab   The text collection.
 * @param pio_clob      The CLOB. If null a temporary is created.
 * @param pi_append     Should we append or not? If not the CLOB will be trimmed to zero bytes.
 */
procedure text2clob
( pi_text_tab in oracle_tools.t_text_tab
, pio_clob in out nocopy clob
, pi_append in boolean := false
);

function text2clob
( pi_text_tab in oracle_tools.t_text_tab
)
return clob;

/**
 * Write or append a text collection to a CLOB.
 *
 * @param pi_clob     The CLOB. If null a temporary is created.
 * @param pi_trim     Trim at both ends.
 *
 * @return The text collection
 */
function clob2text
( pi_clob in clob
, pi_trim in naturaln default 0
)
return oracle_tools.t_text_tab;

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
procedure ut_trim2;

--%test
procedure ut_compare1;

--%test
procedure ut_compare2;

--%test
procedure ut_append_text1;

--%test
procedure ut_append_text2;

--%test
procedure ut_text2clob1;

--%test
procedure ut_text2clob2;

--%test
procedure ut_clob2text;

$end -- $if oracle_tools.cfg_pkg.c_testing $then

END pkg_str_util;
/

