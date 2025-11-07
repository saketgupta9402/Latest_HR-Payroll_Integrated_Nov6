-- Migration: 20251030000001
-- Ensure pending_approval exists on payroll_status enum (idempotent duplicate safeguard)

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_type t
    JOIN pg_enum e ON t.oid = e.enumtypid
    WHERE t.typname = 'payroll_status' AND e.enumlabel = 'pending_approval'
  ) THEN
    ALTER TYPE public.payroll_status ADD VALUE 'pending_approval';
  END IF;
END $$;

