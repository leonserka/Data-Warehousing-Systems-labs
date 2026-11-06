-- Lab 2, zadatak 5

-- 1. 
SELECT *
FROM dbo.Customer
WHERE CustomerAmount >= 200
ORDER BY CustomerCode;

-- 2. 
SELECT *
FROM dbo.ImportLog
WHERE Status = 'FAILED'
ORDER BY ImportLogId DESC;

-- 3. 
SELECT SourceFileName,
       COUNT(*) AS broj_kupaca,
       MIN(CustomerAmount) AS najmanji_iznos,
       MAX(CustomerAmount) AS najveci_iznos,
       SUM(CustomerAmount) AS ukupan_iznos
FROM dbo.Customer
GROUP BY SourceFileName
ORDER BY SourceFileName;

-- 4. 
SELECT SourceFileName, COUNT(*) AS broj_kupaca
FROM dbo.Customer
GROUP BY SourceFileName
HAVING COUNT(*) >= 3
ORDER BY SourceFileName;

-- 6.
SELECT SourceFileName,
       Status,
       COUNT(*) AS broj_obrada,
       MIN(StartedAt) AS prvi_pocetak,
       MAX(FinishedAt) AS posljednji_zavrsetak
FROM dbo.ImportLog
GROUP BY SourceFileName, Status
ORDER BY SourceFileName, MAX(StartedAt) DESC, MAX(ImportLogId) DESC;

-- 7.
SELECT DISTINCT l.SourceFileName
FROM dbo.ImportLog AS l
WHERE l.Status = 'FAILED'
  AND NOT EXISTS (
      SELECT 1
      FROM dbo.ImportLog AS s
      WHERE s.SourceFileName = l.SourceFileName
        AND s.Status = 'SUCCESS'
  )
ORDER BY l.SourceFileName;

-- 8.
SELECT c.CustomerCode, c.CustomerName, c.CustomerAmount
FROM dbo.Customer AS c
WHERE NOT EXISTS (
    SELECT 1
    FROM stg.CustomerRaw AS s
    WHERE s.CustomerCode = c.CustomerCode
)
ORDER BY c.CustomerCode;
