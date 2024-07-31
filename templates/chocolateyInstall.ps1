$ErrorActionPreference = 'Stop';

$additionalArgs = ''
$packageParameters = Get-PackageParameters

# see if any parameters were passed
if ($packageParameters['GenerateConfig']) { $GenerateConfig = $packageParameters['GenerateConfig'] }
if ($packageParameters['LicenseKey']) { $LicenseKey = $packageParameters['LicenseKey'] }
if ($packageParameters['DisplayName']) { $DisplayName = $packageParameters['DisplayName'] }
if ($packageParameters['Proxy']) { $Proxy = $packageParameters['Proxy'] }
if ($packageParameters['CustomAttributes']) { $CustomAttributes = $packageParameters['CustomAttributes'] }

if(Get-Variable -Name GenerateConfig -ErrorAction SilentlyContinue) {
  $additionalArgs = 'GENERATE_CONFIG=true'

  if(Get-Variable -Name LicenseKey -ErrorAction SilentlyContinue) {
    $additionalArgs += " LICENSE_KEY=$LicenseKey"
  }

  if(Get-Variable -Name DisplayName -ErrorAction SilentlyContinue) {
    $additionalArgs += " DISPLAY_NAME=$DisplayName"
  }

  if(Get-Variable -Name Proxy -ErrorAction SilentlyContinue) {
    $additionalArgs += " PROXY=$Proxy"
  }

  if(Get-Variable -Name CustomAttributes -ErrorAction SilentlyContinue) {
    $additionalArgs += " CUSTOM_ATTRIBUTES=$CustomAttributes"
  }
}

$packageName     = 'newrelic-infra'
$softwareName    = 'newrelic-infra*'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

$packageArgs = @{
  PackageName = $package;
  FileType       = 'MSI';
  silentArgs    = "/qn $additionalArgs /norestart /l*v `"$($env:TEMP)\$($packageName).$($env:chocolateyPackageVersion).MsiInstall.log`""
  file64         = "$launch_path\..\binaries\##FILEx64##";
  checksum64     = '##SHA256x64##'
  checksumType64 = 'sha256'
  validExitCodes= @(0, 3010, 1641)
  softwareName  = $softwareName
}

Install-ChocolateyPackage @packageArgs

#AutoStart
#Start-Service newrelic-infra