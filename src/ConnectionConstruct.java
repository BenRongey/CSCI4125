
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.*;

public class ConnectionConstruct {

    final String connectionProtocol;
    final String dbLocation;

    public ConnectionConstruct(String connectionProtocol, String host, String port, String sID) {

        this.dbLocation = "@" +host + ":" + port + ":" + sID;
        this.connectionProtocol = connectionProtocol;
    }

    public Connection initializeDBConnect(String oracleUser, String oraclePass) throws SQLException {
        DriverManager.registerDriver(new oracle.jdbc.driver.OracleDriver());
        String url = connectionProtocol + ":" + dbLocation;
        System.out.println("DB Connection URL = " +url);
        Connection connect = DriverManager.getConnection(url, oracleUser, oraclePass);
        return connect;
    }
}
