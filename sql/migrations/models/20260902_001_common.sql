-- Mosque Financial System
-- Common helper functions and reusable database conventions

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.set_updated_at IS
    'Automatically refreshes updated_at on rows whenever a record is updated.';
