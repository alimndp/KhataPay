-- ============================================================
-- KhataPay - Database Functions & Triggers
-- ============================================================

-- ============================================================
-- 1. TRIGGER: Auto-create approval step on disbursement creation
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_disbursement()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_workflow RECORD;
    v_step JSONB;
    v_owner_id UUID;
BEGIN
    -- Get active workflow
    SELECT * INTO v_workflow
    FROM public.approval_workflows
    WHERE is_active = true
    ORDER BY created_at DESC
    LIMIT 1;

    -- If no workflow configured, use default single-step owner approval
    IF v_workflow.id IS NULL THEN
        -- Find business owner
        SELECT id INTO v_owner_id
        FROM public.profiles
        WHERE role = 'business_owner'
        LIMIT 1;

        INSERT INTO public.disbursement_approvals (
            disbursement_id, approver_id, approver_role, sequence, status
        ) VALUES (
            NEW.id, v_owner_id, 'business_owner', 1, 'pending'
        );
    ELSE
        -- Create approval steps from workflow config
        FOR v_step IN SELECT * FROM jsonb_array_elements(v_workflow.steps)
        LOOP
            INSERT INTO public.disbursement_approvals (
                disbursement_id,
                approver_id,
                approver_role,
                sequence,
                status
            ) VALUES (
                NEW.id,
                NULL, -- approver assigned at runtime
                v_step->>'role',
                (v_step->>'sequence')::INTEGER,
                'pending'
            );
        END LOOP;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_new_disbursement_approval
    AFTER INSERT ON public.salary_disbursements
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_disbursement();

-- ============================================================
-- 2. TRIGGER: Update disbursement status on approval action
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_approval_action()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NEW.status = 'approved' THEN
        -- Update disbursement status to approved
        UPDATE public.salary_disbursements
        SET status = 'approved',
            approved_by = NEW.approver_id,
            approved_at = now(),
            updated_at = now()
        WHERE id = NEW.disbursement_id
          AND status = 'pending_approval';

    ELSIF NEW.status = 'rejected' THEN
        -- Update disbursement status to rejected
        UPDATE public.salary_disbursements
        SET status = 'rejected',
            approved_by = NEW.approver_id,
            approved_at = now(),
            updated_at = now()
        WHERE id = NEW.disbursement_id
          AND status = 'pending_approval';
    END IF;

    NEW.action_at := now();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_approval_action
    BEFORE UPDATE OF status ON public.disbursement_approvals
    FOR EACH ROW
    WHEN (OLD.status = 'pending' AND NEW.status IN ('approved', 'rejected'))
    EXECUTE FUNCTION public.handle_approval_action();

-- ============================================================
-- 3. TRIGGER: Auto-create expense when salary is paid
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_salary_paid()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_salary_category_id UUID;
    v_default_account_id UUID;
    v_employee_name TEXT;
BEGIN
    -- Only act when status changes to 'paid'
    IF NEW.status = 'paid' AND OLD.status <> 'paid' THEN

        -- Get or create 'Salary' expense category
        SELECT id INTO v_salary_category_id
        FROM public.categories
        WHERE name = 'Salary' AND type = 'expense'
        LIMIT 1;

        IF v_salary_category_id IS NULL THEN
            INSERT INTO public.categories (name, type, is_default)
            VALUES ('Salary', 'expense', true)
            RETURNING id INTO v_salary_category_id;
        END IF;

        -- Get default account (first active account)
        SELECT id INTO v_default_account_id
        FROM public.accounts
        WHERE is_active = true
        ORDER BY created_at
        LIMIT 1;

        -- Get employee name
        SELECT CONCAT(first_name, ' ', last_name) INTO v_employee_name
        FROM public.employees
        WHERE id = NEW.employee_id;

        -- Create expense transaction
        INSERT INTO public.transactions (
            type,
            category_id,
            account_id,
            amount,
            currency,
            description,
            transaction_date,
            payment_method,
            reference,
            linked_disbursement_id,
            created_by
        ) VALUES (
            'expense',
            v_salary_category_id,
            v_default_account_id,
            NEW.amount,
            NEW.currency,
            'Salary payment - ' || COALESCE(v_employee_name, 'Employee') || ' (' || TO_CHAR(NEW.period_month, 'YYYY-MM') || ')',
            NEW.period_month,
            'upi',
            NEW.payment_reference,
            NEW.id,
            NEW.approved_by
        );

        -- Update account balance (decrease for expense)
        IF v_default_account_id IS NOT NULL THEN
            UPDATE public.accounts
            SET current_balance = current_balance - NEW.amount,
                updated_at = now()
            WHERE id = v_default_account_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_salary_paid_expense
    AFTER UPDATE OF status ON public.salary_disbursements
    FOR EACH ROW
    WHEN (NEW.status = 'paid')
    EXECUTE FUNCTION public.handle_salary_paid();

