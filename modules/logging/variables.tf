variable "prefix" {
  type        = string
  description = "Naming prefix for log groups"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags applied to all log groups"
}

