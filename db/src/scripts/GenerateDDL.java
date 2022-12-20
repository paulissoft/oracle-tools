import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintStream;

import java.sql.*;

import java.util.Map;
import java.util.Properties;


public class GenerateDDL
{
    public static void main(String[] args) throws SQLException, IOException, Exception
    {
        final int args_size = 1;
        final int props_size = 13;
        final int vars_size = props_size + 1; /* JDBC URL passed as environment variable */
        int nr;
        final PrintStream out = new PrintStream(System.out, true, "UTF-8");
        Connection conn = null;
        CallableStatement pstmt = null;
    
        try {
            if (args.length != args_size) {
                throw new Exception("Usage: GenerateDDL <property file>");
            }

            // strip " and ' at the beginning and end
            args[0] = args[0].replaceAll("^\"|^'|'$|\"$", "");

            try (InputStream input = new FileInputStream(args[0])) {
                final Properties props = new Properties();

                // load the properties file
                props.load(input);
            
                final Map<String, String> env = System.getenv();

                if (!env.get("NLS_LANG").endsWith(".UTF8")) {
                    throw new Exception("NLS_LANG environment variable must end with .UTF8");
                }

                final StringBuffer JDBCUrl = new StringBuffer(env.get("JDBC_URL"));
                final String sourceSchema = props.getProperty("source.schema");
                final String sourceDbLink = props.getProperty("source.db.name");
                final String targetSchema = props.getProperty("target.schema");
                final String targetDbLink = props.getProperty("target.db.name");
                final String objectType = props.getProperty("object.type");
                final String objectNamesInclude = props.getProperty("object.names.include");
                final String objectNames = props.getProperty("object.names");
                final String skipRepeatables = props.getProperty("skip.repeatables");
                final String interfaceName = props.getProperty("interface");
                final String transformParams = props.getProperty("transform.params");
                final String objectsInclude = props.getProperty("objects.include");
                final String objects = props.getProperty("objects");
                final String owner = props.getProperty("owner");

                assert JDBCUrl != null && !JDBCUrl.toString().equals("");
                assert sourceSchema != null && !sourceSchema.equals("");
                assert sourceDbLink != null;
                assert targetSchema != null;
                assert targetDbLink != null;
                assert objectType != null;
                assert objectNamesInclude != null;
                assert objectNames != null;
                assert skipRepeatables != null && !skipRepeatables.equals("");
                assert interfaceName != null && !interfaceName.equals("");
                assert transformParams != null;
                assert objectsInclude != null;
                assert objects != null;
                assert owner != null;

                // Load and register Oracle driver
                System.setProperty("oracle.jdbc.fanEnabled", "false");
                DriverManager.registerDriver(new oracle.jdbc.driver.OracleDriver());
                // Establish a connection

                conn = DriverManager.getConnection(JDBCUrl.toString());

                final Statement stmt = conn.createStatement();

                // GJP 2022-09-28
                // DDL generation changes due to timestamp format for dbms_scheduler jobs should be ignored.
                // https://github.com/paulissoft/oracle-tools/issues/59
            
                // Try to set up a common environment to ensure that the local radix character X in 'DD-MON-RRRR HH.MI.SSXFF AM TZR' is the same everywhere.
            
                stmt.executeUpdate("alter session set NLS_LANGUAGE = 'AMERICAN'");
                stmt.executeUpdate("alter session set NLS_TERRITORY = 'AMERICA'");

                pstmt = conn.prepareCall("{call " + owner + (owner.equals("") ? "" : ".") + "p_generate_ddl(?,?,?,?,?,?,?,?,?,?,?,?,?)}");

                final Clob objectsClob = conn.createClob();

                // Print the arguments as one multi line comment and every line as a comment too.
                out.println("/*");
      
                for (nr = -1; nr < vars_size; nr++) {

                    out.print("-- ");

                    /* -1 and 0 are not statement parameters (?) but owner can be part of the statement */
                    switch (nr) {
                    case -1:
                        // JDBC url, includes password (jdbc:oracle:thin:<user>/<password>@<db>) so strip it
                        final String str1 = JDBCUrl.substring(0, JDBCUrl.indexOf("/"));
                        final String str2 = JDBCUrl.substring(JDBCUrl.lastIndexOf("@"));

                        out.println("JDBC url            : " + str1 + str2);
                        break;
    
                    case 0:
                        out.println("owner               : " + owner);
                        break;

                    case 1:
                        out.println("source schema       : " + sourceSchema);
                        pstmt.setString(nr, sourceSchema);
                        break;
    
                    case 2:
                        out.println("source database link: " + sourceDbLink);
                        pstmt.setString(nr, sourceDbLink);
                        break;
    
                    case 3:
                        out.println("target schema       : " + targetSchema);
                        pstmt.setString(nr, targetSchema);
                        break;
        
                    case 4:
                        out.println("target database link: " + targetDbLink);
                        pstmt.setString(nr, targetDbLink);
                        break;

                    case 5:
                        out.println("object type         : " + objectType);
                        pstmt.setString(nr, objectType);
                        break;
    
                    case 6:
                        out.println("object names include: " + objectNamesInclude);
                        // this argument can be empty so setNull must be called explicitly because empty string can not be converted to a null integer
                        try {
                            pstmt.setInt(nr, Integer.parseInt(objectNamesInclude));
                        } catch(Exception e) {
                            if (objectNamesInclude != null && objectNamesInclude.toString().trim().length() > 0) {
                                throw new Exception("Can not convert '" + objectNamesInclude  + "' to an integer");
                            } else {
                                pstmt.setNull(nr, Types.INTEGER);
                            }
                        }
                        break;
    
                    case 7:
                        out.println("object names        : " + objectNames);
                        pstmt.setString(nr, objectNames);
                        break;
    
                    case 8:
                        out.println("skip repeatables    : " + skipRepeatables);
                        pstmt.setInt(nr, Integer.parseInt(skipRepeatables)); // never null
                        break;

                    case 9:
                        out.println("interface           : " + interfaceName);
                        pstmt.setString(nr, interfaceName);
                        break;

                    case 10:
                        out.println("transform params    : " + transformParams);
                        pstmt.setString(nr, transformParams);
                        break;
                    
                    case 11:
                        out.println("objects include     : " + objectsInclude);
                        // this argument can be empty so setNull must be called explicitly because empty string can not be converted to a null integer
                        try {
                            pstmt.setInt(nr, Integer.parseInt(objectsInclude));
                        } catch(Exception e) {
                            if (objectsInclude != null && objectsInclude.toString().trim().length() > 0) {
                                throw new Exception("Can not convert '" + objectsInclude  + "' to an integer");
                            } else {
                                pstmt.setNull(nr, Types.INTEGER);
                            }
                        }
                        break;
    
                    case 12:
                        out.println("objects             : " + objects);
                        objectsClob.setString(1, objects);
                        pstmt.setClob(nr, objectsClob);
                        break;

                    case 13:
                        pstmt.registerOutParameter(nr, Types.CLOB);
                        pstmt.executeUpdate();
                        break;

                    default:
                        assert nr >= -1 && nr <= 13;
                    }
                }

                out.println("*/");

                // last statement parameter is the output clob
                final Clob clob = pstmt.getClob(vars_size - 1);

                // Print all at once
                final long len = clob.length();

                if (len < Integer.MIN_VALUE || len > Integer.MAX_VALUE) {
                    throw new Exception(String.format("CLOB length %d is not between %d and %d", len, Integer.MIN_VALUE, Integer.MAX_VALUE));
                } else {
                    out.print(clob.getSubString(1, (int) len));
                }
            }
        } catch (Exception e) {
            System.err.println("Number of arguments expected: " + args_size + "; actual: " + args.length);
      
            for (nr = 0; nr < args.length; nr++)
                System.err.println("Argument " + nr + ": " + args[nr]);  

            throw e;
        } finally {
            if (pstmt != null) {
                pstmt.close();
            }
            if (conn != null) {
                conn.close();
            }
            out.close();
        }
    }
}
