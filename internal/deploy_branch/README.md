# Deploy Branch Resources

This directory contains the internal resources used to initialize a peer-ready Phase 1 branch from the canonical repository structure.

## Purpose

`phase-1-init.sh` is an idempotent bootstrap script. It creates missing repository scaffold files and Phase 1 lab files while preserving any files that already exist in the target branch.

The script is safe to run more than once:

- existing files are never overwritten
- missing directories are created as needed
- missing files are copied from the internal resources
- differing files are reported and preserved
- generated or centrally managed folders are excluded from branch setup

## Source Of Truth

The repository root is the source of truth for branch structure.

The deploy resources are maintained from these canonical locations:

- `phase_1/lab_12` -> `resources/templates/lab_templates/lab_12_template`
- `phase_1/lab_12a` -> `resources/templates/lab_templates/lab_12a_template`
- `phase_1/lab_12b` -> `resources/templates/lab_templates/lab_12b_template`
- `phase_1/lab_12c` -> `resources/templates/lab_templates/lab_12c_template`
- root scaffold files -> `resources/repo_scaffold`

`RIKB/` and `badges/` are intentionally excluded. They exist in the main repository for maintainer workflows, but peers do not need them to initialize or deploy the lab branch.

## Usage

Check the current branch without writing files:

```bash
./internal/deploy_branch/phase-1-init.sh --check
```

Deploy missing scaffold and Phase 1 lab files:

```bash
./internal/deploy_branch/phase-1-init.sh --deploy
```

Deploy without prompts:

```bash
./internal/deploy_branch/phase-1-init.sh --deploy --yes
```

Limit deployment to a single lab:

```bash
./internal/deploy_branch/phase-1-init.sh --deploy --lab lab_12b
```

Test against a clean target directory:

```bash
./internal/deploy_branch/phase-1-init.sh --deploy --yes --repo-root /tmp/phase-1-branch-test
```

## Maintainer Notes

When Phase 1 lab source changes, refresh the matching internal template from the root lab directory. Do not copy built Lambda layers, Terraform state, `.terraform/`, `.DS_Store`, zip packages, or generated RIKB artifacts into the deploy resources.

The expected validation sequence is:

```bash
bash -n internal/deploy_branch/phase-1-init.sh
./internal/deploy_branch/phase-1-init.sh --check
./internal/deploy_branch/phase-1-init.sh --deploy --yes --repo-root /tmp/phase-1-branch-test
```
