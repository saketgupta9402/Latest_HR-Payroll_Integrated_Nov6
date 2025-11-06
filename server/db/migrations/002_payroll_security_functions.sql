-- Migration: Create SECURITY DEFINER Functions for Payroll Data Access
-- These functions allow controlled access to sensitive payroll data
-- They run with payroll_admin_role privileges, bypassing normal permissions

-- Function to get employee salary details (HR only)
CREATE OR REPLACE FUNCTION payroll.get_employee_salary_details(
  p_employee_id UUID,
  p_tenant_id UUID
)
RETURNS TABLE (
  employee_id UUID,
  employee_code TEXT,
  full_name TEXT,
  email TEXT,
  basic_salary DECIMAL(12,2),
  hra DECIMAL(12,2),
  special_allowance DECIMAL(12,2),
  gross_salary DECIMAL(12,2),
  deductions DECIMAL(12,2),
  net_salary DECIMAL(12,2),
  bank_account_number TEXT,
  bank_ifsc TEXT,
  bank_name TEXT,
  pan_number TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = payroll, public
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    e.id,
    e.employee_code,
    e.full_name,
    e.email,
    cs.basic_salary,
    cs.hra,
    cs.special_allowance,
    (cs.basic_salary + cs.hra + cs.special_allowance)::DECIMAL(12,2) as gross_salary,
    (cs.pf_contribution + cs.esi_contribution)::DECIMAL(12,2) as deductions,
    (cs.basic_salary + cs.hra + cs.special_allowance - cs.pf_contribution - cs.esi_contribution)::DECIMAL(12,2) as net_salary,
    e.bank_account_number,
    e.bank_ifsc,
    e.bank_name,
    e.pan_number
  FROM payroll.employees e
  LEFT JOIN payroll.compensation_structures cs ON cs.employee_id = e.id 
    AND cs.effective_from <= CURRENT_DATE
    AND NOT EXISTS (
      SELECT 1 FROM payroll.compensation_structures cs2
      WHERE cs2.employee_id = e.id
        AND cs2.effective_from > cs.effective_from
        AND cs2.effective_from <= CURRENT_DATE
    )
  WHERE e.id = p_employee_id
    AND e.tenant_id = p_tenant_id;
END;
$$;

-- Function to get payroll item details (HR only)
CREATE OR REPLACE FUNCTION payroll.get_payroll_item_details(
  p_payroll_item_id UUID,
  p_tenant_id UUID
)
RETURNS TABLE (
  id UUID,
  employee_id UUID,
  employee_code TEXT,
  full_name TEXT,
  gross_salary DECIMAL(12,2),
  basic_salary DECIMAL(12,2),
  hra DECIMAL(12,2),
  special_allowance DECIMAL(12,2),
  pf_deduction DECIMAL(12,2),
  esi_deduction DECIMAL(12,2),
  tds_deduction DECIMAL(12,2),
  pt_deduction DECIMAL(12,2),
  deductions DECIMAL(12,2),
  net_salary DECIMAL(12,2),
  bank_account_number TEXT,
  bank_ifsc TEXT,
  bank_name TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = payroll, public
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    pi.id,
    pi.employee_id,
    e.employee_code,
    e.full_name,
    pi.gross_salary,
    pi.basic_salary,
    pi.hra,
    pi.special_allowance,
    pi.pf_deduction,
    pi.esi_deduction,
    pi.tds_deduction,
    pi.pt_deduction,
    pi.deductions,
    pi.net_salary,
    e.bank_account_number,
    e.bank_ifsc,
    e.bank_name
  FROM payroll.payroll_items pi
  JOIN payroll.employees e ON e.id = pi.employee_id
  WHERE pi.id = p_payroll_item_id
    AND pi.tenant_id = p_tenant_id;
END;
$$;

-- Function to get payroll aggregates (CEO/Director - no individual salaries)
CREATE OR REPLACE FUNCTION payroll.get_payroll_aggregates(
  p_tenant_id UUID,
  p_month INTEGER DEFAULT NULL,
  p_year INTEGER DEFAULT NULL
)
RETURNS TABLE (
  total_employees INTEGER,
  total_payroll_cost DECIMAL(15,2),
  average_salary DECIMAL(12,2),
  department TEXT,
  department_count INTEGER,
  department_total DECIMAL(15,2),
  department_avg DECIMAL(12,2)
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = payroll, public
AS $$
BEGIN
  -- Overall aggregates
  IF p_month IS NULL OR p_year IS NULL THEN
    RETURN QUERY
    SELECT 
      COUNT(DISTINCT e.id)::INTEGER as total_employees,
      COALESCE(SUM(cs.ctc), 0)::DECIMAL(15,2) as total_payroll_cost,
      COALESCE(AVG(cs.ctc), 0)::DECIMAL(12,2) as average_salary,
      NULL::TEXT as department,
      NULL::INTEGER as department_count,
      NULL::DECIMAL(15,2) as department_total,
      NULL::DECIMAL(12,2) as department_avg
    FROM payroll.employees e
    LEFT JOIN payroll.compensation_structures cs ON cs.employee_id = e.id
      AND cs.effective_from <= CURRENT_DATE
      AND NOT EXISTS (
        SELECT 1 FROM payroll.compensation_structures cs2
        WHERE cs2.employee_id = e.id
          AND cs2.effective_from > cs.effective_from
          AND cs2.effective_from <= CURRENT_DATE
      )
    WHERE e.tenant_id = p_tenant_id
      AND e.status = 'active';
  ELSE
    -- Cycle-specific aggregates
    RETURN QUERY
    SELECT 
      COUNT(DISTINCT pi.employee_id)::INTEGER as total_employees,
      COALESCE(SUM(pi.net_salary), 0)::DECIMAL(15,2) as total_payroll_cost,
      COALESCE(AVG(pi.net_salary), 0)::DECIMAL(12,2) as average_salary,
      NULL::TEXT as department,
      NULL::INTEGER as department_count,
      NULL::DECIMAL(15,2) as department_total,
      NULL::DECIMAL(12,2) as department_avg
    FROM payroll.payroll_items pi
    JOIN payroll.payroll_cycles pc ON pc.id = pi.payroll_cycle_id
    WHERE pi.tenant_id = p_tenant_id
      AND pc.month = p_month
      AND pc.year = p_year;
  END IF;
  
  -- Department-wise aggregates (if needed)
  RETURN QUERY
  SELECT 
    NULL::INTEGER as total_employees,
    NULL::DECIMAL(15,2) as total_payroll_cost,
    NULL::DECIMAL(12,2) as average_salary,
    e.department,
    COUNT(DISTINCT e.id)::INTEGER as department_count,
    COALESCE(SUM(cs.ctc), 0)::DECIMAL(15,2) as department_total,
    COALESCE(AVG(cs.ctc), 0)::DECIMAL(12,2) as department_avg
  FROM payroll.employees e
  LEFT JOIN payroll.compensation_structures cs ON cs.employee_id = e.id
    AND cs.effective_from <= CURRENT_DATE
    AND NOT EXISTS (
      SELECT 1 FROM payroll.compensation_structures cs2
      WHERE cs2.employee_id = e.id
        AND cs2.effective_from > cs.effective_from
        AND cs2.effective_from <= CURRENT_DATE
    )
  WHERE e.tenant_id = p_tenant_id
    AND e.status = 'active'
    AND e.department IS NOT NULL
  GROUP BY e.department;
END;
$$;

-- Function to get own payslip (Employee - only their own data)
CREATE OR REPLACE FUNCTION payroll.get_own_payslip(
  p_employee_id UUID,
  p_payroll_cycle_id UUID,
  p_user_email TEXT
)
RETURNS TABLE (
  id UUID,
  employee_id UUID,
  employee_code TEXT,
  full_name TEXT,
  gross_salary DECIMAL(12,2),
  basic_salary DECIMAL(12,2),
  hra DECIMAL(12,2),
  special_allowance DECIMAL(12,2),
  pf_deduction DECIMAL(12,2),
  esi_deduction DECIMAL(12,2),
  tds_deduction DECIMAL(12,2),
  pt_deduction DECIMAL(12,2),
  deductions DECIMAL(12,2),
  net_salary DECIMAL(12,2),
  lop_days DECIMAL(5,2),
  paid_days DECIMAL(5,2),
  total_working_days DECIMAL(5,2),
  month INTEGER,
  year INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = payroll, public
AS $$
BEGIN
  -- Verify the employee_id matches the user's email
  IF NOT EXISTS (
    SELECT 1 FROM payroll.employees e
    WHERE e.id = p_employee_id
      AND e.email = p_user_email
  ) THEN
    RAISE EXCEPTION 'Access denied: You can only view your own payslip';
  END IF;
  
  RETURN QUERY
  SELECT 
    pi.id,
    pi.employee_id,
    e.employee_code,
    e.full_name,
    pi.gross_salary,
    pi.basic_salary,
    pi.hra,
    pi.special_allowance,
    pi.pf_deduction,
    pi.esi_deduction,
    pi.tds_deduction,
    pi.pt_deduction,
    pi.deductions,
    pi.net_salary,
    pi.lop_days,
    pi.paid_days,
    pi.total_working_days,
    pc.month,
    pc.year
  FROM payroll.payroll_items pi
  JOIN payroll.employees e ON e.id = pi.employee_id
  JOIN payroll.payroll_cycles pc ON pc.id = pi.payroll_cycle_id
  WHERE pi.employee_id = p_employee_id
    AND pi.payroll_cycle_id = p_payroll_cycle_id;
END;
$$;

-- Grant execute permissions to postgres (the API user)
-- The functions themselves run with payroll_admin_role privileges
GRANT EXECUTE ON FUNCTION payroll.get_employee_salary_details(UUID, UUID) TO postgres;
GRANT EXECUTE ON FUNCTION payroll.get_payroll_item_details(UUID, UUID) TO postgres;
GRANT EXECUTE ON FUNCTION payroll.get_payroll_aggregates(UUID, INTEGER, INTEGER) TO postgres;
GRANT EXECUTE ON FUNCTION payroll.get_own_payslip(UUID, UUID, TEXT) TO postgres;

-- Grant payroll_admin_role the ability to use these functions
GRANT EXECUTE ON FUNCTION payroll.get_employee_salary_details(UUID, UUID) TO payroll_admin_role;
GRANT EXECUTE ON FUNCTION payroll.get_payroll_item_details(UUID, UUID) TO payroll_admin_role;
GRANT EXECUTE ON FUNCTION payroll.get_payroll_aggregates(UUID, INTEGER, INTEGER) TO payroll_admin_role;
GRANT EXECUTE ON FUNCTION payroll.get_own_payslip(UUID, UUID, TEXT) TO payroll_admin_role;

