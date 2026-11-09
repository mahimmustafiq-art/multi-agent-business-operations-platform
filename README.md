# Multi-Agent Business Operations Platform

An AI customer-operations system built with **n8n, Supabase, Stripe and LLMs**. A **Supervisor** routes each customer message to a **Sales**, **Support** or **Billing** agent. Each agent answers only from real data. A **second, independent AI call reviews every answer** before it is sent: approve, retry once, or escalate to a human.

> **Status: demo / portfolio project.** It was built and tested by its author, but it has not been deployed for a client and no business results are claimed. See [Limitations](#limitations).


> ## ⚠️ Security warning: read before exposing anything publicly
>
> This project has **four unauthenticated webhooks**. They are not the same thing:
>
> | Webhook | Path | Role | Risk |
> |---|---|---|---|
> | Supervisor (workflow `04`) | `POST /webhook/supervisor` | The intended public entry point. Every message goes through classification, review, audit log and escalation | Unauthenticated: anyone with the URL can submit messages and create usage events, tickets and quotes |
> | Specialist test webhooks (workflows `03`, `05`, `07`) | `/webhook/sales-agent-test`, `/webhook/support-agent-test`, `/webhook/billing-agent-test` | Direct testing of one specialist | Unauthenticated **and they bypass the Supervisor**: no second-AI review, no audit-log row, no escalation, no usage metering, no memory. They accept any customer UUID, so a caller who knows a UUID could request that customer's order or billing data, and the specialists can still create quotes and tickets |
>
> **Before any public exposure, remove or protect the three specialist test webhooks** (delete the `Webhook - Test ... Agent` node in `03`, `05` and `07` once testing is done, or enable authentication on it). Add authentication to the Supervisor webhook too. The specialists keep working without their test webhooks because the Supervisor calls them through *Execute Workflow*. Details: [docs/security-and-limitations.md](docs/security-and-limitations.md).


## The problem

Small shops and service businesses answer the same questions all day: prices, stock, order status, refunds, billing. A single chatbot answers fast, but it can invent prices, promise refunds it cannot grant, and leave no record of why it said what it said.

## The solution

```
Customer message -> Supervisor (validate, classify, audit, memory lookup)
   -> Sales | Support | Billing (separate sub-workflows)
   -> Supervisor self-critique (2nd LLM call)
        approved  -> reply + usage event + Stripe meter event
        retry     -> specialist runs once more with reviewer feedback
        escalate  -> row in `escalations` (human queue)
   -> interaction saved as per-customer long-term memory
```

![Architecture](diagrams/architecture.png)

Mermaid source: [`diagrams/architecture.mermaid`](diagrams/architecture.mermaid)

## What is implemented

| Feature | Notes |
|---|---|
| Intent classification | Groq LLM returns intent, confidence, reason. Below 0.6 confidence, or intent `human` / `unknown`, goes straight to a human |
| Sales agent | RAG over `products` (top 5 by vector similarity), recommendations, draft quotes. **Totals are calculated in code, never by the LLM** |
| Support agent | Reads only the customer's own orders. Complaints, refund requests and handoffs create `support_tickets`. Never approves, denies or estimates a refund |
| Billing agent | Reads subscription, usage, invoices and upcoming invoice from Stripe. Subscription changes and invoice requests become tickets |
| Self-critique | Second LLM call checks relevance, sufficiency, evidence support, no hallucination and business rules. Decision logic runs in code |
| Long-term memory | Each interaction is summarised, embedded (Mistral, 1024 dims) and stored per customer; top 5 are retrieved on the next message |
| Usage billing | Each approved answer writes a `usage_events` row and sends a Stripe meter event (`ai_request`) |
| Audit log | One `supervisor_audit_log` row per request with intent, route, critique, confidence, retries and outcome |
| Error isolation | Every specialist is its own workflow with its own error output; the Supervisor receives a structured failure instead of crashing |

## Repository structure

```
workflows/   Sanitized n8n exports (import into n8n)
database/    schema.sql (reconstructed) and functions.sql (RPC functions)
docs/        Architecture and per-agent documentation
diagrams/    Architecture PNG and Mermaid source
examples/    Sample requests (placeholders only)
portfolio/   7-slide portfolio carousel (PDF + PNG slides)
.env.example Values you must provide (stored as n8n credentials)
```

## Documentation

- [Architecture](docs/architecture.md)
- [Supervisor agent](docs/supervisor-agent.md)
- [Sales agent](docs/sales-agent.md)
- [Support agent](docs/support-agent.md)
- [Billing agent](docs/billing-agent.md)
- [RAG and knowledge retrieval](docs/rag-architecture.md)
- [Self-critique mechanism](docs/self-critique.md)
- [Stripe integration](docs/stripe-integration.md)
- [Database](docs/database.md)
- [Setup and configuration](docs/setup.md)
- [Security, accuracy and limitations](docs/security-and-limitations.md)

## Technology stack

| Layer | Tool |
|---|---|
| Orchestration | n8n (webhooks, Execute Workflow sub-workflows) |
| Database / vector store | Supabase Postgres + pgvector |
| LLM | Groq, model `openai/gpt-oss-20b` (classification, specialists, review) |
| Embeddings | Mistral `mistral-embed` (1024 dimensions) |
| Billing | Stripe Billing Meters, subscriptions, invoices (test mode) |

## Workflows

| File | Purpose |
|---|---|
| `02-product-ingestion` | `POST /product-ingest`: validates up to 50 products, creates embeddings, upserts by SKU |
| `03-sales-agent` | Product questions, recommendations, draft quotes |
| `04-supervisor` | Main entry `POST /supervisor`: classify, route, review, retry, escalate, audit, meter, remember |
| `05-support-agent` | Order status, complaints, refund requests, human handoff |
| `06-stripe-setup-run-once` | Creates the meter, product, metered price, Stripe customers and subscriptions |
| `07-billing-agent` | Reads Stripe subscription, usage and invoices |
| `01-...ARCHIVED` | Early routing-only draft, kept for history. Not part of the running system |

## Feature status: implemented, documented, tested

- **Implemented** = present in the workflow JSON files in this repository.
- **Test record** = the author's own written test notes. **No execution logs or screenshots are included**, so these results are recorded, not independently reproducible from this repository.

| Feature | Implemented | Test record |
|---|---|---|
| Intent classification, routing, escalation to human | Yes | Yes (author's notes) |
| Sales RAG, recommendations, draft quote | Yes | Yes (author's notes) |
| Support: order lookup, tickets, refund logging | Yes | Yes (author's notes) |
| Billing: Stripe lookups, change requests as tickets | Yes | Yes (author's notes) |
| Self-critique with one retry, then escalation | Yes | Yes (author's notes) |
| Long-term customer memory | Yes | No test record |
| Usage events and Stripe meter events | Yes | No test record |
| Specialist failure isolation (error outputs) | Yes | No test record |
| Webhook authentication | **No** | n/a |
| Refund policy or refund execution | **No** | n/a |

## Test results from the author's notes

These were recorded by the author during development (all through `POST /supervisor`). They are not reproduced automatically by this repository.

| Test | Recorded result |
|---|---|
| Product question | Approved, sales agent, 1 attempt |
| Quote for 5 units | `LM-MS-01 x 5 @ 24.99 = 124.95 USD`, draft quote saved |
| Refund request (ORD-1003) | Approved answer, ticket created, no refund promised |
| Cancel subscription | Ticket `subscription_change` created, nothing cancelled |
| "I want to talk to a human agent" | Escalated directly, 0 specialist attempts |
| Self-critique test (`test_mode: corrupt_all`) | Fake "30% discount" rejected twice, escalated to human |

## Limitations

- The Billing agent only **reads** from Stripe. Changes become tickets because no authorization rules are configured.
- No refund policy exists; refunds are ticket-only.
- **No webhook has authentication.** The three specialist test webhooks additionally bypass the Supervisor's review (see the security warning at the top). Do not expose any of them publicly without protection.
- A few fallback messages inside the workflows are in **Bengali** (each paired with an English sentence). See [Language note](#language-note).
- `04-supervisor` contains a **test-only `test_mode` hook** (`corrupt_first_attempt`, `corrupt_all`). It is inactive unless the request includes it. Remove it for production use.
- Specialist workflow IDs are hard-coded in the Supervisor and must be replaced after import.
- Usage is counted only for approved answers.
- Quotes have no duplicate check, so a retried sales answer can create a second draft.
- The `database/schema.sql` file is reconstructed from the project's documentation, not exported from a live database.
- Not load-tested.

## Language note

A few fallback messages inside the workflows are currently written in **Bengali**, each following an English sentence. They appear in: `03-sales-agent` (`Output - No Product Data`), `05-support-agent` (`Parse & Decide`, the "please share your order number" reply), `07-billing-agent` (`Output - No Billing Account`) and `04-supervisor` (`Prepare Escalation`, the human hand-off message). The LLM-written answers follow the customer's language. Edit the text in those nodes if you need another language.

## Quick start

See [docs/setup.md](docs/setup.md). Short version: create the Supabase tables and functions, add credentials in n8n, import the workflows, set the three workflow IDs in the Supervisor, ingest products, activate, and call `POST /webhook/supervisor`.

## Project Demo Video

Watch the full demonstration of the Multi-Agent Business Operations Platform:

[▶ Watch the Project Demo on YouTube](https://youtu.be/XajpSii3VII)

## Author

Khalid Mostafiq Mahim, AI automation specialist.

License: not yet specified.
