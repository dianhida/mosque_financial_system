-- Add current_cash_balance to v_wakaf_summary.
-- Current Cash Balance is the net ledger balance (income minus expense)
-- for the WAKAF fund restricted to the WAKAF CASH account.
-- Run after 20260908_007_repair_wakaf_summary_view.sql.

DROP VIEW IF EXISTS public.v_wakaf_summary;

CREATE OR REPLACE VIEW public.v_wakaf_summary AS
WITH wakaf AS (
    SELECT f.id AS fund_id
    FROM public.funds f
    WHERE f.code = 'WAKAF'
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
    WHERE UPPER(f.name) = 'WAKAF'
      AND UPPER(a.name) = 'WAKAF CASH'
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
    'WAKAF target, cash balance, bank balance, and progress based on the latest manual balance snapshot plus recorded expenses.';

GRANT SELECT ON public.v_wakaf_summary TO authenticated;
NOTIFY pgrst, 'reload schema';
