# Scenario 1 — Questions

Answer these questions in `answer-template/ANSWERS.md` under the Scenario 1 section.

---

## Question 1.1 — First 10 Minutes

You've just been paged. You have 10 minutes before the next escalation tier is notified.

**What are your first 10-minute actions?**

Consider:
- What do you check first and why?
- What information do you need to gather?
- Who do you communicate with?
- What do you NOT do yet?

---

## Question 1.2 — Alarm Correlation

Multiple alarms fired in quick succession. Review the `cloudwatch_alarms.json` file.

**How do you correlate these alarms? What story do they tell?**

Consider:
- Which alarm is the leading indicator?
- Which alarms are symptoms vs. causes?
- Are any alarms misleading or red herrings?

---

## Question 1.3 — Hypothesis Ranking

Based on your analysis of the artifacts, list your hypotheses for the root cause.

**Rank your hypotheses from most to least likely. Explain your reasoning.**

Format your answer as:

| Rank | Hypothesis | Supporting Evidence | Against Evidence |
|------|------------|---------------------|------------------|
| 1 | ... | ... | ... |
| 2 | ... | ... | ... |
| 3 | ... | ... | ... |

---

## Question 1.4 — Immediate Mitigation

It's now 14:25 UTC. You need to stop the bleeding.

**What immediate mitigation steps do you take? In what order?**

For each step:
- What action do you take?
- What is the expected outcome?
- What could go wrong?
- How do you verify success?

---

## Question 1.5 — Permanent Fix

After the incident is mitigated, you need to ensure it doesn't happen again.

**What is the root cause? What permanent fix do you propose?**

Consider:
- What code/config changes are needed?
- What process changes are needed?
- What guardrails should be added?

---

## Question 1.6 — Postmortem

The incident is resolved. You need to write a postmortem.

**Provide an outline of the postmortem document.**

Include:
- Timeline
- Impact summary
- Root cause analysis
- Contributing factors
- Action items (with owners and due dates)
- Lessons learned

---

## Bonus Questions

### Bonus 1.A — WAF False Positives

The WAF blocked legitimate traffic from `ap-southeast-1`. 

**How do you handle this without disabling the WAF entirely?**

### Bonus 1.B — SQS Queue Backlog

After the incident, there are 15,000+ messages in the SQS queue.

**How do you safely process this backlog? What's your strategy?**

### Bonus 1.C — Aurora Connection Exhaustion

The connection pool nearly exhausted (285/300).

**What changes would you make to prevent this in the future?**

