# Mosque Finance

A desktop-first mosque financial management application backed by Supabase PostgreSQL.

## Application

```bash
npm install
npm run dev
```

Open `http://localhost:3000`.

The browser uses `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` from `.env.local`. Never use the browser anon key as the ETL database connection.

## Spreadsheet ETL

The source spreadsheets are imported through the reusable pipeline in [etl/README.md](etl/README.md):

```bash
python -m etl.run_import --dry-run \
	etl/source/infaq.csv etl/source/wakaf.csv \
	--vendor-file 'etl/source/Rekening Vendor.txt'
```

For a database import, set `SUPABASE_DB_MOSQUE_URL` to a direct SSL PostgreSQL connection string and apply the migrations and seed SQL described in the ETL README.

The pipeline preserves raw source rows in `staging`, normalizes master data, uses `INF*`/`WKF*` as unique `transactions.external_id` values, and records batch and row-level import errors.