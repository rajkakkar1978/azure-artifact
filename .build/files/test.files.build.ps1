# Synopsis: Run script QA tests
Task 'Run_QA_Test_File' {
    $nUnitTestResultFile = Join-Path -Path $testResultFolder -ChildPath 'QAFileTestsResults-NUnit.xml'
    $pesterResultFile = Join-Path -Path $testResultFolder -ChildPath 'QAFilePesterResultObject.xml'

    $pesterArgs = @{
        Script = @{
            Path = $fileQATestPath
            Parameters = @{
                SourcePath = $sourceFolder
            }
        }
        OutputFormat = 'NUnitXml'
        OutputFile = $nUnitTestResultFile
        PassThru = $true
    }

    Write-Build -Color 'Green' -Text 'Invoking File QA Tests'
    $res = Invoke-Pester @pesterArgs

    $res | Export-Clixml -Path $pesterResultFile -Force -Encoding utf8BOM
    if ($res.FailedCount -gt 0) {
        throw "$($res.FailedCount) tests failed."
    }
}
