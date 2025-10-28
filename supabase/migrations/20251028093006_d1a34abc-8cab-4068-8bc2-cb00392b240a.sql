-- Create timesheets table
CREATE TABLE public.timesheets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  week_start_date DATE NOT NULL,
  week_end_date DATE NOT NULL,
  total_hours DECIMAL(5,2) NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  submitted_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  reviewed_by UUID REFERENCES public.employees(id),
  reviewed_at TIMESTAMP WITH TIME ZONE,
  rejection_reason TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create timesheet_entries table for daily breakdown
CREATE TABLE public.timesheet_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  timesheet_id UUID NOT NULL REFERENCES public.timesheets(id) ON DELETE CASCADE,
  work_date DATE NOT NULL,
  hours DECIMAL(4,2) NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create leave_requests table
CREATE TABLE public.leave_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  leave_type_id UUID REFERENCES public.leave_policies(id),
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  total_days INTEGER NOT NULL,
  reason TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  submitted_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  reviewed_by UUID REFERENCES public.employees(id),
  reviewed_at TIMESTAMP WITH TIME ZONE,
  rejection_reason TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.timesheets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.timesheet_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leave_requests ENABLE ROW LEVEL SECURITY;

-- Timesheets RLS Policies
CREATE POLICY "Employees can view their own timesheets"
  ON public.timesheets FOR SELECT
  USING (employee_id = get_employee_id(auth.uid()));

CREATE POLICY "Employees can insert their own timesheets"
  ON public.timesheets FOR INSERT
  WITH CHECK (employee_id = get_employee_id(auth.uid()));

CREATE POLICY "Employees can update their pending timesheets"
  ON public.timesheets FOR UPDATE
  USING (employee_id = get_employee_id(auth.uid()) AND status = 'pending');

CREATE POLICY "Managers can view their team timesheets"
  ON public.timesheets FOR SELECT
  USING (
    employee_id IN (
      SELECT id FROM public.employees 
      WHERE reporting_manager_id = get_employee_id(auth.uid())
    )
  );

CREATE POLICY "Managers can update their team timesheets"
  ON public.timesheets FOR UPDATE
  USING (
    employee_id IN (
      SELECT id FROM public.employees 
      WHERE reporting_manager_id = get_employee_id(auth.uid())
    )
  );

CREATE POLICY "HR can view all timesheets"
  ON public.timesheets FOR SELECT
  USING (has_role(auth.uid(), 'hr'::app_role) OR has_role(auth.uid(), 'director'::app_role) OR has_role(auth.uid(), 'ceo'::app_role));

-- Timesheet entries RLS
CREATE POLICY "Users can manage entries for their timesheets"
  ON public.timesheet_entries FOR ALL
  USING (
    timesheet_id IN (
      SELECT id FROM public.timesheets 
      WHERE employee_id = get_employee_id(auth.uid())
    )
  );

CREATE POLICY "Managers can view team timesheet entries"
  ON public.timesheet_entries FOR SELECT
  USING (
    timesheet_id IN (
      SELECT t.id FROM public.timesheets t
      JOIN public.employees e ON t.employee_id = e.id
      WHERE e.reporting_manager_id = get_employee_id(auth.uid())
    )
  );

-- Leave requests RLS Policies
CREATE POLICY "Employees can view their own leave requests"
  ON public.leave_requests FOR SELECT
  USING (employee_id = get_employee_id(auth.uid()));

CREATE POLICY "Employees can insert their own leave requests"
  ON public.leave_requests FOR INSERT
  WITH CHECK (employee_id = get_employee_id(auth.uid()));

CREATE POLICY "Employees can update their pending leave requests"
  ON public.leave_requests FOR UPDATE
  USING (employee_id = get_employee_id(auth.uid()) AND status = 'pending');

CREATE POLICY "Managers can view their team leave requests"
  ON public.leave_requests FOR SELECT
  USING (
    employee_id IN (
      SELECT id FROM public.employees 
      WHERE reporting_manager_id = get_employee_id(auth.uid())
    )
  );

CREATE POLICY "Managers can update their team leave requests"
  ON public.leave_requests FOR UPDATE
  USING (
    employee_id IN (
      SELECT id FROM public.employees 
      WHERE reporting_manager_id = get_employee_id(auth.uid())
    )
  );

CREATE POLICY "HR can view all leave requests"
  ON public.leave_requests FOR SELECT
  USING (has_role(auth.uid(), 'hr'::app_role) OR has_role(auth.uid(), 'director'::app_role) OR has_role(auth.uid(), 'ceo'::app_role));

-- Triggers for updated_at
CREATE TRIGGER update_timesheets_updated_at
  BEFORE UPDATE ON public.timesheets
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_leave_requests_updated_at
  BEFORE UPDATE ON public.leave_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();