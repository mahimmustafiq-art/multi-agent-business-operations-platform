# Security, Accuracy and Limitations

## ⚠️ Unauthenticated webhooks (important)

Four webhooks exist and **none has authentication configured**. They differ in what they allow.

### 1. Supervisor webhook: `POST /webhook/supervisor` (workflow `04-supervisor`)

The intended public entry point. Messages pass through classification, the second-AI review, the audit log, escalation, usage metering and memory. Without authentication, anyone who has the URL can submit messages, which can create `usage_events`, tickets, quotes and escalations for the customer id they send, and consume your LLM and Stripe-meter calls. **Add authentication** (for example Header Auth on the Webhook node) or place it behind an authenticated gateway before public use.

### 2. Specialist test webhooks: workflows `03`, `05`, `07`

| Webhook | Workflow |
|---|---|
| `POST /webhook/sales-agent-test` | `03-sales-agent` |
| `POST /webhook/support-agent-test` | `05-support-agent` |
| `POST /webhook/billing-agent-test` | `07-billing-agent` |

These call one specialist directly and **bypass the Supervisor**. That means: no second-AI review of the answer, no `supervisor_audit_log` row, no escalation path, no usage metering and no memory. They accept any customer UUID in the request, so a caller who knows or guesses a UUID could ask for that customer's orders (support) or Stripe billing data (billing). The specialists also still perform their own writes: draft quotes (sales) and support tickets (support, billing).

**They must be removed or protected before public exposure.**

- Recommended: after testing, delete the node `Webhook - Test Sales Agent`, `Webhook - Test Support Agent` and `Webhook - Test Billing Agent` from `03`, `05` and `07`. The Supervisor does not use these nodes; it calls the specialists through *Execute Workflow*, so the system keeps working.
- Alternative: enable authentication on each of those Webhook nodes.
- A workflow that is *activated* in n8n exposes its production webhook URL. Keep these workflows inactive until protected, or use n8n's test URLs only while developing.

This repository's workflow exports are set to `active: false`.

### 3. Test-only hook inside the Supervisor

`04-supervisor` accepts an optional `test_mode` value (`corrupt_first_attempt`, `corrupt_all`) that appends a fake discount line to specialist answers to demonstrate the reviewer. It is inactive unless sent. Remove the nodes `Test Hook 1 (test only)` and `Test Hook 2 (test only)` for production.

## Language note

A few fallback messages in the workflows are written in **Bengali** (each follows an English sentence): `03-sales-agent` (`Output - No Product Data`), `05-support-agent` (`Parse & Decide`, the order-number request), `07-billing-agent` (`Output - No Billing Account`), `04-supervisor` (`Prepare Escalation`, the hand-off message). They were intentionally left unchanged. The LLM-written answers follow the customer's language.

## What was sanitized in this repository

The Supabase project URL, n8n credential IDs, the n8n instance ID, workflow IDs, version IDs and webhook IDs were replaced or removed. All workflows are exported with `active: false`. No API keys, tokens or passwords were present in the exports; credentials are referenced through n8n credential objects. No customer data or database dump is included.

## Do not commit

API keys, Supabase service-role keys, Stripe secret keys, real customer data, or real exports from your own instance without scanning them first.

## Implemented, documented, recorded as tested

| Status | Meaning | Items |
|---|---|---|
| Implemented | Present in the workflow JSON files | Everything in the README's "What is implemented" table |
| Recorded as tested | The author's written test notes; no logs or screenshots are included | Product question, quote (5 units), refund request, subscription cancel request, human hand-off, self-critique with `test_mode` |
| Implemented, no test record | Present, but no test notes exist | Long-term memory, usage and Stripe meter events, specialist failure isolation |
| Not implemented | Absent | Webhook authentication, refund policy or refund execution, subscription changes or invoice sending, quote duplicate protection, load testing, foreign keys and row-level security in the documented schema |
| Illustrative only | Not real data or screenshots | Sample product and requests in `examples/`; diagrams and the carousel workflow maps |

## Limitations

See the README Limitations section. In addition, `database/schema.sql` is reconstructed from documentation and has no foreign keys, indexes or row-level security.
