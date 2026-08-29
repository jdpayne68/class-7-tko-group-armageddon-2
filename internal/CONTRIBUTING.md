# Contributing

1. Do not push directly to `main`.
2. Create work from the latest approved base branch.
3. Never commit AWS credentials, private keys, `.env` files, real `terraform.tfvars`, or Terraform state.
4. Run formatting and validation before opening a pull request.
5. Include validation evidence and cleanup instructions.
6. Use clear commit messages such as:
   - `feat(lab12): add WAF correlation Lambda`
   - `fix(iam): allow correlation agent to publish EventBridge events`
   - `docs: add Phase 1 deployment instructions`

## Phase 1 Branch Bootstrap

Use `internal/deploy_branch/phase-1-init.sh` to initialize peer-ready Phase 1 branch content. The script copies missing scaffold and lab files from `internal/deploy_branch/resources` while preserving existing branch work.

Maintainer expectations:

1. Treat the repository root as the source of truth.
2. Keep `internal/deploy_branch/resources/templates/lab_templates` synchronized with `phase_1/lab_12` through `phase_1/lab_12c`.
3. Keep `internal/deploy_branch/resources/repo_scaffold` synchronized with required root-level branch structure.
4. Do not include `RIKB/` or `badges/` in branch setup resources.
5. Do not include generated Terraform state, `.terraform/`, Lambda layer build output, zip packages, `.DS_Store`, or local virtual environments.
6. Validate changes with `bash -n internal/deploy_branch/phase-1-init.sh` and `internal/deploy_branch/phase-1-init.sh --check`.
