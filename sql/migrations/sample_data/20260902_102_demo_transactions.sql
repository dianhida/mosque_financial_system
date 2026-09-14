-- Demo transactions to validate relationships and reporting views

WITH seed AS (
    SELECT
        (SELECT id FROM public.funds WHERE code = 'INFAQ') AS infaq_id,
        (SELECT id FROM public.funds WHERE code = 'WAKAF') AS wakaf_id,
        (SELECT id FROM public.categories WHERE code = 'OPENING_BALANCE') AS opening_balance_id,
        (SELECT id FROM public.categories WHERE code = 'INFAQ') AS infaq_category_id,
        (SELECT id FROM public.categories WHERE code = 'MATERIAL') AS material_category_id,
        (SELECT id FROM public.categories WHERE code = 'LABOR') AS labor_category_id,
        (SELECT id FROM public.activities WHERE code = 'RUANG_SOUND') AS ruang_sound_id,
        (SELECT id FROM public.accounts WHERE name = 'BSI Infaq') AS infaq_bank_account_id,
        (SELECT id FROM public.accounts WHERE name = 'BSI Wakaf') AS wakaf_bank_account_id,
        (SELECT id FROM public.accounts WHERE name = 'Kas Wakaf') AS wakaf_cash_account_id,
        (SELECT id FROM public.vendors WHERE name = 'Toko Material Nusantara') AS material_vendor_id,
        (SELECT id FROM public.vendors WHERE name = 'Pak Radi') AS pak_radi_vendor_id,
        (SELECT id FROM public.persons WHERE name = 'Dian Hidayat') AS dian_person_id,
        (SELECT id FROM public.persons WHERE name = 'Pak Radi') AS pak_radi_person_id
)
INSERT INTO public.transactions (
    transaction_date,
    fund_id,
    category_id,
    activity_id,
    transaction_type,
    amount,
    description,
    vendor_id,
    person_id,
    account_id,
    reference_number,
    receipt_url,
    notes
)
SELECT
    '2026-01-01'::DATE,
    infaq_id,
    opening_balance_id,
    NULL::BIGINT,
    'INCOME',
    10946700.00,
    'Saldo 2025',
    NULL::BIGINT,
    NULL::BIGINT,
    infaq_bank_account_id,
    'SALDO-2025',
    NULL::TEXT,
    'Opening balance carried from previous period'
FROM seed
UNION ALL
SELECT
    '2026-01-10'::DATE,
    infaq_id,
    infaq_category_id,
    NULL::BIGINT,
    'INCOME',
    3500000.00,
    'Infaq jumat',
    NULL::BIGINT,
    NULL::BIGINT,
    infaq_bank_account_id,
    'INF-2026-001',
    NULL::TEXT,
    'Weekly infaq collection'
FROM seed
UNION ALL
SELECT
    '2026-07-21'::DATE,
    wakaf_id,
    material_category_id,
    ruang_sound_id,
    'EXPENSE',
    580000.00,
    'Material batu',
    material_vendor_id,
    NULL,
    wakaf_bank_account_id,
    'E072126-00',
    NULL,
    'Materials for Ruang Sound project'
FROM seed
UNION ALL
SELECT
    '2026-07-25'::DATE,
    wakaf_id,
    labor_category_id,
    ruang_sound_id,
    'EXPENSE',
    700000.00,
    'Upah tukang Pak Radi',
    pak_radi_vendor_id,
    pak_radi_person_id,
    wakaf_cash_account_id,
    'E072526-00',
    NULL,
    'Labor payment by Pak Radi, pending reimbursement'
FROM seed;

INSERT INTO public.reimbursements (transaction_id, person_id, status, requested_at, reimbursed_at, notes)
SELECT
    t.id,
    p.id,
    'PENDING',
    NOW(),
    NULL,
    'Reimbursement for labor paid by Pak Radi'
FROM public.transactions t
JOIN public.persons p ON p.name = 'Pak Radi'
WHERE t.description = 'Upah tukang Pak Radi'
ON CONFLICT DO NOTHING;

INSERT INTO public.receipts (transaction_id, storage_provider, file_path, file_name, mime_type, ocr_status, ocr_data)
SELECT
    t.id,
    'GOOGLE_DRIVE',
    'mosque/receipts/E072126-00.pdf',
    'E072126-00.pdf',
    'application/pdf',
    'PROCESSED',
    '{"vendor":"Toko Material Nusantara","amount":580000,"reference":"E072126-00"}'::jsonb
FROM public.transactions t
WHERE t.reference_number = 'E072126-00'
UNION ALL
SELECT
    t.id,
    'GOOGLE_DRIVE',
    'mosque/receipts/E072526-00.pdf',
    'E072526-00.pdf',
    'application/pdf',
    'NOT_PROCESSED',
    '{"vendor":"Pak Radi","amount":700000,"reference":"E072526-00"}'::jsonb
FROM public.transactions t  
WHERE t.reference_number = 'E072526-00';
