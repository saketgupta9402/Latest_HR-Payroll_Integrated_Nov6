-- Migration: Create Payroll Schema and Migrate Tables
-- This consolidates the payroll database into the main hr_suite database
-- All payroll tables will be in the payroll schema for better organization

-- Create payroll schema
CREATE SCHEMA IF NOT EXISTS payroll;

-- Grant usage on schema to postgres user (will be revoked later for security)
GRANT USAGE ON SCHEMA payroll TO postgres;

-- Create payroll-specific enums in payroll schema
CREATE TYPE payroll.user_role AS ENUM ('owner', 'admin', 'hr', 'payroll', 'finance', 'manager', 'employee');
CREATE TYPE payroll.employment_status AS ENUM ('active', 'inactive', 'on_leave', 'terminated');
CREATE TYPE payroll.payroll_status AS ENUM ('draft', 'approved', 'processing', 'completed', 'failed', 'pending_approval');

-- Note: We'll keep using the main public schema for shared tables like users, profiles, organizations
-- Only payroll-specific tables go into the payroll schema

-- Tenants table (if not exists in public, create in payroll for payroll-specific tenant data)
-- Actually, we'll use the main organizations table, so this is just for reference
-- CREATE TABLE IF NOT EXISTS payroll.tenants (
--   id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--   subdomain TEXT UNIQUE NOT NULL,
--   company_name TEXT NOT NULL,
--   logo_url TEXT,
--   theme_color TEXT DEFAULT '#1E40AF',
--   created_at TIMESTAMPTZ DEFAULT now(),
--   updated_at TIMESTAMPTZ DEFAULT now()
-- );

-- Employees table in payroll schema (payroll-specific employee data)
-- Note: This extends the main employees table with payroll-specific fields
-- We'll create a view or use joins to connect to main employees table
CREATE TABLE IF NOT EXISTS payroll.employees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES organizations(id) ON DELETE CASCADE NOT NULL,
  employee_code TEXT NOT NULL,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  date_of_joining DATE NOT NULL,
  date_of_birth DATE,
  department TEXT,
  designation TEXT,
  status payroll.employment_status DEFAULT 'active',
  pan_number TEXT,
  aadhaar_number TEXT,
  bank_account_number TEXT,
  bank_ifsc TEXT,
  bank_name TEXT,
  created_by UUID REFERENCES profiles(id),
  updated_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(tenant_id, employee_code)
);

-- Compensation structures table
CREATE TABLE IF NOT EXISTS payroll.compensation_structures (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES organizations(id) ON DELETE CASCADE NOT NULL,
  employee_id UUID REFERENCES payroll.employees(id) ON DELETE CASCADE NOT NULL,
  effective_from DATE NOT NULL,
  ctc DECIMAL(12,2) NOT NULL,
  basic_salary DECIMAL(12,2) NOT NULL,
  hra DECIMAL(12,2) DEFAULT 0,
  special_allowance DECIMAL(12,2) DEFAULT 0,
  da DECIMAL(12,2) DEFAULT 0,
  lta DECIMAL(12,2) DEFAULT 0,
  bonus DECIMAL(12,2) DEFAULT 0,
  pf_contribution DECIMAL(12,2) DEFAULT 0,
  esi_contribution DECIMAL(12,2) DEFAULT 0,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Payroll cycles table
CREATE TABLE IF NOT EXISTS payroll.payroll_cycles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES organizations(id) ON DELETE CASCADE NOT NULL,
  month INTEGER NOT NULL CHECK (month >= 1 AND month <= 12),
  year INTEGER NOT NULL,
  payday INTEGER CHECK (payday >= 1 AND payday <= 31),
  status payroll.payroll_status DEFAULT 'draft',
  total_employees INTEGER DEFAULT 0,
  total_amount DECIMAL(15,2) DEFAULT 0,
  approved_by UUID REFERENCES profiles(id),
  approved_at TIMESTAMPTZ,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(tenant_id, month, year)
);

-- Payroll items table (sensitive salary data)
CREATE TABLE IF NOT EXISTS payroll.payroll_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES organizations(id) ON DELETE CASCADE NOT NULL,
  payroll_cycle_id UUID REFERENCES payroll.payroll_cycles(id) ON DELETE CASCADE NOT NULL,
  employee_id UUID REFERENCES payroll.employees(id) ON DELETE CASCADE NOT NULL,
  gross_salary DECIMAL(12,2) NOT NULL,
  deductions DECIMAL(12,2) DEFAULT 0,
  net_salary DECIMAL(12,2) NOT NULL,
  basic_salary DECIMAL(12,2) NOT NULL,
  hra DECIMAL(12,2) DEFAULT 0,
  special_allowance DECIMAL(12,2) DEFAULT 0,
  pf_deduction DECIMAL(12,2) DEFAULT 0,
  esi_deduction DECIMAL(12,2) DEFAULT 0,
  tds_deduction DECIMAL(12,2) DEFAULT 0,
  pt_deduction DECIMAL(12,2) DEFAULT 0,
  lop_days DECIMAL(5,2) DEFAULT 0,
  paid_days DECIMAL(5,2) DEFAULT 0,
  total_working_days DECIMAL(5,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(payroll_cycle_id, employee_id)
);

-- Payroll settings table
CREATE TABLE IF NOT EXISTS payroll.payroll_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES organizations(id) ON DELETE CASCADE NOT NULL UNIQUE,
  pf_rate DECIMAL(5,2) DEFAULT 12.00,
  esi_rate DECIMAL(5,2) DEFAULT 3.25,
  pt_rate DECIMAL(8,2) DEFAULT 200.00,
  tds_threshold DECIMAL(12,2) DEFAULT 250000.00,
  basic_salary_percentage DECIMAL(5,2) DEFAULT 40.00,
  hra_percentage DECIMAL(5,2) DEFAULT 40.00,
  special_allowance_percentage DECIMAL(5,2) DEFAULT 20.00,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Tax declarations table
