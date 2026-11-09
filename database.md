# Database (Supabase)

Nine tables in `public`; primary keys are `uuid` (`gen_random_uuid()`); vector columns are pgvector `vector(1024)`.

| Table | Purpose |
|---|---|
| `customers` | One row per customer; holds Stripe ids |
| `products` | Catalogue with embedding for RAG |
| `orders` | Customer orders (read by Support) |
| `quotes` | Draft quotes created by Sales |
| `support_tickets` | Complaints, refund requests, handoffs, billing change requests |
| `supervisor_audit_log` | One row per request: intent, route, critique, confidence, outcome |
| `escalations` | Human queue |
| `customer_memory` | Per-customer embedded memories |
| `usage_events` | Billable usage and Stripe reporting flag |

> `database/schema.sql` is **reconstructed** from the project documentation (column names, requirements and defaults as documented; data types inferred from how the workflows use them). It is not an export of a live database. Foreign keys, indexes and row-level security are not part of the original documentation and are not included. Add them for production use.

Run `schema.sql` first, then `functions.sql` in the Supabase SQL editor.
