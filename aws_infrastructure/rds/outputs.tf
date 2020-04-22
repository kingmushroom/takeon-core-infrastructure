output "DBName" {
  value = "${random_string.username.result}"
}

output "password" {
  value = "${random_password.password.result}"
}
