-- Update INFAQ and WAKAF views to filter by account name
-- Infaq: fund code INFAQ AND account name 'Main Cash'
-- Wakaf: fund code WAKAF AND account name 'Wakaf Cash'

-- Update v_infaq_summary
DROP VIEW IF EXISTS public.v_infaq_monthly_category_expense;
DROP VIEW IF EXISTS public.v_infaq_summary;

CREATE OR REPLACE VIEW public.v_infaq_summary AS
WITH infaq AS (
    SELECT f.id AS fund_id
    FROM public.funds f
    WHERE f.code = 'INFAQ'
), main_cash_account AS (
    SELECT a.id AS account_id
    FROM public.accounts a
    WHERE a.name = 'Main Cash'
), periods AS (
    SELECT
        (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month')::DATE AS reporting_month,
        DATE_TRUNC('month', CURRENT_DATE)::DATE AS current_month,
        (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '2 month')::DATE AS previous_month
), current_as_of AS (
    SELECT MAX(t.transaction_date) AS current_as_of
    FROM public.transactions t
    JOIN infaq i ON i.fund_id = t.fund_id
    JOIN main_cash_account m ON m.account_id = t.account_id
    CROSS JOIN periods p
    WHERE t.transaction_date >= p.reporting_month
      AND t.transaction_date < p.current_month
), previous_as_of AS (
    SELECT MAX(t.transaction_date) AS previous_month_as_of
    FROM public.transactions t
    JOIN infaq i ON i.fund_id = t.fund_id
    JOIN main_cash_account m ON m.account_id = t.account_id
    CROSS JOIN periods p
    WHERE t.transaction_date >= p.previous_month
      AND t.transaction_date < p.reporting_month
), metrics AS (
    SELECT
        COALESCE(SUM(CASE
            WHEN t.transaction_type = 'INCOME' THEN t.amount
            WHEN t.transaction_type = 'EXPENSE' THEN -t.amount
            ELSE 0
        END), 0)::NUMERIC(15,2) AS current_balance,
        COALESCE(SUM(CASE
            WHEN t.transaction_date >= p.reporting_month
                AND t.transaction_date < p.current_month
                AND t.transaction_type = 'INCOME' THEN t.amount
            ELSE 0
        END), 0)::NUMERIC(15,2) AS reporting_month_income,
        COALESCE(SUM(CASE
            WHEN t.transaction_date >= p.reporting_month
                AND t.transaction_date < p.current_month
                AND t.transaction_type = 'EXPENSE' THEN t.amount
            ELSE 0
        END), 0)::NUMERIC(15,2) AS reporting_month_expense,
        COALESCE(SUM(CASE
            WHEN t.transaction_date < p.reporting_month
                AND t.transaction_type = 'INCOME' THEN t.amount
            WHEN t.transaction_date < p.reporting_month
                AND t.transaction_type = 'EXPENSE' THEN -t.amount
            ELSE 0
        END), 0)::NUMERIC(15,2) AS previous_month_closing_balance,
        COALESCE(SUM(CASE
            WHEN t.transaction_date >= p.previous_month
                AND t.transaction_date < p.reporting_month
                AND t.transaction_type = 'INCOME' THEN t.amount
            ELSE 0
        END), 0)::NUMERIC(15,2) AS previous_month_income,
        COALESCE(SUM(CASE
            WHEN t.transaction_date >= p.previous_month
                AND t.transaction_date < p.reporting_month
                AND t.transaction_type = 'EXPENSE' THEN t.amount
            ELSE 0
        END), 0)::NUMERIC(15,2) AS previous_month_expense
    FROM infaq i
    CROSS JOIN periods p
    LEFT JOIN public.transactions t ON t.fund_id = i.fund_id
    LEFT JOIN main_cash_account m ON m.account_id = t.account_id
    GROUP BY p.reporting_month, p.current_month, p.previous_month
)
SELECT
    metrics.current_balance,
    periods.reporting_month AS current_month,
    metrics.reporting_month_income AS current_month_income,
    metrics.reporting_month_expense AS current_month_expense,
    current_as_of.current_as_of,
    periods.previous_month,
    metrics.previous_month_closing_balance,
    metrics.previous_month_income,
    metrics.previous_month_expense,
    previous_as_of.previous_month_as_of
FROM metrics
CROSS JOIN periods
CROSS JOIN current_as_of
CROSS JOIN previous_as_of;

CREATE OR REPLACE VIEW public.v_infaq_monthly_category_expense AS
WITH infaq AS (
    SELECT f.id AS fund_id
    FROM public.funds f
    WHERE f.code = 'INFAQ'
), main_cash_account AS (
    SELECT a.id AS account_id
    FROM public.accounts a
    WHERE a.name = 'Main Cash'
), periods AS (
    SELECT
        (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month')::DATE AS reporting_month,
        DATE_TRUNC('month', CURRENT_DATE)::DATE AS current_month
)
SELECT
    p.reporting_month AS latest_month,
    c.id AS category_id,
    c.name AS category_name,
    t.transaction_type,
    SUM(t.amount)::NUMERIC(15,2) AS amount
FROM public.transactions t
JOIN infaq i ON i.fund_id = t.fund_id
JOIN main_cash_account m ON m.account_id = t.account_id
JOIN public.categories c ON c.id = t.category_id
CROSS JOIN periods p
WHERE t.transaction_date >= p.reporting_month
  AND t.transaction_date < p.current_month
GROUP BY p.reporting_month, c.id, c.name, t.transaction_type
ORDER BY c.name;

COMMENT ON VIEW public.v_infaq_summary IS
    'INFAQ current and previous calendar month metrics for Main Cash account using system date.';

COMMENT ON VIEW public.v_infaq_monthly_category_expense IS
    'INFAQ previous-month income and expense cashflow grouped by category for Main Cash account using system date.';

GRANT SELECT ON public.v_infaq_summary TO authenticated;
GRANT SELECT ON public.v_infaq_monthly_category_expense TO authenticated;
NOTIFY pgrst, 'reload schema';

-- Update v_wakaf_summary
DROP VIEW IF EXISTS public.v_wakaf_summary;

CREATE OR REPLACE VIEW public.v_wakaf_summary AS
WITH wakaf AS (
    SELECT f.id AS fund_id
    FROM public.funds f
    WHERE f.code = 'WAKAF'
), wakaf_cash_account AS (
    SELECT a.id AS account_id
    FROM public.accounts a
    WHERE a.name = 'Wakaf Cash'
), target AS (
    SELECT NULLIF(TRIM(fs.setting_value), '')::NUMERIC(15,2) AS target_amount
    FROM public.fund_settings fs
    JOIN wakaf w ON w.fund_id = fs.fund_id
    WHERE fs.setting_key = 'target_amount'
), latest_snapshot AS (
    SELECT snapshot.balance
    FROM public.fund_balance_snapshots snapshot
    JOIN wakaf w ON w.fund_id = snapshot.fund_id
    ORDER BY snapshot.checked_at DESC, snapshot.id DESC
    LIMIT 1
), expenses AS (
    SELECT COALESCE(SUM(t.amount), 0)::NUMERIC(15,2) AS total_expense
    FROM public.transactions t
    JOIN wakaf w ON w.fund_id = t.fund_id
    WHERE t.transaction_type = 'EXPENSE'
), cash_balance AS (
    SELECT COALESCE(SUM(CASE
        WHEN t.transaction_type = 'INCOME' THEN t.amount
        WHEN t.transaction_type = 'EXPENSE' THEN -t.amount
        ELSE 0
    END), 0)::NUMERIC(15,2) AS current_cash_balance
    FROM public.transactions t
    JOIN public.funds f ON f.id = t.fund_id
    JOIN public.accounts a ON a.id = t.account_id
    WHERE f.code = 'WAKAF'
      AND a.name = 'Wakaf Cash'
)
SELECT
    target.target_amount,
    latest_snapshot.balance AS current_balance,
    cash_balance.current_cash_balance,
    expenses.total_expense,
    CASE
        WHEN latest_snapshot.balance IS NULL THEN NULL
        ELSE (latest_snapshot.balance + expenses.total_expense)::NUMERIC(15,2)
    END AS estimated_total_collected,
    CASE
        WHEN target.target_amount IS NULL
            OR target.target_amount <= 0
            OR latest_snapshot.balance IS NULL
        THEN NULL
        ELSE ROUND(((latest_snapshot.balance + expenses.total_expense) / target.target_amount) * 100, 2)
    END AS progress_percentage
FROM wakaf
LEFT JOIN target ON TRUE
LEFT JOIN latest_snapshot ON TRUE
CROSS JOIN expenses
CROSS JOIN cash_balance;

COMMENT ON VIEW public.v_wakaf_summary IS
    'WAKAF target, cash balance (Wakaf Cash account), bank balance, and progress based on the latest manual balance snapshot plus recorded expenses.';

GRANT SELECT ON public.v_wakaf_summary TO authenticated;
NOTIFY pgrst, 'reload schema';

-- Update v_wakaf_activity_expense to filter by Wakaf Cash account
DROP VIEW IF EXISTS public.v_wakaf_activity_expense;

CREATE OR REPLACE VIEW public.v_wakaf_activity_expense AS
WITH wakaf AS (
    SELECT f.id AS fund_id
    FROM public.funds f
    WHERE f.code = 'WAKAF'
), wakaf_cash_account AS (
    SELECT a.id AS account_id
    FROM public.accounts a
    WHERE a.name = 'Wakaf Cash'
)
SELECT
    a.id AS activity_id,
    COALESCE(a.name, 'Uncategorized') AS activity_name,
    SUM(t.amount) AS expense_amount
FROM public.transactions t
JOIN public.funds f ON f.id = t.fund_id
JOIN wakaf_cash_account wca ON wca.account_id = t.account_id
LEFT JOIN public.activities a ON a.id = t.activity_id
WHERE f.code = 'WAKAF'
  AND t.transaction_type = 'EXPENSE'
GROUP BY a.id, a.name
ORDER BY activity_name;

COMMENT ON VIEW public.v_wakaf_activity_expense IS
    'WAKAF expenses grouped by activity for Wakaf Cash account.';

GRANT SELECT ON public.v_wakaf_activity_expense TO authenticated;
NOTIFY pgrst, 'reload schema';