Write-Verbose 'Starting VC++ 2015 Build Tools download...' -verbose
$downloadUrl = 'https://download.microsoft.com/download/5/f/7/5f7acaeb-8363-451f-9425-68a90f98b238/visualcppbuildtools_full.exe'
Invoke-WebRequest -Uri $downloadUrl -UseBasicParsing -OutFile $PSScriptRoot\vcpptools.exe
$expectedSha = '1E1774869ABD953D05D10372B7C08BFA0C76116F5C6DF1F3D031418CCDCD8F7B'
$actualSha = $(Get-FileHash -Path $PSScriptRoot\vcpptools.exe -Algorithm SHA256).Hash
If ($expectedSha -ne $actualSha) {
    Throw 'vcpptools.exe hash does not match!'
}

$adminFilePath = Join-Path $PSScriptRoot  -ChildPath 'visualcppbuildtools.xml'
if (-not(Test-Path $adminFilePath))
{
    throw ('AdminFile not found:{0}' -f $adminFilePath)

}

$procArgs = @(
    '-NoRestart'
    '-Quiet'
    "-Log $PSScriptRoot\vcpptools.exe.log"
    "-AdminFile $adminFilePath"
)

Write-Verbose 'Starting VC++ 2015 Build Tools setup...' -verbose
$proc = Start-Process -FilePath $PSScriptRoot\vcpptools.exe -ArgumentList $procArgs -wait -PassThru 
$vcVars = ${env:ProgramFiles(x86)}+'\Microsoft Visual Studio 14.0\Common7\Tools\vsvars32.bat'
$vcBld = ${env:ProgramFiles(x86)}+'\Microsoft Visual C++ Build Tools\vcbuildtools.bat'
If (($proc.ExitCode -eq 0) -and (Test-Path $vcBld) -and (Test-Path $VcVars)) {
    Write-Verbose -Verbose 'VC++ 2015 Build Tools v14.0.25420.1 setup is complete.'`
} 
else 
{
    Get-Content -Path $PSScriptRoot\vcpptools.exe.log -ea Ignore | %{Write-Verbose $_ -verbose}
    Write-Verbose -Verbose 'See C:\Dockerfile.log for more information.'
    Write-Verbose -Verbose ('Test-Path "'+$vcBld+'"')
    Test-Path $vcBld
    Write-Verbose ('Test-Path "'+$VcVars+'"') -verbose
    Test-Path $VcVars
    Throw ("$PSScriptRoot\vcpptools.exe returned "+$proc.ExitCode+". Verbose logs under $PSScriptRoot\")
} 
Remove-Item 'C:\ProgramData\Package Cache\' -Recurse -Force
