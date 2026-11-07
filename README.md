# Database & ETL Labs

Completed exercises for Labs 1–3, including SQL solutions, sample data, and assignment documents.

- **Lab 1 (`files_01`)** — Database setup, CSV/JSON/XML imports, staging, validation, and automation scripts.
- **Lab 2 (`files_02`)** — File-based customer loading, ETL procedures, result checks, and additional exercises.
- **Lab 3 (`files_03`)** — Sales data warehouse preparation and ETL procedures for customers, salespeople, and sales data.

## Usage

Read the assignment documents in each folder, configure local file paths, and run the relevant setup and loading scripts. Follow the numbered script order where provided.

All three labs build on the same PostgreSQL database, `lab01`. Run them in order.

## PostgreSQL in VS Code

1. Install [PostgreSQL](https://www.postgresql.org/download/windows/) locally and remember the password you set for the `postgres` user. Make sure the PostgreSQL service is running.
2. In VS Code, open this project folder and install Microsoft's [PostgreSQL extension](https://marketplace.visualstudio.com/items?itemName=ms-ossdata.vscode-pgsql) (`ms-ossdata.vscode-pgsql`).
3. Open the PostgreSQL sidebar, add a connection, and enter your local settings:

   | Setting | Typical local value |
   | --- | --- |
   | Host | `localhost` |
   | Port | `5432` |
   | User | `postgres` |
   | Password | Your installation password |
   | Database | `postgres` initially, then `lab01` after creating it |

4. Create the lab database once by running `CREATE DATABASE lab01;` while connected to `postgres`, outside a transaction. Skip this if `lab01` already exists.
5. For Labs 1–2, connect to `lab01`, open a `.sql` file, select the intended SQL statements, and use the extension's query execution action. Start with the setup scripts and follow the numbered order where available.
6. Check the connection with `SELECT current_database(), version();` and update import paths to match your local files.

Scripts containing psql commands such as `\set` should be run with `psql` in VS Code's integrated terminal, rather than sent directly through the query editor. For example, from the project folder, use `psql -h localhost -p 5432 -U postgres -d postgres -f files_01/00_create_database.sql` to create the database instead of step 4. This requires `psql` on your PATH and should only be run before the database exists.

## Run Lab 3

After Labs 1 and 2, connect to `lab01` and run these PostgreSQL scripts from `files_03` in order. Update the input paths in `05_loadproduct.sql` and `07_run_loads.sql` if the project is on a different drive or in a different folder.

1. `Lab3_Priprema.sql` drops the earlier `dbo.customer` table and creates the Lab 3 tables. Save any Lab 2 results you need before running it.
2. `etl.usp_LoadSalesPerson.sql`, `etl.usp_LoadCustomerFileLab3.sql`, and `etl.usp_LoadSalesDataFileLab3.sql` define the file import procedures.
3. `05_loadproduct.sql` defines and runs the product loader. Expect five products.
4. `06_loadsalesdata.sql` defines the procedure that groups sales by date, salesperson, product, and customer.
5. `07_run_loads.sql` loads the remaining input files and runs the sales procedure. Expect 19 sales rows in staging.
6. `08_check_results.sql` verifies the result. Expect 17 sales groups, a total of `5291.00`, and zero unmatched staging rows.

## VS Code connection errors

If the Microsoft PostgreSQL extension reports `No connection for owner URI` or opens results from the wrong SQL tab, open the Command Palette (`Ctrl+Shift+P`) and run **Developer: Reload Window**. Reconnect the SQL file to `lab01` and rerun the intended query. If the loads already succeeded, rerun only `08_check_results.sql` to view the results.

You can also run the checks from the project root in the integrated terminal:

```powershell
psql -h localhost -U postgres -d lab01 -v ON_ERROR_STOP=1 -f files_03/08_check_results.sql
```