-- ============================================================
-- 4. TRIGGER: Update account balance on transaction changes
-- ============================================================
CREATE OR REPLACE FUNCTION public.update_account_balance()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Handle INSERT
    IF TG_OP = 'INSERT' THEN
        IF NEW.account_id IS NOT NULL THEN
            IF NEW.type = 'income' THEN
                UPDATE public.accounts
                SET current_balance = current_balance + NEW.amount,
                    updated_at = now()
                WHERE id = NEW.account_id;
            ELSIF NEW.type = 'expense' THEN
                UPDATE public.accounts
                SET current_balance = current_balance - NEW.amount,
                    updated_at = now()
                WHERE id = NEW.account_id;
            END IF;
        END IF;
        RETURN NEW;
    END IF;

    -- Handle UPDATE
    IF TG_OP = 'UPDATE' THEN
        -- Revert old account effect
        IF OLD.account_id IS NOT NULL THEN
            IF OLD.type = 'income' THEN
                UPDATE public.accounts
                SET current_balance = current_balance - OLD.amount,
                    updated_at = now()
                WHERE id = OLD.account_id;
            ELSIF OLD.type = 'expense' THEN
                UPDATE public.accounts
                SET current_balance = current_balance + OLD.amount,
                    updated_at = now()
                WHERE id = OLD.account_id;
            END IF;
        END IF;

        -- Apply new account effect
        IF NEW.account_id IS NOT NULL THEN
            IF NEW.type = 'income' THEN
                UPDATE public.accounts
                SET current_balance = current_balance + NEW.amount,
                    updated_at = now()
                WHERE id = NEW.account_id;
            ELSIF NEW.type = 'expense' THEN
                UPDATE public.accounts
                SET current_balance = current_balance - NEW.amount,
                    updated_at = now()
                WHERE id = NEW.account_id;
            END IF;
        END IF;
        RETURN NEW;
    END IF;

    -- Handle DELETE
    IF TG_OP = 'DELETE' THEN
        IF OLD.account_id IS NOT NULL THEN
            IF OLD.type = 'income' THEN
                UPDATE public.accounts
                SET current_balance = current_balance - OLD.amount,
                    updated_at = now()
                WHERE id = OLD.account_id;
            ELSIF OLD.type = 'expense' THEN
                UPDATE public.accounts
                SET current_balance = current_balance + OLD.amount,
                    updated_at = now()
                WHERE id = OLD.account_id;
            END IF;
        END IF;
        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$;

CREATE TRIGGER trg_transaction_balance
    AFTER INSERT OR UPDATE OR DELETE ON public.transactions
    FOR EACH ROW
    EXECUTE FUNCTION public.update_account_balance();

