// -----------------------------------------------------------------------------
// file   : CustomLibrary.js
// goal   : Custom library for Oracle Data Modeler (ODM)
// author : Gert-Jan Paulissen (Paulissoft)
// date   : 2025-10-10
// usage  : - Copy the contents of this file and paste them into a custom library
//            (for instance CustomLibrary) in ODM. Add each function
//            without underscore below as function / method to the ODM library.
//            ODM Menu: Tools | Design Rules And transformations | Libraries
//            Currently these are:
//            1) tableAbbreviationToColumn
//            2) removeTableAbbrFromColumn
//            3) applyStandardsForSelectedRelationalItems
//            4) applyStandardsForSelectedLogicalItems
//            5) setTableAbbreviation
//            6) tableNamePlural
//            7) tableToLowerCase
//            8) copyTablePrefixToIndexesAndKeys
//          - Export this library to file CustomLibrary.xml.
//          - Next add or change custom transformation scripts and use
//            the description after each 'Custom Transformation Script:' below
//            for the name. Set library and method in ODM as well.
//            Menu: Tools | Design Rules And transformations | Transformations
//          - Export these methods to file CustomTransformationScripts.xml.
// note   : The functions applyStandardsForSelectedItems_(logical|relational) are
//          the most important functiond and can be used to apply standards of
//          selected logical or relational items.
//          If the dynamic property canApplyStandards is set to 0,
//          no standards will be applied.
//          The property canApplyStandards will be set to 1 if missing.
// changes: 2025-10-10 - setDefaultOnNull(true) when !isDefaultOnNull() for ID columns
// -----------------------------------------------------------------------------

var appView = Java.type("oracle.dbtools.crest.swingui.ApplicationView");
var maxLength = 4000;
var trace = false;
var debug = false;

/**
 * Displays a message in a dialog box and returns the string that is input.
 *
 * @param question The message that is displayed in the dialog box
 * @return A String object containing the user input
 */
function _ask(question) {
    return javax.swing.JOptionPane.showInputDialog(question);
}

function _msg(msg) {
    appView.log(msg);
}

function _debug(msg) {
    if (debug) {
        _msg(msg);
    }
}

function _showObject(obj) {
    _msg(obj.getObjectTypeName() +
         " " +
         obj.getName());
}

function _trace(where, obj) {
    if (trace) {
        _msg(where +
             ": " +
             obj.getObjectTypeName() +
             " " +
             obj.getName());
    }
}

function _isEmpty(name) {
    return name === null || name.equals("") || name.equals("Unknown");
}

function _setDirty(where, obj) {
    if (!obj.isDirty()) {
        _msg("Changing " +
             obj.getObjectTypeName() +
             " " +
             obj.getName() +
             " - " +
             where);
        obj.setDirty(true);
    }
}

function _canProcess(where, object) {
    var canProcess = object.getProperty(where);

    if (_isEmpty(canProcess)) {
        canProcess = "1";
        object.setProperty(where, canProcess);
        _setDirty(where, object);
    }

    try {
        canProcess = Number(canProcess);
    } catch (e) {
        _msg(e);
        canProcess = 0;
    }

    if (canProcess !== 0) {
        _debug("Can process " +
               object.getObjectTypeName() +
               " " +
               object.getName() +
               " since the dynamic property " + where + " is 1 (true).");
        return true;
    } else {
        _msg("Can NOT process " +
             object.getObjectTypeName() +
             " " +
             object.getName() +
             " since the dynamic property " + where + " is 0 (false).");

        return false;
    }
}

function _toStream(array) {
    var dummy;

    try {
        dummy = array[0];
        return java.util.Arrays.stream(array);
    } catch (e) {
        return java.util.Arrays.stream(array.toArray());
    }
}

function _getSelectedObjects(model, objectType) {
    var appv = model.getAppView();
    var dpv = appv.getCurrentDPV();
    var obj;
    var objects = new java.util.ArrayList();

    _msg("Window: " + dpv);
    // check there is a diagram selected and it belongs to the same model
    if (dpv !== null && dpv.getDesignPart() === model) {
        _toStream(dpv.getSelectedTopViews()).forEach(function (tv) {
            obj = tv.getModel();
            if (objectType.equals(obj.getObjectTypeName())) {
                objects.add(obj);
            }
        });
    }
    _msg("# Objects of type " + objectType + ": " + objects.size());

    return objects;
}

