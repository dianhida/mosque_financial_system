-- Repair migration for databases where 20260906_006 failed before exposing v_wakaf_summary.
-- Run after 20260906_006_fund_configuration.sql.

DO $$
BEGIN
    IF to_regclass('public.fund_settings') IS NULL
        OR to_regclass('public.fund_balance_snapshots') IS NULL THEN
        RAISE EXCEPTION
            'Run 20260906_006_fund_configuration.sql before this repair migration';
    END IF;
END
$$;

DROP VIEW IF EXISTS public.v_wakaf_summary;

CREATE VIEW public.v_wakaf_summary AS
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
)
SELECT
    target.target_amount,
    latest_snapshot.balance AS current_balance,
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
CROSS JOIN expenses;

COMMENT ON VIEW public.v_wakaf_summary IS
    'WAKAF target and progress based on the latest manual balance snapshot plus recorded expenses.';

GRANT SELECT ON public.v_wakaf_summary TO authenticated;
NOTIFY pgrst, 'reload schema';
