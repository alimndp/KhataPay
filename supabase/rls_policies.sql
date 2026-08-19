-- ============================================================
-- KhataPay - Row Level Security (RLS) Policies
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.salary_advancements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.salary_disbursements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.disbursement_approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.approval_workflows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- Helper function: Get current user's role
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_current_user_role()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT role FROM public.profiles WHERE id = auth.uid()
$$;

-- Helper function: Check if user is business owner
CREATE OR REPLACE FUNCTION public.is_business_owner()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'business_owner'
    )
$$;

-- Helper function: Check if user is finance/HR
CREATE OR REPLACE FUNCTION public.is_finance_or_hr()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role IN ('finance', 'hr')
    )
$$;

-- ============================================================
-- PROFILES
-- ============================================================

-- Users can view their own profile
CREATE POLICY "Users can view own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

-- Business owner can view all profiles
CREATE POLICY "Owner can view all profiles"
    ON public.profiles FOR SELECT
    USING (public.is_business_owner());

-- Business owner can insert profiles
CREATE POLICY "Owner can insert profiles"
    ON public.profiles FOR INSERT
    WITH CHECK (public.is_business_owner());

-- ============================================================
-- EMPLOYEES
-- ============================================================

-- Employees can view their own record
CREATE POLICY "Employees can view own record"
    ON public.employees FOR SELECT
    USING (profile_id = auth.uid());

-- Owner/HR/Finance can view all employees
CREATE POLICY "Staff can view all employees"
    ON public.employees FOR SELECT
    USING (public.is_business_owner() OR public.is_finance_or_hr());

-- Owner/HR can insert employees
CREATE POLICY "Staff can insert employees"
    ON public.employees FOR INSERT
    WITH CHECK (public.is_business_owner() OR public.is_finance_or_hr());

-- Owner/HR can update employees
CREATE POLICY "Staff can update employees"
    ON public.employees FOR UPDATE
    USING (public.is_business_owner() OR public.is_finance_or_hr());

-- Owner can delete employees
CREATE POLICY "Owner can delete employees"
    ON public.employees FOR DELETE
    USING (public.is_business_owner());

-- ============================================================
-- ATTENDANCE LOGS
-- ============================================================

-- Employees can view their own attendance
CREATE POLICY "Employees can view own attendance"
    ON public.attendance_logs FOR SELECT
    USING (
        employee_id IN (
            SELECT id FROM public.employees WHERE profile_id = auth.uid()
        )
    );

-- Owner/HR can view all attendance
CREATE POLICY "Staff can view all attendance"
    ON public.attendance_logs FOR SELECT
    USING (public.is_business_owner() OR public.is_finance_or_hr());

-- Employees can insert their own attendance (check-in)
CREATE POLICY "Employees can insert own attendance"
    ON public.attendance_logs FOR INSERT
    WITH CHECK (
        employee_id IN (
            SELECT id FROM public.employees WHERE profile_id = auth.uid()
        )
    );

-- Owner/HR can insert attendance for any employee
CREATE POLICY "Staff can insert attendance"
    ON public.attendance_logs FOR INSERT
    WITH CHECK (public.is_business_owner() OR public.is_finance_or_hr());

-- Owner/HR can update attendance
CREATE POLICY "Staff can update attendance"
    ON public.attendance_logs FOR UPDATE
    USING (public.is_business_owner() OR public.is_finance_or_hr());

-- ============================================================
-- SALARY ADVANCEMENTS
-- ============================================================

-- Employees can view their own advancements
CREATE POLICY "Employees can view own advancements"
    ON public.salary_advancements FOR SELECT
    USING (
        employee_id IN (
            SELECT id FROM public.employees WHERE profile_id = auth.uid()
        )
    );

-- Owner/HR/Finance can view all advancements
CREATE POLICY "Staff can view all advancements"
    ON public.salary_advancements FOR SELECT
    USING (public.is_business_owner() OR public.is_finance_or_hr());

-- Employees can request advancements
CREATE POLICY "Employees can request advancements"
    ON public.salary_advancements FOR INSERT
    WITH CHECK (
        employee_id IN (
            SELECT id FROM public.employees WHERE profile_id = auth.uid()
        )
    );

-- Owner can approve/reject advancements
CREATE POLICY "Owner can update advancements"
    ON public.salary_advancements FOR UPDATE
    USING (public.is_business_owner());

-- ============================================================
-- SALARY DISBURSEMENTS
-- ============================================================

-- Employees can view their own disbursements
CREATE POLICY "Employees can view own disbursements"
    ON public.salary_disbursements FOR SELECT
    USING (
        employee_id IN (
            SELECT id FROM public.employees WHERE profile_id = auth.uid()
        )
    );

-- Owner/Finance/HR can view all disbursements
CREATE POLICY "Staff can view all disbursements"
    ON public.salary_disbursements FOR SELECT
    USING (public.is_business_owner() OR public.is_finance_or_hr());

