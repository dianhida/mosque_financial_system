# Task: Fix Existing Features and Add Infaq & Wakaf Transaction Ledgers

Please inspect the existing codebase and implement the following changes. Follow the current application architecture, database schema, coding conventions, and UI design.

**Important:** Do not unnecessarily rebuild existing components or change unrelated functionality. Reuse existing logic and components wherever possible.

## PART 1 — FIXES

### 1. Use the Existing Logo as the Browser Favicon

- Locate the existing official logo used by the Mosque Financial System.
- Use that logo as the browser favicon (the icon displayed in the browser tab).
- Reuse the existing asset. Do not create a new logo or use a placeholder.
- Ensure the favicon works correctly in the production deployment, not just in the local development environment.
- Follow the favicon conventions of the existing framework (Next.js).

### 2. Fix Transaction Summary Month Calculation

**Current issue:**

Transaction summaries, including category summaries, are currently calculated based on the month of the latest available transaction minus one month.

This is incorrect because the reporting period should not depend on when the latest transaction was recorded.

**Expected behavior:**

- Determine the reporting month dynamically using the actual current system date.
- The reporting period must always be the previous calendar month relative to the current system month.
- Do not use the latest transaction date to determine the reporting period.
- All relevant transaction summaries and category summaries must follow this same reporting period.

**Example:**

If the current system date is November 12, 2026:
- Reporting month: October 2026.
- All transaction and category summaries must reflect October 2026.

If there are no transactions in the reporting month:
- All relevant summary values must display `0`.
- Do not fall back to an older month with available transactions.
- Ensure empty results do not cause `null`, `undefined`, or `NaN` values in the UI.

Also handle year transitions correctly. For example, if the current month is January 2027, the reporting month must be December 2026.

## PART 2 — NEW FEATURES: INFAQ & WAKAF TRANSACTION LEDGERS

Add two separate navigation menu items:

1. **Infaq Transactions**
2. **Wakaf Transactions**

Each menu must display a complete transaction ledger for its respective transaction type.

### 1. Transaction Data

- Infaq and Wakaf must be completely separated.
- Each page must retrieve all historical transactions belonging to its respective type.
- Display transactions from the beginning of the available transaction history up to the present.
- Do not restrict the results to the current month or a specific date range.
- Sort records by transaction date in descending order (newest first).
- Where multiple transactions share the same date, use a deterministic secondary sort, such as transaction creation time or ID.

### 2. Ledger Table Structure

Display the following columns in this exact order:

| Column | Description |
|---|---|
| Date | Transaction date |
| Description | Transaction description or relevant transaction details |
| Income / Expense | Transaction amount, visually distinguished by type |
| Current Balance | Cumulative balance immediately after applying that transaction |

**Important: Cumulative balance calculation**

The balance must represent the actual running balance after each transaction has been applied.

Calculation:
- Income: increases the balance.
- Expense: decreases the balance.
- Running Balance = Previous Balance + Income - Expense.

The calculation must start from the beginning of the available transaction history, not from the first transaction currently visible on the screen.

For example:

| Date | Description | Income / Expense | Current Balance |
|---|---|---:|---:|
| Nov 01 | Initial donation | +500,000 | 500,000 |
| Nov 03 | Additional donation | +200,000 | 700,000 |
| Nov 05 | Operational expense | -100,000 | 600,000 |
| Nov 08 | Additional donation | +300,000 | 900,000 |

**Important display consideration:**

Although transactions are displayed in descending date order, the cumulative balance must be calculated chronologically in ascending order first, then presented in descending order.

This ensures that every transaction displays the correct balance immediately after that transaction was applied.

### 3. Income / Expense Visual Indicators

- Income amounts must use the application's existing green color convention.
- Expense amounts must use the application's existing red color convention.
- Clearly indicate whether each transaction is income or expense.
- Use consistent currency formatting with the rest of the application (IDR / Rupiah).
- Do not rely on color alone; retain a visible positive/negative sign or transaction type indicator.

### 4. UI / UX Design

The design should follow these principles:

- Maintain the application's existing green theme.
- Keep the interface minimal, compact, and information-dense.
- Aim for the visual clarity of a database editor or spreadsheet-style data grid.
- Avoid oversized cards, excessive padding, unnecessary whitespace, and decorative elements.
- Keep column alignment consistent and numeric values right-aligned.
- Use clear column headers and subtle row separators.
- Ensure dates, descriptions, amounts, and balances are easy to scan.
- Maintain readability on smaller screens without breaking the layout.
- Reuse the application's existing typography, colors, and navigation patterns.

**Design direction:** A clean financial ledger / database table, rather than a dashboard with large summary cards.

## PART 3 — TECHNICAL REQUIREMENTS & VALIDATION

Before implementation:

1. Inspect the existing database schema and identify how Infaq and Wakaf transactions are categorized.
2. Inspect the existing transaction calculation logic to understand how income and expenses are represented.
3. Inspect the existing navigation structure and reusable table components.
4. Identify the existing logo asset.

During implementation:

- Reuse existing database models, queries, and utility functions wherever appropriate.
- Do not duplicate transaction data or introduce unnecessary database tables.
- Do not modify existing transaction records.
- Ensure the cumulative balance calculation handles historical transactions correctly.
- Avoid N+1 database queries.
- Preserve existing authentication and authorization rules.
- Ensure both new pages work correctly with empty datasets.

### Acceptance Criteria

The implementation is complete only when:

- [ ] The existing logo appears as the browser favicon.
- [ ] All relevant transaction summaries use the actual previous calendar month.
- [ ] Empty reporting months display zero values instead of falling back to older months.
- [ ] Infaq has its own dedicated transaction ledger.
- [ ] Wakaf has its own dedicated transaction ledger.
- [ ] Both ledgers display the complete available transaction history.
- [ ] Both ledgers are displayed in descending date order.
- [ ] Each transaction shows the correct cumulative balance immediately after it was applied.
- [ ] Income and expense are visually distinguishable.
- [ ] Currency formatting is consistent with the existing application.
- [ ] The UI remains compact, clean, and consistent with the existing green theme.
- [ ] Existing features and functionality remain unaffected.

After implementation, provide a brief summary of:
1. Files created or modified.
2. Changes made to existing calculation logic.
3. How the cumulative balance is calculated.
4. Any assumptions made about transaction classification or database structure.
5. Tests performed and their results.