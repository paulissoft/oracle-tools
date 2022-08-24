var appView = Java.type("oracle.dbtools.crest.swingui.ApplicationView");
var maxLength = 4000;

function _msg(msg) {
    appView.log(msg);
}

function _getSelectedObjects(model, objectType) {
    var appv = model.getAppView();
    var dpv = appv.getCurrentDPV();
    var objects = [];

    _msg("Window: " + dpv);
    // check there is a diagram selected and it belongs to the same model
    if (dpv !== null && dpv.getDesignPart() === model) {
        dpv.getSelectedTopViews().forEach(function (item, index) {
            var obj = item.getModel();

            _msg("Object type: " + obj.getObjectTypeName());

            //if table then put its name in the log window
            if (objectType.equals(obj.getObjectTypeName())) {
                objects.push(obj);
            }
        });
    }
    _msg("# Objects of type " + objectType + ": " + objects.length);

    return objects;
}

function _showObject(obj) {
    _msg(arguments.callee.name +
         ": " +
         obj.getObjectTypeName() +
         " " +
         obj.getName());
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

function _copyCommentInRDBMS(object) {
    _showObject(object);
    if (object.getComment().equals("")) {
        if (!object.getCommentInRDBMS().equals("")) {
            if (object.getCommentInRDBMS().length() > maxLength) {
                object.setComment
                ( object.getCommentInRDBMS().substring(0, maxLength)
                );
            } else {
                object.setComment(object.getCommentInRDBMS());
            }
            object.setDirty(true);
        }
    }
}

// Custom Transformation Script:
// Copy Comments in RDBMS to Comments (logical) - custom | logical
function copyCommentsInRDBMS_logical(model) {
    var entities = model.getEntitySet().toArray();

    entities.forEach(function (entity, index) {
        _copyCommentInRDBMS(entity);

        entity.getElements().forEach(function (attribute) {
            _copyCommentInRDBMS(attribute);
        });

        entity.getKeys().forEach(function (key) {
            if (!key.isFK()) {
                _copyCommentInRDBMS(key);
            } else {
                _copyCommentInRDBMS(key.getFKAssociation());
            }
        });
    });
}

function _copyPreferredAbbreviation(object) {
    var preferredAbbreviation = object.getPreferredAbbreviation();

    _showObject(object);
    if (object.getShortName().equals("")) {

        if (!preferredAbbreviation.equals("")) {
            object.setShortName(preferredAbbreviation);
            object.setDirty(true);
        }
    }
}

// Custom Transformation Script:
// Copy Preferred Abbreviation to Short Name - custom | logical
function copyPreferredAbbreviation(model) {
    model.getEntitySet().toArray().forEach(function (entity) {
        _copyPreferredAbbreviation(entity);
    });
}

function _setRelationName(object,
                          sourceShortName,
                          sourceAbbreviation,
                          targetShortName,
                          targetAbbreviation) {
    var sourceName = (sourceAbbreviation.equals("") ?
                      sourceShortName :
                      sourceAbbreviation);
    var targetName = (targetAbbreviation.equals("") ?
                      targetShortName :
                      targetAbbreviation);
    var name = ((sourceName.equals("") || targetName.equals("")) ?
                "" :
                sourceName + "_" + targetName);

    _showObject(object);

    if (!name.equals("") && !object.getName().equals(name)) {
        object.setName(name);
        object.setDirty(true);
    }
}

// Custom Transformation Script:
// Set Relation Name - custom | logical
function setRelationName(model) {
    model.getRelationSet().toArray().forEach(function (relation) {
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
    model.getTableSet().toArray().forEach(function (table) {
        _copyCommentInRDBMS(table);

        table.getElements().forEach(function (column) {
            _copyCommentInRDBMS(column);
        });

        table.getKeys().forEach(function (key) {
            if (!key.isFK()) {
                _copyCommentInRDBMS(key);
            } else {
                _copyCommentInRDBMS(key.getFKAssociation());
            }
        });
    });
}

function _setSecurityOptions(table) {
    _showObject(table);

    table.getElements().forEach(function (column) {
        if (column.isContainsPII() !== true) {
            column.setContainsPII(false);
        }
        if (column.isContainsSensitiveInformation() !== true) {
            column.setContainsSensitiveInformation(false);
        }
    });
    table.setDirty(true);
}

// Custom Transformation Script:
// Set security options - custom | relational
function setSecurityOptions(model) {
    model.getTableSet().toArray().forEach(function (table) {
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

function _setTableNamePlural(table) {
    var tableName = table.getName();

    _showObject(table);

    if (tableName.endsWith("Y")) {
        // Y -> IES
        table.setName(tableName.slice(0, -1) + "IES");
        table.setDirty(true);
    } else if (tableName.endsWith("X")) {
        // X -> CES
        table.setName(tableName.slice(0, -1) + "CES");
        table.setDirty(true);
    } else if (!tableName.endsWith("S")) {
        // . -> .S
        table.setName(tableName + "S");
        table.setDirty(true);
    }
}

// Custom Transformation Script:
// Table names plural - custom | relational
function setTableNamesPlural(model) {
    model.getTableSet().toArray().forEach(function (table) {
        _setTableNamePlural(table);
    });
}

function _setUseDomainConstraints(table) {
    _showObject(table);

    table.getElements().forEach(function (column) {
        if (column.getDomain() !== null &&
            column.getDomain().getName() !== "Unknown" &&
            column.getUseDomainConstraints() !== true) {
            column.setUseDomainConstraints(true);
            table.setDirty(true);
        }
    });
}

// Custom Transformation Script:
// Set Use Domain Constraints - custom | relational
function setUseDomainConstraints(model) {
    model.getTableSet().toArray().forEach(function (table) {
        _setUseDomainConstraints(table);
    });
}

function _setIdentityColumn_relational(table) {
    _showObject(table);

    table.getElements().forEach(function (column) {
        if (column.getName().equals("ID")) {
            column.setAutoIncrementColumn(true);
            column.setIdentityColumn(true);
            column.setAutoIncrementGenerateTrigger(false);
            column.setDirty(true);
        }
    });
}

function _setIdentityColumn_physical(table) {
    // not conform the SQL Data Modeler 18 documentation (!)
    var clause = "IDENTITY_CLAUSE";

    _showObject(table);

    table.getColumns().toArray().forEach(function (column) {
        if (column.getName().equals("ID")) {
            column.setAutoIncrementDDL(clause);
            column.setDirty(true);
        }
    });
}

function _setIdentityColumn(relationalTable, physicalTables, tableNames) {
    var stop = false;

    _setIdentityColumn_relational(relationalTable);

    physicalTables.forEach(function (physicalTable) {
        if (!stop &&
            relationalTable.getName().equals(physicalTable.getName())) {
            _setIdentityColumn_physical(physicalTable);
            stop = true;
        }
    });
}

function _setIdentityColumns(relationalTables, physicalTables) {
    var tableNames = [];

    relationalTables.forEach(function (relationalTable) {
        _setIdentityColumn(relationalTable, physicalTables, tableNames);
    });
}

// Custom Transformation Script:
// Define IDENTITY clause for ID columns - custom | relational
function setIdentityColumns(model) {
    _setIdentityColumns(model.getTableSet().toArray(),
                        model.getStorageDesign().getTableProxySet().toArray());
}

// Custom Transformation Script:
// Define IDENTITY clause for selected ID columns - custom | relational
function setSelectedIdentityColumns(model) {
    _setIdentityColumns(_getSelectedObjects(model, "Table"),
                        model.getStorageDesign().getTableProxySet().toArray());
}

function _setTableToLowerCase(table) {
    var name = table.getName().toLowerCase();

    _showObject(table);

    table.setName(name);

    table.getElements().forEach(function (column) {
        name = column.getName().toLowerCase();

        column.setName(name);
    });

    table.getKeys().forEach(function (key) {
        if (!key.isFK()){
            name = key.getName().toLowerCase();
            key.setName(name);
        } else {
            name = key.getFKAssociation().getName().toLowerCase();
            key.getFKAssociation().setName(name);
            key.getFKAssociation().setDirty(true);
        }
    });

    table.setDirty(true);
}

// Custom Transformation Script:
// Tables to lower case - Rhino
function setTablesToLowerCase(model) {
    model.getTableSet().toArray().forEach(function (table) {
        _setTableToLowerCase(table);
    });
}

function _setTableAbbreviationToColumn(table) {
    var abbr = table.getAbbreviation()+"_";

    _showObject(table);

    if(abbr.length !== 1){
        table.getElements().forEach(function (column) {
            var cname = column.getName();
            if(!cname.startsWith(abbr)){
                column.setName(abbr+cname);
            }
        });
    }
}

// Custom Transformation Script:
// Table abbreviation to column
function setTableAbbreviationToColumn(model) {
    model.getTableSet().toArray().forEach()(function (table) {
        _setTableAbbreviationToColumn(table);
    });
}

function _setRemoveTableAbbrFromColumn(table) {
    var abbr = table.getAbbreviation()+"_";
    var count = table.getAbbreviation().length()+1;

    _showObject(table);

    if (count !== 1) {
        table.getElements().forEach(function (column) {
            var cname = column.getName();
            if(cname.startsWith(abbr)){
                column.setName(cname.substring(count));
                table.setDirty(true);
            }
        });
    }
}

// Custom Transformation Script:
// Remove Table abbr from column
function setRemoveTableAbbrFromColumn(model) {
    model.getTableSet().toArray().forEach(function (table) {
        setRemoveTableAbbrFromColumn(table);
    });
}

function _setTableToUpperCase(table) {
    var name = table.getName().toUpperCase();

    _showObject(table);

    table.setName(name);

    table.getElements().forEach(function (column) {
        name = column.getName().toUpperCase();
        column.setName(name);
    });

    table.setDirty(true);

    table.getKeys().forEach(function (key) {
        if (!key.isFK()) {
            name = key.getName().toUpperCase();
            key.setName(name);
        } else {
            name = key.getFKAssociation().getName().toUpperCase();
            key.getFKAssociation().setName(name);
            key.getFKAssociation().setDirty(true);
        }
    });
}

// Custom Transformation Script:
// Tables to upper case - Rhino
function setTablesToUpperCase(model) {
    model.getTableSet().toArray().forEach(function (table) {
        _setTableToUpperCase(table);
    });
}

function _copyComments(object){
    _showObject(object);
    if (object.getCommentInRDBMS().equals("")) {
        if (!object.getComment().equals("")) {
            if (object.getComment().length() > maxLength) {
                object.setCommentInRDBMS
                ( object.getComment().substring(0, maxLength)
                );
            } else {
                object.setCommentInRDBMS(object.getComment());
            }
            object.setDirty(true);
        }
    }
}

// Custom Transformation Script:
// Copy Comments to Comments in RDBMS
function copyComments(model) {
    model.getTableSet().toArray().forEach(function (table) {
        _copyComments(table);
        table.getElements().forEach(function (column) {
            _copyComments(column);
        });
        table.getKeys().forEach(function (key) {
            if (!key.isFK()) {
                _copyComments(key);
            } else {
                _copyComments(key.getFKAssociation());
            }
        });
    });
}

function _getIndex(tab, cols) {
    var returnIndex = null;

    tab.getKeys().forEach(function (index) {
        if (returnIndex === null &&
            !(index.isPK() || index.isUnique()) &&
            !index.isFK() &&
            index.isIndexForColumns(cols)) {
            returnIndex = index;
        }
    });

    return returnIndex;
}

function _createIndexOnFK(table) {
    var columns;
    var newIndex;

    _copyComments(table);

    table.getKeys().forEach(function (index) {
        if (index.isFK()) {
            columns = index.getColumns();
            if (columns.length > 0) {
                newIndex = _getIndex(table, columns);
                if (newIndex === null) {
                    newIndex = table.createIndex();
                    table.setDirty(true);
                    columns.forEach(function (column) {
                        newIndex.add(column);
                    });
                }
            }
        }
    });
}

// Custom Transformation Script:
// Create index on FK
function createIndexOnFK(model) {
    model.getTableSet().toArray().forEach(function (table) {
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
        pk.getColumns().forEach(function (col) {
            // in fact don't need this check,
            // because PK columns are processed first
            if (!list.contains(col)) {
                list.add(col);
            }
        });
    }
}

function _addFKcolumns(list, fkeys){
    fkeys.forEach(function (fkey) {
        fkey.getColumns().forEach(function (col) {
            if (!list.contains(col)) {
                list.add(col);
            }
        });
    });
}

//adds mandatory or optional columns to list depending on mandatory parameter
function _addMandatoryOptColumns(list, cols, mand){
    cols.forEach(function (col) {
        if (col.isMandatory() === mand && !list.contains(col)) {
            list.add(col);
        }
    });
}

function _setColumnsOrder(table) {
    var list = new java.util.ArrayList();
    var cols = table.getElements();

    _copyComments(table);

    // add PK columns to list
    _addPKcolumns(list, table);
    // add FK columns to list
    _addFKcolumns(list, table.getFKAssociations());
    // add mandatory columns
    _addMandatoryOptColumns(list, cols, true);
    // add optional columns
    _addMandatoryOptColumns(list, cols, false);
    //use list to reorder columns
    list.toArray().forEach(function (col, n) {
        table.moveToIndex(col, n);
    });

    // prevent reordering from engineering, can be changed with UI
    table.setAllowColumnReorder(false);
    table.setDirty(true);
}

// Custom Transformation Script:
// Columns order
function setColumnsOrder(model) {
    model.getTableSet().toArray().forEach(function (table) {
        _setColumnsOrder(table);
    });
}

// Custom Transformation Script:
// Apply standards for selected tables
function applyStandardsForSelectedTables(model) {
    _getSelectedObjects(model, "Table").forEach(function (table) {
        _copyCommentInRDBMS(table);
        _copyPreferredAbbreviation(table);
        _setSecurityOptions(table);
        _setTableNamePlural(table);
        _setUseDomainConstraints(table);
        _setIdentityColumn(table);
    });
}
