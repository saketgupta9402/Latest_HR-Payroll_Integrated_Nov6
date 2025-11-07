-- Consolidated Payroll Integration Migration (was payroll-integration 001)

ALTER TABLE public.users 
  ADD COLUMN IF NOT EXISTS hr_user_id UUID,
  ADD COLUMN IF NOT EXISTS org_id UUID,
  ADD COLUMN IF NOT EXISTS payroll_role VARCHAR(50) CHECK (payroll_role IN ('payroll_admin', 'payroll_employee'));

CREATE TABLE IF NOT EXISTS public.payroll_user_ext (
  hr_user_id UUID PRIMARY KEY,
  bank_account VARCHAR(64),
  bank_name VARCHAR(255),
  bank_branch VARCHAR(255),
  ifsc_code VARCHAR(16),
  pan VARCHAR(16),
  aadhar VARCHAR(16),
  passport VARCHAR(32),
  tax_reg_no VARCHAR(32),
  esi_number VARCHAR(32),
  pf_number VARCHAR(32),
  uan VARCHAR(32),
  updated_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.payroll_orgs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  hr_org_id UUID UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  domain VARCHAR(255),
  timezone VARCHAR(50) DEFAULT 'Asia/Kolkata',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_users_hr_user_id ON public.users(hr_user_id);
CREATE INDEX IF NOT EXISTS idx_users_org_id ON public.users(org_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_payroll_role ON public.users(payroll_role);
CREATE INDEX IF NOT EXISTS idx_payroll_user_ext_hr_user_id ON public.payroll_user_ext(hr_user_id);
CREATE INDEX IF NOT EXISTS idx_payroll_orgs_hr_org_id ON public.payroll_orgs(hr_org_id);

CREATE OR REPLACE FUNCTION public.update_payroll_user_ext_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER IF NOT EXISTS update_payroll_user_ext_updated_at
  BEFORE UPDATE ON public.payroll_user_ext
  FOR EACH ROW
  EXECUTE FUNCTION public.update_payroll_user_ext_updated_at();

CREATE TRIGGER IF NOT EXISTS update_payroll_orgs_updated_at
  BEFORE UPDATE ON public.payroll_orgs
  FOR EACH ROW
  EXECUTE FUNCTION public.update_payroll_user_ext_updated_at();

