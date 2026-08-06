locals {
  common_tags = {
    Project     = var.project_name
    Environment = "lab"
    ManagedBy   = "Terraform"
  }

  function_names = {
    application = "${var.project_name}-protected-api"
    analyzer    = "${var.project_name}-waf-analyzer"
    correlation = "${var.project_name}-threat-correlation"
    soar        = "${var.project_name}-soar-response"
    dashboard   = "${var.project_name}-executive-dashboard"
  }
}
