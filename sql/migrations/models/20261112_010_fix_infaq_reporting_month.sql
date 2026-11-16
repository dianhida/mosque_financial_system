-- Fix INFAQ reporting to use current system date (previous calendar month) instead of latest transaction date.

DROP VIEW IF EXISTS public.v_infaq_monthly_category_expense;
DROP VIEW IF EXISTS public.v_infaq_summary;

CREATE OR REPLACE VIEW public.v_infaq_summary AS
WITH infaq AS (
    SELECT f.id AS fund_id
    FROM public.funds f
    WHERE f.code = 'INFAQ'
), periods AS (
    SELECT
        (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month')::DATE AS reporting_month,
        DATE_TRUNC('month', CURRENT_DATE)::DATE AS current_month,
        (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '2 month')::DATE AS previous_month
), current_as_of AS (
    SELECT MAX(t.transaction_date) AS current_as_of
    FROM public.transactions t
    JOIN infaq i ON i.fund_id = t.fund_id
    CROSS JOIN periods p
    WHERE t.transaction_date >= p.reporting_month
      AND t.transaction_date < p.current_month
), previous_as_of AS (
    SELECT MAX(t.transaction_date) AS previous_month_as_of
    FROM public.transactions t
    JOIN infaq i ON i.fund_id = t.fund_id
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
JOIN public.categories c ON c.id = t.category_id
CROSS JOIN periods p
WHERE t.transaction_date >= p.reporting_month
  AND t.transaction_date < p.current_month
GROUP BY p.reporting_month, c.id, c.name, t.transaction_type
ORDER BY c.name;

COMMENT ON VIEW public.v_infaq_summary IS
    'INFAQ current and previous calendar month metrics derived from the transaction ledger using system date.';

COMMENT ON VIEW public.v_infaq_monthly_category_expense IS
    'INFAQ previous-month income and expense cashflow grouped by category using system date.';

GRANT SELECT ON public.v_infaq_summary TO authenticated;
GRANT SELECT ON public.v_infaq_monthly_category_expense TO authenticated;
NOTIFY pgrst, 'reload schema';