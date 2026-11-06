\set ON_ERROR_STOP on
\encoding UTF8
BEGIN;
SELECT pg_advisory_xact_lock(101001);

CREATE TABLE stg.CroatiaRegionRaw(RawId bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,SourceFileName text NOT NULL,SourceFormat text NOT NULL,Region text,AdministrativeCenter text,LoadedAt timestamp NOT NULL DEFAULT clock_timestamp());
CREATE TABLE dbo.CroatiaRegion(RegionId int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,Region text NOT NULL UNIQUE CHECK(trim(Region)<>''),AdministrativeCenter text NOT NULL CHECK(trim(AdministrativeCenter)<>''),SourceFileName text NOT NULL,LoadedAt timestamp NOT NULL DEFAULT clock_timestamp());
CREATE UNIQUE INDEX uq_region_normalized ON dbo.CroatiaRegion(lower(trim(Region)));
CREATE TABLE dbo.CroatiaRegionImportError(ErrorId bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,SourceFileName text,Region text,AdministrativeCenter text,ErrorReason text NOT NULL,LoggedAt timestamp NOT NULL DEFAULT clock_timestamp());
CREATE VIEW etl.RegionParsed AS WITH c AS(SELECT *,NULLIF(trim(Region),'') AS RegionClean,NULLIF(trim(AdministrativeCenter),'') AS CenterClean,
 count(*) OVER(PARTITION BY lower(trim(Region))) AS RegionCount FROM stg.CroatiaRegionRaw)
 SELECT *,concat(CASE WHEN RegionClean IS NULL THEN 'Nedostaje zupanija. ' ELSE '' END,CASE WHEN CenterClean IS NULL THEN 'Nedostaje srediste. ' ELSE '' END,
 CASE WHEN RegionCount>1 THEN 'Duplikat zupanije. ' ELSE '' END) AS ErrorReason FROM c;

INSERT INTO stg.CroatiaRegionRaw(SourceFileName,SourceFormat,Region,AdministrativeCenter)
 SELECT 'CroatiaRegions.json','JSON',v->>'Region',v->>'AdministrativeCenter' FROM jsonb_array_elements(ltrim(convert_from(pg_read_binary_file('D:/tatjana_labovi/files_01/CroatiaRegions.json'),'UTF8'),chr(65279))::jsonb) v;

SELECT * FROM stg.CroatiaRegionRaw ORDER BY RawId;
SELECT * FROM etl.RegionParsed ORDER BY RawId;
INSERT INTO dbo.CroatiaRegionImportError(SourceFileName,Region,AdministrativeCenter,ErrorReason)
 SELECT SourceFileName,Region,AdministrativeCenter,ErrorReason FROM etl.RegionParsed WHERE ErrorReason<>'';
INSERT INTO dbo.CroatiaRegion(Region,AdministrativeCenter,SourceFileName)
 SELECT RegionClean,CenterClean,SourceFileName FROM etl.RegionParsed WHERE ErrorReason='' ORDER BY RegionClean ON CONFLICT DO NOTHING;
SELECT * FROM dbo.CroatiaRegion ORDER BY RegionId;

INSERT INTO etl.ExecutionHistory(ScriptName,DocumentSection,Description,CustomerCount,ErrorCount) SELECT '21_regions_json.sql','Import zupanija JSON','Najprije JSON kroz zaseban staging',count(*),(SELECT count(*) FROM dbo.ImportError) FROM dbo.Customer;
COMMIT;
