# Self-Critique Mechanism

After every specialist answer the Supervisor makes a **second LLM call** (temperature 0). It receives the customer message, the specialist answer, system-computed data (for example the ticket reference) and the verified evidence records.

## Checks

relevant, sufficient, supported by evidence, no hallucination, business rules followed. Business rules differ per specialist (for example: no discounts in sales, no refund promises in support, no invented billing values).

## Output

`approved`, `confidence`, `reason`, `needs_retry`, `needs_human`, `checks{}`.

## Decision logic (in code, not in the prompt)

| Condition | Decision |
|---|---|
| Approved, confidence >= 0.7, no human needed | approve |
| Specialist failed, attempt 1 | retry |
| Not approved, attempt 1 | retry once, with the reviewer's reason as feedback |
| Reviewer requests a human, or its output is unreadable | escalate |
| Still insufficient after attempt 2 | escalate |

Maximum 2 attempts. The reviewer result and decision are stored in `supervisor_audit_log.critique`.

## Proof test

With `test_mode: corrupt_all` a fake "30% discount and free express shipping" line is appended to every answer. In the author's test the reviewer rejected both attempts and the case reached the `escalations` table.
