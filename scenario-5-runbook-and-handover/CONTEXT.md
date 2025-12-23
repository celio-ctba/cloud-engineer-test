# Scenario 5 — Runbook and Onboarding

## Situation

You've joined the team as the new DevOps engineer for the Plooral platform. The existing documentation is incomplete, and you need to create operational documentation that will enable **safe, consistent operations** across the team.

## Current Documentation State

The existing documentation includes:
- Some scattered notes in Confluence (incomplete)
- A few bash scripts in their home directory
- Tribal knowledge not written down
- No formal runbooks
- No incident response procedures
- No on-call documentation

## What You Must Create

### 1. RUNBOOK.md

A comprehensive operational runbook that covers:

#### Incident Response Playbooks
- How to respond to P0/P1/P2 incidents
- Escalation procedures
- Communication templates
- Rollback procedures

#### Deployment Procedures
- How to deploy to production safely
- Pre-deployment checklist
- Post-deployment verification
- Rollback procedures

#### Troubleshooting Guides
- ECS service issues
- Lambda function failures
- Aurora database problems
- SQS queue backups
- CloudFront / WAF issues

#### Alarm Response
- What each alarm means
- How to respond to each alarm
- When to escalate
- Common false positives

#### Access Management
- How to grant/revoke access
- IAM role management
- Emergency access procedures

### 2. ONBOARDING_30_DAYS.md

A 30-day onboarding plan that includes:

#### Week 1: Shadowing
- What to observe
- Key meetings to attend
- Systems to get access to
- Questions to ask

#### Week 2: Guided Operations
- First deployments with supervision
- First on-call shift (backup)
- First incident response (observer)

#### Week 3: Independent Operations
- Solo deployments
- Primary on-call
- Incident commander role

#### Week 4: Full Ownership
- Emergency procedures
- Vendor contacts
- Escalation paths
- Final knowledge transfer

#### Milestones & Exit Criteria
- What skills must be demonstrated
- What documentation must be complete
- How to verify readiness
- Risk assessment

## Platform Summary

For reference, the Plooral platform consists of:

| Component | Technology | Key Details |
|-----------|------------|-------------|
| API | ECS Fargate | 3 tasks, Node.js |
| Worker | Lambda | Event-driven, Python |
| Database | Aurora PostgreSQL | Writer + Reader |
| CDN | CloudFront | Global distribution |
| WAF | AWS WAF | Attached to CloudFront |
| Messaging | SQS, SNS, EventBridge | Async processing |
| CI/CD | CodePipeline | GitHub → Build → Deploy |
| Secrets | SSM Parameter Store | SecureString |
| Monitoring | CloudWatch | Alarms → SNS → Slack (#prod-alerts) |

## Key Contacts (Fictional)

| Role | Contact | Responsibility |
|------|---------|----------------|
| Engineering Manager | eng-manager@plooral.com | Escalation for business decisions |
| Platform Lead | platform-lead@plooral.com | Technical escalation |
| Security Team | security@plooral.com | Security incidents |
| AWS TAM | aws-tam@plooral.com | AWS support escalation |
| Slack Admin | slack-admin@plooral.com | Slack workspace & alerting channels |

## Your Task

Create the two documents specified in `REQUIREMENTS.md`.

These documents should be practical, actionable, and enable someone with AWS knowledge to safely operate the platform after reviewing them.

