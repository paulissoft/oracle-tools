CREATE OR REPLACE TRIGGER ALL_SCHEMA_OBJECTS_TRG 
BEFORE INSERT ON ALL_SCHEMA_OBJECTS 
FOR EACH ROW
BEGIN
  IF :NEW.AUDSID IS NULL
  THEN
    RAISE_APPLICATION_ERROR(-20000, 'AUDSID should not be NULL.');
  END IF;
  IF :NEW.SEQ IS NULL
  THEN
    SELECT  NVL(MAX(SEQ), 0) + 1 AS SEQ
    INTO    :NEW.SEQ
    FROM    ALL_SCHEMA_OBJECTS
    WHERE   AUDSID = :NEW.AUDSID;
  END IF;  
END;
/