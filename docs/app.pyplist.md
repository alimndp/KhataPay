# Project Implementation Plan

## 1. High-Level Plan Document
- Core Features: Implement a feature-rich app with core functionalities including employee management, attendance tracking, salary calculations, benefits reporting, and real-time updates.
- Database Setup: Create secure tables for Profile, Employee, Attendance Log, and Salary Advancements using Supabase Table Editor.
- RLS Policies: Set up Row-Level Security (RLS) to limit access to only authorized personnel only in the app.
- Integration with FlutterFlow's Supabase API: Enable real-time updates on the cloud by integrating with Flutter Flow.

## 2. Database Setup

### a. Profile Table
- Create dynamic tables for profile data using Supabase Table Editor.
- Set up RLS policies to control access only within the app.

### b. Employee Table
- Build tables for employee IDs, names, emails, and phone numbers.
- Configure RLS policies based on specific roles and permissions.

### c. Attendance Log Table
- Create an insertion table with date and time fields.
- Set up RLS policies to allow editing only within the app context.

### d. Salary Advancements Table
- Build a table for salary increments.
- Configure RLS policies to control data editing within the app.

## 3. Flutter Flow Integration
### a. Supabase API Integration
- Use Supabase's API SDK to link your app with Flutter Flow's services.
- Enable real-time attendance updates and automatically log employee data.

## 4. UPI Payment Trigger
### a. Button Design in Flutter Flow
- Create a button component or icon in Flutter Flow to trigger the UPI payment link.
- Implement URL formatting logic for dynamic UPI payments via launch URLs.

---

## 5. Salary Disbursement Feature with Approval Flow

### Overview
The salary disbursement feature enables salary payments to be initiated (manually or automatically), routed through a single-level approval workflow (small business owner), and then executed automatically via UPI payment integration. This builds on the existing Employee, Attendance Log, and Salary Advancements tables, and the planned UPI payment trigger.

### a. New Database Tables

#### i. `salary_disbursements` Table
Stores each disbursement request and its overall state.

| Column | Type | Description |
|---|---|---|
| `id` | UUID (PK) | Primary key |
| `employee_id` | UUID (FK → employees) | Employee receiving salary |
| `amount` | numeric | Disbursement amount |
| `currency` | text | Default 'INR' |
| `period_month` | date | Salary period (e.g., 2024-08-01) |
| `status` | text | `pending_approval`, `approved`, `rejected`, `paid`, `failed` |
| `initiation_type` | text | `manual` or `automatic` |
| `requested_by` | UUID | Who initiated the request |
| `requested_at` | timestamp | When request was created |
| `approved_by` | UUID | Business owner who approved |
| `approved_at` | timestamp | When approved |
| `payment_reference` | text | UPI transaction reference |
| `payment_status` | text | `not_initiated`, `initiated`, `success`, `failed` |
| `payment_initiated_at` | timestamp | When payment was triggered |
| `notes` | text | Additional notes |

#### ii. `disbursement_approvals` Table
Tracks the approval step in the workflow (single-level for small business owner).

| Column | Type | Description |
|---|---|---|
| `id` | UUID (PK) | Primary key |
| `disbursement_id` | UUID (FK → salary_disbursements) | Linked disbursement |
| `approver_id` | UUID | Business owner user |
| `approver_role` | text | `business_owner` |
| `sequence` | integer | Order of approval (1) |
| `status` | text | `pending`, `approved`, `rejected` |
| `comments` | text | Approver's comments |
| `action_at` | timestamp | When action was taken |

#### iii. `approval_workflows` Table (Configurable)
Defines the approval workflow template so it can be changed without code changes.

| Column | Type | Description |
|---|---|---|
| `id` | UUID (PK) | Primary key |
| `name` | text | e.g., "Standard Salary Approval" |
| `steps` | jsonb | Array of `{role, sequence}` defining approval order |
| `is_active` | boolean | Whether this workflow is in use |

#### iv. `payment_methods` Table
Stores employee UPI payment details for automatic UPI triggering.

