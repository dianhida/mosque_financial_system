    -- Focused reporting views for the web dashboard.

    DROP VIEW IF EXISTS public.v_financial_summary;
    DROP VIEW IF EXISTS public.v_monthly_category_summary;
    DROP VIEW IF EXISTS public.v_monthly_fund_summary;
    DROP VIEW IF EXISTS public.v_reimbursement_summary;

    CREATE OR REPLACE VIEW public.v_infaq_summary AS
    WITH infaq AS (
        SELECT f.id AS fund_id
        FROM public.funds f
        WHERE f.code = 'INFAQ'
    ), latest AS (
        SELECT (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month')::DATE AS latest_month
    ), totals AS (
        SELECT
            COALESCE(SUM(CASE
                WHEN t.transaction_type = 'INCOME' THEN t.amount
                WHEN t.transaction_type = 'EXPENSE' THEN -t.amount
                WHEN t.transaction_date >= l.latest_month + INTERVAL '1 month' THEN 0
                ELSE 0
            END), 0) AS current_balance,
            COALESCE(SUM(CASE
                WHEN t.transaction_type = 'INCOME'
                    AND t.transaction_date >= l.latest_month
                    AND t.transaction_date < l.latest_month + INTERVAL '1 month'
                THEN t.amount ELSE 0
            END), 0) AS latest_month_income,
            COALESCE(SUM(CASE
                WHEN t.transaction_type = 'EXPENSE'
                    AND t.transaction_date >= l.latest_month
                    AND t.transaction_date < l.latest_month + INTERVAL '1 month'
                THEN t.amount ELSE 0
            END), 0) AS latest_month_expense,
            COALESCE(SUM(CASE
                WHEN t.transaction_date < l.latest_month
                AND t.transaction_type = 'INCOME' THEN t.amount
                WHEN t.transaction_date < l.latest_month
                AND t.transaction_type = 'EXPENSE' THEN -t.amount
                ELSE 0
            END), 0) AS previous_month_balance
        FROM infaq i
        CROSS JOIN latest l
        LEFT JOIN public.transactions t
            ON t.fund_id = i.fund_id
            AND t.transaction_date < l.latest_month + INTERVAL '1 month'
    )
    SELECT
        totals.current_balance,
        latest.latest_month,
        totals.previous_month_balance,
        totals.latest_month_income,
        totals.latest_month_expense
    FROM totals
    CROSS JOIN latest;

    CREATE OR REPLACE VIEW public.v_infaq_monthly_category_expense AS
    WITH latest AS (
        SELECT (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month')::DATE AS latest_month
    )
    SELECT
        l.latest_month,
        c.id AS category_id,
        c.name AS category_name,
        SUM(t.amount) AS expense_amount
    FROM public.transactions t
    JOIN public.funds f ON f.id = t.fund_id
    JOIN public.categories c ON c.id = t.category_id
    CROSS JOIN latest l
    WHERE f.code = 'INFAQ'
    AND t.transaction_type = 'EXPENSE'
    AND t.transaction_date >= l.latest_month
    AND t.transaction_date < l.latest_month + INTERVAL '1 month'
    GROUP BY l.latest_month, c.id, c.name
    ORDER BY c.name;

    CREATE OR REPLACE VIEW public.v_wakaf_activity_expense AS
    SELECT
        a.id AS activity_id,
        COALESCE(a.name, 'Uncategorized') AS activity_name,
        SUM(t.amount) AS expense_amount
    FROM public.transactions t
    JOIN public.funds f ON f.id = t.fund_id
    LEFT JOIN public.activities a ON a.id = t.activity_id
    WHERE f.code = 'WAKAF'
    AND t.transaction_type = 'EXPENSE'
    GROUP BY a.id, a.name
    ORDER BY activity_name;

    CREATE OR REPLACE VIEW public.v_unreimbursed_expense_summary AS
    SELECT
        t.id AS transaction_id,
        t.transaction_date,
        f.code AS fund_code,
        f.name AS fund_name,
        c.name AS category_name,
        t.description,
        t.amount AS expense_amount,
        COALESCE(latest_reimbursement.person_name, 'Unknown') AS person_name,
        COALESCE(latest_reimbursement.status, 'NOT_REQUESTED') AS reimbursement_status,
        t.reference_number
    FROM public.transactions t
    JOIN public.funds f ON f.id = t.fund_id
    JOIN public.categories c ON c.id = t.category_id
    LEFT JOIN LATERAL (
            SELECT
                    r.status,
                    p.name AS person_name
            FROM public.reimbursements r
            LEFT JOIN public.persons p ON p.id = r.person_id
            WHERE r.transaction_id = t.id
            ORDER BY r.created_at DESC, r.id DESC
            LIMIT 1
    ) AS latest_reimbursement ON TRUE
    WHERE t.transaction_type = 'EXPENSE'
        AND NOT EXISTS (
                SELECT 1
                FROM public.reimbursements reimbursed
                WHERE reimbursed.transaction_id = t.id
                    AND reimbursed.status = 'REIMBURSED'
        )
    ORDER BY t.transaction_date, t.id;

    COMMENT ON VIEW public.v_infaq_summary IS 'Current and latest-month INFAQ dashboard metrics.';
    COMMENT ON VIEW public.v_infaq_monthly_category_expense IS 'Latest-month INFAQ expenses grouped by category.';
    COMMENT ON VIEW public.v_wakaf_activity_expense IS 'All WAKAF expenses grouped by activity without monthly grouping.';
    COMMENT ON VIEW public.v_unreimbursed_expense_summary IS 'Expense transactions that have not been reimbursed or have no reimbursement request.';
