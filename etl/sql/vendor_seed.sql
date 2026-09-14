    -- One-time vendor seed from etl/source/Rekening Vendor.txt.
    -- Re-running this file does not duplicate vendors because names are matched case-insensitively.

    INSERT INTO public.vendors (
        name,
        bank_name,
        bank_account_number,
        bank_account_name,
        notes,
        active
    )
    SELECT
        seed.name,
        seed.bank_name,
        seed.bank_account_number,
        seed.account_holder,
        seed.notes,
        TRUE
    FROM (
        VALUES
            ('Deva Ayu Regitha', 'BRI', '767401010212532', 'Deva Ayu Regitha', 'Imported from Rekening Vendor.txt'),
            ('Jaka Santosa', 'Mandiri', '1370010121214', 'Jaka Santosa', 'Imported from Rekening Vendor.txt'),
            ('Wawan Suwandi', 'BCA', '4560702502', 'Wawan Suwandi', 'Imported from Rekening Vendor.txt'),
            ('TB Agung Sedayu', 'BCA', '8020496151', 'TB Agung Sedayu', 'Imported from Rekening Vendor.txt'),
            ('Jiana', 'BRI', '306201025339534', 'Jiana', 'Imported from Rekening Vendor.txt'),
            ('Satria Graha Utama CV', 'BCA', '4458885999', 'Satria Graha Utama CV', 'Imported from Rekening Vendor.txt'),
            ('Darwin Ginting', 'BCA', '8020496151', 'Darwin Ginting', 'Imported from Rekening Vendor.txt'),
            ('Radi', NULL, NULL, 'Radi', 'Vendor has no bank account in source file.'),
            ('Supri', NULL, NULL, 'Supri', 'Vendor has no bank account in source file.'),
            ('Shopee', NULL, NULL, 'Shopee', 'Vendor has no bank account in source file.')
    ) AS seed(name, bank_name, bank_account_number, account_holder, notes)
    WHERE NOT EXISTS (
        SELECT 1
        FROM public.vendors existing
        WHERE LOWER(TRIM(existing.name)) = LOWER(TRIM(seed.name))
    );
