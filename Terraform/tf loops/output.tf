# output "azure_subnet_id" {
#     value = {
#         for id in keys(var.subnets) : id => azurerm_subnet.subnet[id].id
#     }
#     description = "Lists the ID's of the subnets"
# }

# For set type variable
# output "azure_subnet_id" {
#     value = {
#         for id in var.subnets : azurerm_subnet.subnet[id].name => azurerm_subnet.subnet[id].id
#     }
#     description = "Lists the ID's of the subnets"
# }

# For map type variable
output "azure_subnet_id" {
    value = {
        #for id in keys(var.subnets) : id => azurerm_subnet.subnet[id].id
        for k, v in var.subnets : k => azurerm_subnet.subnet[k].id
    }
    description = "Lists the ID's of the subnets"
}