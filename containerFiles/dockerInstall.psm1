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