| Column | Type | Description |
|---|---|---|
| `id` | UUID (PK) | Primary key |
| `employee_id` | UUID (FK → employees) | Linked employee |
| `upi_id` | text | UPI ID (e.g., name@upi) |
| `account_holder_name` | text | Name as on bank account |
| `bank_name` | text | Bank name |
| `account_number` | text | Bank account number (encrypted) |
| `ifsc_code` | text | IFSC code |
| `is_default` | boolean | Whether this is the default payment method |
| `is_active` | boolean | Whether this payment method is active |

### b. RLS Policies

| Table | Policy | Rule |
|---|---|---|
| `salary_disbursements` | Employee access | Users can view their own disbursements |
| `salary_disbursements` | Business owner access | Owner can view all disbursements and approve/reject |
| `salary_disbursements` | Finance access | Finance can view all and update payment status |
| `disbursement_approvals` | Approver access | Approvers can view and act on their assigned steps |
| `approval_workflows` | Admin access | Only admins can manage workflow definitions |
| `payment_methods` | Employee access | Users can view their own payment methods |
| `payment_methods` | Owner access | Owner can view all payment methods |

### c. Approval Flow Logic

1. **Initiation (Manual)**: HR/finance creates a disbursement request via the "Create Disbursement" screen. Status = `pending_approval`, `initiation_type = manual`.
2. **Initiation (Automatic)**: A scheduled job (or trigger) calculates salary based on attendance + salary advancements, creates disbursement requests. Status = `pending_approval`, `initiation_type = automatic`.
3. **Workflow Assignment**: Based on the active `approval_workflows` config, an approval step is created in `disbursement_approvals` with `status = pending`.
4. **Approval**: The business owner receives a notification. When they approve, the approval step is marked `approved` and the disbursement status becomes `approved`. If rejected, the disbursement status becomes `rejected` and the workflow stops.
5. **Automatic UPI Payment**: After final approval, the system automatically generates a UPI payment link using the employee's UPI ID from `payment_methods` and triggers the payment via URL launcher.
6. **Payment Completion**: Payment status is updated to `success` or `failed` in `salary_disbursements`.

### d. UPI Payment Integration

- After final approval, the system retrieves the employee's UPI ID from the `payment_methods` table.
- Generate a UPI payment link: `upi://pay?pa={upi_id}&pn={name}&tn={note}&am={amount}&cu=INR`
- Use FlutterFlow's URL launcher to trigger the UPI app automatically.
- After payment, update `payment_status` and `payment_reference` in `salary_disbursements`.
- Handle payment failure scenarios (retry, mark as failed).

### e. FlutterFlow UI Screens


| Screen | Purpose |
|---|---|
| **Salary Disbursement List** | Employees view their disbursement history and status; Owner sees all |
| **Disbursement Detail** | View full details of a single disbursement |
| **Create Disbursement** | HR/finance form to manually initiate a new disbursement |
| **Approval Dashboard** | Business owner sees pending approvals |
| **Approval Action** | Screen to approve/reject with comments |
| **Payment Tracking** | Finance/owner tracks payment status |
| **Payment Methods** | Employee manages their UPI/bank payment details |

### f. Real-Time Updates

- Use Supabase real-time subscriptions to push disbursement status changes to relevant users instantly.
- Approval notifications appear in real-time on the business owner's dashboard.
- Payment status updates appear in real-time on the payment tracking screen.

### g. Implementation Steps (Ordered)

1. **Create database tables** (`salary_disbursements`, `disbursement_approvals`, `approval_workflows`, `payment_methods`) in Supabase
2. **Set up RLS policies** for all new tables
3. **Create database functions/triggers** for workflow automation (auto-create approval steps on disbursement creation, update disbursement status on approval, auto-trigger UPI payment on final approval)
4. **Build FlutterFlow UI screens** (list, detail, create, approval dashboard, approval action, payment tracking, payment methods)
5. **Implement approval flow logic** (step progression, rejection handling)
6. **Integrate UPI payment trigger** (URL generation, launch, status update)
7. **Set up real-time subscriptions** for live updates
8. **Test the full flow** end-to-end (initiate → approve → pay → track)

