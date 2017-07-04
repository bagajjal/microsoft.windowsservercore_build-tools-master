function Get-File
{
    param(
        $filter
    )

    $result = Get-ChildItem $filter -ErrorAction SilentlyContinue -Recurse | Select-Object -First 1
    if($result)
    {
        return $result.fullname
    }
    return $filter
}

Describe "Verify containers contain expected files" {
    $repos = @(
        @{
            file = (Get-File -filter "${env:ProgramFiles(x86)}\Windows Kits\10\bin\x64\mc.exe")
        }
        @{
            file = (Get-File -filter "${env:ProgramFiles(x86)}\Microsoft Visual C++ Build Tools\vcbuildtools.bat")
        }
        @{
            file = (Get-File -filter "${env:ProgramFiles(x86)}\WiX Toolset xcopy\bin\heat.exe")
        }
    )

    it "should contain <file>" -TestCases $repos {
        param(
            [parameter(Mandatory)]
            [string]$file
            
        )

        $file | should exist
    }
}