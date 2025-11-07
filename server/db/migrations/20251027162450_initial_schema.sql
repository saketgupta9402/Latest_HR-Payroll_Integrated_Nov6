-- Migration: 20251027162450 (Corrected)
-- Create enums
CREATE TYPE public.user_role AS ENUM ('owner', 'admin', 'hr', 'payroll', 'finance', 'manager', 'employee');
CREATE TYPE public.employment_status AS ENUM ('active', 'inactive', 'on_leave', 'terminated');
CREATE TYPE public.payroll_status AS ENUM ('draft', 'approved', 'processing', 'completed', 'failed');

-- Tenants table
CREATE TABLE public.tenants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subdomain TEXT UNIQUE NOT NULL,
  company_name TEXT NOT NULL,
  logo_url TEXT,
  theme_color TEXT DEFAULT '#1E40AF',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Users table (This was missing)
CREATE TABLE public.users (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- User roles table
CREATE TABLE public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  tenant_id UUID REFERENCES public.tenants(id) ON DELETE CASCADE NOT NULL,
  role public.user_role NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, tenant_id, role)
);

-- Profiles table
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  tenant_id UUID REFERENCES public.tenants(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Employees table
CREATE TABLE public.employees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES public.tenants(id) ON DELETE CASCADE NOT NULL,
  employee_code TEXT NOT NULL,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  date_of_joining DATE NOT NULL,
  date_of_birth DATE,
  department TEXT,
  designation TEXT,
  status public.employment_status DEFAULT 'active',
  pan_number TEXT,
  aadhaar_number TEXT,
  bank_account_number TEXT,
  bank_ifsc TEXT,
  bank_name TEXT,
  created_by UUID REFERENCES public.users(id),
  updated_by UUID REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(tenant_id, employee_code)
);

-- Compensation structures table
CREATE TABLE public.compensation_structures (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES public.tenants(id) ON DELETE CASCADE NOT NULL,
  employee_id UUID REFERENCES public.employees(id) ON DELETE CASCADE NOT NULL,
  effective_from DATE NOT NULL,
  ctc DECIMAL(12,2) NOT NULL,
  basic_salary DECIMAL(12,2) NOT NULL,
  hra DECIMAL(12,2) DEFAULT 0,
  special_allowance DECIMAL(12,2) DEFAULT 0,
  da DECIMAL(12,2) DEFAULT 0,
  lta DECIMAL(12,2) DEFAULT 0,
  bonus DECIMAL(12,2) DEFAULT 0,
  other_allowances JSONB DEFAULT '{}'::jsonb,
  deductions JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Payroll cycles table
CREATE TABLE public.payroll_cycles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES public.tenants(id) ON DELETE CASCADE NOT NULL,
  month INT NOT NULL CHECK (month BETWEEN 1 AND 12),
  year INT NOT NULL CHECK (year BETWEEN 2000 AND 2100),
  status public.payroll_status DEFAULT 'draft',
  total_employees INT DEFAULT 0,
  total_amount DECIMAL(14,2) DEFAULT 0,
  payday DATE,
  created_by UUID REFERENCES public.users(id),
  approved_by UUID REFERENCES public.users(id),
  approved_at TIMESTAMPTZ,
  processed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(tenant_id, month, year)
);

-- Payroll items table
CREATE TABLE public.payroll_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES public.tenants(id) ON DELETE CASCADE NOT NULL,
  payroll_cycle_id UUID REFERENCES public.payroll_cycles(id) ON DELETE CASCADE NOT NULL,
  employee_id UUID REFERENCES public.employees(id) ON DELETE CASCADE NOT NULL,
  basic_salary DECIMAL(12,2) NOT NULL,
  hra DECIMAL(12,2) DEFAULT 0,
  special_allowance DECIMAL(12,2) DEFAULT 0,
  da DECIMAL(12,2) DEFAULT 0,
  lta DECIMAL(12,2) DEFAULT 0,
  bonus DECIMAL(12,2) DEFAULT 0,
  gross_salary DECIMAL(12,2) NOT NULL,
  pf_deduction DECIMAL(12,2) DEFAULT 0,
  esi_deduction DECIMAL(12,2) DEFAULT 0,
  pt_deduction DECIMAL(12,2) DEFAULT 0,
  tds_deduction DECIMAL(12,2) DEFAULT 0,
  deductions DECIMAL(12,2) DEFAULT 0,
  net_salary DECIMAL(12,2) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(payroll_cycle_id, employee_id)
);

-- Payslips table
CREATE TABLE public.payslips (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES public.tenants(id) ON DELETE CASCADE NOT NULL,
  payroll_cycle_id UUID REFERENCES public.payroll_cycles(id) ON DELETE CASCADE NOT NULL,
  employee_id UUID REFERENCES public.employees(id) ON DELETE CASCADE NOT NULL,
  content JSONB NOT NULL,
  generated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(payroll_cycle_id, employee_id)
);

-- Audit logs table for payroll actions
CREATE TABLE public.payroll_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES public.tenants(id) ON DELETE CASCADE,
  payroll_cycle_id UUID REFERENCES public.payroll_cycles(id) ON DELETE CASCADE,
  employee_id UUID REFERENCES public.employees(id),
  action TEXT NOT NULL,
  performed_by UUID REFERENCES public.users(id),
  details JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes for better query performance
CREATE INDEX idx_comp_struct_employee ON public.compensation_structures(employee_id);
CREATE INDEX idx_comp_struct_tenant ON public.compensation_structures(tenant_id);
CREATE INDEX idx_payroll_cycles_tenant ON public.payroll_cycles(tenant_id);
CREATE INDEX idx_payroll_cycles_status ON public.payroll_cycles(status);
CREATE INDEX idx_payroll_items_cycle ON public.payroll_items(payroll_cycle_id);
CREATE INDEX idx_payroll_items_employee ON public.payroll_items(employee_id);
CREATE INDEX idx_payroll_audit_logs_tenant ON public.payroll_audit_logs(tenant_id);
CREATE INDEX idx_payroll_audit_logs_cycle ON public.payroll_audit_logs(payroll_cycle_id);

-- Enable row-level security on core payroll tables (will be configured later)
ALTER TABLE public.payroll_cycles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payroll_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payroll_audit_logs ENABLE ROW LEVEL SECURITY;

-- Default policies (will be refined)
CREATE POLICY payroll_cycles_org_policy ON public.payroll_cycles
  USING (tenant_id = current_setting('app.org_id')::uuid);

CREATE POLICY payroll_items_org_policy ON public.payroll_items
  USING (tenant_id = current_setting('app.org_id')::uuid);

CREATE POLICY payroll_audit_org_policy ON public.payroll_audit_logs
  USING (tenant_id = current_setting('app.org_id')::uuid);

