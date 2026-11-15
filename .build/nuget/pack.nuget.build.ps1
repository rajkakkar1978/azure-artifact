# Synopsis: Cleanup the nupkg folder in case of an additional run
Task 'Cleanup_nupkg_path' {
    if (Test-Path -Path $nupkgFolder) {
        Write-Build -Color 'Green' -Text "Removing: $nupkgFolder"
        Remove-Item -Path $nupkgFolder -Recurse -Force
    }

    Write-Build -Color 'Green' -Text "Creating at: $nupkgFolder"
    $null = New-Item -Path $nupkgFolder -ItemType Directory
}

# Synopsis: Package the staging folder into a NuGet package
Task 'Pack_NuGet' {
    Push-Location -Path $stagingFolder
    try {
        dotnet pack -o $nupkgFolder
        if ($LASTEXITCODE -ne 0) {
            throw 'Packaging failed.'
        }
    }
    finally {
        Pop-Location
    }
}

Task Pack Create_Staging_Folder, Copy_Files_Staging, Cleanup_nupkg_path, Solution_Specific_Build, Pack_NuGet {
    if (Get-BuildError -Task Pack_NuGet) {
        throw 'NuGet package creation failed.'
    }
}
