# Scenario 5 — Requirements

## Deliverables

You must create two documents in the `answer-template/` directory:

### 1. RUNBOOK.md

Create a comprehensive operational runbook at `answer-template/RUNBOOK.md`.

**Required Sections:**

#### 1.1 Incident Response Playbooks

- [ ] P0 Incident Response (complete outage)
- [ ] P1 Incident Response (degraded service)
- [ ] P2 Incident Response (non-critical issue)
- [ ] Escalation matrix (when to escalate, to whom)
- [ ] Communication templates (internal and external)
- [ ] Post-incident review process

#### 1.2 Deployment Procedures

- [ ] Pre-deployment checklist
- [ ] Production deployment steps
- [ ] Post-deployment verification
- [ ] Rollback procedure (step-by-step)
- [ ] Hotfix deployment process
- [ ] Deployment freeze policy

#### 1.3 ECS Troubleshooting

- [ ] Service not starting
- [ ] Tasks failing health checks
- [ ] Container OOM errors
- [ ] Deployment stuck in progress
- [ ] Scaling issues

#### 1.4 Lambda Troubleshooting

- [ ] Function timeouts
- [ ] Concurrency limits
- [ ] Permission errors
- [ ] Cold start optimization
- [ ] DLQ handling

#### 1.5 Aurora / RDS Troubleshooting

- [ ] Connection exhaustion
- [ ] Slow queries
- [ ] Replication lag
- [ ] Storage issues
- [ ] Failover handling

#### 1.6 SQS Troubleshooting

- [ ] Queue backlog
- [ ] DLQ accumulation
- [ ] Message processing failures
- [ ] Visibility timeout issues

#### 1.7 CloudFront / WAF Troubleshooting

- [ ] Cache invalidation
- [ ] Origin errors
- [ ] WAF false positives
- [ ] Certificate issues

#### 1.8 Alarm Response Guide

For each major alarm, document:
- What the alarm indicates
- First response actions
- Escalation criteria
- Resolution verification

#### 1.9 Access Management

- [ ] Granting AWS console access
- [ ] Revoking access (offboarding)
- [ ] Emergency access procedures
- [ ] Key rotation procedures

---

### 2. ONBOARDING_30_DAYS.md

Create a 30-day onboarding plan at `answer-template/ONBOARDING_30_DAYS.md`.

**Required Sections:**

#### 2.1 Week 1: Shadowing (Days 1-7)

- [ ] Day-by-day activities
- [ ] Systems to get access to
- [ ] Key meetings to attend
- [ ] Documentation to read
- [ ] Questions to ask the team
- [ ] Pair programming sessions

#### 2.2 Week 2: Guided Operations (Days 8-14)

- [ ] First supervised deployment
- [ ] First on-call shift (backup role)
- [ ] Incident response observation
- [ ] Database operations practice
- [ ] Monitoring review

#### 2.3 Week 3: Independent Operations (Days 15-21)

- [ ] Solo deployment (with review)
- [ ] Primary on-call rotation
- [ ] Incident commander training
- [ ] Runbook validation
- [ ] Security review

#### 2.4 Week 4: Full Ownership (Days 22-30)

- [ ] Full ownership transition
- [ ] Emergency procedures drill
- [ ] Vendor contact verification
- [ ] Final knowledge transfer
- [ ] Team support and escalation plan

#### 2.5 Milestones

Define specific, measurable milestones:

| Milestone | Due | Success Criteria |
|-----------|-----|------------------|
| ... | ... | ... |

#### 2.6 Exit Criteria

List the criteria that must be met before you are fully operational:

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] ...

#### 2.7 Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| ... | ... | ... | ... |

#### 2.8 Contingency Plan

What happens if key team members are unavailable during your onboarding?

---

## Evaluation Criteria

Your runbook and onboarding documents will be evaluated on:

| Criterion | Weight |
|-----------|--------|
| **Completeness** — All required sections present | 25% |
| **Actionability** — Steps are specific and executable | 25% |
| **Clarity** — Easy to follow under pressure | 20% |
| **Safety** — Includes verification and rollback | 15% |
| **Realism** — Appropriate for the Plooral platform | 15% |

## Tips

1. **Be specific** — "Check the logs" is not helpful; "Check CloudWatch log group `/ecs/plooral-api` for the last 15 minutes" is.

2. **Think about pressure** — During an incident, people can't read paragraphs. Use checklists and short steps.

3. **Include verification** — After each action, how do you verify it worked?

4. **Plan for failure** — What if Step 3 doesn't work? What's the fallback?

5. **Be realistic** — Base your runbook on what you've learned in Scenarios 1-4.

