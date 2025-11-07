-- Consolidated Payroll Integration Migration (was payroll-integration 002)
-- Ensure tenant/organization scoping indexes exist on payroll tables

CREATE INDEX IF NOT EXISTS idx_payroll_cycles_tenant_status
  ON public.payroll_cycles(tenant_id, status);

CREATE INDEX IF NOT EXISTS idx_payroll_items_tenant_employee
  ON public.payroll_items(tenant_id, employee_id);

CREATE INDEX IF NOT EXISTS idx_payroll_items_tenant_cycle
  ON public.payroll_items(tenant_id, payroll_cycle_id);

CREATE INDEX IF NOT EXISTS idx_payslips_tenant
  ON public.payslips(tenant_id);

CREATE INDEX IF NOT EXISTS idx_payroll_audit_logs_tenant_action
  ON public.payroll_audit_logs(tenant_id, action);

CREATE INDEX IF NOT EXISTS idx_users_org_role
  ON public.users(org_id, payroll_role);

