package com.paulissoft.pato.jdbc;

import java.util.Properties;
import java.sql.Connection;
import oracle.ucp.jdbc.LabelableConnection;
import oracle.ucp.ConnectionLabelingCallback;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


class SmartConnectionLabelingCallbackOracle implements ConnectionLabelingCallback {

    private static final Logger LOGGER = LoggerFactory.getLogger(SmartConnectionLabelingCallbackOracle.class.getName());
    
    private final String CURRENT_SCHEMA = "current_schema";
    
    public SmartConnectionLabelingCallbackOracle() {
    }

    public int cost(Properties reqLabels, Properties currentLabels) {
        int result = Integer.MAX_VALUE; // default: create new connection

        if (reqLabels.equals(currentLabels)) {
            // Case 1: exact match
            result = 0;
        } else {
            final String schema1 = (String) reqLabels.get(CURRENT_SCHEMA);
            final String schema2 = (String) currentLabels.get(CURRENT_SCHEMA);
            final boolean match =
                (schema1 != null && schema2 != null && schema1.equalsIgnoreCase(schema2));
            final var rKeys = reqLabels.keySet();
            final var cKeys = currentLabels.keySet();
        
            if (match && rKeys.containsAll(cKeys)) {
                // Case 2: current schema label matches and no unmatched labels
                result = 1;
            }
        }
        
        LOGGER.debug("cost(reqLabels={}, currentLabels={}) = {}", reqLabels, currentLabels, result);

        return result;
    }

    public boolean configure(Properties reqLabels, Object conn) {
        boolean result = true;
        
        try {
            final String schema = (String) reqLabels.get(CURRENT_SCHEMA);
                
            ((Connection) conn).setSchema(schema);
            
            final LabelableConnection lconn = (LabelableConnection) conn;

            // Find the unmatched labels on this connection
            final Properties unmatchedLabels =
                lconn.getUnmatchedConnectionLabels(reqLabels);

            // Apply each label <key,value> in unmatchedLabels to conn
            for (var label : unmatchedLabels.entrySet()) {
                final String key = (String) label.getKey();
                final String value = (String) label.getValue();

                lconn.applyConnectionLabel(key, value);
            }
        } catch (Exception exc) {
            result = false;
        }

        LOGGER.debug("configure(reqLabels={}) = {}", reqLabels, result);

        return result;
    }
}
