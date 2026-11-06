\set ON_ERROR_STOP on
\encoding UTF8
BEGIN;
SELECT pg_advisory_xact_lock(101001);

TRUNCATE stg.CustomerRaw;
DO $load$ DECLARE j jsonb; BEGIN
 j:=ltrim(convert_from(pg_read_binary_file('D:/tatjana_labovi/files_01/Customer1.json'),'UTF8'),chr(65279))::jsonb;
 IF jsonb_typeof(j) IS DISTINCT FROM 'array' THEN RAISE EXCEPTION 'Ocekuje se JSON niz'; END IF;
 IF jsonb_array_length(j)=0 THEN RAISE EXCEPTION 'Prazan JSON niz'; END IF;
 INSERT INTO stg.CustomerRaw(SourceFileName,SourceFormat,CustomerCode,CustomerName,CustomerAmountRaw,SalesDateRaw)
 SELECT 'Customer1.json','JSON',v->>'CustomerCode',v->>'CustomerName',v->>'CustomerAmount',v->>'SalesDate' FROM jsonb_array_elements(j) v;
END $load$;
SELECT * FROM stg.CustomerRaw ORDER BY RawId;

CALL etl.usp_ValidateAndLoadCustomers();
SELECT * FROM stg.CustomerRaw ORDER BY RawId;
SELECT * FROM dbo.Customer ORDER BY CustomerId;
SELECT * FROM dbo.ImportError ORDER BY ErrorId;
SELECT * FROM dbo.ImportLog ORDER BY ImportLogId;
INSERT INTO etl.ExecutionHistory(ScriptName,DocumentSection,Description,CustomerCount,ErrorCount) SELECT '18_automation_json.sql','8 Automatizacija','Provjera JSON skripte prije rasporeda',count(*),(SELECT count(*) FROM dbo.ImportError) FROM dbo.Customer;
COMMIT;