function _copyCommentsInRDBMS(object) {
    var where = "copyCommentsInRDBMS";

    if (!_canProcess(where, object)) {
        return;
    }

    _trace(where, object);
    if (object.getComment().equals("")) {
        if (!object.getCommentInRDBMS().equals("")) {
            if (object.getCommentInRDBMS().length() > maxLength) {
                object.setComment
                ( object.getCommentInRDBMS().substring(0, maxLength)
                );
            } else {
                object.setComment(object.getCommentInRDBMS());
            }
            _setDirty(where, object);
        }
    }
}

function _copyCommentsInRDBMS_container(object) {
    _copyCommentsInRDBMS(object);

    _toStream(object.getElements()).forEach(function (element) {
        _copyCommentsInRDBMS(element);
    });

    _toStream(object.getKeys()).forEach(function (key) {
        if (!key.isFK()) {
            _copyCommentsInRDBMS(key);
        } else {
            _copyCommentsInRDBMS(key.getFKAssociation());
        }
    });
}

function _copyPreferredAbbreviation(object) {
    var where = "copyPreferredAbbreviation";

    if (!_canProcess(where, object)) {
        return;
    }

    _trace(where, object);

    if (object.getShortName().equals("")) {
        var preferredAbbreviation = object.getPreferredAbbreviation();

        if (!preferredAbbreviation.equals("")) {
            object.setShortName(preferredAbbreviation);
            _setDirty(where, object);
        }
    }
}

function _setRelationName(object,
                          sourceShortName,
                          sourceAbbreviation,
                          targetShortName,
                          targetAbbreviation) {
    var where = "setRelationName";

    if (!_canProcess(where, object)) {
        return;
    }

    var sourceName = (sourceAbbreviation.equals("") ?
                      sourceShortName :
                      sourceAbbreviation);
    var targetName = (targetAbbreviation.equals("") ?
                      targetShortName :
                      targetAbbreviation);
    var name = ((sourceName.equals("") || targetName.equals("")) ?
                "" :
                sourceName + "_" + targetName);

    if (!name.equals("") && !object.getName().equals(name)) {
        object.setName(name);
        _setDirty(where, object);
    }
}

function _setSecurityOptions(table) {
    var where = "setSecurityOptions";

    if (!_canProcess(where, table)) {
        return;
    }

    _trace(where, table);
    _toStream(table.getElements()).forEach(function (column) {
        var dirty = false;
        
        if (column.isContainsPII() !== false) {
            column.setContainsPII(false);
            dirty = true;
        }
        if (column.isContainsSensitiveInformation() !== false) {
            column.setContainsSensitiveInformation(false);
            dirty = true;
        }
        if (dirty) {
            _setDirty(where, column);
        }
    });
}

/**
 * Convert table name to plural (English).
 *
 * Skip names that end with S or ES (includes thus IES).
 * For names that end in CH, SH, X, and Z, add -ES to make them plural.
 * For names that end with Y, convert that into -IES.
 * Else, add an -S to make them plural. 
 *
 * See also https://www.english-grammar-revolution.com/last-name-plural.html.
 *   
 * @param table  The table object
 */
function _tableNamePlural(table) {
    var where = "tableNamePlural";

    if (!_canProcess(where, table)) {
        return;
    }

    var tableName = table.getName();
    var dirty = true;

    _trace(where, table);

    if (tableName.endsWith("S") ||
        tableName.endsWith("ES")) {
        dirty = false;
    } else if (tableName.endsWith("CH") ||               
               tableName.endsWith("SH") ||
               tableName.endsWith("X") ||
               tableName.endsWith("Z")) {
        table.setName(tableName + "ES");
    } else if (tableName.endsWith("Y")) {
        // Y -> IES
        table.setName(tableName.slice(0, -1) + "IES");
    } else {
        // add S
        table.setName(tableName + "S");
    }
    if (dirty) {
        _setDirty(where, table);
    }
}

// Custom Transformation Script:
// Pluralize table names (English) | relational
function tableNamePlural(model) {
    try {
        var tables = _getSelectedObjects(model, "Table");
        
        for (var i = 0; i < tables.length; i++) {
            _tableNamePlural(tables.get(i));
        }
    } catch (e) {
        _msg(e.stack);
        throw(e);
    }
}

function _setUseDomainConstraints(table) {
    var where = "setUseDomainConstraints";

    if (!_canProcess(where, table)) {
        return;
    }

    _trace(where, table);
    _toStream(table.getElements()).forEach(function (column) {
        if (column.getDomain() !== null &&
            column.getDomain().getName() !== "Unknown" &&
            column.getUseDomainConstraints() !== true) {
            column.setUseDomainConstraints(true);
            _setDirty(where, table);
        }
    });
}

