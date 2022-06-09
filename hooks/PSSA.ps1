#powershell.exe -executionpolicy bypass         #to bypass execution policy error.

$ScriptDirectory = Split-Path -parent $MyInvocation.MyCommand.path
#write-host $ScriptDirectory

Invoke-ScriptAnalyzer -Path $ScriptDirectory -Recurse       #it will provide all issues.

#Invoke-ScriptAnalyzer -Path $ScriptDirectory -Recurse -severity ParseError     #It will provide parse errors only.