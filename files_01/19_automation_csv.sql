\set ON_ERROR_STOP on
\encoding UTF8
BEGIN;
SELECT pg_advisory_xact_lock(101001);

CREATE TEMP TABLE CsvInput(CustomerCode text,CustomerName text,CustomerAmountRaw text,SalesDateRaw text) ON COMMIT DROP;
COPY CsvInput FROM 'D:/tatjana_labovi/files_01/Customer3.csv' WITH(FORMAT CSV,HEADER true,DELIMITER ';',QUOTE '"',ENCODING 'UTF8');
TRUNCATE stg.CustomerRaw;
INSERT INTO stg.CustomerRaw(SourceFileName,SourceFormat,CustomerCode,CustomerName,CustomerAmountRaw,SalesDateRaw)
 SELECT 'Customer3.csv','CSV',CustomerCode,CustomerName,CustomerAmountRaw,replace(SalesDateRaw,chr(13),'') FROM CsvInput;
SELECT * FROM stg.CustomerRaw ORDER BY RawId;

CALL etl.usp_ValidateAndLoadCustomers();
SELECT * FROM stg.CustomerRaw ORDER BY RawId;
SELECT * FROM dbo.Customer ORDER BY CustomerId;
SELECT * FROM dbo.ImportError ORDER BY ErrorId;
SELECT * FROM dbo.ImportLog ORDER BY ImportLogId;
INSERT INTO etl.ExecutionHistory(ScriptName,DocumentSection,Description,CustomerCount,ErrorCount) SELECT '19_automation_csv.sql','8 Automatizacija','Provjera CSV skripte prije rasporeda',count(*),(SELECT count(*) FROM dbo.ImportError) FROM dbo.Customer;
COMMIT;
