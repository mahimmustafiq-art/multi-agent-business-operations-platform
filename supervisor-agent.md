# Supervisor Agent (`04-supervisor`)

Entry: `POST /webhook/supervisor` with `{"customer_id": "...", "customer_name": "...", "message": "..."}`. `customer_id` here is your external customer identifier; the Supervisor maps it to the customer UUID in Supabase.

## Responsibilities

| Step | Behaviour |
|---|---|
| Classify | Groq LLM returns `intent` (sales, support, billing, human, unknown), `confidence`, `reason` |
| Route | sales -> Sales, support -> Support, billing -> Billing; human/unknown or confidence < 0.6 -> human escalation |
| Memory | Retrieves the customer's top 5 similar memories and passes them as background only |
| Review | Second LLM call evaluates the specialist answer (see [self-critique](self-critique.md)) |
| Decide | Approve, retry once with reviewer feedback, or escalate. Maximum 2 attempts |
| Audit | One `supervisor_audit_log` row per request |
| Meter | Approved answers create a `usage_events` row and a Stripe meter event |
| Remember | Saves a short interaction summary as embedded memory |

## Response

Approved: `status: approved`, `response`, `intent`, `specialist`, `confidence`, `attempts`, `retried`, `needs_human`, `ticket_reference`, `critique`, `audit_log_id`, `memory_count`.

Escalated: `status: escalated`, a hand-off message, `reason`, `escalation_id`.

## Test hook

The workflow accepts an optional `test_mode` (`corrupt_first_attempt`, `corrupt_all`). It appends a fake discount line to specialist answers to demonstrate that the reviewer rejects them. Inactive unless sent; remove the "Test Hook" nodes for production.