function _setAutoIncrement(relationalTable, physicalTables) {
    var where = "setAutoIncrement";

    if (!_canProcess(where, relationalTable)) {
        return;
    }

    var dirty = null;

    _trace(where, relationalTable);
    _toStream(relationalTable.getElements())
        .filter(function (column) { return column.getName().equals("ID"); })
        .forEach(function (column) {
            dirty = false;
            if (!column.isAutoIncrementColumn()) {
                column.setAutoIncrementColumn(true);
                dirty = true;
            }
            // GJP 2025-09-29 No more identity columns: use sequence.NEXTVAL in default
            if (column.isIdentityColumn()) {
                column.setIdentityColumn(false);
                dirty = true;
            }            
            if (_isEmpty(column.getAutoIncrementSequenceName())) {
                column.setAutoIncrementSequenceName(relationalTable.getAbbreviation()+"_SEQ");
                column.setDefaultValue(column.getAutoIncrementSequenceName()+".NEXTVAL");
                dirty = true;
            }
            if (!column.isDefaultOnNull()) {
                column.setDefaultOnNull(true); // when column is set to NULL (and not just ignored), the sequence is also used
                dirty = true;
            }
            if (column.isAutoIncrementGenerateTrigger()) {
                column.setAutoIncrementGenerateTrigger(false);
                dirty = true;
            }
            if (dirty) {
                _setDirty(where, column);
            }
            _debug("*** " + relationalTable.getName() + "." + column.getName() + " ***");
            _debug("isAutoIncrementColumn: " + column.isAutoIncrementColumn());
            _debug("isIdentityColumn: " + column.isIdentityColumn());
            _debug("getAutoIncrementSequenceName: " + column.getAutoIncrementSequenceName());
            _debug("getDefaultValue: " + column.getDefaultValue());
            _debug("isDefaultOnNull: " + column.isDefaultOnNull());
            _debug("isAutoIncrementGenerateTrigger: " + column.isAutoIncrementGenerateTrigger());                
        });

    var physicalTable = null;

    // find physical table
    _toStream(physicalTables)
        .filter(function (physicalTable) {
            return relationalTable.getName().equals(physicalTable.getName());
        })
        .forEach(function (pt) {
            physicalTable = pt;
        });

    if (physicalTable === null || !_canProcess(where, physicalTable)) {
        return;
    }

    // not conform the SQL Data Modeler 18 documentation (!)
    var clause = "DEFAULT_CLAUSE"; // was IDENTITY_CLAUSE

    _trace(where, physicalTable);

    _toStream(physicalTable.getColumns())
        .filter(function (column) {
            return column.getName().equals("ID") &&
                   ( column.getAutoIncrementDDL() === null ||
                     !clause.equals(column.getAutoIncrementDDL()) );
        })
        .forEach(function (column) {
            column.setAutoIncrementDDL(clause);
            _setDirty(where, column);
            _debug("*** " + physicalTable.getName() + "." + column.getName() + " ***");
            _debug("getAutoIncrementDDL: " + column.getAutoIncrementDDL());
        });
}

/**
 * Convert table name, column names and key names to lower case.
 *
 * @param table  The table object
 */
function _tableToLowerCase(table) {
    var where = "tableToLowerCase";

    if (!_canProcess(where, table)) {
        return;
    }

    var name = table.getName().toLowerCase();

    _trace(where, table);

    if (!name.equals(table.getName())) {
        table.setName(name);
        _setDirty(where, table);
    }

    _toStream(table.getElements()).forEach(function (column) {
        name = column.getName().toLowerCase();
        if (!name.equals(column.getName())) {
            column.setName(name);
            _setDirty(where, column);
        }
    });

    _toStream(table.getKeys()).forEach(function (key) {
        if (!key.isFK()) {
            name = key.getName().toLowerCase();
            if (!name.equals(key.getName())) {
                key.setName(name);
                _setDirty(where, key);
            }
        } else {
            name = key.getFKAssociation().getName().toLowerCase();
            if (!name.equals(key.getFKAssociation().getName())) {
                key.getFKAssociation().setName(name);
                _setDirty(where, key.getFKAssociation());
            }
        }
    });
}

