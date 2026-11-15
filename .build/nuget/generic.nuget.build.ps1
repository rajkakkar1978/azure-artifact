# Synopsis: Create staging folder
Task 'Create_Staging_Folder' {
    if (Test-Path -Path $stagingFolder) {
        Write-Build -Color 'Green' -Text "Removing: $stagingFolder"
        Remove-Item -Path $stagingFolder -Recurse -Force
    }

    Write-Build -Color 'Green' -Text "Creating at: $stagingFolder"
    $null = New-Item -Path $stagingFolder -ItemType Directory
}

# Synopsis: Copy files to staging directory
Task 'Copy_Files_Staging' {
    if ($script:packageSourceFolder) {
        Copy-Item -Path (Join-Path $script:packageSourceFolder '*') -Destination $stagingFolder -Recurse -Force
    }
    else {
        Copy-Item -Path (Join-Path $script:sourceFolder '*') -Destination $stagingFolder -Recurse -Force
    }
}

# Synopsis: Update nuspec version
Task 'Update_NuSpec_Version' -After Copy_Files_Staging {
    $nuspecFile = Resolve-Path -Path (Join-Path $stagingFolder '*.nuspec')
    $nuspecContent = [xml](Get-Content -Path $nuspecFile)
    $script:packageName = $nuspecContent.package.metadata.id
    $nuspecVersion = [version]$nuspecContent.package.metadata.version

    Write-Build -Color 'Green' -Text "Build Reason: $env:BUILD_REASON"
    switch ($env:BUILD_REASON) {
        'PullRequest' {
            $script:projectVersionNumber = [version]::new(0, 0, [int]$env:BUILD_BUILDID)
            Write-Build -Color 'Green' -Text "PR build package will be versioned with Azure DevOps Build Number: $script:projectVersionNumber"
        }
        { $_ -in 'IndividualCI', 'Manual' -and $script:Release.IsPresent } {
            $script:projectVersionNumber = Build-KeosPackageVersion -FeedName $feedName -PackageName $script:packageName -NuSpecVersion $nuspecVersion
        }
        default {
            $script:projectVersionNumber = $nuspecVersion
            Write-Build -Color 'Green' -Text 'NuGet package will be versioned with the nuspec version.'
        }
    }

    $script:tagName = "$($script:tagNamePrefix)$($script:packageName)-$($script:projectVersionNumber)"
    $script:tagMessage = $nuspecContent.package.metadata.releaseNotes
}
