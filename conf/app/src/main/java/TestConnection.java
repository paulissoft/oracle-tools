import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Properties;
import java.util.Scanner;


import oracle.jdbc.pool.OracleDataSource;
import oracle.jdbc.OracleConnection;
import java.sql.DatabaseMetaData;

public class TestConnection {
    private static final Scanner input = new Scanner(System.in);
    
    private static String dbUrl;
    
    private static String dbUsername;
    
    private static String dbPassword;

    private static String dbProxyClientName = null;

    private static OracleConnection connection;
        
    private static void error(final String msg) {
        System.err.println("ERROR: " + msg);
    }
    
    private static void info(final String msg) {
        System.out.println(msg);
    }
    
    private static void showMenuOption(final Integer nr, final String description) {
        info(nr + " - " + description);
    }

    private static String question(final String description) {
        info("");
        info(description + ": ");
        
        return input.nextLine();
    }

    private static void showConnectionInfo() throws SQLException {
        info("");
        connection.getProperties().list(System.out);

        // Get the JDBC driver name and version 
        final DatabaseMetaData dbmd = connection.getMetaData();
        
        info("Driver Name: " + dbmd.getDriverName());
        info("Driver Version: " + dbmd.getDriverVersion());

        // Print some connection properties
        info("Default Row Prefetch Value is: " + connection.getDefaultRowPrefetch());
        info("Database Username is: " + connection.getUserName());
        info("");
    }

    private static void connect() throws SQLException {
        info("Db Url: " + dbUrl);
        info("Db Username: " + dbUsername);
        info("Db Password: " + (dbPassword != null ? "***" : "null"));

        final Properties properties = new Properties();
        
        properties.put(OracleConnection.CONNECTION_PROPERTY_USER_NAME, dbUsername);
        properties.put(OracleConnection.CONNECTION_PROPERTY_PASSWORD, dbPassword);          
        properties.put(OracleConnection.CONNECTION_PROPERTY_DEFAULT_ROW_PREFETCH, "20");
        if (!(dbProxyClientName == null || dbProxyClientName.equals(""))) {
            info("Db Proxy Client Name: " + dbProxyClientName);
            properties.put(OracleConnection.CONNECTION_PROPERTY_PROXY_CLIENT_NAME, dbProxyClientName);
        }

        final OracleDataSource ods = new OracleDataSource();
        
        ods.setURL(dbUrl);
        ods.setConnectionProperties(properties);

        connection = (OracleConnection) ods.getConnection();
    }

    private static void openProxySession() throws SQLException {
        final Properties proxyProperties = new Properties();

        final String schema = question("schema to proxy to");
            
        proxyProperties.setProperty(OracleConnection.PROXY_USER_NAME, schema);
        proxyProperties.setProperty(OracleConnection.CONNECTION_PROPERTY_PROXY_CLIENT_NAME, schema);

        connection.openProxySession(OracleConnection.PROXYTYPE_USER_NAME, proxyProperties);
    }

    private static void closeProxySession() throws SQLException {
        connection.close(OracleConnection.PROXY_SESSION);
    }

    private static void disconnect() throws SQLException {
        connection.close();
    }
    
    private static void menu() {
        while (true) {
            try {
                info("=== menu ===");
                showMenuOption(0, "Quit");
                showMenuOption(1, "Connect");
                showMenuOption(2, "Show connection info");
                showMenuOption(3, "Show user objects");
                showMenuOption(4, "Open proxy session");
                showMenuOption(5, "Close proxy session");
                showMenuOption(6, "Disconnect");

                switch (Integer.parseInt(question("your choice"))) {
                case 0:
                    return;
                
                case 1:
                    dbUrl = question("database url (jdbc:oracle:thin:@...)");
                    dbUsername = question("username");
                    dbPassword = question("password");
                    dbProxyClientName = question("proxy client name");
                    connect();
                    break;

                case 2:
                    showConnectionInfo();
                    break;
                    
                case 3:
                    printUserObjects(connection);
                    break;
                    
                case 4:
                    openProxySession();
                    break;

                case 5:
                    closeProxySession();
                    break;
                
                case 6:
                    disconnect();
                    break; 
                }
            } catch (Exception e) {
                error(e.getMessage());
            }
        }
    }
    
    /*
     * The method gets a database connection using 
     * oracle.jdbc.pool.OracleDataSource. It also sets some connection 
     * level properties, such as
     * OracleConnection.CONNECTION_PROPERTY_DEFAULT_ROW_PREFETCH.
     * There are many other connection related properties. Refer to 
     * the OracleConnection interface to find more. 
     */
    public static void main(String args[]) throws SQLException, Exception {
        if (args.length == 0) {
            menu();
            
            return;
        }
        
        final int args_size = 3;
        
        if (args.length == 1) {
            args = args[0].split("\\s+");
        }
        
        if (args.length != args_size) {
            throw new Exception("Usage: TestConnection <JDBC DB url> <username> <password>");
        }

        dbUrl = args[0];
        dbUsername = args[1];
        dbPassword = args[2];

        connect();

        showConnectionInfo();
        
        // Perform a database operation 
        printUserObjects(connection);
        
        disconnect();
    }
    /*
     * Displays object name and object type from user objects.
     */
    public static void printUserObjects(Connection connection) throws SQLException {
        // Statement and ResultSet are AutoCloseable and closed automatically. 
        try (Statement statement = connection.createStatement()) {
            final String query = "select cast(object_name as varchar2(30 char)), cast(object_type as varchar2(30 char)) from user_objects order by 2, 1";
            
            try (ResultSet resultSet = statement.executeQuery(query)) {
                info("OBJECT_TYPE                     OBJECT_NAME");
                info("-----------                     -----------");
                while (resultSet.next())
                    info(String.format("%-30s  %s", resultSet.getString(2), resultSet.getString(1)));
            }
        }   
    } 
}
