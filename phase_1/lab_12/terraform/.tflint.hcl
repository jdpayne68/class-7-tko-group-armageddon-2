plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "aws" {
  enabled = true
  version = "0.34.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# AWS currently supports python3.14 and nodejs24.x. The pinned TFLint AWS
# ruleset predates those runtime identifiers, while AWS provider 6.46 validates
# them successfully. Re-enable this rule after the ruleset includes both.
rule "aws_lambda_function_invalid_runtime" {
  enabled = false
}
