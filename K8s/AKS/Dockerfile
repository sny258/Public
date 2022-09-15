FROM mcr.microsoft.com/windows/servercore:ltsc2022
ARG pat
WORKDIR /azp
COPY start.ps1 start-deleteAgents.ps1 deleteAgentByName.ps1 nestleroot.cer ./
RUN powershell -Command \
    $ErrorActionPreference = 'Stop'; \
    $ProgressPreference = 'SilentlyContinue'; \
    write-host 'Importing Certificate'; \
    Import-Certificate -FilePath 'c:\azp\nestleroot.cer' -CertStoreLocation 'Cert:\LocalMachine\Root'; \
    write-host "Installing Nestle Powershell Modules"; \
    Install-PackageProvider NuGet -Force; \
    $patToken = ConvertTo-SecureString -string $($env:pat) -AsPlainText -Force; \
    $credsAzureDevopsServices = New-Object System.Management.Automation.PSCredential('ben.herman@nestle.com', $patToken); \
    Register-PSRepository -Name 'iac-packages' -SourceLocation 'https://pkgs.dev.azure.com/nestle-it/_packaging/iac-packages/nuget/v2' -PublishLocation 'https://pkgs.dev.azure.com/nestle-it/_packaging/iac-packages/nuget/v2' -InstallationPolicy Trusted -Credential $credsAzureDevopsServices; \
    # install-module -Name 'nestle.az' -Repository iac-packages -Credential $credsAzureDevopsServices -Force; \
    "Find-Module -Repository iac-packages -Credential $credsAzureDevopsServices | install-module -Repository iac-packages -Credential $credsAzureDevopsServices -Force"; \
    write-host 'Terraform and Packer'; \
    Invoke-WebRequest -uri 'https://releases.hashicorp.com/terraform/1.1.9/terraform_1.1.9_windows_amd64.zip' -OutFile 'c:\azp\tf.zip'; \
    Expand-Archive -Path 'c:\azp\tf.zip' -DestinationPath 'c:\windows\system32'; \
    Remove-Item 'c:\azp\tf.zip' -Force; \
    Invoke-WebRequest -uri 'https://releases.hashicorp.com/terraform-provider-azurerm/3.5.0/terraform-provider-azurerm_3.5.0_windows_amd64.zip' -OutFile 'c:\azp\tfazurermprovider.zip'; \
    mkdir 'c:\windows\system32\providers'; \
    Expand-Archive -Path 'c:\azp\tfazurermprovider.zip' -DestinationPath 'c:\windows\system32\providers'; \
    Remove-Item 'c:\azp\tfazurermprovider.zip' -Force; \
    Invoke-WebRequest -uri 'https://releases.hashicorp.com/packer/1.8.0/packer_1.8.0_windows_amd64.zip' -OutFile 'c:\azp\packer.zip'; \
    Expand-Archive -Path 'c:\azp\packer.zip' -DestinationPath 'c:\windows\system32'; \
    Remove-Item 'c:\azp\packer.zip' -Force; \
    write-host 'Azure DevOps Agent'; \
    mkdir 'c:\azp\agent'; \
    Invoke-WebRequest -uri 'https://vstsagentpackage.azureedge.net/agent/2.202.1/vsts-agent-win-x64-2.202.1.zip' -OutFile 'c:\azp\azdoagent.zip'; \
    Expand-Archive -Path 'c:\azp\azdoagent.zip' -DestinationPath 'c:\azp\agent'; \
    Remove-Item 'c:\azp\azdoagent.zip' -Force; \
    write-host 'Powershell Modules'; \
    Invoke-WebRequest -Uri 'https://www.powershellgallery.com/api/v2/package/SqlServer/21.1.18256' -OutFile 'c:\azp\sqlmodule.zip'; \
    mkdir 'C:\Program Files\WindowsPowerShell\Modules\SqlServer\21.1.18256'; \
    Expand-Archive -Path 'c:\azp\sqlmodule.zip' -DestinationPath 'C:\Program Files\WindowsPowerShell\Modules\SqlServer\21.1.18256'; \
    Remove-Item 'c:\azp\sqlmodule.zip' -Force; \
    Invoke-WebRequest -Uri 'https://github.com/Azure/azure-powershell/releases/download/v7.5.0-April2022/Az-Cmdlets-7.5.0.35663-x64.msi' -OutFile 'c:\azp\azmodules.msi'; \
    Start-Process 'msiexec.exe' -Wait -ArgumentList '/I c:\azp\azmodules.msi /quiet'; \
    Remove-Item 'c:\azp\azmodules.msi' -Force; \
    write-host 'Azure cli'; \
    Invoke-WebRequest -uri 'https://azcliprod.blob.core.windows.net/msi/azure-cli-2.36.0.msi' -OutFile 'c:\azp\azurecli.msi'; \
    Start-Process 'msiexec.exe' -Wait -ArgumentList '/I','C:\azp\azurecli.msi','/quiet'; \
    Remove-Item 'c:\azp\azurecli.msi' -Force; \
    write-host 'Python'; \
    Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.10.4/python-3.10.4-amd64.exe' -OutFile 'c:\azp\python.exe'; \
    Start-Process 'c:\azp\python.exe' -Wait -ArgumentList '/quiet InstallAllUsers=1 PrependPath=1'; \
    Remove-Item 'c:\azp\python.exe' -Force; \
    write-host 'Installing Checkov'; \
    Start-Process 'C:\Program Files\Python310\Scripts\pip' -Wait -ArgumentList 'install checkov'; \
    write-host 'Domain Suffix Search List'; \
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters' -Name 'SearchList' -Type 'String' -Value 'nestle.com,ams.nestle.com,eur.nestle.com,ctr.nestle.com,aoa.nestle.com,globeint.ddc,nestle.w2k'; \
    write-host 'Done.'
CMD ["powershell.exe", "-File", "start-deleteAgents.ps1"] 
