output "json_map" {
  description = "Map type of container definition"
  value       = jsondecode(module.container.json_map)
}

output "json" {
  description = "String type of container definition"
  value       = module.container.json_map
}