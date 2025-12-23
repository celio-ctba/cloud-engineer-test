# AWS DevOps Challenge

## Purpose

This practical challenge evaluates **AWS operational maturity** and your ability to own production infrastructure.

You are stepping into a production environment with existing infrastructure. Your task is to demonstrate that you can **analyze, troubleshoot, and improve** the platform while ensuring **safe, reliable operations**.

---

## The Scenario

**Plooral** is a SaaS platform running on AWS with the following stack:

- **Edge:** CloudFront + WAF
- **Compute:** ECS (Fargate), Lambda
- **Data:** Aurora PostgreSQL
- **Messaging:** SQS, SNS, EventBridge
- **CI/CD:** CodePipeline, CodeBuild, CodeDeploy
- **Observability:** CloudWatch metrics/alarms, X-Ray

The platform has logs, configs, and partial documentation. Your job is to analyze, fix, and document what's needed for safe, reliable operations.

---

## What You Must Do

### 1. Fork & Clone
```bash
# Fork this repository to your own GitHub account
# Clone your fork
git clone https://github.com/YOUR_USERNAME/aws-devops-challenge.git
cd aws-devops-challenge

# Create a working branch
git checkout -b submission
```

### 2. Complete All Scenarios

| Scenario | Focus Area | Time Estimate |
|----------|------------|---------------|
| [Scenario 1](scenario-1-incident-response/) | P0 Incident Triage | 60–90 min |
| [Scenario 2](scenario-2-cicd-and-deployments/) | CI/CD & ECS Deployments | 45–60 min |
| [Scenario 3](scenario-3-data-and-messaging/) | Data & Messaging | 45–60 min |
| [Scenario 4](scenario-4-security-and-edge/) | Security, IAM, Edge | 45–60 min |
| [Scenario 5](scenario-5-runbook-and-handover/) | Runbook & Onboarding Plan | 60–90 min |

### 3. Submit Your Work

1. Complete `answer-template/ANSWERS.md`
2. Commit any corrected configs (fixed JSON/YAML files)
3. Create required runbook and onboarding documents
4. Add optional diagrams (Mermaid format)
5. Push your branch to **your fork**
6. **Send us the link to your repository**

> ⚠️ **Important:** Do NOT open a Pull Request against the original repository. Complete all work in your own fork and share the repository link with us.

---

## What to Submit

| Deliverable | Required | Location |
|-------------|----------|----------|
| Completed answers | ✅ | `answer-template/ANSWERS.md` |
| Corrected configs | ✅ | In-place fixes to scenario artifacts |
| Runbook | ✅ | `answer-template/RUNBOOK.md` |
| 30-day onboarding plan | ✅ | `answer-template/ONBOARDING_30_DAYS.md` |
| Architecture diagrams | Optional | `answer-template/diagrams/` |

---

## Allowed Resources

| Resource | Allowed? |
|----------|----------|
| AWS Documentation | ✅ Yes |
| Internet search | ✅ Yes |
| AI assistants | ✅ Yes |
| Colleagues / pair work | ❌ No |

> **Important:** All reasoning must be **explicit and documented**. We evaluate your thought process, not just the answer.

---

## Evaluation Criteria

We assess your work on:

| Criterion | What We Look For |
|-----------|------------------|
| **Safety** | Do you avoid making things worse? |
| **Clarity** | Is your reasoning easy to follow? |
| **Operational Judgment** | Do you prioritize correctly under pressure? |
| **Rollback Thinking** | Do you plan for failure? |
| **Least Privilege** | Are your security decisions minimal and correct? |
| **Communication** | Could another engineer follow your work? |

Your submission will be reviewed by our team based on these criteria.

---

## Explicit "Do NOT" List

❌ **Do not** rewrite everything from scratch — focus on targeted fixes  
❌ **Do not** hand-wave — vague answers score zero  
❌ **Do not** invent AWS behavior — state assumptions explicitly  
❌ **Do not** skip the reasoning — "just trust me" is not acceptable  
❌ **Do not** over-engineer — production stability beats elegance  

---

## Time Expectation

**Total:** 4–6 hours

This is not a speed test. We value **thorough, safe, well-documented** work over rushing through.

---

## Questions?

If something is genuinely ambiguous, document your assumption and proceed. Real incidents don't wait for clarification.

Good luck. Show us you can own this.

