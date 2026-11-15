function Get-AzDevOpsPackageFeed {
    [CmdletBinding(DefaultParameterSetName = 'list')]
    param (
        [Parameter(Mandatory, ParameterSetName = 'named')]
        [ValidateNotNullOrEmpty()]
        [string] $Name
    )

    begin {
        if ($null -eq $script:AzDevOpsToken) {
            throw 'Use Connect-AzDevOps first!'
        }
    }

    process {
        try {
            $result = (Invoke-RestMethod -Uri ('https://feeds.dev.azure.com/{0}/_apis/packaging/feeds?api-version=5.1-preview.1' -f $script:AzDevOpsOrg) -Headers @{
                Authorization = 'Basic {0}' -f $script:AzDevOpsToken
            } -ErrorAction Stop).value

            $result | ForEach-Object -Process {
                if ($PSBoundParameters.ContainsKey('Name') -and $_.name -ne $Name) {
                    return
                }

                [void] $_.PSObject.TypeNames.Insert(0, 'AzDevOpsPackageFeed')
                $_
            }
        }
        catch {
            $PSCmdlet.WriteError($_)
        }
    }
}

function Get-AzDevOpsPackageFeedPackage {
    [CmdletBinding(DefaultParameterSetName = 'list')]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [PSTypeNameAttribute('AzDevOpsPackageFeed')]
        $Feed,

        [Parameter(Mandatory, ParameterSetName = 'named')]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [switch] $IncludeDeleted,
        [switch] $IncludeAllVersions
    )

    begin {
        if ($null -eq $script:AzDevOpsToken) {
            throw 'Use Connect-AzDevOps First!'
        }
    }

    process {
        try {
            if ($null -eq $Feed.project) {
                $url = 'https://feeds.dev.azure.com/{0}/_apis/packaging/feeds/{1}/packages?api-version=5.1-preview.1' -f $script:AzDevOpsOrg, $Feed.Id
            }
            else {
                $url = 'https://feeds.dev.azure.com/{0}/{1}/_apis/packaging/feeds/{2}/packages?api-version=5.1-preview.1' -f $script:AzDevOpsOrg, $Feed.project, $Feed.Id
            }

            if ($IncludeDeleted) {
                $url = "$url&includeDeleted=true"
            }

            if ($IncludeAllVersions) {
                $url = "$url&includeAllVersions=true"
            }

            $result = (Invoke-RestMethod -Uri $url -Headers @{
                Authorization = 'Basic {0}' -f $script:AzDevOpsToken
            } -ErrorAction Stop).value

            $result | ForEach-Object -Process {
                if ($PSBoundParameters.ContainsKey('Name') -and $_.name -ne $Name) {
                    return
                }

                $_
            }
        }
        catch {
            $PSCmdlet.WriteError($_)
        }
    }
}

function Get-AzDevOpsRepository {
    [CmdletBinding(DefaultParameterSetName = 'list')]
    param (
        [Parameter(Mandatory, ParameterSetName = 'named')]
        [ValidateNotNullOrEmpty()]
        [string] $Name
    )

    begin {
        if ($null -eq $script:AzDevOpsToken) {
            throw 'Use Connect-AzDevOps first!'
        }
    }

    process {
        try {
            $result = (Invoke-RestMethod -Uri ('https://{0}.visualstudio.com/_apis/git/repositories?api-version=5.1-preview.1' -f $script:AzDevOpsOrg) -Headers @{
                Authorization = 'Basic {0}' -f $script:AzDevOpsToken
            } -ErrorAction Stop).value

            $result | ForEach-Object -Process {
                if ($PSBoundParameters.ContainsKey('Name') -and $_.name -ne $Name) {
                    return
                }

                $_
            }
        }
        catch {
            $PSCmdlet.WriteError($_)
        }
    }
}

function New-AzDevOpsAnnotatedTag {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Message,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $CommitSha,

        [Parameter(Mandatory, ValueFromPipeline)]
        [pscustomobject] $Repository
    )

    begin {
        if ($null -eq $script:AzDevOpsToken) {
            throw 'Use Connect-AzDevOps first!'
        }
    }

    process {
        $body = @{
            name        = $Name
            taggedObject = @{
                objectId = $CommitSha
            }
            message     = $Message
        } | ConvertTo-Json

        try {
            Invoke-RestMethod -Uri ('https://{0}.visualstudio.com/{1}/_apis/git/repositories/{2}/annotatedtags?api-version=5.1-preview.1' -f $script:AzDevOpsOrg, $Repository.project.id, $Repository.id) -Headers @{
                Authorization = 'Basic {0}' -f $script:AzDevOpsToken
            } -ErrorAction Stop -ContentType 'application/json' -Method Post -Body $body
        }
        catch {
            $PSCmdlet.WriteError($_)
        }
    }
}
