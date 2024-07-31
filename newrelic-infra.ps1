$Params = @{
  Algorithm = 'SHA256';
  URL = @{};
  LocalFile = @{};
  Hash = @{};
  ProductCode = @{};
}
$Package     = 'newrelic-infra'
$RSSfeed     = 'https://docs.newrelic.com/docs/release-notes/infrastructure-release-notes/infrastructure-agent-release-notes/feed.xml'

Try{ 
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  [xml]$RSSResults = $(Invoke-WebRequest -Uri $RSSfeed -ErrorAction Stop).Content
}
Catch [System.Exception]{ 
  $WebReqErr = $error[0] | Select-Object * | Format-List -Force 
  Write-Error "An error occurred while attempting to connect to the requested site.  The error was $WebReqErr.Exception"
}

$Sorted = $RSSResults.rss.channel.item | Sort-Object -Desc -Property @{e={$_.pubDate -as [datetime]}}
$Version = $Sorted[0].title.InnerText -replace '(.*\bv)(\d.+)', '$2'
$ReleaseNotes = $Sorted[0].link

$PackageName = 'newrelic-infra.${Version}.msi'
$PackageURL  = "https://download.newrelic.com/infrastructure_agent/windows/$PackageName" 

Write-Output `
  $Package `
  "Release Version: $Version" `
  "Release Notes: $ReleaseNotes" `
  "Release Package Name: $PackageName" `
  "Release Package URL: $PackageURL"

New-Item `
  -ItemType Directory `
  -Path "$PSScriptRoot\output\binaries","$PSScriptRoot\output\tools\" `
  -ErrorAction SilentlyContinue | Out-Null

$Params['URL']['x64'] = $ExecutionContext.InvokeCommand.ExpandString($PackageURL)
$Params['LocalFile']['x64'] = "$PSScriptRoot\output\binaries\$($ExecutionContext.InvokeCommand.ExpandString($PackageName))"

Invoke-WebRequest `
  -Uri $Params['URL']['x64'] `
  -OutFile $Params['LocalFile']['x64']
Write-Output "Downloaded x64 from $($Params['URL']['x64'])"

$Params['Hash']['x64'] = Get-FileHash `
  -Path $Params['LocalFile']['x64'] `
  -Algorithm $Params['Algorithm']
Write-Output "Created x64 $($Params['Algorithm']): $($Params['Hash']['x64'].Hash)"

$Params['ProductCode']['x64'] = $(.\Get-MSIFileInformation.ps1 -Path $Params['LocalFile']['x64'] -Property ProductCode)[3]
Write-Output "Found x64 ProductCode: $($Params['ProductCode']['x64'])"

Start-Process "msiexec" -ArgumentList "/a $($Params['LocalFile']['x64']) /qn TARGETDIR=$PSScriptRoot\temp\x64" -Wait

$LicenseFile = $(Get-ChildItem -Recurse $PSScriptRoot\temp\ | Where-Object {$_.Name -like "LICENSE.txt"})
Copy-Item $LicenseFile[0].FullName -Destination "$PSScriptRoot\output"
Write-Output "Copied output\License.txt"

$(Get-Content -Path "$PSScriptRoot\templates\$Package.nuspec") `
  -replace '##VERSION##', $Version `
  -replace '##RELEASENOTES##', $ReleaseNotes | `
  Out-File "$PSScriptRoot\output\$Package.nuspec"
Write-Output 'Created output\$Package.nuspec'

$(Get-Content -Path "$PSScriptRoot\templates\chocolateyInstall.ps1") `
  -replace '##FILEx64##', "$(& {$OS='x64'; $($ExecutionContext.InvokeCommand.ExpandString($PackageName))})" `
  -replace '##SHA256x64##', $Params['Hash']['x64'].Hash | `
  Out-File "$PSScriptRoot\output\tools\chocolateyInstall.ps1"
Write-Output 'Created output\tools\chocolateyInstall.ps1'

$(Get-Content -Path "$PSScriptRoot\templates\chocolateyUninstall.ps1") `
  -replace '##PRODUCTCODEx64##', $Params['ProductCode']['x64'] | `
  Out-File "$PSScriptRoot\output\tools\chocolateyUninstall.ps1"
Write-Output 'Created output\tools\chocolateyUninstall.ps1'

Copy-Item -Path "$PSScriptRoot\templates\chocolateyBeforeModify.ps1" `
  -Destination "$PSScriptRoot\output\tools\chocolateyBeforeModify.ps1"
Write-Output 'Created output\tools\chocolateyBeforeModify.ps1'

Copy-Item -Path "$PSScriptRoot\templates\VERIFICATION.txt" `
  -Destination "$PSScriptRoot\output\tools\VERIFICATION.txt"
Write-Output 'Created output\tools\VERIFICATION.txt'

Set-Item -Path ENV:NUPKG_VERSION -Value "$Version"  
Set-Item -Path ENV:NUPKG -Value "$Package.$Version.nupkg"