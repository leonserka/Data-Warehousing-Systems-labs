CREATE OR REPLACE PROCEDURE etl.usp_loadproduct(p_fullpath text)
LANGUAGE plpgsql
AS $$
BEGIN
    CREATE TEMP TABLE lab3_product_input (
        productid integer PRIMARY KEY,
        productname text NOT NULL
    ) ON COMMIT DROP;

    EXECUTE format(
        'COPY pg_temp.lab3_product_input FROM %L WITH (FORMAT csv, HEADER true, DELIMITER %L, ENCODING %L)',
        p_fullpath, ';', 'UTF8'
    );

    INSERT INTO dbo.dimproduct (productid, productname)
    SELECT productid, btrim(productname)
    FROM pg_temp.lab3_product_input
    ON CONFLICT (productid) DO UPDATE
        SET productname = EXCLUDED.productname;

    DROP TABLE pg_temp.lab3_product_input;
END;
$$;



-- CALL etl.usp_loadproduct('E:/tatjana_labovi/files_03/Product/Product1.txt');
-- CALL etl.usp_loadproduct('E:/tatjana_labovi/files_03/Product/Product2.txt');

CALL etl.usp_loadproduct('D:/Data-Warehousing-Systems-labs/files_03/Product/Product1.txt');
CALL etl.usp_loadproduct('D:/Data-Warehousing-Systems-labs/files_03/Product/Product2.txt');

SELECT productid, productname
FROM dbo.dimproduct
ORDER BY productid;