// Custom Transformation Script:
// Set table, column and key names to lower case | relational
function tableToLowerCase(model) {
    try {
        var tables = _getSelectedObjects(model, "Table");
        
        for (var i = 0; i < tables.length; i++) {
            _tableToLowerCase(tables.get(i));
        }
    } catch (e) {
        _msg(e.stack);
        throw(e);
    }
}

/**
 * Prefix each column name with the table abbreviation (plus an underscore).
 *
 * @param table  The table object
 */
function _tableAbbreviationToColumn(table) {
    var where = "tableAbbreviationToColumn";

    if (!_canProcess(where, table)) {
        return;
    }

    var abbr = table.getAbbreviation()+"_";

    _trace(where, table);

    if (abbr.length !== 1) {
        _toStream(table.getElements()).forEach(function (column) {
            var cname = column.getName();
            if (!cname.startsWith(abbr)) {
                column.setName(abbr + cname);
            }
        });
    }
}

// Custom Transformation Script:
// Prefix each column with the table abbreviation | relational
function tableAbbreviationToColumn(model) {
    _toStream(model.getTableSet()).forEach()(function (table) {
        _tableAbbreviationToColumn(table);
    });
}

/**
 * Remove from each column the table abbreviation (plus an underscore) prefix.
 *
 * @param table  The table object
 */
function _removeTableAbbrFromColumn(table) {
    var where = "removeTableAbbrFromColumn";

    if (!_canProcess(where, table)) {
        return;
    }

    var abbr = table.getAbbreviation()+"_";
    var count = table.getAbbreviation().length()+1;

    _trace(where, table);

    if (count !== 1) {
        _toStream(table.getElements()).forEach(function (column) {
            var cname = column.getName();
            if (cname.startsWith(abbr)) {
                column.setName(cname.substring(count));
                _setDirty(where, column);
            }
        });
    }
}

// Custom Transformation Script:
// Remove from columns the table abbreviation prefix | relational
function removeTableAbbrFromColumn(model) {
    _toStream(model.getTableSet()).forEach(function (table) {
        _removeTableAbbrFromColumn(table);
    });
}

function _tableToUpperCase(table) {
    var where = "tableToUpperCase";

    if (!_canProcess(where, table)) {
        return;
    }

    var name = table.getName().toUpperCase();

    _trace(where, table);

    if (!name.equals(table.getName())) {
        table.setName(name);
        _setDirty(where, table);
    }

    _toStream(table.getElements()).forEach(function (column) {
        name = column.getName().toUpperCase();
        if (!name.equals(column.getName())) {
            column.setName(name);
            _setDirty(where, column);
        }
    });

    _toStream(table.getKeys()).forEach(function (key) {
        if (!key.isFK()) {
            name = key.getName().toUpperCase();
            if (!name.equals(key.getName())) {
                key.setName(name);
                _setDirty(where, key);
            }
        } else {
            name = key.getFKAssociation().getName().toUpperCase();
            if (!name.equals(key.getFKAssociation().getName())) {
                key.getFKAssociation().setName(name);
                _setDirty(where, key.getFKAssociation());
            }
        }
    });
}

function _copyComments(object) {
    var where = "copyComments";

    if (!_canProcess(where, object)) {
        return;
    }

    _trace(where, object);
    if (object.getCommentInRDBMS().equals("")) {
        if (!object.getComment().equals("")) {
            if (object.getComment().length() > maxLength) {
                object.setCommentInRDBMS
                ( object.getComment().substring(0, maxLength)
                );
            } else {
                object.setCommentInRDBMS(object.getComment());
            }
            _setDirty(where, object);
        }
    }
}

function _copyComments_container(object) {
    _copyComments(object);
    _toStream(object.getElements()).forEach(function (element) {
        _copyComments(element);
    });
    _toStream(object.getKeys()).forEach(function (key) {
        if (!key.isFK()) {
            _copyComments(key);
        } else {
            _copyComments(key.getFKAssociation());
        }
    });
}

function _getIndex(tab, cols) {
    try {
        return _toStream(tab.getKeys())
            .filter(function (k) {
                return !(k.isPK() || k.isUnique()) &&
                       !k.isFK() &&
                       k.isIndexForColumns(cols);
            })
            .findFirst()
            .get();
    } catch (e) { // NoSuchElementException
        return null;
    }
}

