-- ════════════════════════════════════════════════════════════════════
-- 云智ERP 完整数据库初始化脚本
-- PostgreSQL 15 | Supabase
-- ════════════════════════════════════════════════════════════════════

-- ─── Extensions ──────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- for full-text search

-- ─── ENUM Types ──────────────────────────────────────────────────────
CREATE TYPE emp_status AS ENUM ('active','resigned','suspended');
CREATE TYPE order_status AS ENUM ('draft','pending','approved','processing','shipped','completed','cancelled');
CREATE TYPE pay_method AS ENUM ('bank','alipay','wechat','cash','check','wire');

-- ════════════════════════════════════════════════════════════════════
-- 1. 组织权限模块
-- ════════════════════════════════════════════════════════════════════

CREATE TABLE roles (
  id          bigserial PRIMARY KEY,
  name        varchar(50) UNIQUE NOT NULL,
  display     varchar(50) NOT NULL,
  description text,
  is_system   boolean DEFAULT false,
  created_at  timestamp DEFAULT now()
);

CREATE TABLE permissions (
  id          bigserial PRIMARY KEY,
  module      varchar(50) NOT NULL,
  resource    varchar(50) NOT NULL,
  action      varchar(20) NOT NULL,
  description text,
  UNIQUE(module, resource, action)
);

