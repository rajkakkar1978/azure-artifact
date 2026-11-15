# Synopsis: Tag an Azure DevOps commit
Task 'Tag_Az_DevOps' {
    # tagName and tagMessage need to be set in an earlier task as $script:tagName and $script:tagMessage.
    Get-AzDevOpsRepository -Name $env:BUILD_REPOSITORY_NAME |
        New-AzDevOpsAnnotatedTag -Name $tagName -Message $tagMessage -CommitSha $env:BUILD_SOURCEVERSION
}
