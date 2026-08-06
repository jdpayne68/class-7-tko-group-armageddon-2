# Badge Normalization Guide

Badges should help a reader understand the project quickly. Good badge design is not just about adding more badges. It is about making the badge row scannable, accurate, and visually consistent.

## Recommended Structure

Use blank-line groups instead of visible badge headings at the top of a README. This keeps the README clean while still creating visual organization.

Recommended order:

1. Repository health
2. Tooling and language requirements
3. Platform or cloud services
4. Project focus and documentation

```markdown
[repo badges...]

[tooling badges...]

[platform badges...]

[project/docs badges...]
```

## Color System

Use a hybrid color system:

- Repository badges use GitHub black: `181717`
- Tooling badges use official or recognizable brand colors
- Cloud provider service badges use one provider color for the whole row
- Project focus badges use a distinct semantic color
- Documentation badges use a clear documentation blue

This avoids a noisy badge row while preserving enough brand recognition to make badges useful at a glance.

## Suggested Palette

Repository:

- GitHub / repository health: `181717`

Tooling:

- Terraform: `844FBA`
- Python: `3776AB`
- Node.js: `339933`
- Shell / Bash: `4EAA25`

AWS services:

- AWS service badges: `FF9900`

Project and documentation:

- DevSecOps / security focus: `0F766E`
- Documentation: `2563EB`

## Label Style

Use the official product or technology name on the left side of the badge. Use a short capability descriptor on the right side.

Good examples:

- `AWS WAF - managed rule groups`
- `Amazon Cognito - user authentication`
- `Amazon DynamoDB - security evidence`
- `Amazon EventBridge - event routing`
- `DevSecOps - cloud security pipeline`

Prefer lowercase for right-side descriptors unless the descriptor contains a proper product name, acronym, or version.

## Version Badges

When a badge communicates a requirement, use the minimum supported version:

- `Terraform >= 1.10`
- `Python >= 3.12`
- `Node.js >= 24`

Do not use a vague version like `3.x` if the repository clearly depends on a specific runtime family.

## Sample Rendering Blocks

### Repository Health

```markdown
[![Last Commit](https://img.shields.io/github/last-commit/OWNER/REPO?logo=github&color=181717)](https://github.com/OWNER/REPO/commits/main)
[![Contributors](https://img.shields.io/github/contributors/OWNER/REPO?logo=github&color=181717)](https://github.com/OWNER/REPO/graphs/contributors)
[![Stars](https://img.shields.io/github/stars/OWNER/REPO?style=flat&logo=github&color=181717)](https://github.com/OWNER/REPO)
[![Forks](https://img.shields.io/github/forks/OWNER/REPO?style=flat&logo=github&color=181717)](https://github.com/OWNER/REPO/forks)
[![Commit Activity](https://img.shields.io/github/commit-activity/m/OWNER/REPO?logo=github&color=181717)](https://github.com/OWNER/REPO/graphs/commit-activity)
```

### Tooling

```markdown
[![Terraform](https://img.shields.io/badge/Terraform-%E2%89%A5%201.10-844FBA?logo=terraform&logoColor=white)](https://developer.hashicorp.com/terraform)
[![Python](https://img.shields.io/badge/Python-%E2%89%A5%203.12-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![Node.js](https://img.shields.io/badge/Node.js-%E2%89%A5%2024-339933?logo=nodedotjs&logoColor=white)](https://nodejs.org/)
[![Shell](https://img.shields.io/badge/Shell-scripts-4EAA25?logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
```

### AWS Services

```markdown
[![Amazon Cognito](https://img.shields.io/badge/Amazon%20Cognito-user%20authentication-FF9900?logo=amazonaws&logoColor=white)](https://aws.amazon.com/cognito/)
[![Amazon API Gateway](https://img.shields.io/badge/Amazon%20API%20Gateway-REST%20APIs-FF9900?logo=amazonaws&logoColor=white)](https://aws.amazon.com/api-gateway/)
[![AWS WAF](https://img.shields.io/badge/AWS%20WAF-managed%20rule%20groups-FF9900?logo=amazonaws&logoColor=white)](https://aws.amazon.com/waf/)
[![AWS Lambda](https://img.shields.io/badge/AWS%20Lambda-security%20agents-FF9900?logo=awslambda&logoColor=white)](https://aws.amazon.com/lambda/)
[![Amazon EventBridge](https://img.shields.io/badge/Amazon%20EventBridge-event%20routing-FF9900?logo=amazoneventbridge&logoColor=white)](https://aws.amazon.com/eventbridge/)
[![Amazon DynamoDB](https://img.shields.io/badge/Amazon%20DynamoDB-security%20evidence-FF9900?logo=amazondynamodb&logoColor=white)](https://aws.amazon.com/dynamodb/)
[![Amazon Bedrock](https://img.shields.io/badge/Amazon%20Bedrock-foundation%20models-FF9900?logo=amazonaws&logoColor=white)](https://aws.amazon.com/bedrock/)
```

