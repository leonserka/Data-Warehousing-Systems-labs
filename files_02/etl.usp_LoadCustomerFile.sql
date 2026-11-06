USE [Lab];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE etl.usp_LoadCustomerFile
    @FullPath nvarchar(1000),
    @FileName nvarchar(260)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    -- Ove izvršne postavke vrijede i pri pozivu iz ADO.NET-a.
    -- ANSI_NULLS i QUOTED_IDENTIFIER spremljeni su pri CREATE OR ALTER.
    SET ANSI_PADDING ON;
    SET ANSI_WARNINGS ON;
    SET ARITHABORT ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET NUMERIC_ROUNDABORT OFF;

    DECLARE @SourceFormat varchar(10) = 'UNKNOWN';
    DECLARE @StagingStarted bit = 0;
    DECLARE @ValidationStarted bit = 0;
    DECLARE @Text nvarchar(max);
    DECLARE @Xml xml;
    DECLARE @Sql nvarchar(max);
    DECLARE @ErrorMessage nvarchar(2000);

    BEGIN TRY
        SET @FileName = NULLIF(LTRIM(RTRIM(@FileName)), N'');
        SET @FullPath = NULLIF(LTRIM(RTRIM(@FullPath)), N'');
        IF @FileName IS NULL OR @FullPath IS NULL
            THROW 51031, N'Potrebni su naziv i puna putanja datoteke.', 1;
        IF CHARINDEX(N'\', @FileName) > 0 OR CHARINDEX(N'/', @FileName) > 0
           OR CHARINDEX(N':', @FileName) > 0
            THROW 51032, N'FileName mora sadržavati samo naziv, bez putanje.', 1;
        IF LEN(@FullPath) <= LEN(@FileName)
           OR RIGHT(@FullPath, LEN(@FileName) + 1) <> N'\' + @FileName
            THROW 51033, N'FullPath mora završavati obrnutom kosom crtom i zadanim FileName.', 1;

        SET @SourceFormat = CASE
            WHEN LOWER(RIGHT(@FileName, 5)) = N'.json' THEN 'JSON'
            WHEN LOWER(RIGHT(@FileName, 4)) = N'.xml' THEN 'XML'
            WHEN LOWER(RIGHT(@FileName, 4)) = N'.csv' THEN 'CSV'
            ELSE 'UNKNOWN' END;

        IF @SourceFormat = 'UNKNOWN'
            THROW 51034, N'Podržane su samo datoteke JSON, XML i CSV.', 1;

        SET @StagingStarted = 1;
        TRUNCATE TABLE stg.CustomerRaw;

        IF @SourceFormat = 'JSON'
        BEGIN
            -- Eksplicitna UTF-8 kolacija čuva hrvatska slova pri dekodiranju.
            SET @Sql = N'
SELECT @TextOut = CONVERT(nvarchar(max),
    COALESCE(BulkColumn, '''' COLLATE Latin1_General_100_CI_AS_SC_UTF8))
FROM OPENROWSET(BULK ''' + REPLACE(@FullPath, N'''', N'''''') + N''', SINGLE_BLOB) AS src;';
            EXEC sys.sp_executesql @Sql,
                N'@TextOut nvarchar(max) OUTPUT', @TextOut = @Text OUTPUT;
            IF LEFT(@Text, 1) = NCHAR(65279)
                SET @Text = STUFF(@Text, 1, 1, N'');
        END;

        IF @SourceFormat = 'JSON'
        BEGIN
            IF @Text IS NULL OR ISJSON(@Text) <> 1
                THROW 51036, N'Datoteka ne sadrži valjan JSON.', 1;
            IF LEFT(LTRIM(REPLACE(REPLACE(REPLACE(@Text,
                NCHAR(13), N''), NCHAR(10), N''), NCHAR(9), N'')), 1) <> N'['
                THROW 51037, N'Očekuje se JSON niz objekata: [ {...}, {...} ].', 1;
            IF EXISTS (SELECT 1 FROM OPENJSON(@Text) WHERE [type] <> 5)
                THROW 51038, N'Svaki element JSON niza mora biti objekt kupca.', 1;

            INSERT stg.CustomerRaw
                (SourceFileName, SourceFormat, CustomerCode, CustomerName,
                 CustomerAmountRaw, SalesDateRaw)
            SELECT @FileName, 'JSON', j.CustomerCode, j.CustomerName,
                   j.CustomerAmount, j.SalesDate
            FROM OPENJSON(@Text) WITH
            (
                CustomerCode nvarchar(max) '$.CustomerCode',
                CustomerName nvarchar(max) '$.CustomerName',
                CustomerAmount nvarchar(max) '$.CustomerAmount',
                SalesDate nvarchar(max) '$.SalesDate'
            ) AS j;
        END
        ELSE IF @SourceFormat = 'XML'
        BEGIN
            -- XML parser koristi kodiranje iz XML deklaracije.
            SET @Sql = N'SELECT @XmlOut = CONVERT(xml, BulkColumn)
FROM OPENROWSET(BULK ''' + REPLACE(@FullPath, N'''', N'''''') + N''', SINGLE_BLOB) AS src;';
            EXEC sys.sp_executesql @Sql,
                N'@XmlOut xml OUTPUT', @XmlOut = @Xml OUTPUT;
            IF @Xml IS NULL OR @Xml.exist('(/Customers/Customer, /customers/customer)') <> 1
                THROW 51039, N'XML nema elemente Customers/Customer (ili customers/customer).', 1;

            INSERT stg.CustomerRaw
                (SourceFileName, SourceFormat, CustomerCode, CustomerName,
                 CustomerAmountRaw, SalesDateRaw)
            SELECT @FileName, 'XML',
                x.n.value('(CustomerCode/text())[1]', 'nvarchar(max)'),
                x.n.value('(CustomerName/text())[1]', 'nvarchar(max)'),
                x.n.value('(CustomerAmount/text())[1]', 'nvarchar(max)'),
                x.n.value('(SalesDate/text())[1]', 'nvarchar(max)')
            FROM @Xml.nodes('(/Customers/Customer, /customers/customer)') AS x(n);
        END
        ELSE IF @SourceFormat = 'CSV'
        BEGIN
            -- CSV ima zaglavlje, razdjelnik ; i UTF-8 kodiranje.
            CREATE TABLE #CsvInput
            (
                CustomerCode nvarchar(50) NULL,
                CustomerName nvarchar(100) NULL,
                CustomerAmountRaw nvarchar(50) NULL,
                SalesDateRaw nvarchar(50) NULL
            );
            SET @Sql = N'BULK INSERT #CsvInput
FROM ''' + REPLACE(@FullPath, N'''', N'''''') + N'''
WITH (FORMAT = ''CSV'', FIRSTROW = 2, FIELDTERMINATOR = '';'',
      FIELDQUOTE = ''"'', ROWTERMINATOR = ''0x0a'', CODEPAGE = ''65001'', MAXERRORS = 1);';
            EXEC sys.sp_executesql @Sql;

            INSERT stg.CustomerRaw
                (SourceFileName, SourceFormat, CustomerCode, CustomerName,
                 CustomerAmountRaw, SalesDateRaw)
            SELECT @FileName, 'CSV', CustomerCode, CustomerName,
                   CustomerAmountRaw, REPLACE(SalesDateRaw, NCHAR(13), N'')
            FROM #CsvInput;
        END;

        IF NOT EXISTS (SELECT 1 FROM stg.CustomerRaw)
            THROW 51047, N'Datoteka nema zapisa za obradu.', 1;

        -- Procedura iz Lab1 nema parametre i sama vodi dnevnik obrade.
        SET @ValidationStarted = 1;
        EXEC etl.usp_ValidateAndLoadCustomers;
    END TRY
    BEGIN CATCH
        SET @ErrorMessage = LEFT(ERROR_MESSAGE(), 2000);
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;

        -- Greške čitanja bilježimo ovdje; greške validacije bilježi Lab1.
        IF @ValidationStarted = 0
        BEGIN
            IF @StagingStarted = 1 TRUNCATE TABLE stg.CustomerRaw;

            INSERT dbo.ImportLog
                (SourceFileName, SourceFormat, StartedAt, FinishedAt,
                 RowsRead, RowsInserted, RowsRejected, Status, ErrorMessage)
            VALUES
                (COALESCE(@FileName, N'<nepoznata datoteka>'), @SourceFormat,
                 SYSDATETIME(), SYSDATETIME(), 0, 0, 0, 'FAILED', @ErrorMessage);
        END;

        THROW;
    END CATCH;
END;
GO

/*
Primjeri za ručno pokretanje u SSMS-u (označite samo željene naredbe).

1. Prije početka vježbe ispraznite ciljnu tablicu:
TRUNCATE TABLE dbo.Customer;

2. Učitajte odabranu datoteku:
EXEC etl.usp_LoadCustomerFile
    @FullPath = N'C:\LabDWH\Lab2\Customer_01.csv',
    @FileName = N'Customer_01.csv';

Za drugu datoteku promijenite oba parametra.

3. Pregledajte rezultate:
SELECT * FROM dbo.Customer;
SELECT * FROM dbo.ImportError;
SELECT * FROM dbo.ImportLog;
*/
