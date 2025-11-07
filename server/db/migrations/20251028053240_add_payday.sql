-- Migration: 20251028053240
-- Add payday metadata to payroll settings

CREATE TABLE IF NOT EXISTS public.payroll_paydays (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES public.tenants(id) ON DELETE CASCADE NOT NULL,
  default_payday INT NOT NULL CHECK (default_payday BETWEEN 1 AND 31),
  payday_grace_policy TEXT DEFAULT 'adjust_to_weekday',
  weekend_adjustment TEXT DEFAULT 'previous_business_day',
  holiday_adjustment TEXT DEFAULT 'previous_business_day',
  custom_overrides JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(tenant_id)
);

-- Backfill default payday data (set to 30th for existing tenants)
INSERT INTO public.payroll_paydays (tenant_id, default_payday)
SELECT DISTINCT tenant_id, 30
FROM public.payroll_cycles
ON CONFLICT (tenant_id) DO NOTHING;

