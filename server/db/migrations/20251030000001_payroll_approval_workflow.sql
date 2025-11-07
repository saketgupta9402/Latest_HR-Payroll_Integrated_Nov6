-- Migration: 20251030000001_payroll_approval_workflow
-- Additional workflow indexes to support sequential approvals

CREATE INDEX IF NOT EXISTS idx_payroll_cycle_approvals_tenant ON public.payroll_cycle_approvals(tenant_id);
CREATE INDEX IF NOT EXISTS idx_payroll_cycle_approvals_approver ON public.payroll_cycle_approvals(approver_id);
CREATE INDEX IF NOT EXISTS idx_payroll_approval_rules_sequence ON public.payroll_approval_rules(tenant_id, sequence);

