# Mosque Financial System — PostgreSQL Schema Specification

## 1. General Design Principles

Build a normalized PostgreSQL schema for a mosque financial management system.

The system manages multiple financial funds such as:

* Infaq
* Wakaf
* Qurban
* Zakat
* Social
* Other future funds

The system must support:

1. Income and expense transactions.
2. Separate financial funds.
3. Transaction categories.
4. Activities/projects/events.
5. Vendors and vendor bank accounts.
6. Cash/bank accounts used by the mosque.
7. Reimbursement tracking.
8. Receipt/document references.
9. Monthly financial analytics.
10. Fund-level financial summaries.
11. Category-level monthly summaries.

### Important modeling rules

* Do NOT store `credit` and `debit` as separate amount columns.
* Use `transaction_type` + `amount`.
* `transaction_type` must distinguish `INCOME` and `EXPENSE`.
* Do NOT store `month` separately; derive month/year from `transaction_date`.
* Do NOT store running `balance` in the transaction table.
* Balance must be calculated from income minus expense.
* Master data should be referenced using foreign keys instead of free-text values.
* Analytical reports should be implemented as SQL views, not manually maintained tables.
* Foreign keys should use PostgreSQL `BIGINT`/`UUID` consistently throughout the schema.
* Monetary amounts should use `NUMERIC(15,2)`, never floating-point types.
* Use `TIMESTAMPTZ` for audit timestamps.
* All master data should support soft deactivation using an `active` boolean.
* Foreign keys should use `ON DELETE RESTRICT` or `ON DELETE SET NULL` where appropriate. Do not cascade-delete financial transaction history.

---

# 2. Table: funds

Represents separate pools of mosque funds.

Examples:

* Infaq
* Wakaf
* Qurban
* Zakat
* Social

### Columns

| Column      | Type         | Constraints                      | Description                                         |
| ----------- | ------------ | -------------------------------- | --------------------------------------------------- |
| id          | BIGINT       | PK, GENERATED ALWAYS AS IDENTITY | Unique fund ID                                      |
| code        | VARCHAR(30)  | UNIQUE, NOT NULL                 | Stable machine-readable code, e.g. `INFAQ`, `WAKAF` |
| name        | VARCHAR(100) | UNIQUE, NOT NULL                 | Human-readable fund name                            |
| description | TEXT         | NULL                             | Description of the fund                             |
| active      | BOOLEAN      | NOT NULL DEFAULT TRUE            | Whether this fund can still be used                 |
| created_at  | TIMESTAMPTZ  | NOT NULL DEFAULT NOW()           | Record creation timestamp                           |
| updated_at  | TIMESTAMPTZ  | NOT NULL DEFAULT NOW()           | Last update timestamp                               |

### Notes

A fund represents financial separation.

Transactions belonging to `WAKAF` must not be mixed with transactions belonging to `INFAQ`.

---

# 3. Table: categories

Represents transaction categories.

Examples:

Income categories:

* Infaq
* Donation
* Qurban
* Wakaf Donation
* Other Income

Expense categories:

* Operational
* Kajian
* Equipment
* Social
* TPA
* Bank Administration
* Material
* Labor
* Other Expense

### Columns

| Column      | Type         | Constraints                      | Description                                          |
| ----------- | ------------ | -------------------------------- | ---------------------------------------------------- |
| id          | BIGINT       | PK, GENERATED ALWAYS AS IDENTITY | Unique category ID                                   |
| code        | VARCHAR(50)  | UNIQUE, NOT NULL                 | Stable machine-readable category code                |
| name        | VARCHAR(100) | NOT NULL                         | Category display name                                |
| parent_id   | BIGINT       | FK → categories.id, NULL         | Optional parent category for hierarchical categories |
| description | TEXT         | NULL                             | Category description                                 |
| active      | BOOLEAN      | NOT NULL DEFAULT TRUE            | Whether category is active                           |
| created_at  | TIMESTAMPTZ  | NOT NULL DEFAULT NOW()           | Record creation timestamp                            |
| updated_at  | TIMESTAMPTZ  | NOT NULL DEFAULT NOW()           | Last update timestamp                                |

### FK

`parent_id → categories.id`

Use `ON DELETE RESTRICT`.

### Notes

Categories are financial classifications.

Do not use the category table to represent a project/event such as `Ruang Sound`.

---

# 4. Table: activities

Represents a project, event, program, or activity associated with transactions.

Examples:

* Ruang Sound
* Kajian Jumat
* TPA
* Donor Darah
* Qurban 2026

### Columns

