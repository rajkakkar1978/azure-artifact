# Synopsis: Connect with Az DevOps
Task 'Connect_Az_DevOps' {
    if ([string]::IsNullOrWhiteSpace($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)) {
        throw 'SYSTEM_TEAMFOUNDATIONCOLLECTIONURI is not set.'
    }

    if ([string]::IsNullOrWhiteSpace($env:SYSTEM_ACCESSTOKEN)) {
        throw 'SYSTEM_ACCESSTOKEN is not set. Enable access to the OAuth token for the pipeline job.'
    }

    $collectionUri = [Uri] $env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI
    $organization = $collectionUri.AbsolutePath.Trim('/').Split('/')[0]
    if ([string]::IsNullOrWhiteSpace($organization) -or $organization -eq 'DefaultCollection') {
        $organization = $collectionUri.Host.Split('.')[0]
    }

    Write-Host -Object "Organisation: '$organization'" -ForegroundColor Green

    Connect-AzDevOps -Organization $organization -PatToken $env:SYSTEM_ACCESSTOKEN -ErrorAction Stop
}
