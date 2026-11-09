# Setup and Configuration

You need accounts for n8n (cloud or self-hosted), Supabase, Groq, Mistral and Stripe (test mode). Free tiers or trials may have limits; check each provider.

## 1. Supabase

1. Create a project and enable pgvector: `create extension if not exists vector;`
2. In the SQL editor run `database/schema.sql`, then `database/functions.sql`.

## 2. n8n credentials

Create four credentials in n8n (never paste keys into workflow JSON):

| n8n credential type | Used for |
|---|---|
| Supabase API | all database calls |
| Groq API | LLM calls |
| Mistral Cloud API | embeddings |
| Stripe API | billing (test mode secret key) |

See `.env.example` for what each one needs.

## 3. Import workflows

Import in this order: `02-product-ingestion`, `03-sales-agent`, `05-support-agent`, `07-billing-agent`, then `04-supervisor`. Run `06-stripe-setup-run-once` once. Do not import the `01-...ARCHIVED` file.

After import, in **every** workflow:

- Open each credential field shown in red and select your credential (the exports contain the placeholder `YOUR_CREDENTIAL_ID`).
- In the `Config` node set `supabase_url` to your project URL (the export contains `https://YOUR-PROJECT-REF.supabase.co`).

In `04-supervisor`, open the code nodes `Prepare Specialist Call 1` and `Prepare Specialist Call 2` and replace `YOUR_SALES_AGENT_WORKFLOW_ID`, `YOUR_SUPPORT_AGENT_WORKFLOW_ID` and `YOUR_BILLING_AGENT_WORKFLOW_ID` with the IDs of your imported workflows (the ID is in each workflow's URL).

## 4. Stripe

Follow [stripe-integration.md](stripe-integration.md). Make sure customers exist before running workflow 06.

## 5. Add products

`POST /webhook/product-ingest` with a body like `examples/sample-product-ingest.json`.

## 6. Activate and test

Activate `03`, `05`, `07`, then `04`. Call `POST https://<your-n8n>/webhook/supervisor` (see `examples/requests.md`).

Webhooks have no authentication. Add one before exposing them to the internet.
