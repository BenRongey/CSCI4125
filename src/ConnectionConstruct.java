import java.sql.*;

class ConnectionConstruct {

    private final String connectionProtocol;
    private final String dbLocation;

    protected ConnectionConstruct(String connectionProtocol, String host, String port, String sID) {

        this.dbLocation = "@" +host + ":" + port + ":" + sID;
        this.connectionProtocol = connectionProtocol;
    }

     Connection initializeDBConnect() throws SQLException {
        DriverManager.registerDriver(new oracle.jdbc.driver.OracleDriver());
        String url = connectionProtocol + ":" + dbLocation;
        System.out.println("DB Connection URL = " +url);
         return DriverManager.getConnection(url, "brongey", "zW4qhxXH");
    }
}