function _createIndexOnFK(table) {
    var where = "createIndexOnFK";

    if (!_canProcess(where, table)) {
        return;
    }

    var columns;
    var newIndex;

    _trace(where, table);

    _toStream(table.getKeys())
        .filter(function (index) { return index.isFK(); })
        .forEach(function (index) {
            columns = index.getColumns();
            if (columns.length > 0) {
                newIndex = _getIndex(table, columns);
                if (newIndex === null) {
                    newIndex = table.createIndex();
                    _setDirty(where, table);
                    _toStream(columns).forEach(function (column) {
                        newIndex.add(column);
                    });
                }
            }
        });
}

/**
 * Set table abbreviation based on primary key.
 *
 * @param table  The table object
 */
function _setTableAbbreviation(table) {
    var where = "setTableAbbreviation";

    if (!_canProcess(where, table)) {
        return;
    }

    var pk = table.getPK();

    if (_isEmpty(table.getAbbreviation()) && pk !== null && pk.getName().endsWith("_PK")) {
        table.setAbbreviation(pk.getName().replaceAll("_PK", ""));
        _debug("abbreviation: " + table.getAbbreviation());
        _setDirty(where, table);
    }
}

// Custom Transformation Script:
// Set table abbreviation based on primary key | relational
function setTableAbbreviation(model) {
    try {
        var tables = _getSelectedObjects(model, "Table");
        
        for (var i = 0; i < tables.length; i++) {
            _setTableAbbreviation(tables.get(i));
        }
    } catch (e) {
        _msg(e.stack);
        throw(e);
    }
}

// sorts table columns as asked here
// https://forums.oracle.com/forums/thread.jspa?threadID=2508315&tstart=0
// 1) first the pk columns,
// 2) after them fk columns
// 3) and after them the not null columns
function _addPKcolumns(list, table) {
    var pk = table.getPK();

    if (pk !== null) {
        _toStream(pk.getColumns())
            .filter(function (col) { return !list.contains(col); })
            .forEach(function (col) {
                // in fact don't need this check,
                // because PK columns are processed first
                _debug("adding PK column " + col);
                list.add(col);
            });
    }
}

function _addUKcolumns(list, table) {
    _toStream(table.getKeys())
        .filter(function (key) { return !key.isPK() && key.isUnique(); })
        .forEach(function (key) {
            _toStream(key.getColumns())
                .filter(function (col) { return !list.contains(col); })
                .forEach(function (col) {
                    _debug("adding UK column " + col);
                    list.add(col);
                });
        });
}

function _addFKcolumns(list, fkeys) {
    if (fkeys === null || fkeys.length == 0) return;
    _toStream(fkeys).forEach(function (fkey) {
        _toStream(fkey.getColumns())
            .filter(function (col) { return !list.contains(col); })
            .forEach(function (col) {
                _debug("adding FK column " + col);
                list.add(col);
            });
    });
}

//adds mandatory or optional columns to list depending on mandatory parameter
function _addMandatoryOptColumns(list, cols, mand) {
    _toStream(cols)
        .filter(function (col) {
            return col.isMandatory() === mand && !list.contains(col);
        })
        .forEach(function (col) {
            _debug("adding " +
                   (mand ? "mandatory" : "optional") +
                   " column " +
                   col);
            list.add(col);
        });
}

function _setColumnsOrder(table) {
    var where = "setColumnsOrder";

    if (!_canProcess(where, table)) {
        return;
    }

    var oldColumnList = new java.util.ArrayList();
    var newColumnList = new java.util.ArrayList();
    var cols = table.getElements();
    var index = 0;

    _trace(where, table);

    _toStream(cols)
        .forEach(function (column) {
            oldColumnList.add(column);
        });

    // add PK columns to newColumnList
    _addPKcolumns(newColumnList, table);
    // add UK columns to newColumnList
    _addUKcolumns(newColumnList, table);
    // add FK columns to newColumnList
    _addFKcolumns(newColumnList, table.getFKAssociations());
    // add mandatory columns
    _addMandatoryOptColumns(newColumnList, cols, true);
    // add optional columns
    _addMandatoryOptColumns(newColumnList, cols, false);
    // do we need to change?
    if (!oldColumnList.equals(newColumnList)) {
        // use newColumnList to reorder columns
        newColumnList.forEach(function (col) {
            _debug("move column " + col + " to index " + index);
            table.moveToIndex(col, index);
            index += 1;
        });

        // prevent reordering from engineering, can be changed with UI
        table.setAllowColumnReorder(false);
        _setDirty(where, table);
    }
}

/**
 * Copy table prefix to indexes and keys.
 *
 * @param table  The table object
 */
