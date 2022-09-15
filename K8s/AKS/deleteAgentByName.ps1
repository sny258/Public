#script to delete the agent from AgentPool by agent name

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
 write-host "poolId- "$PoolId
 $AgentsUrl = "${Env:AZP_URL}/_apis/distributedtask/pools/$($PoolId)/agents?api-version=5.1"
 $Agents = (Invoke-RestMethod -Uri $AgentsUrl -Method 'Get' -Headers @{Authorization = "Basic $EncodedPAT"}).value
 
 if ($Agents) {
   
   #write-host ${Env:MY_POD_NAME}
   #$AgentName = ($Agents | Where-Object { $_.name -eq $($AgentName)}).Name
   $AgentId = ($Agents | Where-Object { $_.name -eq ${Env:MY_POD_NAME} }).id
   
   Write-Output "Removing: ${Env:MY_POD_NAME} From Pool: ${Env:AZP_POOL} from Organization: ${Env:AZP_URL}"
   $DeleteAgentsUrl = "${Env:AZP_URL}/_apis/distributedtask/pools/$($PoolId)/agents/$($AgentId)?api-version=5.1"
   Invoke-RestMethod -Uri $DeleteAgentsUrl -Method 'Delete' -Headers @{Authorization = "Basic $EncodedPAT"}
 } else {
   Write-Output "No Agent found in ${Env:AZP_POOL} named ${Env:MY_POD_NAME}"
 }
} else {
 Write-Output "No Pools named ${Env:AZP_POOL} found"
}