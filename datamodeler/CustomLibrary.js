var appView = Java.type("oracle.dbtools.crest.swingui.ApplicationView");
var maxLength = 4000;

function _msg(msg) {
    appView.log(msg);
}

function _toStream(array) {
    var dummy;

    _msg("array: " + array.toString() + "; type: " + (typeof array));

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
    _msg(where +
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

function _copyCommentsInRDBMS(object) {
    _trace("Copy Comments in RDBMS to Comments (logical) - custom | logical",
           object);
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
    var preferredAbbreviation = object.getPreferredAbbreviation();

    _trace("copyPreferredAbbreviation", object);

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
    _toStream(model.getEntitySet()).forEach(function (entity) {
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

    if (!name.equals("") && !object.getName().equals(name)) {
        object.setName(name);
        object.setDirty(true);
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
    _trace("setSecurityOptions", table);
    _toStream(table.getElements()).forEach(function (column) {
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

function _setTableNamePlural(table) {
    var tableName = table.getName();

    _trace("setTableNamePlural", table);

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
    _toStream(model.getTableSet()).forEach(function (table) {
        _setTableNamePlural(table);
    });
}

function _setUseDomainConstraints(table) {
    _trace("setUseDomainConstraints", table);
    _toStream(table.getElements()).forEach(function (column) {
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
    _toStream(model.getTableSet()).forEach(function (table) {
        _setUseDomainConstraints(table);
    });
}

function _setIdentityColumn_relational(table) {
    _trace("setIdentityColumn_relational", table);
    _toStream(table.getElements())
        .filter(function (column) { return column.getName().equals("ID"); })
        .forEach(function (column) {
            column.setAutoIncrementColumn(true);
            column.setIdentityColumn(true);
            column.setAutoIncrementGenerateTrigger(false);
            column.setDirty(true);
        });
}

function _setIdentityColumn_physical(table) {
    // not conform the SQL Data Modeler 18 documentation (!)
    var clause = "IDENTITY_CLAUSE";

    _trace("setIdentityColumn_physical", table);

    _toStream(table.getColumns())
        .filter(function (column) { return column.getName().equals("ID"); })
        .forEach(function (column) {
            column.setAutoIncrementDDL(clause);
            column.setDirty(true);
        });
}

function _setIdentityColumn(relationalTable, physicalTables) {
    _trace("setIdentityColumn", relationalTable);

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

function _setTableToLowerCase(table) {
    var name = table.getName().toLowerCase();

    _trace("setTableToLowerCase", table);

    table.setName(name);

    _toStream(table.getElements()).forEach(function (column) {
        name = column.getName().toLowerCase();

        column.setName(name);
    });

    _toStream(table.getKeys()).forEach(function (key) {
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
    _toStream(model.getTableSet()).forEach(function (table) {
        _setTableToLowerCase(table);
    });
}

function _setTableAbbreviationToColumn(table) {
    var abbr = table.getAbbreviation()+"_";

    _trace("setTableAbbreviationToColumn", table);

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
function setTableAbbreviationToColumn(model) {
    _toStream(model.getTableSet()).forEach()(function (table) {
        _setTableAbbreviationToColumn(table);
    });
}

function _setRemoveTableAbbrFromColumn(table) {
    var abbr = table.getAbbreviation()+"_";
    var count = table.getAbbreviation().length()+1;

    _trace("setRemoveTableAbbrFromColumn", table);

    if (count !== 1) {
        _toStream(table.getElements()).forEach(function (column) {
            var cname = column.getName();
            if (cname.startsWith(abbr)) {
                column.setName(cname.substring(count));
                table.setDirty(true);
            }
        });
    }
}

// Custom Transformation Script:
// Remove Table abbr from column
function setRemoveTableAbbrFromColumn(model) {
    _toStream(model.getTableSet()).forEach(function (table) {
        setRemoveTableAbbrFromColumn(table);
    });
}

function _setTableToUpperCase(table) {
    var name = table.getName().toUpperCase();

    _trace("setTableToUpperCase", table);

    table.setName(name);

    _toStream(table.getElements()).forEach(function (column) {
        name = column.getName().toUpperCase();
        column.setName(name);
    });

    table.setDirty(true);

    _toStream(table.getKeys()).forEach(function (key) {
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
    try {
        _toStream(model.getTableSet()).forEach(function (table) {
            _setTableToUpperCase(table);
        });
    } catch (e) {
        _msg(e.stack);
        throw(e);
    }
}

function _copyComments(object) {
    _trace("copyComments", object);
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
    var columns;
    var newIndex;

    _trace("createIndexOnFK", table);

    _toStream(table.getKeys())
        .filter(function (index) { return index.isFK(); })
        .forEach(function (index) {
            columns = index.getColumns();
            if (columns.length > 0) {
                newIndex = _getIndex(table, columns);
                if (newIndex === null) {
                    newIndex = table.createIndex();
                    table.setDirty(true);
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
    var list = new java.util.ArrayList();
    var cols = table.getElements();

    _trace("setColumnsOrder", table);

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
    table.setDirty(true);
}

// Custom Transformation Script:
// Columns order
function setColumnsOrder(model) {
    _toStream(model.getTableSet()).forEach(function (table) {
        _setColumnsOrder(table);
    });
}

// Custom Transformation Script:
// Apply standards for selected tables
function applyStandardsForSelectedTables(model) {
    var physicalTables = model.getStorageDesign().getTableProxySet();

    _getSelectedObjects(model, "Table").forEach(function (table) {
        _showObject(table);

        _copyCommentsInRDBMS(table);
        _copyComments(table);
        _setSecurityOptions(table);
        _setTableToUpperCase(table);
        _setTableNamePlural(table);
        _setUseDomainConstraints(table);
        _setIdentityColumn(table, physicalTables);
        // _setTableToLowerCase(table);
        // _setTableAbbreviationToColumn(table);
        // _setRemoveTableAbbrFromColumn(table);
        _createIndexOnFK(table);
        _setColumnsOrder(table);
    });
}
