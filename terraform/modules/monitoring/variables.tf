variable "name" {
  description = "Log Analytics workspace name."
  type        = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "retention_in_days" {
  description = "Workspace retention. 30 is enough for a lab; production is a cost decision."
  type        = number
  default     = 30
}

variable "alert_email" {
  description = "Action group email. Use a mailbox you control; this is not a ServiceNow connector."
  type        = string
}

variable "failed_signin_threshold" {
  description = "Failed SigninLogs count in a 15-minute window that pages the action group."
  type        = number
  default     = 25
}

variable "nsg_ids" {
  description = "NSGs that send diagnostic logs to this workspace."
  type        = map(string)
  default     = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
