/**
 * Data Masking Utility
 * 
 * Provides functions to mask sensitive PII data for non-privileged users
 * HR users should see full data, but other roles should see masked data
 */

/**
 * Mask bank account number - show only last 4 digits
 * @param {string} accountNumber - Full bank account number
 * @returns {string} Masked account number (e.g., "...-XX-1234")
 */
export function maskBankAccount(accountNumber) {
  if (!accountNumber || typeof accountNumber !== 'string') {
    return null;
  }
  
  const cleaned = accountNumber.replace(/\D/g, ''); // Remove non-digits
  if (cleaned.length < 4) {
    return '****';
  }
  
  const last4 = cleaned.slice(-4);
  return `...-XX-${last4}`;
}

/**
 * Mask PAN number - show only last 4 characters
 * @param {string} panNumber - Full PAN number
 * @returns {string} Masked PAN (e.g., "XXXXX1234")
 */
export function maskPAN(panNumber) {
  if (!panNumber || typeof panNumber !== 'string') {
    return null;
  }
  
  const cleaned = panNumber.toUpperCase().replace(/\s/g, '');
  if (cleaned.length < 4) {
    return 'XXXX';
  }
  
  const last4 = cleaned.slice(-4);
  return `XXXXX${last4}`;
}

/**
 * Mask Aadhaar number - show only last 4 digits
 * @param {string} aadhaarNumber - Full Aadhaar number
 * @returns {string} Masked Aadhaar (e.g., "XXXX XXXX 1234")
 */
export function maskAadhaar(aadhaarNumber) {
  if (!aadhaarNumber || typeof aadhaarNumber !== 'string') {
    return null;
  }
  
  const cleaned = aadhaarNumber.replace(/\D/g, '');
  if (cleaned.length < 4) {
    return 'XXXX XXXX XXXX';
  }
  
  const last4 = cleaned.slice(-4);
  return `XXXX XXXX ${last4}`;
}

/**
 * Mask salary information - show null or 0 for non-HR users
 * @param {number} salary - Salary amount
 * @param {boolean} isHR - Whether the user is HR
 * @returns {number|null} Salary or null/0 based on role
 */
export function maskSalary(salary, isHR = false) {
  if (isHR) {
    return salary;
  }
  return null; // Or return 0 if preferred
}

/**
 * Mask employee object - applies masking to all sensitive fields
 * @param {Object} employee - Employee object
 * @param {boolean} isHR - Whether the user is HR
 * @returns {Object} Employee object with masked fields
 */
export function maskEmployeeData(employee, isHR = false) {
  if (!employee) {
    return employee;
  }
  
  const masked = { ...employee };
  
  if (!isHR) {
    // Mask sensitive financial data
    masked.bank_account_number = maskBankAccount(employee.bank_account_number);
    masked.bank_ifsc = employee.bank_ifsc ? 'XXXX' : null;
    masked.bank_name = employee.bank_name ? '****' : null;
    masked.pan_number = maskPAN(employee.pan_number);
    masked.aadhaar_number = maskAadhaar(employee.aadhaar_number);
    
    // Mask salary-related fields if present
    if (masked.ctc !== undefined) {
      masked.ctc = null;
    }
    if (masked.basic_salary !== undefined) {
      masked.basic_salary = null;
    }
    if (masked.gross_salary !== undefined) {
      masked.gross_salary = null;
    }
    if (masked.net_salary !== undefined) {
      masked.net_salary = null;
    }
  }
  
  return masked;
}

/**
 * Mask array of employees
 * @param {Array} employees - Array of employee objects
 * @param {boolean} isHR - Whether the user is HR
 * @returns {Array} Array of masked employee objects
 */
export function maskEmployeeList(employees, isHR = false) {
  if (!Array.isArray(employees)) {
    return employees;
  }
  
  return employees.map(emp => maskEmployeeData(emp, isHR));
}

