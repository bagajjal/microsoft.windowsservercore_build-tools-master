Import-Module "$psscriptroot\dockerinstall.psm1" -DisableNameChecking
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