-- ============================================================
-- 5. TRIGGER: Auto-update profile on auth user creation
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, email, role)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'role', 'employee')
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- 6. TRIGGER: Audit logging for critical tables
-- ============================================================
CREATE OR REPLACE FUNCTION public.log_audit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO public.audit_logs (table_name, record_id, action, new_data, performed_by)
        VALUES (TG_TABLE_NAME, NEW.id, 'INSERT', to_jsonb(NEW), auth.uid());
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO public.audit_logs (table_name, record_id, action, old_data, new_data, performed_by)
        VALUES (TG_TABLE_NAME, NEW.id, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW), auth.uid());
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO public.audit_logs (table_name, record_id, action, old_data, performed_by)
        VALUES (TG_TABLE_NAME, OLD.id, 'DELETE', to_jsonb(OLD), auth.uid());
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;

-- Audit triggers on critical tables
CREATE TRIGGER trg_audit_salary_disbursements
    AFTER INSERT OR UPDATE OR DELETE ON public.salary_disbursements
    FOR EACH ROW EXECUTE FUNCTION public.log_audit();

CREATE TRIGGER trg_audit_transactions
    AFTER INSERT OR UPDATE OR DELETE ON public.transactions
    FOR EACH ROW EXECUTE FUNCTION public.log_audit();

CREATE TRIGGER trg_audit_employees
    AFTER INSERT OR UPDATE OR DELETE ON public.employees
    FOR EACH ROW EXECUTE FUNCTION public.log_audit();

CREATE TRIGGER trg_audit_invoices
    AFTER INSERT OR UPDATE OR DELETE ON public.invoices
    FOR EACH ROW EXECUTE FUNCTION public.log_audit();

-- ============================================================
-- 7. FUNCTION: Generate UPI payment link
-- ============================================================
CREATE OR REPLACE FUNCTION public.generate_upi_link(
    p_disbursement_id UUID
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_upi_id TEXT;
    v_name TEXT;
    v_amount NUMERIC;
    v_employee_id UUID;
    v_currency TEXT;
    v_note TEXT;
BEGIN
    -- Get disbursement details
    SELECT employee_id, amount, currency
    INTO v_employee_id, v_amount, v_currency
    FROM public.salary_disbursements
    WHERE id = p_disbursement_id;

    -- Get employee's default UPI ID
    SELECT upi_id INTO v_upi_id
    FROM public.payment_methods
    WHERE employee_id = v_employee_id AND is_default = true AND is_active = true
    LIMIT 1;

    IF v_upi_id IS NULL THEN
        SELECT upi_id INTO v_upi_id
        FROM public.payment_methods
        WHERE employee_id = v_employee_id AND is_active = true
        LIMIT 1;
    END IF;

    IF v_upi_id IS NULL THEN
        RAISE EXCEPTION 'No UPI ID found for employee';
    END IF;

    -- Get employee name
    SELECT CONCAT(first_name, ' ', last_name) INTO v_name
    FROM public.employees
    WHERE id = v_employee_id;

    v_note := 'Salary payment for ' || v_name;

    -- Build UPI link
    RETURN 'upi://pay?pa=' || v_upi_id ||
           '&pn=' || REPLACE(v_name, ' ', '%20') ||
           '&tn=' || REPLACE(v_note, ' ', '%20') ||
           '&am=' || v_amount::TEXT ||
           '&cu=' || v_currency;
END;
$$;

-- ============================================================
-- 8. FUNCTION: Mark disbursement as paid
-- ============================================================
CREATE OR REPLACE FUNCTION public.mark_disbursement_paid(
    p_disbursement_id UUID,
    p_payment_reference TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    UPDATE public.salary_disbursements
    SET status = 'paid',
        payment_status = 'success',
        payment_reference = COALESCE(p_payment_reference, payment_reference),
        payment_initiated_at = now(),
        updated_at = now()
    WHERE id = p_disbursement_id
      AND status = 'approved';
END;
$$;

-- ============================================================
-- 9. FUNCTION: Mark disbursement payment as failed
-- ============================================================
CREATE OR REPLACE FUNCTION public.mark_disbursement_failed(
    p_disbursement_id UUID,
    p_error TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    UPDATE public.salary_disbursements
    SET status = 'failed',
        payment_status = 'failed',
        notes = COALESCE(p_error, notes),
        updated_at = now()
    WHERE id = p_disbursement_id
      AND status = 'approved';
END;
$$;

-- ============================================================
-- 10. FUNCTION: Get Profit & Loss Report
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_profit_loss_report(
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    total_income NUMERIC,
    total_expense NUMERIC,
    net_profit NUMERIC,
    income_by_category JSONB,
    expense_by_category JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_total_income NUMERIC := 0;
    v_total_expense NUMERIC := 0;
    v_income_categories JSONB;
    v_expense_categories JSONB;
BEGIN
    -- Total income
    SELECT COALESCE(SUM(amount), 0) INTO v_total_income
    FROM public.transactions
    WHERE type = 'income'
      AND transaction_date BETWEEN p_start_date AND p_end_date;

    -- Total expense
    SELECT COALESCE(SUM(amount), 0) INTO v_total_expense
    FROM public.transactions
    WHERE type = 'expense'
      AND transaction_date BETWEEN p_start_date AND p_end_date;

    -- Income by category
    SELECT COALESCE(
        jsonb_agg(jsonb_build_object(
            'category', c.name,
            'amount', t.total
        )), '[]'::jsonb
    ) INTO v_income_categories
    FROM (
        SELECT category_id, SUM(amount) as total
        FROM public.transactions
        WHERE type = 'income'
          AND transaction_date BETWEEN p_start_date AND p_end_date
        GROUP BY category_id
    ) t
    LEFT JOIN public.categories c ON c.id = t.category_id;

    -- Expense by category
    SELECT COALESCE(
        jsonb_agg(jsonb_build_object(
            'category', c.name,
            'amount', t.total
        )), '[]'::jsonb
    ) INTO v_expense_categories
    FROM (
        SELECT category_id, SUM(amount) as total
        FROM public.transactions
        WHERE type = 'expense'
          AND transaction_date BETWEEN p_start_date AND p_end_date
        GROUP BY category_id
    ) t
    LEFT JOIN public.categories c ON c.id = t.category_id;

    RETURN QUERY
    SELECT
        v_total_income,
        v_total_expense,
        v_total_income - v_total_expense,
        v_income_categories,
        v_expense_categories;
END;
$$;

-- ============================================================
-- 11. FUNCTION: Get Cash Flow Report
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_cash_flow_report(
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    month TEXT,
    income NUMERIC,
    expense NUMERIC,
    net NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        TO_CHAR(transaction_date, 'YYYY-MM') AS month,
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount END), 0) AS income,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount END), 0) AS expense,
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount END), 0) -
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount END), 0) AS net
    FROM public.transactions
    WHERE transaction_date BETWEEN p_start_date AND p_end_date
    GROUP BY TO_CHAR(transaction_date, 'YYYY-MM')
    ORDER BY month;
