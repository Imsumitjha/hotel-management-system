package com.hotel.util;

import javax.naming.InitialContext;
import javax.naming.NameNotFoundException;
import javax.naming.NamingException;
import javax.naming.NoInitialContextException;
import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.logging.Level;
import java.util.logging.Logger;

/** Shared database connection factory. */
public final class DBConnection {
    private static final Logger LOG = Logger.getLogger(DBConnection.class.getName());
    private static final String JNDI_NAME = "java:comp/env/jdbc/HotelDB";
    private static final String DRIVER = "com.mysql.cj.jdbc.Driver";

    private static volatile DataSource jndiDataSource;
    private static volatile boolean jndiLookupComplete;

    private DBConnection() { }

    /**
     * Uses explicit database environment settings when provided (local runs),
     * otherwise uses Tomcat's pooled JNDI DataSource (production deployments).
     */
    public static Connection getConnection() throws SQLException {
        // SmartTomcat may expose an incomplete JNDI datasource from its local
        // descriptor. An explicit URL is the local-run signal, so honor the
        // complete environment configuration before looking up that resource.
        String configuredUrl = System.getenv("HOTEL_DB_URL");
        if (configuredUrl != null && !configuredUrl.trim().isEmpty()) {
            return getEnvironmentConnection();
        }

        DataSource dataSource = lookupJndiDataSource();
        if (dataSource != null) return dataSource.getConnection();

        return getEnvironmentConnection();
    }

    private static Connection getEnvironmentConnection() throws SQLException {
        String url = requiredEnvironmentValue("HOTEL_DB_URL");
        String user = requiredEnvironmentValue("HOTEL_DB_USER");
        String password = requiredSecret("HOTEL_DB_PASSWORD");
        if (!url.startsWith("jdbc:mysql://") && !url.startsWith("jdbc:mysql:loadbalance://")) {
            throw new SQLException("HOTEL_DB_URL must be a MySQL JDBC URL.");
        }
        try {
            Class.forName(DRIVER);
        } catch (ClassNotFoundException e) {
            throw new SQLException("MySQL JDBC driver is missing from the application.", e);
        }
        return DriverManager.getConnection(url, user, password);
    }

    private static DataSource lookupJndiDataSource() throws SQLException {
        if (jndiLookupComplete) return jndiDataSource;
        synchronized (DBConnection.class) {
            if (jndiLookupComplete) return jndiDataSource;
            try {
                Object resource = new InitialContext().lookup(JNDI_NAME);
                if (!(resource instanceof DataSource)) {
                    throw new SQLException("JNDI resource " + JNDI_NAME + " is not a DataSource.");
                }
                jndiDataSource = (DataSource) resource;
                LOG.info("Using Tomcat-managed database connection pool: " + JNDI_NAME);
            } catch (NameNotFoundException | NoInitialContextException notConfigured) {
                LOG.fine("Tomcat JNDI database pool is not configured; using local environment settings.");
            } catch (NamingException e) {
                throw new SQLException("Could not access the Tomcat database resource " + JNDI_NAME + ".", e);
            }
            jndiLookupComplete = true;
            return jndiDataSource;
        }
    }

    private static String requiredEnvironmentValue(String name) throws SQLException {
        String value = System.getenv(name);
        if (value == null || value.trim().isEmpty()) {
            throw new SQLException("Required database environment variable is not set: " + name);
        }
        return value.trim();
    }

    private static String requiredSecret(String name) throws SQLException {
        String value = System.getenv(name);
        if (value == null || value.isEmpty()) {
            throw new SQLException("Required database environment variable is not set: " + name);
        }
        return value;
    }

    /** Silently closes a connection and logs close failures. */
    public static void close(Connection connection) {
        if (connection == null) return;
        try {
            connection.close();
        } catch (SQLException e) {
            LOG.log(Level.WARNING, "Failed to close database connection.", e);
        }
    }

    /** Quick connectivity check for local troubleshooting. */
    public static void main(String[] args) {
        System.out.println("Testing database connection...");
        try (Connection connection = getConnection()) {
            System.out.println("Connection successful. Database: " + connection.getCatalog());
        } catch (SQLException e) {
            System.err.println("Connection failed: " + e.getMessage());
        }
    }
}
