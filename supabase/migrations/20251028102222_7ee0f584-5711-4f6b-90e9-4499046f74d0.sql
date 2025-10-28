-- Add tenant_id to remaining tables
ALTER TABLE public.timesheets ADD COLUMN IF NOT EXISTS tenant_id uuid REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE public.timesheet_entries ADD COLUMN IF NOT EXISTS tenant_id uuid REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE public.leave_requests ADD COLUMN IF NOT EXISTS tenant_id uuid REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE public.onboarding_data ADD COLUMN IF NOT EXISTS tenant_id uuid REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE public.leave_policies ADD COLUMN IF NOT EXISTS tenant_id uuid REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE public.workflows ADD COLUMN IF NOT EXISTS tenant_id uuid REFERENCES public.organizations(id) ON DELETE CASCADE;

-- Clean up old test data
DELETE FROM timesheet_entries WHERE tenant_id IS NULL;
DELETE FROM timesheets WHERE tenant_id IS NULL;
DELETE FROM leave_requests WHERE tenant_id IS NULL;
DELETE FROM onboarding_data WHERE tenant_id IS NULL;
DELETE FROM employees WHERE tenant_id IS NULL;
DELETE FROM profiles WHERE tenant_id IS NULL;