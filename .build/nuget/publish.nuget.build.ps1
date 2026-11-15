# Synopsis: Write NuGet config file with publishing information
Task 'Write_NuGetConfig' {
    if ([string]::IsNullOrWhiteSpace($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)) {
        throw 'SYSTEM_TEAMFOUNDATIONCOLLECTIONURI is not set.'
    }

    if ([string]::IsNullOrWhiteSpace($env:SYSTEM_ACCESSTOKEN)) {
        throw 'SYSTEM_ACCESSTOKEN is not set.'
    }

    $collectionUri = [System.Uri]$env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI
    if ($collectionUri.Host -ieq 'dev.azure.com') {
        $organization = $collectionUri.AbsolutePath.Trim('/').Split('/')[0]
    }
    elseif ($collectionUri.Host -like '*.visualstudio.com') {
        $organization = $collectionUri.Host.Split('.')[0]
    }
    else {
        throw "Unsupported SYSTEM_TEAMFOUNDATIONCOLLECTIONURI format: $($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)"
    }

    Write-Build -Color 'Green' -Text "Creating NuGet config for organization: $organization and feed: $feedName"

    @'
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <add key="AzDevOpsFeed" value="https://pkgs.dev.azure.com/{0}/{1}/_packaging/{2}/nuget/v3/index.json" />
  </packageSources>
  <packageSourceCredentials>
    <AzDevOpsFeed>
      <add key="Username" value="bogus" />
      <add key="ClearTextPassword" value="{3}" />
    </AzDevOpsFeed>
  </packageSourceCredentials>
</configuration>
'@ -f $organization, 'KPMGAU-BUS-KEOS_Azure', $feedName, $env:SYSTEM_ACCESSTOKEN |
        Out-File -FilePath .\nuget.config
}

# Synopsis: Publish the NuPkg to the feed
Task 'Publish_NuPkg_To_Feed' {
    try {
        $packageToPublishPath = Join-Path -Path $nupkgFolder -ChildPath "$packageName.$projectVersionNumber.nupkg" -Resolve
        Write-Build -Color 'Green' -Text "Publishing nupkg using path: $packageToPublishPath"

        dotnet nuget push $packageToPublishPath -s AzDevOpsFeed -k 'bogusKey' --no-service-endpoint
        if ($LASTEXITCODE -ne 0) {
            throw 'Publishing failed.'
        }
    }
    finally {
        if (Test-Path -LiteralPath .\nuget.config) {
            Remove-Item -LiteralPath .\nuget.config -Force
        }
    }
}

# Synopsis: Cleanup the NuGet.Config file from disk
Task 'Cleanup_NuGetConfig' {
    if (Test-Path -LiteralPath .\nuget.config) {
        Remove-Item -LiteralPath .\nuget.config -Force
    }
}

Task PublishPackage Write_NuGetConfig, Publish_NuPkg_To_Feed, Cleanup_NuGetConfig {
    if (Get-BuildError -Task Publish_NuPkg_To_Feed) {
        throw 'NuGet package publishing failed.'
    }
}
