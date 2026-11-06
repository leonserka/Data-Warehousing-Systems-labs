-- Lab 2, 1 zadatak 

BEGIN;

DO $$
BEGIN
    IF current_database() <> 'lab01' THEN
        RAISE EXCEPTION 'Spoji se na bazu lab01. Trenutna baza: %', current_database();
    END IF;
END;
$$;

TRUNCATE TABLE dbo.Customer;
TRUNCATE TABLE stg.CustomerRaw;

COMMIT;


SELECT 'dbo.Customer' AS tablica, COUNT(*) AS broj_redaka
FROM dbo.Customer
UNION ALL
SELECT 'stg.CustomerRaw', COUNT(*)
FROM stg.CustomerRaw;
