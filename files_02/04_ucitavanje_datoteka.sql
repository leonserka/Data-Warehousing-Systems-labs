-- Lab 2, zad 3.2 

CALL etl.usp_LoadCustomerFile(
    'D:/tatjana_labovi/files_02/Customer_01.csv',
    'Customer_01.csv'
);

CALL etl.usp_LoadCustomerFile(
    'D:/tatjana_labovi/files_02/Customer_02.json',
    'Customer_02.json'
);

CALL etl.usp_LoadCustomerFile(
    'D:/tatjana_labovi/files_02/Customer_03.xml',
    'Customer_03.xml'
);

CALL etl.usp_LoadCustomerFile(
    'D:/tatjana_labovi/files_02/Customer_04.csv',
    'Customer_04.csv'
);

CALL etl.usp_LoadCustomerFile(
    'D:/tatjana_labovi/files_02/Customer_05.json',
    'Customer_05.json'
);

-- Ocekivano nakon prvog ucitavanja: 11 kupaca.
SELECT COUNT(*) AS broj_kupaca
FROM dbo.Customer;

-- Posljednja obrada svake od pet datoteka.
SELECT DISTINCT ON (SourceFileName)
       SourceFileName, Status, RowsRead, RowsInserted,
       RowsRejected, RowsSkipped, ErrorMessage
FROM dbo.ImportLog
WHERE SourceFileName IN (
    'Customer_01.csv', 'Customer_02.json', 'Customer_03.xml',
    'Customer_04.csv', 'Customer_05.json'
)
ORDER BY SourceFileName, ImportLogId DESC;
