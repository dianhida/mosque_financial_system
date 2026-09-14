
ALTER TABLE public.transactions
    ADD COLUMN IF NOT EXISTS external_id TEXT;
CREATE UNIQUE INDEX IF NOT EXISTS uq_transactions_external_id
    ON public.transactions (external_id)
    WHERE external_id IS NOT NULL;

COMMENT ON COLUMN public.transactions.external_id IS
    'Stable source-system identifier such as INF1 or WKF1 used for idempotent imports.';

CREATE SCHEMA IF NOT EXISTS staging;

CREATE TABLE IF NOT EXISTS staging.import_batches (
    batch_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_file TEXT NOT NULL,
    source_type TEXT NOT NULL,
    imported_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status TEXT NOT NULL DEFAULT 'RUNNING',
    total_rows INTEGER NOT NULL DEFAULT 0,
    success_rows INTEGER NOT NULL DEFAULT 0,
    failed_rows INTEGER NOT NULL DEFAULT 0,
    skipped_rows INTEGER NOT NULL DEFAULT 0,
    notes TEXT,
    CONSTRAINT chk_import_batches_source_type
        CHECK (source_type IN ('INFAQ', 'WAKAF', 'VENDOR')),
    CONSTRAINT chk_import_batches_status
        CHECK (status IN ('RUNNING', 'COMPLETED', 'COMPLETED_WITH_ERRORS', 'FAILED')),
    CONSTRAINT chk_import_batches_counts
        CHECK (total_rows >= 0 AND success_rows >= 0 AND failed_rows >= 0 AND skipped_rows >= 0)
);

CREATE TABLE IF NOT EXISTS staging.import_errors (
    error_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    batch_id BIGINT NOT NULL,
    source_row INTEGER NOT NULL,
    external_id TEXT,
    error_message TEXT NOT NULL,
    raw_payload JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_import_errors_batch
        FOREIGN KEY (batch_id)
        REFERENCES staging.import_batches(batch_id)
        ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS staging.infaq_raw (
    raw_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    batch_id BIGINT NOT NULL,
    source_row INTEGER NOT NULL,
    no_text TEXT,
    flow TEXT,
    kredit TEXT,
    debit TEXT,
    tanggal TEXT,
    bulan TEXT,
    event TEXT,
    description TEXT,
    pic TEXT,
    reimbursement TEXT,
    remark TEXT,
    reimburse TEXT,
    saldo TEXT,
    note TEXT,
    external_id TEXT,
    summary_income TEXT,
    summary_expense TEXT,
    summary_month TEXT,
    summary_event TEXT,
    summary_total_kredit TEXT,
    summary_total_debit TEXT,
    summary_total TEXT,
    raw_payload JSONB NOT NULL,
    loaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_infaq_raw_batch
        FOREIGN KEY (batch_id)
        REFERENCES staging.import_batches(batch_id)
        ON DELETE CASCADE,
    CONSTRAINT uq_infaq_raw_batch_row UNIQUE (batch_id, source_row)
);

CREATE TABLE IF NOT EXISTS staging.wakaf_raw (
    raw_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    batch_id BIGINT NOT NULL,
    source_row INTEGER NOT NULL,
    no_text TEXT,
    flow TEXT,
    account_type TEXT,
    kredit TEXT,
    debit TEXT,
    tanggal TEXT,
    category TEXT,
    description TEXT,
    nota TEXT,
    vendor TEXT,
    donator TEXT,
    external_id TEXT,
    summary_income TEXT,
    summary_expense TEXT,
    target TEXT,
    kekurangan TEXT,
    balance_label TEXT,
    balance_update_manual TEXT,
    tahap_satu TEXT,
    target_final TEXT,
    raw_payload JSONB NOT NULL,
    loaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_wakaf_raw_batch
        FOREIGN KEY (batch_id)
        REFERENCES staging.import_batches(batch_id)
        ON DELETE CASCADE,
    CONSTRAINT uq_wakaf_raw_batch_row UNIQUE (batch_id, source_row)
);

CREATE INDEX IF NOT EXISTS idx_import_errors_batch_id
    ON staging.import_errors(batch_id);
CREATE INDEX IF NOT EXISTS idx_infaq_raw_external_id
    ON staging.infaq_raw(external_id);
CREATE INDEX IF NOT EXISTS idx_wakaf_raw_external_id
    ON staging.wakaf_raw(external_id);
CREATE INDEX IF NOT EXISTS idx_infaq_raw_batch_id
    ON staging.infaq_raw(batch_id);
CREATE INDEX IF NOT EXISTS idx_wakaf_raw_batch_id
    ON staging.wakaf_raw(batch_id);

COMMENT ON SCHEMA staging IS 'Raw spreadsheet landing tables and import audit records.';
COMMENT ON TABLE staging.import_batches IS 'One audit record for each source file import attempt.';
COMMENT ON TABLE staging.import_errors IS 'Row-level validation and load failures retained for troubleshooting.';
COMMENT ON TABLE staging.infaq_raw IS 'Source-shaped raw rows from the INFAQ spreadsheet, including summary columns.';
COMMENT ON TABLE staging.wakaf_raw IS 'Source-shaped raw rows from the WAKAF spreadsheet, including summary columns.';

CREATE UNIQUE INDEX IF NOT EXISTS uq_reimbursements_transaction_id
    ON public.reimbursements(transaction_id);
