\set ON_ERROR_STOP on
\encoding UTF8
BEGIN;
SELECT pg_advisory_xact_lock(101001);
SELECT * FROM stg.CustomerRaw ORDER BY RawId;
SELECT * FROM dbo.Customer ORDER BY CustomerId;
SELECT * FROM dbo.ImportError ORDER BY ErrorId;
SELECT * FROM dbo.ImportLog ORDER BY ImportLogId;
INSERT INTO etl.ExecutionHistory(ScriptName,DocumentSection,Description,CustomerCount,ErrorCount) SELECT '07_xml_results.sql','6 nakon XML-a','Pregled XML rezultata prije CSV-a',count(*),(SELECT count(*) FROM dbo.ImportError) FROM dbo.Customer;
COMMIT;
