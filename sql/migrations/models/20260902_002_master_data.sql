-- Core master-data tables

CREATE TABLE IF NOT EXISTS public.funds (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.categories (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    parent_id BIGINT NULL,
    description TEXT,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_categories_parent
        FOREIGN KEY (parent_id)
        REFERENCES public.categories(id)
        ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS public.activities (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fund_id BIGINT NULL,
    code VARCHAR(50) UNIQUE,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    start_date DATE,
    end_date DATE,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_activities_fund
        FOREIGN KEY (fund_id)
        REFERENCES public.funds(id)
        ON DELETE SET NULL,
    CONSTRAINT chk_activities_date_range
        CHECK (end_date IS NULL OR start_date IS NULL OR end_date >= start_date)
);

CREATE TABLE IF NOT EXISTS public.persons (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    phone VARCHAR(30),
    role VARCHAR(100),
    notes TEXT,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.vendors (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    phone VARCHAR(30),
    address TEXT,
    bank_name VARCHAR(100),
    bank_account_number VARCHAR(100),
    bank_account_name VARCHAR(150),
    notes TEXT,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.accounts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    account_type VARCHAR(20) NOT NULL,
    bank_name VARCHAR(100),
    account_number VARCHAR(100),
    account_name VARCHAR(150),
    description TEXT,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_accounts_type
        CHECK (account_type IN ('CASH', 'BANK', 'OTHER'))
);

COMMENT ON TABLE public.funds IS 'Separated financial pools for mosque operations, such as Infaq and Wakaf.';
COMMENT ON COLUMN public.funds.code IS 'Stable machine-readable code such as INFAQ or WAKAF.';
COMMENT ON COLUMN public.funds.name IS 'Human-readable fund name shown in reports and forms.';
COMMENT ON COLUMN public.funds.active IS 'Whether the fund remains usable in new transactions.';

COMMENT ON TABLE public.categories IS 'Financial category classification for income and expense records.';
COMMENT ON COLUMN public.categories.code IS 'Stable machine-readable category code.';
COMMENT ON COLUMN public.categories.parent_id IS 'Optional parent category for hierarchical classification.';

COMMENT ON TABLE public.activities IS 'Projects, events, or activities tied to a transaction.';
COMMENT ON COLUMN public.activities.fund_id IS 'Fund to which the activity is related when applicable.';
COMMENT ON COLUMN public.activities.code IS 'Optional human-friendly identifier for the activity.';

COMMENT ON TABLE public.persons IS 'People associated with payments, reimbursements, or transaction handling.';
COMMENT ON COLUMN public.persons.name IS 'Full name of the person involved in a financial interaction.';

COMMENT ON TABLE public.vendors IS 'External suppliers, workers, or payment recipients.';
COMMENT ON COLUMN public.vendors.name IS 'Vendor, worker, or business name.';

COMMENT ON TABLE public.accounts IS 'Cash or bank accounts used as mosque payment sources, independent of funds.';
COMMENT ON COLUMN public.accounts.account_type IS 'Account type such as CASH or BANK.';

CREATE TRIGGER trg_funds_set_updated_at
    BEFORE UPDATE ON public.funds
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_categories_set_updated_at
    BEFORE UPDATE ON public.categories
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_activities_set_updated_at
    BEFORE UPDATE ON public.activities
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_persons_set_updated_at
    BEFORE UPDATE ON public.persons
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_vendors_set_updated_at
    BEFORE UPDATE ON public.vendors
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_accounts_set_updated_at
    BEFORE UPDATE ON public.accounts
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
