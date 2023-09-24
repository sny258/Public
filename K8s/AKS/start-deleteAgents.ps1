#to let status of terminated agent/s change to offline
#Start-Sleep -Seconds 90         


#Script to delete all offline agents for AgentPool

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$EncodedPAT = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(":${Env:AZP_TOKEN}"))
$PoolsUrl = "${Env:AZP_URL}/_apis/distributedtask/pools?api-version=5.1"
try {
 $Pools = (Invoke-RestMethod -Uri $PoolsUrl -Method 'Get' -Headers @{Authorization = "Basic $EncodedPAT"}).value
} catch {
 throw $_.Exception
}

If ($Pools) {
 $PoolId = ($Pools | Where-Object { $_.Name -eq ${Env:AZP_POOL} }).id
 #write-host "poolId- "$PoolId
 $AgentsUrl = "${Env:AZP_URL}/_apis/distributedtask/pools/$($PoolId)/agents?api-version=5.1"
 $Agents = (Invoke-RestMethod -Uri $AgentsUrl -Method 'Get' -Headers @{Authorization = "Basic $EncodedPAT"}).value
 
 if ($Agents) {
   
   $OffAgentNames = ($Agents | Where-Object { $_.status -eq 'Offline'}).Name
   #write-host "OfflineAgentNames- "$OffAgentNames
   $OffAgentIds = ($Agents | Where-Object { $_.status -eq 'Offline'}).id
   #write-host "OfflineAgentIds- "$OffAgentIds
   
   Write-Output "Removing: $($OffAgentNames) From Pool: ${Env:AZP_POOL} from Organization: ${Env:AZP_URL}"
   foreach ($OffAgentId in $OffAgentIds) {
     $OfflineAgentsUrl = "${Env:AZP_URL}/_apis/distributedtask/pools/$($PoolId)/agents/$($OffAgentId)?api-version=5.1"
	   #Write-Output $OfflineAgentsUrl
     Invoke-RestMethod -Uri $OfflineAgentsUrl -Method 'Delete' -Headers @{Authorization = "Basic $EncodedPAT"}
     }
 } else {
   Write-Output "No Agents found in ${Env:AZP_POOL}"
 }
} else {
 Write-Output "No Pools named ${Env:AZP_POOL} found"
}



#script to setup and start the agent on windows server

if (-not (Test-Path Env:AZP_URL)) {
  Write-Error "error: missing AZP_URL environment variable"
  exit 1
}

if (-not (Test-Path Env:AZP_TOKEN_FILE)) {
  if (-not (Test-Path Env:AZP_TOKEN)) {
    Write-Error "error: missing AZP_TOKEN environment variable"
    exit 1
  }

  $Env:AZP_TOKEN_FILE = "\azp\.token"
  $Env:AZP_TOKEN | Out-File -FilePath $Env:AZP_TOKEN_FILE
}

Remove-Item Env:AZP_TOKEN

if ((Test-Path Env:AZP_WORK) -and -not (Test-Path $Env:AZP_WORK)) {
  New-Item $Env:AZP_WORK -ItemType directory | Out-Null
}

# Let the agent ignore the token env variables
$Env:VSO_AGENT_IGNORE = "AZP_TOKEN,AZP_TOKEN_FILE"

Set-Location agent

try
{
  Write-Host "1. Configuring Azure Pipelines agent..." -ForegroundColor Cyan

  .\config.cmd --unattended `
    --agent "$(if (Test-Path Env:AZP_AGENT_NAME) { ${Env:AZP_AGENT_NAME} } else { hostname })" `
    --url "$(${Env:AZP_URL})" `
    --auth PAT `
    --token "$(Get-Content ${Env:AZP_TOKEN_FILE})" `
    --pool "$(if (Test-Path Env:AZP_POOL) { ${Env:AZP_POOL} } else { 'Default' })" `
    --work "$(if (Test-Path Env:AZP_WORK) { ${Env:AZP_WORK} } else { '_work' })" `
    --replace

  Write-Host "2. Running Azure Pipelines agent..." -ForegroundColor Cyan

  .\run.cmd
}
finally
{
  Write-Host "3. Cleanup. Removing Azure Pipelines agent..." -ForegroundColor Cyan

  .\config.cmd remove --unattended `
    --auth PAT `
    --token "$(Get-Content ${Env:AZP_TOKEN_FILE})"
}