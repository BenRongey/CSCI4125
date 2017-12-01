import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;

public class Main {


    private static Connection connect;
    static List<PreparedStatement> queries;

    public static void main(String[] args) {

        ConnectionConstruct build;
        build = new ConnectionConstruct("jdbc:oracle:thin", "dbsvcs.cs.uno.edu", "1521", "orcl");

        try {

            connect = build.initializeDBConnect("brongey", "zW4qhxXH");
            queries = parseSQLFile("src/DBQueries.sql");

            int selection = 0;

            while (-1 != selection) {
                System.out.println("Welcome to kickass DB!");

                System.out.println("1. Add an employee");
                System.out.println("2. Run Query");

                Scanner input = new Scanner(System.in);
                selection = input.nextInt();

                if (selection == 1) {
                    newEmployee();
                } else if (selection == 2) {

                    System.out.println("Enter query number (1-28):");
                    ResultSet result = evaluateQuery(input.nextInt());
                    printSQLResults(result);
                    System.out.println();
                    System.out.println();
                } else {
                    System.out.println("Invalid command.  Press -1 to exit");
                }
            }

        } catch(SQLException e) {
            System.err.println(e);
        } catch (FileNotFoundException e) {
            System.out.println("File not fount");
        }
    }

    public static List<PreparedStatement> parseSQLFile(String path)
            throws FileNotFoundException, SQLException
    {
        File inputFile = new File(path);
        BufferedInputStream stream = new BufferedInputStream(new FileInputStream(inputFile.getAbsoluteFile()));

        List<PreparedStatement> queries = new ArrayList<>();
        Scanner fileScan = new Scanner(stream);

        String line = fileScan.nextLine();
        while (fileScan.hasNextLine()) {
            if (line.startsWith("/*")) {
                while (!line.endsWith("*/")) {
                    line = fileScan.nextLine();
                }
            }

            String query = "";
            while (fileScan.hasNextLine()) {
                line = fileScan.nextLine();
                if (line.startsWith("/*")) {
                    break;
                }

                query += line + System.getProperty("line.separator");
            }

            queries.add(connect.prepareStatement(query));

        }

        return queries;
    }

    public static void newEmployee() throws SQLException {

        Scanner input = new Scanner(System.in);
        PreparedStatement statement;

        System.out.println("Enter person ID");
        int per_id = input.nextInt();
        System.out.println("Enter Company ID");
        int comp_id = input.nextInt();

        String printAvailableJobs = ""
                + "SELECT JOB_CODE "
                + "FROM JOB WHERE PER_ID IS NULL AND COMP_ID = ?";

        statement = connect.prepareStatement(printAvailableJobs);
        statement.setInt(1, comp_id);
        ResultSet result = statement.executeQuery();

        if (result.isBeforeFirst() == false) {
            System.out.println("This company has no jobs available");
            return;
        } else {
            System.out.println("Jobs available at this company:");
            printSQLResults(result);

            System.out.println("Enter job code");
            int job_code = input.nextInt();

            String temporary = "Insert into work_history Values (?, ?)";
            statement = connect.prepareStatement(temporary);
            statement.setInt(1, per_id);
            statement.setInt(2, job_code);

            System.out.println("Enter the courses the new employee has taken");
            int c_code;

            System.out.println("Enter the course id");
            c_code = input.nextInt();

            temporary = "INSERT INTO TAKES VALUES (?, ?) ";
            statement = connect.prepareStatement(temporary);
            statement.setInt(1, per_id);
            statement.setInt(2, c_code);
            statement.executeUpdate();

            temporary = "WITH Missing_Skills (KS_CODE) AS ( "
                + "SELECT KS_CODE "
                + "FROM REQUIRED_SKILL "
                + "WHERE JOB_CODE = ? "
                + "MINUS "
                + "SELECT KS_CODE "
                + "FROM HAS_SKILL "
                + "WHERE PER_ID = ?) "

                + "SELECT C_CODE, C_TITLE "
                + "FROM COURSE, Missing_Skills "
                + "WHERE NOT EXISTS( "
                + "SELECT KS_CODE "
                + "FROM Missing_Skills "
                + "MINUS "
                + "SELECT KS_CODE "
                + "FROM COURSE_KS "
                + "WHERE COURSE.C_CODE = COURSE_KS.C_CODE)";

            statement = connect.prepareStatement(temporary);
            statement.setInt(1, job_code);
            statement.setInt(2, per_id);

            result = statement.executeQuery();

            if (result.isBeforeFirst() == false) {
                System.out.println("This employee meets the job requirements");
            } else {
                System.out.println("The employee is missing essential skills for the job");
                printSQLResults(result);
            }
        }
    }

