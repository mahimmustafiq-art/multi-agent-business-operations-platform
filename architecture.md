# Architecture

## Components

- **Supervisor** (`04-supervisor`): single entry point `POST /webhook/supervisor`.
- **Specialists** (`03`, `05`, `07`): separate workflows called through *Execute Workflow*. They share one input/output contract.
- **Supabase**: Postgres tables plus pgvector similarity search (two RPC functions).
- **Groq**: LLM for classification, specialist answers and review.
- **Mistral**: embeddings for products and customer memory.
- **Stripe**: usage meter, subscription and invoices.

## Request flow (Supervisor)

1. Validate input (`customer_id` and `message` required; message max 4000 characters). Invalid input returns HTTP 400.
2. Upsert the customer by `external_id`.
3. Classify intent with the LLM (temperature 0). Confidence below 0.6, or intent `human`/`unknown`, routes to human escalation.
4. Insert an audit-log row (`status: classified`).
5. Embed the message and retrieve the customer's top 5 memories.
6. Call the selected specialist (attempt 1) and collect the result. A specialist failure becomes a structured error result.
7. Run the self-critique (second LLM call) and decide in code: approve, retry once, or escalate.
8. Approved: update audit log, write a usage event, send the Stripe meter event, save memory, respond.
9. Escalated: insert an `escalations` row, update audit log, save memory, respond with a hand-off message.

## Specialist contract

Input: `customer_id` (customer UUID), `message`, `intent`, `memory`, `context` (reviewer feedback on retry).

Output: `success`, `response`, `confidence`, `data` (including `data.evidence`), `needs_human`, `error`, `agent`.

`data.evidence` carries the records the answer was based on so the reviewer can verify it.

## Error handling

- Each specialist has its own error output that returns `success: false, needs_human: true`.
- LLM and embedding HTTP calls retry up to 3 times (memory embedding up to 2).
- Database failures return HTTP 500 with a generic message.

Diagram: [../diagrams/architecture.png](../diagrams/architecture.png)
