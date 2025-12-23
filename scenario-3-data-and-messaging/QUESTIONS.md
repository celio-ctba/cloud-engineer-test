# Scenario 3 — Questions

Answer these questions in `answer-template/ANSWERS.md` under the Scenario 3 section.

---

## Question 3.1 — Migration Risk Assessment

Review `artifacts/migration.sql` carefully.

**What risks do you see in the proposed migration?**

For each risk:

| Risk | Severity (Critical/High/Medium/Low) | Mitigation |
|------|-------------------------------------|------------|
| ... | ... | ... |

Consider:
- Table locking implications
- Index creation on large tables
- Data integrity constraints
- Rollback complexity
- Performance impact

---

## Question 3.2 — Safe Rollout Plan

The team wants to run this migration during business hours.

**How would you safely execute this migration?**

Include:
- Pre-migration checklist
- Step-by-step execution plan
- Rollback procedure
- Success criteria
- Communication plan

---

## Question 3.3 — Monitoring During Migration

**What do you monitor during the migration? What thresholds trigger rollback?**

Define:
- Key metrics to watch
- Threshold values that indicate problems
- Rollback triggers
- How long to monitor post-migration

---

## Question 3.4 — DLQ Handling

There are 234 messages in the Dead Letter Queue.

**How do you handle the messages in the DLQ?**

Consider:
- Should all messages be reprocessed?
- How do you determine which messages are safe to retry?
- What order should they be processed?
- How do you prevent duplicate actions?
- When should messages be discarded?

---

## Question 3.5 — Alarm Adjustments

After reviewing the current EventBridge rules and SQS configuration:

**What alarm changes do you recommend?**

Consider:
- Are current thresholds appropriate?
- What new alarms should be added?
- What alerting gaps exist?

---

## Bonus Questions

### Bonus 3.A — Zero-Downtime Migration

**How would you restructure this migration to achieve zero-downtime?**

Describe the expand-contract pattern or other techniques.

### Bonus 3.B — Event Replay

If you needed to replay all events from the last 24 hours:

**How would you do this? What's your strategy?**

### Bonus 3.C — Aurora Failover

During a migration, the Aurora writer instance fails over to the reader.

**What happens to your migration? How do you handle this?**

