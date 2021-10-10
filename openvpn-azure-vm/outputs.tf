output "run_for_copy_openvpn_client_configs" {
    value = "scp -r -o StrictHostKeyChecking=no ${var.user_name}@${azurerm_public_ip.main.fqdn}:/home/${var.user_name}/openvpn/ready_client_conf ~/Downloads/"
}
