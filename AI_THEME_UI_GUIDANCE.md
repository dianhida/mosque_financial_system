# UI / Design System — Mosque Finance

The application must follow a consistent visual identity based on the mosque's existing visual theme.

Do NOT use a generic SaaS dashboard aesthetic.

Do NOT make the interface look like a default Tailwind, Bootstrap, Material UI, or generic shadcn dashboard.

The visual direction should feel:

* modern
* elegant
* calm
* trustworthy
* warm
* Islamic/mosque-oriented without excessive decorative Islamic elements
* professional enough for financial administration
* clean and editorial
* desktop-first
* spacious
* easy to scan

The application should feel like a modern financial/reporting application rather than an old accounting system.

---

# 1. Core Color Palette

Use the following colors as the primary design tokens.

### Main Background

```text
#E6F9E8
```

Use this as the primary application/page background.

It should create a soft, light green atmosphere without looking saturated.

### Surface / Content Background

```text
#F4FFF5
```

Use this for:

* dashboard content areas
* panels
* table surfaces
* forms
* dropdowns
* important information areas
* cards when a card is actually appropriate

Do not make every UI element a separate rectangular card.

The relationship should generally feel like:

```text
#E6F9E8
   └── #F4FFF5 content surfaces
```

### General / Primary Text / Income

```text
#297757
```

Use this as the primary accent and financial-positive color.

Suitable for:

* primary text accents
* income
* positive financial indicators
* selected navigation states
* primary buttons
* important labels
* active states
* links

### Expense

```text
#C04440
```

Use this specifically for:

* expense amounts
* expense indicators
* negative financial changes
* expense chart elements
* expense labels where appropriate

Do not use expense red as a dominant UI color.

It should remain a semantic financial color.

---

# 2. Typography

Use:

### Body / UI

Prefer:

```text
Montserrat
```

for:

* body text
* table text
* navigation
* buttons
* form labels
* numbers where appropriate
* metadata

Alternative:

```text
Merriweather
```

may be used selectively where it improves the editorial feel, but do not mix fonts excessively.

### Titles / Headings

Use:

```text
Playfair Display
```

for:

* dashboard titles
* page titles
* major section headings
* important hero/KPI headings where appropriate

The title typography should provide an elegant editorial identity.

Example:

```text
Playfair Display
INFAQ Dashboard
```

with:

```text
Montserrat
Your financial overview for August 2026
```

Do not use Playfair Display for dense table content.

---

# 3. Overall Visual Direction

The most important design principle:

> **Modern tables and information layouts, not old-fashioned boxed accounting software.**

Avoid interfaces where everything looks like:

```text
┌──────────────┐
│   CARD       │
│              │
└──────────────┘

┌──────────────┐
│   CARD       │
│              │
└──────────────┘
```

Instead, use:

* whitespace
* subtle background separation
* typography hierarchy
* thin/subtle dividers
* restrained borders
* generous spacing
* soft radius
* horizontal information grouping
* clear alignment
* subtle hover states

Use cards only where they communicate a meaningful grouping.

---

# 4. Dashboard Layout

Dashboards should feel spacious and editorial.

Preferred hierarchy:

```text
INFAQ
Financial overview

┌───────────────────────────────────────────────────────────────┐
│ Current Balance          Latest Month        Income           │
│ Rp 11.810.311            August 2026         Rp 3.5M          │
│                                                               │
│ Previous Balance         Expense                               │
│ Rp 10.XXX.XXX            Rp 2.1M                              │
└───────────────────────────────────────────────────────────────┘

Expense by Category

Operational                         Rp 888.000
Kajian                              Rp 2.375.000
Equipment                           Rp 1.096.000
Social                              Rp 92.000
```

However, do not necessarily render the entire area as one large bordered box.

The layout should use visual grouping through:

* spacing
* subtle surfaces
* typography
* dividers

rather than excessive borders.

---

# 5. KPI / Financial Numbers

Financial numbers are important and should be visually prominent.

Use:

### Income

```text
#297757
```

### Expense

```text
#C04440
```

### Balance

Use the primary green palette.

Do not use bright neon green.

Currency formatting:

```text
Rp 11.810.311
```