END;
$$;

-- ============================================================
-- 12. FUNCTION: Get Account Summary
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_account_summary()
RETURNS TABLE (
    account_id UUID,
    account_name TEXT,
    account_type TEXT,
    opening_balance NUMERIC,
    current_balance NUMERIC,
    total_income NUMERIC,
    total_expense NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        a.id AS account_id,
        a.name AS account_name,
        a.account_type,
        a.opening_balance,
        a.current_balance,
        COALESCE(SUM(CASE WHEN t.type = 'income' THEN t.amount END), 0) AS total_income,
        COALESCE(SUM(CASE WHEN t.type = 'expense' THEN t.amount END), 0) AS total_expense
    FROM public.accounts a
    LEFT JOIN public.transactions t ON t.account_id = a.id
    WHERE a.is_active = true
    GROUP BY a.id, a.name, a.account_type, a.opening_balance, a.current_balance
    ORDER BY a.name;
END;
$$;

-- ============================================================
-- 13. FUNCTION: Get Dashboard Summary
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_dashboard_summary()
RETURNS TABLE (
    month_income NUMERIC,
    month_expense NUMERIC,
    month_net NUMERIC,
    total_income NUMERIC,
    total_expense NUMERIC,
    pending_approvals BIGINT,
    pending_invoices BIGINT,
    recent_transactions JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_month_start DATE := DATE_TRUNC('month', CURRENT_DATE)::DATE;
    v_month_end DATE := (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month - 1 day')::DATE;
    v_month_income NUMERIC := 0;
    v_month_expense NUMERIC := 0;
    v_total_income NUMERIC := 0;
    v_total_expense NUMERIC := 0;
    v_pending_approvals BIGINT := 0;
    v_pending_invoices BIGINT := 0;
    v_recent JSONB;
BEGIN
    -- Month income
    SELECT COALESCE(SUM(amount), 0) INTO v_month_income
    FROM public.transactions
    WHERE type = 'income' AND transaction_date BETWEEN v_month_start AND v_month_end;

    -- Month expense
    SELECT COALESCE(SUM(amount), 0) INTO v_month_expense
    FROM public.transactions
    WHERE type = 'expense' AND transaction_date BETWEEN v_month_start AND v_month_end;

    -- Total income
    SELECT COALESCE(SUM(amount), 0) INTO v_total_income
    FROM public.transactions WHERE type = 'income';

    -- Total expense
    SELECT COALESCE(SUM(amount), 0) INTO v_total_expense
    FROM public.transactions WHERE type = 'expense';

    -- Pending approvals
    SELECT COUNT(*) INTO v_pending_approvals
    FROM public.salary_disbursements
    WHERE status = 'pending_approval';

    -- Pending invoices
    SELECT COUNT(*) INTO v_pending_invoices
    FROM public.invoices
    WHERE status IN ('draft', 'sent', 'overdue');

    -- Recent transactions
    SELECT COALESCE(
        jsonb_agg(jsonb_build_object(
            'id', t.id,
            'type', t.type,
            'amount', t.amount,
            'description', t.description,
            'date', t.transaction_date,
            'category', c.name
        ) ORDER BY t.transaction_date DESC, t.created_at DESC),
        '[]'::jsonb
    ) INTO v_recent
    FROM (
        SELECT * FROM public.transactions
        ORDER BY transaction_date DESC, created_at DESC
        LIMIT 10
    ) t
    LEFT JOIN public.categories c ON c.id = t.category_id;

    RETURN QUERY
    SELECT
        v_month_income,
        v_month_expense,
        v_month_income - v_month_expense,
        v_total_income,
        v_total_expense,
        v_pending_approvals,
        v_pending_invoices,
        v_recent;
END;
$$;

-- ============================================================
-- 14. FUNCTION: Bulk create disbursements for all employees
-- ============================================================
CREATE OR REPLACE FUNCTION public.bulk_create_disbursements(
    p_period_month DATE,
    p_requested_by UUID DEFAULT NULL
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_count INTEGER := 0;
    v_employee RECORD;
    v_advance_total NUMERIC;
BEGIN
    -- Create disbursement for each active employee
    FOR v_employee IN
        SELECT e.id, e.base_salary
        FROM public.employees e
        WHERE e.is_active = true
          AND NOT EXISTS (
              SELECT 1 FROM public.salary_disbursements sd
              WHERE sd.employee_id = e.id AND sd.period_month = p_period_month
          )
    LOOP
        -- Calculate total outstanding advancements
        SELECT COALESCE(SUM(sa.amount - sa.repaid_amount), 0)
        INTO v_advance_total
        FROM public.salary_advancements sa
        WHERE sa.employee_id = v_employee.id
          AND sa.status IN ('approved', 'pending')
          AND sa.advance_date <= p_period_month;

        INSERT INTO public.salary_disbursements (
            employee_id,
            amount,
            currency,
            period_month,
            status,
            initiation_type,
            requested_by
        ) VALUES (
            v_employee.id,
            v_employee.base_salary - v_advance_total,
            'INR',
            p_period_month,
            'pending_approval',
            'automatic',
            COALESCE(p_requested_by, auth.uid())
        );

        v_count := v_count + 1;
    END LOOP;

    RETURN v_count;
END;
$$;
