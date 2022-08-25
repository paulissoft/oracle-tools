// -----------------------------------------------------------------------------
// file  : CustomLibrary.js
// goal  : Custom library for Oracle Data Modeler (ODM)
// author: Gert-Jan Paulissen (Paulissoft)
// date  : 2022-08-25
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
// note  : The function applyStandardsForSelectedTables is the most important
//         function and can be used to apply standards fo selected tables.
//         If the dynamic property canApplyStandards is set to 0,
//         no standards will be applied.
//         The property canApplyStandards will be set to 1 if missing.
// -----------------------------------------------------------------------------

var appView = Java.type("oracle.dbtools.crest.swingui.ApplicationView");
var maxLength = 4000;
var trace = false;

function _msg(msg) {
    appView.log(msg);
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

            _msg("Object type: " + obj.getObjectTypeName());

            //if table then put its name in the log window
            if (objectType.equals(obj.getObjectTypeName())) {
                objects.add(obj);
            }
        });
    }
    _msg("# Objects of type " + objectType + ": " + objects.size());

    return objects;
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

// Custom Transformation Script:
// Show selected tables - custom
function showSelectedTables(model) {
    _getSelectedObjects(model, "Table").forEach(_showObject);
}

// Custom Transformation Script:
// Show selected entities - custom
function showSelectedEntities(model) {
    _getSelectedObjects(model, "Entity").forEach(_showObject);
}

