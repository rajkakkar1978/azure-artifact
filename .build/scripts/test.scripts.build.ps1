# Synopsis: Run script QA tests
Task 'Run_QA_Test_Script' -If (-not $SkipScriptQA) {
    $nUnitTestResultFile = Join-Path -Path $testResultFolder -ChildPath 'QAScriptTestsResults-NUnit.xml'
    $pesterResultFile = Join-Path -Path $testResultFolder -ChildPath 'QAScriptPesterResultObject.xml'

    $pesterArgs = @{
        Script = @{
            Path = $scriptQATestPath
            Parameters = @{
                SourcePath = $sourceFolder
            }
        }
        OutputFormat = 'NUnitXml'
        OutputFile = $nUnitTestResultFile
        PassThru = $true
    }

    Write-Build -Color 'Green' -Text 'Invoking Script QA Tests'
    $res = Invoke-Pester @pesterArgs

    $res | Export-Clixml -Path $pesterResultFile -Force -Encoding utf8BOM
    if ($res.FailedCount -gt 0) {
        throw "$($res.FailedCount) tests failed."
    }
}
