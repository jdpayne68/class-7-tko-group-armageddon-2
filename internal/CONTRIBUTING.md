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
