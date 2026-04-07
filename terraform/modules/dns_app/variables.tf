variable "dns_zone" {
  type        = string
  description = "DNS Zone ID"
}

variable "records" {
  type        = list(string)
  description = "records to resovle"
}

variable "hostname" {
  type        = string
  description = "Hostname record"

}

variable "type" {
  type        = string
  description = "type of record"
  default     = "CNAME"
}
