# Badge Library

Reusable Shields.io badge patterns for repository READMEs.

This page is the front door for the badge system. Use the examples below as balanced starting points, then pull additional badges from the specialized libraries in [`library/`](library/).

## Recommended Layout

Use blank-line groups instead of visible badge headings at the top of a README:

1. Repository health
2. Tooling and language requirements
3. Platform, methodology, or project focus
4. Documentation or community signals

## Badge Block Examples

### Standard Repository

General software project with repository health, runtime requirements, and documentation.

```markdown
[![Last Commit](https://img.shields.io/github/last-commit/OWNER/REPO?logo=github&color=181717)](https://github.com/OWNER/REPO/commits/main)
[![Contributors](https://img.shields.io/github/contributors/OWNER/REPO?logo=github&color=181717)](https://github.com/OWNER/REPO/graphs/contributors)
[![Stars](https://img.shields.io/github/stars/OWNER/REPO?style=flat&logo=github&color=181717)](https://github.com/OWNER/REPO)
[![Forks](https://img.shields.io/github/forks/OWNER/REPO?style=flat&logo=github&color=181717)](https://github.com/OWNER/REPO/forks)
[![Commit Activity](https://img.shields.io/github/commit-activity/m/OWNER/REPO?logo=github&color=181717)](https://github.com/OWNER/REPO/graphs/commit-activity)

[![Python](https://img.shields.io/badge/Python-%E2%89%A5%203.12-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![Node.js](https://img.shields.io/badge/Node.js-%E2%89%A5%2024-339933?logo=nodedotjs&logoColor=white)](https://nodejs.org/)
[![Shell](https://img.shields.io/badge/Shell-scripts-4EAA25?logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)

[![Documentation](https://img.shields.io/badge/Documentation-project%20guides-2563EB?logo=readthedocs&logoColor=white)](#documentation)
```

### DevSecOps Project

Security-focused engineering project with cloud, automation, and infrastructure signals.

```markdown
[![Last Commit](https://img.shields.io/github/last-commit/OWNER/REPO?logo=github&color=181717)](https://github.com/OWNER/REPO/commits/main)
[![Contributors](https://img.shields.io/github/contributors/OWNER/REPO?logo=github&color=181717)](https://github.com/OWNER/REPO/graphs/contributors)
[![Commit Activity](https://img.shields.io/github/commit-activity/m/OWNER/REPO?logo=github&color=181717)](https://github.com/OWNER/REPO/graphs/commit-activity)

[![Terraform](https://img.shields.io/badge/Terraform-%E2%89%A5%201.10-844FBA?logo=terraform&logoColor=white)](https://developer.hashicorp.com/terraform)
[![Python](https://img.shields.io/badge/Python-%E2%89%A5%203.12-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![Shell](https://img.shields.io/badge/Shell-scripts-4EAA25?logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)

[![DevSecOps](https://img.shields.io/badge/DevSecOps-cloud%20security%20pipeline-0F766E?logo=securityscorecard&logoColor=white)](#devsecops)
[![GitOps](https://img.shields.io/badge/GitOps-declarative%20delivery-0F766E?logo=argo&logoColor=white)](https://opengitops.dev/)
[![Infrastructure as Code](https://img.shields.io/badge/Infrastructure%20as%20Code-methodology-0F766E?logo=terraform&logoColor=white)](https://developer.hashicorp.com/terraform)
[![OWASP](https://img.shields.io/badge/OWASP-app%20security-000000?logo=owasp&logoColor=white)](https://owasp.org/)

[![Documentation](https://img.shields.io/badge/Documentation-security%20runbooks-2563EB?logo=readthedocs&logoColor=white)](#documentation)
```

### Cloud Platform Project

Cloud-native infrastructure or serverless project with provider service badges.

