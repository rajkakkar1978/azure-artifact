# Synopsis: Cleanup the test results folder in case of an additional run
Task 'Cleanup_Tests_Path' {
    if (Test-Path -Path $testResultFolder) {
        Remove-Item -Path $testResultFolder -Recurse -Force
    }

    $null = New-Item -Path $testResultFolder -ItemType Directory
}

# Synopsis: Run QA tests for a specific solution
Task 'Run_QA_Test_Specific_Solution' -If ((Test-Path -Path $solutionQATestPath) -and -not $SkipSolutionQA) {
    $nUnitTestResultFile = Join-Path -Path $testResultFolder -ChildPath 'QASolutionSpecificTestsResults-NUnit.xml'
    $pesterResultFile = Join-Path -Path $testResultFolder -ChildPath 'QASolutionSpecificPesterResultObject.xml'

    $pesterArgs = @{
        Script = @{
            Path = $solutionQATestPath
        }
        OutputFormat = 'NUnitXml'
        OutputFile = $nUnitTestResultFile
        PassThru = $true
    }

    Write-Build -Color 'Green' -Text 'Invoking Solution QA Tests'
    $res = Invoke-Pester @pesterArgs

    $res | Export-Clixml -Path $pesterResultFile -Force -Encoding utf8BOM
    if ($res.FailedCount -gt 0) {
        throw "$($res.FailedCount) tests failed."
    }
}

Task QATest Cleanup_Tests_Path, ?Run_QA_Test_File, ?Run_QA_Test_Specific_Solution, ?Run_QA_Test_Script, ?Run_QA_Test_Nuget_Files {
    if (Get-BuildError -Task Run_QA_Test_File) {
        throw 'File QA tests failed.'
    }
    if (Get-BuildError -Task Run_QA_Test_Specific_Solution) {
        throw 'Solution-specific QA tests failed.'
    }
    if (Get-BuildError -Task Run_QA_Test_Script) {
        throw 'Script QA tests failed.'
    }
    if (Get-BuildError -Task Run_QA_Test_Nuget_Files) {
        throw 'NuGet QA tests failed.'
    }
}
