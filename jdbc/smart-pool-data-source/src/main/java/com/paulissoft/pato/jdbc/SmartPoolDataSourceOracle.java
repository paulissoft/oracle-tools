package com.paulissoft.pato.jdbc;

import java.io.Closeable;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.SQLFeatureNotSupportedException;
import java.util.logging.Logger;
import java.util.Properties;
import oracle.ucp.jdbc.PoolDataSourceImpl;


public class SmartPoolDataSourceOracle extends PoolDataSourceImpl implements ConnectInfo, Closeable {

    private static final long serialVersionUID = 1L;
	
    // this delegate will do the actual work
    private static final SharedPoolDataSourceOracle delegate = new SharedPoolDataSourceOracle();
    
    private volatile String currentSchema = null;

    /*
    // overridden methods from PoolDataSourceImpl
    */
    
    @Override
    public Connection getConnection() throws SQLException {
        return delegate.getConnection();
    }

    @Override
    public Connection getConnection(Properties labels) throws SQLException {
	try {
            throw new SQLFeatureNotSupportedException("getConnection");            
	} catch (Exception ex) {
	    throw new RuntimeException(String.format("%s: %s", ex.getClass().getName(), ex.getMessage()));
	}
    }

    @Override
    public Connection getConnection(String username, String password) throws SQLException {
        return delegate.getConnection(username, password);
    }

    @Override
    public Connection getConnection(String username, String password, Properties labels) throws SQLException {
	try {
            throw new SQLFeatureNotSupportedException("getConnection");            
	} catch (Exception ex) {
	    throw new RuntimeException(String.format("%s: %s", ex.getClass().getName(), ex.getMessage()));
	}
    }
    
    @Override
    public PrintWriter getLogWriter() throws SQLException {
        return delegate.getLogWriter();
    }

    @Override
    public void setLogWriter(PrintWriter out) throws SQLException {
        delegate.setLogWriter(out);
    }

    @Override
    public Logger getParentLogger() {
	try {
	    return delegate.getParentLogger();
	} catch (Exception ex) {
	    throw new RuntimeException(String.format("%s: %s", ex.getClass().getName(), ex.getMessage()));
	}
    }

    @Override
    public <T> T unwrap(Class<T> iface) throws SQLException {
        return delegate.unwrap(iface);
    }

    @Override
    public boolean isWrapperFor(Class<?> iface) throws SQLException {
        return delegate.isWrapperFor(iface);
    }

    @Override
    public String getSQLForValidateConnection() {
        return getSQLAlterSessionSetCurrentSchema();
    }

    @Override
    public void setSQLForValidateConnection(String SQLstring) {
        try {
            // since getSQLForValidateConnection is overridden it does not make sense to set it
            throw new SQLFeatureNotSupportedException("setSQLForValidateConnection");            
        } catch (Exception ex) {
            throw new RuntimeException(String.format("%s: %s", ex.getClass().getName(), ex.getMessage()));
        }
    }
    
    @Override
    public void setPassword(String password) throws SQLException {
        // Here we will set both the super and the delegate password so that the overridden getConnection() will always use
        // the same password no matter where it comes from.

        super.setPassword(password);
        delegate.setPassword(password);
    }

    @Override
    public void setUser(String username) throws SQLException {
        // Here we will set both the super and the delegate username so that the overridden getConnection() will always use
        // the same password no matter where it comes from.
	var connectInfo = determineProxyUsernameAndCurrentDSchema(username);
	
        synchronized(this) {
	    currentSchema = connectInfo[1];
        }

        super.setUser(connectInfo[0] != null ? connectInfo[0] : connectInfo[1]);
        delegate.setUsername(connectInfo[0] != null ? connectInfo[0] : connectInfo[1]);

        // Add this object here (setUsername() should always be called) and
        // not in the constructor to prevent a this escape warning in the constructor.
        delegate.add(this);
    }

    /*
    // Interface ConnectInfo
    */
    public String getCurrentSchema() {
	return currentSchema;
    }

    /*
    // Interface Closeable
    */
    public void close() {
        delegate.remove(this);
    }

    // extra
    
    public boolean isClosed() {
        return !delegate.contains(this);
    }

}
