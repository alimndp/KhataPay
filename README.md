# KhataPay - Business Management App

A comprehensive business management application built with **Flutter (Dart)** and **Supabase** that includes:

- 👥 **Employee Management** - Profiles, roles, and employee records
- 📅 **Attendance Tracking** - Daily check-in/out and attendance logs
- 💰 **Salary Disbursement** - Approval workflow + UPI payment integration
- 📊 **Account Module** - Income, expense tracking, and financial reports
- 🔐 **Role-Based Access** - RLS policies for secure data access

---

## 📁 Project Structure

```
KhataPay/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── core/
│   │   ├── constants/               # App constants
│   │   ├── theme/                   # Material 3 theme
│   │   └── utils/                   # Formatters
│   ├── models/                      # Data models
│   ├── providers/                   # Riverpod state management
│   ├── screens/
│   │   ├── auth/                    # Splash, Login, Register
│   │   ├── home/                    # Navigation shell
│   │   ├── dashboard/               # Owner dashboard
│   │   ├── employees/               # Employee management
│   │   ├── salary/                  # Disbursement & approvals
│   │   ├── accounts/                # Income/expense tracking
│   │   └── reports/                 # Reports & charts
│   ├── services/                    # Supabase & API services
│   └── widgets/                     # Reusable components
├── supabase/
│   ├── schema.sql                   # All database tables & indexes
│   ├── rls_policies.sql             # Row Level Security policies
│   ├── functions_triggers.sql       # Database functions & triggers
│   └── seed.sql                     # Default categories, accounts, workflows
├── docs/
│   └── app.pyplist.md               # Full implementation plan
└── README.md                        # This file
```

---

## 🚀 Setup Instructions

### 1. Install Flutter

1. Download Flutter SDK from [flutter.dev](https://flutter.dev/docs/get-started/install)
2. Add Flutter to your PATH
3. Run `flutter doctor` to verify installation

### 2. Create a Supabase Project

1. Go to [supabase.com](https://supabase.com) and create a new project
2. Note your **Project URL** and **anon/public key** from Settings → API

### 3. Configure the App

1. Open `lib/core/constants/app_constants.dart`
2. Replace these values with your Supabase credentials:
   ```dart
   static const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
   static const String supabaseAnonKey = 'YOUR_ANON_KEY';
   ```

### 4. Run the SQL Scripts

Execute the SQL files **in order** using the Supabase SQL Editor:

| Order | File | Purpose |
|---|---|---|
| 1 | `supabase/schema.sql` | Creates all tables and indexes |
| 2 | `supabase/rls_policies.sql` | Enables RLS and creates security policies |
| 3 | `supabase/functions_triggers.sql` | Creates functions and triggers |
| 4 | `supabase/seed.sql` | Inserts default categories, accounts, workflow |

### 5. Run the App

```bash
flutter pub get
flutter run
```

---

## ⚙️ Dependencies

| Package | Purpose |
|---|---|
| `supabase_flutter` | Supabase database & auth integration |
| `flutter_riverpod` | State management |
| `fl_chart` | Charts for reports & dashboard |
| `intl` | Date/currency formatting |
| `url_launcher` | UPI payment links |
| `pdf` / `printing` | PDF export |
| `csv` | CSV export |

---

## 📊 Database Tables

### Core Tables
| Table | Description |
|---|---|
| `profiles` | User profiles linked to auth.users |
| `employees` | Employee records with salary info |
| `attendance_logs` | Daily attendance tracking |
| `salary_advancements` | Salary advance requests |

### Salary Disbursement Tables
| Table | Description |
|---|---|
| `salary_disbursements` | Salary payment requests with approval status |
| `disbursement_approvals` | Approval workflow steps |
| `approval_workflows` | Configurable approval templates |
| `payment_methods` | Employee UPI/bank payment details |

### Account Module Tables
| Table | Description |
|---|---|
| `transactions` | Central ledger for income/expenses |
| `categories` | Income/expense categories |
| `accounts` | Bank/cash/UPI accounts |
| `invoices` | Customer invoices |
| `audit_logs` | Action audit trail |

---

## 🔄 Automated Workflows

### Salary Disbursement Flow
1. **Create** → HR/Finance creates disbursement (manual or bulk)
2. **Approve** → Business owner approves/rejects via approval dashboard
3. **Pay** → System generates UPI link and triggers payment
4. **Track** → Payment status updates in real-time

### Account Automation
- **Salary → Expense**: When a salary is marked `paid`, an expense transaction is auto-created
- **Balance Updates**: Account balances update automatically on every transaction
- **Reports**: Pre-built functions for P&L, cash flow, and account summaries

---

## 📱 App Screens

### Auth
- Splash / Login / Register (with role selection)

### Home (Navigation Shell)
- Role-based tabs: Dashboard, Employees, Salary, Accounts, Reports

### Dashboard
- Welcome message with role
- Income / Expense / Net Profit stat cards
- Income vs Expense pie chart
- Pending approvals section
- Recent transactions list
- Pending invoices

### Employees
- Employee list with search
- Add/Edit employee form
- Employee detail view with delete option

### Salary
- Disbursement list with status badges
- Pending approvals tab with approve/reject
- Bulk create disbursements
- Disbursement detail with UPI payment trigger

### Accounts
- All / Income / Expense tabs
- Transaction totals summary
- Add transaction form (type, category, account, payment method)

### Reports
- **Profit & Loss** - Income vs expense with category pie charts
- **Cash Flow** - Monthly income/expense bar chart
- **Accounts** - Balance summary per account
- Date range picker for reports

---

## 🔐 Security

- **Row Level Security (RLS)** enabled on all tables
- Role-based access: `business_owner`, `finance`, `hr`, `employee`
- Employees can only view their own data
- Owner has full access to all business data
- Audit logging on critical tables

---

## 🧪 Testing

1. **Create a business owner** user with role `business_owner`
2. **Create employees** and add payment methods
3. **Record attendance** for employees
4. **Create a disbursement** → verify approval step is auto-created
5. **Approve the disbursement** → verify status changes to `approved`
6. **Mark as paid** → verify expense transaction is auto-created
7. **Add income/expense transactions** → verify account balances update
8. **View reports** → verify P&L and cash flow calculations
9. **Check audit logs** → verify all actions are logged

---

## 📄 License

Private project - All rights reserved.