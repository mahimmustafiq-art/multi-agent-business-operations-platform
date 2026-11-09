# Example requests (placeholders only)

```bash
export N8N_URL="https://your-n8n-instance.example.com"

# Product question
curl -X POST "$N8N_URL/webhook/supervisor" -H "Content-Type: application/json" \
  -d '{"customer_id":"cust_001","customer_name":"Demo Customer","message":"Do you have a wireless mouse?"}'

# Quote (totals calculated by code)
curl -X POST "$N8N_URL/webhook/supervisor" -H "Content-Type: application/json" \
  -d '{"customer_id":"cust_001","message":"I need a quote for 5 units of Lumio Silent Wireless Mouse"}'

# Refund request (needs an existing order on the account)
curl -X POST "$N8N_URL/webhook/supervisor" -H "Content-Type: application/json" \
  -d '{"customer_id":"cust_001","message":"I want a refund for order ORD-1003"}'

# Self-critique demonstration (test hook)
curl -X POST "$N8N_URL/webhook/supervisor" -H "Content-Type: application/json" \
  -d '{"customer_id":"cust_001","message":"Do you have a wireless mouse?","test_mode":"corrupt_all"}'

# Product ingestion
curl -X POST "$N8N_URL/webhook/product-ingest" -H "Content-Type: application/json" -d @sample-product-ingest.json
```

`cust_001` is an example external customer id. Order `ORD-1003` must exist in your own `orders` table.
