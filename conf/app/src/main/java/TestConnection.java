import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Properties;

import oracle.jdbc.pool.OracleDataSource;
import oracle.jdbc.OracleConnection;
import java.sql.DatabaseMetaData;

public class TestConnection {  
    /*
     * The method gets a database connection using 
     * oracle.jdbc.pool.OracleDataSource. It also sets some connection 
     * level properties, such as,
     * OracleConnection.CONNECTION_PROPERTY_DEFAULT_ROW_PREFETCH,
     * OracleConnection.CONNECTION_PROPERTY_THIN_NET_CHECKSUM_TYPES, etc.,
     * There are many other connection related properties. Refer to 
     * the OracleConnection interface to find more. 
     */
    public static void main(String args[]) throws SQLException, Exception {
        final int args_size = 3;
        
        if (args.length == 1) {
            args = args[0].split("\\s+");
        }
        
        if (args.length != args_size) {
            throw new Exception("Usage: TestConnection <JDBC DB url> <username> <password>");
        }

        final String dbUrl = args[0];
        final String dbUsername = args[1];
        final String dbPassword = args[2];
        
        System.out.println("Db Url: " + dbUrl);
        System.out.println("Db Username: " + dbUsername);
        System.out.println("Db Password: " + (dbPassword != null ? "***" : "null"));

        Properties info = new Properties();     
        info.put(OracleConnection.CONNECTION_PROPERTY_USER_NAME, dbUsername);
        info.put(OracleConnection.CONNECTION_PROPERTY_PASSWORD, dbPassword);          
        info.put(OracleConnection.CONNECTION_PROPERTY_DEFAULT_ROW_PREFETCH, "20");    

        OracleDataSource ods = new OracleDataSource();
        ods.setURL(dbUrl);    
        ods.setConnectionProperties(info);

        // With AutoCloseable, the connection is closed automatically.
        try (OracleConnection connection = (OracleConnection) ods.getConnection()) {
            // Get the JDBC driver name and version 
            DatabaseMetaData dbmd = connection.getMetaData();       
            System.out.println("Driver Name: " + dbmd.getDriverName());
            System.out.println("Driver Version: " + dbmd.getDriverVersion());
            // Print some connection properties
            System.out.println("Default Row Prefetch Value is: " + 
                               connection.getDefaultRowPrefetch());
            System.out.println("Database Username is: " + connection.getUserName());
            System.out.println();
            // Perform a database operation 
            printUserObjects(connection);
        }   
    }
    /*
     * Displays object name and object type from user objects.
     */
    public static void printUserObjects(Connection connection) throws SQLException {
        // Statement and ResultSet are AutoCloseable and closed automatically. 
        try (Statement statement = connection.createStatement()) {
            final String query = "select cast(object_name as varchar2(30 char)), cast(object_type as varchar2(30 char)) from user_objects order by 2, 1";
            
            try (ResultSet resultSet = statement.executeQuery(query)) {
                System.out.println("OBJECT_TYPE                     OBJECT_NAME");
                System.out.println("-----------                     -----------");
                while (resultSet.next())
                    System.out.println(String.format("%-30s  %s", resultSet.getString(2), resultSet.getString(1)));
            }
        }   
    } 
}
