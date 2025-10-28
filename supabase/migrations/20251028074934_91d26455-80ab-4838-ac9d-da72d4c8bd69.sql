-- Create enum for user roles
CREATE TYPE public.app_role AS ENUM ('employee', 'manager', 'hr', 'director', 'ceo');

-- Create enum for onboarding status
CREATE TYPE public.onboarding_status AS ENUM ('pending', 'in_progress', 'completed');

-- Create enum for leave policy type
CREATE TYPE public.leave_type AS ENUM ('annual', 'sick', 'casual', 'maternity', 'paternity', 'bereavement');

-- Create profiles table
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  first_name TEXT,
  last_name TEXT,
  phone TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Create user_roles table
CREATE TABLE public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  role app_role NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE (user_id, role)
);

ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- Create security definer function to check roles
CREATE OR REPLACE FUNCTION public.has_role(_user_id UUID, _role app_role)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_roles
    WHERE user_id = _user_id AND role = _role
  )
$$;

-- Create function to get user's highest role
CREATE OR REPLACE FUNCTION public.get_user_role(_user_id UUID)
RETURNS app_role
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role FROM public.user_roles
  WHERE user_id = _user_id
  ORDER BY CASE role
    WHEN 'ceo' THEN 1
    WHEN 'director' THEN 2
    WHEN 'hr' THEN 3
    WHEN 'manager' THEN 4
    WHEN 'employee' THEN 5
  END
  LIMIT 1
$$;

-- Create employees table
CREATE TABLE public.employees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,
  employee_id TEXT UNIQUE NOT NULL,
  department TEXT,
  position TEXT,
  reporting_manager_id UUID REFERENCES public.employees(id),
  work_location TEXT,
  join_date DATE,
  status TEXT DEFAULT 'active',
  onboarding_status onboarding_status DEFAULT 'pending',
  temporary_password TEXT,
  must_change_password BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;

