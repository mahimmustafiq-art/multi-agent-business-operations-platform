# Support Agent (`05-support-agent`)

Triggers: *Execute Workflow* and `POST /webhook/support-agent-test`.

## Data access

Reads only the customer's own orders. If the message contains an order number (`ORD-` plus digits) it fetches that order; otherwise the latest 5 orders.

## Request types

`order_status`, `complaint`, `refund_request`, `human_handoff`, `general`.

## Rules enforced

- Never invents order status, tracking numbers, delivery dates or refund status.
- No refund policy is configured: the agent never approves, denies, promises or estimates a refund. It only says the request is recorded and passed to the team.
- A `refund_request` is accepted only if the named order exists in the customer's data; otherwise it asks for the order number.
- Complaints get an empathetic answer, no compensation promise, and are recorded.

## Tickets

Complaints, refund requests and handoffs create a `support_tickets` row (`pending_human_review` for refunds, `open` otherwise). Before inserting, the workflow looks for an existing open ticket of the same customer, type and order and reuses it, so duplicates are not created. The reply includes a short reference code derived from the ticket id.
