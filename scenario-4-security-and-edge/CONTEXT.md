# Scenario 4 — Security and Edge

## Situation

You've been asked to review the security configuration of the Plooral platform. The previous operator set up IAM roles, WAF rules, and SSM parameters, but there are concerns about the security posture.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              CloudFront                                      │
│                    Distribution: E1A2B3C4D5E6F7                             │
│                                                                              │
│    ┌──────────────────────────────────────────────────────────────────┐     │
│    │                         AWS WAF                                   │     │
│    │                   WebACL: plooral-prod-waf                       │     │
│    │                                                                   │     │
│    │  Rules:                                                          │     │
│    │  - AWS Managed Core Rule Set                                     │     │
│    │  - AWS Managed Known Bad Inputs                                  │     │
│    │  - plooral-rate-limit-rule (Custom)                             │     │
│    │  - plooral-geo-block-rule (Custom)                              │     │
│    └──────────────────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Application Load Balancer                                 │
│                    plooral-api-prod-alb                                     │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         ECS Cluster (Fargate)                                │
│                                                                              │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                      ECS Task Role                                   │   │
│   │            plooral-ecs-task-role                                    │   │
│   │                                                                      │   │
│   │  Used by: plooral-api containers                                   │   │
│   │  Permissions: Access to Aurora, SQS, SNS, SSM, S3                  │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                    ECS Execution Role                                │   │
│   │            plooral-ecs-execution-role                               │   │
│   │                                                                      │   │
│   │  Used by: ECS agent                                                 │   │
│   │  Permissions: ECR pull, CloudWatch logs, Secrets Manager           │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                            Lambda                                            │
│                                                                              │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                     Lambda Execution Role                            │   │
│   │            plooral-lambda-execution-role                            │   │
│   │                                                                      │   │
│   │  Used by: plooral-worker Lambda function                           │   │
│   │  Permissions: SQS, Aurora, CloudWatch, X-Ray                       │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

## SSM Parameter Store

The following parameters are stored in SSM:

| Parameter | Type | Description |
|-----------|------|-------------|
| `/plooral/prod/db-password` | SecureString | Database password |
| `/plooral/prod/jwt-secret` | SecureString | JWT signing secret |
| `/plooral/prod/api-keys/stripe` | SecureString | Stripe API key |
| `/plooral/prod/api-keys/sendgrid` | SecureString | SendGrid API key |
| `/plooral/prod/config/feature-flags` | String | Feature flag configuration |
| `/plooral/prod/config/rate-limits` | String | Rate limiting configuration |

## Background

The security configuration was set up quickly during the initial platform build. There have been some concerns raised in recent security reviews, but no detailed findings have been documented. Your task is to perform a comprehensive security review and identify any issues.

## Available Artifacts

| File | Description |
|------|-------------|
| `iam_policy.json` | ECS task role policy |
| `iam_trust_policy.json` | Trust policies for all roles |
| `ssm_parameters.json` | SSM parameter configurations |
| `waf_web_acl.json` | WAF Web ACL configuration |
| `cloudfront_distribution.json` | CloudFront distribution config |

## Your Task

1. Review all security configurations
2. Identify and fix IAM policy issues
3. Improve WAF rules without breaking legitimate traffic
4. Secure SSM parameters properly
5. Enhance CloudFront security configuration

Answer the questions in `QUESTIONS.md`.

