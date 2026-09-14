# Build Mosque Financial Management Web App

Build a desktop-first financial management web application for mosque financial administration.

The application will replace the current spreadsheet-based workflow.

## 1. Tech Stack

Use the existing project stack where possible:

* Next.js
* TypeScript
* Tailwind CSS
* Supabase PostgreSQL
* Supabase Auth if authentication is already configured
* Supabase Storage for receipt files
* Responsive UI, but optimize primarily for desktop/laptop usage

Do not introduce another frontend framework.

The database schema already exists in Supabase. Treat the existing database schema as the source of truth.

**Do not modify or recreate the database schema unless explicitly necessary.**

The application should consume the existing tables, relationships, and reporting views.

---

# 2. Main Application Layout

Use an application-style desktop layout.

Recommended structure:

```text
┌───────────────────────────────────────────────────────────────┐
│ Header                                                        │
│ Logo / Mosque Finance       Fund / Navigation / User         │
├──────────────┬────────────────────────────────────────────────┤
│ Sidebar      │                                                │
│              │              Page Content                      │
│ Dashboard    │                                                │
│ Transactions │                                                │
│ Master Data  │                                                │
│              │                                                │
└──────────────┴────────────────────────────────────────────────┘
```

The application should feel like an internal business/finance application rather than a marketing website.

Use a clean, professional financial-dashboard style.

---

# 3. Landing Page = Dashboard

The `/` route should be the main Dashboard.

The dashboard should provide quick access to:

* INFAQ dashboard
* WAKAF dashboard
* latest transactions
* quick financial indicators
* navigation to transaction management
* navigation to master data configuration

Do not make the landing page a marketing/landing page.

It is an authenticated application dashboard.

---

# 4. Header / Navigation

Create a persistent application header/sidebar.

Navigation should include:

```text
Dashboard
Transactions
Master Data
```

Master Data should have a dropdown/sub-navigation because there are multiple master tables.

For example:

```text
Master Data
  ├── Funds
  ├── Categories
  ├── Activities
  ├── Vendors
  ├── Persons
  └── Accounts
```

The exact routing structure can be:

```text
/master/funds
/master/categories
/master/activities
/master/vendors
/master/persons
/master/accounts
```

or another clean equivalent.

The navigation should remain accessible from all pages.

---

# 5. Page 1 — Master Data Configuration

Create a generic master-data management UI.

The user should be able to select the master data type from the Master Data navigation/dropdown.

Supported master data:

```text
Funds
Categories
Activities
Vendors
Persons
Accounts
```

Each master page should display:

* page title
* description
* existing records in a table
* search/filter if useful
* Add button
* Edit button where appropriate
* Delete button
* active/inactive status where the table supports it

Example:

```text
Master Data > Vendors

┌──────────────────────────────────────────────────────────────┐
│ Vendors                                      [+ Add Vendor]   │
├────────────┬───────────────┬───────────────┬─────────────────┤
│ Name       │ Phone         │ Bank          │ Status          │
├────────────┼───────────────┼───────────────┼─────────────────┤
│ Vendor A   │ ...           │ BSI           │ Active          │
│ Vendor B   │ ...           │ BCA           │ Active          │
└────────────┴───────────────┴───────────────┴─────────────────┘
```

Use modal/dialog forms for Add/Edit where appropriate.

## Master-specific fields

Respect the existing database schema.

### Funds

Fields include:

```text
code
name
description
active
```

### Categories

Fields include:

```text
code
name
parent_id
description
active
```

`parent_id` should be implemented as a dropdown/select from existing categories.

### Activities

Fields include:

```text
fund_id
code
name
description
start_date
end_date
active
```

`fund_id` must be a dropdown populated from Funds.

### Persons

Fields include:

```text
name
phone
role
notes
active
```

### Vendors

Fields include:

```text
name
phone
address
bank_name
bank_account_number
bank_account_name
notes
active
```

### Accounts

Fields include:

```text
fund_id
name
account_type
bank_name
account_number
account_name
description
active
```

