variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

################################################################################
# Key Pair
################################################################################

variable "key_pair_name" {
  description = "The name for the key pair."
  type        = string
  default     = null
}

variable "public_key" {
  description = "The public key material"
  type        = string
  default     = ""
}
