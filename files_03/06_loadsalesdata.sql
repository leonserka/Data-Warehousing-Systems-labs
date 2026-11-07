-- Zadatak 2: poveži poslovne ključeve s dimenzijama i zbroji prodaju.
CREATE OR REPLACE PROCEDURE etl.usp_LoadSalesDataLab3()
LANGUAGE sql
AS $$
    INSERT INTO dbo.salesdata (salesdate, personkey, productkey, customerkey, salesamount)
    SELECT s.salesdateraw::date, sp.id, p.id, c.id, SUM(s.salesamountraw::numeric)
    FROM stg.salesdatalab3raw AS s
    JOIN dbo.dimsalesperson AS sp ON sp.personid = s.personidraw::integer
    JOIN dbo.dimproduct AS p ON p.productid = s.productidraw::integer
    JOIN dbo.customer AS c ON c.customercode = s.customercode
    GROUP BY s.salesdateraw::date, sp.id, p.id, c.id
    ON CONFLICT (salesdate, customerkey, productkey, personkey) DO UPDATE
        SET salesamount = EXCLUDED.salesamount;
$$;
