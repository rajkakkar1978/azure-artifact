param (
    [string] $SolutionName = (property SolutionName),
    [bool] $SkipScriptQA = (property SkipScriptQA),
    [bool] $SkipSolutionQA = (property SkipSolutionQA),
    [string] $ReleaseFeedType = (property ReleaseFeedType)
)

$solutionPath = Join-Path -Path (Join-Path -Path $BuildRoot -ChildPath 'solutions') -ChildPath $SolutionName
$sourceFolder = Join-Path -Path $solutionPath -ChildPath 'src'
$solutionQATestPath = Join-Path -Path (Join-Path -Path $solutionPath -ChildPath 'tests') -ChildPath "$SolutionName.tests.ps1"
$outFolder = Join-Path -Path $BuildRoot -ChildPath 'out'
$buildFolder = Join-Path -Path (Join-Path -Path $outFolder -ChildPath 'solutions') -ChildPath $SolutionName
$testResultFolder = Join-Path -Path $buildFolder -ChildPath 'testresult'
$stagingFolder = Join-Path -Path $buildFolder -ChildPath 'staging'
$nupkgFolder = Join-Path -Path $buildFolder -ChildPath 'nupkg'

if ($ReleaseFeedType -eq 'test') {
    $feedName = 'keos-solutions-test'
    $tagNamePrefix = 'test-'
}
else {
    $feedName = 'keos-solutions'
}