| Column      | Type         | Constraints                      | Description                       |
| ----------- | ------------ | -------------------------------- | --------------------------------- |
| id          | BIGINT       | PK, GENERATED ALWAYS AS IDENTITY | Unique activity ID                |
| fund_id     | BIGINT       | FK → funds.id, NULL              | Fund associated with the activity |
| code        | VARCHAR(50)  | UNIQUE, NULL                     | Optional activity code            |
| name        | VARCHAR(150) | NOT NULL                         | Activity/project name             |
| description | TEXT         | NULL                             | Activity description              |
| start_date  | DATE         | NULL                             | Activity/project start date       |
| end_date    | DATE         | NULL                             | Activity/project end date         |
| active      | BOOLEAN      | NOT NULL DEFAULT TRUE            | Whether activity is active        |
| created_at  | TIMESTAMPTZ  | NOT NULL DEFAULT NOW()           | Record creation timestamp         |
| updated_at  | TIMESTAMPTZ  | NOT NULL DEFAULT NOW()           | Last update timestamp             |

### FK

`fund_id → funds.id`

Use `ON DELETE SET NULL`.

### Notes

Activity is intentionally different from category.

Example:

```text
Fund       = WAKAF
Category   = MATERIAL
Activity   = RUANG SOUND
Description = Material batu
```

---

# 5. Table: persons

Represents people involved in financial transactions.

Examples:

* Treasurer
* Mosque committee member
* Person paying for an expense first
* Person receiving reimbursement
* Worker receiving payment

### Columns

| Column     | Type         | Constraints                      | Description                   |
| ---------- | ------------ | -------------------------------- | ----------------------------- |
| id         | BIGINT       | PK, GENERATED ALWAYS AS IDENTITY | Unique person ID              |
| name       | VARCHAR(150) | NOT NULL                         | Person's full name            |
| phone      | VARCHAR(30)  | NULL                             | Phone number                  |
| role       | VARCHAR(100) | NULL                             | Optional role, e.g. Treasurer |
| notes      | TEXT         | NULL                             | Additional information        |
| active     | BOOLEAN      | NOT NULL DEFAULT TRUE            | Whether person is active      |
| created_at | TIMESTAMPTZ  | NOT NULL DEFAULT NOW()           | Record creation timestamp     |
| updated_at | TIMESTAMPTZ  | NOT NULL DEFAULT NOW()           | Last update timestamp         |

### Notes

Do not store personal information that is unnecessary for financial management.

---

# 6. Table: vendors

Represents external vendors, suppliers, workers, or payment recipients.

Examples:

* Building material store
* Pak Radi
* Pak Supri
* Electricity provider

### Columns

| Column              | Type         | Constraints                      | Description                         |
| ------------------- | ------------ | -------------------------------- | ----------------------------------- |
| id                  | BIGINT       | PK, GENERATED ALWAYS AS IDENTITY | Unique vendor ID                    |
| name                | VARCHAR(150) | NOT NULL                         | Vendor/person/business name         |
| phone               | VARCHAR(30)  | NULL                             | Vendor phone number                 |
| address             | TEXT         | NULL                             | Vendor address                      |
| bank_name           | VARCHAR(100) | NULL                             | Bank used for payment               |
| bank_account_number | VARCHAR(100) | NULL                             | Vendor bank account number          |
| bank_account_name   | VARCHAR(150) | NULL                             | Name registered on the bank account |
| notes               | TEXT         | NULL                             | Additional notes                    |
| active              | BOOLEAN      | NOT NULL DEFAULT TRUE            | Whether vendor is active            |
| created_at          | TIMESTAMPTZ  | NOT NULL DEFAULT NOW()           | Record creation timestamp           |
| updated_at          | TIMESTAMPTZ  | NOT NULL DEFAULT NOW()           | Last update timestamp               |

### Notes

Vendor information is optional for a transaction.

Do not require every transaction to have a vendor.

For example:

* Opening balance → no vendor
* Friday infaq → no vendor
* Bank administration → vendor may be NULL
* Material purchase → vendor recommended
* Worker payment → vendor/person can be recorded

---

# 7. Table: accounts

Represents mosque financial accounts/payment sources.

Examples:

* Cash Operational
* BSI Operational
* Cash Wakaf
* BSI Wakaf

### Columns

