# Stripe Integration

Use **test mode**. Stripe credentials are n8n credentials; no key is stored in the workflows.

## One-time setup (`06-stripe-setup-run-once`)

Creates, in order: a billing meter (`display_name` "AI Requests", `event_name` `ai_request`, aggregation `sum`, customer mapped by `stripe_customer_id`), a product, a metered monthly price (USD, 5 cents per request, lookup key `ai_request_usage_monthly`), then for each Supabase customer without a Stripe id: a Stripe customer (placeholder email `<external_id>@example.com`) and a subscription with `collection_method: send_invoice`, due in 30 days. IDs are written back to `customers`. Each step uses an idempotency key.

## Usage reporting (Supervisor)

Each approved answer inserts a `usage_events` row (`ai_request`, quantity 1), then sends a Stripe meter event whose `identifier` is the usage event id, and marks the row `stripe_reported`. Escalated answers are not counted. Usage can take a few minutes to appear in Stripe.

## Lookups (Billing agent)

Read-only: subscription, meter usage summary, invoices, upcoming-invoice preview. No write actions exist.

Customers added later need their Stripe customer and subscription created by re-running the customer part of workflow 06.
