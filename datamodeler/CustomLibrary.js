// Custom Transformation Script: Show selected tables - custom
var appView = Java.type('oracle.dbtools.crest.swingui.ApplicationView');

function _msg(msg) {
    appView.log(msg);
}
  
function _getSelectedObjects(model, objectType) {
    var appv = model.getAppView();
    var dpv = appv.getCurrentDPV();
    var objects = [];

    _msg('Window: ' + dpv);
    // check there is a diagram selected and it belongs to the same model
    if (dpv != null && dpv.getDesignPart() == model) {
        var tvs = dpv.getSelectedTopViews();
        
        for (var i = 0; i < tvs.length; i++) {
            var obj = tvs[i].getModel();

            _msg('Object type: ' + obj.getObjectTypeName());

            //if table then put its name in the log window
            if (objectType.equals(obj.getObjectTypeName())) {
                objects[objects.length] = obj
            }
        }
    }
    _msg('# Objects of type ' + objectType + ': ' + objects.length);

    return objects;
}

function _showObject(obj) {
    _msg(obj.getName());
}

function showSelectedTables(model) {
    _getSelectedObjects(model, "Table").forEach(_showObject);  
}

// Custom Transformation Script: Show selected tables - custom
function showSelectedEntities(model) {
    _getSelectedObjects(model, "Entity").forEach(_showObject);  
}

// Custom Transformation Script: Copy Comments in RDBMS to Comments (logical) - custom | logical
var maxLength = 4000;

function _copyCommentInRDBMS(object) {
    _showObject(object);
    if (object.getComment().equals("")) {
        if (!object.getCommentInRDBMS().equals("")) {
            if (object.getCommentInRDBMS().length() > maxLength) {
                object.setComment(object.getCommentInRDBMS().substring(0, maxLength));
            } else {
                object.setComment(object.getCommentInRDBMS());
            }
            object.setDirty(true);
        }
    }
}

function copyCommentsInRDBMS_logical(model) {
    var entities = model.getEntitySet().toArray();
    
    for (var e = 0; e < entities.length; e++) {
        var entity = entities[e];
        
        _copyCommentInRDBMS(entity);
        
        var attributes = entity.getElements();
        
        for (var i = 0; i < attributes.length; i++) {
            _copyCommentInRDBMS(attributes[i]);
        }
        
        var keys = entity.getKeys();
        
        for (var i = 0; i < keys.length; i++) {
            var key = keys[i];
            
            if (!key.isFK()) {
                _copyCommentInRDBMS(key);
            } else {
                _copyCommentInRDBMS(key.getFKAssociation());
            }
        }
    }
}

// Custom Transformation Script: Copy Preferred Abbreviation to Short Name - custom | logical
function _copyPreferredAbbreviation(object) {
    _showObject(object);
    if (object.getShortName().equals("")) {
        var preferredAbbreviation = object.getPreferredAbbreviation();
        
        if (!preferredAbbreviation.equals("")) {
            object.setShortName(preferredAbbreviation);
            object.setDirty(true);
        }
    }
}

function copyPreferredAbbreviation(model) {
    var entities = model.getEntitySet().toArray();
    
    for (var e = 0; e < entities.length; e++) {
        _copyPreferredAbbreviation(entities[e]);
    }
}

// Custom Transformation Script: Set Relation Name - custom | logical
function _setRelationName(object, sourceShortName, sourceAbbreviation, targetShortName, targetAbbreviation) {
    _showObject(object);
    
    var sourceName = (sourceAbbreviation.equals('') ? sourceShortName : sourceAbbreviation);
    var targetName = (targetAbbreviation.equals('') ? targetShortName : targetAbbreviation);
    var name = (sourceName.equals('') || targetName.equals('') ? '' : sourceName + '_' + targetName);

    if (!name.equals('') && !object.getName().equals(name)) {
        object.setName(name);
        object.setDirty(true);
    }
}

function setRelationName(model) {
    var relations = model.getRelationSet().toArray();
    
    for (var r = 0; r < relations.length; r++) {
        _setRelationName(relations[r],
                         relations[r].getSourceEntity().getShortName(),
                         relations[r].getSourceEntity().getPreferredAbbreviation(),
                         relations[r].getTargetEntity().getShortName(),
                         relations[r].getTargetEntity().getPreferredAbbreviation());
    }
}