| Column         | Type         | Constraints                      | Description                                      |
| -------------- | ------------ | -------------------------------- | ------------------------------------------------ |
| id             | BIGINT       | PK, GENERATED ALWAYS AS IDENTITY | Unique account ID                                |
| fund_id        | BIGINT       | FK → funds.id, NULL              | Fund primarily associated with this account      |
| name           | VARCHAR(100) | NOT NULL                         | Account name                                     |
| account_type   | VARCHAR(20)  | NOT NULL                         | `CASH`, `BANK`, or other supported account types |
| bank_name      | VARCHAR(100) | NULL                             | Bank name if account_type is BANK                |
| account_number | VARCHAR(100) | NULL                             | Bank account number                              |
| account_name   | VARCHAR(150) | NULL                             | Account holder name                              |
| description    | TEXT         | NULL                             | Account description                              |
| active         | BOOLEAN      | NOT NULL DEFAULT TRUE            | Whether account is active                        |
| created_at     | TIMESTAMPTZ  | NOT NULL DEFAULT NOW()           | Record creation timestamp                        |
| updated_at     | TIMESTAMPTZ  | NOT NULL DEFAULT NOW()           | Last update timestamp                            |

### FK

`fund_id → funds.id`

Use `ON DELETE SET NULL`.

### Notes

Do not store `Bank` or `Cash` as free text inside transactions.

Transaction references an account, and the account defines whether it is cash or bank.

---

# 8. Table: transactions

The core financial ledger.

Every financial movement is represented by one transaction.

### Columns

| Column               | Type          | Constraints                       | Description                                  |
| -------------------- | ------------- | --------------------------------- | -------------------------------------------- |
| id                   | BIGINT        | PK, GENERATED ALWAYS AS IDENTITY  | Unique transaction ID                        |
| transaction_date     | DATE          | NOT NULL                          | Date when transaction occurred               |
| fund_id              | BIGINT        | FK → funds.id, NOT NULL           | Financial fund affected                      |
| category_id          | BIGINT        | FK → categories.id, NOT NULL      | Financial category                           |
| activity_id          | BIGINT        | FK → activities.id, NULL          | Related activity/project/event               |
| transaction_type     | VARCHAR(20)   | NOT NULL                          | `INCOME` or `EXPENSE`                        |
| amount               | NUMERIC(15,2) | NOT NULL                          | Transaction amount, always positive          |
| description          | TEXT          | NOT NULL                          | Human-readable transaction description       |
| vendor_id            | BIGINT        | FK → vendors.id, NULL             | Vendor/payment recipient                     |
| person_id            | BIGINT        | FK → persons.id, NULL             | Person associated with the transaction       |
| account_id           | BIGINT        | FK → accounts.id, NULL            | Cash/bank account used                       |
| reimbursement_status | VARCHAR(30)   | NOT NULL DEFAULT 'NOT_APPLICABLE' | Reimbursement state                          |
| reference_number     | VARCHAR(100)  | NULL                              | External/reference number, e.g. `E072126-00` |
| receipt_url          | TEXT          | NULL                              | URL/path to receipt/document                 |
| notes                | TEXT          | NULL                              | Additional notes                             |
| created_at           | TIMESTAMPTZ   | NOT NULL DEFAULT NOW()            | Record creation timestamp                    |
| updated_at           | TIMESTAMPTZ   | NOT NULL DEFAULT NOW()            | Last update timestamp                        |

### Primary key

`id`

### Foreign keys

```text
fund_id       → funds.id
category_id   → categories.id
activity_id   → activities.id
vendor_id     → vendors.id
person_id     → persons.id
account_id    → accounts.id
```

### Recommended FK behavior

```text
fund_id       → ON DELETE RESTRICT
category_id   → ON DELETE RESTRICT
activity_id   → ON DELETE SET NULL
vendor_id     → ON DELETE SET NULL
person_id     → ON DELETE SET NULL
account_id    → ON DELETE SET NULL
```

### Constraints

`amount > 0`

`transaction_type IN ('INCOME', 'EXPENSE')`

`reimbursement_status IN ('NOT_APPLICABLE', 'PENDING', 'REIMBURSED')`

### Important rules

Do not store:

* credit
* debit
* balance
* month
* year

These are derived values.

For example:

```text
INCOME  + 1000000
EXPENSE + 250000
```

The financial balance is calculated as:

```text
SUM(INCOME) - SUM(EXPENSE)
```

### Opening balance

Opening balances should be represented as transactions.

Example:

```text
transaction_type = INCOME
category         = OPENING_BALANCE
description      = Saldo akhir 2025
amount           = 10946700
```

---

# 9. Table: receipts

Represents receipt/document metadata.

Receipt files themselves may be stored in Google Drive, S3, or another storage provider.

### Columns

