# Petal HR Suite Refactoring Summary

## Overview
This document summarizes the comprehensive refactoring to unify the database architecture, consolidate services, and implement granular zero-trust security for payroll data.

## ✅ Completed Tasks

### Part 1: Database & Migration Consolidation

1. **Created Payroll Schema Migration** (`server/db/migrations/001_create_payroll_schema.sql`)
   - Creates `payroll` schema in the main `hr_suite` database
   - Migrates all payroll tables to the `payroll` schema
   - Sets up proper indexes and triggers
   - **CRITICAL**: Revokes all permissions from `public` and `postgres` user on payroll schema

2. **Created Security Functions** (`server/db/migrations/002_payroll_security_functions.sql`)
   - `payroll.get_employee_salary_details()` - HR only access to sensitive salary data
   - `payroll.get_payroll_item_details()` - HR only access to payroll items
   - `payroll.get_payroll_aggregates()` - CEO/Director access to aggregate data (NO individual salaries)
   - `payroll.get_own_payslip()` - Employee access to their own payslip only
   - All functions use `SECURITY DEFINER` with `payroll_admin_role` privileges

3. **Updated Docker Compose** (`docker-compose.yml`)
   - Auto-runs migrations in alphanumeric order:
     - `01-full-schema.sql` - Main HR schema
     - `02-payroll-schema-migrations/` - Payroll schema creation
     - `03-payroll-app-migrations/` - Payroll app migrations
     - `04-payroll-integration-migrations/` - Integration migrations
   - Removed `payroll-api`, `payroll-db`, and `payroll-redis` services
   - Updated `payroll-app` to depend on main `api` service

### Part 3: Granular Security & RBAC

1. **Extended Capability System** (`server/policy/authorize.js`)
   - Added granular payroll capabilities:
     - `CAN_VIEW_OWN_PAYSLIP` - Employees can view their own payslips
     - `CAN_VIEW_PAYROLL_AGGREGATES` - CEO/Director can see aggregate data
     - `CAN_VIEW_EMPLOYEE_SENSITIVE_PAYROLL` - HR only, for individual salaries
     - `CAN_MANAGE_PAYROLL_RUNS` - HR only, for managing payroll cycles
   - Updated role mappings:
     - `employee`: Can view own payslip
     - `hr`: Full payroll access (all capabilities)
     - `ceo`: Only aggregate data (NO individual salaries)
     - `director`: Aggregate data for their department

## 🔄 Remaining Tasks

### Part 2: Service Layer Consolidation

**Status**: Partially Complete - Docker services removed, but routes need consolidation

**Required Actions**:

1. **Create Consolidated Payroll Service** (`server/routes/payroll-service.js`)
   - Convert TypeScript routes from `payroll-app/server/src/routes/app.ts` to JavaScript
   - Update all database queries to use `payroll.*` schema
   - Use main database pool (`server/db/pool.js`)
   - Replace direct table access with SECURITY DEFINER function calls:
     - Use `payroll.get_employee_salary_details()` instead of direct SELECT
     - Use `payroll.get_payroll_aggregates()` for CEO/Director endpoints
     - Use `payroll.get_own_payslip()` for employee endpoints

2. **Update Main Server** (`server/index.js`)
   - Mount payroll routes: `app.use('/api/payroll', payrollServiceRoutes)`
   - Ensure routes are protected with `requireCapability` middleware

3. **Update Frontend API Calls**
   - Update `src/lib/api.ts` to point all payroll calls to `http://localhost:3001/api/payroll`
   - Remove references to `http://localhost:4000`

### Part 3: Security Implementation (Remaining)

1. **Protect Payroll Endpoints** (`server/routes/payroll-service.js`)
   - All endpoints must use `requireCapability` middleware
   - Employee endpoints: `requireCapability(CAPABILITIES.CAN_VIEW_OWN_PAYSLIP)`
   - HR endpoints: `requireCapability(CAPABILITIES.CAN_VIEW_EMPLOYEE_SENSITIVE_PAYROLL)`
   - CEO/Director endpoints: `requireCapability(CAPABILITIES.CAN_VIEW_PAYROLL_AGGREGATES)`
   - Management endpoints: `requireCapability(CAPABILITIES.CAN_MANAGE_PAYROLL_RUNS)`

