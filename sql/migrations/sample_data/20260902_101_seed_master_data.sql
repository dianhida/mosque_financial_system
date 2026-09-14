-- Seed master data for initial mosque financial setup

INSERT INTO public.funds (code, name, description, active)
VALUES
    ('INFAQ', 'Infaq', 'General infaq fund', TRUE),
    ('WAKAF', 'Wakaf', 'Dedicated wakaf fund', TRUE)
ON CONFLICT (code) DO NOTHING;

INSERT INTO public.categories (code, name, description, active)
VALUES
    ('OPENING_BALANCE', 'Opening Balance', 'Opening balance carried from previous period', TRUE),
    ('INFAQ', 'Infaq', 'Infaq income category', TRUE),
    ('DONATION', 'Donation', 'General donation', TRUE),
    ('OPERATIONAL', 'Operational', 'Operational expense', TRUE),
    ('KAJIAN', 'Kajian', 'Kajian or religious event expense', TRUE),
    ('EQUIPMENT', 'Equipment', 'Equipment purchase', TRUE),
    ('SOCIAL', 'Social', 'Social assistance and community support', TRUE),
    ('TPA', 'TPA', 'Early education or TPA activity cost', TRUE),
    ('QURBAN', 'Qurban', 'Qurban-related income or expense', TRUE),
    ('BANK_ADMINISTRATION', 'Bank Administration', 'Bank or administration charges', TRUE),
    ('MATERIAL', 'Material', 'Construction or material expense', TRUE),
    ('LABOR', 'Labor', 'Labor and services', TRUE),
    ('OTHER_INCOME', 'Other Income', 'Miscellaneous income', TRUE),
    ('OTHER_EXPENSE', 'Other Expense', 'Miscellaneous expense', TRUE)
ON CONFLICT (code) DO NOTHING;

INSERT INTO public.activities (fund_id, code, name, description, start_date, end_date, active)
SELECT id, 'RUANG_SOUND', 'Ruang Sound', 'Ruang Sound renovation and sound system project', '2026-01-01', '2026-12-31', TRUE
FROM public.funds
WHERE code = 'WAKAF'
ON CONFLICT (code) DO NOTHING;

INSERT INTO public.activities (fund_id, code, name, description, start_date, end_date, active)
SELECT id, 'KAJIAN_JUMAT', 'Kajian Jumat', 'Weekly Friday study session', '2026-01-01', '2026-12-31', TRUE
FROM public.funds
WHERE code = 'INFAQ'
ON CONFLICT (code) DO NOTHING;

INSERT INTO public.persons (name, phone, role, notes, active)
VALUES
    ('Dian Hidayat', '0812-3456-7890', 'Treasurer', 'Handles cash and reimbursements', TRUE),
    ('Pak Radi', '0813-0000-1111', 'Worker', 'Construction worker / labor support', TRUE);

INSERT INTO public.vendors (name, phone, address, bank_name, bank_account_number, bank_account_name, notes, active)
VALUES
    ('Toko Material Nusantara', '0812-2222-3333', 'Jl. Merdeka No. 12', 'Bank Syariah Indonesia', '1234567890', 'Toko Material Nusantara', 'Building materials supplier', TRUE),
    ('Pak Radi', '0813-0000-1111', 'Jl. Pelajar No. 8', 'Bank Mandiri', '9988776655', 'Radi', 'Worker / contractor', TRUE);

INSERT INTO public.accounts (name, account_type, bank_name, account_number, account_name, description, active)
VALUES ('Kas Infaq', 'CASH', NULL, NULL, NULL, 'Cash account used for Infaq operations', TRUE);

INSERT INTO public.accounts (name, account_type, bank_name, account_number, account_name, description, active)
VALUES ('BSI Infaq', 'BANK', 'Bank Syariah Indonesia', '1001001234', 'Masjid Al-Hidayah', 'Bank account used for Infaq operations', TRUE);

INSERT INTO public.accounts (name, account_type, bank_name, account_number, account_name, description, active)
VALUES ('Kas Wakaf', 'CASH', NULL, NULL, NULL, 'Cash account used for Wakaf operations', TRUE);

INSERT INTO public.accounts (name, account_type, bank_name, account_number, account_name, description, active)
VALUES ('BSI Wakaf', 'BANK', 'Bank Syariah Indonesia', '2002005678', 'Masjid Al-Hidayah', 'Bank account used for Wakaf operations', TRUE);
