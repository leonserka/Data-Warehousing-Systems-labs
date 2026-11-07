CREATE OR REPLACE PROCEDURE etl.usp_loadcustomerfilelab3(p_fullpath text, p_filename text)
LANGUAGE plpgsql
AS $$
BEGIN
    CREATE TEMP TABLE usp_loadcustomerfilelab3_input (
        customercode text PRIMARY KEY,
        customername text NOT NULL,
        placename text NOT NULL,
        regionname text NOT NULL
    ) ON COMMIT DROP;

    EXECUTE format(
        'COPY pg_temp.usp_loadcustomerfilelab3_input FROM %L WITH (FORMAT csv, HEADER true, DELIMITER %L, ENCODING %L)',
        p_fullpath, ';', 'UTF8'
    );

    TRUNCATE TABLE stg.customerlab3raw;

    INSERT INTO stg.customerlab3raw (customercode, customername, placename, regionname, sourcefilename)
    SELECT btrim(customercode), btrim(customername), btrim(placename), btrim(regionname), p_filename
    FROM pg_temp.usp_loadcustomerfilelab3_input;

    INSERT INTO dbo.customer (customercode, customername, placename, regionname)
    SELECT customercode, customername, placename, regionname
    FROM stg.customerlab3raw
    ON CONFLICT (customercode) DO UPDATE
        SET customername = EXCLUDED.customername,
            placename = EXCLUDED.placename,
            regionname = EXCLUDED.regionname;

    DROP TABLE pg_temp.usp_loadcustomerfilelab3_input;
END;
$$;
