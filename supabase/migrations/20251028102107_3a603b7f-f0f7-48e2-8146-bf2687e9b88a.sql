-- Create organizations table
CREATE TABLE public.organizations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  domain text UNIQUE NOT NULL,
  company_size text,
  industry text,
  timezone text DEFAULT 'Asia/Kolkata',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;

-- Add tenant_id columns
ALTER TABLE public.employees ADD COLUMN tenant_id uuid REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE public.profiles ADD COLUMN tenant_id uuid REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE public.user_roles ADD COLUMN tenant_id uuid REFERENCES public.organizations(id) ON DELETE CASCADE;

-- Helper function to get user's tenant
CREATE OR REPLACE FUNCTION public.get_user_tenant_id(_user_id uuid)
RETURNS uuid
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path = 'public'
AS $$
  SELECT tenant_id FROM public.profiles WHERE id = _user_id LIMIT 1
$$;

-- Update signup trigger for CEO/org creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  assigned_role app_role;
  org_id uuid;
BEGIN
  -- Check if org signup (has org metadata)
  IF NEW.raw_user_meta_data->>'org_name' IS NOT NULL THEN
    INSERT INTO public.organizations (name, domain, company_size, industry, timezone)
    VALUES (
      NEW.raw_user_meta_data->>'org_name',
      NEW.raw_user_meta_data->>'domain',
      NEW.raw_user_meta_data->>'company_size',
      NEW.raw_user_meta_data->>'industry',
      COALESCE(NEW.raw_user_meta_data->>'timezone', 'Asia/Kolkata')
    )
    RETURNING id INTO org_id;
    assigned_role := 'ceo';
  ELSIF NEW.raw_user_meta_data->>'tenant_id' IS NOT NULL THEN
    -- Employee created by edge function
    org_id := (NEW.raw_user_meta_data->>'tenant_id')::uuid;
    assigned_role := NULL;
  ELSE
    RAISE EXCEPTION 'No organization specified';
  END IF;
  
  INSERT INTO public.profiles (id, email, first_name, last_name, tenant_id)
  VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'first_name', NEW.raw_user_meta_data->>'last_name', org_id);
  
  IF assigned_role IS NOT NULL THEN
    INSERT INTO public.user_roles (user_id, role, tenant_id)
    VALUES (NEW.id, assigned_role, org_id);
  END IF;
  
  RETURN NEW;
END;
$$;

-- RLS for organizations
CREATE POLICY "Users can view their org" ON public.organizations FOR SELECT
USING (id = get_user_tenant_id(auth.uid()));

CREATE POLICY "CEOs can update their org" ON public.organizations FOR UPDATE
USING (id = get_user_tenant_id(auth.uid()) AND has_role(auth.uid(), 'ceo'::app_role));

-- Update employee RLS
DROP POLICY IF EXISTS "Users can view their own employee record" ON public.employees;
DROP POLICY IF EXISTS "All authenticated users can view employees for org chart" ON public.employees;
DROP POLICY IF EXISTS "HR can view all employees" ON public.employees;
DROP POLICY IF EXISTS "Managers can view their team" ON public.employees;
DROP POLICY IF EXISTS "HR can insert employees" ON public.employees;
DROP POLICY IF EXISTS "HR can update employees" ON public.employees;
DROP POLICY IF EXISTS "Employees can update their own record" ON public.employees;

CREATE POLICY "View org employees" ON public.employees FOR SELECT
USING (tenant_id = get_user_tenant_id(auth.uid()));

CREATE POLICY "HR manage org employees" ON public.employees FOR ALL
USING (tenant_id = get_user_tenant_id(auth.uid()) AND 
  (has_role(auth.uid(), 'hr'::app_role) OR has_role(auth.uid(), 'director'::app_role) OR has_role(auth.uid(), 'ceo'::app_role)));

-- Update profile RLS
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "HR can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;

CREATE POLICY "View org profiles" ON public.profiles FOR SELECT
USING (tenant_id = get_user_tenant_id(auth.uid()));

CREATE POLICY "Update own profile" ON public.profiles FOR UPDATE
USING (auth.uid() = id);

-- Update user_roles RLS
DROP POLICY IF EXISTS "Users can view their own roles" ON public.user_roles;
DROP POLICY IF EXISTS "HR can view all roles" ON public.user_roles;
DROP POLICY IF EXISTS "HR can insert roles" ON public.user_roles;
DROP POLICY IF EXISTS "HR can update roles" ON public.user_roles;

CREATE POLICY "View org roles" ON public.user_roles FOR SELECT
USING (tenant_id = get_user_tenant_id(auth.uid()));

CREATE POLICY "HR manage org roles" ON public.user_roles FOR ALL
USING (tenant_id = get_user_tenant_id(auth.uid()) AND 
  (has_role(auth.uid(), 'hr'::app_role) OR has_role(auth.uid(), 'director'::app_role) OR has_role(auth.uid(), 'ceo'::app_role)));