USE Lab;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE etl.usp_LoadSalesPerson
    @FullPath nvarchar(1000)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Pomoćna tablica odgovara dvama stupcima CSV datoteke.
    CREATE TABLE #SalesPersonInput
    (
        PersonId int,
        PersonName nvarchar(100)
    );

    DECLARE @Sql nvarchar(max);

    BEGIN TRY
        -- Putanja se zadaje pri pozivu procedure.
        SET @Sql = N'BULK INSERT #SalesPersonInput
FROM ''' + REPLACE(@FullPath, N'''', N'''''') + N'''
WITH
(
    FORMAT = ''CSV'',
    FIRSTROW = 2,
    FIELDTERMINATOR = '';'',
    ROWTERMINATOR = ''0x0a'',
    CODEPAGE = ''65001'',
    MAXERRORS = 1
);';
        EXEC sys.sp_executesql @Sql;

        -- Uklanjamo CR na kraju retka i razmake oko imena.
        UPDATE #SalesPersonInput
        SET PersonName = TRIM(REPLACE(PersonName, NCHAR(13), N''));

        BEGIN TRANSACTION;

        -- PersonId je poslovni kljuc; ID IDENTITY se ne navodi u INSERT-u.
        -- SCD 1: promijenjeno ime prepisuje prethodnu vrijednost.
        UPDATE d
        SET PersonName = s.PersonName
        FROM dbo.DimSalesPerson AS d
        INNER JOIN #SalesPersonInput AS s ON s.PersonId = d.PersonId
        WHERE d.PersonName <> s.PersonName;

        -- Nove predstavnike dodajemo u dimenziju.
        INSERT dbo.DimSalesPerson (PersonId, PersonName)
        SELECT s.PersonId, s.PersonName
        FROM #SalesPersonInput AS s
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.DimSalesPerson AS d
            WHERE d.PersonId = s.PersonId
        );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
