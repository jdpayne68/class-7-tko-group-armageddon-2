output "waf_analyzer_role_arn" {
  value = aws_iam_role.waf_analyzer_role.arn
}

output "threat_correlation_role_arn" {
  value = aws_iam_role.threat_correlation_role.arn
}

output "soar_response_role_arn" {
  value = aws_iam_role.soar_response_role.arn
}

output "executive_dashboard_role_arn" {
  value = aws_iam_role.executive_dashboard_role.arn
}
output "soar_role_arn" {
  value = aws_iam_role.soar_role.arn
}


output "compliance_role_arn" {
  value = aws_iam_role.compliance_role.arn
}


# output "compliance_policy_arn" {
#   value = aws_iam_role_policy.compliance_policy.arn
# }