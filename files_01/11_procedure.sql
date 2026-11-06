\set ON_ERROR_STOP on
\encoding UTF8
BEGIN;
SELECT pg_advisory_xact_lock(101001);

CREATE PROCEDURE etl.usp_ValidateAndLoadCustomers() LANGUAGE plpgsql AS $proc$
DECLARE s record; id bigint; n int; ins int; rej int; msg text;
BEGIN
 PERFORM pg_advisory_xact_lock(101001);
 SELECT count(*) INTO n FROM stg.CustomerRaw;
 IF n=0 THEN RAISE EXCEPTION 'Staging je prazan'; END IF;
 IF (SELECT count(*) FROM(SELECT DISTINCT SourceFileName,SourceFormat FROM stg.CustomerRaw) q)<>1
 THEN RAISE EXCEPTION 'Staging mora sadrzavati jedan izvor'; END IF;
 SELECT SourceFileName,SourceFormat INTO s FROM stg.CustomerRaw LIMIT 1;
 INSERT INTO dbo.ImportLog(SourceFileName,SourceFormat,StartedAt,RowsRead,Status)
 VALUES(s.SourceFileName,s.SourceFormat,clock_timestamp(),n,'RUNNING') RETURNING ImportLogId INTO id;
 BEGIN
  INSERT INTO dbo.ImportError(SourceFileName,CustomerCode,CustomerName,CustomerAmountRaw,SalesDateRaw,ErrorReason)
   SELECT SourceFileName,CustomerCodeClean,CustomerName,CustomerAmountRaw,SalesDateRaw,ErrorReason FROM etl.CustomerParsed WHERE ErrorReason<>'' ORDER BY RawId;
  GET DIAGNOSTICS rej=ROW_COUNT;
  INSERT INTO dbo.Customer(CustomerCode,CustomerName,CustomerAmount,SalesDate,SourceFileName)
   SELECT CustomerCodeClean,CustomerNameClean,AmountParsed,SalesDateParsed,SourceFileName FROM etl.CustomerParsed WHERE ErrorReason='' ORDER BY RawId
   ON CONFLICT(CustomerCode) DO NOTHING;
  GET DIAGNOSTICS ins=ROW_COUNT;
  UPDATE dbo.ImportLog SET FinishedAt=clock_timestamp(),RowsInserted=ins,RowsRejected=rej,RowsSkipped=n-rej-ins,Status='SUCCESS' WHERE ImportLogId=id;
 EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS msg=MESSAGE_TEXT;
  UPDATE dbo.ImportLog SET FinishedAt=clock_timestamp(),RowsInserted=0,RowsRejected=0,RowsSkipped=0,Status='FAILED',ErrorMessage=msg WHERE ImportLogId=id;
  RAISE WARNING 'ETL FAILED: %',msg;
 END;
END $proc$;
CALL etl.usp_ValidateAndLoadCustomers();
SELECT * FROM dbo.ImportLog ORDER BY ImportLogId;

INSERT INTO etl.ExecutionHistory(ScriptName,DocumentSection,Description,CustomerCount,ErrorCount) SELECT '11_procedure.sql','7','Zamjena rucnih koraka procedurom',count(*),(SELECT count(*) FROM dbo.ImportError) FROM dbo.Customer;
COMMIT;
