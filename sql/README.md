# Mosque Financial System SQL

This folder contains Supabase/PostgreSQL migration files for the mosque financial management schema.

## Migration order

Apply the files in this order:

1. `migrations/models/20260902_001_common.sql`
2. `migrations/models/20260902_002_master_data.sql`
3. `migrations/models/20260902_003_financial_tables.sql`
4. `migrations/models/20260902_004_views.sql`
5. `migrations/models/20260905_005_etl_support.sql`
6. `migrations/models/20260906_006_fund_configuration.sql`
7. `migrations/models/20260908_007_repair_wakaf_summary_view.sql`
8. `migrations/models/20260908_008_infaq_monthly_reporting.sql`
9. `migrations/sample_data/20260902_101_seed_master_data.sql`
10. `migrations/sample_data/20260902_102_demo_transactions.sql`

## Design notes

- The schema keeps `transactions` as the single source of truth.
- `transaction_type` is either `INCOME` or `EXPENSE`.
- Monetary values use `NUMERIC(15,2)`.
- Balance is derived from totals, not stored as a column.
- Reporting logic is implemented with SQL views.
- Reimbursement amounts are read from the linked expense transaction.
- Seed data includes essential funds and categories for a fresh database.
- `transactions.external_id` supports idempotent spreadsheet imports.
- The `staging` schema stores raw source rows and import audit records.

## Reporting views

- `v_infaq_summary` provides current balance, latest month, previous cumulative balance, and latest-month totals.
- `v_infaq_monthly_category_expense` provides previous-month INFAQ income and expense cashflow by category.
- `v_wakaf_summary` provides the WAKAF target, latest manual balance, recorded expenses, estimated collected funds, and progress.
- `v_wakaf_activity_expense` provides WAKAF expenses grouped by activity.
- `v_unreimbursed_expense_summary` lists expenses without a completed reimbursement.

`v_wakaf_summary` repair migration `007` is needed when the earlier fund-configuration migration failed before the view was created. It also reloads the Supabase PostgREST schema cache.

`v_infaq_summary` and `v_infaq_monthly_category_expense` migration `008` uses the latest INFAQ transaction month as the current month and reports the prior month closing balance, income, expense, and as-of dates.

## Supabase usage

These files are compatible with the default `public` schema and can be applied with the Supabase SQL editor or migration tooling.
