variable "prefix" {
  type        = string
  description = "Naming prefix for WAF resources"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags applied to all WAF resources"
}
