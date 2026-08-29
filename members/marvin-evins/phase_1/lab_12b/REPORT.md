# Lab 12B Deliverable — Executive Reporting
**Participant:** Marvin Evins  
**Phase:** 1  
**Status:** Implemented as the reporting layer built on the SOAR incident pipeline

## Objective
Lab 12B adds executive reporting to the security automation pipeline. Instead of leaving security data only in logs and DynamoDB, the reporting layer converts incident information into management-friendly report artifacts and stores those artifacts for later review.

## Implementation Summary
The executive reporting stage consumes security-incident information created by the earlier pipeline. The design uses a reporting Lambda, DynamoDB incident data, S3 report storage, CloudWatch logging, Terraform-managed IAM permissions, and a PDF-generation dependency/layer where required.

The main architectural progression is:

`Finding -> SOAR Incident -> Executive Reporting Lambda -> PDF/JSON Report -> S3`

## What This Demonstrates
- Separation between operational security processing and executive communication.
- Durable report artifacts rather than transient console output.
- Infrastructure-as-code for the reporting Lambda, S3 destination, IAM, and supporting resources.
- Reuse of the same incident data generated in Lab 12A.

## Evidence to Submit
- Screenshot: executive/reporting Lambda exists and is successfully invoked.
- Screenshot: S3 bucket containing executive PDF and/or JSON report artifacts.
- Screenshot: one generated executive report opened or downloaded locally.
- Screenshot: CloudWatch log for the executive reporting Lambda.
- Code evidence: executive dashboard/reporting Lambda and S3/IAM Terraform.

## Key Result
Lab 12B proves that the Armageddon pipeline is not only detecting and responding to security events; it can also translate technical incident data into durable artifacts that can be reviewed by leadership or other non-SOC stakeholders.
