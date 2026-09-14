-- Master data required by the spreadsheet mappings.
-- Funds and existing category codes are safe to re-run.

INSERT INTO public.funds (code, name, description, active)
VALUES
    ('INFAQ', 'Infaq', 'General infaq fund', TRUE),
    ('WAKAF', 'Wakaf', 'Dedicated wakaf fund', TRUE)
ON CONFLICT (code) DO NOTHING;

INSERT INTO public.categories (code, name, description, active)
VALUES
    ('OPENING_BALANCE', 'Opening Balance', 'Opening balance carried from a previous period', TRUE),
    ('INFAQ', 'Infaq', 'Infaq income', TRUE),
    ('DONATION', 'Donation', 'General donation income', TRUE),
    ('OPERATIONAL', 'Operational', 'Utilities and mosque operations', TRUE),
    ('KAJIAN', 'Kajian', 'Study and religious event expense', TRUE),
    ('EQUIPMENT', 'Equipment', 'Equipment and durable goods', TRUE),
    ('SOCIAL', 'Social', 'Community and social assistance', TRUE),
    ('TPA', 'TPA', 'TPA and children education', TRUE),
    ('QURBAN', 'Qurban', 'Qurban-related movement', TRUE),
    ('BANK_ADMINISTRATION', 'Bank Administration', 'Bank, transfer, and payment fees', TRUE),
    ('MATERIAL', 'Material', 'Building and project materials', TRUE),
    ('LABOR', 'Labor', 'Worker and service payments', TRUE),
    ('OTHER_INCOME', 'Other Income', 'Other income', TRUE),
    ('OTHER_EXPENSE', 'Other Expense', 'Other expense', TRUE)
ON CONFLICT (code) DO NOTHING;

INSERT INTO public.activities (fund_id, code, name, description, active)
SELECT f.id, activity.code, activity.name, activity.description, TRUE
FROM public.funds f
JOIN (
    VALUES
        ('INFAQ', 'INFAQ_OPERATIONS', 'Operasional', 'Operational activity imported from Infaq.csv'),
        ('INFAQ', 'INFAQ_KAJIAN', 'Kajian', 'Kajian activity imported from Infaq.csv'),
        ('INFAQ', 'INFAQ_TPA', 'TPA', 'TPA activity imported from Infaq.csv'),
        ('INFAQ', 'INFAQ_DONOR_DARAH', 'Donor Darah', 'Donor Darah activity imported from Infaq.csv'),
        ('WAKAF', 'RUANG_SOUND', 'Ruang Sound', 'Ruang Sound project imported from Wakaf.csv'),
        ('WAKAF', 'SERTIFIKAT', 'Sertifikat', 'Certificate activity imported from Wakaf.csv')
) AS activity(fund_code, code, name, description) ON activity.fund_code = f.code
WHERE NOT EXISTS (
    SELECT 1
    FROM public.activities existing
    WHERE existing.code = activity.code
);