-- HR/Finance can create disbursements
CREATE POLICY "Staff can create disbursements"
    ON public.salary_disbursements FOR INSERT
    WITH CHECK (public.is_business_owner() OR public.is_finance_or_hr());

-- Owner can approve/reject disbursements
CREATE POLICY "Owner can update disbursements"
    ON public.salary_disbursements FOR UPDATE
    USING (public.is_business_owner());

-- Finance can update payment status
CREATE POLICY "Finance can update payment status"
    ON public.salary_disbursements FOR UPDATE
    USING (public.is_finance_or_hr());

-- ============================================================
-- DISBURSEMENT APPROVALS
-- ============================================================

-- Approvers can view their assigned steps
CREATE POLICY "Approvers can view assigned steps"
    ON public.disbursement_approvals FOR SELECT
    USING (approver_id = auth.uid() OR public.is_business_owner());

-- Owner can act on approvals
CREATE POLICY "Owner can act on approvals"
    ON public.disbursement_approvals FOR UPDATE
    USING (public.is_business_owner());

-- System creates approval steps (via trigger, security definer)
CREATE POLICY "System can create approvals"
    ON public.disbursement_approvals FOR INSERT
    WITH CHECK (public.is_business_owner() OR public.is_finance_or_hr());

-- ============================================================
-- APPROVAL WORKFLOWS
-- ============================================================

-- All authenticated users can view active workflows
CREATE POLICY "Users can view active workflows"
    ON public.approval_workflows FOR SELECT
    USING (is_active = true);

-- Only owner can manage workflows
CREATE POLICY "Owner can manage workflows"
    ON public.approval_workflows FOR ALL
    USING (public.is_business_owner())
    WITH CHECK (public.is_business_owner());

-- ============================================================
-- PAYMENT METHODS
-- ============================================================

-- Employees can view their own payment methods
CREATE POLICY "Employees can view own payment methods"
    ON public.payment_methods FOR SELECT
    USING (
        employee_id IN (
            SELECT id FROM public.employees WHERE profile_id = auth.uid()
        )
    );

-- Owner can view all payment methods
CREATE POLICY "Owner can view all payment methods"
    ON public.payment_methods FOR SELECT
    USING (public.is_business_owner());

-- Employees can manage their own payment methods
CREATE POLICY "Employees can manage own payment methods"
    ON public.payment_methods FOR ALL
    USING (
        employee_id IN (
            SELECT id FROM public.employees WHERE profile_id = auth.uid()
        )
    )
    WITH CHECK (
        employee_id IN (
            SELECT id FROM public.employees WHERE profile_id = auth.uid()
        )
    );

-- ============================================================
-- CATEGORIES
-- ============================================================

-- All authenticated users can view categories
CREATE POLICY "Users can view categories"
    ON public.categories FOR SELECT
    USING (true);

-- Owner can manage categories
CREATE POLICY "Owner can manage categories"
    ON public.categories FOR ALL
    USING (public.is_business_owner())
    WITH CHECK (public.is_business_owner());

-- ============================================================
-- ACCOUNTS
-- ============================================================

-- Owner can view accounts
CREATE POLICY "Owner can view accounts"
    ON public.accounts FOR SELECT
    USING (public.is_business_owner());

-- Owner can manage accounts
CREATE POLICY "Owner can manage accounts"
    ON public.accounts FOR ALL
    USING (public.is_business_owner())
    WITH CHECK (public.is_business_owner());

-- ============================================================
-- TRANSACTIONS
-- ============================================================

-- Owner can view all transactions
CREATE POLICY "Owner can view all transactions"
    ON public.transactions FOR SELECT
    USING (public.is_business_owner());

-- Finance can view all transactions
CREATE POLICY "Finance can view all transactions"
    ON public.transactions FOR SELECT
    USING (public.is_finance_or_hr());

-- Owner can create transactions
CREATE POLICY "Owner can create transactions"
    ON public.transactions FOR INSERT
    WITH CHECK (public.is_business_owner());

-- Owner can update transactions
CREATE POLICY "Owner can update transactions"
    ON public.transactions FOR UPDATE
    USING (public.is_business_owner());

-- Owner can delete transactions
CREATE POLICY "Owner can delete transactions"
    ON public.transactions FOR DELETE
    USING (public.is_business_owner());

-- ============================================================
-- INVOICES
-- ============================================================

-- Owner can view all invoices
CREATE POLICY "Owner can view all invoices"
    ON public.invoices FOR SELECT
    USING (public.is_business_owner());

-- Owner can manage invoices
CREATE POLICY "Owner can manage invoices"
    ON public.invoices FOR ALL
    USING (public.is_business_owner())
    WITH CHECK (public.is_business_owner());

-- ============================================================
-- AUDIT LOGS
-- ============================================================

-- Only owner can view audit logs
CREATE POLICY "Owner can view audit logs"
    ON public.audit_logs FOR SELECT
    USING (public.is_business_owner());

-- System can insert audit logs (via trigger, security definer)
CREATE POLICY "System can insert audit logs"
    ON public.audit_logs FOR INSERT
    WITH CHECK (true);