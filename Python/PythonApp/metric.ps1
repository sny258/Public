${Env:AZP_URL} = "https://dev.azure.com/snyverma1994"
${Env:AZP_POOL} = "default"
${Env:AZP_TOKEN} = "hqp7xi75oa5yoe52squxmgsn46de56i6l3fk4rv2j7mefzgcdm7a"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$EncodedPAT = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(":${Env:AZP_TOKEN}"))
Write-Output($EncodedPAT)

$PoolsUrl = "${Env:AZP_URL}/_apis/distributedtask/pools?api-version=5.1"
try {
 $Pools = (Invoke-RestMethod -Uri $PoolsUrl -Method 'Get' -Headers @{Authorization = "Basic $EncodedPAT"}).value
} catch {
 throw $_.Exception
}
#write-host $pools
If ($Pools) {
 $PoolId = ($Pools | Where-Object { $_.Name -eq ${Env:AZP_POOL} }).id
 write-host "poolId- "$PoolId
}

#to get the online agents count in the AgentPool
$AgentsUrl = "${Env:AZP_URL}/_apis/distributedtask/pools/$($PoolId)/agents?api-version=5.1"
$Agents = (Invoke-RestMethod -Uri $AgentsUrl -Method 'Get' -Headers @{Authorization = "Basic $EncodedPAT"}).value
#write-host $Agents
 
if ($Agents) {
  #Checking the count of Online agents in the AgentPool
  $AgentNames = ($Agents | Where-Object { $_.status -eq 'Online'}).Name
  #$AgentIds = ($Agents).id
  $AgentIds = ($Agents | Where-Object { $_.status -eq 'Online'}).id
  $count = ($AgentIds).count
  write-host "Online Agents- "$count
}

#to get the the running jobs and queued jobs count
$jobsurl = "${Env:AZP_URL}/_apis/distributedtask/pools/$($PoolId)/jobrequests?api-version=5.1"
$jobs = (Invoke-RestMethod -Uri $jobsurl -Method 'Get' -Headers @{Authorization = "Basic $EncodedPAT"}).value
#write-host $jobs

If ($jobs) {
 # for completed jobs there will be result property
 #$rjobid = ($jobs | Where-Object { $_.PSobject.Properties.name -notcontains "result" } ).requestid
 #write-host "running jobid- "$rjobid

 # So if there is no finishTime, and also not receiveTime, then it is queued.
 $Qjobid = ($jobs | Where-Object { ($_.PSobject.Properties.name -notcontains "finishTime") -and ($_.PSobject.Properties.name -notcontains "receiveTime") } ).requestid
 write-host "Queued job ids- "$Qjobid
 $Qcount = ($Qjobid).count
 write-host "Queued jobs- "$Qcount

 # When there is no finishTime, but there is a receiveTime, it is running.
 $Rjobid = ($jobs | Where-Object { ($_.PSobject.Properties.name -notcontains "finishTime") -and ($_.PSobject.Properties.name -contains "receiveTime") } ).requestid
 write-host "Running job ids- "$Rjobid
 $Rcount = ($Rjobid).count
 write-host "Running jobs- "$Rcount
}