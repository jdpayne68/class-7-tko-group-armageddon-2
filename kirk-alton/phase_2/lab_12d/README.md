# Lab Readme

TODO: Add documentation for lab.

## Work In Progress

### Lambda Functions
- [ ] Fusion Agent
    - [ ] Update [fusion agent lambda code](./terraform/lambda/src/fusion_agent/fusion-agent.py)
    - [ ] Define required [environment variables](terraform/lambda/src/.env.lambda)
    - [ ] Map out minimum permissions
- [ ] Provider Registry Agent
    - [ ] Update [provider registry agent lambda code](./terraform/lambda/src/provider_registry_agent/provider-registry-agent.py)
    - [ ] Define required [environment variables](terraform/lambda/src/.env.lambda)
    - [ ] Map out minimum permissions
- [ ] Threat Intelligence Report Agent
    - [ ] Update [threat intelligence report agent lambda code](./terraform/lambda/src/intelligence_report_agent/intelligence-report-agent.py)
    - [ ] Define required [environment variables](terraform/lambda/src/.env.lambda)
    - [ ] Map out minimum permissions

### Terraform
- [ ] Fusion Agent
    - [ ] [Lambda](terraform/10-iam-policies.tf)
    - [ ] [Log Group](terraform/80-cloudwatch-logs.tf)
    - [ ] [IAM Policies](terraform/10-iam-policies.tf) for Lambda and Eventbridge Invocation
    - [ ] [IAM Policies](terraform/11-iam-roles.tf)
    - [ ] [EventBridge Rules/Scheduler](terraform/60-eventbridge.tf) to Invoke Lambda
- [ ] Provider Registry Agent
    - [ ] [Lambda](terraform/10-iam-policies.tf)
    - [ ] [Log Group](terraform/80-cloudwatch-logs.tf)
    - [ ] [IAM Policies](terraform/10-iam-policies.tf) for Lambda and Eventbridge Invocation
    - [ ] [IAM Policies](terraform/11-iam-roles.tf)
    - [ ] [EventBridge Rules/Scheduler](terraform/60-eventbridge.tf) to Invoke Lambda
- [ ] Threat Intelligence Report Agent
    - [ ] [Lambda](terraform/10-iam-policies.tf)
    - [ ] [Log Group](terraform/80-cloudwatch-logs.tf)
    - [ ] [IAM Policies](terraform/10-iam-policies.tf) for Lambda and Eventbridge Invocation
    - [ ] [IAM Policies](terraform/11-iam-roles.tf)
    - [ ] [EventBridge Rules/Scheduler](terraform/60-eventbridge.tf) to Invoke Lambda