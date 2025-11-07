-- Consolidated Payroll Integration Migration (was payroll-integration 003)
-- Adds PIN support for Payroll users

ALTER TABLE public.users 
  ADD COLUMN IF NOT EXISTS pin_hash VARCHAR(255),
  ADD COLUMN IF NOT EXISTS pin_set_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_users_pin_set
  ON public.users(pin_set_at)
  WHERE pin_hash IS NOT NULL;

COMMENT ON COLUMN public.users.pin_hash IS 'BCrypt hash of 6-digit PIN for Payroll authentication';
COMMENT ON COLUMN public.users.pin_set_at IS 'Timestamp when PIN was set';