Numbers should have strong typographic hierarchy.

The label should be smaller and quieter than the number.

Example:

```text
Current Balance

Rp 11.810.311
```

Avoid excessive icons inside every KPI.

---

# 6. Tables

Tables are a major part of this application.

They must look modern.

Avoid:

* heavy grid borders
* borders around every individual cell
* dark header backgrounds
* excessive vertical lines
* old-school spreadsheet appearance
* tiny text
* cramped rows

Preferred approach:

```text
Transactions

Date        Description          Fund       Category      Amount
────────────────────────────────────────────────────────────────
03 Sep      Listrik              Infaq      Operational   Rp 38.000
02 Sep      Material batu        Wakaf      Material      Rp 580.000
01 Sep      Infaq Jumat          Infaq      Infaq         Rp 1.010.300
```

Use:

* subtle horizontal dividers
* whitespace
* aligned numeric columns
* right-aligned currency
* semantic colors for income/expense
* subtle row hover
* rounded container only around the overall table when useful

The table should feel closer to a modern financial product than an Excel spreadsheet.

---

# 7. Transaction Table

Transaction type should be immediately understandable.

Example:

```text
INCOME
Rp 1.010.300
```

using:

```text
#297757
```

and:

```text
EXPENSE
Rp 580.000
```

using:

```text
#C04440
```

Use subtle badges/pills for transaction type if appropriate, but avoid oversized badges.

The amount column should be visually dominant within each row.

---

# 8. Navigation

The navigation should use the same visual identity.

Avoid generic dark sidebar dashboards.

Prefer a light, elegant navigation area that works naturally with:

```text
#E6F9E8
#F4FFF5
#297757
```

Example conceptual navigation:

```text
MOSQUE FINANCE

Dashboard

Transactions

Master Data
  Funds
  Categories
  Activities
  Vendors
  Persons
  Accounts
```

Active navigation should use the green accent subtly.

Do not turn the entire sidebar into a large green block unless it genuinely improves the design.

---

# 9. Header

The header should contain the mosque/application identity.

Use the existing logo:

```text
/LOGO.png
```

located in the project root.

**Do not create or generate a replacement logo.**

Use `LOGO.png` consistently in:

* application header
* login/authentication page if applicable
* dashboard identity
* favicon/app identity if appropriate and technically suitable

Inspect the logo's proportions before implementing it.

Do not distort the logo.

Preserve its aspect ratio.

The logo should feel like part of the application identity rather than a random image placed in the header.

---

# 10. Page Titles

Use Playfair Display for major page titles.

Example:

```text
INFAQ
Financial Overview
```

or:

```text
Transactions
```

Subtitle/description can use Montserrat.

Maintain a strong typography hierarchy:

```text
Page Title
Subtitle / contextual information

Section Title

Supporting information
```

Do not make every heading huge.

---

# 11. Master Data Pages

Master-data pages should follow the same modern table language.

Example:

```text
Categories

Manage financial categories

                           + Add Category

Category              Code            Status
──────────────────────────────────────────────
Operational            OPERATIONAL     Active
Kajian                 KAJIAN          Active
Equipment              EQUIPMENT       Active
```

Use clean inline actions.

Avoid putting every row inside a separate card.

Add/Edit should preferably use a modern modal/drawer rather than navigating to a visually disconnected legacy-style form.

---

# 12. Transaction Form

The transaction form should be clean and structured.

Group fields logically:

### Basic Information

```text
Transaction Date
Fund
Transaction Type
Amount
```

### Classification

```text
Category
Activity
```

### Payment / Party

```text
Account
Vendor
Person
```

### Additional Information

```text
Description
Reference Number
Receipt
Notes
```

### Reimbursement

Show reimbursement fields conditionally when reimbursement is required.

Use clear section headings and whitespace.

Do not put all fields into one dense grid.

---

# 13. Forms

Forms should use:

* generous spacing
* clear labels
* readable input heights
* subtle borders
* soft focus states
* accessible contrast
* clear validation messages

Avoid tiny input controls.

Dropdowns should look polished and consistent.

Foreign-key fields should show names rather than IDs.

For example:

```text
Fund
[ Wakaf                  ▼ ]
```

not:

```text
Fund ID
[ 2                      ]
```

---

# 14. Buttons

Primary action:

Use the green visual identity based on:

```text
#297757
```

Examples:

```text
+ Add Transaction
+ Add Vendor
Save
```

Secondary actions should be quieter.

Danger/delete actions should use an appropriately restrained red rather than the primary expense red everywhere.

Do not make every button colorful.

Use hierarchy:

```text
Primary
Secondary
Ghost
Danger
```

---

# 15. WAKAF Dashboard Visual Identity

The WAKAF dashboard should strongly use the provided green theme.

Main background:

```text
#E6F9E8
```

Surfaces:

```text
#F4FFF5
```

Primary:

```text
#297757
```

Expense:

```text
#C04440
```

The dashboard should communicate:

> funds collected → funds used → current balance → active programs

A suggested hierarchy:

```text
WAKAF

Dana wakaf yang terkumpul dan penggunaannya

Total Collected        Total Used        Current Balance
Rp xx.xxx.xxx          Rp xx.xxx.xxx     Rp xx.xxx.xxx

────────────────────────────────────────────────────────

Program Aktif

Ruang Sound
Rp x.xxx.xxx digunakan

Program lainnya
Rp x.xxx.xxx digunakan
```

The active-program section should feel more like a **program/project overview** than a financial spreadsheet.

---

# 16. INFAQ Dashboard Visual Identity

Use the same overall design system but optimize the information hierarchy around monthly financial activity.

Suggested hierarchy:

```text
INFAQ

Monthly financial overview

Current Balance        Latest Month        Previous Balance

Income                 Expense

────────────────────────────────────────────────────────

Expense by Category

Category                         Amount
Operational                      Rp xxx
Kajian                           Rp xxx
Equipment                        Rp xxx
...
```

The INFAQ dashboard should communicate:

> "How is the mosque's operational/infaq money doing this month?"

---

# 17. Charts

Charts should follow the same color system.

Do not introduce random dashboard colors.

Use:

```text
Primary / positive → #297757
Expense → #C04440
Background → #E6F9E8 / #F4FFF5
```

Keep charts minimal.

Avoid:

* rainbow charts
* excessive gradients
* 3D charts
* unnecessary decoration

For category expense, a horizontal bar chart is preferred because category names can be long.

Always provide exact values in a table or accessible text alongside the chart.

---

# 18. Borders, Shadows and Radius

Use restrained styling.

Prefer:

* subtle borders
* subtle shadows only where necessary
* medium/small border radius
* generous whitespace

Avoid:

* heavy shadows
* huge rounded cards everywhere
* excessive glassmorphism
* excessive gradients
* thick borders
* overly decorative UI

The interface should feel premium through **spacing, typography, and hierarchy**, not through visual effects.

---

# 19. Responsive Behavior

The primary target is:

```text
Desktop / Laptop
```

but the application should remain usable on:

```text
Tablet
Mobile
```

Do not compromise the desktop table/dashboard experience just to make everything mobile-first.

On smaller screens:

* tables may become horizontally scrollable
* dashboard KPI sections may stack
* navigation may collapse
* forms may become single-column

---

# 20. Consistency Rules

Every page must use the same design system.

Do not create separate visual styles for:

* transactions
* master data
* dashboards
* forms
* settings

They should look like parts of one application.

Create reusable design tokens/components where practical.

For example:

```text
colors
typography
spacing
radius
buttons
inputs
tables
badges
KPI
section headers
dialogs
```

Avoid hardcoding different visual styles in individual pages.

---

# 21. Design Philosophy

The final result should feel like:

> **A modern, elegant mosque financial management application with an editorial visual identity.**

Not:

> "A generic admin dashboard template."

Prioritize:

1. readability
2. financial clarity
3. hierarchy
4. whitespace
5. typography
6. consistency
7. subtle visual identity

The green theme should be visible throughout the entire application, not only on the WAKAF dashboard.

The application should look coherent from:

```text
Login
  ↓
Dashboard
  ↓
Transactions
  ↓
Transaction Form
  ↓
Master Data
  ↓
Reports
```

Use the mosque's `LOGO.png` as the primary identity asset throughout the application.
