-- Ledger tables for transactions, receipts, and reimbursements

CREATE TABLE IF NOT EXISTS public.transactions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transaction_date DATE NOT NULL,
    fund_id BIGINT NOT NULL,
    category_id BIGINT NOT NULL,
    activity_id BIGINT,
    transaction_type VARCHAR(20) NOT NULL,
    amount NUMERIC(15,2) NOT NULL,
    description TEXT NOT NULL,
    vendor_id BIGINT,
    person_id BIGINT,
    account_id BIGINT,
    reference_number VARCHAR(100),
    receipt_url TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_transactions_fund
        FOREIGN KEY (fund_id)
        REFERENCES public.funds(id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_transactions_category
        FOREIGN KEY (category_id)
        REFERENCES public.categories(id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_transactions_activity
        FOREIGN KEY (activity_id)
        REFERENCES public.activities(id)
        ON DELETE SET NULL,
    CONSTRAINT fk_transactions_vendor
        FOREIGN KEY (vendor_id)
        REFERENCES public.vendors(id)
        ON DELETE SET NULL,
    CONSTRAINT fk_transactions_person
        FOREIGN KEY (person_id)
        REFERENCES public.persons(id)
        ON DELETE SET NULL,
    CONSTRAINT fk_transactions_account
        FOREIGN KEY (account_id)
        REFERENCES public.accounts(id)
        ON DELETE SET NULL,
    CONSTRAINT chk_transactions_amount
        CHECK (amount > 0),
    CONSTRAINT chk_transactions_type
        CHECK (transaction_type IN ('INCOME', 'EXPENSE'))
);

ALTER TABLE public.transactions
    DROP COLUMN IF EXISTS reimbursement_status;

CREATE TABLE IF NOT EXISTS public.receipts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transaction_id BIGINT NOT NULL,
    storage_provider VARCHAR(50),
    file_path TEXT,
    file_name VARCHAR(255),
    mime_type VARCHAR(100),
    ocr_status VARCHAR(30) NOT NULL DEFAULT 'NOT_PROCESSED',
    ocr_data JSONB,
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_receipts_transaction
        FOREIGN KEY (transaction_id)
        REFERENCES public.transactions(id)
        ON DELETE CASCADE,
    CONSTRAINT chk_receipts_ocr_status
        CHECK (ocr_status IN ('NOT_PROCESSED', 'PROCESSING', 'PROCESSED', 'FAILED'))
);

CREATE TABLE IF NOT EXISTS public.reimbursements (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transaction_id BIGINT NOT NULL,
    person_id BIGINT NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    reimbursed_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_reimbursements_transaction
        FOREIGN KEY (transaction_id)
        REFERENCES public.transactions(id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_reimbursements_person
        FOREIGN KEY (person_id)
        REFERENCES public.persons(id)
        ON DELETE RESTRICT,
    CONSTRAINT chk_reimbursements_status
        CHECK (status IN ('PENDING', 'REIMBURSED', 'CANCELLED'))
);

ALTER TABLE public.reimbursements
    DROP COLUMN IF EXISTS amount;

COMMENT ON TABLE public.transactions IS 'Single source of truth for all financial movements in the mosque ledger.';
COMMENT ON COLUMN public.transactions.transaction_date IS 'Actual date the financial event occurred.';
COMMENT ON COLUMN public.transactions.fund_id IS 'The fund impacted by the transaction.';
COMMENT ON COLUMN public.transactions.category_id IS 'The financial category for the transaction.';
COMMENT ON COLUMN public.transactions.activity_id IS 'Optional activity, project, or event linked to the transaction.';
COMMENT ON COLUMN public.transactions.transaction_type IS 'Whether the movement is an INCOME or EXPENSE.';
COMMENT ON COLUMN public.transactions.amount IS 'Positive amount for the financial movement.';
COMMENT ON COLUMN public.transactions.account_id IS 'Cash or bank account used for the transaction.';

COMMENT ON TABLE public.receipts IS 'Metadata and storage references for scanned or uploaded transaction documents.';
COMMENT ON COLUMN public.receipts.transaction_id IS 'Transaction associated with the receipt.';
COMMENT ON COLUMN public.receipts.storage_provider IS 'Cloud storage provider such as GOOGLE_DRIVE or S3.';
COMMENT ON COLUMN public.receipts.ocr_status IS 'Current OCR status for the receipt document.';

COMMENT ON TABLE public.reimbursements IS 'Detailed reimbursement workflow for expenses paid by a person on behalf of the mosque.';
COMMENT ON COLUMN public.reimbursements.transaction_id IS 'Expense transaction that triggered the reimbursement request.';
COMMENT ON COLUMN public.reimbursements.person_id IS 'Person to reimburse.';
COMMENT ON COLUMN public.reimbursements.status IS 'Lifecycle state of the reimbursement request.';

CREATE TRIGGER trg_transactions_set_updated_at
    BEFORE UPDATE ON public.transactions
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_reimbursements_set_updated_at
    BEFORE UPDATE ON public.reimbursements
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE INDEX IF NOT EXISTS idx_transactions_transaction_date
    ON public.transactions (transaction_date);
CREATE INDEX IF NOT EXISTS idx_transactions_fund_id
    ON public.transactions (fund_id);
CREATE INDEX IF NOT EXISTS idx_transactions_category_id
    ON public.transactions (category_id);
CREATE INDEX IF NOT EXISTS idx_transactions_activity_id
    ON public.transactions (activity_id);
CREATE INDEX IF NOT EXISTS idx_transactions_vendor_id
    ON public.transactions (vendor_id);
CREATE INDEX IF NOT EXISTS idx_transactions_person_id
    ON public.transactions (person_id);
CREATE INDEX IF NOT EXISTS idx_transactions_account_id
    ON public.transactions (account_id);
CREATE INDEX IF NOT EXISTS idx_transactions_transaction_type
    ON public.transactions (transaction_type);
CREATE INDEX IF NOT EXISTS idx_transactions_fund_date
    ON public.transactions (fund_id, transaction_date);
CREATE INDEX IF NOT EXISTS idx_transactions_category_date
    ON public.transactions (category_id, transaction_date);
CREATE INDEX IF NOT EXISTS idx_transactions_fund_category_date
    ON public.transactions (fund_id, category_id, transaction_date);

CREATE INDEX IF NOT EXISTS idx_activities_fund_id
    ON public.activities (fund_id);
CREATE INDEX IF NOT EXISTS idx_receipts_transaction_id
    ON public.receipts (transaction_id);
CREATE INDEX IF NOT EXISTS idx_reimbursements_transaction_id
    ON public.reimbursements (transaction_id);
CREATE INDEX IF NOT EXISTS idx_reimbursements_person_id
    ON public.reimbursements (person_id);
