CREATE OR REPLACE PACKAGE "ORACLE_TOOLS"."PKG_STR_UTIL" IS
/**
 * <h1>Functionaliteit</h1>
 * <p>
 * String utilities.
 * </p>
 * <h2>NOTE 1</h2>
 * <p>
 * De documentatie is in PLDoc formaat
 * (<a href="http://www.sourceforge.net/projects/pldoc">http://www.sourceforge.net/projects/pldoc</a>).
 * </p>
 * @headcom
 *
 */

c_revision_label constant varchar2(100 char) := '$Revision:: 1.15	  $';

type t_clob_tab is table of clob;

/**
 * Splitst een string gescheiden door een karakterreeks in meerdere delen.
 *
 * @param p_str        De te splitsen string.
 * @param p_delimiter  De scheiding tussen delen.
 * @param p_str_tab    De afzonderlijke delen.
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
 * Verwijdert rechts aan het begin en links aan het einde van de string alle karakters die in de set zitten.
 *
 * @param p_str  De string. Als de string alleen maar uit karakters van set bestaat, wordt die leeg (null).
 * @param p_set  De set van karakters die niet meer aan begin of einde mogen.
 */
procedure trim
( p_str in out nocopy clob
, p_set in varchar2 := ' '
);

/**
 * Verwijdert voor elk element rechts aan het begin en links aan het einde alle karakters die in de set zitten.
 * Hierna worden alle null elementen vanaf het einde verwijderd.
 *
 * @param p_str_tab  Een collectie van strings.
 * @param p_set      De set van karakters die niet meer aan begin of einde mogen.
 */
procedure trim
( p_str_tab in out nocopy t_clob_tab
, p_set in varchar2 := ' '
);

/**
 * Vergelijkt twee CLOB collecties en retourneert 0 indien ze gelijk zijn qua aantal elementen en ook per element.
 *
 * @param p_str1_tab  De eerste CLOB collectie.
 * @param p_str2_tab  De eerste CLOB collectie.
 *
 * @return -1 indien p_str1_tab.count < p_str2_tab.count of
 *	      indien p_str1_tab.count = p_str2_tab.count en er is een rij R met
 *	      dbms_lob.compare(p_str1_tab(R), p_str2_tab(R)) < 0 en
 *	      voor alle rijen < R geldt dbms_lob.compare(p_str1_tab(R), p_str2_tab(R)) = 0
 *	    0 p_str1_tab.count = p_str2_tab.count en
 *	      voor alle rijen R geldt dbms_lob.compare(p_str1_tab(R), p_str2_tab(R)) = 0
 *	    1 indien p_str1_tab.count > p_str2_tab.count of
 *	      indien p_str1_tab.count = p_str2_tab.count en er is een rij R met
 *	      dbms_lob.compare(p_str1_tab(R), p_str2_tab(R)) > 0 en
 *	      voor alle rijen < R geldt dbms_lob.compare(p_str1_tab(R), p_str2_tab(R)) = 0

 * @throws ORA-06531  Reference to uninitialized collection
 */
function compare
( p_str1_tab in t_clob_tab
, p_str2_tab in t_clob_tab
)
return integer;

/**
 * Vergelijkt twee CLOB collecties.
 *
 * @param p_str1_tab		  De eerste CLOB collectie.
 * @param p_str2_tab		  De eerste CLOB collectie.
 * @param p_first_line_not_equal  De eerste regel die niet gelijk is.
 *				  NULL indien er geen verschillen zijn.
 * @param p_first_char_not_equal  De eerste karakterpositie die niet gelijk is in de eerste regel die niet gelijk is.
 *				  NULL indien er geen verschillen zijn of als de ene collectie groter is dan de andere
 *				  en de kleinere collectie een subset is van de andere (d.w.z. alle regels gelijk).
 *				  Niet NULL als er een regelnummer R is die in beide collecties zit en waarvoor er een
 *				  karakter C zit is waarvoor geldt dat:
 *				  dbms_lob.substr(lob_loc => p_str1_tab(R), offset => C, amount => 1) !=
 *				  dbms_lob.substr(lob_loc => p_str2_tab(R), offset => C, amount => 1)
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
 * @param pi_buffer		  The buffer.
 * @param pio_clob		  The CLOB.
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
 * @param pi_text 		  The text to write to the buffer.
 * @param pio_buffer		  The buffer that, when full, is flushed to the CLOB.
 * @param pio_clob		  The CLOB.
 */
procedure append_text
( pi_text in varchar2
, pio_buffer in out nocopy varchar2
, pio_clob in out nocopy clob
);

/**
 * Write or append a text collection to a CLOB.
 *
 * @param pi_text_tab 		  The text collection.
 * @param pio_clob		  The CLOB. If null a temporary is created.
 * @param pi_append               Should we append or not? If not the CLOB will be trimmed to zero bytes.
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
 * @param pi_clob		  The CLOB. If null a temporary is created.
 * @param pi_trim                 Trim at both ends.
 *
 * @return The text collection
 */
function clob2text
( pi_clob in clob
, pi_trim in naturaln default 0
)
return oracle_tools.t_text_tab;

END PKG_STR_UTIL;
/

