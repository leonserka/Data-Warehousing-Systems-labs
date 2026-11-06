# Database & ETL Labs

Completed exercises for Labs 1–3, including SQL solutions, sample data, and assignment documents.

- **Lab 1 (`files_01`)** — Database setup, CSV/JSON/XML imports, staging, validation, and automation scripts.
- **Lab 2 (`files_02`)** — File-based customer loading, ETL procedures, result checks, and additional exercises.
- **Lab 3 (`files_03`)** — Sales data warehouse preparation and ETL procedures for customers, salespeople, and sales data.

## Usage

Read the assignment documents in each folder, configure local file paths, and run the relevant setup and loading scripts. Follow the numbered script order where provided.

All three labs are solved using PostgreSQL. Some scripts clear existing data, so run them in a dedicated lab database.

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
5. Connect to `lab01`, open a `.sql` file, select the intended SQL statements, and use the extension's query execution action. Start with the setup scripts and follow the numbered order where available.
6. Check the connection with `SELECT current_database(), version();` and update import paths to match your local files.

Scripts containing psql commands such as `\set` should be run with `psql` in VS Code's integrated terminal, rather than sent directly through the query editor. For example, from the project folder, use `psql -h localhost -p 5432 -U postgres -d postgres -f files_01/00_create_database.sql` to create the database instead of step 4. This requires `psql` on your PATH and should only be run before the database exists.
