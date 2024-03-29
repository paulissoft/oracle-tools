// -----------------------------------------------------------------------------
// file  : CustomLibrary.js
// goal  : Custom library for Oracle Data Modeler (ODM)
// author: Gert-Jan Paulissen (Paulissoft)
// date  : 2023-07-31
// usage : - Copy the contents of this file and paste them into a custom library
//           (for instance CustomLibrary) in ODM. Add each function
//           without underscore below as function / method to the ODM library.
//           ODM Menu: Tools | Design Rules And transformations | Libraries
//         - Export this library to file CustomLibrary.xml.
//         - Next add or change custom transformation scripts and use
//           the description after each 'Custom Transformation Script:' below
//           for the name. Set library and method in ODM as well.
//           Menu: Tools | Design Rules And transformations | Transformations
//         - Export these methods to file CustomTransformationScripts.xml.
// note  : The functions applyStandardsForSelectedItems_(logical|relatonal) are
//         the most important functiond and can be used to apply standards of
//         selected logical or relational items.
//         If the dynamic property canApplyStandards is set to 0,
//         no standards will be applied.
//         The property canApplyStandards will be set to 1 if missing.
// -----------------------------------------------------------------------------

var appView = Java.type("oracle.dbtools.crest.swingui.ApplicationView");
var maxLength = 4000;
var trace = false;
var debug = false;

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

function _setDirty(where, obj) {
    _msg("Changing " +
         obj.getObjectTypeName() +
         " " +
         obj.getName() +
         " - " +
         where);
    obj.setDirty(true);
}