`fund_id` should be a dropdown.

`account_type` should be a select such as:

```text
CASH
BANK
```

Do not allow users to manually type foreign-key IDs.

Use human-readable dropdowns.

---

# 6. Page 2 — Transactions

Create a full-page transaction management screen.

Route can be:

```text
/transactions
```

The default view should display **transactions for the current month**.

Example:

```text
Transactions

[ September 2026 ▼ ]                         [+ Add Transaction]

┌────────────┬─────────┬────────────┬──────────┬───────────────┐
│ Date       │ Fund    │ Category   │ Type     │ Amount        │
├────────────┼─────────┼────────────┼──────────┼───────────────┤
│ 03 Sep     │ Infaq   │ Operational│ Expense  │ Rp 50,000     │
│ 02 Sep     │ Wakaf   │ Material   │ Expense  │ Rp 500,000    │
└────────────┴─────────┴────────────┴──────────┴───────────────┘
```

Provide filters for:

* month/date
* fund
* category
* activity
* transaction type
* account
* reimbursement status if applicable

The default date filter is the current month.

Allow the user to change the month/date range.

---

# 7. Add Transaction

Provide a prominent:

```text
+ Add Transaction
```

button.

Use a modal or dedicated form page.

The transaction form must respect the existing database relationships.

Fields:

```text
Transaction Date
Fund
Category
Activity
Transaction Type
Amount
Description
Vendor
Person
Account
Reference Number
Receipt
Notes
```

Transaction Type:

```text
INCOME
EXPENSE
```

Amount must be a positive number.

Do NOT create separate Credit/Debit input fields.

The financial direction is determined by:

```text
transaction_type
```

---

# 8. Many-to-One / Foreign-Key Dependencies

All relational fields must use dropdowns/selects populated from the relevant master data.

Do not expose numeric database IDs to the user.

Examples:

```text
fund_id       → Funds
category_id   → Categories
activity_id   → Activities
vendor_id     → Vendors
person_id     → Persons
account_id    → Accounts
```

## Dependent dropdowns

Implement sensible dependency filtering.

For example:

### Activity

When the user selects:

```text
Fund = WAKAF
```

the Activity dropdown should preferentially show activities belonging to WAKAF.

### Account

When the user selects:

```text
Fund = WAKAF
```

the Account dropdown should show relevant WAKAF accounts.

### Category

Category selection should come from the Categories master.

If the existing schema does not enforce fund/category relationships, do not invent database relationships that do not exist. Handle filtering only where the existing schema supports it.

---

# 9. Reimbursement

Transaction entry must support reimbursement information.

The existing design has a separate:

```text
reimbursements
```

table.

Do not duplicate reimbursement amount unnecessarily if the reimbursement represents the full transaction amount.

The transaction amount remains the source of truth for the transaction amount.

If the existing reimbursement model supports:

```text
transaction_id
person_id
status
requested_at
reimbursed_at
notes
```

use that model.

The UI should allow the user to indicate that an expense requires reimbursement.

For example:

```text
☐ Requires reimbursement
```

If enabled:

```text
Reimbursement Person
Status
Notes
```

should become available.

Do not create a second reimbursement amount field unless the existing schema explicitly supports partial/multiple reimbursements.

Do not maintain duplicate reimbursement status in both transaction and reimbursement records if the database design has already removed that redundancy.

---

# 10. Receipt Upload

Allow receipt upload when creating/editing a transaction.

Receipt files should be stored using the existing receipt/storage architecture.

Prefer:

```text
Supabase Storage
```

for the actual file.

The database should store receipt metadata/reference, not binary file contents.

The UI should show:

```text
Upload Receipt
```

and after upload:

```text
Receipt uploaded
[View]
```

Do not implement OCR in the frontend.

OCR will later be handled by n8n + AWS Textract.

---

# 11. Page 3 — Dashboards

Create two separate financial dashboards:

```text
/dashboard/infaq
/dashboard/wakaf
```

