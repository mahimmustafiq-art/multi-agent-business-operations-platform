# RAG and Knowledge Retrieval

Two retrieval uses, both with Mistral `mistral-embed` (1024 dimensions) and pgvector cosine distance.

## Product knowledge (Sales agent)

- **Ingestion** (`02-product-ingestion`): each product's text (name, category, description, specs) is embedded and upserted into `products.embedding` by SKU.
- **Retrieval**: the customer message is embedded and `match_products(query_embedding, match_count := 5)` returns the closest products with `similarity`.
- **Grounding**: only those records go into the prompt. The reviewer later checks the answer against the same records (`data.evidence`).

## Customer memory (Supervisor)

- After each interaction a short summary is embedded and stored in `customer_memory`.
- On a new message `match_customer_memory(query_embedding, p_customer_id, match_count := 5)` returns that customer's closest memories. The function filters by `customer_id`, so one customer's memory cannot be returned for another.
- Memory is background context only. It is never accepted as a source for prices, stock, order status or billing facts.

SQL: [../database/functions.sql](../database/functions.sql)
