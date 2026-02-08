provider "snowflake" {
  account_name  = "cr56839"
  organization_name  = "vvyellg"
  user     = var.snowflake_user
  password = var.snowflake_password
  role     = var.snowflake_role
}
