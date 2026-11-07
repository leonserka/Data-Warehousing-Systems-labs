-- Pokreni nakon 05_loadproduct.sql, koji učitava proizvode.
CALL etl.usp_loadsalesperson('E:/tatjana_labovi/files_03/SalesPerson/SalesPerson1.txt');
CALL etl.usp_loadsalesperson('E:/tatjana_labovi/files_03/SalesPerson/SalesPerson2.txt');

CALL etl.usp_loadcustomerfilelab3('E:/tatjana_labovi/files_03/Customer/Customer1.txt', 'Customer1.txt');
CALL etl.usp_loadcustomerfilelab3('E:/tatjana_labovi/files_03/Customer/Customer2.txt', 'Customer2.txt');

-- Učitaj prodaju u staging i provjeri broj ulaznih redaka.
CALL etl.usp_loadsalesdatafilelab3('E:/tatjana_labovi/files_03/SalesData/SalesData.txt', 'SalesData.txt');

SELECT count(*) AS staging_redaka
FROM stg.salesdatalab3raw;

CALL etl.usp_LoadSalesDataLab3();