    public static ResultSet evaluateQuery(int query) throws SQLException {
        Scanner input = new Scanner(System.in);
        ResultSet result = null;

        switch (query) {
            case 1:
                System.out.println("Query 1");
                System.out.println("Enter company ID");
                queries.get(0).setInt(1, input.nextInt());
                result = queries.get(0).executeQuery();
                break;

            case 2:
                System.out.println("Query 2");
                System.out.println("Enter company name");
                queries.get(1).setString(1, input.next());
                result = queries.get(1).executeQuery();
                break;

            case 3:
                System.out.println("Query 3");
                result = queries.get(2).executeQuery();
                break;

            case 4:
                System.out.println("Query 4");
                System.out.println("Enter person id");
                queries.get(3).setInt(1, input.nextInt());
                result = queries.get(3).executeQuery();
                break;

            case 5:
                System.out.println("Query 5");
                System.out.println("Enter person id");
                queries.get(4).setInt(1, input.nextInt());
                result = queries.get(4).executeQuery();
                break;

            case 6:
                System.out.println("Query 6");
                System.out.println("Enter person id");
                queries.get(5).setInt(1, input.nextInt());
                System.out.println("Enter person id");
                queries.get(5).setInt(2, input.nextInt());
                result = queries.get(5).executeQuery();
                break;

            case 7:
                System.out.println("Query 7A");
                System.out.println("Enter job code");
                queries.get(6).setInt(1, input.nextInt());
                result = queries.get(6).executeQuery();
                break;

            case 8:
                System.out.println("Query 7B");
                System.out.println("Enter category code");
                queries.get(7).setInt(1, input.nextInt());
                result = queries.get(7).executeQuery();
                break;

            case 9:
                System.out.println("Query 8");
                System.out.println("Enter job code");
                queries.get(8).setInt(1, input.nextInt());
                System.out.println("Enter person id");
                queries.get(8).setInt(2, input.nextInt());
                result = queries.get(8).executeQuery();
                break;

            case 10:
                System.out.println("Query 9");
                System.out.println("Enter job code");
                queries.get(9).setInt(1, input.nextInt());
                System.out.println("Enter person id");
                queries.get(9).setInt(2, input.nextInt());
                result = queries.get(9).executeQuery();
                break;

            case 11:
                System.out.println("Query 10");
                System.out.println("Enter job code");
                queries.get(10).setInt(1, input.nextInt());
                System.out.println("Enter person id");
                queries.get(10).setInt(2, input.nextInt());
                result = queries.get(10).executeQuery();
                break;

            case 12:
                System.out.println("Query 11");
                System.out.println("Enter job code");
                queries.get(11).setInt(1, input.nextInt());
                System.out.println("Enter person id");
                queries.get(11).setInt(2, input.nextInt());
                result = queries.get(11).executeQuery();
                break;

            case 13:
                System.out.println("Query 12");
                System.out.println("Enter person id");
                queries.get(12).setInt(1, input.nextInt());
                result = queries.get(12).executeQuery();
                break;
            //TODO this sql query doesn't appear to be correct, take a look at it again

            case 14:
                System.out.println("Query 13");
                System.out.println("Enter person id");
                queries.get(13).setInt(1, input.nextInt());
                result = queries.get(13).executeQuery();
                break;

            case 15:
                System.out.println("Query 14");
                System.out.println("Enter person id");
                queries.get(14).setInt(1, input.nextInt());
                result = queries.get(14).executeQuery();
                break;

            case 16:
                System.out.println("Query 15");
                System.out.println("Enter job code");
                queries.get(15).setInt(1, input.nextInt());
                result = queries.get(15).executeQuery();
                break;

            case 17:
                System.out.println("Query 16");
                System.out.println("Enter job code");
                queries.get(16).setInt(1, input.nextInt());
                result = queries.get(16).executeQuery();
                break;
            //TODO missing sql (missing k crap)

            case 18:
                System.out.println("Query 17");
                System.out.println("Enter job code");
                queries.get(17).setInt(1, input.nextInt());
                result = queries.get(17).executeQuery();
                break;
            //TODO missing sql (missing k crap)

            case 19:
                System.out.println("Query 18");
                System.out.println("Enter job code");
                queries.get(18).setInt(1, input.nextInt());
                result = queries.get(18).executeQuery();
                break;
            //TODO missing sql (missing k crap)

            case 20:
                System.out.println("Query 19");
                System.out.println("Enter job code");
                queries.get(19).setInt(1, input.nextInt());
                result = queries.get(19).executeQuery();
                break;
            //TODO missing sql (missing k crap)

            case 21:
                System.out.println("Query 20");
                System.out.println("Enter job code");
                queries.get(20).setInt(1, input.nextInt());
                result = queries.get(20).executeQuery();
                break;
            //TODO missing sql (missing k crap)

            case 22:
                System.out.println("Query 21");
                System.out.println("Enter category code");
                queries.get(21).setInt(1, input.nextInt());
                result = queries.get(21).executeQuery();
                break;

            case 23:
                System.out.println("Query 22");
                System.out.println("Enter job code");
                queries.get(22).setInt(1, input.nextInt());
                result = queries.get(22).executeQuery();
                break;

            case 24:
                System.out.println("Query 23A");
                result = queries.get(23).executeQuery();
                break;

            case 25:
                System.out.println("Query 23B");
                result = queries.get(24).executeQuery();
                break;

            case 26:
                System.out.println("Query 24A");
                result = queries.get(25).executeQuery();
                break;

            case 27:
                System.out.println("Query 24B");
                result = queries.get(26).executeQuery();
                break;
            //TODO missing sql query
        }

        return result;
    }



        public static void printSQLResults (ResultSet result)
        throws SQLException {

            ResultSetMetaData metaData = result.getMetaData();
            int columnCount= metaData.getColumnCount();

            while (result.next()) {
                for (int i = 1; i <= columnCount; i++) {
                    if (i > 1) System.out.print(", ");
                        String columnValue = result.getString(i);
                        System.out.print(columnValue + " " + metaData.getColumnName(i));
                    }
                System.out.println();
                }

        }
}
