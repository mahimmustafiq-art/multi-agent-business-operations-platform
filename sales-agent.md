# Sales Agent (`03-sales-agent`)

Triggers: *Execute Workflow* (from the Supervisor) and `POST /webhook/sales-agent-test` (direct testing).

## Flow

1. Validate: `message` required, `customer_id` must be a customer UUID.
2. Embed the message (Mistral) and call `match_products` (top 5).
3. If no products are found, return a "not enough verified information" answer with confidence 0.2.
4. Build a prompt from the product data only. Missing values are marked `NOT AVAILABLE`.
5. LLM returns JSON: `response`, `confidence`, `used_skus`, `quote_request`.
6. Code validates SKUs against the retrieved products.

## Rules enforced

- Never invent products, prices, availability, discounts, specifications or quote values.
- No discount data exists, so discounts are never mentioned.
- Customer memory is background only, never a source of product facts.

## Quotes

The LLM only returns SKU and quantity. **Code** calculates `price x quantity` and the total. A quote is saved (`status: draft`) only if every line has a price, a currency and `in_stock = true`, quantity is 1 to 1000, and currencies do not mix. Otherwise the answer notes why no quote was created and confidence is capped at 0.5.
