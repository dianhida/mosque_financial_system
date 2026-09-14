-- INFAQ monthly reporting correction.
-- The current/latest month is derived from the latest INFAQ transaction date.
-- WAKAF reporting is intentionally unchanged.

DROP VIEW IF EXISTS public.v_infaq_monthly_category_expense;
DROP VIEW IF EXISTS public.v_infaq_summary;

CREATE VIEW public.v_infaq_summary AS
WITH infaq AS (
    SELECT f.id AS fund_id
    FROM public.funds f
    WHERE f.code = 'INFAQ'
), latest AS (
    SELECT
        DATE_TRUNC('month', MAX(t.transaction_date))::DATE AS current_month,
        MAX(t.transaction_date) AS current_as_of
    FROM public.transactions t
    JOIN infaq i ON i.fund_id = t.fund_id
), periods AS (
    SELECT
        current_month,
        current_as_of,
        (current_month - INTERVAL '1 month')::DATE AS previous_month
    FROM latest
), metrics AS (
    SELECT
        COALESCE(SUM(CASE
            WHEN t.transaction_type = 'INCOME' THEN t.amount
            WHEN t.transaction_type = 'EXPENSE' THEN -t.amount
            ELSE 0
        END), 0)::NUMERIC(15,2) AS current_balance,
        COALESCE(SUM(CASE
            WHEN t.transaction_date >= p.current_month
                AND t.transaction_date < p.current_month + INTERVAL '1 month'
                AND t.transaction_type = 'INCOME' THEN t.amount
            ELSE 0
        END), 0)::NUMERIC(15,2) AS current_month_income,
        COALESCE(SUM(CASE
            WHEN t.transaction_date >= p.current_month
                AND t.transaction_date < p.current_month + INTERVAL '1 month'
                AND t.transaction_type = 'EXPENSE' THEN t.amount
            ELSE 0
        END), 0)::NUMERIC(15,2) AS current_month_expense,
        COALESCE(SUM(CASE
            WHEN t.transaction_date < p.current_month
                AND t.transaction_type = 'INCOME' THEN t.amount
            WHEN t.transaction_date < p.current_month
                AND t.transaction_type = 'EXPENSE' THEN -t.amount
            ELSE 0
        END), 0)::NUMERIC(15,2) AS previous_month_closing_balance,
        COALESCE(SUM(CASE
            WHEN t.transaction_date >= p.previous_month
                AND t.transaction_date < p.current_month
                AND t.transaction_type = 'INCOME' THEN t.amount
            ELSE 0
        END), 0)::NUMERIC(15,2) AS previous_month_income,
        COALESCE(SUM(CASE
            WHEN t.transaction_date >= p.previous_month
                AND t.transaction_date < p.current_month
                AND t.transaction_type = 'EXPENSE' THEN t.amount
            ELSE 0
        END), 0)::NUMERIC(15,2) AS previous_month_expense
    FROM infaq i
    CROSS JOIN periods p
    LEFT JOIN public.transactions t ON t.fund_id = i.fund_id
    GROUP BY p.current_month, p.current_as_of, p.previous_month
), previous_as_of AS (
    SELECT MAX(t.transaction_date) AS previous_month_as_of
    FROM public.transactions t
    JOIN infaq i ON i.fund_id = t.fund_id
    CROSS JOIN periods p
    WHERE t.transaction_date >= p.previous_month
      AND t.transaction_date < p.current_month
)
SELECT
    metrics.current_balance,
    periods.current_month,
    metrics.current_month_income,
    metrics.current_month_expense,
    periods.current_as_of,
    periods.previous_month,
    metrics.previous_month_closing_balance,
    metrics.previous_month_income,
    metrics.previous_month_expense,
    previous_as_of.previous_month_as_of
FROM metrics
CROSS JOIN periods
CROSS JOIN previous_as_of;

CREATE VIEW public.v_infaq_monthly_category_expense AS
WITH infaq AS (
    SELECT f.id AS fund_id
    FROM public.funds f
    WHERE f.code = 'INFAQ'
), periods AS (
    SELECT (DATE_TRUNC('month', MAX(t.transaction_date)) - INTERVAL '1 month')::DATE AS previous_month,
           DATE_TRUNC('month', MAX(t.transaction_date))::DATE AS current_month
    FROM public.transactions t
    JOIN infaq i ON i.fund_id = t.fund_id
)
SELECT
    p.previous_month AS latest_month,
    c.id AS category_id,
    c.name AS category_name,
    t.transaction_type,
    SUM(t.amount)::NUMERIC(15,2) AS amount
FROM public.transactions t
JOIN infaq i ON i.fund_id = t.fund_id
JOIN public.categories c ON c.id = t.category_id
CROSS JOIN periods p
WHERE t.transaction_date >= p.previous_month
  AND t.transaction_date < p.current_month
GROUP BY p.previous_month, c.id, c.name, t.transaction_type;

COMMENT ON VIEW public.v_infaq_summary IS
    'INFAQ current and previous calendar month metrics derived from the transaction ledger.';
COMMENT ON VIEW public.v_infaq_monthly_category_expense IS
    'INFAQ previous-month income and expense cashflow grouped by category.';

GRANT SELECT ON public.v_infaq_summary TO authenticated;
GRANT SELECT ON public.v_infaq_monthly_category_expense TO authenticated;
NOTIFY pgrst, 'reload schema';
