USE Lab;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
IF SCHEMA_ID(N'stg') IS NULL EXEC(N'CREATE SCHEMA stg;');
GO

-- Samo opisni podaci o kupcima. Prodaja ima vlastiti staging i datoteku.
IF OBJECT_ID(N'stg.CustomerLab3Raw', N'U') IS NULL
BEGIN
    CREATE TABLE stg.CustomerLab3Raw
    (
        RawId bigint IDENTITY(1,1) NOT NULL PRIMARY KEY,
        SourceFileName nvarchar(260) NOT NULL,
        CustomerCode nvarchar(50) NULL,
        CustomerName nvarchar(100) NULL,
        PlaceName nvarchar(200) NULL,
        RegionName nvarchar(100) NULL,
        LoadedAt datetime2(0) NOT NULL DEFAULT SYSDATETIME()
    );
END;
GO

CREATE OR ALTER PROCEDURE etl.usp_LoadCustomerFileLab3
    @FullPath nvarchar(1000),
    @FileName nvarchar(260)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Cetiri polja iz Customer1.txt ili Customer2.txt.
    CREATE TABLE #CustomerInput
    (
        CustomerCode nvarchar(50),
        CustomerName nvarchar(100),
        PlaceName nvarchar(200),
        RegionName nvarchar(100)
    );
    DECLARE @Sql nvarchar(max);

    BEGIN TRY
        SET @Sql = N'BULK INSERT #CustomerInput
FROM ''' + REPLACE(@FullPath, N'''', N'''''') + N'''
WITH
(
    FORMAT = ''CSV'', FIRSTROW = 2, FIELDTERMINATOR = '';'',
    ROWTERMINATOR = ''0x0a'', CODEPAGE = ''65001'', MAXERRORS = 1
);';
        EXEC sys.sp_executesql @Sql;

        UPDATE #CustomerInput
        SET CustomerCode = NULLIF(TRIM(CustomerCode), N''),
            CustomerName = NULLIF(TRIM(CustomerName), N''),
            RegionName = CASE WHEN RIGHT(RegionName, 1) = NCHAR(13)
                              THEN LEFT(RegionName, LEN(RegionName) - 1)
                              ELSE RegionName END;

        BEGIN TRANSACTION;

        TRUNCATE TABLE stg.CustomerLab3Raw;
        INSERT INTO stg.CustomerLab3Raw
            (SourceFileName, CustomerCode, CustomerName, PlaceName, RegionName)
        SELECT @FileName, CustomerCode, CustomerName, PlaceName, RegionName
        FROM #CustomerInput;

        -- Mjesto i zupaniju preuzimamo doslovno, bez sifrarnika i zamjene ID-jem.
        SELECT DISTINCT CustomerCode, CustomerName, PlaceName, RegionName
        INTO #ValidCustomers
        FROM #CustomerInput
        WHERE CustomerCode IS NOT NULL AND CustomerName IS NOT NULL
          AND PlaceName IS NOT NULL AND RegionName IS NOT NULL;

        IF EXISTS
        (
            SELECT CustomerCode FROM #ValidCustomers
            GROUP BY CustomerCode
            HAVING COUNT(*) > 1
        )
            THROW 51402, N'Isti CustomerCode ima razlicito ime ili mjesto u istoj datoteci. Uskladite podatke.', 1;

        -- SCD1 opisnih podataka kupca, neovisno o njegovim prodajama.
        UPDATE c
        SET CustomerName = s.CustomerName, PlaceName = s.PlaceName, RegionName = s.RegionName
        FROM dbo.Customer AS c
        JOIN #ValidCustomers AS s ON s.CustomerCode = c.CustomerCode;
        DECLARE @RowsUpdated int = @@ROWCOUNT;

        INSERT INTO dbo.Customer (CustomerCode, CustomerName, PlaceName, RegionName)
        SELECT s.CustomerCode, s.CustomerName, s.PlaceName, s.RegionName
        FROM #ValidCustomers AS s
        WHERE NOT EXISTS
        (
            SELECT 1 FROM dbo.Customer AS c WHERE c.CustomerCode = s.CustomerCode
        );
        DECLARE @RowsInserted int = @@ROWCOUNT;

        COMMIT TRANSACTION;
        SELECT (SELECT COUNT(*) FROM #CustomerInput) AS RowsRead,
               @RowsInserted AS CustomerRowsInserted,
               @RowsUpdated AS CustomerRowsUpdated;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
