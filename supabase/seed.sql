-- ============================================================
-- KhataPay - Seed Data
-- Default categories, accounts, and workflow configuration
-- ============================================================

-- ============================================================
-- 1. DEFAULT CATEGORIES
-- ============================================================
INSERT INTO public.categories (name, type, is_default) VALUES
    -- Income categories
    ('Sales', 'income', true),
    ('Services', 'income', true),
    ('Product Sales', 'income', true),
    ('Other Income', 'income', true),

    -- Expense categories
    ('Salary', 'expense', true),
    ('Rent', 'expense', true),
    ('Utilities', 'expense', true),
    ('Supplies', 'expense', true),
    ('Transportation', 'expense', true),
    ('Marketing', 'expense', true),
    ('Maintenance', 'expense', true),
    ('Insurance', 'expense', true),
    ('Taxes', 'expense', true),
    ('Other Expense', 'expense', true)
ON CONFLICT DO NOTHING;

-- ============================================================
-- 2. DEFAULT ACCOUNTS
-- ============================================================
INSERT INTO public.accounts (name, account_type, opening_balance, current_balance) VALUES
    ('Cash on Hand', 'cash', 0, 0),
    ('Business Bank Account', 'bank', 0, 0),
    ('UPI Wallet', 'upi_wallet', 0, 0)
ON CONFLICT DO NOTHING;

-- ============================================================
-- 3. DEFAULT APPROVAL WORKFLOW
-- ============================================================
INSERT INTO public.approval_workflows (name, steps, is_active) VALUES
    (
        'Standard Salary Approval',
        '[{"role": "business_owner", "sequence": 1}]'::jsonb,
        true
    )
ON CONFLICT DO NOTHING;

-- ============================================================
-- 4. SAMPLE DATA (Optional - Comment out for production)
-- ============================================================

-- Note: Sample data requires existing auth users.
-- Uncomment and adjust after creating users in Supabase Auth.

/*
-- Sample employee (requires profile_id from an existing auth user)
INSERT INTO public.employees (
    profile_id, employee_code, first_name, last_name, email,
    phone, designation, department, base_salary, joining_date
) VALUES
    (
        NULL, 'EMP001', 'Rahul', 'Sharma', 'rahul@example.com',
        '+91 98765 43210', 'Software Engineer', 'Engineering',
        50000.00, '2024-01-15'
    ),
    (
        NULL, 'EMP002', 'Priya', 'Patel', 'priya@example.com',
        '+91 98765 43211', 'Accountant', 'Finance',
        45000.00, '2024-02-01'
    ),
    (
        NULL, 'EMP003', 'Amit', 'Kumar', 'amit@example.com',
        '+91 98765 43212', 'Sales Executive', 'Sales',
        35000.00, '2024-03-10'
    );

-- Sample payment methods
INSERT INTO public.payment_methods (
    employee_id, upi_id, account_holder_name, bank_name,
    account_number, ifsc_code, is_default, is_active
) VALUES
    (
        (SELECT id FROM public.employees WHERE employee_code = 'EMP001'),
        'rahul.sharma@okhdfcbank', 'Rahul Sharma', 'HDFC Bank',
        'XXXX1234', 'HDFC0001234', true, true
    ),
    (
        (SELECT id FROM public.employees WHERE employee_code = 'EMP002'),
        'priya.patel@ybl', 'Priya Patel', 'ICICI Bank',
        'XXXX5678', 'ICIC0005678', true, true
    ),
    (
        (SELECT id FROM public.employees WHERE employee_code = 'EMP003'),
        'amit.kumar@okaxis', 'Amit Kumar', 'Axis Bank',
        'XXXX9012', 'UTIB0009012', true, true
    );

-- Sample attendance for current month
INSERT INTO public.attendance_logs (employee_id, attendance_date, status)
SELECT e.id, d::date, 'present'
FROM public.employees e
CROSS JOIN generate_series(
    DATE_TRUNC('month', CURRENT_DATE)::date,
    CURRENT_DATE,
    '1 day'::interval
) AS d
WHERE e.employee_code IN ('EMP001', 'EMP002', 'EMP003')
  AND EXTRACT(DOW FROM d) NOT IN (0, 6) -- Skip weekends
ON CONFLICT (employee_id, attendance_date) DO NOTHING;

-- Sample transactions
INSERT INTO public.transactions (
    type, category_id, account_id, amount, currency,
    description, transaction_date, payment_method, reference
) VALUES
    (
        'income',
        (SELECT id FROM public.categories WHERE name = 'Sales' AND type = 'income'),
        (SELECT id FROM public.accounts WHERE name = 'Business Bank Account'),
        150000.00, 'INR', 'Monthly sales revenue',
        CURRENT_DATE - INTERVAL '5 days', 'bank', 'INV-2024-001'
    ),
    (
        'income',
        (SELECT id FROM public.categories WHERE name = 'Services' AND type = 'income'),
        (SELECT id FROM public.accounts WHERE name = 'Business Bank Account'),
        50000.00, 'INR', 'Consulting services',
        CURRENT_DATE - INTERVAL '3 days', 'upi', 'INV-2024-002'
    ),
    (
        'expense',
        (SELECT id FROM public.categories WHERE name = 'Rent' AND type = 'expense'),
        (SELECT id FROM public.accounts WHERE name = 'Business Bank Account'),
        20000.00, 'INR', 'Office rent for the month',
        CURRENT_DATE - INTERVAL '2 days', 'bank', 'RENT-2024-08'
    ),
    (
        'expense',
        (SELECT id FROM public.categories WHERE name = 'Utilities' AND type = 'expense'),
        (SELECT id FROM public.accounts WHERE name = 'Business Bank Account'),
        5000.00, 'INR', 'Electricity bill',
        CURRENT_DATE - INTERVAL '1 day', 'bank', 'BILL-2024-08'
    );

-- Sample invoice
INSERT INTO public.invoices (
    invoice_number, customer_name, customer_phone,
    amount, status, issue_date, due_date
) VALUES
    (
        'INV-2024-001', 'ABC Traders', '+91 90000 00001',
        150000.00, 'paid', CURRENT_DATE - INTERVAL '10 days', CURRENT_DATE - INTERVAL '5 days'
    ),
    (
        'INV-2024-002', 'XYZ Corporation', '+91 90000 00002',
        50000.00, 'sent', CURRENT_DATE - INTERVAL '3 days', CURRENT_DATE + INTERVAL '7 days'
    ),
    (
        'INV-2024-003', 'LMN Enterprises', '+91 90000 00003',
        75000.00, 'overdue', CURRENT_DATE - INTERVAL '30 days', CURRENT_DATE - INTERVAL '5 days'
    );
*/