### h. Additional Feature Suggestions

1. **Bulk Disbursement**: Allow the business owner to initiate salary disbursements for all employees at once (e.g., monthly salary run).
2. **Disbursement Reports**: Generate PDF/CSV reports of all disbursements for accounting purposes.
3. **Payment Retry**: Allow retrying failed UPI payments.
4. **Salary Calculation Integration**: Link disbursement amounts to attendance logs and salary advancements automatically.
5. **Notification System**: Email/SMS notifications for approval requests and payment confirmations.
6. **Audit Trail**: Log all actions (create, approve, reject, pay) for compliance.

---

## 6. Account Module (Income, Expense & Reports)

### Overview
The Account Module gives the business owner a complete financial dashboard to track all income, expenses, and generate reports. It integrates with the existing salary disbursement system so salary payments automatically appear as expenses.

### a. New Database Tables

#### i. `transactions` Table
Central ledger for all income and expense entries.

| Column | Type | Description |
|---|---|---|
| `id` | UUID (PK) | Primary key |
| `type` | text | `income` or `expense` |
| `category_id` | UUID (FK → categories) | Transaction category |
| `amount` | numeric | Transaction amount |
| `currency` | text | Default 'INR' |
| `description` | text | Description of transaction |
| `transaction_date` | date | Date of transaction |
| `payment_method` | text | `cash`, `bank`, `upi`, `card`, `other` |
| `reference` | text | Reference number (invoice, receipt, UPI ref) |
| `linked_disbursement_id` | UUID (FK → salary_disbursements) | If this expense is a salary payment |
| `created_by` | UUID | User who created the entry |
| `created_at` | timestamp | When entry was created |
| `updated_at` | timestamp | Last update |

#### ii. `categories` Table
Predefined and custom categories for income/expense classification.

| Column | Type | Description |
|---|---|---|
| `id` | UUID (PK) | Primary key |
| `name` | text | e.g., "Sales", "Rent", "Utilities", "Salary" |
| `type` | text | `income` or `expense` |
| `is_default` | boolean | System-defined category |
| `is_active` | boolean | Whether category is in use |

#### iii. `accounts` Table
Bank/cash accounts for tracking balances.

| Column | Type | Description |
|---|---|---|
| `id` | UUID (PK) | Primary key |
| `name` | text | Account name (e.g., "HDFC Business Account") |
| `account_type` | text | `cash`, `bank`, `upi_wallet` |
| `opening_balance` | numeric | Starting balance |
| `current_balance` | numeric | Computed current balance |
| `is_active` | boolean | Whether account is active |

#### iv. `invoices` Table (Optional - Income Tracking)
For tracking customer invoices and payments received.

| Column | Type | Description |
|---|---|---|
| `id` | UUID (PK) | Primary key |
| `invoice_number` | text | Unique invoice number |
| `customer_name` | text | Customer name |
| `customer_phone` | text | Customer phone |
| `amount` | numeric | Invoice amount |
| `status` | text | `draft`, `sent`, `paid`, `overdue`, `cancelled` |
| `issue_date` | date | Invoice issue date |
| `due_date` | date | Payment due date |
| `paid_at` | timestamp | When payment was received |
| `notes` | text | Additional notes |

### b. RLS Policies

| Table | Policy | Rule |
|---|---|---|
| `transactions` | Owner access | Business owner can view/create/update all transactions |
| `transactions` | Read-only for finance | Finance can view all transactions |
| `categories` | Owner access | Owner can manage categories |
| `accounts` | Owner access | Owner can manage accounts |
| `invoices` | Owner access | Owner can manage invoices |

### c. Key Features

1. **Income Tracking**
   - Record sales, service income, and other revenue
   - Create invoices and track payment status
   - Categorize income by type

2. **Expense Tracking**
   - Record business expenses (rent, utilities, supplies, etc.)
   - **Automatic salary expense**: When a salary disbursement is marked `paid`, an expense transaction is auto-created with `linked_disbursement_id`
   - Categorize expenses for analysis

