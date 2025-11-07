-- Migration: 20251028053241
-- Add payroll settings table for statutory rates and preferences

CREATE TABLE IF NOT EXISTS public.payroll_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES public.tenants(id) ON DELETE CASCADE NOT NULL,
  pf_rate DECIMAL(5,2) DEFAULT 12.00,
  esi_rate DECIMAL(5,2) DEFAULT 0.75,
  pt_rate DECIMAL(5,2) DEFAULT 200.00,
  tds_threshold DECIMAL(10,2) DEFAULT 250000.00,
  hra_percentage DECIMAL(5,2) DEFAULT 40.00,
  special_allowance_percentage DECIMAL(5,2) DEFAULT 10.00,
  basic_salary_percentage DECIMAL(5,2) DEFAULT 50.00,
  rounding_rule TEXT DEFAULT 'nearest',
  statutory_config JSONB DEFAULT '{}'::jsonb,
  notifications JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(tenant_id)
);

ALTER TABLE public.payroll_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY payroll_settings_org_policy ON public.payroll_settings
  USING (tenant_id = current_setting('app.org_id')::uuid);

