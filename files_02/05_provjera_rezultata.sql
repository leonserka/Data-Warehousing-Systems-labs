-- Lab 2, zadatak 4


SELECT *
FROM dbo.Customer
ORDER BY CustomerCode;


SELECT *
FROM dbo.ImportLog
ORDER BY ImportLogId DESC
LIMIT 6;


SELECT *
FROM dbo.ImportError
ORDER BY ErrorId DESC;


SELECT CustomerCode, CustomerName, CustomerAmount, SourceFileName
FROM dbo.Customer
WHERE CustomerCode = 'C101';


SELECT pg_get_functiondef(
    'etl.usp_validateandloadcustomers()'::regprocedure
) AS definicija_procedure;