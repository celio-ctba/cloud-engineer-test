# Scenario 2 — Questions

Answer these questions in `answer-template/ANSWERS.md` under the Scenario 2 section.

---

## Question 2.1 — Pipeline Issues Identified

Review all configuration files in the `pipeline/` directory.

**What problems did you find in the pipeline configuration?**

Document each issue:

| Issue | File | Line/Section | Severity | Impact |
|-------|------|--------------|----------|--------|
| ... | ... | ... | ... | ... |

---

## Question 2.2 — Fixed Configurations

**Describe your fixes. Commit the corrected files.**

For each fix:
- What was the problem?
- How did you fix it?
- Why is this fix correct?

---

## Question 2.3 — Manual Approval Stage

Production deployments should require manual approval.

**How did you add the manual approval gate for production?**

Provide:
- The configuration change
- Who should be notified
- What information should the approver see
- Timeout policy

---

## Question 2.4 — ECS Task Definition Fixes

The task definition has issues that caused the incident in Scenario 1.

**What was wrong with the task definition? How did you fix it?**

Consider:
- Memory/CPU allocation
- Health check configuration
- Container image reference
- Environment variables
- Secrets management

---

## Question 2.5 — Rollback Strategy

A deployment has failed. You need to roll back.

**Describe the rollback procedure for a failed deployment.**

Include:
- How to trigger rollback
- What to verify after rollback
- How long rollback takes
- Communication during rollback

---

## Question 2.6 — Safe Deployment Flow

Document the complete deployment process from commit to production.

**Document the complete safe deployment flow.**

Include:
- Each stage and its purpose
- Approval gates
- Automated checks
- Rollback triggers
- Monitoring during deployment

---

## Bonus Questions

### Bonus 2.A — Blue/Green Deployment

The current pipeline uses rolling updates.

**How would you convert this to blue/green deployment?**

What are the tradeoffs?

### Bonus 2.B — Canary Deployment

**How would you implement canary deployments for this service?**

What percentage would you start with? How would you measure success?

### Bonus 2.C — Build Caching

CodeBuild is slow. 

**How would you speed up the build process?**

