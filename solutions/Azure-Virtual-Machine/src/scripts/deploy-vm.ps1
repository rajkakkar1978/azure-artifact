[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $ResourceGroupName,

    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $TemplateParameterFile,

    [Parameter()]
    [System.Security.SecureString] $AdminPassword,

    [Parameter()]
    [System.Security.SecureString] $DomainPassword
)

$templatePath = Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..') -ChildPath 'armtemplates\avm\azuredeploy-vm.json'
$templatePath = [System.IO.Path]::GetFullPath($templatePath)
$parameterFilePath = [System.IO.Path]::GetFullPath($TemplateParameterFile)

if (-not (Test-Path -LiteralPath $templatePath -PathType Leaf)) {
    throw "ARM template not found: $templatePath"
}

$parameterFile = Get-Content -LiteralPath $parameterFilePath -Raw | ConvertFrom-Json -ErrorAction Stop
if (-not $parameterFile.parameters.virtualMachine.value) {
    throw "The parameter file must define parameters.virtualMachine.value: $parameterFilePath"
}

if (-not (Get-Command -Name New-AzResourceGroupDeployment -ErrorAction SilentlyContinue)) {
    throw 'New-AzResourceGroupDeployment is unavailable. Install the Az.Resources module.'
}

$azContext = Get-AzContext -ErrorAction SilentlyContinue
if (-not $azContext) {
    throw 'No Azure context is available. Run Connect-AzAccount and select a subscription first.'
}

if (-not $AdminPassword) {
    $AdminPassword = Read-Host -Prompt 'Enter the local administrator password' -AsSecureString
}
if ($AdminPassword.Length -eq 0) {
    throw 'The local administrator password cannot be empty.'
}

$virtualMachine = $parameterFile.parameters.virtualMachine.value
$deploymentParameters = @{}
foreach ($parameter in $parameterFile.parameters.PSObject.Properties) {
    if ($parameter.Name -notin @('adminPassword', 'domainPassword')) {
        $deploymentParameters[$parameter.Name] = $parameter.Value.value
    }
}
$deploymentParameters.adminPassword = $AdminPassword

if ($virtualMachine.domainJoin -and $virtualMachine.windowsOS) {
    if (-not $virtualMachine.domainName -or -not $virtualMachine.domainUsername) {
        throw 'The virtualMachine settings must include domainName and domainUsername when domainJoin is enabled for Windows.'
    }
    if (-not $DomainPassword) {
        $DomainPassword = Read-Host -Prompt 'Enter the domain account password' -AsSecureString
    }
    if ($DomainPassword.Length -eq 0) {
        throw 'The domain account password cannot be empty.'
    }
    $deploymentParameters.domainPassword = $DomainPassword
}

$deploymentArguments = @{
    ResourceGroupName       = $ResourceGroupName
    TemplateFile            = $templatePath
    TemplateParameterObject = $deploymentParameters
    ErrorAction             = 'Stop'
}

if ($PSCmdlet.ShouldProcess($ResourceGroupName, 'Deploy Azure Virtual Machine template')) {
    New-AzResourceGroupDeployment @deploymentArguments
}
