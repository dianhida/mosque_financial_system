-- Dedicated views for Transaction Ledgers
-- Infaq: fund code INFAQ AND account name 'Main Cash'
-- Wakaf: fund code WAKAF AND account name 'Wakaf Cash'

-- Infaq Transaction Ledger View
DROP VIEW IF EXISTS public.v_infaq_transaction_ledger;

CREATE OR REPLACE VIEW public.v_infaq_transaction_ledger AS
WITH infaq AS (
    SELECT f.id AS fund_id
    FROM public.funds f
    WHERE f.code = 'INFAQ'
), main_cash_account AS (
    SELECT a.id AS account_id
    FROM public.accounts a
    WHERE a.name = 'Main Cash'
)
SELECT
    t.id,
    t.transaction_date,
    t.description,
    t.transaction_type,
    t.amount,
    t.fund_id,
    t.category_id,
    t.activity_id,
    t.vendor_id,
    t.person_id,
    t.account_id,
    t.reference_number,
    t.notes,
    t.created_at,
    f.name AS fund_name,
    c.name AS category_name,
    a.name AS activity_name,
    v.name AS vendor_name,
    p.name AS person_name,
    ac.name AS account_name
FROM public.transactions t
JOIN infaq i ON i.fund_id = t.fund_id
JOIN main_cash_account mca ON mca.account_id = t.account_id
JOIN public.funds f ON f.id = t.fund_id
LEFT JOIN public.categories c ON c.id = t.category_id
LEFT JOIN public.activities a ON a.id = t.activity_id
LEFT JOIN public.vendors v ON v.id = t.vendor_id
LEFT JOIN public.persons p ON p.id = t.person_id
LEFT JOIN public.accounts ac ON ac.id = t.account_id
ORDER BY t.transaction_date DESC, t.created_at DESC;

COMMENT ON VIEW public.v_infaq_transaction_ledger IS
    'Complete INFAQ transaction ledger for Main Cash account, ordered newest first.';

GRANT SELECT ON public.v_infaq_transaction_ledger TO authenticated;
NOTIFY pgrst, 'reload schema';

-- Wakaf Transaction Ledger View
DROP VIEW IF EXISTS public.v_wakaf_transaction_ledger;

CREATE OR REPLACE VIEW public.v_wakaf_transaction_ledger AS
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
    t.id,
    t.transaction_date,
    t.description,
    t.transaction_type,
    t.amount,
    t.fund_id,
    t.category_id,
    t.activity_id,
    t.vendor_id,
    t.person_id,
    t.account_id,
    t.reference_number,
    t.notes,
    t.created_at,
    f.name AS fund_name,
    c.name AS category_name,
    a.name AS activity_name,
    v.name AS vendor_name,
    p.name AS person_name,
    ac.name AS account_name
FROM public.transactions t
JOIN wakaf w ON w.fund_id = t.fund_id
JOIN wakaf_cash_account wca ON wca.account_id = t.account_id
JOIN public.funds f ON f.id = t.fund_id
LEFT JOIN public.categories c ON c.id = t.category_id
LEFT JOIN public.activities a ON a.id = t.activity_id
LEFT JOIN public.vendors v ON v.id = t.vendor_id
LEFT JOIN public.persons p ON p.id = t.person_id
LEFT JOIN public.accounts ac ON ac.id = t.account_id
ORDER BY t.transaction_date DESC, t.created_at DESC;

COMMENT ON VIEW public.v_wakaf_transaction_ledger IS
    'Complete WAKAF transaction ledger for Wakaf Cash account, ordered newest first.';

GRANT SELECT ON public.v_wakaf_transaction_ledger TO authenticated;
NOTIFY pgrst, 'reload schema';