-- Migration: 20251030000000
-- Add payroll_pending_approval enum value for payroll status tracking

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

