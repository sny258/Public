terraform init -backend=false
terraform validate 
Remove-Item -LiteralPath ".terraform" -Force -Recurse
Remove-Item -Path ".terraform.lock.hcl" -Force