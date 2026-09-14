# Mosque Finance Spreadsheet ETL

This pipeline imports the existing INFAQ and WAKAF spreadsheets into the Supabase PostgreSQL schema without treating the spreadsheets as normalized tables.

```text
CSV/TXT -> staging -> normalize -> master lookup/creation -> transactions -> dashboards
```

## Source analysis

### `infaq.csv` / `Infaq.csv`

- 25 columns, including two summary/reporting sections appended to the right.
- Transaction fields are in columns `No.` through `ID`.
- `Flow` determines direction.
- Income amount comes from `Kredit`; expense amount comes from `Debit`.
- A few expense rows contain both values; the expense `Debit` is authoritative.
- 161 rows have dates, 187 rows have source IDs, and 26 rows are blank/template rows.
- `Reimburse` contains values such as `Sudah` and `Belum`; `PIC` is used for the reimbursement person when present.

### `wakaf.csv` / `Wakaf.csv`

- 24 columns, including a summary/reporting section appended to the right.
- Transaction fields are in columns `No.` through `ID`.
- `Flow` determines direction.
- Amounts are stored in `Kredit` for both income and expense rows; the loader falls back to `Debit` if present.
- `Category` is used for the program/activity, while the transaction category is inferred from the description.
- 58 rows have dates and 158 rows have source IDs; remaining rows are blank/template rows.
- `Type` maps to the account master (`Bank` or `Cash`).

The parser intentionally ignores spreadsheet summary columns such as `Saldo`, `TOTAL`, `TARGET`, and manual balance blocks. They are not source-of-truth ledger facts.

## Database setup

Apply these SQL files to the existing Supabase database:

1. `sql/migrations/models/20260905_005_etl_support.sql`
2. `etl/sql/master_seed.sql`
3. `etl/sql/vendor_seed.sql`

The model migration adds:

- nullable `public.transactions.external_id`
- a partial unique index on `external_id`
- `staging.infaq_raw`
- `staging.wakaf_raw`
- `staging.import_batches`
- `staging.import_errors`
- one reimbursement record per transaction

Run the migration after the existing model migrations in `sql/README.md`.

## Install

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r etl/requirements.txt
```

Set a direct PostgreSQL connection string. The browser anon key in `.env.local` is not a database connection string and must not be used by this ETL.

```bash
export SUPABASE_DB_MOSQUE_URL='postgresql+psycopg2://postgres:<password>@db.<project-ref>.supabase.co:5432/postgres?sslmode=require'
```

## Run

Dry-run parsing and validation does not connect to Supabase:

```bash
python etl/run_import.py --dry-run \
  etl/source/infaq.csv etl/source/wakaf.csv \
  --vendor-file 'etl/source/Rekening Vendor.txt'
```

Import into Supabase:

```bash
python etl/run_import.py \
  etl/source/infaq.csv etl/source/wakaf.csv \
  --vendor-file 'etl/source/Rekening Vendor.txt'
```

By default existing transactions are skipped by `external_id`. To update an existing transaction when source values have changed:

```bash
python etl/run_import.py --update-existing \
  etl/source/infaq.csv etl/source/wakaf.csv
```

## Idempotency and logging

`INF1`, `INF2`, `WKF1`, and similar source IDs are copied to `transactions.external_id`. The unique index prevents duplicate normalized transactions. Each run creates a `staging.import_batches` record; row-level failures are written to `staging.import_errors` with the original JSON payload.

The command prints a compact import report:

```text
Found 10 vendor records
infaq.csv: normalized 162 rows, imported 162, skipped 0 duplicates, failed 2 rows
wakaf.csv: normalized 58 rows, imported 58, skipped 0 duplicates, failed 0 rows
TOTAL: imported 220, skipped 0 duplicates, errors 2
```

Master lookup is case-insensitive. Missing categories, activities, vendors, persons, and accounts are created only when enough information is available. Placeholder vendors such as `-`, `admin bank`, and `??????` are ignored.

## Mapping decisions

- INFAQ `Infaq` -> `INFAQ`
- INFAQ `Operasional`, `Listrik` -> `OPERATIONAL`
- INFAQ `Kajian` -> `KAJIAN`
- INFAQ `Perlengkapan` -> `EQUIPMENT`
- INFAQ `Event - Donor`, `Ramadhan` -> `SOCIAL`
- WAKAF material descriptions -> `MATERIAL`
- WAKAF `Upah tukang ...` -> `LABOR`
- WAKAF bank/payment fees -> `BANK_ADMINISTRATION`
- WAKAF `Ruang Sound` -> activity `RUANG_SOUND`
- INFAQ event labels such as `Kajian` and `Operasional` -> corresponding activities

Ambiguous or blank template rows are retained in raw staging but do not become transactions.
