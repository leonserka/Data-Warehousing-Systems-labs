CREATE OR REPLACE PROCEDURE etl.usp_loadsalesdatafilelab3(p_fullpath text, p_filename text)
LANGUAGE plpgsql
AS $$
BEGIN
    CREATE TEMP TABLE usp_loadsalesdatafilelab3_input (
        salesdateraw text,
        customercode text,
        productidraw text,
        personidraw text,
        salesamountraw text
    ) ON COMMIT DROP;

    EXECUTE format(
        'COPY pg_temp.usp_loadsalesdatafilelab3_input FROM %L WITH (FORMAT csv, HEADER true, DELIMITER %L, ENCODING %L)',
        p_fullpath, ';', 'UTF8'
    );

    TRUNCATE TABLE stg.salesdatalab3raw;

    INSERT INTO stg.salesdatalab3raw
        (salesdateraw, customercode, productidraw, personidraw, salesamountraw, sourcefilename)
    SELECT btrim(salesdateraw), btrim(customercode), btrim(productidraw),
           btrim(personidraw), btrim(salesamountraw), p_filename
    FROM pg_temp.usp_loadsalesdatafilelab3_input;

    DROP TABLE pg_temp.usp_loadsalesdatafilelab3_input;
END;
$$;
