-- Provjeri rezultat prodaje nakon 07_run_loads.sql.

SELECT s.salesdate, sp.personid, p.productid, c.customercode, s.salesamount
FROM dbo.salesdata AS s
JOIN dbo.dimsalesperson AS sp ON sp.id = s.personkey
JOIN dbo.dimproduct AS p ON p.id = s.productkey
JOIN dbo.customer AS c ON c.id = s.customerkey
ORDER BY s.salesdate, sp.personid, p.productid, c.customercode;

SELECT count(*) AS grupa_prodaje, sum(salesamount) AS ukupna_prodaja
FROM dbo.salesdata;

SELECT count(*) AS nepovezani_redci
FROM stg.salesdatalab3raw AS s
LEFT JOIN dbo.dimsalesperson AS sp ON sp.personid = s.personidraw::integer
LEFT JOIN dbo.dimproduct AS p ON p.productid = s.productidraw::integer
LEFT JOIN dbo.customer AS c ON c.customercode = s.customercode
WHERE sp.id IS NULL OR p.id IS NULL OR c.id IS NULL;