function _copyTablePrefixToIndexesAndKeys(table) {
    var where = "copyTablePrefixToIndexesAndKeys";

    if (!_canProcess(where, table)) {
        return;
    }

    var pos = table.getName().indexOf("_");
    var prefix = (pos < 0 ? null : table.getName().substring(0, pos+1));
    var name = null;

    if (prefix) {
        _toStream(table.getKeys()).forEach(function (key) {
            if (!key.isFK()) {
                name = key.getName();
                if (!name.startsWith(prefix)) {
                    key.setName(prefix + name);
                    _setDirty(where, key);
                }
            } else {
                name = key.getFKAssociation().getName();
                if (!name.startsWith(prefix)) {
                    key.getFKAssociation().setName(prefix + name);
                    _setDirty(where, key.getFKAssociation());
                }
            }
        });
        _toStream(table.getIndexes()).forEach(function (index) {
            name = index.getName();
            if (!name.startsWith(prefix)) {
                index.setName(prefix + name);
                _setDirty(where, index);
            }
        });
    }
}

// Custom Transformation Script:
// Copy table prefix to indexes and keys | relational
function copyTablePrefixToIndexesAndKeys(model) {
    try {
        var tables = _getSelectedObjects(model, "Table");
        
        for (var i = 0; i < tables.length; i++) {
            _copyTablePrefixToIndexesAndKeys(tables.get(i));
        }
    } catch (e) {
        _msg(e.stack);
        throw(e);
    }
}

function _applyStandardsTable(table, physicalTables) {
    var where = "applyStandards";

    if (!_canProcess(where, table)) {
        return;
    }

    _showObject(table);

    _copyComments_container(table);
    _copyCommentsInRDBMS_container(table);
    _setSecurityOptions(table);
    _tableToUpperCase(table);
    // _tableNamePlural(table); // there is a tableNamePlural()
    _setUseDomainConstraints(table);
    _setTableAbbreviation(table);
    _setAutoIncrement(table, physicalTables);
    // _tableToLowerCase(table); // there is a tableToLowerCase()
    // _tableAbbreviationToColumn(table); // there is a tableAbbreviationToColumn()
    // _removeTableAbbrFromColumn(table); // there is a removeTableAbbrFromColumn()
    _createIndexOnFK(table);
    _setColumnsOrder(table);
    // _copyTablePrefixToIndexesAndKeys(table); // there is a copyTablePrefixToIndexesAndKeys()
}

// Custom Transformation Script:
// Apply standards for selected relational items | relational
function applyStandardsForSelectedRelationalItems(model) {
    var physicalTables = model.getStorageDesign().getTableProxySet();

    try {
        // Ask some questions before converting all.
        debug = /^[YyTt1]/.test(_ask('Debugging on [N] ? '));
        if (debug) { // enable trace only when debug is true
            trace = /^[YyTt1]/.test(_ask('Tracing on [N] ? '));
        }
        
        _getSelectedObjects(model, "Table").forEach(function (table) {
            _applyStandardsTable(table, physicalTables);
        });
    } catch (e) {
        _msg(e.stack);
        throw(e);
    }
}

function _applyStandardsEntity(entity) {
    var where = "applyStandards";

    if (!_canProcess(where, entity)) {
        return;
    }

    _showObject(entity);

    _copyPreferredAbbreviation(entity);
    _copyComments_container(entity);
    _copyCommentsInRDBMS_container(entity);
}

function _applyStandardsRelation(rel) {
    var where = "applyStandards";

    if (!_canProcess(where, rel)) {
        return;
    }

    _showObject(rel);

    _setRelationName(rel,
                     rel.getSourceEntity().getShortName(),
                     rel.getSourceEntity().getPreferredAbbreviation(),
                     rel.getTargetEntity().getShortName(),
                     rel.getTargetEntity().getPreferredAbbreviation());
}

// Custom Transformation Script:
// Apply standards for selected logical items | logical
function applyStandardsForSelectedLogicalItems(model) {
    try {
        // Ask some questions before converting all.
        debug = /^[YyTt1]/.test(_ask('Debugging on [N] ? '));
        if (debug) { // enable trace only when debug is true
            trace = /^[YyTt1]/.test(_ask('Tracing on [N] ? '));
        }

        _getSelectedObjects(model, "Entity").forEach(function (entity) {
            _applyStandardsEntity(entity);
        });
        _getSelectedObjects(model, "Relation").forEach(function (rel) {
            _applyStandardsRelation(rel);
        });
    } catch (e) {
        _msg(e.stack);
        throw(e);
    }
}
