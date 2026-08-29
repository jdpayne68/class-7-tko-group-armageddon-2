# Imposter Syndrome Defense

The Imposter Syndrome script is an interactive tool that scans a Terraform deployment, compares the active resources against a generated skill definition file, shows the skills the deployment demonstrates, then optionally runs Terraform with the lab's `chewbacca.tfvars` file. Providing motivation along the way

The Imposter Syndrome script is an interactive motivational tool that scans a Terraform deployment, compares its active resources against a generated skill-definition file, then highlights the cloud and DevSecOps skills demonstrated by the architecture. Optionally, it can deploy a lab using its chewbacca.tfvars file.

## Files

| File | Purpose |
| --- | --- |
| `imposter-syndrome-defense.py` | Runs the skill scan and optional Terraform plan/apply workflow |
| `assets/skills/skill-builder-agent-prompt.md` | Prompt used by an AI agent to build the skill definition file |
| `assets/skills/skills.tf` | Active Terraform resource/data-to-skill contract used by the script |
| `assets/skills/skills-example.tf` | Human reference for the expected skill-file style |
| `assets/quotes/quotes.json` | Quote source used for CLI encouragement |
| `../../terraform-tfvars.example` | Deployment template users can copy into a real `.tfvars` file |
| `../../chewbacca.tfvars` | Local deployment values used by the script; ignored by Git |

## Prerequisites

- Run from a lab Terraform root, such as `phase_1/lab_12/terraform`.
- Terraform must be installed.
- Run `terraform init` before deployment runs.
- Run `terraform validate` before deployment runs.
- `chewbacca.tfvars` must exist before the script can run Terraform.
- A valid `assets/skills/skills.tf` must exist before the script can detect skills.
- Python 3 is required.

Create a local deployment file from the template:

```bash
cd phase_1/lab_12/terraform
cp terraform-tfvars.example chewbacca.tfvars
```

Edit `chewbacca.tfvars` with your real deployment values. Do not commit it.

## Agent Build Skills Workflow

Use the skill-builder prompt when Terraform resources change or when `skills.tf` needs to be rebuilt.

1. Open [assets/skills/skill-builder-agent-prompt.md](assets/skills/skill-builder-agent-prompt.md).
2. Modify the prompt so it includes the Terraform directory the agent should inspect:

```text
phase_1/lab_12/terraform
```

3. Provide the updated prompt to the agent.
4. Ask the agent to generate:

```text
terraform/scripts/imposter_syndrome/assets/skills/skills.tf
```

The agent should inspect active Terraform files, ignore generated/support folders, and write a skill-tagged `skills.tf` file without modifying deployment Terraform.

## Run The Script

From the Terraform root:

```bash
cd phase_1/lab_12/terraform
python scripts/imposter_syndrome/imposter-syndrome-defense.py --name Kirk
```

Scan skills without running Terraform:

```bash
python scripts/imposter_syndrome/imposter-syndrome-defense.py --name Kirk --skip-terraform
```

Show all supporting Terraform evidence:

```bash
python scripts/imposter_syndrome/imposter-syndrome-defense.py --name Kirk --skip-terraform --verbose-skills
```

Speed up scripted demos:

```bash
NO_TYPEWRITER=true PAUSE_LONG=0 python scripts/imposter_syndrome/imposter-syndrome-defense.py --name Kirk --skip-terraform
```

## Terraform Behavior

When Terraform execution is enabled, the script first asks:

```text
Run Terraform Auto Apply?
```

If you answer yes, the script runs `terraform apply -auto-approve -var-file=chewbacca.tfvars`.

If you answer no, the script generates `chewbacca.tfplan`, prints the plan output, and asks whether to apply that reviewed plan.

If `chewbacca.tfvars` is missing, the script stops before Terraform and tells you exactly what file it expected.

## Troubleshooting

### Error Acquiring The State Lock

If you interrupt the script during Terraform activity, Terraform may leave a state lock behind. Terraform uses state locks to prevent two commands from modifying the same state at the same time.

Before unlocking anything, confirm no Terraform command is still running:

```bash
ps aux | grep terraform
```

If another Terraform process is still active, wait for it to finish or stop it intentionally before continuing.

### Get The Lock ID

`terraform force-unlock` requires the lock ID. Running it without the ID produces:

```text
Expected a single argument: LOCK_ID
```

Run a normal Terraform command to make Terraform print the lock details:

```bash
terraform plan -var-file=chewbacca.tfvars
```

If the state is locked, Terraform prints a block like this:

```text
Error: Error acquiring the state lock

Lock Info:
  ID:        <LOCK_ID>
  Path:      <BACKEND_STATE_PATH>
  Operation: <TERRAFORM_OPERATION>
  Who:       <USER_AND_HOST>
  Version:   <TERRAFORM_VERSION>
  Created:   <LOCK_CREATED_TIME>
```

Copy the `ID` value.

> [!NOTE]
> Do not run `terraform plan chewbacca.tfvars`. Terraform treats that as an extra positional argument. Use `-var-file=chewbacca.tfvars`.

### Unlock Remote State

For S3 or other remote backends, unlock the state with the lock ID:

```bash
terraform force-unlock <LOCK_ID>
```

Terraform will ask for confirmation. Type:

```text
yes
```

For non-interactive recovery after confirming the lock is stale:

```bash
terraform force-unlock -force <LOCK_ID>
```

> [!WARNING]
> Only force-unlock a state when you are sure the previous Terraform process is dead. Unlocking active state can allow multiple Terraform commands to write to the same state.

### Local State Locks

Local state behaves differently. Local state files cannot be unlocked by another process.

If local state appears locked:

1. Confirm no Terraform process is running.
2. Close terminals or editors that may be holding the file.
3. Retry the Terraform command.
4. If a local lock file remains after a crash, inspect it before deleting it.

Do not delete local state files. The state file is the deployment record.

### Emergency Destroy With Lock Disabled

If you are cleaning up a stuck lab and you have confirmed no Terraform process is still running, you can bypass locking during destroy:

```bash
terraform destroy -lock=false -var-file=chewbacca.tfvars
```

Use this as a recovery option, not the normal workflow. `-lock=false` bypasses Terraform's state-lock protection.

### Quick Recovery Flow

```bash
ps aux | grep terraform
terraform plan -var-file=chewbacca.tfvars
terraform force-unlock <LOCK_ID>
terraform plan -var-file=chewbacca.tfvars
```

If the final plan runs without the lock error, the state lock is cleared.
