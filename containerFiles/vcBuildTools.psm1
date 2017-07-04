Import-Module "$PSScriptRoot\dockerInstall.psm1"
Import-Module "$PSScriptRoot\sdkCommon.psm1"

$cmdContents = @"
@echo off
call "%ProgramFiles(x86)%\Microsoft Visual C++ Build Tools\vcbuildtools.bat" x64
set
"@
function Set-SdkEnv
{
    $cmdPath = Join-Path $env:temp -ChildPath ([System.IO.Path]::GetRandomFileName() + '.cmd')
    Set-Content -LiteralPath $cmdPath -Value $cmdContents -Encoding Ascii 
    try
    {
        &$cmdPath | Foreach-Object {
            $cmdVar,$cmdVal=$_.split('=')
            if($cmdVar -ne 'Platform')
            {
                if((Get-Item -Path env:$cmdVar -Exclude SilentlyContinue).Value -ne $cmdVal)
                {
                    Write-Verbose "setting machine variable $cmdVar to $cmdVal" -Verbose
                    [System.Environment]::SetEnvironmentVariable($cmdVar,$cmdVal,[System.EnvironmentVariableTarget]::Machine)
                }
            }
        }
    }
    finally
    {
        Remove-Item -LiteralPath $cmdPath -ErrorAction SilentlyContinue -Force
    }
}

function Install-VcBuildTools
{
    Install-ChocolateyPackage -PackageName vcbuildtools -ArgumentList @(
        '-ia'
        '"/InstallSelectableItems VisualCppBuildTools_ATLMFC_SDK;VisualCppBuildTools_NETFX_SDK"'
    )
    Set-SdkEnv
    Remove-Win10SdkPackageCache
}
