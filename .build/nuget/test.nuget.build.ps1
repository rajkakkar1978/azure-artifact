# Synopsis: Run NuGet files QA tests
Task 'Run_QA_Test_Nuget_Files' {
    $nUnitTestResultFile = Join-Path -Path $testResultFolder -ChildPath 'QANugetTestsResults-NUnit.xml'
    $pesterResultFile = Join-Path -Path $testResultFolder -ChildPath 'QANugetPesterResultObject.xml'

    $pesterArgs = @{
        Script = @{
            Path = $nugetQATestPath
            Parameters = @{
                NugetFilesPath = $sourceFolder
            }
        }
        OutputFormat = 'NUnitXml'
        OutputFile = $nUnitTestResultFile
        PassThru = $true
    }

    Write-Build -Color 'Green' -Text 'Invoking Nuget QA Tests'
    $res = Invoke-Pester @pesterArgs

    $res | Export-Clixml -Path $pesterResultFile -Force -Encoding utf8BOM
    if ($res.FailedCount -gt 0) {
        throw "$($res.FailedCount) tests failed."
    }
}
