# Scenario 2 — CI/CD and Deployments

## Situation

You've been asked to review and fix the CI/CD pipeline for the Plooral API. The current pipeline was set up quickly and has several issues that have caused production incidents.

## Current Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              GitHub Repository                               │
│                         plooral/plooral-api (main branch)                   │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼ (webhook on push)
┌─────────────────────────────────────────────────────────────────────────────┐
│                              AWS CodePipeline                                │
│                            plooral-api-pipeline                              │
│                                                                              │
│   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                     │
│   │   Source    │───▶│    Build    │───▶│   Deploy    │                     │
│   │   Stage     │    │   Stage     │    │   Stage     │                     │
│   │  (GitHub)   │    │ (CodeBuild) │    │(CodeDeploy) │                     │
│   └─────────────┘    └─────────────┘    └─────────────┘                     │
│                                                                              │
│   ⚠️ NO MANUAL APPROVAL BEFORE PRODUCTION                                    │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         ECS Cluster (Fargate)                                │
│                      Cluster: plooral-prod-cluster                           │
│                      Service: plooral-api                                    │
│                                                                              │
│   Deployment Type: Rolling Update                                            │
│   Minimum Healthy: 50%                                                       │
│   Maximum Percent: 200%                                                      │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Known Issues

The previous operator left notes about these problems:

1. **No manual approval** — Changes go straight to production after build
2. **Build sometimes fails** — Intermittent failures in CodeBuild
3. **Task definition mismatch** — Container image reference doesn't match
4. **No rollback automation** — Rollbacks are done manually
5. **Deployment takes too long** — Health checks are too aggressive
6. **Secrets exposure risk** — Build logs might expose sensitive data

## Pipeline Configuration Files

Review the following files in the `pipeline/` directory:

| File | Description |
|------|-------------|
| `codepipeline.json` | CodePipeline definition |
| `buildspec.yml` | CodeBuild build specification |
| `appspec.yml` | CodeDeploy application specification |
| `ecs_taskdef.json` | ECS task definition template |

## Build & Deploy Artifacts

Review the following files in the `artifacts/` directory:

| File | Description |
|------|-------------|
| `codebuild.log` | Recent CodeBuild execution log |
| `codedeploy.log` | Recent CodeDeploy deployment log |
| `pipeline_execution.log` | Pipeline execution history |

## Environment Details

| Component | Value |
|-----------|-------|
| AWS Region | us-east-1 |
| ECR Repository | 123456789012.dkr.ecr.us-east-1.amazonaws.com/plooral-api |
| ECS Cluster | plooral-prod-cluster |
| ECS Service | plooral-api |
| Target Group | plooral-api-prod-tg |
| CodeBuild Project | plooral-api-build |
| CodeDeploy Application | plooral-api-deploy |
| CodeDeploy Deployment Group | plooral-api-prod-dg |

## Your Task

1. Review the pipeline configuration files
2. Identify all issues
3. Propose and implement fixes
4. Ensure safe deployment practices

Answer the questions in `QUESTIONS.md`.

