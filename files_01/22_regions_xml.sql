\set ON_ERROR_STOP on
\encoding UTF8
BEGIN;
SELECT pg_advisory_xact_lock(101001);

TRUNCATE stg.CroatiaRegionRaw;
INSERT INTO stg.CroatiaRegionRaw(SourceFileName,SourceFormat,Region,AdministrativeCenter)
 SELECT 'CroatiaRegions.xml','XML',t.* FROM XMLTABLE('/regions/region' PASSING XMLPARSE(DOCUMENT convert_from(pg_read_binary_file('D:/tatjana_labovi/files_01/CroatiaRegions.xml'),'UTF8'))
 COLUMNS Region text PATH 'Region',AdministrativeCenter text PATH 'AdministrativeCenter') t;

SELECT * FROM stg.CroatiaRegionRaw ORDER BY RawId;
SELECT * FROM etl.RegionParsed ORDER BY RawId;
INSERT INTO dbo.CroatiaRegionImportError(SourceFileName,Region,AdministrativeCenter,ErrorReason)
 SELECT SourceFileName,Region,AdministrativeCenter,ErrorReason FROM etl.RegionParsed WHERE ErrorReason<>'';
INSERT INTO dbo.CroatiaRegion(Region,AdministrativeCenter,SourceFileName)
 SELECT RegionClean,CenterClean,SourceFileName FROM etl.RegionParsed WHERE ErrorReason='' ORDER BY RegionClean ON CONFLICT DO NOTHING;
SELECT * FROM dbo.CroatiaRegion ORDER BY RegionId;

DO $test$ BEGIN
 IF (SELECT count(*) FROM stg.CroatiaRegionRaw)<>21 OR (SELECT count(*) FROM dbo.CroatiaRegion)<>21
 OR EXISTS(SELECT 1 FROM stg.CroatiaRegionRaw s FULL JOIN dbo.CroatiaRegion r ON s.Region=r.Region AND s.AdministrativeCenter=r.AdministrativeCenter WHERE s.RawId IS NULL OR r.RegionId IS NULL)
 THEN RAISE EXCEPTION 'JSON i XML zupanije nisu jednake'; END IF;
END $test$;
SELECT 'JSON/XML: svih 21 zapisa jednako' AS Comparison;

INSERT INTO etl.ExecutionHistory(ScriptName,DocumentSection,Description,CustomerCount,ErrorCount) SELECT '22_regions_xml.sql','Import zupanija XML','Zatim XML kroz staging i usporedba s JSON-om',count(*),(SELECT count(*) FROM dbo.ImportError) FROM dbo.Customer;
COMMIT;