3. **Account Balances**
   - Track multiple accounts (cash, bank, UPI wallet)
   - View current balance per account
   - Balance updates automatically when transactions are recorded

4. **Reports & Analytics**
   - **Profit & Loss Report**: Income vs. expenses over a period (daily, weekly, monthly, yearly)
   - **Category-wise Breakdown**: Pie chart showing spending by category
   - **Cash Flow Statement**: Money in vs. money out over time
   - **Account Summary**: Balance per account
   - **Export**: PDF/CSV export of all reports

5. **Dashboard**
   - Summary cards: Total income, total expenses, net profit (this month)
   - Recent transactions list
   - Upcoming invoice payments
   - Monthly trend chart

### d. FlutterFlow UI Screens

| Screen | Purpose |
|---|---|
| **Account Dashboard** | Overview of income, expenses, net profit, recent transactions |
| **Transaction List** | Filterable list of all transactions (by type, category, date) |
| **Add Transaction** | Form to add income/expense entry |
| **Transaction Detail** | View/edit a single transaction |
| **Categories Management** | Manage income/expense categories |
| **Accounts Management** | Add/edit bank/cash accounts |
| **Invoice List** | View all invoices and their status |
| **Create Invoice** | Create a new customer invoice |
| **Reports Screen** | Select report type and date range |
| **Profit & Loss Report** | Income vs. expense report view |
| **Category Report** | Category-wise breakdown with charts |
| **Cash Flow Report** | Money in/out over time |
| **Export Options** | PDF/CSV export dialog |

### e. Integration with Existing Features

- **Salary Disbursement → Expense**: When a salary disbursement is marked `paid`, automatically create an expense transaction in the `transactions` table with `linked_disbursement_id` pointing to the disbursement.
- **UPI Payments → Expense**: UPI salary payments automatically appear as expenses.
- **Dashboard**: The account dashboard shows salary expenses separately from other expenses.

### f. Implementation Steps (Ordered)

1. **Create database tables** (`transactions`, `categories`, `accounts`, `invoices`) in Supabase
2. **Set up RLS policies** for all new tables
3. **Create database functions/triggers**:
   - Auto-create expense transaction when salary disbursement is paid
   - Update account balance on transaction insert/update/delete
   - Auto-create default categories on setup
4. **Build FlutterFlow UI screens** (dashboard, transaction list, add/edit, categories, accounts, invoices, reports)
5. **Implement report generation logic** (aggregation queries, date filtering)
6. **Add export functionality** (PDF/CSV)
7. **Integrate with salary disbursement** (auto-expense creation)
8. **Set up real-time updates** for dashboard and transaction list
9. **Test end-to-end** (add income → add expense → view reports → export)

---

## 7. Additional Suggested Features

1. **Bulk Disbursement**: Initiate salary disbursements for all employees at once (monthly salary run).
2. **Disbursement Reports**: Generate PDF/CSV reports of all disbursements for accounting.
3. **Payment Retry**: Allow retrying failed UPI payments.
4. **Salary Calculation Integration**: Link disbursement amounts to attendance logs and salary advancements automatically.
5. **Notification System**: Email/SMS notifications for approval requests and payment confirmations.
6. **Audit Trail**: Log all actions (create, approve, reject, pay) for compliance.
7. **GST/Tax Tracking**: Track GST on income/expenses and generate tax reports.
8. **Recurring Transactions**: Set up recurring income/expense entries (e.g., monthly rent).
9. **Budget Planning**: Set monthly budgets per category and track against actuals.
10. **Multi-Currency Support**: Support transactions in multiple currencies with conversion.
11. **Data Backup & Export**: One-click export of all financial data.
12. **Role-Based Access**: Granular permissions (owner, finance, accountant, employee).
13. **Dark Mode & Customization**: Theme options for better UX.
14. **Offline Mode**: Cache data for offline access with sync when back online.
15. **Analytics & Insights**: AI-powered insights on spending patterns and profit trends.
