-- Create shifts table
CREATE TABLE public.shifts (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id UUID NOT NULL,
  employee_id UUID REFERENCES public.employees(id),
  shift_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  shift_type TEXT NOT NULL DEFAULT 'regular',
  status TEXT NOT NULL DEFAULT 'scheduled',
  notes TEXT,
  created_by UUID,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.shifts ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "HR can manage all shifts"
ON public.shifts
FOR ALL
USING (
  tenant_id = get_user_tenant_id(auth.uid()) AND 
  (has_role(auth.uid(), 'hr') OR has_role(auth.uid(), 'director') OR has_role(auth.uid(), 'ceo'))
);

CREATE POLICY "Managers can manage their team shifts"
ON public.shifts
FOR ALL
USING (
  tenant_id = get_user_tenant_id(auth.uid()) AND
  has_role(auth.uid(), 'manager') AND
  employee_id IN (
    SELECT id FROM public.employees 
    WHERE reporting_manager_id = get_employee_id(auth.uid())
  )
);

CREATE POLICY "Employees can view their own shifts"
ON public.shifts
FOR SELECT
USING (
  employee_id = get_employee_id(auth.uid())
);

-- Add updated_at trigger
CREATE TRIGGER update_shifts_updated_at
BEFORE UPDATE ON public.shifts
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();