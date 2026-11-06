\set ON_ERROR_STOP on
\encoding UTF8
BEGIN;
SELECT pg_advisory_xact_lock(101001);

CREATE SCHEMA stg; CREATE SCHEMA dbo; CREATE SCHEMA etl;
CREATE TABLE stg.CustomerRaw(RawId bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 SourceFileName varchar(260) NOT NULL,SourceFormat varchar(10) NOT NULL,
 CustomerCode varchar(50),CustomerName varchar(100),CustomerAmountRaw varchar(50),SalesDateRaw varchar(50),
 LoadedAt timestamp NOT NULL DEFAULT clock_timestamp());
CREATE TABLE dbo.Customer(CustomerId int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 CustomerCode varchar(50) NOT NULL UNIQUE CHECK(trim(CustomerCode)<>''),CustomerName varchar(100) NOT NULL CHECK(trim(CustomerName)<>''),
 CustomerAmount numeric(18,2) NOT NULL CHECK(CustomerAmount>=0 AND CustomerAmount<>'NaN'::numeric),
 SalesDate date NOT NULL,SourceFileName varchar(260) NOT NULL,LoadedAt timestamp NOT NULL DEFAULT clock_timestamp());
CREATE TABLE dbo.ImportError(ErrorId bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 SourceFileName varchar(260),CustomerCode varchar(50),CustomerName varchar(100),CustomerAmountRaw varchar(50),SalesDateRaw varchar(50),
 ErrorReason varchar(500) NOT NULL,LoggedAt timestamp NOT NULL DEFAULT clock_timestamp());
CREATE TABLE dbo.ImportLog(ImportLogId bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 SourceFileName varchar(260) NOT NULL,SourceFormat varchar(10) NOT NULL,StartedAt timestamp NOT NULL,FinishedAt timestamp,
 RowsRead int,RowsInserted int,RowsRejected int,RowsSkipped int,Status varchar(20) NOT NULL,ErrorMessage text);
CREATE TABLE etl.ExecutionHistory(StepId bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 ScriptName text NOT NULL,DocumentSection text NOT NULL,Description text NOT NULL,
 CompletedAt timestamptz NOT NULL DEFAULT clock_timestamp(),CustomerCount int NOT NULL,ErrorCount int NOT NULL);

INSERT INTO etl.ExecutionHistory(ScriptName,DocumentSection,Description,CustomerCount,ErrorCount) SELECT '01_structure.sql','1','Kreiranje baze i strukture',count(*),(SELECT count(*) FROM dbo.ImportError) FROM dbo.Customer;
COMMIT;