Do not create one generic dashboard containing all reporting logic.

INFAQ and WAKAF have different reporting requirements.

---

# 12. INFAQ Dashboard

The INFAQ dashboard should consume:

```text
v_infaq_summary
v_infaq_monthly_category_expense
```

The summary view contains:

```text
current_balance
latest_month
previous_month_balance
latest_month_income
latest_month_expense
```

Display these as prominent KPI cards.

Example:

```text
INFAQ

┌──────────────────┐
│ Current Balance  │
│ Rp 11.810.311    │
└──────────────────┘

┌──────────────────┐
│ Latest Month     │
│ August 2026      │
└──────────────────┘

┌──────────────────┐
│ Previous Balance │
│ Rp xx.xxx.xxx    │
└──────────────────┘

┌──────────────────┐
│ Income           │
│ Rp x.xxx.xxx     │
└──────────────────┘

┌──────────────────┐
│ Expense          │
│ Rp x.xxx.xxx     │
└──────────────────┘
```

Below the KPI cards, display:

### Monthly Expense by Category

Use:

```text
v_infaq_monthly_category_expense
```

Display a table and/or chart.

Example:

```text
Expense by Category — August 2026

Operational       Rp 888,000
Kajian             Rp 2,375,000
Equipment          Rp 1,096,000
Social             Rp 92,000
TPA                Rp 400,000
```

A bar chart is preferred if the data supports it, with a table below/alongside it for exact values.

The dashboard should clearly communicate that this is the **latest month's** category expense.

---

# 13. WAKAF Dashboard

The WAKAF dashboard should consume:

```text
v_wakaf_summary
v_wakaf_activity_expense
```

No monthly breakdown is required.

The main KPIs should include:

```text
Total Collected
Total Used
Current Balance
```

Example:

```text
WAKAF

┌──────────────────┐
│ Total Collected  │
│ Rp xx.xxx.xxx    │
└──────────────────┘

┌──────────────────┐
│ Total Used       │
│ Rp xx.xxx.xxx    │
└──────────────────┘

┌──────────────────┐
│ Current Balance  │
│ Rp xx.xxx.xxx    │
└──────────────────┘
```

Below this, display:

### Active Programs

Use:

```text
v_wakaf_activity_expense
```

Only display programs/activities that are currently active.

The purpose is to answer:

> "Dana wakaf sekarang sudah digunakan untuk program apa saja?"

Example:

```text
Active Programs

Ruang Sound
Used: Rp 4.XXX.XXX

Pembangunan Masjid
Used: Rp X.XXX.XXX
```

Do not show monthly grouping.

Prefer displaying the activity name, total expense used, and optionally the activity start/end date if available.

If an activity is inactive, do not display it in the active-program section.

---

# 14. Dashboard Design

The dashboards should be visually different enough to communicate their purpose, but use the same overall design system.

Recommended layout:

```text
Dashboard
├── INFAQ
│   ├── KPI Cards
│   ├── Latest Month Summary
│   └── Expense by Category
│
└── WAKAF
    ├── KPI Cards
    └── Active Programs
```

The main `/dashboard` or `/` page can provide a high-level overview with two cards/sections:

```text
INFAQ
Current Balance: ...

WAKAF
Current Balance: ...
```

with buttons:

```text
View INFAQ
View WAKAF
```

This keeps the landing page simple while allowing dedicated dashboards for each fund.

---

# 15. Suggestions / Additional Features

Implement these only if they fit naturally and do not overcomplicate the MVP.

### Transaction detail

Clicking a transaction should open a detail view showing:

* transaction information
* related fund/category/activity
* vendor/person
* account
* receipt
* reimbursement information
* reference number
* notes

### Quick actions

On dashboard:

```text
+ Add Transaction
View Transactions
```

### Search

Transaction page should support searching descriptions, reference numbers, vendors, etc.

### Pagination

Do not load an unlimited number of transactions into the browser.

Use pagination or server-side querying where appropriate.

