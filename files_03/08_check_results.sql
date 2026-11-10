SELECT dbo.salesdata.salesdate,
       dbo.dimsalesperson.personid,
       dbo.dimproduct.productid,
       dbo.customer.customercode,
       dbo.salesdata.salesamount
FROM dbo.salesdata
JOIN dbo.dimsalesperson ON dbo.dimsalesperson.id = dbo.salesdata.personkey
JOIN dbo.dimproduct ON dbo.dimproduct.id = dbo.salesdata.productkey
JOIN dbo.customer ON dbo.customer.id = dbo.salesdata.customerkey
ORDER BY dbo.salesdata.salesdate,
         dbo.dimsalesperson.personid,
         dbo.dimproduct.productid,
         dbo.customer.customercode;

SELECT count(*) AS grupa_prodaje, sum(salesamount) AS ukupna_prodaja
FROM dbo.salesdata;

SELECT count(*) AS nepovezani_redci
FROM stg.salesdatalab3raw
LEFT JOIN dbo.dimsalesperson
    ON dbo.dimsalesperson.personid = stg.salesdatalab3raw.personidraw::integer
LEFT JOIN dbo.dimproduct
    ON dbo.dimproduct.productid = stg.salesdatalab3raw.productidraw::integer
LEFT JOIN dbo.customer
    ON dbo.customer.customercode = stg.salesdatalab3raw.customercode
WHERE dbo.dimsalesperson.id IS NULL
   OR dbo.dimproduct.id IS NULL
   OR dbo.customer.id IS NULL;
