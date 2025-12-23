# Scenario 1 — P0 Incident Response

## Situation

You are on-call for the Plooral platform. At **14:17 UTC**, you receive a Slack notification in the `#prod-alerts` channel:

> 🚨 **[ALARM] plooral-api-p99-latency**
> P99 Latency > 2000ms for 5 minutes
> Region: us-east-1 | Severity: P0

Within the next 3 minutes, additional alarms fire in Slack:
- `plooral-api-5xx-rate` — 5xx error rate exceeds 1%
- `plooral-api-unhealthy-hosts` — ECS tasks failing health checks
- `plooral-tasks-queue-depth` — SQS queue depth > 10,000 messages
- `plooral-waf-block-spike` — WAF block rate increased 300%

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                 USERS                                        │
└─────────────────────────────────────┬───────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        CloudFront (CDN + WAF)                                │
│                     Distribution: E1A2B3C4D5E6F7                             │
│                     WAF WebACL: plooral-prod-waf                             │
└─────────────────────────────────────┬───────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                   Application Load Balancer                                  │
│                   ALB: plooral-api-prod-alb                                  │
│                   Target Group: plooral-api-prod-tg                          │
└─────────────────────────────────────┬───────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         ECS Cluster (Fargate)                                │
│                      Cluster: plooral-prod-cluster                           │
│                      Service: plooral-api                                    │
│                      Tasks: 3 (desired), currently 2 healthy                 │
│                                                                              │
│   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                     │
│   │   Task 1    │    │   Task 2    │    │   Task 3    │                     │
│   │  HEALTHY    │    │  HEALTHY    │    │ UNHEALTHY   │                     │
│   │  (v2.4.1)   │    │  (v2.4.1)   │    │ (v2.5.0)    │                     │
│   └─────────────┘    └─────────────┘    └─────────────┘                     │
└─────────────────────────────────────┬───────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Aurora PostgreSQL                                     │
│                    Cluster: plooral-aurora-prod                              │
│                    Writer: plooral-aurora-prod-instance-1                    │
│                    Reader: plooral-aurora-prod-instance-2                    │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │
        ┌─────────────────────────────┴─────────────────────────────┐
        │                                                           │
        ▼                                                           ▼
┌───────────────────┐                                   ┌───────────────────┐
│    EventBridge    │                                   │    SNS Topic      │
│  plooral-events   │                                   │plooral-notify-prod│
└────────┬──────────┘                                   └────────┬──────────┘
         │                                                       │
         ▼                                                       ▼
┌───────────────────┐                                   ┌───────────────────┐
│    SQS Queue      │                                   │    Lambda         │
│  plooral-tasks    │───────────────────────────────────│  plooral-worker   │
│  DLQ: plooral-    │                                   │                   │
│  tasks-dlq        │                                   │                   │
└───────────────────┘                                   └───────────────────┘

                     ┌─────────────────────────────────┐
                     │        CloudWatch Alarms        │
                     │              │                  │
                     │              ▼                  │
                     │    SNS → Lambda (Slack Bot)     │
                     │              │                  │
                     │              ▼                  │
                     │      Slack #prod-alerts         │
                     └─────────────────────────────────┘
```

## Recent Events

| Time (UTC) | Event |
|------------|-------|
| 13:45 | Sprint planning meeting ended |
| 14:00 | **Deployment started** — v2.5.0 of plooral-api |
| 14:05 | Deployment completed — 1 of 3 tasks running v2.5.0 |
| 14:08 | CloudFront cache miss rate starts increasing |
| 14:10 | Aurora connection count starts rising |
| 14:15 | First latency alarm fires (P99 > 2s) |
| 14:17 | **Slack alert received** — you're tagged in #prod-alerts |
| 14:18 | ECS health check failures begin |
| 14:20 | SQS queue depth alarm fires |
| 14:22 | WAF block rate alarm fires |

## Key Details

### Deployment (v2.5.0)
- Deployed via CodeDeploy (ECS rolling deployment)
- Change: New database query for user recommendations
- The query was not reviewed by DBA
- Rollback is available (v2.4.1 image exists)

### Current Metrics
- **Latency P99:** 4,200ms (normal: <500ms)
- **5xx Rate:** 3.2% (normal: <0.1%)
- **Healthy ECS Tasks:** 2 of 3
- **SQS Queue Depth:** 14,832 (normal: <100)
- **SQS Oldest Message:** 8 minutes
- **Aurora CPU:** 78% (normal: 25%)
- **Aurora Connections:** 285 (max: 300)

### WAF Observations
- Block rate from `ap-southeast-1` increased 400%
- Blocked requests contain legitimate-looking user agents
- Rule `plooral-rate-limit-rule` triggered most blocks

## Available Artifacts

Review the following files in `artifacts/`:

| File | Description |
|------|-------------|
| `alb_access.log` | ALB access logs around incident time |
| `cloudfront.log` | CloudFront access logs |
| `ecs_service.log` | ECS service events |
| `lambda.log` | Lambda function logs |
| `rds_slowquery.log` | Aurora slow query log |
| `sqs_metrics.json` | SQS CloudWatch metrics |
| `sns_notifications.log` | SNS delivery logs |
| `cloudwatch_alarms.json` | Current alarm states |
| `cloudwatch_metrics.json` | Key metrics snapshot |
| `waf_sample_requests.log` | Sample WAF blocked requests |

## Your Task

Analyze the situation and answer the questions in `QUESTIONS.md`.

**Remember:** This is a production incident. Safety first.

