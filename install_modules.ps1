<#
.SYNOPSIS
    This script is used in AWS CodeBuild to install the required PowerShell Modules
    for the build process.
#>
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$VerbosePreference = 'SilentlyContinue'

$tempPath = [System.IO.Path]::GetTempPath()

# List of PowerShell Modules required for the build
# The AWS PowerShell Modules are added below, based on the $PSEdition
$modulesToInstall = [System.Collections.ArrayList]::new()
$null = $modulesToInstall.Add(([PSCustomObject]@{
            ModuleName    = 'Pester'
            ModuleVersion = '4.10.1'
            BucketName    = 'ps-invoke-modules'
            KeyPrefix     = ''
        }))
$null = $modulesToInstall.Add(([PSCustomObject]@{
            ModuleName    = 'InvokeBuild'
            ModuleVersion = '5.6.1'
            BucketName    = 'ps-invoke-modules'
            KeyPrefix     = ''
        }))
$null = $modulesToInstall.Add(([PSCustomObject]@{
            ModuleName    = 'PSScriptAnalyzer'
            ModuleVersion = '1.19.1'
            BucketName    = 'ps-invoke-modules'
            KeyPrefix     = ''
        }))
$null = $modulesToInstall.Add(([PSCustomObject]@{
            ModuleName    = 'platyPS'
            ModuleVersion = '0.12.0'
            BucketName    = 'ps-invoke-modules'
            KeyPrefix     = ''
        }))
$null = $modulesToInstall.Add(([PSCustomObject]@{
            ModuleName    = 'AWS.Tools.Common'
            ModuleVersion = '4.1.0.0'
            BucketName    = 'ps-invoke-modules'
            KeyPrefix     = ''
        }))
$null = $modulesToInstall.Add(([PSCustomObject]@{
            ModuleName    = 'AWS.Tools.SecretsManager'
            ModuleVersion = '4.1.0.0'
            BucketName    = 'ps-invoke-modules'
            KeyPrefix     = ''
        }))

if ($PSVersionTable.Platform -eq 'Win32NT') {
    $moduleInstallPath = [System.IO.Path]::Combine($env:ProgramFiles, 'WindowsPowerShell', 'Modules')
    if ($PSEdition -eq 'Core') {
        $moduleInstallPath = [System.IO.Path]::Combine($env:ProgramFiles, 'PowerShell', 'Modules')
    }
    else {
        $moduleInstallPath = [System.IO.Path]::Combine($env:ProgramFiles, 'WindowsPowerShell', 'Modules')
    }
}
elseif ($PSVersionTable.Platform -eq 'Unix') {
    $moduleInstallPath = [System.IO.Path]::Combine('/', 'usr', 'local', 'share', 'powershell', 'Modules')
}
elseif ($PSEdition -eq 'Desktop') {
    $moduleInstallPath = [System.IO.Path]::Combine($env:ProgramFiles, 'WindowsPowerShell', 'Modules')
}
else {
    throw 'Unrecognized OS platform'
}

'Installing PowerShell Modules'
foreach ($module in $modulesToInstall) {
    '  - {0} {1}' -f $module.ModuleName, $module.ModuleVersion

    # Download file from S3
    $key = '{0}_{1}.zip' -f $module.ModuleName, $module.ModuleVersion
    $localFile = Join-Path -Path $tempPath -ChildPath $key

    # Download modules from S3 to using the AWS CLI
    $s3Uri = 's3://{0}/{1}{2}' -f $module.BucketName, $module.KeyPrefix, $key
    & aws s3 cp $s3Uri $localFile --quiet

    # Ensure the download worked
    if (-not(Test-Path -Path $localFile)) {
        $message = 'Failed to download {0}' -f $module.ModuleName
        "  - $message"
        throw $message
    }

    # Create module path
    $modulePath = Join-Path -Path $moduleInstallPath -ChildPath $module.ModuleName
    $moduleVersionPath = Join-Path -Path $modulePath -ChildPath $module.ModuleVersion
    $null = New-Item -Path $modulePath -ItemType 'Directory' -Force
    $null = New-Item -Path $moduleVersionPath -ItemType 'Directory' -Force

    # Expand downloaded file
    Expand-Archive -Path $localFile -DestinationPath $moduleVersionPath -Force
}