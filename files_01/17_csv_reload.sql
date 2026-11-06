-- Prije ovog koraka urediti isti Customer3.csv: C003 iznos 80.00 i datum 2026-03-17; C004 iznos 3.10 i datum 2026-03-18.
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
INSERT INTO etl.ExecutionHistory(ScriptName,DocumentSection,Description,CustomerCount,ErrorCount) SELECT '17_csv_reload.sql','8','Ponovljeni uvoz nakon ispravka istog CSV izvora',count(*),(SELECT count(*) FROM dbo.ImportError) FROM dbo.Customer;
COMMIT;
