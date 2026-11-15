[CmdletBinding(DefaultParameterSetName = 'build')]
param (
    [Parameter(Mandatory, Position = 0, ParameterSetName = 'build')]
    [Parameter(Mandatory, Position = 0, ParameterSetName = 'release')]
    [Parameter(Mandatory, Position = 0, ParameterSetName = 'packageOnly')]
    [ArgumentCompleter({
        param(
            [Parameter()]
            $CmdName,

            [Parameter()]
            $ParamName,

            [Parameter()]
            $WordToComplete
        )

        Get-ChildItem -Path (Join-Path $PSScriptRoot "solutions\$WordToComplete*") -Directory |
            Select-Object -ExpandProperty BaseName
    })]
    [ValidateScript({
        $filteredSolutions = Get-ChildItem -Path (Join-Path $PSScriptRoot 'solutions') -Directory |
            Select-Object -ExpandProperty BaseName
        $_ -in $filteredSolutions
    })]
    [string] $SolutionName,

    [Parameter(Mandatory, ParameterSetName = 'release')]
    [switch] $Release,

    [Parameter(Mandatory, ParameterSetName = 'packageOnly')]
    [switch] $PackageOnly,

    [Parameter(ParameterSetName = 'build')]
    [Parameter(ParameterSetName = 'release')]
    [switch] $SkipScriptQA,

    [Parameter(ParameterSetName = 'build')]
    [Parameter(ParameterSetName = 'release')]
    [switch] $SkipSolutionQA,

    [Parameter(ParameterSetName = 'release')]
    [ValidateSet('test', 'production')]
    [string] $ReleaseFeedType = 'production',

    [switch] $DisableGitTagging
)

#region Initialize module cache
$pathSeparator = [System.IO.Path]::PathSeparator
$moduleCachePath = Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath 'out') -ChildPath 'modulecache'
if (-not (Test-Path -Path $moduleCachePath)) {
    $null = New-Item -Path $moduleCachePath -ItemType Directory
}

if ($moduleCachePath -notin ($env:PSModulePath -split $pathSeparator)) {
    Write-Verbose -Message 'Prepending module cache directory to PSModulePath.'
    $env:PSModulePath = $moduleCachePath, $env:PSModulePath -join $pathSeparator
}
#endregion

#region Bootstrap PSDepend
$psDependPath = Join-Path -Path $moduleCachePath -ChildPath 'PSDepend'
if (-not (Test-Path -Path $psDependPath)) {
    Write-Verbose -Message 'Bootstrapping PSDepend.'
    $installPSDependParams = @{
        Name       = 'PSDepend'
        Confirm    = $false
        Force      = $true
        Path       = $moduleCachePath
        Repository = 'PSGallery'
    }
    $null = Save-Module @installPSDependParams
}

$psDependResolvedPath = Resolve-Path -Path (Join-Path $psDependPath '*/PSDepend.psd1')
Import-Module -Name $psDependResolvedPath
#endregion

#region Install dependencies
$buildDependPath = Join-Path -Path (Join-Path $PSScriptRoot '.depend') -ChildPath 'solutions.depend.psd1'
$solutionSpecificBuildDependPath = Join-Path -Path (Join-Path (Join-Path $PSScriptRoot 'solutions') $SolutionName) -ChildPath "$SolutionName.build.depend.psd1"

if (Test-Path -Path $solutionSpecificBuildDependPath) {
    Write-Verbose -Message "Handling solution-specific build dependencies from $solutionSpecificBuildDependPath."
    $invokePSDependArgs = @{
        Path = $buildDependPath, $solutionSpecificBuildDependPath
    }
}
else {
    Write-Verbose -Message "Handling solution common build dependencies from $buildDependPath."
    $invokePSDependArgs = @{
        Path = $buildDependPath
    }
}

$dependenciesInstalled = Invoke-PSDepend -Test @invokePSDependArgs
if ($dependenciesInstalled.DependencyExists -contains $false) {
    $null = Invoke-PSDepend -Force -Install @invokePSDependArgs
}
#endregion

#region Restart through Invoke-Build when called directly
if ($MyInvocation.ScriptName -notlike '*Invoke-Build.ps1') {
    Invoke-Build $null $MyInvocation.MyCommand.Path @PSBoundParameters
    return
}
#endregion

#region Tasks
Set-BuildHeader -Script {
    param(
        [Parameter()]
        $Path
    )

    ''
    '=' * 79
    Write-Build -Color 'Cyan' -Text "`t`t$($Task.Name.Replace('_', ' ').ToUpper())"
    # Write-Build -Color 'DarkGray' -Text "$(Get-BuildSynopsis $Task)"
    '-' * 79
    Write-Build -Color 'DarkGray' -Text "  $Path"
    Write-Build -Color 'DarkGray' -Text "  $($Task.InvocationInfo.ScriptName):$($Task.InvocationInfo.ScriptLineNumber)"
    ''
}

Write-Verbose -Message 'Importing Invoke-Build tasks.'
$buildTasks = 'solutions', 'azdevops', 'nuget', 'scripts', 'files'
$invokeBuildTasksPath = Join-Path -Path $PSScriptRoot -ChildPath '.build'

foreach ($buildTask in $buildTasks) {
    $buildTaskPath = Join-Path -Path $invokeBuildTasksPath -ChildPath $buildTask
    if (Test-Path -Path $buildTaskPath) {
        Get-ChildItem -Path $buildTaskPath -Filter '*.ps1' -Recurse -File |
            ForEach-Object -Process {
                Write-Verbose -Message "Importing task file $($_.BaseName)."
                . $_.FullName
            }
    }
}

$solutionSpecificBuildScriptPath = Join-Path -Path (Join-Path (Join-Path $PSScriptRoot 'solutions') $SolutionName) -ChildPath "$SolutionName.build.ps1"
if (Test-Path -Path $solutionSpecificBuildScriptPath) {
    Write-Verbose -Message "Loading solution-specific build tasks from $solutionSpecificBuildScriptPath."
    . $solutionSpecificBuildScriptPath
}
else {
    Write-Verbose -Message "No solution-specific build tasks found at $solutionSpecificBuildScriptPath."
    Task Solution_Specific_Build { }
}
#endregion

#region Execute required task flow
if ($Release) {
    Write-Verbose -Message 'Test, package and release.'
    if (-not $env:TF_BUILD) {
        throw 'Releases are only allowed to run in an Azure DevOps pipeline.'
    }

    if (($ReleaseFeedType -eq 'test') -and $DisableGitTagging) {
        Task . Connect_Az_DevOps, QATest, Pack, PublishPackage
    }
    else {
        Task . Connect_Az_DevOps, QATest, Pack, Tag_Az_DevOps, PublishPackage
    }
}
elseif ($PackageOnly) {
    Task . Pack
}
else {
    Write-Verbose -Message 'Test and package.'
    Task . QATest, Pack
}
#endregion
