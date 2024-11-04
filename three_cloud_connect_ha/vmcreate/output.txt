output "tls_private_key" {
  description = "Azure VM"
  value       = tls_private_key.myazssh.private_key_pem
  sensitive   = true
}