// Custom Transformation Script: Copy Comments in RDBMS to Comments (relational) - custom | relational
function copyCommentsInRDBMS_relational(model) {
    var tables = model.getTableSet().toArray();
    
    for (var t = 0; t < tables.length; t++) {
        var table = tables[t];
        
        _copyCommentInRDBMS(table);
        
        var columns = table.getElements();
        var size = table.getElementsCollection().size();

        for (var i = 0; i < columns.length; i++) {
            _copyCommentInRDBMS(columns[i]);
        }
        
        var keys = table.getKeys();

        for (var i = 0; i < keys.length; i++) {
            var key = keys[i];

            if (!key.isFK()) {
                _copyCommentInRDBMS(key);
            } else {
                _copyCommentInRDBMS(key.getFKAssociation());
            }
        }
    }
}

// Custom Transformation Script: Set security options - custom | relational
function _setSecurityOptions(table) {
    _showObject(table);

    var cols = table.getElements();
    
    for (var c = 0; c < cols.length; c++) {
        if (cols[c].isContainsPII() != true) {
            cols[c].setContainsPII(false);
        }
        if (cols[c].isContainsSensitiveInformation() != true) {
            cols[c].setContainsSensitiveInformation(false); }
    }
    table.setDirty(true);
}

function setSecurityOptions(model) {
    var tables = model.getTableSet().toArray();
    
    for (var t = 0; t < tables.length; t++) {
        _setSecurityOptions(tables[t]);
    }
}

// Custom Transformation Script: Set selected security options - custom | relational
function setSelectedSecurityOptions(model) {
    var tables = _getSelectedObjects(model, "Table");
    
    for (var t = 0; t < tables.length; t++) {
        _setSecurityOptions(tables[t]);
    }
}

// Custom Transformation Script: Table names plural - custom | relational
function _setTableNamePlural(table) {
    _showObject(table);

    var tableName = table.getName();
    
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

function setTableNamesPlural(model) {
    var tables = model.getTableSet().toArray();
    
    for (var t = 0; t < tables.length; t++) {
        _setTableNamePlural(tables[t]);
    }
}

// Custom Transformation Script: Set Use Domain Constraints - custom | relational
function _setUseDomainConstraints(table) {
    _showObject(table);

    var cols = table.getElements();
    
    for(var c = 0; c < cols.length; c++) {
        if (cols[c].getDomain() != null && cols[c].getDomain().getName() != "Unknown" && cols[c].getUseDomainConstraints() != true) {
            cols[c].setUseDomainConstraints(true);
            table.setDirty(true);
        }
    }
}

function setUseDomainConstraints(model) {
    var tables = model.getTableSet().toArray();
    
    for (var t = 0; t < tables.length; t++) {
        _setUseDomainConstraints(tables[t]);
    }
}

// Custom Transformation Script: Define IDENTITY clause for ID columns - custom | relational
function _setIdentityColumn_relational(table) {
    _showObject(table);

    var cols = table.getElements();
    
    for (var c = 0; c < cols.length; c++) {
        if (cols[c].getName().equals("ID")) {
            cols[c].setAutoIncrementColumn(true);
            cols[c].setIdentityColumn(true);
            cols[c].setAutoIncrementGenerateTrigger(false);
            cols[c].setDirty(true);
        }
    }
}

function _setIdentityColumn_physical(table) {
    _showObject(table);

    var cols = table.getColumns().toArray();
    var clause = "IDENTITY_CLAUSE"; // not conform the SQL Data Modeler 18 documentation (!)
    
    for (var c = 0; c < cols.length; c++) {
        if (cols[c].getName().equals("ID")) {
            cols[c].setAutoIncrementDDL(clause);
            cols[c].setDirty(true);
        }
    }
}

function _setIdentityColumns(relationalTables, physicalTables) {
    var tableNames = []
    
    for (var rt = 0; rt < relationalTables.length; rt++) {
        _setIdentityColumn_relational(relationalTables[rt]);
        tableNames[tableNames.length] = relationalTables[rt].getName();
    
        for (var pt = 0; pt < physicalTables.length; pt++) {
            if (relationalTables[rt].getName().equals(physicalTables[pt].getName())) {
                _setIdentityColumn_physical(physicalTables[pt]);
                break;
            }
        }
    }
}

function setIdentityColumns(model) {
    _setIdentityColumns(model.getTableSet().toArray(),
                        model.getStorageDesign().getTableProxySet().toArray());
}

// Custom Transformation Script: Define IDENTITY clause for selected ID columns - custom | relational
function setSelectedIdentityColumns(model) {
    _setIdentityColumns(_getSelectedObjects(model, "Table"),
                        model.getStorageDesign().getTableProxySet().toArray());
}
