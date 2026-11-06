\set ON_ERROR_STOP on
\encoding UTF8
BEGIN;
SELECT pg_advisory_xact_lock(101001);

CREATE VIEW etl.CustomerParsed AS
WITH Clean AS(SELECT *,NULLIF(trim(CustomerCode),'') AS CustomerCodeClean,NULLIF(upper(trim(CustomerName)),'') AS CustomerNameClean,
 count(*) OVER(PARTITION BY trim(CustomerCode)) AS CodeCount,replace(NULLIF(trim(CustomerAmountRaw),''),',','.') AS AmountClean,
 NULLIF(trim(SalesDateRaw),'') AS DateClean FROM stg.CustomerRaw),
Parsed AS(SELECT *,CASE WHEN pg_input_is_valid(AmountClean,'numeric(18,2)')
 AND lower(AmountClean) NOT IN('nan','infinity','+infinity','-infinity','inf','+inf','-inf') THEN AmountClean::numeric(18,2) END AS AmountParsed,
 CASE WHEN DateClean ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND pg_input_is_valid(DateClean,'date') THEN DateClean::date END AS SalesDateParsed FROM Clean)
SELECT *,concat(CASE WHEN CustomerCodeClean IS NULL THEN 'Nedostaje CustomerCode. ' ELSE '' END,
 CASE WHEN CustomerNameClean IS NULL THEN 'Nedostaje CustomerName. ' ELSE '' END,
 CASE WHEN CodeCount>1 THEN 'Duplikat CustomerCode u batchu. ' ELSE '' END,
 CASE WHEN AmountParsed IS NULL THEN 'CustomerAmount nije broj. ' ELSE '' END,
 CASE WHEN AmountParsed<0 THEN 'CustomerAmount ne smije biti negativan. ' ELSE '' END,
 CASE WHEN SalesDateParsed IS NULL THEN 'SalesDate nije ispravan datum. ' ELSE '' END) AS ErrorReason FROM Parsed;

SELECT * FROM etl.CustomerParsed ORDER BY RawId;
INSERT INTO dbo.ImportError(SourceFileName,CustomerCode,CustomerName,CustomerAmountRaw,SalesDateRaw,ErrorReason)
 SELECT SourceFileName,CustomerCodeClean,CustomerName,CustomerAmountRaw,SalesDateRaw,ErrorReason FROM etl.CustomerParsed WHERE ErrorReason<>'' ORDER BY RawId;
INSERT INTO dbo.Customer(CustomerCode,CustomerName,CustomerAmount,SalesDate,SourceFileName)
 SELECT CustomerCodeClean,CustomerNameClean,AmountParsed,SalesDateParsed,SourceFileName FROM etl.CustomerParsed p
 WHERE ErrorReason='' AND NOT EXISTS(SELECT 1 FROM dbo.Customer c WHERE c.CustomerCode=p.CustomerCodeClean) ORDER BY RawId;

INSERT INTO etl.ExecutionHistory(ScriptName,DocumentSection,Description,CustomerCount,ErrorCount) SELECT '03_json_validation.sql','5 nakon JSON-a','Rucna JSON transformacija validacija prijenos',count(*),(SELECT count(*) FROM dbo.ImportError) FROM dbo.Customer;
COMMIT;