| Column           | Type         | Constraints                      | Description                         |
| ---------------- | ------------ | -------------------------------- | ----------------------------------- |
| id               | BIGINT       | PK, GENERATED ALWAYS AS IDENTITY | Unique receipt ID                   |
| transaction_id   | BIGINT       | FK → transactions.id, NOT NULL   | Transaction associated with receipt |
| storage_provider | VARCHAR(50)  | NULL                             | e.g. `GOOGLE_DRIVE`, `S3`           |
| file_path        | TEXT         | NULL                             | Storage path/key                    |
| file_name        | VARCHAR(255) | NULL                             | Original file name                  |
| mime_type        | VARCHAR(100) | NULL                             | File MIME type                      |
| ocr_status       | VARCHAR(30)  | NOT NULL DEFAULT 'NOT_PROCESSED' | OCR processing status               |
| ocr_data         | JSONB        | NULL                             | Raw/normalized OCR output           |
| uploaded_at      | TIMESTAMPTZ  | NOT NULL DEFAULT NOW()           | Upload timestamp                    |
| created_at       | TIMESTAMPTZ  | NOT NULL DEFAULT NOW()           | Record creation timestamp           |

### FK

`transaction_id → transactions.id`

Use `ON DELETE CASCADE`.

### Notes

A transaction may have zero or more receipts.

Do not store the actual image binary in PostgreSQL.

Store the file in object/file storage and keep its reference in this table.

---

# 10. Table: reimbursements

Use this table when reimbursement tracking needs more detail than a simple transaction status.

This table represents money that must be returned to a person who initially paid an expense.

### Columns

| Column         | Type          | Constraints                      | Description                          |
| -------------- | ------------- | -------------------------------- | ------------------------------------ |
| id             | BIGINT        | PK, GENERATED ALWAYS AS IDENTITY | Unique reimbursement ID              |
| transaction_id | BIGINT        | FK → transactions.id, NOT NULL   | Original expense transaction         |
| person_id      | BIGINT        | FK → persons.id, NOT NULL        | Person to reimburse                  |
| amount         | NUMERIC(15,2) | NOT NULL                         | Amount to reimburse                  |
| status         | VARCHAR(30)   | NOT NULL DEFAULT 'PENDING'       | `PENDING`, `REIMBURSED`, `CANCELLED` |
| requested_at   | TIMESTAMPTZ   | NOT NULL DEFAULT NOW()           | Reimbursement request timestamp      |
| reimbursed_at  | TIMESTAMPTZ   | NULL                             | Actual reimbursement timestamp       |
| notes          | TEXT          | NULL                             | Additional notes                     |
| created_at     | TIMESTAMPTZ   | NOT NULL DEFAULT NOW()           | Record creation timestamp            |
| updated_at     | TIMESTAMPTZ   | NOT NULL DEFAULT NOW()           | Last update timestamp                |

### Foreign keys

```text
transaction_id → transactions.id
person_id      → persons.id
```

### Notes

This table is optional for the first MVP.

If reimbursement requirements remain simple, `transactions.reimbursement_status` may be sufficient.

If the application needs proper reimbursement workflow, use this table.

---

# 11. View: v_financial_summary

Provides high-level financial summary.

The view must calculate:

* Total income
* Total expense
* Balance

Grouped at least by fund.

Expected conceptual output:

| fund  | total_income | total_expense | balance |
| ----- | -----------: | ------------: | ------: |
| Infaq |          ... |           ... |     ... |
| Wakaf |          ... |           ... |     ... |

Balance:

```text
total_income - total_expense
```

Do not store this data physically.

---

# 12. View: v_monthly_category_summary

Provides monthly financial summary grouped by:

* year
* month
* fund
* category

Expected columns:

| Column        | Description       |
| ------------- | ----------------- |
| year          | Transaction year  |
| month         | Transaction month |
| fund_id       | Fund ID           |
| fund_name     | Fund name         |
| category_id   | Category ID       |
| category_name | Category name     |
| total_income  | Total income      |
| total_expense | Total expense     |

Example:

```text
2026 | 1 | Infaq | Operasional    | 10,946,700 | 2,568,000
2026 | 1 | Infaq | Kajian         | 0           | 2,375,000
2026 | 1 | Infaq | Infaq          | 3,556,800   | 0
2026 | 1 | Infaq | Perlengkapan   | 0           | 198,000
```

Do not store month as a separate transaction column.

Derive it from:

```sql
EXTRACT(YEAR FROM transaction_date)
EXTRACT(MONTH FROM transaction_date)
```

or use `DATE_TRUNC`.

---

# 13. View: v_monthly_fund_summary

Provides monthly summary grouped by fund.

Expected output:

| year | month | fund  | total_income | total_expense | balance |
| ---: | ----: | ----- | -----------: | ------------: | ------: |
| 2026 |     1 | Infaq |          ... |           ... |     ... |
| 2026 |     1 | Wakaf |          ... |           ... |     ... |