CREATE TABLE role_permissions (
  role_id       bigint REFERENCES roles(id) ON DELETE CASCADE,
  permission_id bigint REFERENCES permissions(id) ON DELETE CASCADE,
  PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE departments (
  id          bigserial PRIMARY KEY,
  parent_id   bigint REFERENCES departments(id),
  name        varchar(100) NOT NULL,
  type        varchar(30) DEFAULT 'dept',
  code        varchar(20) UNIQUE,
  manager_id  uuid,
  sort_order  integer DEFAULT 0,
  status      varchar(20) DEFAULT 'active',
  created_at  timestamp DEFAULT now()
);

CREATE TABLE positions (
  id          bigserial PRIMARY KEY,
  dept_id     bigint REFERENCES departments(id),
  name        varchar(100) NOT NULL,
  code        varchar(30),
  level       integer DEFAULT 1,
  created_at  timestamp DEFAULT now()
);

CREATE TABLE users (
  id          uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  emp_id      varchar(20) UNIQUE,
  name        varchar(50) NOT NULL,
  avatar_url  text,
  phone       varchar(20),
  email       varchar(100) UNIQUE NOT NULL,
  dept_id     bigint REFERENCES departments(id),
  role_id     bigint REFERENCES roles(id),
  position_id bigint REFERENCES positions(id),
  status      varchar(20) DEFAULT 'active',
  created_at  timestamp DEFAULT now(),
  updated_at  timestamp DEFAULT now()
);

-- ════════════════════════════════════════════════════════════════════
-- 2. HRM 人力资源
-- ════════════════════════════════════════════════════════════════════

CREATE TABLE employees (
  id               bigserial PRIMARY KEY,
  user_id          uuid REFERENCES users(id),
  emp_no           varchar(20) UNIQUE NOT NULL,
  name             varchar(50) NOT NULL,
  gender           varchar(10),
  birth_date       date,
  id_card          varchar(18),
  phone            varchar(20),
  email            varchar(100),
  address          text,
  dept_id          bigint REFERENCES departments(id),
  position_id      bigint REFERENCES positions(id),
  manager_id       bigint REFERENCES employees(id),
  hire_date        date NOT NULL,
  regularize_date  date,
  resign_date      date,
  resign_reason    text,
  status           emp_status DEFAULT 'active',
  avatar_url       text,
  contract_url     text,
  id_card_url      text,
  salary           numeric(12,2),
  probation_salary numeric(12,2),
  bank_account     varchar(30),
  emergency_contact varchar(50),
  emergency_phone  varchar(20),
  education        varchar(30),
  created_at       timestamp DEFAULT now(),
  updated_at       timestamp DEFAULT now()
);

CREATE TABLE attendance_rules (
  id          bigserial PRIMARY KEY,
  dept_id     bigint REFERENCES departments(id),
  work_start  time DEFAULT '09:00',
  work_end    time DEFAULT '18:00',
  late_min    integer DEFAULT 15,
  break_hours numeric(3,1) DEFAULT 1.5
);

CREATE TABLE attendance (
  id          bigserial PRIMARY KEY,
  emp_id      bigint REFERENCES employees(id),
  date        date NOT NULL,
  check_in    timestamp,
  check_out   timestamp,
  type        varchar(20) DEFAULT 'normal',
  leave_type  varchar(20),
  leave_hours numeric(4,1),
  overtime_hours numeric(4,1) DEFAULT 0,
  note        text,
  status      varchar(20) DEFAULT 'confirmed',
  created_at  timestamp DEFAULT now(),
  UNIQUE(emp_id, date)
);

CREATE TABLE payroll (
  id               bigserial PRIMARY KEY,
  emp_id           bigint REFERENCES employees(id),
  period           varchar(7) NOT NULL,
  base_salary      numeric(12,2) DEFAULT 0,
  performance      numeric(12,2) DEFAULT 0,
  allowance        numeric(12,2) DEFAULT 0,
  bonus            numeric(12,2) DEFAULT 0,
  overtime_pay     numeric(12,2) DEFAULT 0,
  deduction        numeric(12,2) DEFAULT 0,
  social_ins_emp   numeric(12,2) DEFAULT 0,
  social_ins_comp  numeric(12,2) DEFAULT 0,
  housing_fund_emp numeric(12,2) DEFAULT 0,
  housing_fund_comp numeric(12,2) DEFAULT 0,
  income_tax       numeric(12,2) DEFAULT 0,
  net_salary       numeric(12,2),
  status           varchar(20) DEFAULT 'draft',
  pay_date         date,
  note             text,
  created_at       timestamp DEFAULT now(),
  UNIQUE(emp_id, period)
);

-- Auto-calculate net salary
CREATE OR REPLACE FUNCTION calc_net_salary() RETURNS TRIGGER AS $$
BEGIN
  NEW.net_salary := NEW.base_salary + NEW.performance + NEW.allowance
    + NEW.bonus + NEW.overtime_pay - NEW.deduction
    - NEW.social_ins_emp - NEW.housing_fund_emp - NEW.income_tax;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_net_salary BEFORE INSERT OR UPDATE ON payroll
  FOR EACH ROW EXECUTE FUNCTION calc_net_salary();

CREATE TABLE job_positions (
  id          bigserial PRIMARY KEY,
  dept_id     bigint REFERENCES departments(id),
  title       varchar(100) NOT NULL,
  headcount   integer DEFAULT 1,
  salary_min  numeric(12,2),
  salary_max  numeric(12,2),
  requirements text,
  status      varchar(20) DEFAULT 'open',
  published_at timestamp,
  closed_at   timestamp,
  created_by  uuid REFERENCES users(id),
  created_at  timestamp DEFAULT now()
);

CREATE TABLE candidates (
  id          bigserial PRIMARY KEY,
  job_id      bigint REFERENCES job_positions(id),
  name        varchar(50) NOT NULL,
  phone       varchar(20),
  email       varchar(100),
  resume_url  text,
  source      varchar(30) DEFAULT 'website',
  stage       varchar(30) DEFAULT 'applied',
  score       integer,
  interview_date timestamp,
  interviewer_id uuid REFERENCES users(id),
  offer_salary numeric(12,2),
  note        text,
  created_at  timestamp DEFAULT now()
);

-- ════════════════════════════════════════════════════════════════════
-- 3. 产品与供应商
-- ════════════════════════════════════════════════════════════════════

CREATE TABLE product_categories (
  id        bigserial PRIMARY KEY,
  parent_id bigint REFERENCES product_categories(id),
  name      varchar(100) NOT NULL,
  code      varchar(30) UNIQUE,
  sort_order integer DEFAULT 0
);

CREATE TABLE products (
  id            bigserial PRIMARY KEY,
  sku           varchar(50) UNIQUE NOT NULL,
  name          varchar(200) NOT NULL,
  category_id   bigint REFERENCES product_categories(id),
  unit          varchar(20) DEFAULT '个',
  cost_price    numeric(12,2),
  sale_price    numeric(12,2),
  min_price     numeric(12,2),
  weight        numeric(10,3),
  specification text,
  image_url     text,
  status        varchar(20) DEFAULT 'active',
  created_at    timestamp DEFAULT now()
);

CREATE TABLE suppliers (
  id            bigserial PRIMARY KEY,
  code          varchar(20) UNIQUE,
  name          varchar(200) NOT NULL,
  short_name    varchar(50),
  contact       varchar(50),
  phone         varchar(20),
  email         varchar(100),
  address       text,
  category      varchar(50),
  level         varchar(10) DEFAULT 'A',
  payment_terms integer DEFAULT 30,
  bank_name     varchar(100),
  bank_account  varchar(50),
  tax_no        varchar(30),
  status        varchar(20) DEFAULT 'active',
  created_at    timestamp DEFAULT now()
);

-- ════════════════════════════════════════════════════════════════════
-- 4. CRM 销售客户
-- ════════════════════════════════════════════════════════════════════

CREATE TABLE customers (
  id               bigserial PRIMARY KEY,
  code             varchar(20) UNIQUE,
  name             varchar(200) NOT NULL,
  short_name       varchar(50),
  contact          varchar(50),
  phone            varchar(20),
  email            varchar(100),
  address          text,
  industry         varchar(50),
  level            varchar(10) DEFAULT 'B',
  source           varchar(30),
  owner_id         uuid REFERENCES users(id),
  status           varchar(20) DEFAULT 'active',
  contract_amount  numeric(15,2) DEFAULT 0,
  credit_limit     numeric(15,2),
  payment_terms    integer DEFAULT 30,
  created_at       timestamp DEFAULT now(),
  updated_at       timestamp DEFAULT now()
);

CREATE TABLE opportunities (
  id            bigserial PRIMARY KEY,
  customer_id   bigint REFERENCES customers(id),
  title         varchar(200) NOT NULL,
  amount        numeric(15,2),
  stage         varchar(30) DEFAULT 'lead',
  probability   integer DEFAULT 10,
  expected_date date,
  owner_id      uuid REFERENCES users(id),
  source        varchar(30),
  description   text,
  lost_reason   text,
  created_at    timestamp DEFAULT now(),
  updated_at    timestamp DEFAULT now()
);

CREATE TABLE follow_records (
  id             bigserial PRIMARY KEY,
  customer_id    bigint REFERENCES customers(id),
  opportunity_id bigint REFERENCES opportunities(id),
  type           varchar(20) DEFAULT 'call',
  content        text NOT NULL,
  next_action    text,
  next_date      date,
  follow_date    timestamp NOT NULL DEFAULT now(),
  user_id        uuid REFERENCES users(id),
  created_at     timestamp DEFAULT now()
);

CREATE SEQUENCE sales_order_seq;
CREATE TABLE sales_orders (
  id             bigserial PRIMARY KEY,
  order_no       varchar(30) UNIQUE,
  customer_id    bigint REFERENCES customers(id),
  opportunity_id bigint REFERENCES opportunities(id),
  amount         numeric(15,2) NOT NULL DEFAULT 0,
  tax_rate       numeric(5,2) DEFAULT 0.13,
  tax_amount     numeric(15,2) DEFAULT 0,
  total_amount   numeric(15,2),
  discount       numeric(5,2) DEFAULT 0,
  status         order_status DEFAULT 'draft',
  delivery_date  date,
  owner_id       uuid REFERENCES users(id),
  approved_by    uuid REFERENCES users(id),
  approved_at    timestamp,
  shipped_at     timestamp,
  note           text,
  created_at     timestamp DEFAULT now()
);

CREATE TABLE sales_order_items (
  id            bigserial PRIMARY KEY,
  order_id      bigint REFERENCES sales_orders(id) ON DELETE CASCADE,
  product_id    bigint REFERENCES products(id),
  qty           integer NOT NULL,
  unit_price    numeric(12,2) NOT NULL,
  discount      numeric(5,2) DEFAULT 0,
  amount        numeric(15,2),
  delivered_qty integer DEFAULT 0
);

-- Auto-generate order number
CREATE OR REPLACE FUNCTION gen_sales_order_no() RETURNS TRIGGER AS $$
BEGIN
  NEW.order_no := 'SO-' || to_char(now(),'YYYY') || '-' || lpad(nextval('sales_order_seq')::text,4,'0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sales_order_no BEFORE INSERT ON sales_orders
  FOR EACH ROW WHEN (NEW.order_no IS NULL) EXECUTE FUNCTION gen_sales_order_no();

-- ════════════════════════════════════════════════════════════════════
-- 5. 采购管理
-- ════════════════════════════════════════════════════════════════════

CREATE TABLE purchase_requisitions (
  id          bigserial PRIMARY KEY,
  req_no      varchar(30) UNIQUE,
  emp_id      bigint REFERENCES employees(id),
  dept_id     bigint REFERENCES departments(id),
  item_name   varchar(200) NOT NULL,
  qty         integer NOT NULL,
  budget      numeric(12,2),
  urgency     varchar(20) DEFAULT 'normal',
  purpose     text,
  status      varchar(20) DEFAULT 'draft',
  created_at  timestamp DEFAULT now()
);

CREATE SEQUENCE purchase_order_seq;
CREATE TABLE purchase_orders (
  id            bigserial PRIMARY KEY,
  order_no      varchar(30) UNIQUE,
  supplier_id   bigint REFERENCES suppliers(id),
  req_id        bigint REFERENCES purchase_requisitions(id),
  amount        numeric(15,2) NOT NULL DEFAULT 0,
  tax_amount    numeric(15,2) DEFAULT 0,
  total_amount  numeric(15,2),
  status        order_status DEFAULT 'draft',
  delivery_date date,
  warehouse_id  bigint,
  created_by    uuid REFERENCES users(id),
  approved_by   uuid REFERENCES users(id),
  note          text,
  created_at    timestamp DEFAULT now()
);

CREATE TABLE purchase_order_items (
  id          bigserial PRIMARY KEY,
  order_id    bigint REFERENCES purchase_orders(id) ON DELETE CASCADE,
  product_id  bigint REFERENCES products(id),
  qty         integer NOT NULL,
  unit_price  numeric(12,2),
  amount      numeric(15,2),
  received_qty integer DEFAULT 0
);

CREATE OR REPLACE FUNCTION gen_purchase_order_no() RETURNS TRIGGER AS $$
BEGIN
  NEW.order_no := 'PO-' || to_char(now(),'YYYY') || '-' || lpad(nextval('purchase_order_seq')::text,4,'0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_po_no BEFORE INSERT ON purchase_orders
  FOR EACH ROW WHEN (NEW.order_no IS NULL) EXECUTE FUNCTION gen_purchase_order_no();

-- ════════════════════════════════════════════════════════════════════
-- 6. WMS 仓储库存
-- ════════════════════════════════════════════════════════════════════

CREATE TABLE warehouses (
  id          bigserial PRIMARY KEY,
  name        varchar(100) NOT NULL,
  code        varchar(20) UNIQUE,
  address     text,
  manager_id  uuid REFERENCES users(id),
  area        numeric(10,2),
  status      varchar(20) DEFAULT 'active',
  created_at  timestamp DEFAULT now()
);

CREATE TABLE warehouse_zones (
  id           bigserial PRIMARY KEY,
  warehouse_id bigint REFERENCES warehouses(id) ON DELETE CASCADE,
  name         varchar(50) NOT NULL,
  code         varchar(20)
);

CREATE TABLE warehouse_locations (
  id       bigserial PRIMARY KEY,
  zone_id  bigint REFERENCES warehouse_zones(id),
  code     varchar(30) UNIQUE,
  row_no   integer,
  col_no   integer,
  capacity integer DEFAULT 100,
  status   varchar(20) DEFAULT 'empty'
);

CREATE TABLE inventory (
  id            bigserial PRIMARY KEY,
  product_id    bigint REFERENCES products(id),
  warehouse_id  bigint REFERENCES warehouses(id),
  location_id   bigint REFERENCES warehouse_locations(id),
  qty           integer NOT NULL DEFAULT 0,
  safety_qty    integer DEFAULT 0,
  max_qty       integer,
  avg_cost      numeric(12,4) DEFAULT 0,
  total_amount  numeric(15,2) DEFAULT 0,
  updated_at    timestamp DEFAULT now(),
  UNIQUE(product_id, warehouse_id, location_id)
);

CREATE TABLE inventory_transactions (
  id            bigserial PRIMARY KEY,
  product_id    bigint REFERENCES products(id),
  warehouse_id  bigint REFERENCES warehouses(id),
  location_id   bigint REFERENCES warehouse_locations(id),
  type          varchar(30) NOT NULL,
  ref_type      varchar(30),
  ref_id        bigint,
  ref_no        varchar(50),
  qty           integer NOT NULL,
  before_qty    integer DEFAULT 0,
  after_qty     integer DEFAULT 0,
  unit_cost     numeric(12,4),
  amount        numeric(15,2),
  batch_no      varchar(50),
  operator_id   uuid REFERENCES users(id),
  note          text,
  created_at    timestamp DEFAULT now()
);

-- Inventory transaction trigger (update inventory qty)
CREATE OR REPLACE FUNCTION update_inventory() RETURNS TRIGGER AS $$
DECLARE
  current_qty integer;
  new_qty integer;
  new_cost numeric;
BEGIN
  SELECT COALESCE(qty, 0) INTO current_qty
  FROM inventory WHERE product_id = NEW.product_id AND warehouse_id = NEW.warehouse_id;

  new_qty := current_qty + NEW.qty;
  NEW.before_qty := current_qty;
  NEW.after_qty := new_qty;

  INSERT INTO inventory(product_id, warehouse_id, qty, avg_cost, total_amount)
  VALUES(NEW.product_id, NEW.warehouse_id, new_qty, COALESCE(NEW.unit_cost,0), new_qty * COALESCE(NEW.unit_cost,0))
  ON CONFLICT(product_id, warehouse_id, location_id)
  DO UPDATE SET qty = new_qty, total_amount = new_qty * COALESCE(NEW.unit_cost, inventory.avg_cost), updated_at = now();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_inventory AFTER INSERT ON inventory_transactions
  FOR EACH ROW EXECUTE FUNCTION update_inventory();

CREATE TABLE stocktakes (
  id            bigserial PRIMARY KEY,
  code          varchar(30) UNIQUE,
  warehouse_id  bigint REFERENCES warehouses(id),
  type          varchar(20) DEFAULT 'full',
  status        varchar(20) DEFAULT 'draft',
  plan_date     date,
  complete_date date,
  operator_id   uuid REFERENCES users(id),
  note          text,
  diff_amount   numeric(15,2),
  created_at    timestamp DEFAULT now()
);

CREATE TABLE stocktake_items (
  id            bigserial PRIMARY KEY,
  stocktake_id  bigint REFERENCES stocktakes(id) ON DELETE CASCADE,
  product_id    bigint REFERENCES products(id),
  location_id   bigint REFERENCES warehouse_locations(id),
  book_qty      integer NOT NULL DEFAULT 0,
  actual_qty    integer,
  diff_qty      integer GENERATED ALWAYS AS (actual_qty - book_qty) STORED,
  unit_cost     numeric(12,4),
  diff_amount   numeric(12,2),
  status        varchar(20) DEFAULT 'pending',
  counted_by    uuid REFERENCES users(id)
);

-- ════════════════════════════════════════════════════════════════════
-- 7. 财务管理
-- ════════════════════════════════════════════════════════════════════

CREATE TABLE accounts (
  id            bigserial PRIMARY KEY,
  parent_id     bigint REFERENCES accounts(id),
  code          varchar(20) UNIQUE NOT NULL,
  name          varchar(100) NOT NULL,
  type          varchar(20) NOT NULL,
  normal_balance varchar(10) DEFAULT 'debit',
  level         integer DEFAULT 1,
  is_detail     boolean DEFAULT true,
  currency      varchar(10) DEFAULT 'CNY',
  created_at    timestamp DEFAULT now()
);

CREATE TABLE accounting_periods (
  id          bigserial PRIMARY KEY,
  year        integer NOT NULL,
  month       integer NOT NULL,
  status      varchar(20) DEFAULT 'open',
  closed_at   timestamp,
  closed_by   uuid REFERENCES users(id),
  UNIQUE(year, month)
);

CREATE SEQUENCE voucher_seq;
CREATE TABLE vouchers (
  id           bigserial PRIMARY KEY,
  voucher_no   varchar(30) UNIQUE,
  period_id    bigint REFERENCES accounting_periods(id),
  type         varchar(20) DEFAULT 'general',
  description  text NOT NULL,
  total_debit  numeric(15,2) DEFAULT 0,
  total_credit numeric(15,2) DEFAULT 0,
  status       varchar(20) DEFAULT 'draft',
  prepared_by  uuid REFERENCES users(id),
  reviewed_by  uuid REFERENCES users(id),
  posted_at    timestamp,
  created_at   timestamp DEFAULT now()
);

CREATE TABLE voucher_lines (
  id          bigserial PRIMARY KEY,
  voucher_id  bigint REFERENCES vouchers(id) ON DELETE CASCADE,
  account_id  bigint REFERENCES accounts(id),
  description text,
  debit       numeric(15,2) DEFAULT 0,
  credit      numeric(15,2) DEFAULT 0,
  line_no     integer NOT NULL
);

CREATE OR REPLACE FUNCTION gen_voucher_no() RETURNS TRIGGER AS $$
BEGIN
  NEW.voucher_no := 'JV-' || to_char(now(),'YYYY-MM') || '-' || lpad(nextval('voucher_seq')::text,4,'0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_voucher_no BEFORE INSERT ON vouchers
  FOR EACH ROW WHEN (NEW.voucher_no IS NULL) EXECUTE FUNCTION gen_voucher_no();

CREATE TABLE receivables (
  id           bigserial PRIMARY KEY,
  customer_id  bigint REFERENCES customers(id),
  order_id     bigint REFERENCES sales_orders(id),
  invoice_no   varchar(30),
  amount       numeric(15,2) NOT NULL,
  received     numeric(15,2) DEFAULT 0,
  due_date     date NOT NULL,
  status       varchar(20) DEFAULT 'pending',
  note         text,
  created_at   timestamp DEFAULT now()
);

CREATE TABLE payables (
  id           bigserial PRIMARY KEY,
  supplier_id  bigint REFERENCES suppliers(id),
  order_id     bigint REFERENCES purchase_orders(id),
  invoice_no   varchar(30),
  amount       numeric(15,2) NOT NULL,
  paid         numeric(15,2) DEFAULT 0,
  due_date     date NOT NULL,
  status       varchar(20) DEFAULT 'pending',
  note         text,
  created_at   timestamp DEFAULT now()
);

CREATE TABLE payments (
  id             bigserial PRIMARY KEY,
  type           varchar(10) NOT NULL,
  customer_id    bigint REFERENCES customers(id),
  supplier_id    bigint REFERENCES suppliers(id),
  amount         numeric(15,2) NOT NULL,
  method         pay_method DEFAULT 'bank',
  bank_account   varchar(50),
  transaction_no varchar(100),
  pay_date       date NOT NULL,
  ref_type       varchar(30),
  ref_id         bigint,
  operator_id    uuid REFERENCES users(id),
  note           text,
  created_at     timestamp DEFAULT now()
);

CREATE TABLE expense_reports (
  id            bigserial PRIMARY KEY,
  report_no     varchar(30) UNIQUE,
  emp_id        bigint REFERENCES employees(id),
  type          varchar(30) NOT NULL,
  amount        numeric(12,2) NOT NULL,
  status        varchar(20) DEFAULT 'draft',
  dept_id       bigint REFERENCES departments(id),
  occur_date    date NOT NULL,
  description   text,
  submit_date   timestamp,
  approved_by   uuid REFERENCES users(id),
  approved_at   timestamp,
  reject_reason text,
  paid_at       timestamp,
  created_at    timestamp DEFAULT now()
);

CREATE TABLE expense_attachments (
  id          bigserial PRIMARY KEY,
  report_id   bigint REFERENCES expense_reports(id) ON DELETE CASCADE,
  file_name   varchar(200),
  file_url    text NOT NULL,
  file_size   integer,
  file_type   varchar(50),
  uploaded_at timestamp DEFAULT now()
);

-- ════════════════════════════════════════════════════════════════════
-- 8. OA 办公
-- ════════════════════════════════════════════════════════════════════

CREATE TABLE announcements (
  id          bigserial PRIMARY KEY,
  title       varchar(200) NOT NULL,
  content     text NOT NULL,
  type        varchar(30) DEFAULT 'notice',
  is_top      boolean DEFAULT false,
  publish_at  timestamp DEFAULT now(),
  expire_at   timestamp,
  author_id   uuid REFERENCES users(id),
  dept_scope  bigint[],
  read_count  integer DEFAULT 0,
  created_at  timestamp DEFAULT now()
);

CREATE TABLE meeting_rooms (
  id          bigserial PRIMARY KEY,
  name        varchar(50) NOT NULL,
  capacity    integer,
  floor       varchar(20),
  equipment   text[],
  status      varchar(20) DEFAULT 'available'
);

CREATE TABLE meeting_reservations (
  id          bigserial PRIMARY KEY,
  room_id     bigint REFERENCES meeting_rooms(id),
  title       varchar(200) NOT NULL,
  host_id     uuid REFERENCES users(id),
  start_time  timestamp NOT NULL,
  end_time    timestamp NOT NULL,
  attendees   uuid[],
  status      varchar(20) DEFAULT 'confirmed',
  created_at  timestamp DEFAULT now()
);

CREATE TABLE file_folders (
  id          bigserial PRIMARY KEY,
  parent_id   bigint REFERENCES file_folders(id),
  name        varchar(200) NOT NULL,
  owner_id    uuid REFERENCES users(id),
  dept_id     bigint REFERENCES departments(id),
  access_type varchar(20) DEFAULT 'private',
  created_at  timestamp DEFAULT now()
);

CREATE TABLE files (
  id           bigserial PRIMARY KEY,
  folder_id    bigint REFERENCES file_folders(id),
  name         varchar(200) NOT NULL,
  storage_path text NOT NULL,
  public_url   text,
  size         bigint,
  mime_type    varchar(100),
  extension    varchar(20),
  version      integer DEFAULT 1,
  is_latest    boolean DEFAULT true,
  owner_id     uuid REFERENCES users(id),
  dept_id      bigint REFERENCES departments(id),
  tags         text[],
  downloads    integer DEFAULT 0,
  created_at   timestamp DEFAULT now()
);

CREATE TABLE todos (
  id          bigserial PRIMARY KEY,
  user_id     uuid REFERENCES users(id),
  title       varchar(200) NOT NULL,
  description text,
  priority    varchar(20) DEFAULT 'normal',
  due_date    timestamp,
  is_done     boolean DEFAULT false,
  done_at     timestamp,
  category    varchar(50),
  created_at  timestamp DEFAULT now()
);

CREATE TABLE knowledge_articles (
  id          bigserial PRIMARY KEY,
  folder_id   bigint,
  title       varchar(200) NOT NULL,
  content     text,
  type        varchar(30) DEFAULT 'article',
  author_id   uuid REFERENCES users(id),
  tags        text[],
  views       integer DEFAULT 0,
  is_pinned   boolean DEFAULT false,
  status      varchar(20) DEFAULT 'published',
  created_at  timestamp DEFAULT now(),
  updated_at  timestamp DEFAULT now()
);

-- ════════════════════════════════════════════════════════════════════
-- 9. 审批工作流
-- ════════════════════════════════════════════════════════════════════

CREATE TABLE workflow_templates (
  id          bigserial PRIMARY KEY,
  name        varchar(100) NOT NULL,
  type        varchar(30) NOT NULL,
  config      jsonb NOT NULL DEFAULT '{"nodes":[]}',
  is_active   boolean DEFAULT true,
  created_by  uuid REFERENCES users(id),
  created_at  timestamp DEFAULT now()
);

CREATE TABLE workflow_instances (
  id           bigserial PRIMARY KEY,
  template_id  bigint REFERENCES workflow_templates(id),
  title        varchar(200) NOT NULL,
  applicant_id uuid REFERENCES users(id),
  ref_type     varchar(30),
  ref_id       bigint,
  form_data    jsonb DEFAULT '{}',
  current_node integer DEFAULT 0,
  status       varchar(20) DEFAULT 'pending',
  created_at   timestamp DEFAULT now(),
  completed_at timestamp
);

CREATE TABLE workflow_approvals (
  id           bigserial PRIMARY KEY,
  instance_id  bigint REFERENCES workflow_instances(id) ON DELETE CASCADE,
  node_index   integer NOT NULL,
  approver_id  uuid REFERENCES users(id),
  action       varchar(20),
  comment      text,
  acted_at     timestamp,
  deadline     timestamp,
  created_at   timestamp DEFAULT now()
);

-- ════════════════════════════════════════════════════════════════════
-- 10. 系统管理
-- ════════════════════════════════════════════════════════════════════

CREATE TABLE notifications (
  id          bigserial PRIMARY KEY,
  user_id     uuid REFERENCES users(id) NOT NULL,
  type        varchar(30) NOT NULL,
  title       varchar(200) NOT NULL,
  content     text,
  is_read     boolean DEFAULT false,
  ref_type    varchar(30),
  ref_id      bigint,
  action_url  text,
  created_at  timestamp DEFAULT now()
);

CREATE TABLE dict_types (
  id          bigserial PRIMARY KEY,
  code        varchar(50) UNIQUE NOT NULL,
  name        varchar(100) NOT NULL,
  description text,
  status      varchar(20) DEFAULT 'active',
  created_at  timestamp DEFAULT now()
);

CREATE TABLE dict_items (
  id          bigserial PRIMARY KEY,
  type_id     bigint REFERENCES dict_types(id) ON DELETE CASCADE,
  item_code   varchar(50) NOT NULL,
  item_name   varchar(100) NOT NULL,
  item_value  text,
  sort_order  integer DEFAULT 0,
  is_default  boolean DEFAULT false,
  status      varchar(20) DEFAULT 'active',
  UNIQUE(type_id, item_code)
);

CREATE TABLE system_config (
  id          bigserial PRIMARY KEY,
  key         varchar(100) UNIQUE NOT NULL,
  value       text,
  type        varchar(20) DEFAULT 'string',
  group_name  varchar(50),
  description text,
  updated_at  timestamp DEFAULT now()
);

CREATE TABLE audit_logs (
  id          bigserial PRIMARY KEY,
  user_id     uuid REFERENCES users(id),
  action      varchar(50) NOT NULL,
  module      varchar(50) NOT NULL,
  resource    varchar(50),
  resource_id text,
  old_data    jsonb,
  new_data    jsonb,
  ip_address  inet,
  user_agent  text,
  status      varchar(20) DEFAULT 'success',
  created_at  timestamp DEFAULT now()
);

-- ════════════════════════════════════════════════════════════════════
-- 11. 索引
-- ════════════════════════════════════════════════════════════════════

CREATE INDEX idx_users_dept ON users(dept_id);
CREATE INDEX idx_users_role ON users(role_id);
CREATE INDEX idx_employees_dept ON employees(dept_id);
CREATE INDEX idx_employees_status ON employees(status);
CREATE INDEX idx_attendance_emp ON attendance(emp_id, date);
CREATE INDEX idx_payroll_emp ON payroll(emp_id, period);
CREATE INDEX idx_customers_owner ON customers(owner_id);
CREATE INDEX idx_customers_search ON customers USING gin(to_tsvector('simple', name));
CREATE INDEX idx_opportunities_stage ON opportunities(stage);
CREATE INDEX idx_sales_orders_customer ON sales_orders(customer_id);
CREATE INDEX idx_sales_orders_status ON sales_orders(status);
CREATE INDEX idx_purchase_orders_supplier ON purchase_orders(supplier_id);
CREATE INDEX idx_inventory_product ON inventory(product_id);
CREATE INDEX idx_inventory_warehouse ON inventory(warehouse_id);
CREATE INDEX idx_inv_txn_product ON inventory_transactions(product_id, created_at DESC);
CREATE INDEX idx_receivables_customer ON receivables(customer_id, status);
CREATE INDEX idx_payables_supplier ON payables(supplier_id, status);
CREATE INDEX idx_expenses_emp ON expense_reports(emp_id, status);
CREATE INDEX idx_vouchers_period ON vouchers(period_id);
CREATE INDEX idx_notifications_user ON notifications(user_id, is_read);
CREATE INDEX idx_wf_instances_status ON workflow_instances(status, applicant_id);
CREATE INDEX idx_audit_logs_user ON audit_logs(user_id, created_at DESC);
CREATE INDEX idx_audit_logs_module ON audit_logs(module, created_at DESC);

-- ════════════════════════════════════════════════════════════════════
-- 12. Realtime
-- ════════════════════════════════════════════════════════════════════

ALTER TABLE notifications REPLICA IDENTITY FULL;
ALTER TABLE workflow_instances REPLICA IDENTITY FULL;
ALTER TABLE inventory REPLICA IDENTITY FULL;

-- ════════════════════════════════════════════════════════════════════
-- 13. Row Level Security
-- ════════════════════════════════════════════════════════════════════

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE opportunities ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE expense_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE payroll ENABLE ROW LEVEL SECURITY;

-- Helper function to get current user role
CREATE OR REPLACE FUNCTION get_user_role() RETURNS text AS $$
  SELECT r.name FROM users u JOIN roles r ON u.role_id = r.id WHERE u.id = auth.uid()
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Users: see self, admins see all
CREATE POLICY "users_read_self" ON users FOR SELECT USING (id = auth.uid() OR get_user_role() IN ('super_admin','admin'));
CREATE POLICY "users_update_self" ON users FOR UPDATE USING (id = auth.uid());
CREATE POLICY "admin_manage_users" ON users FOR ALL USING (get_user_role() IN ('super_admin','admin'));

-- Employees: hr and above see all, others see self
CREATE POLICY "emp_read" ON employees FOR SELECT
  USING (user_id = auth.uid() OR get_user_role() IN ('super_admin','admin','hr'));
CREATE POLICY "emp_manage" ON employees FOR ALL
  USING (get_user_role() IN ('super_admin','admin','hr'));

-- Customers: sales sees own, admin sees all
CREATE POLICY "customers_read" ON customers FOR SELECT
  USING (owner_id = auth.uid() OR get_user_role() IN ('super_admin','admin','sales'));
CREATE POLICY "customers_manage" ON customers FOR ALL
  USING (owner_id = auth.uid() OR get_user_role() IN ('super_admin','admin','sales'));

-- Notifications: only owner
CREATE POLICY "notif_own" ON notifications FOR ALL USING (user_id = auth.uid());

-- Payroll: only HR and self
CREATE POLICY "payroll_read" ON payroll FOR SELECT
  USING (get_user_role() IN ('super_admin','admin','hr') OR
    emp_id IN (SELECT id FROM employees WHERE user_id = auth.uid()));

-- Audit logs: admin only
CREATE POLICY "audit_admin" ON audit_logs FOR SELECT
  USING (get_user_role() IN ('super_admin','admin'));

-- ════════════════════════════════════════════════════════════════════
-- 14. 初始化数据
-- ════════════════════════════════════════════════════════════════════

INSERT INTO roles(name,display,is_system) VALUES
  ('super_admin','超级管理员',true),
  ('admin','系统管理员',true),
  ('finance','财务管理员',true),
  ('sales','销售管理员',true),
  ('warehouse','仓储管理员',true),
  ('hr','人事管理员',true),
  ('employee','普通员工',true);

INSERT INTO departments(name,type,code,sort_order) VALUES
  ('云智科技集团','group','ROOT',0),
  ('总经理办公室','dept','CEO',1),
  ('销售部','dept','SALES',2),
  ('财务部','dept','FIN',3),
  ('技术部','dept','TECH',4),
  ('人事部','dept','HR',5),
  ('采购部','dept','PUR',6),
  ('仓储部','dept','WMS',7),
  ('行政部','dept','ADM',8);

INSERT INTO positions(dept_id,name,code,level) VALUES
  (1,'董事长','CHAIRMAN',10),(1,'总经理','CEO',9),
  (2,'副总经理','VP',8),(3,'销售总监','SALES_DIR',7),
  (3,'销售经理','SALES_MGR',6),(3,'销售专员','SALES_STAFF',3),
  (4,'财务总监','CFO',7),(4,'财务主管','FIN_MGR',5),(4,'财务专员','FIN_STAFF',3),
  (5,'技术总监','CTO',7),(5,'高级工程师','SR_ENG',5),(5,'工程师','ENG',3),
  (6,'人事主管','HR_MGR',6),(6,'人事专员','HR_STAFF',3),
  (7,'采购经理','PUR_MGR',6),(7,'采购专员','PUR_STAFF',3),
  (8,'仓库主管','WMS_MGR',6),(8,'仓管员','WMS_STAFF',3);

INSERT INTO meeting_rooms(name,capacity,floor,equipment) VALUES
  ('会议室A',8,'3F',ARRAY['投影仪','白板']),
  ('会议室B',15,'3F',ARRAY['投影仪','白板','视频会议']),
  ('会议室C',30,'5F',ARRAY['大屏幕','视频会议','音响']),
  ('董事会议室',20,'18F',ARRAY['智慧大屏','视频会议','音响','同声传译']);

INSERT INTO warehouses(name,code,address,area) VALUES
  ('A区-主仓','WH-A','北京朝阳区经济开发区1号',2000),
  ('B区-存储仓','WH-B','北京朝阳区经济开发区2号',1500),
  ('C区-成品仓','WH-C','北京通州区物流园',3000);

INSERT INTO system_config(key,value,type,group_name,description) VALUES
  ('company_name','云智科技集团有限公司','string','company','公司全称'),
  ('company_short_name','云智科技','string','company','公司简称'),
  ('currency_symbol','¥','string','finance','货币符号'),
  ('currency_code','CNY','string','finance','货币代码'),
  ('fiscal_year_start','01','string','finance','财年开始月份'),
  ('work_start_time','09:00','string','hr','上班时间'),
  ('work_end_time','18:00','string','hr','下班时间'),
  ('late_tolerance_min','15','number','hr','迟到容忍分钟'),
  ('invoice_prefix','INV','string','finance','发票前缀'),
  ('logo_url','','string','company','公司Logo URL'),
  ('system_version','2.8.1','string','system','系统版本');

INSERT INTO dict_types(code,name) VALUES
  ('DEPT_TYPE','部门类型'),('POS_TYPE','岗位类型'),
  ('PROD_CAT','产品分类'),('LEAVE_TYPE','请假类型'),
  ('ORDER_STATUS','订单状态'),('EMP_STATUS','员工状态'),
  ('EXPENSE_TYPE','费用类型'),('FOLLOW_TYPE','跟进类型'),
  ('URGENCY_LEVEL','紧急程度'),('PAYMENT_METHOD','付款方式');

INSERT INTO dict_items(type_id,item_code,item_name,sort_order) VALUES
  (1,'GROUP','集团',1),(1,'COMPANY','公司',2),(1,'BRANCH','分公司',3),
  (1,'DIVISION','事业部',4),(1,'DEPT','部门',5),(1,'TEAM','小组',6),
  (4,'ANNUAL','年假',1),(4,'SICK','病假',2),(4,'PERSONAL','事假',3),
  (4,'MATERNITY','产假',4),(4,'PATERNITY','陪产假',5),
  (7,'TRAVEL','差旅费',1),(7,'ENTERTAINMENT','招待费',2),
  (7,'OFFICE','办公费用',3),(7,'TRAINING','培训费',4),(7,'OTHER','其他',5),
  (8,'CALL','电话',1),(8,'VISIT','拜访',2),(8,'EMAIL','邮件',3),(8,'WECHAT','微信',4),
  (9,'URGENT','紧急',1),(9,'HIGH','高',2),(9,'NORMAL','普通',3),(9,'LOW','低',4),
  (10,'BANK','银行转账',1),(10,'ALIPAY','支付宝',2),(10,'WECHAT','微信',3),(10,'CASH','现金',4);

INSERT INTO accounts(code,name,type,normal_balance,level) VALUES
  ('1','资产类','asset','debit',1),
  ('1001','库存现金','asset','debit',2),
  ('1002','银行存款','asset','debit',2),
  ('1012','其他货币资金','asset','debit',2),
  ('1101','短期投资','asset','debit',2),
  ('1122','应收票据','asset','debit',2),
  ('1131','应收账款','asset','debit',2),
  ('1221','其他应收款','asset','debit',2),
  ('1401','库存商品','asset','debit',2),
  ('1601','固定资产','asset','debit',2),
  ('2','负债类','liability','credit',1),
  ('2202','应付账款','liability','credit',2),
  ('2211','应付职工薪酬','liability','credit',2),
  ('2221','应交税费','liability','credit',2),
  ('2241','其他应付款','liability','credit',2),
  ('3','所有者权益','equity','credit',1),
  ('4001','实收资本','equity','credit',2),
  ('4141','未分配利润','equity','credit',2),
  ('5','成本类','expense','debit',1),
  ('5001','生产成本','expense','debit',2),
  ('6','损益类','revenue','credit',1),
  ('6001','主营业务收入','revenue','credit',2),
  ('6051','其他业务收入','revenue','credit',2),
  ('6301','投资收益','revenue','credit',2),
  ('6401','主营业务成本','expense','debit',2),
  ('6601','销售费用','expense','debit',2),
  ('6602','管理费用','expense','debit',2),
  ('6603','财务费用','expense','debit',2),
  ('6711','营业外收入','revenue','credit',2),
  ('6801','营业外支出','expense','debit',2),
  ('6901','所得税费用','expense','debit',2);

INSERT INTO workflow_templates(name,type,config) VALUES
  ('采购申请审批','purchase_req','{"nodes":[{"type":"start","label":"发起人"},{"type":"approval","label":"直属上级","approver_type":"direct_manager"},{"type":"condition","label":"金额判断","condition":"amount>=10000","branches":[{"label":"是","nodes":[{"type":"approval","label":"财务总监","approver_role":"finance"}]},{"label":"否","nodes":[]}]},{"type":"end","label":"完成"}]}'),
  ('费用报销审批','expense','{"nodes":[{"type":"start","label":"发起人"},{"type":"approval","label":"直属上级","approver_type":"direct_manager"},{"type":"approval","label":"财务审核","approver_role":"finance"},{"type":"end","label":"完成"}]}'),
  ('请假申请审批','leave','{"nodes":[{"type":"start","label":"发起人"},{"type":"approval","label":"直属上级","approver_type":"direct_manager"},{"type":"cc","label":"人事部","approver_role":"hr"},{"type":"end","label":"完成"}]}'),
  ('合同审批','contract','{"nodes":[{"type":"start","label":"发起人"},{"type":"approval","label":"部门总监","approver_type":"dept_director"},{"type":"approval","label":"法务审核","approver_role":"legal"},{"type":"approval","label":"总经理","approver_role":"ceo"},{"type":"end","label":"完成"}]}');
