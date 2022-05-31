# vars
variable "instance_name" {
  description = "Value of the Name tag for the EC2 instance"
  type        = string
  default     = "AppServer"
}

variable "db_password" {
  description = "RDS root user password"
  type = string
  sensitive = true 
}