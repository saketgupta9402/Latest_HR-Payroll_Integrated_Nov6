-- Migration: 20251028044119
-- Add tax tables for payroll system

CREATE TABLE IF NOT EXISTS public.tax_configurations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES public.tenants(id) ON DELETE CASCADE NOT NULL,
  financial_year TEXT NOT NULL,
  tax_slabs JSONB NOT NULL,
  cess_rate DECIMAL(5,2) DEFAULT 4.00,
  surcharge_thresholds JSONB DEFAULT '[]'::jsonb,
  created_by UUID REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(tenant_id, financial_year)
);

CREATE TABLE IF NOT EXISTS public.tax_declarations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES public.tenants(id) ON DELETE CASCADE NOT NULL,
  employee_id UUID REFERENCES public.employees(id) ON DELETE CASCADE NOT NULL,
  financial_year TEXT NOT NULL,
  section_80c DECIMAL(12,2) DEFAULT 0,
  section_80d DECIMAL(12,2) DEFAULT 0,
  section_24b DECIMAL(12,2) DEFAULT 0,
  other_deductions DECIMAL(12,2) DEFAULT 0,
  total_deductions DECIMAL(12,2) DEFAULT 0,
  submitted_at TIMESTAMPTZ DEFAULT now(),
  approved_by UUID REFERENCES public.users(id),
  approved_at TIMESTAMPTZ,
  status TEXT DEFAULT 'pending',
  remarks TEXT,
  supporting_documents JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(employee_id, financial_year)
);

CREATE TABLE IF NOT EXISTS public.tax_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES public.tenants(id) ON DELETE CASCADE NOT NULL,
  employee_id UUID REFERENCES public.employees(id) ON DELETE CASCADE NOT NULL,
  document_type TEXT NOT NULL,
  file_name TEXT NOT NULL,
  file_url TEXT NOT NULL,
  uploaded_at TIMESTAMPTZ DEFAULT now(),
  uploaded_by UUID REFERENCES public.users(id),
  metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_tax_declarations_employee ON public.tax_declarations(employee_id);
CREATE INDEX IF NOT EXISTS idx_tax_declarations_tenant ON public.tax_declarations(tenant_id);
CREATE INDEX IF NOT EXISTS idx_tax_documents_employee ON public.tax_documents(employee_id);

ALTER TABLE public.tax_configurations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tax_declarations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tax_documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY tax_configurations_org_policy ON public.tax_configurations
  USING (tenant_id = current_setting('app.org_id')::uuid);

CREATE POLICY tax_declarations_org_policy ON public.tax_declarations
  USING (tenant_id = current_setting('app.org_id')::uuid);

CREATE POLICY tax_documents_org_policy ON public.tax_documents
  USING (tenant_id = current_setting('app.org_id')::uuid);

