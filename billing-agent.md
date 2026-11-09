# Billing Agent (`07-billing-agent`)

Triggers: *Execute Workflow* and `POST /webhook/billing-agent-test`.

## Data access (Stripe, read-only)

Requires `stripe_customer_id` on the customer. Without it, the agent declines to share billing data. Otherwise it reads:

- the subscription (status, plan, unit price, period, cancel-at-period-end)
- the `ai_request` meter and its usage summary for the current period
- the 5 most recent invoices
- the upcoming-invoice preview

Every Stripe object is checked to belong to the same customer before it is used. Values that cannot be read are marked `NOT AVAILABLE`.

## Request types

`usage_lookup`, `invoice_lookup`, `subscription_lookup`, `subscription_change`, `invoice_request`, `human_handoff`, `general`.

## Rules enforced

- Never invents usage, amounts, invoice numbers, status or any billing fact; quotes numbers exactly as read.
- Cannot change subscriptions, cancel plans, send invoices, apply credits or refunds. Such requests become `support_tickets` for human review (duplicates are detected and reused).
