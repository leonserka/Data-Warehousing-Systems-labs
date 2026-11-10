CREATE OR REPLACE PROCEDURE etl.usp_LoadSalesDataLab3()
LANGUAGE sql
AS $$
    INSERT INTO dbo.salesdata (salesdate, personkey, productkey, customerkey, salesamount)
    SELECT stg.salesdatalab3raw.salesdateraw::date,
           dbo.dimsalesperson.id,
           dbo.dimproduct.id,
           dbo.customer.id,
           SUM(stg.salesdatalab3raw.salesamountraw::numeric)
    FROM stg.salesdatalab3raw
    JOIN dbo.dimsalesperson
        ON dbo.dimsalesperson.personid = stg.salesdatalab3raw.personidraw::integer
    JOIN dbo.dimproduct
        ON dbo.dimproduct.productid = stg.salesdatalab3raw.productidraw::integer
    JOIN dbo.customer
        ON dbo.customer.customercode = stg.salesdatalab3raw.customercode
    GROUP BY stg.salesdatalab3raw.salesdateraw::date,
             dbo.dimsalesperson.id,
             dbo.dimproduct.id,
             dbo.customer.id
    ON CONFLICT (salesdate, customerkey, productkey, personkey) DO UPDATE
        SET salesamount = EXCLUDED.salesamount;
$$;