### Currency formatting

All monetary values should be displayed in Indonesian Rupiah format:

```text
Rp 11.810.311
```

while the database continues storing numeric values.

### Date formatting

Display dates in Indonesian-friendly format, for example:

```text
03 Sep 2026
```

while keeping database values as proper DATE/TIMESTAMP types.

### Loading / empty / error states

Every page should have sensible:

* loading state
* empty state
* error state

Do not leave blank screens when data is unavailable.

---

# 16. Important Database Rules

The existing database is the source of truth.

Use:

```text
transactions
funds
categories
activities
vendors
persons
accounts
reimbursements
receipts
```

and the reporting views:

```text
v_infaq_summary
v_infaq_monthly_category_expense
v_wakaf_summary
v_wakaf_activity_expense
```

Do not recreate reporting calculations in multiple frontend components.

Where possible, consume the reporting views directly.

Do not store derived values such as:

```text
credit
debit
saldo
month
year
```

in the transaction table.

Transaction model:

```text
INCOME  + positive amount
EXPENSE + positive amount
```

Balance is calculated from transactions/views.

---

# 17. Security

Use Supabase authentication if authentication is already configured.

Do not expose Supabase service-role keys in the browser.

Only public/anon client configuration may be used client-side.

Respect Supabase Row Level Security if it exists.

Do not place secret AWS credentials, n8n credentials, or service-role credentials in frontend code.

---

# 18. Code Quality

Use reusable components where appropriate.

Suggested structure:

```text
components/
  layout/
  dashboard/
  transactions/
  master-data/
  ui/

lib/
  supabase/
  queries/
  utils/
```

Create reusable components for:

```text
DataTable
FormModal
CurrencyDisplay
KpiCard
SelectField
DatePicker
EmptyState
LoadingState
```

Avoid duplicating Supabase queries throughout components.

Keep database access/query logic separated from UI components where practical.

---

# 19. Implementation Order

Implement in this order:

### Phase 1

Application shell:

* Header/sidebar
* Routing
* Dashboard landing page
* Basic styling

### Phase 2

Master data:

* Funds
* Categories
* Activities
* Vendors
* Persons
* Accounts
* CRUD

### Phase 3

Transactions:

* Current-month transaction table
* Filters
* Add transaction
* Foreign-key dropdowns
* Dependent selections
* Edit/delete
* Reimbursement
* Receipt upload

### Phase 4

INFAQ dashboard:

* `v_infaq_summary`
* `v_infaq_monthly_category_expense`

### Phase 5

WAKAF dashboard:

* `v_wakaf_summary`
* `v_wakaf_activity_expense`

### Phase 6

Polish:

* loading states
* error handling
* empty states
* pagination
* responsive behavior
* UX improvements

---

# 20. Critical Constraint

Do not redesign the database simply because a frontend implementation is inconvenient.

If something is unclear, inspect the existing Supabase schema and adapt the frontend to it.

The goal is:

```text
Next.js
   ↓
Supabase
   ↓
Existing PostgreSQL schema
   ↓
Reporting views
```

The web application should become the primary interface for entering and managing financial data.

The old spreadsheet is only for initial data migration/import and optional export/reporting.

Do not build the application around continuous synchronization with the old spreadsheet.

---

# Final Expected Result

The finished application should feel like a small but proper mosque financial management system:

```text
                    MOSQUE FINANCE
                         │
        ┌────────────────┼────────────────┐
        │                │                │
    Dashboard       Transactions     Master Data
        │                │                │
   ┌────┴────┐           │        ┌───────┴────────┐
   │         │           │        │                │
 INFAQ     WAKAF       Ledger   Funds          Categories
   │         │                    Activities     Vendors
   │         │                    Persons        Accounts
   │         │
 Summary   Summary
 Monthly   Active Programs
 Category  Activity Expense
 Expense
```

The application should prioritize **correct financial data, clean UX, clear separation between INFAQ and WAKAF reporting, and maintainability** over unnecessary complexity.
