USE Lab;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
IF SCHEMA_ID(N'stg') IS NULL EXEC(N'CREATE SCHEMA stg;');
GO

IF OBJECT_ID(N'stg.SalesDataLab3Raw', N'U') IS NULL
BEGIN
    CREATE TABLE stg.SalesDataLab3Raw
    (
        RawId bigint IDENTITY(1,1) NOT NULL PRIMARY KEY,
        SourceFileName nvarchar(260) NOT NULL,
        SalesDateRaw nvarchar(50) NULL,
        CustomerCode nvarchar(50) NULL,
        ProductIdRaw nvarchar(50) NULL,
        PersonIdRaw nvarchar(50) NULL,
        SalesAmountRaw nvarchar(50) NULL,
        LoadedAt datetime2(0) NOT NULL DEFAULT SYSDATETIME()
    );
END;
GO

CREATE OR ALTER PROCEDURE etl.usp_LoadSalesDataFileLab3
    @FullPath nvarchar(1000),
    @FileName nvarchar(260)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    CREATE TABLE #SalesInput
    (
        SalesDateRaw nvarchar(50),
        CustomerCode nvarchar(50),
        ProductIdRaw nvarchar(50),
        PersonIdRaw nvarchar(50),
        SalesAmountRaw nvarchar(50)
    );
    DECLARE @Sql nvarchar(max);
    BEGIN TRY
        SET @Sql = N'BULK INSERT #SalesInput
FROM ''' + REPLACE(@FullPath, N'''', N'''''') + N'''
WITH
(
    FORMAT = ''CSV'', FIRSTROW = 2, FIELDTERMINATOR = '';'',
    ROWTERMINATOR = ''0x0a'', CODEPAGE = ''65001'', MAXERRORS = 1
);';
        EXEC sys.sp_executesql @Sql;

        BEGIN TRANSACTION;
        -- Staging cuva svaki redak posljednje prodajne datoteke, i neispravan.
        TRUNCATE TABLE stg.SalesDataLab3Raw;
        INSERT INTO stg.SalesDataLab3Raw
            (SourceFileName, SalesDateRaw, CustomerCode, ProductIdRaw,
             PersonIdRaw, SalesAmountRaw)
        SELECT @FileName, TRIM(SalesDateRaw), TRIM(CustomerCode), TRIM(ProductIdRaw),
               TRIM(PersonIdRaw), TRIM(REPLACE(SalesAmountRaw, NCHAR(13), N''))
        FROM #SalesInput;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
