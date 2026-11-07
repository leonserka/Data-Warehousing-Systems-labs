CREATE OR REPLACE PROCEDURE etl.usp_loadsalesperson(p_fullpath text)
LANGUAGE plpgsql
AS $$
BEGIN
    CREATE TEMP TABLE usp_loadsalesperson_input (
        personid integer PRIMARY KEY,
        personname text NOT NULL
    ) ON COMMIT DROP;

    EXECUTE format(
        'COPY pg_temp.usp_loadsalesperson_input FROM %L WITH (FORMAT csv, HEADER true, DELIMITER %L, ENCODING %L)',
        p_fullpath, ';', 'UTF8'
    );

    INSERT INTO dbo.dimsalesperson (personid, personname)
    SELECT personid, btrim(personname)
    FROM pg_temp.usp_loadsalesperson_input
    ON CONFLICT (personid) DO UPDATE
        SET personname = EXCLUDED.personname;

    DROP TABLE pg_temp.usp_loadsalesperson_input;
END;
$$;
