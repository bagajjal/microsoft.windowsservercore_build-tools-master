Import-Module "$PSScriptRoot\dockerInstall.psm1"
Import-Module "$PSScriptRoot\sdkCommon.psm1"

# C# program used in Install-FakeNetExe
$programDefinition = @"
class Program 
{
  static void Main(string[] args)
  {
  }
}
"@



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

function Install-Win10Sdk
{
    Install-FakeNetExe
    try 
    {
        Install-ChocolateyPackage -PackageName "windows-sdk-10.1" -CleanUp
        Remove-Win10SdkPackageCache
    }
    finally
    {
        Remove-FakeNetExe  
    }
}