Balance must be calculated as:

```text
total_income - total_expense
```

---

# 14. View: v_reimbursement_summary

Provides reimbursement information.

Expected output:

| person | pending_amount | reimbursed_amount |
| ------ | -------------: | ----------------: |
| Dian   |            ... |               ... |
| Ahmad  |            ... |               ... |

If the `reimbursements` table is not implemented initially, this view may instead aggregate transactions using `reimbursement_status`.

---

# 15. Recommended indexes

Create indexes on frequently queried foreign keys and transaction dates.

At minimum:

```text
transactions.transaction_date
transactions.fund_id
transactions.category_id
transactions.activity_id
transactions.vendor_id
transactions.person_id
transactions.account_id
transactions.transaction_type
transactions.reimbursement_status

activities.fund_id
accounts.fund_id
receipts.transaction_id
reimbursements.transaction_id
reimbursements.person_id
```

Consider composite indexes for common reporting queries, especially:

```text
transactions(fund_id, transaction_date)
transactions(category_id, transaction_date)
transactions(fund_id, category_id, transaction_date)
```

Do not blindly create every possible index.

---

# 16. Recommended constraints and validation

The database should enforce:

```text
amount > 0
transaction_type ∈ ('INCOME', 'EXPENSE')
reimbursement_status ∈ ('NOT_APPLICABLE', 'PENDING', 'REIMBURSED')
```

For `reimbursements`:

```text
amount > 0
status ∈ ('PENDING', 'REIMBURSED', 'CANCELLED')
```

Prevent invalid date ranges:

```text
activities.end_date >= activities.start_date
```

when both dates are present.

---

# 17. Seed/master data

The initial seed should include at least:

### Funds

```text
INFAQ
WAKAF
```

### Suggested categories

```text
OPENING_BALANCE
INFAQ
DONATION
OPERATIONAL
KAJIAN
EQUIPMENT
SOCIAL
TPA
QURBAN
BANK_ADMINISTRATION
MATERIAL
LABOR
OTHER_INCOME
OTHER_EXPENSE
```

Do not assume all categories must be used by all funds.

---

# 18. Example mapping from existing spreadsheet

Existing:

```text
Income
Rp 10,946,700
01/01/2026
Operasional
Saldo 2025
```

becomes:

```text
fund_id         = INFAQ
category_id     = OPENING_BALANCE
transaction_type = INCOME
amount          = 10946700
transaction_date = 2026-01-01
description     = Saldo 2025
```

Existing:

```text
Expense
Rp 580,000
21/07/2026
Ruang Sound
Material batu
E072126-00
Bank
```

becomes:

```text
fund_id          = WAKAF
category_id      = MATERIAL
activity_id      = RUANG_SOUND
transaction_type = EXPENSE
amount           = 580000
transaction_date = 2026-07-21
description      = Material batu
reference_number = E072126-00
account_id       = BSI_WAKAF
vendor_id        = appropriate vendor if known
```

Existing:

```text
Expense
Rp 700,000
25/07/2026
Ruang Sound
Upah tukang Pak Radi
E072526-00
Cash
```

becomes:

```text
fund_id          = WAKAF
category_id      = LABOR
activity_id      = RUANG_SOUND
transaction_type = EXPENSE
amount           = 700000
transaction_date = 2026-07-25
description      = Upah tukang Pak Radi
reference_number = E072526-00
account_id       = KAS_WAKAF
vendor_id        = PAK_RADI
```

---

# 19. Implementation instructions for AI coding agent

Generate the PostgreSQL DDL based strictly on this specification.

Requirements:

1. Use PostgreSQL syntax.
2. Prefer `BIGINT GENERATED ALWAYS AS IDENTITY` for primary keys.
3. Use explicit foreign key constraints.
4. Use appropriate `ON DELETE` behavior as specified.
5. Use `NUMERIC(15,2)` for monetary values.
6. Add CHECK constraints for enumerated values.
7. Add indexes specified above.
8. Create tables in dependency order.
9. Create views after all required tables exist.
10. Include seed data for initial funds and categories.
11. Use idempotent migrations where practical.
12. Do not create redundant `credit`, `debit`, `balance`, `month`, or `year` columns.
13. Do not duplicate the same financial data in analytics tables.
14. Add comments to tables and important columns using PostgreSQL `COMMENT ON`.
15. Keep the schema compatible with Supabase PostgreSQL.
16. Do not introduce additional tables unless required by the specification.
17. If there is an ambiguity, prefer normalized relational modeling and document the assumption in the migration comments.

The generated DDL should be organized as a migration that can be executed against a fresh Supabase PostgreSQL database.