function _copyCommentsInRDBMS(object) {
    var where =
        "Copy Comments in RDBMS to Comments (logical) - custom | logical";

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

// Custom Transformation Script:
// Copy Comments in RDBMS to Comments (logical) - custom | logical
function copyCommentsInRDBMS_logical(model) {
    _toStream(model.getEntitySet()).forEach(function (entity, index) {
        _copyCommentsInRDBMS(entity);

        _toStream(entity.getElements()).forEach(function (attribute) {
            _copyCommentsInRDBMS(attribute);
        });

        _toStream(entity.getKeys()).forEach(function (key) {
            if (!key.isFK()) {
                _copyCommentsInRDBMS(key);
            } else {
                _copyCommentsInRDBMS(key.getFKAssociation());
            }
        });
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

// Custom Transformation Script:
// Copy Preferred Abbreviation to Short Name - custom | logical
function copyPreferredAbbreviation(model) {
    _toStream(model.getEntitySet()).forEach(function (entity) {
        _copyPreferredAbbreviation(entity);
    });
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

    if (!name.equals("") && !object.getName().equals(name)) {
        object.setName(name);
        _setDirty(where, object);
    }
}

// Custom Transformation Script:
// Set Relation Name - custom | logical
function setRelationName(model) {
    _toStream(model.getRelationSet()).forEach(function (relation) {
        _setRelationName(relation,
                         relation.getSourceEntity().getShortName(),
                         relation.getSourceEntity().getPreferredAbbreviation(),
                         relation.getTargetEntity().getShortName(),
                         relation.getTargetEntity().getPreferredAbbreviation());
    });
}

// Custom Transformation Script:
// Copy Comments in RDBMS to Comments (relational) - custom | relational
function copyCommentsInRDBMS_relational(model) {
    _toStream(model.getTableSet()).forEach(function (table) {
        _copyCommentsInRDBMS(table);

        _toStream(table.getElements()).forEach(function (column) {
            _copyCommentsInRDBMS(column);
        });

        _toStream(table.getKeys()).forEach(function (key) {
            if (!key.isFK()) {
                _copyCommentsInRDBMS(key);
            } else {
                _copyCommentsInRDBMS(key.getFKAssociation());
            }
        });
    });
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

// Custom Transformation Script:
// Set security options - custom | relational
function setSecurityOptions(model) {
    _toStream(model.getTableSet()).forEach(function (table) {
        _setSecurityOptions(table);
    });
}

// Custom Transformation Script:
// Set selected security options - custom | relational
function setSelectedSecurityOptions(model) {
    _getSelectedObjects(model, "Table").forEach(function (table) {
        _setSecurityOptions(table);
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

// Custom Transformation Script:
// Table names plural - custom | relational
function tableNamesPlural(model) {
    _toStream(model.getTableSet()).forEach(function (table) {
        _tableNamePlural(table);
    });
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

// Custom Transformation Script:
// Set Use Domain Constraints - custom | relational
function setUseDomainConstraints(model) {
    _toStream(model.getTableSet()).forEach(function (table) {
        _setUseDomainConstraints(table);
    });
}

function _setIdentityColumn_relational(table) {
    var where = "setIdentityColumn_relational";

    _trace(where, table);
    _toStream(table.getElements())
        .filter(function (column) { return column.getName().equals("ID"); })
        .forEach(function (column) {
            column.setAutoIncrementColumn(true);
            column.setIdentityColumn(true);
            column.setAutoIncrementGenerateTrigger(false);
            _setDirty(where, column);
        });
}

function _setIdentityColumn_physical(table) {
    var where = "setIdentityColumn_physical";
    // not conform the SQL Data Modeler 18 documentation (!)
    var clause = "IDENTITY_CLAUSE";

    _trace(where, table);

    _toStream(table.getColumns())
        .filter(function (column) { return column.getName().equals("ID"); })
        .forEach(function (column) {
            column.setAutoIncrementDDL(clause);
            _setDirty(where, column);
        });
}

function _setIdentityColumn(relationalTable, physicalTables) {
    var where = "setIdentityColumn";

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

// Custom Transformation Script:
// Define IDENTITY clause for ID columns - custom | relational
function setIdentityColumns(model) {
    _setIdentityColumns(model.getTableSet(),
                        model.getStorageDesign().getTableProxySet());
}

// Custom Transformation Script:
// Define IDENTITY clause for selected ID columns - custom | relational
function setSelectedIdentityColumns(model) {
    _setIdentityColumns(_getSelectedObjects(model, "Table"),
                        model.getStorageDesign().getTableProxySet());
}

function _tableToLowerCase(table) {
    var where = "tableToLowerCase";
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
        if (!key.isFK()){
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
// Tables to lower case - Rhino
function tablesToLowerCase(model) {
    _toStream(model.getTableSet()).forEach(function (table) {
        _tableToLowerCase(table);
    });
}

function _tableAbbreviationToColumn(table) {
    var where = "tableAbbreviationToColumn";
    var abbr = table.getAbbreviation()+"_";

    _trace(where, table);

    if(abbr.length !== 1){
        _toStream(table.getElements()).forEach(function (column) {
            var cname = column.getName();
            if(!cname.startsWith(abbr)){
                column.setName(abbr + cname);
            }
        });
    }
}

// Custom Transformation Script:
// Table abbreviation to column
function tableAbbreviationToColumn(model) {
    _toStream(model.getTableSet()).forEach()(function (table) {
        _tableAbbreviationToColumn(table);
    });
}

function _removeTableAbbrFromColumn(table) {
    var where = "removeTableAbbrFromColumn";
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
// Remove Table abbr from column
function removeTableAbbrFromColumn(model) {
    _toStream(model.getTableSet()).forEach(function (table) {
        _removeTableAbbrFromColumn(table);
    });
}

function _tableToUpperCase(table) {
    var where = "tableToUpperCase";
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

// Custom Transformation Script:
// Tables to upper case - Rhino
function tablesToUpperCase(model) {
    try {
        _toStream(model.getTableSet()).forEach(function (table) {
            _tableToUpperCase(table);
        });
    } catch (e) {
        _msg(e.stack);
        throw(e);
    }
}

function _copyComments(object) {
    var where = "copyComments";

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

// Custom Transformation Script:
// Copy Comments to Comments in RDBMS
function copyComments(model) {
    _toStream(model.getTableSet()).forEach(function (table) {
        _copyComments(table);
        _toStream(table.getElements()).forEach(function (column) {
            _copyComments(column);
        });
        _toStream(table.getKeys()).forEach(function (key) {
            if (!key.isFK()) {
                _copyComments(key);
            } else {
                _copyComments(key.getFKAssociation());
            }
        });
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

// Custom Transformation Script:
// Create index on FK
function createIndexOnFK(model) {
    _toStream(model.getTableSet()).forEach(function (table) {
        _createIndexOnFK(table);
    });
}

// sorts table columns as asked here
// https://forums.oracle.com/forums/thread.jspa?threadID=2508315&tstart=0
// 1) first the pks columns,
// 2) after them fk columns
// 3) and after the; the not null columns"
function _addPKcolumns(list, table){
    var pk = table.getPK();

    if (pk !== null) {
        _toStream(pk.getColumns())
            .filter(function (col) { return !list.contains(col); })
            .forEach(function (col) {
                // in fact don't need this check,
                // because PK columns are processed first
                list.add(col);
            });
    }
}

function _addFKcolumns(list, fkeys){
    _toStream(fkeys).forEach(function (fkey) {
        _toStream(fkey.getColumns())
            .filter(function (col) { return !list.contains(col); })
            .forEach(function (col) { list.add(col); });
    });
}

//adds mandatory or optional columns to list depending on mandatory parameter
function _addMandatoryOptColumns(list, cols, mand){
    _toStream(cols)
        .filter(function (col) {
            return col.isMandatory() === mand && !list.contains(col);
        })
        .forEach(function (col) { list.add(col); });
}

function _setColumnsOrder(table) {
    var where = "setColumnsOrder";
    var list = new java.util.ArrayList();
    var cols = table.getElements();

    _trace(where, table);

    // add PK columns to list
    _addPKcolumns(list, table);
    // add FK columns to list
    _addFKcolumns(list, table.getFKAssociations());
    // add mandatory columns
    _addMandatoryOptColumns(list, cols, true);
    // add optional columns
    _addMandatoryOptColumns(list, cols, false);
    //use list to reorder columns
    list.forEach(function (col, n) {
        table.moveToIndex(col, n);
    });

    // prevent reordering from engineering, can be changed with UI
    table.setAllowColumnReorder(false);
    _setDirty(where, table);
}

// Custom Transformation Script:
// Columns order
function setColumnsOrder(model) {
    _toStream(model.getTableSet()).forEach(function (table) {
        _setColumnsOrder(table);
    });
}

function _canApplyStandards(where, object) {
    var canApplyStandards = object.getProperty("canApplyStandards");

    if (canApplyStandards === null || canApplyStandards.equals("")) {
        canApplyStandards = "1";
        object.setProperty("canApplyStandards", canApplyStandards);
        _setDirty(where, object);
    }

    try {
        canApplyStandards = Java.lang.Integer.parseInt(canApplyStandards);
    } catch (e) {
        canApplyStandards = 0;
    }

    return canApplyStandards !== 0;
}

// Custom Transformation Script:
// Apply standards for selected tables
function applyStandardsForSelectedTables(model) {
    var where = "applyStandardsForSelectedTables";
    var physicalTables = model.getStorageDesign().getTableProxySet();

    _getSelectedObjects(model, "Table").forEach(function (table) {
        _showObject(table);

        if (_canApplyStandards(where, table)) {
            _copyCommentsInRDBMS(table);
            _copyComments(table);
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
        } else {
            _msg("Can not transform this table " +
                 "since the dynamic property canApplyStandards is 0 (false).");
        }
    });
}
