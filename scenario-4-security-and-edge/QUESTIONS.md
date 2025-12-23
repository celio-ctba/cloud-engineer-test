# Scenario 4 — Questions

Answer these questions in `answer-template/ANSWERS.md` under the Scenario 4 section.

---

## Question 4.1 — IAM Policy Issues

Review `artifacts/iam_policy.json` carefully.

**What problems exist in the IAM policies? How did you fix them?**

For each issue:

| Issue | Risk Level | Fix Applied | Justification |
|-------|------------|-------------|---------------|
| ... | ... | ... | ... |

Consider:
- Wildcard usage in actions
- Wildcard usage in resources
- Missing condition keys
- Overly broad permissions
- Principle of least privilege

---

## Question 4.2 — Trust Relationship Explanation

Review `artifacts/iam_trust_policy.json`.

**Explain the trust relationships. Are they correct?**

For each role:
- Who/what can assume this role?
- Is this appropriate?
- What risks exist?
- What improvements would you make?

---

## Question 4.3 — WAF Improvements

The WAF is blocking legitimate traffic from Asia-Pacific.

**What WAF rule changes do you recommend?**

Consider:
- How to reduce false positives
- How to maintain security
- Rate limiting configuration
- Geo-blocking alternatives
- Rule priority ordering

---

## Question 4.4 — SSM Parameter Security

Review `artifacts/ssm_parameters.json`.

**How should the SSM parameters be secured?**

Consider:
- Which parameters should be SecureString?
- KMS key management
- Access policies
- Parameter hierarchy
- Rotation strategy

---

## Question 4.5 — CloudFront Configuration Review

Review `artifacts/cloudfront_distribution.json`.

**Review the CloudFront config. What issues or improvements do you see?**

Consider:
- Security headers
- Cache behavior
- Origin configuration
- TLS settings
- Logging configuration

---

## Bonus Questions

### Bonus 4.A — Cross-Account Access

A partner company needs read-only access to some S3 buckets.

**How would you securely configure this?**

### Bonus 4.B — Secrets Rotation

The database password needs to be rotated.

**What is your rotation strategy? How do you avoid downtime?**

### Bonus 4.C — Security Incident Response

You detect unusual API activity from an internal IP.

**What is your immediate response? What do you investigate?**

