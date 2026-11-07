BEGIN;

DO $$
BEGIN
    IF current_database() <> 'lab01' THEN
        RAISE EXCEPTION 'Run Lab 3 in lab01.';
    END IF;
END;
$$;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'dbo' AND table_name = 'customer'
          AND column_name = 'customerid'
    ) THEN
        DROP TABLE dbo.customer;
    END IF;
END;
$$;

CREATE TABLE IF NOT EXISTS dbo.dimsalesperson (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    personid integer NOT NULL UNIQUE,
    personname text NOT NULL
);

CREATE TABLE IF NOT EXISTS dbo.dimproduct (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    productid integer NOT NULL UNIQUE,
    productname text NOT NULL
);

CREATE TABLE IF NOT EXISTS dbo.customer (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customercode text NOT NULL UNIQUE,
    customername text NOT NULL,
    placename text NOT NULL,
    regionname text NOT NULL
);

CREATE TABLE IF NOT EXISTS dbo.salesdata (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    salesdate date NOT NULL,
    customerkey integer NOT NULL REFERENCES dbo.customer(id),
    productkey integer NOT NULL REFERENCES dbo.dimproduct(id),
    personkey integer NOT NULL REFERENCES dbo.dimsalesperson(id),
    salesamount numeric(18,2) NOT NULL,
    UNIQUE (salesdate, customerkey, productkey, personkey)
);

CREATE TABLE IF NOT EXISTS stg.customerlab3raw (
    customercode text,
    customername text,
    placename text,
    regionname text,
    sourcefilename text NOT NULL
);

CREATE TABLE IF NOT EXISTS stg.salesdatalab3raw (
    salesdateraw text,
    customercode text,
    productidraw text,
    personidraw text,
    salesamountraw text,
    sourcefilename text NOT NULL
);

COMMIT;