-- Create onboarding_data table
CREATE TABLE public.onboarding_data (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID REFERENCES public.employees(id) ON DELETE CASCADE UNIQUE NOT NULL,
  emergency_contact_name TEXT,
  emergency_contact_phone TEXT,
  emergency_contact_relation TEXT,
  address TEXT,
  city TEXT,
  state TEXT,
  postal_code TEXT,
  bank_account_number TEXT,
  bank_name TEXT,
  bank_branch TEXT,
  ifsc_code TEXT,
  pan_number TEXT,
  aadhar_number TEXT,
  completed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

ALTER TABLE public.onboarding_data ENABLE ROW LEVEL SECURITY;

-- Create leave_policies table
CREATE TABLE public.leave_policies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id TEXT NOT NULL,
  name TEXT NOT NULL,
  leave_type leave_type NOT NULL,
  annual_entitlement INTEGER NOT NULL,
  probation_entitlement INTEGER DEFAULT 0,
  accrual_frequency TEXT,
  carry_forward_allowed BOOLEAN DEFAULT false,
  max_carry_forward INTEGER DEFAULT 0,
  encashment_allowed BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

ALTER TABLE public.leave_policies ENABLE ROW LEVEL SECURITY;

-- Create workflows table
CREATE TABLE public.workflows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  workflow_json JSONB NOT NULL,
  status TEXT DEFAULT 'draft',
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

ALTER TABLE public.workflows ENABLE ROW LEVEL SECURITY;

-- RLS Policies for profiles
CREATE POLICY "Users can view their own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "HR can view all profiles"
  ON public.profiles FOR SELECT
  USING (public.has_role(auth.uid(), 'hr') OR public.has_role(auth.uid(), 'director') OR public.has_role(auth.uid(), 'ceo'));

-- RLS Policies for user_roles
CREATE POLICY "Users can view their own roles"
  ON public.user_roles FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "HR can view all roles"
  ON public.user_roles FOR SELECT
  USING (public.has_role(auth.uid(), 'hr') OR public.has_role(auth.uid(), 'director') OR public.has_role(auth.uid(), 'ceo'));

CREATE POLICY "HR can insert roles"
  ON public.user_roles FOR INSERT
  WITH CHECK (public.has_role(auth.uid(), 'hr') OR public.has_role(auth.uid(), 'director') OR public.has_role(auth.uid(), 'ceo'));

CREATE POLICY "HR can update roles"
  ON public.user_roles FOR UPDATE
  USING (public.has_role(auth.uid(), 'hr') OR public.has_role(auth.uid(), 'director') OR public.has_role(auth.uid(), 'ceo'));

-- RLS Policies for employees
CREATE POLICY "Users can view their own employee record"
  ON public.employees FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Managers can view their team"
  ON public.employees FOR SELECT
  USING (
    public.has_role(auth.uid(), 'manager') AND 
    reporting_manager_id IN (SELECT id FROM public.employees WHERE user_id = auth.uid())
  );

CREATE POLICY "HR can view all employees"
  ON public.employees FOR SELECT
  USING (public.has_role(auth.uid(), 'hr') OR public.has_role(auth.uid(), 'director') OR public.has_role(auth.uid(), 'ceo'));

CREATE POLICY "HR can insert employees"
  ON public.employees FOR INSERT
  WITH CHECK (public.has_role(auth.uid(), 'hr') OR public.has_role(auth.uid(), 'director') OR public.has_role(auth.uid(), 'ceo'));

CREATE POLICY "HR can update employees"
  ON public.employees FOR UPDATE
  USING (public.has_role(auth.uid(), 'hr') OR public.has_role(auth.uid(), 'director') OR public.has_role(auth.uid(), 'ceo'));

CREATE POLICY "Employees can update their own record"
  ON public.employees FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- RLS Policies for onboarding_data
CREATE POLICY "Users can view their own onboarding data"
  ON public.onboarding_data FOR SELECT
  USING (employee_id IN (SELECT id FROM public.employees WHERE user_id = auth.uid()));

CREATE POLICY "Users can update their own onboarding data"
  ON public.onboarding_data FOR UPDATE
  USING (employee_id IN (SELECT id FROM public.employees WHERE user_id = auth.uid()));

CREATE POLICY "Users can insert their own onboarding data"
  ON public.onboarding_data FOR INSERT
  WITH CHECK (employee_id IN (SELECT id FROM public.employees WHERE user_id = auth.uid()));

CREATE POLICY "HR can view all onboarding data"
  ON public.onboarding_data FOR SELECT
  USING (public.has_role(auth.uid(), 'hr') OR public.has_role(auth.uid(), 'director') OR public.has_role(auth.uid(), 'ceo'));

CREATE POLICY "HR can insert onboarding data"
  ON public.onboarding_data FOR INSERT
  WITH CHECK (public.has_role(auth.uid(), 'hr') OR public.has_role(auth.uid(), 'director') OR public.has_role(auth.uid(), 'ceo'));

-- RLS Policies for leave_policies
CREATE POLICY "Everyone can view active leave policies"
  ON public.leave_policies FOR SELECT
  USING (is_active = true);

CREATE POLICY "HR can manage leave policies"
  ON public.leave_policies FOR ALL
  USING (public.has_role(auth.uid(), 'hr') OR public.has_role(auth.uid(), 'director') OR public.has_role(auth.uid(), 'ceo'));

-- RLS Policies for workflows
CREATE POLICY "Everyone can view active workflows"
  ON public.workflows FOR SELECT
  USING (status = 'active');

CREATE POLICY "HR can manage workflows"
  ON public.workflows FOR ALL
  USING (public.has_role(auth.uid(), 'hr') OR public.has_role(auth.uid(), 'director') OR public.has_role(auth.uid(), 'ceo'));

-- Create trigger function for updated_at
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- Create triggers for updated_at
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_employees_updated_at
  BEFORE UPDATE ON public.employees
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_onboarding_data_updated_at
  BEFORE UPDATE ON public.onboarding_data
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_leave_policies_updated_at
  BEFORE UPDATE ON public.leave_policies
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_workflows_updated_at
  BEFORE UPDATE ON public.workflows
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Create function to handle new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, first_name, last_name)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'first_name',
    NEW.raw_user_meta_data->>'last_name'
  );
  RETURN NEW;
END;
$$;

-- Create trigger for new user
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();