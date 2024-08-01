import-module au

$releases = 'https://nr-downloads-main.s3.amazonaws.com/?delimiter=/&prefix=infrastructure_agent/windows/'

function global:au_SearchReplace {
   @{
        ".\tools\chocolateyInstall.ps1" = @{
            "(?i)(^\s*url64bit\s*=\s*)('.*')"   = "`$1'$($Latest.URL64)'"
            "(?i)(^\s*checksum64\s*=\s*)('.*')" = "`$1'$($Latest.Checksum64)'"
        }
    }
}

function global:au_GetLatest {

    ## Download List of Installers
    [xml]$download_page = Invoke-WebRequest -Uri $releases -UseBasicParsing

    ## Set Regex Pattern
    $re = 'infrastructure_agent/windows/newrelic-infra.(\d.+)*\.msi$'

    ## Find Matching Pattern
    $match = $download_page.ListBucketResult.Contents | ? Key -match $re | Sort-Object -Desc -Property LastModified | select -First 1

    ## Use Regex to Grab the Version
    $version = $match.Key -replace $re, '$1'

    # Generate URL
    $url = "https://download.newrelic.com/infrastructure_agent/windows/newrelic-infra.$($version).msi"


    @{
        Version      = $version
        URL64        = $url
    }
}

try {
    update
} catch {
    $ignore = 'Unable to connect to the remote server'
    if ($_ -match $ignore) { Write-Host $ignore; 'ignore' }  else { throw $_ }
}