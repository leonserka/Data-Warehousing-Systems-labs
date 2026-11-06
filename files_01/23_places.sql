\set ON_ERROR_STOP on
\encoding UTF8
BEGIN;
SELECT pg_advisory_xact_lock(101001);

CREATE TABLE stg.CroatiaPlaceRaw(RawId bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,SourceFileName text NOT NULL,PlaceName text,MunicipalityName text,MunicipalityType text,RegionName text,LoadedAt timestamp NOT NULL DEFAULT clock_timestamp());
CREATE TABLE dbo.CroatiaPlace(PlaceId int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,PlaceName text NOT NULL CHECK(trim(PlaceName)<>''),MunicipalityName text NOT NULL CHECK(trim(MunicipalityName)<>''),MunicipalityType text NOT NULL CHECK(MunicipalityType IN('Grad','Općina')),RegionId int NOT NULL REFERENCES dbo.CroatiaRegion(RegionId),SourceFileName text NOT NULL,LoadedAt timestamp NOT NULL DEFAULT clock_timestamp(),UNIQUE(RegionId,MunicipalityName,PlaceName));
CREATE TABLE dbo.CroatiaPlaceImportError(ErrorId bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,BatchId uuid NOT NULL,SourceFileName text NOT NULL,PlaceName text,MunicipalityName text,MunicipalityType text,RegionName text,ErrorReason text NOT NULL,LoggedAt timestamp NOT NULL DEFAULT clock_timestamp());
CREATE TEMP TABLE PlaceBatch ON COMMIT DROP AS SELECT gen_random_uuid() AS BatchId;
DO $check$ BEGIN IF NOT EXISTS(SELECT 1 FROM dbo.CroatiaRegion) THEN RAISE EXCEPTION 'Najprije ucitaj zupanije'; END IF; END $check$;
TRUNCATE stg.CroatiaPlaceRaw;
DO $load$ DECLARE j jsonb; BEGIN
 j:=ltrim(convert_from(pg_read_binary_file('D:/tatjana_labovi/files_01/CroatiaPlaces.json'),'UTF8'),chr(65279))::jsonb;
 IF jsonb_typeof(j) IS DISTINCT FROM 'array' THEN RAISE EXCEPTION 'Ocekuje se JSON niz naselja'; END IF;
 IF jsonb_array_length(j)=0 THEN RAISE EXCEPTION 'Nema naselja'; END IF;
 INSERT INTO stg.CroatiaPlaceRaw(SourceFileName,PlaceName,MunicipalityName,MunicipalityType,RegionName)
 SELECT 'CroatiaPlaces.json',v->>'PlaceName',v->>'MunicipalityName',v->>'MunicipalityType',v->>'RegionName' FROM jsonb_array_elements(j) v;
END $load$;
SELECT * FROM stg.CroatiaPlaceRaw ORDER BY RawId LIMIT 50;
CREATE TEMP TABLE PreparedPlaces ON COMMIT DROP AS
WITH Clean AS(SELECT SourceFileName,NULLIF(trim(PlaceName),'') AS PlaceName,NULLIF(trim(MunicipalityName),'') AS MunicipalityName,NULLIF(trim(MunicipalityType),'') AS MunicipalityType,NULLIF(trim(RegionName),'') AS RegionName FROM stg.CroatiaPlaceRaw),
Counted AS(SELECT *,count(*) OVER(PARTITION BY RegionName,MunicipalityName,PlaceName) AS PlaceCount FROM Clean)
SELECT p.*,r.RegionId,concat(CASE WHEN PlaceName IS NULL THEN 'Nedostaje naselje. ' ELSE '' END,
 CASE WHEN MunicipalityName IS NULL THEN 'Nedostaje grad/opcina. ' ELSE '' END,
 CASE WHEN MunicipalityType IS NULL OR MunicipalityType NOT IN('Grad','Općina') THEN 'Vrsta mora biti Grad ili Općina. ' ELSE '' END,
 CASE WHEN RegionName IS NULL THEN 'Nedostaje zupanija. ' ELSE '' END,
 CASE WHEN RegionName IS NOT NULL AND r.MatchCount=0 THEN 'Zupanija nije pronadjena. ' ELSE '' END,
 CASE WHEN r.MatchCount>1 THEN 'Zupanija nije jedinstvena. ' ELSE '' END,
 CASE WHEN PlaceCount>1 THEN 'Duplikat naselja. ' ELSE '' END) AS ErrorReason
FROM Counted p CROSS JOIN LATERAL(SELECT min(RegionId) AS RegionId,count(*) AS MatchCount FROM dbo.CroatiaRegion r WHERE lower(trim(r.Region))=lower(p.RegionName)) r;
INSERT INTO dbo.CroatiaPlaceImportError(BatchId,SourceFileName,PlaceName,MunicipalityName,MunicipalityType,RegionName,ErrorReason)
 SELECT b.BatchId,p.SourceFileName,p.PlaceName,p.MunicipalityName,p.MunicipalityType,p.RegionName,p.ErrorReason FROM PreparedPlaces p CROSS JOIN PlaceBatch b WHERE ErrorReason<>'';
WITH inserted AS(INSERT INTO dbo.CroatiaPlace(PlaceName,MunicipalityName,MunicipalityType,RegionId,SourceFileName)
 SELECT PlaceName,MunicipalityName,MunicipalityType,RegionId,SourceFileName FROM PreparedPlaces WHERE ErrorReason='' ON CONFLICT DO NOTHING RETURNING *)
SELECT (SELECT count(*) FROM PreparedPlaces) AS RowsRead,count(*) AS RowsInserted,(SELECT count(*) FROM PreparedPlaces WHERE ErrorReason<>'') AS RowsRejected FROM inserted;
SELECT r.Region,count(p.PlaceId) AS PlaceCount FROM dbo.CroatiaRegion r LEFT JOIN dbo.CroatiaPlace p USING(RegionId) GROUP BY r.Region ORDER BY r.Region;
SELECT p.*,r.Region FROM dbo.CroatiaPlace p JOIN dbo.CroatiaRegion r USING(RegionId) ORDER BY r.Region,p.MunicipalityName,p.PlaceName LIMIT 100;
SELECT * FROM dbo.CroatiaPlaceImportError ORDER BY ErrorId;

INSERT INTO etl.ExecutionHistory(ScriptName,DocumentSection,Description,CustomerCount,ErrorCount) SELECT '23_places.sql','Import mjesta','Uvoz naselja tek nakon JSON i XML zupanija',count(*),(SELECT count(*) FROM dbo.ImportError) FROM dbo.Customer;
COMMIT;
