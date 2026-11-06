\set ON_ERROR_STOP on
\encoding UTF8
BEGIN;
SELECT pg_advisory_xact_lock(101001);

TRUNCATE stg.CustomerRaw;
DO $load$ DECLARE doc xml; BEGIN
 doc:=XMLPARSE(DOCUMENT convert_from(pg_read_binary_file('D:/tatjana_labovi/files_01/Customer4.xml'),'UTF8'));
 IF NOT xpath_exists('/Customers/Customer | /customers/customer',doc) THEN RAISE EXCEPTION 'Nema Customer elemenata'; END IF;
 INSERT INTO stg.CustomerRaw(SourceFileName,SourceFormat,CustomerCode,CustomerName,CustomerAmountRaw,SalesDateRaw)
 SELECT 'Customer4.xml','XML',t.* FROM XMLTABLE('/Customers/Customer | /customers/customer' PASSING doc
 COLUMNS CustomerCode text PATH 'CustomerCode',CustomerName text PATH 'CustomerName',CustomerAmountRaw text PATH 'CustomerAmount',SalesDateRaw text PATH 'SalesDate') t;
END $load$;
SELECT * FROM stg.CustomerRaw ORDER BY RawId;

INSERT INTO etl.ExecutionHistory(ScriptName,DocumentSection,Description,CustomerCount,ErrorCount) SELECT '05_xml_staging.sql','3','Zatim XML Customer4 bez izmjena',count(*),(SELECT count(*) FROM dbo.ImportError) FROM dbo.Customer;
COMMIT;