CREATE TABLE IF NOT EXISTS payroll.tax_declarations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES organizations(id) ON DELETE CASCADE NOT NULL,
  employee_id UUID REFERENCES payroll.employees(id) ON DELETE CASCADE NOT NULL,
  financial_year TEXT NOT NULL,
  section_80c DECIMAL(12,2) DEFAULT 0,
  section_80d DECIMAL(12,2) DEFAULT 0,
  section_24b DECIMAL(12,2) DEFAULT 0,
  other_deductions DECIMAL(12,2) DEFAULT 0,
  total_deductions DECIMAL(12,2) DEFAULT 0,
  submitted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(employee_id, financial_year)
);

-- Tax documents table
CREATE TABLE IF NOT EXISTS payroll.tax_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES organizations(id) ON DELETE CASCADE NOT NULL,
  employee_id UUID REFERENCES payroll.employees(id) ON DELETE CASCADE NOT NULL,
  document_type TEXT NOT NULL,
  document_url TEXT NOT NULL,
  financial_year TEXT,
  uploaded_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Leave requests table (for payroll integration)
CREATE TABLE IF NOT EXISTS payroll.leave_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES organizations(id) ON DELETE CASCADE NOT NULL,
  employee_id UUID REFERENCES payroll.employees(id) ON DELETE CASCADE NOT NULL,
  leave_type TEXT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  days DECIMAL(5,2) NOT NULL,
  status TEXT DEFAULT 'pending',
  reason TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Attendance records table (for payroll integration)
CREATE TABLE IF NOT EXISTS payroll.attendance_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES organizations(id) ON DELETE CASCADE NOT NULL,
  employee_id UUID REFERENCES payroll.employees(id) ON DELETE CASCADE NOT NULL,
  date DATE NOT NULL,
  status TEXT NOT NULL,
  check_in_time TIMESTAMPTZ,
  check_out_time TIMESTAMPTZ,
  hours_worked DECIMAL(5,2),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(employee_id, date)
);

-- Audit logs table for payroll (separate from main audit logs for compliance)
CREATE TABLE IF NOT EXISTS payroll.audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES organizations(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id UUID,
  details JSONB,
  ip_address TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_payroll_employees_tenant_id ON payroll.employees(tenant_id);
CREATE INDEX IF NOT EXISTS idx_payroll_employees_email ON payroll.employees(email);
CREATE INDEX IF NOT EXISTS idx_payroll_compensation_employee_id ON payroll.compensation_structures(employee_id);
CREATE INDEX IF NOT EXISTS idx_payroll_cycles_tenant_month_year ON payroll.payroll_cycles(tenant_id, year, month);
CREATE INDEX IF NOT EXISTS idx_payroll_items_cycle_id ON payroll.payroll_items(payroll_cycle_id);
CREATE INDEX IF NOT EXISTS idx_payroll_items_employee_id ON payroll.payroll_items(employee_id);
CREATE INDEX IF NOT EXISTS idx_payroll_audit_logs_user_id ON payroll.audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_payroll_audit_logs_entity ON payroll.audit_logs(entity_type, entity_id);

-- Create trigger function for updated_at
CREATE OR REPLACE FUNCTION payroll.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers
CREATE TRIGGER update_payroll_employees_updated_at BEFORE UPDATE ON payroll.employees
  FOR EACH ROW EXECUTE FUNCTION payroll.update_updated_at_column();

CREATE TRIGGER update_payroll_compensation_updated_at BEFORE UPDATE ON payroll.compensation_structures
  FOR EACH ROW EXECUTE FUNCTION payroll.update_updated_at_column();

CREATE TRIGGER update_payroll_cycles_updated_at BEFORE UPDATE ON payroll.payroll_cycles
  FOR EACH ROW EXECUTE FUNCTION payroll.update_updated_at_column();

CREATE TRIGGER update_payroll_items_updated_at BEFORE UPDATE ON payroll.payroll_items
  FOR EACH ROW EXECUTE FUNCTION payroll.update_updated_at_column();

CREATE TRIGGER update_payroll_settings_updated_at BEFORE UPDATE ON payroll.payroll_settings
  FOR EACH ROW EXECUTE FUNCTION payroll.update_updated_at_column();

-- SECURITY: Revoke all permissions from public and postgres user
-- This is critical - the default postgres user should NOT have direct access
REVOKE ALL ON SCHEMA payroll FROM public;
REVOKE ALL ON ALL TABLES IN SCHEMA payroll FROM public;
REVOKE ALL ON ALL TABLES IN SCHEMA payroll FROM postgres;

-- Create a privileged role for payroll admin operations
-- This role will be used by SECURITY DEFINER functions
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'payroll_admin_role') THEN
    CREATE ROLE payroll_admin_role;
  END IF;
END
$$;

-- Grant necessary permissions to payroll_admin_role
GRANT USAGE ON SCHEMA payroll TO payroll_admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA payroll TO payroll_admin_role;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA payroll TO payroll_admin_role;

-- Grant execute on functions to payroll_admin_role
GRANT EXECUTE ON FUNCTION payroll.update_updated_at_column() TO payroll_admin_role;

-- Note: The postgres user will access payroll data ONLY through SECURITY DEFINER functions
-- These functions will be created in a separate migration after the routes are consolidated

