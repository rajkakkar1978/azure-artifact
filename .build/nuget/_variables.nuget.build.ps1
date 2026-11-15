$nugetQATestPath = Join-Path -Path (Join-Path -Path $BuildRoot -ChildPath 'tests') -ChildPath 'nuget.tests.ps1'
$script:stagingFolder = Join-Path -Path $BuildRoot -ChildPath 'staging'
$script:nupkgFolder = Join-Path -Path $BuildRoot -ChildPath 'nupkg'
