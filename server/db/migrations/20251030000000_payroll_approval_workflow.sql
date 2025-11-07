-- Migration: 20251030000000_payroll_approval_workflow
-- Adds approval workflow tables for payroll cycle approvals

CREATE TABLE IF NOT EXISTS public.payroll_cycle_approvals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES public.tenants(id) ON DELETE CASCADE NOT NULL,
  payroll_cycle_id UUID REFERENCES public.payroll_cycles(id) ON DELETE CASCADE NOT NULL,
  approver_id UUID REFERENCES public.users(id) NOT NULL,
  status TEXT DEFAULT 'pending',
  remarks TEXT,
  approved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(payroll_cycle_id, approver_id)
);

CREATE TABLE IF NOT EXISTS public.payroll_approval_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES public.tenants(id) ON DELETE CASCADE NOT NULL,
  rule_name TEXT NOT NULL,
  approver_role TEXT NOT NULL,
  sequence INT NOT NULL,
  conditions JSONB DEFAULT '{}'::jsonb,
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_payroll_cycle_approvals_cycle ON public.payroll_cycle_approvals(payroll_cycle_id);
CREATE INDEX IF NOT EXISTS idx_payroll_cycle_approvals_status ON public.payroll_cycle_approvals(status);
CREATE INDEX IF NOT EXISTS idx_payroll_approval_rules_tenant ON public.payroll_approval_rules(tenant_id);