function _canProcess(where, object) {
    var canProcess = object.getProperty(where);

    if (canProcess === null || canProcess.equals("")) {
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
        return true;
    } else {
        _msg("Can not process " +
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
    var preferredAbbreviation = object.getPreferredAbbreviation();

    _trace(where, object);

    if (object.getShortName().equals("")) {
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
    var sourceName = (sourceAbbreviation.equals("") ?
                      sourceShortName :
                      sourceAbbreviation);
    var targetName = (targetAbbreviation.equals("") ?
                      targetShortName :
                      targetAbbreviation);
    var name = ((sourceName.equals("") || targetName.equals("")) ?
                "" :
                sourceName + "_" + targetName);

    if (!_canProcess(where, object)) {
        return;
    }

    if (!name.equals("") && !object.getName().equals(name)) {
        object.setName(name);
        _setDirty(where, object);
    }
}

function _setSecurityOptions(table) {
    var where = "setSecurityOptions";

    _trace(where, table);
    _toStream(table.getElements()).forEach(function (column) {
        if (column.isContainsPII() !== false) {
            column.setContainsPII(false);
            _setDirty(where, column);
        }
        if (column.isContainsSensitiveInformation() !== false) {
            column.setContainsSensitiveInformation(false);
            _setDirty(where, column);
        }
    });
}

function _tableNamePlural(table) {
    var where = "tableNamePlural";
    var tableName = table.getName();
    var dirty = true;

    _trace(where, table);

    if (tableName.endsWith("Y")) {
        // Y -> IES
        table.setName(tableName.slice(0, -1) + "IES");
    } else if (tableName.endsWith("X")) {
        // X -> CES
        table.setName(tableName.slice(0, -1) + "CES");
    } else if (!tableName.endsWith("S")) {
        // . -> .S
        table.setName(tableName + "S");
    } else {
        dirty = false;
    }
    if (dirty) {
        _setDirty(where, table);
    }
}

function _setUseDomainConstraints(table) {
    var where = "setUseDomainConstraints";

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

function _setIdentityColumn_relational(table) {
    var where = "setIdentityColumn_relational";
    var dirty = null;

    _trace(where, table);
    _toStream(table.getElements())
        .filter(function (column) { return column.getName().equals("ID"); })
        .forEach(function (column) {
            dirty = false;
            if (!column.isAutoIncrementColumn()) {
                column.setAutoIncrementColumn(true);
                dirty = true;
            }
            if (!column.isIdentityColumn()) {
                column.setIdentityColumn(true);
                dirty = true;
            }
            if (column.isAutoIncrementGenerateTrigger()) {
                column.setAutoIncrementGenerateTrigger(false);
                dirty = true;
            }
            if (dirty) {
                _setDirty(where, column);
            }
        });
}

function _setIdentityColumn_physical(table) {
    var where = "setIdentityColumn_physical";
    // not conform the SQL Data Modeler 18 documentation (!)
    var clause = "IDENTITY_CLAUSE";

    _trace(where, table);

    _toStream(table.getColumns())
        .filter(function (column) {
            return column.getName().equals("ID") &&
                   ( column.getAutoIncrementDDL() === null ||
                     !clause.equals(column.getAutoIncrementDDL()) );
        })
        .forEach(function (column) {
            column.setAutoIncrementDDL(clause);
            _setDirty(where, column);
        });
}

function _setIdentityColumn(relationalTable, physicalTables) {
    var where = "setIdentityColumn";

    if (!_canProcess(where, relationalTable)) {
        return;
    }

    _trace(where, relationalTable);

    _setIdentityColumn_relational(relationalTable);

    _toStream(physicalTables)
        .filter(function (physicalTable) {
            return relationalTable.getName().equals(physicalTable.getName());
        })
        .forEach(function (physicalTable) {
            _setIdentityColumn_physical(physicalTable);
        });
}

function _setIdentityColumns(relationalTables, physicalTables) {
    _toStream(relationalTables).forEach(function (relationalTable) {
        _setIdentityColumn(relationalTable, physicalTables);
    });
}

function _tableToLowerCase(table) {
    var where = "tableToLowerCase";
    var name = table.getName().toLowerCase();

    if (!_canProcess(where, table)) {
        return;
    }

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

function _tableAbbreviationToColumn(table) {
    var where = "tableAbbreviationToColumn";
    var abbr = table.getAbbreviation()+"_";

    if (!_canProcess(where, table)) {
        return;
    }

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
// Table abbreviation to column | relational
function tableAbbreviationToColumn(model) {
    _toStream(model.getTableSet()).forEach()(function (table) {
        _tableAbbreviationToColumn(table);
    });
}

function _removeTableAbbrFromColumn(table) {
    var where = "removeTableAbbrFromColumn";
    var abbr = table.getAbbreviation()+"_";
    var count = table.getAbbreviation().length()+1;

    if (!_canProcess(where, table)) {
        return;
    }

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
// Remove Table abbr from column | relational
function removeTableAbbrFromColumn(model) {
    _toStream(model.getTableSet()).forEach(function (table) {
        _removeTableAbbrFromColumn(table);
    });
}

function _tableToUpperCase(table) {
    var where = "tableToUpperCase";
    var name = table.getName().toUpperCase();

    if (!_canProcess(where, table)) {
        return;
    }

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
    var columns;
    var newIndex;

    if (!_canProcess(where, table)) {
        return;
    }

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

// sorts table columns as asked here
// https://forums.oracle.com/forums/thread.jspa?threadID=2508315&tstart=0
// 1) first the pks columns,
// 2) after them fk columns
// 3) and after the; the not null columns"
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
    var oldColumnList = new java.util.ArrayList();
    var newColumnList = new java.util.ArrayList();
    var cols = table.getElements();
    var index = 0;

    if (!_canProcess(where, table)) {
        return;
    }

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

function _copyTablePrefixToIndexesAndKeys(table) {
    var where = "copyTablePrefixToIndexesAndKeys";
    var pos = table.getName().indexOf("_");
    var prefix = (pos < 0 ? null : table.getName().substring(0, pos+1));
    var name = null;

    if (!_canProcess(where, table)) {
        return;
    }

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

function _applyStandardsTable(table, physicalTables) {
    var where = "applyStandards";

    _showObject(table);

    if (_canProcess(where, table)) {
        _copyComments_container(table);
        _copyCommentsInRDBMS_container(table);
        _setSecurityOptions(table);
        _tableToUpperCase(table);
        _tableNamePlural(table);
        _setUseDomainConstraints(table);
        _setIdentityColumn(table, physicalTables);
        // _tableToLowerCase(table);
        // _tableAbbreviationToColumn(table);
        // _removeTableAbbrFromColumn(table);
        _createIndexOnFK(table);
        _setColumnsOrder(table);
        // _copyTablePrefixToIndexesAndKeys(table);
    }
}

// Custom Transformation Script:
// Apply standards for selected relational items | relational
function applyStandardsForSelectedRelationalItems(model) {
    var physicalTables = model.getStorageDesign().getTableProxySet();

    try {
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

    _showObject(entity);

    if (_canProcess(where, entity)) {
        _copyPreferredAbbreviation(entity);
        _copyComments_container(entity);
        _copyCommentsInRDBMS_container(entity);
    }
}

function _applyStandardsRelation(rel) {
    var where = "applyStandards";

    _showObject(rel);

    if (_canProcess(where, rel)) {
        _setRelationName(rel,
                         rel.getSourceEntity().getShortName(),
                         rel.getSourceEntity().getPreferredAbbreviation(),
                         rel.getTargetEntity().getShortName(),
                         rel.getTargetEntity().getPreferredAbbreviation());
    }
}

// Custom Transformation Script:
// Apply standards for selected logical items | logical
function applyStandardsForSelectedLogicalItems(model) {
    try {
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
