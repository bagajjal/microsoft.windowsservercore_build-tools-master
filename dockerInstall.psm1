$programDefinition = @"
class Program 
{
  static void Main(string[] args)
  {
  }
}
"@
function Install-ChocolateyPackage
{
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $PackageName,

        [Parameter(Mandatory=$false)]
        [string]
        $Executable,

        [string[]]
        $ArgumentList,

        [switch]
        $Cleanup
    )

    if(-not(Get-Command -name Choco -ErrorAction SilentlyContinue))
    {
        Write-Verbose "Installing Chocolatey provider..." -Verbose
        Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression
    }

    Write-Verbose "Installing $PackageName..." -Verbose
    choco install -y $PackageName $ArgumentList

    if($executable)
    {
        $machinePathString = [System.Environment]::GetEnvironmentVariable('path',[System.EnvironmentVariableTarget]::Machine)
        $machinePath = $machinePathString -split ';'
        Write-Verbose "Verifing $Executable is in path..." -Verbose
        $exeSource = $null
        $exeSource = Get-ChildItem -path "$env:ProgramFiles\$Executable" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
        if(!$exeSource)
        {
            Write-Verbose "Falling back to x86 program files..." -Verbose
            $exeSource = Get-ChildItem -path "${env:ProgramFiles(x86)}\$Executable" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
        }
        if(!$exeSource)
        {
            Write-Verbose "Falling back to chocolatey..." -Verbose
            $exeSource = Get-ChildItem -path "$env:ProgramData\chocolatey\$Executable" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
        }
        if(!$exeSource)
        {
            Write-Verbose "Falling back to the root of the drive..." -Verbose
            $exeSource = Get-ChildItem -path "/$Executable" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
        }
        if(!$exeSource)
        {
            throw "$Executable not found"
        }

        $exePath = Split-Path -Path $exeSource
        if($machinePath -inotcontains $exePath)
        {
            $newPath = "$machinePathString;$exePath"
            Write-Verbose "Adding $exePath to path..." -Verbose
            [System.Environment]::SetEnvironmentVariable('path',$newPath,[System.EnvironmentVariableTarget]::Machine)
        }
        else 
        {
            Write-Verbose "$exePath already in path." -Verbose
        }
    }

    if($Cleanup.IsPresent)
    {
        Remove-Folder -Folder "$env:temp\chocolatey"
    }
}

function Remove-Folder
{
    param(
        [string]
        $Folder
    )

    Write-Verbose "Cleaning up $Folder..." -Verbose
    $filter = Join-Path -Path $Folder -ChildPath *
    [int]$measuredCleanupMB = (Get-ChildItem $filter -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
    Remove-Item -recurse -force $filter -ErrorAction SilentlyContinue
    Write-Verbose "Cleaned up $measuredCleanupMB MB from $Folder" -Verbose  
}

function Remove-Win10SdkPackageCache
{
    Remove-Folder "$env:ProgramData\Package Cache"
}

function Install-FakeNetExe {
    Write-Verbose "Install fake net.exe" -Verbose
    $fakeNetPath = "$env:temp\net.exe"
    Add-Type -OutputAssembly $fakeNetPath -OutputType ConsoleApplication -TypeDefinition $programDefinition
    Copy-Item C:\Windows\System32\net.exe C:\Windows\System32\net.exe.bak
    Copy-Item C:\Windows\SysWOW64\net.exe C:\Windows\SysWOW64\net.exe.bak
    $script:acl1 = Get-Acl C:\Windows\System32\net.exe
    $acl11 = Get-Acl C:\Windows\System32\net.exe
    $script:acl2 = Get-Acl C:\Windows\SysWOW64\net.exe
    $acl21 = Get-Acl C:\Windows\SysWOW64\net.exe
    $permission = 'BUILTIN\Administrators','FullControl','Allow'
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
    $acl11.SetAccessRule($accessRule)
    Set-Acl C:\Windows\System32\net.exe -AclObject $acl11
    $acl21.SetAccessRule($accessRule)
    Set-Acl C:\Windows\SysWOW64\net.exe -AclObject $acl21
    Copy-Item $fakeNetPath C:\Windows\System32\net.exe
    Copy-Item $fakeNetPath C:\Windows\SysWOW64\net.exe
    Remove-Item $fakeNetPath
}

function Remove-FakeNetExe {
    if(test-Path C:\Windows\System32\net.exe.bak)
    {
        Write-Verbose "Restoring real system32\net.exe" -Verbose
        Remove-Item C:\Windows\System32\net.exe
        Rename-Item C:\Windows\System32\net.exe.bak C:\Windows\System32\net.exe
    }
    if(Test-Path C:\Windows\SysWOW64\net.exe.bak)
    {
        Write-Verbose "Restoring real syswow64\net.exe" -Verbose
        Remove-Item C:\Windows\SysWOW64\net.exe
        Rename-Item C:\Windows\SysWOW64\net.exe.bak C:\Windows\SysWOW64\net.exe
    }

    if($script:acl1)
    {
        Write-Verbose "Restoring real system32\net.exe acl." -Verbose
        Set-Acl C:\Windows\System32\net.exe -AclObject $script:acl1
    }
    else {
        Write-Warning "!!!System32\net.exe acl was not saved!!!"
    }

    if($script:acl2)
    {
        Write-Verbose "Restoring real syswow64\net.exe acl." -Verbose
        Set-Acl C:\Windows\SysWOW64\net.exe -AclObject $script:acl2
    }
    else {
        Write-Warning "!!!Syswow64\net.exe acl was not saved!!!"
    }
}

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