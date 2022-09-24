import java.sql.*;
import java.io.IOException;
import java.io.PrintStream;

import java.util.Map;

public class GenerateDDL
{
    // args[0]: JDBC url
    // args[1]: source schema
    // args[2]: source database link
    // args[3]: target schema
    // args[4]: target database link
    // args[5]: object type
    // args[6]: object names include (0, 1 or empty)
    // args[7]: object names (comma separated list)
    // args[8]: skip repeatables (0 or 1)
    // args[9]: interface
    // args[10]: a list of DBMS_METADATA transformation parameters
    // args[11]: owner of pkg_ddl_util package (MUST BE THE LAST PARAMETER)
    public static void main(String[] args) throws SQLException, IOException, Exception
    {
        final int args_size = 12;
        int nr;
        final PrintStream out = new PrintStream(System.out, true, "UTF-8");
        Connection conn = null;

        try {
            if (args.length == 1) {
                args = args[0].split("\\s+");
            }

            if (args.length != args_size) {
                throw new Exception("Usage: GenerateDDL <JDBC url> " +
                                                       "<source schema> <source database link> " +
                                                       "<target schema> <target database link> " +
                                                       "<object type> <object names include> <object names> " +
                                                       "<skip repeatables> <interface> <transform params> <owner>");
            }

            final Map<String, String> env = System.getenv();

            if (!env.get("NLS_LANG").endsWith(".UTF8")) {
                throw new Exception("NLS_LANG environment variable must end with .UTF8");
            }

            // Print the arguments as one multi line comment and every line as a comment too.
            out.println("/*");

            String owner = "";
      
            for (nr = 0; nr < args.length; nr++) {
                // strip " and ' at the beginning and end
                args[nr] = args[nr].replaceAll("^\"|^'|'$|\"$", "");

                out.print("-- ");

                switch (nr) {
                case 0:
                    // JDBC url, includes password (jdbc:oracle:thin:<user>/<password>@<db>) so strip it
                    StringBuffer JDBCUrl = new StringBuffer(args[0]);
                    String str1 = JDBCUrl.substring(0, JDBCUrl.indexOf("/"));
                    String str2 = JDBCUrl.substring(JDBCUrl.lastIndexOf("@"));

                    out.println("JDBC url            : " + str1 + str2);
                    break;
    
                case 1:
                    // source schema
                    out.println("source schema       : " + args[nr]);
                    break;
    
                case 2:
                    // source database link
                    out.println("source database link: " + args[nr]);
                    break;
    
                case 3:
                    // target schema
                    out.println("target schema       : " + args[nr]);
                    break;
        
                case 4:
                    // target database link
                    out.println("target database link: " + args[nr]);
                    break;

                case 5:
                    // object type
                    out.println("object type         : " + args[nr]);
                    break;
    
                case 6:
                    // object names include
                    out.println("object names include: " + args[nr]);
                    break;
    
                case 7:
                    // object names
                    out.println("object names        : " + args[nr]);
                    break;
    
                case 8:
                    // skip repeatables
                    out.println("skip repeatables    : " + args[nr]);
                    break;

                case 9:
                    // interface
                    out.println("interface           : " + args[nr]);
                    break;

                case 10:
                    // interface
                    out.println("transform params    : " + args[nr]);
                    break;
                    
                case 11:
                    owner = args[nr];
                    // owner
                    out.println("owner               : " + args[nr]);
                    break;
                }
            }

            out.println("*/");
  
            //Load and register Oracle driver
            System.setProperty("oracle.jdbc.fanEnabled", "false");
            DriverManager.registerDriver(new oracle.jdbc.driver.OracleDriver());
            //Establish a connection

            nr = -1;

            conn = DriverManager.getConnection(args[++nr]);

            final Statement stmt = conn.createStatement();

            // try to set up a common environment to get the local radix character X in 'DD-MON-RRRR HH.MI.SSXFF AM TZR' is the same everywhere
            stmt.executeUpdate("alter session set NLS_LANGUAGE = 'AMERICAN'");
            stmt.executeUpdate("alter session set NLS_TERRITORY = 'AMERICA'");

            final CallableStatement pstmt = conn.prepareCall("{call " + owner + (owner.equals("") ? "" : ".") + "p_generate_ddl(?,?,?,?,?,?,?,?,?,?,?)}");
      
            pstmt.setString(1, args[++nr]);
            pstmt.setString(2, args[++nr]);
            pstmt.setString(3, args[++nr]);
            pstmt.setString(4, args[++nr]);
            pstmt.setString(5, args[++nr]);
            // argument 6 can be empty so setNull must be called explicitly because empty string can not be converted to a null integer
            try {
                pstmt.setInt(6, Integer.parseInt(args[++nr]));
            } catch(Exception e) {
                if (args[nr] != null && args[nr].toString().trim().length() > 0) {
                    throw new Exception("Can not convert '" + args[nr]  + "' to an integer");
                } else {
                    pstmt.setNull(6, Types.INTEGER);
                }
            }
            pstmt.setString(7, args[++nr]);
            pstmt.setInt(8, Integer.parseInt(args[++nr])); // never null
            pstmt.setString(9, args[++nr]);
            pstmt.setString(10, args[++nr]);
            pstmt.registerOutParameter(args_size - 1, Types.CLOB);
            pstmt.executeUpdate();

            final Clob clob = pstmt.getClob(args_size - 1);

            // Print all at once
            final long len = clob.length();

            if (len < Integer.MIN_VALUE || len > Integer.MAX_VALUE) {
                throw new Exception(String.format("CLOB length %d is not between %d and %d", len, Integer.MIN_VALUE, Integer.MAX_VALUE));
            } else {
                out.print(clob.getSubString(1, (int) len));
            }

            pstmt.close();
        } catch (Exception e) {
            System.err.println("Number of arguments expected: " + args_size + "; actual: " + args.length);
      
            for (nr = 0; nr < args.length; nr++)
                System.err.println("Argument " + nr + ": " + args[nr]);  

            throw e;
        } finally {
            if (conn != null) {
                conn.close();
            }
            out.close();
        }
    }
}