2. **Implement Data Masking**
   - Create utility function `server/utils/dataMasking.js`
   - Mask bank account numbers: Show only last 4 digits (e.g., "...-XX-1234")
   - Mask PAN numbers: Show only last 4 characters
   - Apply masking in all employee list endpoints (NOT in HR-specific endpoints)

3. **Expand Audit Logging** (`server/utils/auditLog.js`)
   - Add payroll-specific audit events:
     - `payroll_salary_viewed` - When HR views employee salary
     - `payroll_aggregate_viewed` - When CEO/Director views aggregates
     - `payroll_payslip_viewed` - When employee views own payslip
     - `payroll_cycle_created` - When payroll cycle is created
     - `payroll_cycle_processed` - When payroll is processed
   - Log details: user_id, employee_id (if applicable), action, timestamp, IP address
   - Store in `payroll.audit_logs` table

## 🔒 Security Model Summary

### Database-Level Security (Defense-in-Depth)
- ✅ Default `postgres` user has NO direct SELECT access to `payroll.*` tables
- ✅ All sensitive data access goes through SECURITY DEFINER functions
- ✅ Functions run with `payroll_admin_role` privileges
- ✅ Functions enforce business rules (e.g., employees can only see own data)

### API-Level Security (RBAC)
- ✅ Granular capabilities defined
- ✅ Role-based capability mapping
- ⏳ Endpoints protected with `requireCapability` (pending route consolidation)
- ⏳ Data masking for PII (pending implementation)
- ⏳ Comprehensive audit logging (pending expansion)

### Access Control Matrix

| Role | Own Payslip | Aggregate Data | Individual Salaries | Manage Payroll |
|------|-------------|----------------|---------------------|----------------|
| Employee | ✅ | ❌ | ❌ | ❌ |
| Manager | ✅ | ❌ | ❌ | ❌ |
| Director | ✅ | ✅ (Dept) | ❌ | ❌ |
| CEO | ✅ | ✅ (Org) | ❌ | ❌ |
| HR | ✅ | ✅ (Org) | ✅ | ✅ |
| Admin | ✅ | ✅ (Org) | ✅ | ✅ |

## 📋 Migration Steps

### 1. Database Migration
```bash
# Start the database (migrations will run automatically)
docker-compose up postgres

# Verify migrations ran successfully
docker-compose exec postgres psql -U postgres -d hr_suite -c "\dn payroll"
docker-compose exec postgres psql -U postgres -d hr_suite -c "\df payroll.*"
```

### 2. Data Migration (if existing payroll data)
```sql
-- If you have existing payroll data in the old database, migrate it:
-- This should be done manually or via a migration script
INSERT INTO payroll.employees SELECT * FROM old_payroll_db.employees;
-- Repeat for other tables...
```

### 3. Service Consolidation
- Complete the `server/routes/payroll-service.js` file
- Update `server/index.js` to mount the routes
- Test all payroll endpoints

### 4. Security Verification
- Test that `postgres` user cannot directly query payroll tables
- Verify SECURITY DEFINER functions work correctly
- Test capability checks on all endpoints
- Verify audit logs are being created

## 🚨 Critical Security Notes

1. **Never grant direct SELECT on payroll tables to the API user**
   - All access must go through SECURITY DEFINER functions
   - This is enforced at the database level

2. **CEO/Director endpoints must ONLY return aggregates**
   - Never return individual employee salaries
   - Use `payroll.get_payroll_aggregates()` function
   - Verify in code review

3. **All payroll access must be audited**
   - Every API call that touches payroll data must log to `payroll.audit_logs`
   - This is a compliance requirement

4. **Data masking is mandatory for employee lists**
   - Bank details, PAN, salary must be masked
   - Only HR-specific endpoints can show full data

## 📝 Next Steps

1. Complete `server/routes/payroll-service.js` with all payroll routes
2. Add `requireCapability` middleware to all endpoints
3. Implement data masking utility and apply to employee lists
4. Expand audit logging for all payroll operations
5. Update frontend API calls to use main API endpoint
6. Test the complete flow end-to-end
7. Update documentation

## 🔍 Testing Checklist

- [ ] Database migrations run successfully
- [ ] Payroll schema created with proper permissions
- [ ] SECURITY DEFINER functions work correctly
- [ ] API endpoints return correct data based on role
- [ ] CEO cannot see individual salaries
- [ ] Employees can only see their own payslips
- [ ] HR can see all payroll data
- [ ] Data masking works for employee lists
- [ ] Audit logs are created for all payroll access
- [ ] Frontend can access payroll through main API

