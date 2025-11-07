-- Migration: 20251029000000
-- Create leave and attendance management tables for LOP tracking

CREATE TYPE IF NOT EXISTS public.leave_status AS ENUM ('pending', 'approved', 'rejected', 'cancelled');
CREATE TYPE IF NOT EXISTS public.leave_type AS ENUM ('sick', 'casual', 'earned', 'loss_of_pay', 'other');
CREATE TYPE IF NOT EXISTS public.attendance_status AS ENUM ('present', 'absent', 'half_day', 'holiday', 'weekend');

CREATE TABLE IF NOT EXISTS public.leave_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES public.tenants(id) ON DELETE CASCADE NOT NULL,
  employee_id UUID REFERENCES public.employees(id) ON DELETE CASCADE NOT NULL,
  leave_type public.leave_type NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  days DECIMAL(5, 2) NOT NULL,
  reason TEXT,
  status public.leave_status DEFAULT 'pending',
  approved_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  approved_at TIMESTAMPTZ,
  rejected_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  rejected_at TIMESTAMPTZ,
  rejection_reason TEXT,
  created_by UUID REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.attendance_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES public.tenants(id) ON DELETE CASCADE NOT NULL,
  employee_id UUID REFERENCES public.employees(id) ON DELETE CASCADE NOT NULL,
  attendance_date DATE NOT NULL,
  status public.attendance_status NOT NULL,
  is_lop BOOLEAN DEFAULT false,
  remarks TEXT,
  created_by UUID REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(tenant_id, employee_id, attendance_date)
);

ALTER TABLE public.payroll_items
  ADD COLUMN IF NOT EXISTS lop_days DECIMAL(5, 2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS paid_days DECIMAL(5, 2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_working_days DECIMAL(5, 2) DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_leave_requests_employee_id ON public.leave_requests(employee_id);
CREATE INDEX IF NOT EXISTS idx_leave_requests_tenant_id ON public.leave_requests(tenant_id);
CREATE INDEX IF NOT EXISTS idx_leave_requests_status ON public.leave_requests(status);
CREATE INDEX IF NOT EXISTS idx_leave_requests_dates ON public.leave_requests(start_date, end_date);

CREATE INDEX IF NOT EXISTS idx_attendance_records_employee_id ON public.attendance_records(employee_id);
CREATE INDEX IF NOT EXISTS idx_attendance_records_tenant_id ON public.attendance_records(tenant_id);
CREATE INDEX IF NOT EXISTS idx_attendance_records_date ON public.attendance_records(attendance_date);
CREATE INDEX IF NOT EXISTS idx_attendance_records_lop ON public.attendance_records(is_lop) WHERE is_lop = true;

CREATE TRIGGER update_leave_requests_updated_at
BEFORE UPDATE ON public.leave_requests
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_attendance_records_updated_at
BEFORE UPDATE ON public.attendance_records
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

ALTER TABLE public.leave_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY leave_requests_org_policy ON public.leave_requests
  USING (tenant_id = current_setting('app.org_id')::uuid);

CREATE POLICY attendance_records_org_policy ON public.attendance_records
  USING (tenant_id = current_setting('app.org_id')::uuid);