### Project Focus And Documentation

```markdown
[![DevSecOps](https://img.shields.io/badge/DevSecOps-cloud%20security%20pipeline-0F766E?logo=securityscorecard&logoColor=white)](internal/CONTRIBUTING.md)
[![Documentation](https://img.shields.io/badge/Documentation-lab%20guides-2563EB?logo=readthedocs&logoColor=white)](#documentation)
```

### Full README Badge Block

```markdown
[![Last Commit](https://img.shields.io/github/last-commit/OWNER/REPO?logo=github&color=181717)](https://github.com/OWNER/REPO/commits/main)
[![Contributors](https://img.shields.io/github/contributors/OWNER/REPO?logo=github&color=181717)](https://github.com/OWNER/REPO/graphs/contributors)
[![Stars](https://img.shields.io/github/stars/OWNER/REPO?style=flat&logo=github&color=181717)](https://github.com/OWNER/REPO)
[![Forks](https://img.shields.io/github/forks/OWNER/REPO?style=flat&logo=github&color=181717)](https://github.com/OWNER/REPO/forks)
[![Commit Activity](https://img.shields.io/github/commit-activity/m/OWNER/REPO?logo=github&color=181717)](https://github.com/OWNER/REPO/graphs/commit-activity)

[![Terraform](https://img.shields.io/badge/Terraform-%E2%89%A5%201.10-844FBA?logo=terraform&logoColor=white)](https://developer.hashicorp.com/terraform)
[![Python](https://img.shields.io/badge/Python-%E2%89%A5%203.12-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![Node.js](https://img.shields.io/badge/Node.js-%E2%89%A5%2024-339933?logo=nodedotjs&logoColor=white)](https://nodejs.org/)
[![Shell](https://img.shields.io/badge/Shell-scripts-4EAA25?logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)

[![Amazon Cognito](https://img.shields.io/badge/Amazon%20Cognito-user%20authentication-FF9900?logo=amazonaws&logoColor=white)](https://aws.amazon.com/cognito/)
[![Amazon API Gateway](https://img.shields.io/badge/Amazon%20API%20Gateway-REST%20APIs-FF9900?logo=amazonaws&logoColor=white)](https://aws.amazon.com/api-gateway/)
[![AWS WAF](https://img.shields.io/badge/AWS%20WAF-managed%20rule%20groups-FF9900?logo=amazonaws&logoColor=white)](https://aws.amazon.com/waf/)
[![AWS Lambda](https://img.shields.io/badge/AWS%20Lambda-security%20agents-FF9900?logo=awslambda&logoColor=white)](https://aws.amazon.com/lambda/)
[![Amazon EventBridge](https://img.shields.io/badge/Amazon%20EventBridge-event%20routing-FF9900?logo=amazoneventbridge&logoColor=white)](https://aws.amazon.com/eventbridge/)
[![Amazon DynamoDB](https://img.shields.io/badge/Amazon%20DynamoDB-security%20evidence-FF9900?logo=amazondynamodb&logoColor=white)](https://aws.amazon.com/dynamodb/)
[![Amazon Bedrock](https://img.shields.io/badge/Amazon%20Bedrock-foundation%20models-FF9900?logo=amazonaws&logoColor=white)](https://aws.amazon.com/bedrock/)

[![DevSecOps](https://img.shields.io/badge/DevSecOps-cloud%20security%20pipeline-0F766E?logo=securityscorecard&logoColor=white)](internal/CONTRIBUTING.md)
[![Documentation](https://img.shields.io/badge/Documentation-lab%20guides-2563EB?logo=readthedocs&logoColor=white)](#documentation)
```

## What To Avoid

Avoid badges that are unsupported by the repository configuration.

Do not add badges for:

- GitHub Actions if no workflow exists
- CodeQL if CodeQL is not configured
- License if the repository has no license file
- OpenSSF Scorecard if the repository is not using it
- Docker or Kubernetes if the project does not use them

Also avoid duplicate concept badges. For example, if the README already has AWS Lambda and EventBridge badges, a generic serverless badge may be redundant unless the project specifically needs to advertise its architecture style.

## Badge Maintenance Checklist

Before committing badge changes:

1. Confirm every badge reflects something real in the repository.
2. Check every badge image URL returns HTTP 200.
3. Check every external target link returns HTTP 200.
4. Check every local target link exists.
5. Keep the badge section short enough to scan.
6. Prefer stable project qualities over temporary implementation details.

## Rule Of Thumb

A badge earns its place if it tells a new reader something useful in one second. If the README body already communicates the same thing better, skip the badge.
