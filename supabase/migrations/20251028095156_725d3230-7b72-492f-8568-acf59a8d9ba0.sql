-- Add policy to allow all authenticated users to view employees for org chart
CREATE POLICY "All authenticated users can view employees for org chart"
ON public.employees
FOR SELECT
TO authenticated
USING (true);