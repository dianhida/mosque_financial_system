# Schema Design Rationale

This database is designed as a normalized financial ledger for mosque fund management.

The key design principle is to separate **financial facts**, **master data**, and **analytics**.

## Financial facts

`transactions` is the single source of truth for financial movements.

Each transaction has:

* one date
* one fund
* one category
* optional activity/project
* one transaction type (`INCOME` or `EXPENSE`)
* one positive amount

Income and expense must not be represented using separate amount columns.

For example:
      
```text
INCOME  + 1000000
EXPENSE + 250000
```

The balance is always calculated:

```text
balance = total_income - total_expense
```

The transaction table must therefore never contain a stored running balance.

## Master data

Master tables provide controlled and reusable classifications:

```text
funds
categories
activities
vendors
persons
accounts
```

This prevents inconsistent free-text values such as:

```text
Bank
BANK
BSI
Bsi
Kas
Cash
```

Instead, the transaction references a proper `account`.

Similarly, `Ruang Sound` is modeled as an `activity`, while `Material` is modeled as a financial `category`.

This distinction is important.

Example:

```text
Fund       = WAKAF
Activity   = RUANG SOUND
Category   = MATERIAL
Description = Material batu
```

## Fund separation

Funds represent separate pools of money.

For example:

```text
INFAQ
WAKAF
```

must remain distinguishable throughout the system.

A transaction always belongs to one fund.

This allows the system to answer questions such as:

* How much money does the Infaq fund have?
* How much money does the Wakaf fund have?
* How much has been spent on the Wakaf Ruang Sound project?
* What are the monthly expenses for the Infaq fund?

## Activities vs categories

An activity is a project, event, or program.

A category describes the financial nature of a transaction.

Example:

```text
Activity: Ruang Sound
Category: Material
```

Multiple transactions can therefore belong to the same activity:

```text
Material batu
Material pasir
Material besi
Boven
Bata ringan
Upah tukang
```

This makes project-level reporting possible without abusing the category field.

## Vendors

Vendors represent external parties receiving money.

Vendor information is optional because not every transaction has a meaningful vendor.

Examples:

```text
Material purchase → vendor
Worker payment    → vendor/person
Opening balance   → no vendor
Friday infaq      → no vendor
```

Vendor bank information is stored to support future payment workflows.

## Reimbursements

A reimbursement occurs when someone pays an expense personally and the mosque owes that person money.

Simple cases can use:

```text
transactions.reimbursement_status
```

If the workflow becomes more complex, the `reimbursements` table provides a dedicated reimbursement lifecycle.

Possible states:

```text
NOT_APPLICABLE
PENDING
REIMBURSED
```

## Receipts

Receipt files should not be stored directly inside PostgreSQL.

The database stores metadata and references to external storage such as:

```text
Google Drive
Amazon S3
```

This enables future automation:

```text
Receipt upload
      ↓
n8n
      ↓
OCR / Amazon Textract
      ↓
Transaction extraction
      ↓
Transaction creation/update
```

## Analytics

The database uses SQL views for reporting instead of duplicating transaction data.

Important analytical views include:

```text
v_financial_summary
v_monthly_category_summary
v_monthly_fund_summary
v_reimbursement_summary
```

These views calculate totals dynamically from `transactions`.

This prevents inconsistencies where a transaction is updated but a manually maintained summary table is not updated.

## Spreadsheet migration philosophy

The existing spreadsheet is considered a presentation/input format, not the database model.

Fields such as:

```text
Kredit
Debit
Saldo
Bulan
```

should not be copied directly into the normalized database.

Instead:

```text
Kredit/Debit → transaction_type + amount
Bulan        → derived from transaction_date
Saldo        → calculated from transactions
Event        → category and/or activity
Bank/Cash    → accounts
Reimburse    → reimbursement workflow
```

The application and reporting layer can reproduce the familiar spreadsheet-style output without storing spreadsheet-specific redundancy.

## Future architecture

The intended application architecture is:

```text
Next.js
   ↓
Supabase PostgreSQL
   ↑
n8n
   ↓
Google Drive / S3
   ↓
OCR / AI processing
```

The PostgreSQL database remains the source of truth.

n8n performs automation and integration.

Next.js provides the user interface.

Analytics views provide standardized data for dashboards and reports.

The schema should remain simple enough for a small mosque finance operation while being extensible for future automation.
