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

    private static Boolean isDbSingleSessionProxyModel() {
        return dbUsername.endsWith("]");
    }

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

    private static void showConnectionProperties() throws SQLException {
        info("");
        connection.getProperties().list(System.out);
    }

    private static void showConnectionInfo() throws SQLException {
        info("");

        // Get the JDBC driver name and version 
        final DatabaseMetaData dbmd = connection.getMetaData();
        
        info("Driver Name: " + dbmd.getDriverName());
        info("Driver Version: " + dbmd.getDriverVersion());

        // Print some connection properties
        info("Default Row Prefetch Value is: " + connection.getDefaultRowPrefetch());
        info("Database Username is: " + connection.getUserName());
        info("");

        // Prepare a statement to execute the SQL Queries.
        try (final Statement statement = connection.createStatement()) {
            final String newLine = System.getProperty("line.separator");
            final String[] parameters = {
                null,
                "AUTHENTICATED_IDENTITY", // 1
                "AUTHENTICATION_METHOD", // 2
                "CURRENT_SCHEMA", // 3
                "CURRENT_USER", // 4
                "PROXY_USER", // 5
                "SESSION_USER", // 6
                "SESSIONID", // 7
                "SID"  // 8
            };
            final String sessionParametersQuery = String.join(newLine,
                                                              "select  sys_context('USERENV', '" + parameters[1] + "')",
                                                              ",       sys_context('USERENV', '" + parameters[2] + "')",
                                                              ",       sys_context('USERENV', '" + parameters[3] + "')",
                                                              ",       sys_context('USERENV', '" + parameters[4] + "')",
                                                              ",       sys_context('USERENV', '" + parameters[5] + "')",
                                                              ",       sys_context('USERENV', '" + parameters[6] + "')",
                                                              ",       sys_context('USERENV', '" + parameters[7] + "')",
                                                              ",       sys_context('USERENV', '" + parameters[8] + "')",
                                                              "from    dual");
            
            try (final ResultSet resultSet = statement.executeQuery(sessionParametersQuery)) {
                while (resultSet.next()) {
                    for (int i = 1; i < parameters.length; i++) {
                        info(parameters[i] + ": " + resultSet.getString(i));
                    }
                }
            }
        }
    }

    private static void connect(final Boolean openProxySessionIfApplicable) throws SQLException {
        final Properties properties = new Properties();
        
        properties.put(OracleConnection.CONNECTION_PROPERTY_USER_NAME, dbUsername);
        properties.put(OracleConnection.CONNECTION_PROPERTY_PASSWORD, dbPassword);          
        // properties.put(OracleConnection.CONNECTION_PROPERTY_DEFAULT_ROW_PREFETCH, "20");
        /*
        if (!(dbProxyClientName == null || dbProxyClientName.equals(""))) {
            if (isDbSingleSessionProxyModel()) {
                properties.put(OracleConnection.CONNECTION_PROPERTY_PROXY_CLIENT_NAME, dbProxyClientName);
            }
        }
        */

        final OracleDataSource ods = new OracleDataSource();
        
        ods.setURL(dbUrl);
        ods.setConnectionProperties(properties);

        connection = (OracleConnection) ods.getConnection();

        if (openProxySessionIfApplicable &&
            !(dbProxyClientName == null || dbProxyClientName.equals("")) &&
            !isDbSingleSessionProxyModel()) {
            openProxySession(dbProxyClientName);
        }
    }

    private static void openProxySession(final String schema) throws SQLException {
        final Properties proxyProperties = new Properties();

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
    
    private static void benchmark() throws SQLException {
        final long[] elapsedTimes = new long[] { 0L, 0L, 0L, 0L };
        final String[] methodNames = new String[] { "connect()", "openProxySession()", "closeProxySession()", "disconnect()" };
        int method;

        final int MAX_COUNTER = Integer.parseInt(question("how many times to benchmark connect/openProxySession/closeProxySession/disconnect"));
        
        for (int counter = 1; counter <= MAX_COUNTER; counter++) {
            for (method = 0; method < elapsedTimes.length; method++) {
                final long startTime = System.currentTimeMillis();
                
                switch (method) {
                case 0:
                    connect(false);
                    break;
                    
                case 1:
                    if (dbProxyClientName == null || dbProxyClientName.equals("")) {
                        continue;
                    }
                    openProxySession(dbProxyClientName);
                    break;

                case 2:
                    if (dbProxyClientName == null || dbProxyClientName.equals("")) {
                        continue;
                    }
                    closeProxySession();
                    break;
                    
                case 3:
                    disconnect();
                    break;
                }

                final long endTime = System.currentTimeMillis();

                info(methodNames[method] + " (#" + counter + ")" + " elapsed time (ms) = " + (endTime - startTime));

                elapsedTimes[method] += endTime - startTime;
            }
        }

        info("");
        
        for (method = 0; method < elapsedTimes.length; method++) {
            if (elapsedTimes[method] > 0L) {
                info(methodNames[method] + " avg elapsed time (ms) = " + (long) (elapsedTimes[method] / MAX_COUNTER));
            }
        }
    }

    private static void menu() {
        while (true) {
            try {
                info("=== menu ===");
                showMenuOption(0, "Quit");
                showMenuOption(1, "Connect");
                showMenuOption(2, "Show connection info");
                showMenuOption(3, "Show connection properties");
                showMenuOption(4, "Show user objects");
                showMenuOption(5, "Open proxy session");
                showMenuOption(6, "Close proxy session");
                showMenuOption(7, "Benchmark");                
                showMenuOption(8, "Disconnect");

                int choice;
                    
                switch (choice = Integer.parseInt(question("your choice"))) {
                case 0:
                    return;
                
                case 1:
                case 7:
                    dbUrl = question("database DSN (after the @ in jdbc:oracle:thin:@...)");
                    if (!dbUrl.startsWith("jdbc:oracle:thin:@")) {
                        dbUrl = "jdbc:oracle:thin:@" + dbUrl;
                    }
                    dbUsername = question("username");
                    dbPassword = question("password");
                    if (isDbSingleSessionProxyModel()) {
                        dbProxyClientName = null;
                    } else {
                        dbProxyClientName = question("proxy client name");
                    }
                    if (choice == 1) {
                        connect(true);
                    } else {
                        benchmark();
                    }
                    break;

                case 2:
                    showConnectionInfo();
                    break;
                    
                case 3:
                    showConnectionProperties();
                    break;
                    
                case 4:
                    printUserObjects(connection);
                    break;
                    
                case 5:
                    openProxySession(dbProxyClientName = question("schema to proxy to"));
                    break;

                case 6:
                    closeProxySession();
                    break;
                
                case 8:
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

        connect(true);

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
