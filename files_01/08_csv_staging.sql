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

INSERT INTO etl.ExecutionHistory(ScriptName,DocumentSection,Description,CustomerCount,ErrorCount) SELECT '08_csv_staging.sql','4','Zatim CSV Customer3 bez izmjena',count(*),(SELECT count(*) FROM dbo.ImportError) FROM dbo.Customer;
COMMIT;
