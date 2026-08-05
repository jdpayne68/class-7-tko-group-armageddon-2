# RAPTOR

**Rapid Automated Pipeline for Threat Operations and Response**

A serverless, AI-powered security automation pipeline built entirely on AWS. Deployed with a single `terraform apply`.

Built by Marvin, Chicago.

---

## The Problem

Cloud environments throw off thousands of security alerts a day — GuardDuty findings, weird CloudTrail activity, login spikes. Almost all of it is noise, but somewhere in there is the one alert that actually matters, and you can't tell which one until someone looks.

By the time a human gets through the queue, an attacker can already be moving laterally and pulling data out the door. That's not a staffing problem, it's a pipeline problem — manual triage just can't keep up with machine-speed alert volume.

Tools like Splunk SOAR and Palo Alto XSOAR solve this, but they're built (and priced) for big security teams with big budgets. Small teams and solo engineers usually don't have a real option — they're either ignoring the noise or overpaying for infrastructure they don't need.

**RAPTOR is the lightweight alternative:** a fully serverless SOAR pipeline that lives entirely in your own AWS account, costs only what you actually use, and deploys in one command.

## What It Does

When a security event happens, RAPTOR detects it, triages it, uses AI to reason about it, and takes action — automatically, with no human in the loop.

This is a real, working system — not a demo. Every Lambda runs, events flow through EventBridge, incidents are stored in DynamoDB, and Bedrock generates actual AI analysis on live event payloads.

**Built with:**
- AWS Lambda (3 functions)
- Amazon EventBridge (custom bus)
- Amazon DynamoDB
- Amazon Bedrock (Claude)
- Amazon CloudWatch
- Amazon SNS
- Terraform (manages everything)

## Architecture at a Glance

| Piece | AWS Service | What it does |
|---|---|---|
| Threat Ingestion | Lambda | Entry point — cleans up and standardizes raw events |
| Threat Correlation | Lambda | The brain — adds context, checks for related incidents |
| SOAR Response | Lambda | The hands — runs playbooks, logs incidents, calls Bedrock |
| Custom Event Bus | EventBridge | Routes events between the pieces |
| Incident Store | DynamoDB | Source of truth for every incident |
| AI Analysis | Bedrock (Claude) | Turns raw events into human-readable threat summaries |
| Observability | CloudWatch | Logs, metrics, alarms |
| Alerting | SNS | Sends out high-severity notifications |
| Infrastructure | Terraform | Deploys and manages everything |

## How It Works

**1. Ingestion**
A raw event comes in — a GuardDuty finding, a weird CloudTrail entry, whatever. The Ingestion Lambda validates it and reshapes it into one consistent format (source, event type, severity, affected resource, timestamp, details). Anything malformed gets rejected and logged, so bad data never makes it further down the pipeline.

**2. Correlation**
The cleaned-up event goes to the Correlation Lambda, which adds context and checks DynamoDB to see if it's related to an existing open incident. If it matches one (same IP, same resource), it's tagged as an escalation. If not, it becomes a new incident. The Lambda scores it (low/medium/high/critical) and sends it to EventBridge.

> **Heads up:** EventBridge matches events by exact source and type. Get that wrong — wrong casing, a stray space — and the event just disappears. No error, no warning. Turn on CloudWatch logging for the event bus (it's off by default) so you can actually see what's arriving and whether it matched anything. Worth doing before you need it.

**3. Routing**
Everything runs through a dedicated custom EventBridge bus, kept separate from AWS's default bus so it's easier to audit. When an event matches the expected source and type, it triggers the Response Lambda.

**4. AI Analysis**
The Response Lambda hands the incident to Amazon Bedrock (Claude), which returns a structured summary: what happened, why it's rated the way it is, what to do about it, and how confident it is in that read. This gets saved to the incident record in DynamoDB. Being specific in the prompt — laying out the expected JSON structure and giving an example — makes a big difference in how consistent Claude's output is.

**5. Response**
Based on the severity score, the Response Lambda runs the right playbook. High-severity incidents get pushed to SNS for immediate alerting; lower-severity ones are logged and tracked without paging anyone.

---

*Last updated: August 5, 2026*