# Scenario 3 — Data and Messaging

## Situation

The development team wants to deploy a database schema change and you've been asked to review it. Additionally, messages are accumulating in the Dead Letter Queue (DLQ) and need to be handled.

## Database Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Aurora PostgreSQL Cluster                            │
│                        plooral-aurora-prod                                   │
│                                                                              │
│   ┌─────────────────────────────────┐   ┌─────────────────────────────────┐ │
│   │          Writer Instance        │   │         Reader Instance          │ │
│   │   plooral-aurora-prod-instance-1│   │  plooral-aurora-prod-instance-2 │ │
│   │                                 │   │                                  │ │
│   │   db.r6g.large                  │   │   db.r6g.large                  │ │
│   │   us-east-1a                    │   │   us-east-1b                    │ │
│   └─────────────────────────────────┘   └─────────────────────────────────┘ │
│                                                                              │
│   Storage: 500 GB                                                            │
│   Connections: 300 max                                                       │
│   Backup Retention: 7 days                                                   │
│   Performance Insights: Enabled                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Event Flow Architecture

```
┌────────────┐     ┌────────────┐     ┌────────────┐     ┌────────────┐
│  plooral-  │────▶│ EventBridge│────▶│    SNS     │────▶│    SQS     │
│    api     │     │  plooral-  │     │  plooral-  │     │  plooral-  │
│            │     │   events   │     │   notify   │     │   tasks    │
└────────────┘     └────────────┘     └────────────┘     └────────────┘
                                                               │
                                                               ▼
                                                         ┌────────────┐
                                                         │   Lambda   │
                                                         │  plooral-  │
                                                         │   worker   │
                                                         └────────────┘
                                                               │
                                                               ▼ (on failure)
                                                         ┌────────────┐
                                                         │  SQS DLQ   │
                                                         │  plooral-  │
                                                         │ tasks-dlq  │
                                                         └────────────┘
```

## Proposed Database Migration

The development team wants to run the following migration:

**File:** `artifacts/migration.sql`

This migration:
1. Adds new columns to the `users` table
2. Creates new indexes
3. Modifies an existing column constraint
4. Adds a new table

**Concerns:**
- The `users` table has 2.5 million rows
- Some queries involve `ALTER TABLE` which can lock the table
- The migration was written by a developer, not reviewed by a DBA
- They want to run it during business hours

## DLQ Situation

The Dead Letter Queue (`plooral-tasks-dlq`) has accumulated 234 messages following the incident in Scenario 1. These messages failed after 3 retry attempts.

**Sample messages are in:** `artifacts/sqs_dlq_messages.json`

## Available Artifacts

| File | Description |
|------|-------------|
| `migration.sql` | Proposed database migration script |
| `aurora_events.log` | Aurora database event log |
| `performance_insights_snapshot.json` | Performance Insights data |
| `sqs_dlq_messages.json` | Sample messages from the DLQ |
| `eventbridge_rules.json` | EventBridge rule configurations |

## Your Task

1. Review the migration for safety issues
2. Propose a safe rollout plan
3. Define monitoring requirements
4. Handle the DLQ messages appropriately
5. Recommend alarm adjustments

Answer the questions in `QUESTIONS.md`.

