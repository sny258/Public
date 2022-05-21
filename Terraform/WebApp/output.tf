output "website_hostname" {
  value       = azurerm_app_service.apps.default_site_hostname
  description = "The hostname of the website"
}