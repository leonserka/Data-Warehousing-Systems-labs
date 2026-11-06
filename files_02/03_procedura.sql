-- Lab 2, 3 zadatak

CREATE OR REPLACE PROCEDURE etl.usp_LoadCustomerFile(
    IN p_fullpath text,
    IN p_filename text
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_format varchar(10) := 'UNKNOWN';
    v_json jsonb;
    v_xml xml;
    v_error text;
    v_started timestamp := clock_timestamp();
BEGIN
    -- Isti lokot kao u proceduri iz Lab1: staging dijele sve obrade.
    PERFORM pg_advisory_xact_lock(101001);

    BEGIN
        p_fullpath := NULLIF(btrim(p_fullpath), '');
        p_filename := NULLIF(btrim(p_filename), '');

        IF p_fullpath IS NULL OR p_filename IS NULL THEN
            RAISE EXCEPTION 'Potrebni su puna putanja i naziv datoteke.';
        END IF;

        IF position('/' IN p_filename) > 0
           OR position(chr(92) IN p_filename) > 0
           OR position(':' IN p_filename) > 0 THEN
            RAISE EXCEPTION 'Naziv datoteke mora biti bez putanje.';
        END IF;

        p_fullpath := replace(p_fullpath, chr(92), '/');
        IF right(p_fullpath, length(p_filename) + 1) <> '/' || p_filename THEN
            RAISE EXCEPTION 'Putanja mora zavrsavati zadanim nazivom datoteke.';
        END IF;

        v_format := CASE
            WHEN lower(p_filename) LIKE '%.csv' THEN 'CSV'
            WHEN lower(p_filename) LIKE '%.json' THEN 'JSON'
            WHEN lower(p_filename) LIKE '%.xml' THEN 'XML'
            ELSE 'UNKNOWN'
        END;

        IF v_format = 'UNKNOWN' THEN
            RAISE EXCEPTION 'Podrzane su samo CSV, JSON i XML datoteke.';
        END IF;

        TRUNCATE TABLE stg.CustomerRaw;

        IF v_format = 'CSV' THEN
            CREATE TEMP TABLE lab02_csv_input (
                CustomerCode text,
                CustomerName text,
                CustomerAmountRaw text,
                SalesDateRaw text
            ) ON COMMIT DROP;

            EXECUTE format(
                'COPY pg_temp.lab02_csv_input FROM %L WITH (FORMAT CSV, HEADER true, DELIMITER '';'', ENCODING ''UTF8'')',
                p_fullpath
            );

            INSERT INTO stg.CustomerRaw
                (SourceFileName, SourceFormat, CustomerCode, CustomerName,
                 CustomerAmountRaw, SalesDateRaw)
            SELECT p_filename, v_format, CustomerCode, CustomerName,
                   CustomerAmountRaw, replace(SalesDateRaw, chr(13), '')
            FROM pg_temp.lab02_csv_input;

            DROP TABLE pg_temp.lab02_csv_input;

        ELSIF v_format = 'JSON' THEN
            v_json := ltrim(convert_from(pg_read_binary_file(p_fullpath),
                                         'UTF8'), chr(65279))::jsonb;

            IF jsonb_typeof(v_json) IS DISTINCT FROM 'array' THEN
                RAISE EXCEPTION 'Ocekuje se JSON niz objekata.';
            END IF;
            IF EXISTS (
                SELECT 1 FROM jsonb_array_elements(v_json) AS j(value)
                WHERE jsonb_typeof(j.value) <> 'object'
            ) THEN
                RAISE EXCEPTION 'Svaki element JSON niza mora biti objekt.';
            END IF;

            INSERT INTO stg.CustomerRaw
                (SourceFileName, SourceFormat, CustomerCode, CustomerName,
                 CustomerAmountRaw, SalesDateRaw)
            SELECT p_filename, v_format,
                   j.value->>'CustomerCode', j.value->>'CustomerName',
                   j.value->>'CustomerAmount', j.value->>'SalesDate'
            FROM jsonb_array_elements(v_json) AS j(value);

        ELSE
            v_xml := XMLPARSE(DOCUMENT convert_from(
                pg_read_binary_file(p_fullpath), 'UTF8'));

            IF NOT xpath_exists('/Customers/Customer | /customers/customer', v_xml) THEN
                RAISE EXCEPTION 'XML nema elemente Customers/Customer.';
            END IF;

            INSERT INTO stg.CustomerRaw
                (SourceFileName, SourceFormat, CustomerCode, CustomerName,
                 CustomerAmountRaw, SalesDateRaw)
            SELECT p_filename, v_format, x.CustomerCode, x.CustomerName,
                   x.CustomerAmountRaw, x.SalesDateRaw
            FROM XMLTABLE(
                '/Customers/Customer | /customers/customer'
                PASSING v_xml
                COLUMNS
                    CustomerCode text PATH 'CustomerCode',
                    CustomerName text PATH 'CustomerName',
                    CustomerAmountRaw text PATH 'CustomerAmount',
                    SalesDateRaw text PATH 'SalesDate'
            ) AS x;
        END IF;

        IF NOT EXISTS (SELECT 1 FROM stg.CustomerRaw) THEN
            RAISE EXCEPTION 'Datoteka nema zapisa za obradu.';
        END IF;

    EXCEPTION WHEN OTHERS THEN
        -- Ne podizemo novu iznimku kako bi FAILED zapis ostao spremljen.
        GET STACKED DIAGNOSTICS v_error = MESSAGE_TEXT;
        TRUNCATE TABLE stg.CustomerRaw;
        INSERT INTO dbo.ImportLog
            (SourceFileName, SourceFormat, StartedAt, FinishedAt,
             RowsRead, RowsInserted, RowsRejected, RowsSkipped, Status, ErrorMessage)
        VALUES
            (COALESCE(p_filename, '<nepoznata datoteka>'), v_format,
             v_started, clock_timestamp(), 0, 0, 0, 0, 'FAILED', v_error);
        RAISE WARNING 'Ucitavanje nije uspjelo: %', v_error;
        RETURN;
    END;

    -- Validacija, unos kupaca i dnevnik obrade ostaju u proceduri iz Lab1.
    CALL etl.usp_ValidateAndLoadCustomers();
END;
$$;
