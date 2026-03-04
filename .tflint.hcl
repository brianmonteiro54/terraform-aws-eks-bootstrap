# =============================================================================
# TFLint Configuration
# =============================================================================

config {
  call_module_type = "all"
  force            = false
}

# -----------------------------------------------------------------------------
# Plugins
# -----------------------------------------------------------------------------

plugin "aws" {
  enabled = true
  version = "0.45.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

plugin "terraform" {
  enabled = true
  version = "0.14.1"
  source  = "github.com/terraform-linters/tflint-ruleset-terraform"
  preset  = "recommended"
}

# -----------------------------------------------------------------------------
# AWS Rules
# -----------------------------------------------------------------------------

# --- EC2 Instance ---
rule "aws_instance_invalid_type" {
  enabled = true
}

rule "aws_instance_previous_type" {
  enabled = true
}

rule "aws_instance_invalid_ami" {
  enabled = true
}

rule "aws_instance_invalid_vpc_security_group" {
  enabled = true
}

rule "aws_instance_invalid_key_name" {
  enabled = true
}

# --- Security Group ---
rule "aws_security_group_invalid_vpc_id" {
  enabled = true
}

# -----------------------------------------------------------------------------
# Terraform Best Practices
# -----------------------------------------------------------------------------

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true

  variable { format = "snake_case" }
  locals   { format = "snake_case" }
  output   { format = "snake_case" }
  resource { format = "snake_case" }
  module   { format = "snake_case" }
  data     { format = "snake_case" }
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_module_pinned_source" {
  enabled = true
}

rule "terraform_module_version" {
  enabled = true
}

rule "terraform_deprecated_index" {
  enabled = true
}

rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_workspace_remote" {
  enabled = true
}

rule "terraform_comment_syntax" {
  enabled = true
}

rule "terraform_standard_module_structure" {
  enabled = true
}