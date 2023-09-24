
Param (
      # [Parameter()]
      # [string] $pat=(New-Object System.Management.Automation.PsCredential bogususer,(convertto-SecureString (get-content ./prodpat.bin))).GetNetworkCredential().Password,

      [Parameter()]
      [string] $organization = "snyverma1994",

      [Parameter()]
      [string] $project = "sanju728",
            
      [Parameter()]
      [string] $pipelinename = "Nuget",
	  
	  [Parameter()]
      [string] $branchname = "main", #"feature/architecture/bapipelinecall"
	  
	  [Parameter(Mandatory = $true)]
      [string] $packagename
)

# if (-not $packagename) {
  # write-error "Need package name to continue."
  # break
# }

# write-host $($packagename)

$pipelineid = 16
$uri = "https://dev.azure.com/$($organization)/$($project)/_apis/build/builds?api-version=5.1"

$JSON = @"
{
  "templateParameters": {
    "package": "$($packagename)"
   },
   "sourceBranch": "$($branchname)",
   "definition": {
     "id": "$($pipelineid)"
    }
}
"@
write-host $JSON

# $JSON1 = @{templateParameters=@{Package=$($packagename)}}
# ConvertTo-json $JSON1 

$AzureDevOpsPAT = "pire3hkhbso6txvjeeynobejdplu56x62ybkdxxxxxxxxxxxx"
$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($AzureDevOpsPAT)")) }

Invoke-WebRequest -Uri $uri -Method POST -Headers $AzureDevOpsAuthenicationHeader -Body $JSON  -ContentType "application/json"


# powershell.exe -executionpolicy bypass
# .\trigger_pipeline.ps1 -pipelinename "publishnuget-pkg" -branchname "feat/publishnugetpkg" -package "samplepsmodule8.psm1"

