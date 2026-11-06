\set ON_ERROR_STOP on
\encoding UTF8
BEGIN;
SELECT pg_advisory_xact_lock(101001);

SELECT * FROM etl.CustomerParsed ORDER BY RawId;
INSERT INTO dbo.ImportError(SourceFileName,CustomerCode,CustomerName,CustomerAmountRaw,SalesDateRaw,ErrorReason)
 SELECT SourceFileName,CustomerCodeClean,CustomerName,CustomerAmountRaw,SalesDateRaw,ErrorReason FROM etl.CustomerParsed WHERE ErrorReason<>'' ORDER BY RawId;
INSERT INTO dbo.Customer(CustomerCode,CustomerName,CustomerAmount,SalesDate,SourceFileName)
 SELECT CustomerCodeClean,CustomerNameClean,AmountParsed,SalesDateParsed,SourceFileName FROM etl.CustomerParsed p
 WHERE ErrorReason='' AND NOT EXISTS(SELECT 1 FROM dbo.Customer c WHERE c.CustomerCode=p.CustomerCodeClean) ORDER BY RawId;

INSERT INTO etl.ExecutionHistory(ScriptName,DocumentSection,Description,CustomerCount,ErrorCount) SELECT '09_csv_validation.sql','5 nakon CSV-a','Rucna CSV validacija odbija stvarne greske',count(*),(SELECT count(*) FROM dbo.ImportError) FROM dbo.Customer;
COMMIT;