```markdown
[![Last Commit](https://img.shields.io/github/last-commit/OWNER/REPO?logo=github&color=181717)](https://github.com/OWNER/REPO/commits/main)
[![Contributors](https://img.shields.io/github/contributors/OWNER/REPO?logo=github&color=181717)](https://github.com/OWNER/REPO/graphs/contributors)

[![Terraform](https://img.shields.io/badge/Terraform-%E2%89%A5%201.10-844FBA?logo=terraform&logoColor=white)](https://developer.hashicorp.com/terraform)
[![Python](https://img.shields.io/badge/Python-%E2%89%A5%203.12-3776AB?logo=python&logoColor=white)](https://www.python.org/)

[![AWS Lambda](https://img.shields.io/badge/AWS%20Lambda-Serverless%20Compute-FF9900?logo=awslambda&logoColor=white)](https://aws.amazon.com/lambda/)
[![Amazon EventBridge](https://img.shields.io/badge/Amazon%20EventBridge-Event%20Routing-FF9900?logo=amazoneventbridge&logoColor=white)](https://aws.amazon.com/eventbridge/)
[![Amazon DynamoDB](https://img.shields.io/badge/Amazon%20DynamoDB-NoSQL-FF9900?logo=amazondynamodb&logoColor=white)](https://aws.amazon.com/dynamodb/)
[![Amazon S3](https://img.shields.io/badge/Amazon%20S3-Object%20Storage-FF9900?logo=amazonaws&logoColor=white)](https://aws.amazon.com/s3/)
[![Amazon CloudWatch](https://img.shields.io/badge/Amazon%20CloudWatch-Observability-FF9900?logo=amazonaws&logoColor=white)](https://aws.amazon.com/cloudwatch/)

[![Cloud Native](https://img.shields.io/badge/Cloud%20Native-methodology-0F766E?logo=kubernetes&logoColor=white)](https://www.cncf.io/)
[![Documentation](https://img.shields.io/badge/Documentation-deployment%20guide-2563EB?logo=readthedocs&logoColor=white)](#documentation)
```

### Skills Portfolio

Portfolio or profile repository focused on professional capabilities.

```markdown
[![Last Commit](https://img.shields.io/github/last-commit/OWNER/REPO?logo=github&color=181717)](https://github.com/OWNER/REPO/commits/main)
[![Stars](https://img.shields.io/github/stars/OWNER/REPO?style=flat&logo=github&color=181717)](https://github.com/OWNER/REPO)

[![Cloud Engineering](https://img.shields.io/badge/Cloud%20Engineering-professional%20skill-2563EB?logo=github&logoColor=white)](#cloud-engineering)
[![Platform Engineering](https://img.shields.io/badge/Platform%20Engineering-professional%20skill-2563EB?logo=github&logoColor=white)](#platform-engineering)
[![Cloud Security](https://img.shields.io/badge/Cloud%20Security-professional%20skill-DC2626?logo=securityscorecard&logoColor=white)](#cloud-security)
[![Infrastructure Engineering](https://img.shields.io/badge/Infrastructure%20Engineering-professional%20skill-2563EB?logo=github&logoColor=white)](#infrastructure-engineering)
[![AI Engineering](https://img.shields.io/badge/AI%20Engineering-professional%20skill-111827?logo=openai&logoColor=white)](#ai-engineering)

[![Technical Documentation](https://img.shields.io/badge/Technical%20Documentation-professional%20skill-2563EB?logo=github&logoColor=white)](#technical-documentation)
```

### AI / ML Project

AI application, agent, automation, or RAG repository.

```markdown
[![Last Commit](https://img.shields.io/github/last-commit/OWNER/REPO?logo=github&color=181717)](https://github.com/OWNER/REPO/commits/main)
[![Contributors](https://img.shields.io/github/contributors/OWNER/REPO?logo=github&color=181717)](https://github.com/OWNER/REPO/graphs/contributors)

[![Python](https://img.shields.io/badge/Python-%E2%89%A5%203.12-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-API%20framework-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-relational%20database-4169E1?logo=postgresql&logoColor=white)](https://www.postgresql.org/)

[![OpenAI](https://img.shields.io/badge/OpenAI-AI%20platform-412991?logo=openai&logoColor=white)](https://openai.com/)
[![LangChain](https://img.shields.io/badge/LangChain-LLM%20framework-1C3C3C?logo=langchain&logoColor=white)](https://www.langchain.com/)
[![RAG](https://img.shields.io/badge/RAG-professional%20skill-111827?logo=openai&logoColor=white)](#rag)
[![Prompt Engineering](https://img.shields.io/badge/Prompt%20Engineering-professional%20skill-111827?logo=openai&logoColor=white)](#prompt-engineering)

[![Documentation](https://img.shields.io/badge/Documentation-model%20guides-2563EB?logo=readthedocs&logoColor=white)](#documentation)
```

## Badge Libraries

Use the full libraries when a project needs a custom badge block:

- [Git Badges](library/git-badges.md): Git platforms, repository workflows, governance, and release practices.
- [Core Badges](library/core-badges.md): Languages, frameworks, infrastructure, security tools, databases, observability, and engineering ecosystems.
- [Methodology Badges](library/methodology-badges.md): Delivery models, architecture patterns, governance approaches, and engineering methodologies.
- [Skill Badges](library/skill-badges.md): Practitioner capabilities and professional competency badges.
- [AWS Badge Library](library/aws-badges.md): Canonical AWS service badges.
- [Azure Badge Library](library/az-badges.md): Canonical Azure service badges.
- [Google Cloud Badge Library](library/gcp-badges.md): Canonical Google Cloud service badges.

## Notes

Keep README badge blocks short. A badge should communicate something useful in one second; if it does not, leave it in the library instead of the README.
