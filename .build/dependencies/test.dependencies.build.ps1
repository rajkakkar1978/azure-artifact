# Synopsis: Run script QA tests
Task 'Run_QA_Test_Dependencies' {
    $nUnitTestResultFile = Join-Path -Path $testResultFolder -ChildPath 'QADependenciesResults.xml'
    $pesterResultFile = Join-Path -Path $testResultFolder -ChildPath 'QADependenciesPesterResults.xml'

    $writeBuildMessage = 'Invoking Dependencies QA Tests'
    $testScriptParams = @{
        SourcePath = $sourceFolder
    }

    if ($script:PipelineBuild.IsPresent -or $script:Release.IsPresent) {
        $testScriptParams.Add('InvokeKnownModuleDependencies', $true)
        $testScriptParams.Add('PatToken', $env:SYSTEM_ACCESSTOKEN)
        $writeBuildMessage += ' with ValidateIndirectKnownModuleDependencies'
    }

    $pesterArgs = @{
        Script = @{
            Path       = $dependencyQATestPath
            Parameters = $testScriptParams
        }
        OutputFormat = 'NUnitXml'
        OutputFile   = $nUnitTestResultFile
        PassThru     = $true
    }

    Write-Build -Color 'Green' -Text $writeBuildMessage
    $res = Invoke-Pester @pesterArgs

    $res | Export-Clixml -Path $pesterResultFile -Force -Encoding utf8BOM
    if ($res.FailedCount -gt 0) {
        throw "$($res.FailedCount) tests failed."
    }
}
