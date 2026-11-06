USE Lab;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

-- Ova skripta priprema novi model. Ne brise postojece tablice ni podatke.
-- Staru dbo.Customer iz Lab1/Lab2 korisnik prethodno uklanja prema dogovoru.
-- Za stare dimenzije prvo izvrsite Nastavnik\Lab3_PrijelazKljuceva.sql.



IF SCHEMA_ID(N'etl') IS NULL EXEC(N'CREATE SCHEMA etl;');
IF SCHEMA_ID(N'stg') IS NULL EXEC(N'CREATE SCHEMA stg;');


    IF OBJECT_ID(N'dbo.DimSalesPerson', N'U') IS NULL
    BEGIN
        CREATE TABLE dbo.DimSalesPerson
        (
            ID int IDENTITY(1,1) NOT NULL,
            PersonId int NOT NULL,
            PersonName nvarchar(100) NOT NULL,
            CONSTRAINT PK_DimSalesPerson PRIMARY KEY CLUSTERED (ID)
        );
    END;
        CREATE NONCLUSTERED INDEX IX_DimSalesPerson_PersonId
            ON dbo.DimSalesPerson (PersonId);

    IF OBJECT_ID(N'dbo.DimProduct', N'U') IS NULL
    BEGIN
        CREATE TABLE dbo.DimProduct
        (
            ID int IDENTITY(1,1) NOT NULL,
            ProductId int NOT NULL,
            ProductName nvarchar(100) NOT NULL,
            CONSTRAINT PK_DimProduct PRIMARY KEY CLUSTERED (ID)
        );
    END;

        CREATE NONCLUSTERED INDEX IX_DimProduct_ProductId
            ON dbo.DimProduct (ProductId);

    IF OBJECT_ID(N'dbo.Customer', N'U') IS NULL
    BEGIN
        CREATE TABLE dbo.Customer
        (
            ID int IDENTITY(1,1) NOT NULL,
            CustomerCode nvarchar(50) NOT NULL,
            CustomerName nvarchar(100) NOT NULL,
            PlaceName nvarchar(200) NOT NULL,
            RegionName nvarchar(100) NOT NULL,
            CONSTRAINT PK_Customer PRIMARY KEY CLUSTERED (ID),
            CONSTRAINT UQ_Customer_CustomerCode UNIQUE (CustomerCode)
        );
    END;

    IF OBJECT_ID(N'dbo.SalesData', N'U') IS NULL
    BEGIN
        CREATE TABLE dbo.SalesData
        (
            ID bigint IDENTITY(1,1) NOT NULL,
            SalesDate date NOT NULL,
            CustomerKey int NOT NULL,
            ProductKey int NOT NULL,
            PersonKey int NOT NULL,
            SalesAmount decimal(18,2) NOT NULL,
            CONSTRAINT PK_SalesData PRIMARY KEY CLUSTERED (ID),
            CONSTRAINT UQ_SalesData_Grain
                UNIQUE (SalesDate, CustomerKey, ProductKey, PersonKey),
            CONSTRAINT FK_SalesData_Customer FOREIGN KEY (CustomerKey)
                REFERENCES dbo.Customer (ID),
            CONSTRAINT FK_SalesData_Product FOREIGN KEY (ProductKey)
                REFERENCES dbo.DimProduct (ID),
            CONSTRAINT FK_SalesData_SalesPerson FOREIGN KEY (PersonKey)
                REFERENCES dbo.DimSalesPerson (ID)
        );
    END;


