-- RECONSTRUCTED from the project documentation (column names, required fields and defaults
-- as documented; data types inferred from how the workflows use them).
-- NOT an export of a live database. No foreign keys, indexes or row-level security included.
create extension if not exists vector;

create table public.customers (
  id uuid primary key default gen_random_uuid(),
  external_id text not null unique,          -- unique: workflows upsert on external_id
  name text, email text,
  stripe_customer_id text, stripe_subscription_id text,
  created_at timestamptz default now()
);
create table public.products (
  id uuid primary key default gen_random_uuid(),
  sku text not null unique,                  -- unique: workflows upsert on sku
  name text not null,
  description text, category text,
  price numeric, currency text,
  in_stock boolean, stock_quantity integer,
  specs jsonb, embedding vector(1024),
  created_at timestamptz default now(), updated_at timestamptz
);
create table public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text not null,
  customer_id uuid not null,
  status text not null,
  total numeric, currency text, items jsonb, tracking_number text,
  placed_at timestamptz, shipped_at timestamptz, delivered_at timestamptz
);
create table public.quotes (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid, items jsonb, total numeric, currency text,
  status text default 'draft', created_at timestamptz default now()
);
create table public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid, order_id uuid,           -- order_id nullable
  type text, summary text, message text,
  status text default 'open', created_at timestamptz default now()
);
create table public.supervisor_audit_log (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid, message_id text, original_message text,
  intent text, selected_specialist text, routing_reason text,
  specialist_result jsonb, critique jsonb,
  confidence numeric, retry_count integer, needs_human boolean,
  final_response text, status text default 'received',
  created_at timestamptz default now()
);
create table public.escalations (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid, audit_log_id uuid, reason text,
  status text default 'open', created_at timestamptz default now()
);
create table public.customer_memory (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid, memory_type text, content text,
  metadata jsonb, embedding vector(1024),
  created_at timestamptz default now()
);
create table public.usage_events (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid, event_type text, quantity numeric, unit text,
  stripe_reported boolean default false, metadata jsonb,
  created_at timestamptz default now()
);
